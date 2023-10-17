source("functions.r")
library(dplyr)


filename <- "merged_years.csv"
if (file.exists(filename)) {
  master_df <- read.csv(filename)
} else {
  stack_df <- merge_years(2017:2022)
  write.csv(master_df, filename, row.names = FALSE)
}




languages <- c("Python", "SQL", "Java", "JavaScript", "Ruby", "PHP", "C++", "Swift", "Scala", "R", "Rust", "Julia")
stack_df <- extract_and_append_cols(stack_df, "LanguageWorkedWith", languages)

databases <- c("MySQL", "Microsoft SQL Server", "MongoDB", "PostgreSQL", "Oracle", "IBM DB2", "Redis", "SQLite", "MariaDB")
stack_df <- extract_and_append_cols( stack_df, "DatabaseWorkedWith", databases)

# platforms <- c("AWS", "Firebase", "Microsoft Azure", "Google Cloud", "Heroku")
# stack_df <- extract_and_append_cols( stack_df, "PlatformHaveWorkedWith", platforms)
