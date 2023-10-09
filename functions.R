library(tibble)
library(dplyr)
library(tidyverse)
library(tidyr)


extract_samples <- function(years, url_prefix) {
  # builds a summary df that shows you 10 different examples
  # of column data. Useful for understaning what a column does.

  # Initialize the final df.

  final_df <- tibble(year = integer(), columnHeader = character(), percentage_used = double())
  for(i in 1:10) {
    final_df <- final_df %>%
      add_column(!!paste0("sample_record", i) := character())
  }

  for (year in years) {
    url <- paste0(url_prefix, "stack/y=", year, "/survey_results_public.csv")

    tryCatch({
      # Reading the entire CSV to get samples
      data <- read.csv(url, header=TRUE, stringsAsFactors=FALSE)

      # Calculate the percentage of non-NA values for each column
      percentage_used <- sapply(data, function(col) {
        sum(!is.na(col)) / length(col) * 100
      })

      # Creating a dataframe for this year
      data_for_year <- tibble(
        year = rep(year, ncol(data)),
        columnHeader = names(data),
        percentage_used = round(percentage_used, 2)
      )

      # Extracting 10 non-NA samples for each column header
      for (i in 1:10) {
        data_for_year <- data_for_year %>%
          mutate(!!paste0("sample_record", i) := sapply(names(data), function(col) {
            non_na_values <- data[!is.na(data[, col]), col]
            if (length(non_na_values) >= i) { 
              return(as.character(non_na_values[i]))
            } else {
              return(NA)
            }
          }))
      }

      # Binding this dataframe with the final one
      final_df <- bind_rows(final_df, data_for_year)

    }, error = function(e) {
      cat("Error with year", year, ":", e$message, "\n")
    })
  }

  # Return the final dataframe
  return(final_df)
}


extract_column_summary <- function(years_list, url_prefix) {
  ## builds a dataframe that shows if a column overlaps between years or not.
  headers_list <- list()

  for (year in years_list) {
    url <- paste0(url_prefix, "stack/y=", year, "/survey_results_public.csv")

    tryCatch({
      df <- read.csv(url, header=TRUE, nrows = 1)
      headers_list[[year]] <- names(df)
    }, error=function(e) {
      cat("Error with year", year, ":", e$message, "\n")
    })
  }

  long_df <- headers_list %>% 
    enframe(name = "Year", value = "Header") %>%
    unnest(cols = c("Header"))

  reshaped_df <- long_df %>%
    mutate(Present = "*") %>%
    pivot_wider(names_from = "Header", values_from = "Present", values_fill = NA)

  years_as_columns <- reshaped_df %>%
    gather("Header", "Present", -"Year") %>%
    filter(!is.na("Present")) %>%
    spread("Year", "Present", fill = NA)

  return(years_as_columns)
}
