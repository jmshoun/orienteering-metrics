source("_libraries.R")
source("load/load_data.R")
source("fit/load_weather.R")
source("fit/weather_normal.R")
source("fit/weather_poisson.R")

fit_event_weather <- function(weather.df, event.latitude, event.longitude, event.date) {
    message(event.date)
    rbind(
        fit_event_temperature(weather.df, event.latitude, event.longitude, event.date,
                              15, 5, "temperature") %>% mutate(metric = "temperature"),
        fit_event_temperature(weather.df, event.latitude, event.longitude, event.date,
                              15, 5, "dew_point") %>% mutate(metric = "dew_point"),
        fit_event_wind(weather.df, event.latitude, event.longitude, event.date, 15, 5) %>%
            mutate(metric = "wind_speed"),
        fit_event_precipitation(weather.df, event.latitude, event.longitude, event.date, 15, 5) %>%
            mutate(metric = "precipitation_event"),
        fit_event_precipitation(weather.df, event.latitude, event.longitude,
                                event.date, 10, 24) %>%
            mutate(metric = "precipitation_24h")
    )
}

classic.event.location.df <- classic.event.df %>%
    inner_join(venue.location.df, by=c("venue"))

system.time(raw.event.weather.df <- with(classic.event.location.df, {
    mapply(fit_event_weather, event.latitude=latitude, event.longitude=longitude,
           event.date=event_date, MoreArgs=list(weather.df=raw.weather.df), SIMPLIFY = FALSE) %>%
        bind_rows()
}))

saveRDS(raw.event.weather.df, "raw_event_weather.rds")
