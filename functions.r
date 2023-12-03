library(tidyverse)
library(dplyr)
library(purrr)
library(tidyverse)
library(utf8)
library(stringr)


merge_years <- function(years) {
  url_prefix <- "https://tonyfraser-data.s3.amazonaws.com/stack/"
  select_cols <- c("Year", "OrgSize", "Country", "Employment", "Gender", "EdLevel", "US_State", "Age", "DevType",
    "Sexuality", "Ethnicity", "DatabaseWorkedWith", "LanguageWorkedWith", "PlatformWorkedWith", "YearsCodePro", "AnnualSalary")

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
        AnnualSalary = "Salary",
        PlatformWorkedWith="HaveWorkedPlatform",
        Ethnicity = "Race"
      )
      add_columns <- c("Age", "US_State", "Sexuality")

    } else if(year == 2018) {
      rename_list <- c(
        EdLevel = "FormalEducation",
        OrgSize = "CompanySize",
        YearsCodePro = "YearsCoding",
        AnnualSalary = "ConvertedSalary",
        Sexuality = "SexualOrientation",
        Ethnicity = "RaceEthnicity"
      )
      add_columns <- c("US_State")

    } else if(year %in% c(2019, 2020)) {
      rename_list <- list(
        AnnualSalary = "ConvertedComp"
      )
      add_columns <- c("US_State")

    } else if(year == 2021) {
      rename_list <- c(
        AnnualSalary = "ConvertedCompYearly",
        LanguageWorkedWith = "LanguageHaveWorkedWith",
        DatabaseWorkedWith = "DatabaseHaveWorkedWith",
        PlatformWorkedWith = "PlatformHaveWorkedWith"
      )
      add_columns <- c()

    } else if(year == 2022) {
      rename_list <- c(
        AnnualSalary = "ConvertedCompYearly",
        LanguageWorkedWith = "LanguageHaveWorkedWith",
        DatabaseWorkedWith = "DatabaseHaveWorkedWith",
        PlatformWorkedWith = "PlatformHaveWorkedWith"
      )
      add_columns <- c("US_State")



    } else {
      rename_list <- list()
    }

    df <- rename_and_select(df, rename_list, add_columns = add_columns)
    return(df)
  })

  combined_df <- do.call(rbind, list_of_dfs) %>%
    mutate(
      YearsCodeProAvg = sapply(YearsCodePro, extract_and_average),
      OrgSizeAvg = sapply(OrgSize, extract_and_average),
      AgeAvg = sapply(Age, extract_and_average)
    )

  return(combined_df)
}

extract_vector_cols <- function(df, colname, values_to_search) {
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

extract_list_cols <- function(df, colname, values_to_search) {
  new_col <- as.character(names(values_to_search[1]))
  search_terms <- unlist(values_to_search[[1]])

  # Create the regex pattern for all search terms
  search_pattern <- paste0("(?<=^|,|;|\\s)(", paste(search_terms, collapse="|"), ")(?=$|,|;|\\s)")

  df <- df %>%
    mutate(
      !!new_col := ifelse(grepl(search_pattern, !!sym(colname), ignore.case = TRUE, perl = TRUE), "yes", "no")
    )
  return(df)
}


post_build_mutations <- function(wide_stack) {
  return(wide_stack %>%
    mutate(

      sexuality_grouped = case_when(
        #lgbtq   straight <NA>
        #34829   285006   140463
        grepl("Straight / Heterosexual|Straight or heterosexual", Sexuality, ignore.case = TRUE) ~ "straight",
        grepl("Bisexual|Gay or Lesbian|Queer|Asexual|Prefer to self-describe:|Prefer not to say", Sexuality, ignore.case = TRUE) ~ "lgbtq",
        TRUE ~ NA_character_  # NA_character_ is used to create NA values in character vectors
      ),
      ethnicity_grouped = case_when(
        # minority non-minority  <NA>
        # 110615   242511        107172
        grepl("White|European", Ethnicity, ignore.case = TRUE) ~ "non-minority",
        Ethnicity %in% c(NA, "Prefer not to say", "Or, in your own words:", "I don’t know", "I prefer not to say") ~ NA_character_,
        TRUE ~ "minority"
      )
    )
  )
}

get_stack_df <- function(persist = TRUE, load_from_cache = TRUE) {
  raw_stack_fn <- "merged_stack_raw.csv"
  wide_stack_fn <- "merged_stack_wide.csv"

  if (load_from_cache) {
    yr <- 2017:2022
    if (file.exists(wide_stack_fn)) {
      print("loading wide file from cache")
      return(read.csv(wide_stack_fn))
    } else if (file.exists(raw_stack_fn)) {
      print("loading raw file from cache, but building wide file")
      raw_stack <- read.csv(raw_stack_fn)
    } else {
      message("No cache files found. Generating raw and wide files...")
      raw_stack <- merge_years(yr)
    }
  } else {
    raw_stack <- merge_years(yr)
  }

  if (persist) {
    write.csv(raw_stack, raw_stack_fn, row.names = FALSE)
  }

  wide_stack <- raw_stack

  languages <- c("Python", "SQL", "Java", "JavaScript", "Ruby", "PHP", "C++", "Swift", "Scala", "R", "Rust", "Julia")
  wide_stack <- extract_vector_cols(wide_stack, "LanguageWorkedWith", languages)

  databases <- c("MySQL", "Microsoft SQL Server", "MongoDB", "PostgreSQL", "Oracle", "IBM DB2", "Redis", "SQLite", "MariaDB")
  wide_stack <- extract_vector_cols(wide_stack,  "DatabaseWorkedWith", databases)

  platforms <- c("Microsoft Azure", "Google Cloud", "IBM Cloud or Watson", "Kubernetes", "Linux", "Windows")
  wide_stack <- extract_vector_cols(wide_stack,  "PlatformWorkedWith", platforms)

  aws_entries  <- list(aws = c("AWS", "aws", "Amazon Web Services", "Amazon Web Services (AWS)"))
  wide_stack <- post_build_mutations(wide_stack)
  wide_stack <- extract_list_cols(wide_stack, "PlatformWorkedWith", aws_entries)




  if (persist) {
    write.csv(wide_stack, wide_stack_fn, row.names = FALSE)
  }

  return(wide_stack)
}
