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


# create new data frame with the columns we want to use
project_df <- final_df %>%
  select(ResponseID, MainBranch, Employment, EdLevel, DevType, Country, 
         Currency, ConvertedCompYearly, LanguageHaveWorkedWith, 
         DatabaseHaveWorkedWith, OpSysProfessional.use, Age, Gender) %>%
  as.data.frame()


## rename the items in the MainBranch column
# rename any developer to "developer", even if it is not their primary profession (they identify as a developer)
project_df$MainBranch[project_df$MainBranch == "I am a developer by profession"] <- "developer"
project_df$MainBranch[project_df$MainBranch == "I am not primarily a developer, but I write code sometimes as part of my work"] <- "developer"
project_df$MainBranch[project_df$MainBranch == "I used to be a developer by profession, but no longer am"] <- "developer"
# rename to hobbyist
project_df$MainBranch[project_df$MainBranch == "I code primarily as a hobby"] <- "hobbyist"
# rename to student if learning
project_df$MainBranch[project_df$MainBranch == "I am learning to code"] <- "student"
# rename to none
project_df$MainBranch[project_df$MainBranch == "None of these"] <- "none"

## rename the items in the Employment column
project_df <- project_df %>%
  mutate(Employment = case_when(
    Employment %in% c("Employed, full-time", "Employed, full-time;Independent contractor, freelancer, or self-employed",
                      "Employed, full-time;Student, part-time", "Employed, full-time;Student, full-time") ~ "fulltime",
    Employment %in% c("Employed, part-time", "Student, part-time;Employed, part-time") ~ "parttime",
    Employment %in% c("Student, full-time", "Student, part-time", "Student, full-time;Employed, part-time",
                      "Student, full-time;Independent contractor, freelancer, or self-employed",
                      "Student, part-time;Independent contractor, freelancer, or self-employed",
                      "Student, full-time;Not employed, but looking for work",
                      "Student, full-time;Not employed, and not looking for work") ~ "student",
    Employment %in% c("Not employed, but looking for work", "Not employed, and not looking for work") ~ "unemployed",
    Employment == "Independent contractor, freelancer, or self-employed" ~ "selfemployed",
    Employment == "I prefer not to say" ~ NA_character_,
    TRUE ~ Employment
  ))

## rename the items in the EdLevel (Education Level) column
# phd 
project_df$EdLevel[grepl("doctoral", project_df$EdLevel)] <- "doctorate"
# JD or MD
project_df$EdLevel[grepl("Professional degree", project_df$EdLevel)] <- "JDMD"
# Masters
project_df$EdLevel[grepl("Master", project_df$EdLevel)] <- "masters"
# Bachelors
project_df$EdLevel[grepl("Bachelor", project_df$EdLevel)] <- "bachelors"
# Associates
project_df$EdLevel[grepl("Associate", project_df$EdLevel)] <- "associates"
# Others
project_df$EdLevel[grepl("something else", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("Some", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("Secondary", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("primary", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("elementary", project_df$EdLevel)] <- "other"

## rename the items in the DevType (developer type) column

## create columns for languages - I think we should use: Python, Java, JavaScript, 
# Ruby, PHP, C++, Swift, SQL, Scala, R, Rust, Julia

project_df <- project_df %>%
  # python - yes or no
  mutate(python = ifelse(grepl("Python", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # SQL - yes or no
  mutate(sql = ifelse(grepl("SQL", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Java - yes or no
  mutate(java = ifelse(grepl("Java", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # JavaScript - yes or no
  mutate(javascript = ifelse(grepl("JavaScript", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Ruby - yes or no
  mutate(ruby = ifelse(grepl("Ruby", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # PHP - yes or no
  mutate(php = ifelse(grepl("PHP", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # C++ - yes or no
  mutate(cplusplus = ifelse(grepl("C\\+\\+", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Swift - yes or no
  mutate(swift = ifelse(grepl("Swift", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Scala - yes or no
  mutate(scala = ifelse(grepl("Scala", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # R - yes or no
  mutate(r = ifelse(grepl(";R;", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Rust - yes or no
  mutate(rust = ifelse(grepl("Rust", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Julia - yes or no
  mutate(julia = ifelse(grepl("Julia", LanguageHaveWorkedWith, ignore.case = TRUE), "yes", "no"))
  
## create columns for databases - I think we should use MongoDB, MySQL, PostgreSQL, Oracle, Microsoft SQL Server,
# IBM db2, Redis, SQLite, MariaDB
project_df <- project_df %>%
  # MySQL
  mutate(mysql = ifelse(grepl("MySQL", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Microsoft SQL Server
  mutate(microsoftsqlserver = ifelse(grepl("Microsoft SQL Server", 
                                           DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # MongoDB 
  mutate(mongo = ifelse(grepl("MongoDB", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # PostgreSQL
  mutate(postgresql = ifelse(grepl("PostgreSQL", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Oracle
  mutate(oracle = ifelse(grepl("Oracle", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # IBM Db2
  mutate(ibmdb2 = ifelse(grepl("IBM DB2", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # Redis
  mutate(redis = ifelse(grepl("Redis", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # SQLite
  mutate(sqlite = ifelse(grepl("SQLite", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) %>%
  # MariaDB
  mutate(maria = ifelse(grepl("MariaDB", DatabaseHaveWorkedWith, ignore.case = TRUE), "yes", "no")) 

# remove original language and database "worked with" columns
project_df <- project_df %>%
  select(ResponseID, MainBranch, Employment, EdLevel, DevType, Country, 
         Currency, ConvertedCompYearly, python, sql, java, javascript, 
         ruby, php, cplusplus, swift, scala, r, rust, julia, 
         mysql, microsoftsqlserver, mongo, postgresql, oracle,
         ibmdb2, redis, sqlite, maria, 
         OpSysProfessional.use, Age, Gender) %>%
  as.data.frame()