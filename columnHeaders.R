## This code goes, reads the headers from all the files up on S3, and
## then saves them into a local CSV. It's a way we can whittle down
## columns.

library("tidyverse")

b <- "https://tonyfraser-data.s3.amazonaws.com/"
years <- c(2022, 2021, 2020, 2019, 2018, 2017)
headers_list <- list()

for (year in years) {
  url <- paste0(b, "stack/y%3D", year, "/survey_results_public.csv")
  print(url)

  # You can optionally use tryCatch to handle any potential errors 
  # and continue the loop even if one URL fails to load.
  tryCatch({
    df <- read.csv(url, header=TRUE, nrows = 1)
    headers_list[[year]] <- names(df) # Storing only the names (headers) instead of the entire df
  }, error=function(e) {
    cat("Error with year", year, ":", e$message, "\n")
  })
}

# Convert the list to a long-format dataframe
long_df <- headers_list %>% 
  enframe(name = "Year", value = "Header") %>% #<-- converts to a two column tibble, name+header
  unnest(cols = c(Header)) #<- explodes header into column

# Now looks like year -> vector of strings
# > glimpse(long_df)
# Rows: 556
# Columns: 2
# $ Year   <int> 2017, 2017, 2017, 2017, 2017, 2017, 2017, 2017, 2017, 2017, 201…
# $ Header <chr> "Respondent", "Professional", "ProgramHobby", "Country", "Unive…

reshaped_df <- long_df %>%
  mutate(Present = "*") %>% #<- this just adds a column with a *
  # this is the money, it blows out all columns on the top and makes the years look like 
  # row year respondent professional ishappy language ...
  # 1   2022   *        NA           *       *        ...
  # 2   2020   NA       *            NA      *        ...
  pivot_wider(names_from = Header, values_from = Present, values_fill = NA)


# now pivot so we an look at it excel!
years_as_columns <- reshaped_df %>%
  gather(Header, Present, -Year) %>%
  filter(!is.na(Present)) %>%
  spread(Year, Present, fill = NA)
write.csv(years_as_columns, "columns.csv")