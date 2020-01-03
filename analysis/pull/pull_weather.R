### First and last years of weather data to download
FIRST.YEAR <- 2012
LAST.YEAR <- 2019

# Downloads a full archive of weather history for a single weather station.
download_station <- function(station.id, first.year, last.year) {
    for (year in first.year:last.year) {
        url <- sprintf("ftp://ftp.ncdc.noaa.gov/pub/data/noaa/%d/%s-%d.gz", year, station.id, year)
        fname <- sprintf("../data/weather/%s_%d.gz", station.id, year)
        download.file(url, fname, quiet=TRUE)
    }
}

# Download weather for all stations in the DC area.
dc.stations <- readRDS("_cache/dc_stations.rds")
for (station.id in dc.stations$station_id) {
    message(station.id)
    tryCatch({
        download_station(station.id, FIRST.YEAR, LAST.YEAR)
    }, error = function(err) { NULL })
}
