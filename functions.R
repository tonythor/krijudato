library("tidyverse")
library(dplyr)
# years <- c(2017, 2018, 2019, 2020, 2021, 2022)

years <- c( 2022)
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
  select(MainBranch, Employment, EdLevel, DevType, Country, 
         Currency, CompTotal, CompFreq, LanguageHaveWorkedWith, 
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

## rename the items in the Masters column
# phd 
project_df$EdLevel[grepl("doctoral", project_df$EdLevel)] <- "doctorate"
# JD or MD
project_df$EdLevel[grepl("Professional degree", project_df$EdLevel)] <- "JDMD"
# Masters
project_df$EdLevel[grepl("Master", project_df$EdLevel)] <- "masters"
# Bachelros
project_df$EdLevel[grepl("Bachelor", project_df$EdLevel)] <- "bachelors"
# Associates
project_df$EdLevel[grepl("Associate", project_df$EdLevel)] <- "associates"
# Others
project_df$EdLevel[grepl("something else", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("Some", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("Secondary", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("primary", project_df$EdLevel)] <- "other"
project_df$EdLevel[grepl("elementary", project_df$EdLevel)] <- "other"

