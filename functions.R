library("tidyverse")
library(dplyr)
# years <- c(2017, 2018, 2019, 2020, 2021, 2022)

years <- c(2022)
df_list <- list()
for (year in years) {
  url <- paste0("https://tonyfraser-data.s3.amazonaws.com/stack/y%3D", year, "/survey_results_public.csv")
  df <- read.csv(url)
  df$year <- year
  df_list[[year]] <- df
}
final_df <- do.call(rbind, df_list)