source("functions.r")
library(dplyr)


filename <- "cleansed_and_merged.csv"

if (file.exists(filename)) {
  master_df <- read.csv(filename)
} else {
  master_df <- merge_years(2017:2022, "https://tonyfraser-data.s3.amazonaws.com/stack/")
  write.csv(master_df, filename)
}


languages <- c("Python", "SQL", "Java", "JavaScript", "Ruby", "PHP", "C++", "Swift", "Scala", "R", "Rust", "Julia")
project_df <- extract_and_append_cols(project_df, "LanguageHaveWorkedWith", languages)

databases <- c("MySQL", "Microsoft SQL Server", "MongoDB", "PostgreSQL", "Oracle", "IBM DB2", "Redis", "SQLite", "MariaDB")
project_df <- extract_and_append_cols(project_df, "DatabaseHaveWorkedWith", databases)

platforms <- c("AWS", "Firebase", "Microsoft Azure", "Google Cloud", "Heroku")
project_df <- extract_and_append_cols(project_df, "PlatformHaveWorkedWith", platforms)
