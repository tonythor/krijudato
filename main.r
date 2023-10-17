source("functions.r")
library(dplyr)

yr <- 2017:2022
raw_stack_fn <- "merged_stack_raw.csv"
wide_stack_fn <- "merged_stack_wide.csv"

raw_stack <- merge_years(yr)
write.csv(raw_stack, raw_stack_fn, row.names = FALSE)
wide_stack <- raw_stack
languages <- c("Python", "SQL", "Java", "JavaScript", "Ruby", "PHP", "C++", "Swift", "Scala", "R", "Rust", "Julia")
wide_stack <- extract_and_append_cols(wide_stack, "LanguageWorkedWith", languages)
databases <- c("MySQL", "Microsoft SQL Server", "MongoDB", "PostgreSQL", "Oracle", "IBM DB2", "Redis", "SQLite", "MariaDB")
wide_stack <- extract_and_append_cols(wide_stack,  "DatabaseWorkedWith", databases)
write.csv(wide_stack, wide_stack_fn, row.names = FALSE)


#todo : salary for 2017, it's not in dollars. 
