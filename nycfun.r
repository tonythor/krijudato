library(tidyverse)
library(jsonlite)
library(httr)


if (!file.exists("nyc_key")) {
  stop("The API key is missing. Please put the API key in a file called 'nyc_key'.")
}

## ------ functions --------- ## 
get_borough_code <- function(borough) {
  switch(borough,
    "Bronx" = "2",
    "Brooklyn" = "3",
    "Manhattan" = "1",
    "Queens" = "4",
    "Staten Island" = "5",
    NA)
}

getUrl <- function(url, name) {
  response <- GET(url)
  if (status_code(response) == 200) {
    content <- content(response, "text", encoding = "UTF-8")

    if (grepl("NOT RECOGNIZED", content)) {
      message("URL Error: ", url, " - URL NOT RECOGNIZED")
      return("NOT RECOGNIZED")
    } else {
      file_name <- paste0("nogit_cache/", str_replace_all(name, " ", "_"), ".json")
      writeLines(content, file_name)
      return(content)
    }
  } else {
    warning("Failed to fetch data: HTTP status code ", status_code(response))
    return(NULL)
  }
}

extract_street_number <- function(address) {
  str_extract(address, "^\\d+(-\\d+)?")
}

extract_street_name <- function(address) {
  str_replace(address, "^\\d+(-\\d+)?\\s*", "") %>%
    str_trim() %>%
    str_replace_all(" ", "%20")
}

extract_data <- function(json) {
  parsed <- fromJSON(json, flatten = TRUE)
  out_data <- parsed$display[names(parsed$display) %in% grep("^out_", names(parsed$display), value = TRUE)]
  out_data <- setNames(as.list(out_data), names(out_data))
  return(as.data.frame(out_data, stringsAsFactors = FALSE))
}
## --------------------------- ##

key <- readLines("nyc_key")

dir.create("nogit_cache", showWarnings = FALSE)

addr <- read_csv('nyc_cuny.csv') %>%
  mutate(street_number = gsub(" St$", " Street", street_number)) %>%
  mutate(street_number = gsub(" Ave$", " Avenue", street_number)) %>%
  mutate(AddressNo = sapply(street_number, extract_street_number),
    StreetName = sapply(street_number, extract_street_name),
    url = paste0("https://geoservice.planning.nyc.gov/geoservice/geoservice.svc/Function_1A?Borough=",
      sapply(borough, get_borough_code),
      "&AddressNo=", AddressNo,
      "&StreetName=", StreetName,
      "&Key=", key))

json_responses <- map2(addr$url, addr$location_name, getUrl)

extracted_data <- do.call(rbind, lapply(json_responses, extract_data))
addr <- bind_cols(addr, extracted_data)

first_lookup_path <- "./nogit_cache/_first_lookup.csv"
write.csv(addr, first_lookup_path, row.names = FALSE)
looked_up <- read_csv(first_lookup_path)


# download pluto if necessary
url <- "https://tonyfraser-data.s3.amazonaws.com/nyc-addresses/nyc_pluto_23v3_csv/pluto_23v3.csv"
pluto_path <- "./nogit_cache/_pluto_23v3.csv"
if (!file.exists(pluto_path)) {
  download.file(url, pluto_path, mode = "wb")
}
pluto <- read_csv(pluto_path)


joined_pluto_path <- "./nogit_cache/_joined_pluto.csv"
write.csv(left_join(looked_up, pluto, by = c("out_bbl" = "bbl")), joined_pluto_path, row.names = FALSE)

## load the cache
joined_pluto <- read_csv(joined_pluto_path)


## Please save for now.
# https://docs.google.com/spreadsheets/d/1_VMmZhuM18OWDDnPzXLuSJrUpb1LECUEOfmQUJcN6V4/edit#gid=0
# https://geoservice.planning.nyc.gov/geoservice/geoservice.svc/Function_1A?Borough=3&AddressNo=150&StreetName=74%20STREET&Key=7KaPdSgVkXp2s5v8
# # contains out_bbl_block, out_bbl_lot, out_bbl 
# https://geoservice.planning.nyc.gov/geoservice/geoservice.svc/Function_1E?Borough=3&AddressNo=150&StreetName=74%20STREET&Key=7KaPdSgVkXp2s5v8
# https://geoservice.planning.nyc.gov/geoservice/geoservice.svc/Function_BBL?Borough=1&Block=47&Lot=7501&key=7KaPdSgVkXp2s5v8
# https://geoservice.planning.nyc.gov/geoservice/geoservice.svc/Function_BBL?Borough=3&Block=5927&Lot=24&key=7KaPdSgVkXp2s5v8

