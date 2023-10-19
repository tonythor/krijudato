source("functions.r")
library(dplyr)

wide_df <- get_stack_df(persist = TRUE, load_from_cache = TRUE)

#todo : salary for 2017, it's not in dollars.
