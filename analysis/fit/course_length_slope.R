source("_libraries.R")
source("load/load_data.R")

VENUE.SETTER.COLOR.MODEL <- stan_model("model/venue_setter_color.stan")
VENUE.SETTER.MODEL <- stan_model("model/venue_setter.stan")

##  === Support functions =========================================================================

fit_venue_setter_color <- function(df, metric_fn, metric.name) {
    venue.df <- gen_lookup_df(df, "venue")
    setter.df <- gen_lookup_df(df, "setter")
    color.df <- gen_lookup_df(df, "color")
    prepped.df <- df %>%
        inner_join(venue.df, by=c("venue")) %>%
        inner_join(setter.df, by=c("setter")) %>%
        inner_join(color.df, by=c("color"))

    prepped.data <- prep_setter_venue_data(prepped.df, metric_fn(df))
    prepped.data$nColors <- max(prepped.df$color_id)
    prepped.data$color_id = prepped.df$color_id

    mdl.fit <- rstan::sampling(VENUE.SETTER.COLOR.MODEL, data=prepped.data,
                               control=list(adapt_delta=0.995, max_treedepth=14))
    params <- rstan::extract(mdl.fit)

    list(
        venue = extract_params(params, metric.name, venue.df, "venue"),
        setter = extract_params(params, metric.name, setter.df, "setter"),
        color = extract_params(params, metric.name, color.df, "color")
    )
}

fit_venue_setter <- function(df, metric_fn, metric.name) {
    venue.df <- gen_lookup_df(df, "venue")
    setter.df <- gen_lookup_df(df, "setter")
    prepped.df <- df %>%
        inner_join(venue.df, by=c("venue")) %>%
        inner_join(setter.df, by=c("setter"))

    prepped.data <- prep_setter_venue_data(prepped.df, metric_fn(df))
    mdl.fit <- rstan::sampling(VENUE.SETTER.MODEL, data=prepped.data,
                               control=list(adapt_delta=0.995, max_treedepth=14))
    params <- rstan::extract(mdl.fit)

    list(
        venue = extract_params(params, metric.name, venue.df, "venue"),
        setter = extract_params(params, metric.name, setter.df, "setter")
    )
}

gen_lookup_df <- function(df, predictor) {
    prepped.df <- df %>%
        select_(predictor) %>%
        unique() %>%
        arrange_(predictor)
    prepped.df[[paste0(predictor, "_id")]] <- seq_along(prepped.df[[predictor]])
    prepped.df
}

extract_params <- function(params, metric, lookup.df, predictor) {
    effects <- params[[paste0(predictor, "_effect")]]
    lookup.df[[paste0(metric, "_mu")]] <- apply(effects, 2, mean)
    lookup.df[[paste0(metric, "_q05")]] <- apply(effects, 2, quantile, 0.05)
    lookup.df[[paste0(metric, "_q25")]] <- apply(effects, 2, quantile, 0.25)
    lookup.df[[paste0(metric, "_q75")]] <- apply(effects, 2, quantile, 0.75)
    lookup.df[[paste0(metric, "_q95")]] <- apply(effects, 2, quantile, 0.95)
    lookup.df
}

prep_setter_venue_data <- function(df, metric) {
    list(
        N = nrow(df),
        nVenues = max(df$venue_id),
        nSetters = max(df$setter_id),
        metric = metric,
        venue_id = df$venue_id,
        setter_id = df$setter_id
    )
}

##  === Model fitting =============================================================================

course.pred.df <- classic.leg.summary.df %>%
    # Filter out one event with obvious wrong climb values
    filter(!(event_date == as.Date("2013-05-19") & venue == "Mason Neck"))

advanced.course.pred.df <- course.pred.df %>%
    filter(course_clean %in% c("Brown", "Green", "Red", "Blue")) %>%
    rename(setter=course_setter, color=course_clean)

# Fit estimates of effects for all advanced courses combined
advanced.course.fit <- list(
    slope = fit_venue_setter_color(advanced.course.pred.df,
                                   function(df) log(df$climb / df$length * 100), "slope"),
    length = fit_venue_setter_color(advanced.course.pred.df,
                                    function(df) log(df$length / 1000), "length")
)

# Fit estimates of effects for each recreational course separately
recreational.course.fits <- sapply(c("White", "Yellow", "Orange"), function(color.) {
    pred.df <- course.pred.df %>%
        filter(course_clean == color.) %>%
        rename(setter=course_setter)
    list(
        slope = fit_venue_setter(pred.df, function(df) log(df$climb / df$length * 100), "slope"),
        length = fit_venue_setter(pred.df, function(df) log(df$length / 1000), "length")
    )
}, simplify=FALSE)

##  === Consolidating effect estimates ============================================================

venue.length.effects <- rbind(
    advanced.course.fit$length$venue %>% mutate(course = "Advanced"),
    recreational.course.fits$White$length$venue %>% mutate(course = "White"),
    recreational.course.fits$Yellow$length$venue %>% mutate(course = "Yellow"),
    recreational.course.fits$Orange$length$venue %>% mutate(course = "Orange")
)

venue.slope.effects <- rbind(
    advanced.course.fit$slope$venue %>% mutate(course = "Advanced"),
    recreational.course.fits$White$slope$venue %>% mutate(course = "White"),
    recreational.course.fits$Yellow$slope$venue %>% mutate(course = "Yellow"),
    recreational.course.fits$Orange$slope$venue %>% mutate(course = "Orange")
)

setter.length.effects <- rbind(
    advanced.course.fit$length$setter %>% mutate(course = "Advanced"),
    recreational.course.fits$White$length$setter %>% mutate(course = "White"),
    recreational.course.fits$Yellow$length$setter %>% mutate(course = "Yellow"),
    recreational.course.fits$Orange$length$setter %>% mutate(course = "Orange")
)

setter.slope.effects <- rbind(
    advanced.course.fit$slope$setter %>% mutate(course = "Advanced"),
    recreational.course.fits$White$slope$setter %>% mutate(course = "White"),
    recreational.course.fits$Yellow$slope$setter %>% mutate(course = "Yellow"),
    recreational.course.fits$Orange$slope$setter %>% mutate(course = "Orange")
)

venue.effects <- inner_join(venue.length.effects, venue.slope.effects,
                            by=c("venue", "venue_id", "course")) %>%
    mutate(course = factor(course, c("White", "Yellow", "Orange", "Advanced"))) %>%
    inner_join(venue.location.df, by=c("venue"))
setter.effects <- inner_join(setter.length.effects, setter.slope.effects,
                             by=c("setter", "setter_id", "course")) %>%
    mutate(course = factor(course, c("White", "Yellow", "Orange", "Advanced")))

# Cache results
saveRDS(venue.effects, "_cache/course_venue_effects.rds")
saveRDS(setter.effects, "_cache/course_setter_effects.rds")
