WEATHER.NORMAL.MODEL <- stan_model("model/weather_normal.stan")

fit_event_temperature <- function(weather.df, event.latitude, event.longitude,
                                  event.date, stop.hour, window.size, metric) {
    window.stop <- sprintf("%s %02d:30:00", event.date, stop.hour) %>%
        as.POSIXct(tz="America/New_York")
    window.start <- window.stop - hours(window.size)

    weather.df$metric <- weather.df[[metric]]
    raw.temp.df <- weather.df %>%
        filter(date_time >= window.start,
               date_time <= window.stop,
               !is.na(metric)) %>%
        group_by(wban_id) %>%
        arrange(date_time) %>%
        mutate(seconds_to_next = c(diff(as.numeric(date_time)), 0),
               seconds_from_prev = c(0, tail(seconds_to_next, -1)),
               weight = (seconds_to_next + seconds_from_prev) / 2) %>%
        summarize(metric = weighted.mean(metric, weight)) %>%
        inner_join(dc.stations, by=c("wban_id"))

    obs.df <- raw.temp.df %>%
        mutate(y = metric) %>%
        filter(!is.na(y))
    data.frame(value = fit_weather_normal(obs.df, event.latitude, event.longitude),
               event_date = event.date)
}

fit_weather_normal <- function(observation.df, event.latitude, event.longitude) {
    model.data <- with(observation.df, {
        list(
            N1 = length(y),
            N2 = 1,
            obs_latitude = scale(latitude)[, 1],
            obs_longitude = scale(longitude)[, 1],
            y = scale(y)[, 1],
            pred_latitude = as.array((event.latitude - mean(latitude)) / sd(latitude)),
            pred_longitude = as.array((event.longitude - mean(longitude)) / sd(longitude))
        )
    })

    model.fit <- rstan::sampling(WEATHER.NORMAL.MODEL, model.data,
                                 control=list(adapt_delta=0.95))
    rstan::extract(model.fit)$y_pred[, 1] * sd(observation.df$y) + mean(observation.df$y)
}
