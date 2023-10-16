library(tidyverse)
library(dplyr)
library(purrr)
library(tidyverse)
library("utf8")

## original functions, I don't thiink we need it anymore.
# years <- c(2017, 2018, 2019, 2020, 2021, 2022)
# years <- c(2022)
# df_list <- list()
# for (year in years) {
#   url <- paste0("https://tonyfraser-data.s3.amazonaws.com/stack/y%3D", year, "/survey_results_public.csv")
#   df <- read.csv(url)
#   df$year <- year
#   df_list[[year]] <- df
# }
# final_df <- do.call(rbind, df_list)


merge_years <- function(years, url_prefix) {
  # Helper function to construct the URL
  construct_url <- function(year) {
    paste0(url_prefix, "y=", year, "/survey_results_public.csv")
  }

  # Helper function to create a consistent dataframe template
  create_template <- function(df, year) {
    df <- df %>%
      select("OrgSize", "Country", "Employment", "EdLevel", "DevType") %>%
      mutate(
        DatabaseWorkedWith = NA,
        LanguageWorkedWith = NA,
        YearsCodePro = NA,
        Year = year
      )
    return(df)
  }

  list_of_dfs <- lapply(years, function(year) {
    df <- read.csv(construct_url(year))

    if(year == 2017) {
      df <- df %>%
        rename(EdLevel = "FormalEducation", OrgSize = "CompanySize", DevType = "DeveloperType", Employment = "EmploymentStatus")
      return(create_template(df, year))
    } else if(year == 2018) {
      df <- df %>% rename(EdLevel = "FormalEducation", OrgSize = "CompanySize")
      return(create_template(df, year))
    } else if(year %in% c(2019, 2020)) {
      df <- df %>% select("OrgSize", "Country", "Employment", "EdLevel", "DevType", "DatabaseWorkedWith", "LanguageWorkedWith")
      df$YearsCodePro <- NA
      return(df %>% mutate(Year = year))
    } else if(year %in% c(2021, 2022)) {
      df <- df %>% select("OrgSize", "Country", "Employment", "EdLevel", "DevType", 
        "DatabaseHaveWorkedWith", "LanguageHaveWorkedWith", "YearsCodePro") %>%
        rename(LanguageWorkedWith = "LanguageHaveWorkedWith", DatabaseWorkedWith = "DatabaseHaveWorkedWith")
      return(df %>% mutate(Year = year))
    }
  })

  combined_df <- do.call(rbind, list_of_dfs)
  return(combined_df)
}
