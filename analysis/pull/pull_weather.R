### This is the unique station identifier for Ronald Reagan Washington National airport,
### the official weather reporting station for Washington, DC.
REAGAN.STATION.ID <- "72405013743"
### First and last years of weather data to download
FIRST.YEAR <- 2012
LAST.YEAR <- 2019

for (year in FIRST.YEAR:LAST.YEAR) {
    url <- sprintf("https://www.ncei.noaa.gov/data/global-hourly/access/%d/%s.csv",
                   year, REAGAN.STATION.ID)
    fname <- sprintf("../data/weather/reagan_%d.csv", year)
    download.file(url, fname)
}
