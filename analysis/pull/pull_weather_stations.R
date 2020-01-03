# This file has an inventory of weather stations in the ISD data set.
download.file("ftp://ftp.ncdc.noaa.gov/pub/data/noaa/isd-history.csv",
              "../data/isd-history.csv")

isd.history <- read_csv("../data/isd-history.csv")

# Get a subset of stations in the general vicinity of Washington, DC.
dc.stations <- isd.history %>%
    select(usaf_id=USAF, wban_id=WBAN, latitude=LAT, longitude=LON,
           start_date=BEGIN, end_date=END) %>%
    mutate(start_date = as.Date(as.character(start_date), "%Y%m%d"),
           end_date = as.Date(as.character(end_date), "%Y%m%d"),
           station_id = sprintf("%s-%05d", usaf_id, wban_id)) %>%
    filter(latitude >= 37.5,
           latitude <= 40.5,
           longitude >= -78.5,
           longitude <= -75.5,
           # Only take stations with WBAN IDs
           wban_id != 99999,
           # Drop WBAN station 124, which is on Kent Island and reads much higher
           # precipitation than any neighboring station.
           wban_id != 124,
           # Make sure the stations have been active over the entire time period.
           start_date <= as.Date("2012-01-01"),
           end_date >= as.Date("2019-12-01"))

saveRDS(dc.stations, "_cache/dc_stations.rds")
