
source("admin_functions.r")

url_prefix <- "https://tonyfraser-data.s3.amazonaws.com/"
year_list <- c(2022, 2021, 2020, 2019, 2018, 2017)

column_samples <- extract_samples(year_list, url_prefix)
write.csv(column_samples, "column_samples.csv")

column_overlap_summary <- extract_column_summary(year_list, url_prefix)
write.csv(column_overlap_summary, "column_overlap_summary.csv")