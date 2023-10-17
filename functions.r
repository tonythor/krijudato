library(tidyverse)
library(dplyr)
library(purrr)
library(tidyverse)
library(utf8)
library(stringr)


merge_years <- function(years) {
  url_prefix <- "https://tonyfraser-data.s3.amazonaws.com/stack/"
  select_cols <- c("Year", "OrgSize", "Country", "Employment", "Gender", "EdLevel", "DevType",
                   "DatabaseWorkedWith", "LanguageWorkedWith", "YearsCodePro", "AnnualSalary")
  
  extract_and_average<- function(year_string) {
    numbers <- as.numeric(str_extract_all(year_string, "\\d+")[[1]])  # Extract numbers
    mean(numbers)  # Take average
  }
  
  construct_url <- function(year) {
    paste0(url_prefix, "y=", year, "/survey_results_public.csv")
  }
  
  rename_and_select <- function(df, rename_list, add_columns = NULL) {
    df <- df %>%
      rename(!!!rename_list)
    
    if (!is.null(add_columns) && length(add_columns) > 0) {
      for (col in add_columns) {
        df <- df %>% mutate(!!col := NA)
      }
    }
    
    df <- df %>% select(all_of(select_cols))
    return(df)
  }
  list_of_dfs <- lapply(years, function(year) {
    df <- read.csv(construct_url(year)) %>%
      mutate(Year = year)
    
    if (year == 2017) {
      rename_list <- c(
        EdLevel = "FormalEducation",
        OrgSize = "CompanySize",
        DevType = "DeveloperType",
        Employment = "EmploymentStatus",
        DatabaseWorkedWith = "HaveWorkedDatabase",
        LanguageWorkedWith = "HaveWorkedLanguage",
        YearsCodePro = "YearsProgram",
        AnnualSalary = "Salary"
      )
      add_columns <- c()
      
    } else if(year == 2018) {
      rename_list <- c(
        EdLevel = "FormalEducation",
        OrgSize = "CompanySize",
        YearsCodePro = "YearsCoding",
        AnnualSalary = "ConvertedSalary"
      )
      add_columns <- c()
      
    } else if(year %in% c(2019, 2020)) {
      rename_list <- list(
        AnnualSalary = "ConvertedComp"
      )
      add_columns <- c()
      
    } else if(year %in% c(2021, 2022)) {
      rename_list <- c(
        AnnualSalary = "ConvertedCompYearly",
        LanguageWorkedWith = "LanguageHaveWorkedWith",
        DatabaseWorkedWith = "DatabaseHaveWorkedWith"
      )
      add_columns <- c()
    } else {
      rename_list <- list()
    }
    
    df <- rename_and_select(df, rename_list, add_columns = add_columns)
    return(df)
  })
  
  combined_df <- do.call(rbind, list_of_dfs) %>%
    mutate(
      YearsCodeProAvg = sapply(YearsCodePro, extract_and_average),
      OrgSizeAvg = sapply(OrgSize, extract_and_average)
    )
  
  return(combined_df)
}

# Klussi's function
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