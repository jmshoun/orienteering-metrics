WEATHER.POISSON.MODEL <- stan_model("model/weather_poisson.stan")

fit_event_wind <- function(weather.df, event.latitude, event.longitude,
                           event.date, stop.hour, window.size) {
    window.stop <- sprintf("%s %02d:30:00", event.date, stop.hour) %>%
        as.POSIXct(tz="America/New_York")
    window.start <- window.stop - hours(window.size)

    raw.wind.df <- weather.df %>%
        filter(date_time >= window.start,
               date_time <= window.stop,
               !is.na(wind_speed)) %>%
        group_by(wban_id) %>%
        arrange(date_time) %>%
        mutate(seconds_to_next = c(diff(as.numeric(date_time)), 0),
               seconds_from_prev = c(0, tail(seconds_to_next, -1)),
               weight = (seconds_to_next + seconds_from_prev) / 2) %>%
        summarize(wind_speed = weighted.mean(wind_speed, weight)) %>%
        inner_join(dc.stations, by=c("wban_id"))

    obs.df <- raw.wind.df %>%
        mutate(y = as.integer(round(wind_speed * 5))) %>%
        filter(!is.na(y))
    data.frame(value = fit_weather_poisson(obs.df, event.latitude, event.longitude) / 5,
               event_date = event.date)
}

fit_event_precipitation <- function(weather.df, event.latitude, event.longitude,
                                    event.date, stop.hour, window.size) {
    window.stop <- sprintf("%s %02d:30:00", event.date, stop.hour) %>%
        as.POSIXct(tz="America/New_York")
    window.start <- window.stop - hours(window.size)

    raw.precip.df <- weather.df %>%
        filter(date_time >= window.start,
               date_time <= window.stop) %>%
        group_by(wban_id) %>%
        summarize(precipitation = sum(precipitation)) %>%
        ungroup() %>%
        filter(!is.na(precipitation)) %>%
        inner_join(dc.stations, by=c("wban_id")) %>%
        select(wban_id, latitude, longitude, precipitation)

    obs.df <- raw.precip.df %>%
        mutate(y = as.integer(round(precipitation * 10)))
    data.frame(value = fit_weather_poisson(obs.df, event.latitude, event.longitude) / 10,
               event_date = event.date)
}

fit_weather_poisson <- function(observation.df, event.latitude, event.longitude) {
    if (max(observation.df$y) == 0) {
        return(rep(0, 4000))
    }

    model.data <- with(observation.df, {
        list(
            N1 = length(y),
            N2 = 1,
            obs_latitude = scale(latitude)[, 1],
            obs_longitude = scale(longitude)[, 1],
            y = y,
            pred_latitude = as.array((event.latitude - mean(latitude)) / sd(latitude)),
            pred_longitude = as.array((event.longitude - mean(longitude)) / sd(longitude))
        )
    })

    model.fit <- rstan::sampling(WEATHER.POISSON.MODEL, model.data,
                                 control=list(adapt_delta=0.95))
    rstan::extract(model.fit)$y_pred[, 1]
}
