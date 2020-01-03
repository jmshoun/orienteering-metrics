load_weather_file <- function(fname) {
    # The weather files are in a fixed-width format. The documentation for the format can be
    # found at ftp://ftp.ncdc.noaa.gov/pub/data/noaa/isd-format-document.pdf
    # All of the specific column values and transformations can be found there.
    data.frame(line=readLines(gzfile(fname))) %>%
        mutate(report_type = substring(line, 42, 46)) %>%
        # This report type code corresponds to hourly ASOS/AWOS reports. These are taken
        # about once an hour.
        filter(report_type == "FM-15") %>%
        mutate(wban_id = as.integer(substring(line, 11, 15)),
               date_time = substring(line, 16, 27),
               date_time = as.POSIXct(date_time, "%Y%m%d%H%M", tz="UTC"),
               # For each field, we need to extract it from the fixed-width record,
               # see if it takes a default value, and NA it out if it's a placeholder.
               wind_direction = as.integer(substring(line, 61, 63)),
               wind_direction = ifelse(wind_direction == 999, NA, wind_direction),
               wind_speed = as.numeric(substring(line, 66, 69)),
               wind_speed = ifelse(wind_speed == 9999, NA, wind_speed) / 10,
               visibility_v = as.numeric(substring(line, 71, 75)),
               visibility_v = ifelse(visibility_v == 99999, NA, visibility_v),
               visibility_h = as.numeric(substring(line, 79, 84)),
               visibility_h = ifelse(visibility_h == 999999, NA, visibility_h),
               temperature = ifelse(substring(line, 88, 88) == "+", 1, -1)
                    * as.numeric(substring(line, 89, 92)),
               temperature = ifelse(temperature == 9999, NA, temperature) / 10,
               dew_point = ifelse(substring(line, 94, 94) == "+", 1, -1)
                    * as.numeric(substring(line, 95, 98)),
               dew_point = ifelse(dew_point == 9999, NA, dew_point) / 10,
               humidity = 100 * exp((17.625 * dew_point) / (243.04 + dew_point))
                    / exp((17.625 * temperature) / (243.04 + temperature)),
               pressure = as.numeric(substring(line, 100, 104)),
               pressure = ifelse(pressure == 99999, NA, pressure) / 10,
               # Precipition is an optional field, so we need to grep for the field identifier.
               precip_match = regexpr("AA[1-4]01", line),
               precipitation = ifelse(precip_match > -1,
                                      as.numeric(substring(line, precip_match + 5,
                                                           precip_match + 8)),
                                      0),
               precipitation = ifelse(precipitation == 9999, NA, precipitation) / 10
               ) %>%
        select(-line, -precip_match, -report_type)
}

weather.files <- list.files("../data/weather/", full.names=TRUE)
raw.weather.df <- lapply(weather.files, load_weather_file) %>%
    bind_rows()
