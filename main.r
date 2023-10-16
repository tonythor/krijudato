# Usage
source("functions.r")
library(dplyr)


master_df <- merge_years(2017:2022, "https://tonyfraser-data.s3.amazonaws.com/stack/")
write.csv(master_df, "cleansed_and_merged.csv")



