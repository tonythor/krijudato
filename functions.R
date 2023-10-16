library(tidyverse)
library(dplyr)
library(purrr)
library(tidyverse)
library("utf8")
library(stringr)

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

    if (year == 2017) {
      df <- df %>%
        rename(EdLevel = "FormalEducation", OrgSize = "CompanySize", DevType = "DeveloperType", Employment = "EmploymentStatus",
         "DatabaseWorkedWith" =  "HaveWorkedDatabase")
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
        rename(LanguageWorkedWith = "LanguageHaveWorkedWith", DatabaseWorkedWith = "DatabaseHaveWorkedWith") %>%
        mutate(Year = year) %>%
        select("Year", everything())
      return(df)
    }
  })

  combined_df <- do.call(rbind, list_of_dfs)
  return(combined_df)
}



# languages <- c("Python", "SQL", "Java", "JavaScript", "Ruby", "PHP", "C++", "Swift", "Scala", "R", "Rust", "Julia")
# project_df <- extract_and_append_cols(project_df, "LanguageHaveWorkedWith", languages)

# databases <- c("MySQL", "Microsoft SQL Server", "MongoDB", "PostgreSQL", "Oracle", "IBM DB2", "Redis", "SQLite", "MariaDB")
# project_df <- extract_and_append_cols(project_df, "DatabaseHaveWorkedWith", databases)

# platforms <- c("AWS", "Firebase", "Microsoft Azure", "Google Cloud", "Heroku")
# project_df <- extract_and_append_cols(project_df, "PlatformHaveWorkedWith", platforms)




extract_and_append_cols <- function(df, colname, values_to_search) {
  # Transform the values_to_search into a safe column name format
  safe_colnames <- str_to_lower(str_replace_all(values_to_search, "[^[:alnum:]]", ""))

  for (i in seq_along(values_to_search)) {
    # Create new column name
    new_col <- safe_colnames[i]
    # Search string
    search_str <- values_to_search[i]
    # Use regex to ensure full word match
    search_pattern <- paste0("(?<=^|,|;|\\s)", search_str, "(?=$|,|;|\\s)")

    df <- df %>% 
      mutate(
        !!new_col := ifelse(grepl(search_pattern, !!sym(colname), ignore.case = TRUE, perl = TRUE), "yes", "no")
      )
  }

  return(df)
}