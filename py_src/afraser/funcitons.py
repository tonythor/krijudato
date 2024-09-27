import pandas as pd
import numpy as np
import re
import os

# Define URLs
url_prefix = "https://tonyfraser-data.s3.amazonaws.com/stack/"

# Define columns to select
select_cols = ["Year", "OrgSize", "Country", "Employment", "Gender", "EdLevel", "US_State", "Age", "DevType",
               "Sexuality", "Ethnicity", "DatabaseWorkedWith", "LanguageWorkedWith", "PlatformWorkedWith", 
               "YearsCodePro", "AnnualSalary"]

# Function to extract numbers and take the average
def extract_and_average(year_string):
    numbers = list(map(int, re.findall(r"\d+", year_string)))
    return np.mean(numbers) if numbers else np.nan

# Function to construct URLs based on year
def construct_url(year):
    return f"{url_prefix}y={year}/survey_results_public.csv"

# Function to rename and select columns
def rename_and_select(df, rename_dict, add_columns=None):
    df = df.rename(columns=rename_dict)
    
    if add_columns:
        for col in add_columns:
            df[col] = np.nan

    return df[select_cols]

# Function to merge years' data
def merge_years(years):
    def process_year(year):
        url = construct_url(year)
        df = pd.read_csv(url)
        df["Year"] = year
        
        if year == 2017:
            rename_dict = {
                "FormalEducation": "EdLevel",
                "CompanySize": "OrgSize",
                "DeveloperType": "DevType",
                "EmploymentStatus": "Employment",
                "HaveWorkedDatabase": "DatabaseWorkedWith",
                "HaveWorkedLanguage": "LanguageWorkedWith",
                "YearsProgram": "YearsCodePro",
                "Salary": "AnnualSalary",
                "HaveWorkedPlatform": "PlatformWorkedWith",
                "Race": "Ethnicity"
            }
            add_columns = ["Age", "US_State", "Sexuality"]
        elif year == 2018:
            rename_dict = {
                "FormalEducation": "EdLevel",
                "CompanySize": "OrgSize",
                "YearsCoding": "YearsCodePro",
                "ConvertedSalary": "AnnualSalary",
                "SexualOrientation": "Sexuality",
                "RaceEthnicity": "Ethnicity"
            }
            add_columns = ["US_State"]
        elif year in [2019, 2020]:
            rename_dict = {
                "ConvertedComp": "AnnualSalary"
            }
            add_columns = ["US_State"]
        elif year == 2021:
            rename_dict = {
                "ConvertedCompYearly": "AnnualSalary",
                "LanguageHaveWorkedWith": "LanguageWorkedWith",
                "DatabaseHaveWorkedWith": "DatabaseWorkedWith",
                "PlatformHaveWorkedWith": "PlatformWorkedWith"
            }
            add_columns = []
        elif year == 2022:
            rename_dict = {
                "ConvertedCompYearly": "AnnualSalary",
                "LanguageHaveWorkedWith": "LanguageWorkedWith",
                "DatabaseHaveWorkedWith": "DatabaseWorkedWith",
                "PlatformHaveWorkedWith": "PlatformWorkedWith"
            }
            add_columns = ["US_State"]
        else:
            rename_dict = {}
            add_columns = []
        
        df = rename_and_select(df, rename_dict, add_columns=add_columns)
        return df
    
    list_of_dfs = [process_year(year) for year in years]
    combined_df = pd.concat(list_of_dfs, axis=0)
    
    # Apply average functions for certain columns
    combined_df["YearsCodeProAvg"] = combined_df["YearsCodePro"].apply(lambda x: extract_and_average(str(x)))
    combined_df["OrgSizeAvg"] = combined_df["OrgSize"].apply(lambda x: extract_and_average(str(x)))
    combined_df["AgeAvg"] = combined_df["Age"].apply(lambda x: extract_and_average(str(x)))
    
    return combined_df

# Function to extract vector columns from lists
def extract_vector_cols(df, colname, values_to_search):
    for value in values_to_search:
        new_col = re.sub(r"[^a-zA-Z0-9]", "", value.lower())
        search_pattern = fr"(?<=^|,|;|\s){value}(?=$|,|;|\s)"
        df[new_col] = df[colname].apply(lambda x: "yes" if re.search(search_pattern, str(x), re.IGNORECASE) else "no")
    return df

# Function to extract list columns
def extract_list_cols(df, colname, values_to_search):
    new_col = list(values_to_search.keys())[0]
    search_terms = values_to_search[new_col]
    
    search_pattern = fr"(?<=^|,|;|\s)({'|'.join(search_terms)})(?=$|,|;|\s)"
    df[new_col] = df[colname].apply(lambda x: "yes" if re.search(search_pattern, str(x), re.IGNORECASE) else "no")
    
    return df

# Function to perform post-build mutations
def post_build_mutations(df):
    df["sexuality_grouped"] = np.where(df["Sexuality"].str.contains("Straight / Heterosexual|Straight or heterosexual", 
                                                                    case=False, na=False), "straight", 
                                       np.where(df["Sexuality"].str.contains("Bisexual|Gay or Lesbian|Queer|Asexual|Prefer", 
                                                                             case=False, na=False), "lgbtq", np.nan))
    
    df["ethnicity_grouped"] = np.where(df["Ethnicity"].str.contains("White|European", case=False, na=False), 
                                       "non-minority", 
                                       np.where(df["Ethnicity"].isin([np.nan, "Prefer not to say", 
                                                                      "Or, in your own words:", 
                                                                      "I don’t know", "I prefer not to say"]), 
                                                np.nan, "minority"))
    
    df["Gender"] = np.where(df["Gender"] == "Woman", "Female", 
                            np.where(df["Gender"] == "Man", "Male", df["Gender"]))
    
    df["EdLevel"] = np.select(
        [df["EdLevel"].str.contains("(?i)master"), df["EdLevel"].str.contains("(?i)associate"), 
         df["EdLevel"].str.contains("(?i)bachelor"), df["EdLevel"].str.contains("(?i)doctoral"),
         df["EdLevel"].str.contains("(?i)professional"), df["EdLevel"].str.contains("(?i)primary"),
         df["EdLevel"].str.contains("(?i)secondary"), df["EdLevel"].str.contains("(?i)college"),
         df["EdLevel"].str.contains("(?i)never"), df["EdLevel"].str.contains("(?i)else")],
        ["Masters", "Associates", "Bachelors", "Doctorate", "Professional", "Primary", "Secondary", 
         "Some College", "No Education", "Something Else"], 
        default=df["EdLevel"])
    
    df["Employment"] = np.select(
        [df["Employment"].str.contains("(?i)full"), df["Employment"].str.contains("(?i)retired"),
         df["Employment"].str.contains("(?i)part"), df["Employment"].str.contains("(?i)independent")],
        ["Full-Time", "Retired", "Part-Time", "Self-Employed"], 
        default=df["Employment"])
    
    df["Country"] = np.where(df["Country"].str.contains("(?i)america", na=False), "United States", df["Country"])
    
    return df

# Function to load or merge data and apply transformations
# Function to load or merge data and apply transformations
def get_stack_df(persist=True, load_from_cache=True):
    raw_stack_fn = "merged_stack_raw.csv"
    wide_stack_fn = "merged_stack_wide.csv"
    
    years = list(range(2017, 2022+1))
    
    # Check if data should be loaded from cache
    if load_from_cache:
        if os.path.exists(wide_stack_fn):
            # Load wide file from cache
            return pd.read_csv(wide_stack_fn)
        elif os.path.exists(raw_stack_fn):
            # Load raw file from cache and build wide file
            raw_stack = pd.read_csv(raw_stack_fn)
        else:
            print("No cache files found. Generating raw and wide files...")
            raw_stack = merge_years(years)
    else:
        raw_stack = merge_years(years)
    
    # Save the raw data to CSV if persist is True
    if persist:
        raw_stack.to_csv(raw_stack_fn, index=False)
    
    wide_stack = raw_stack
    
    # Process specific columns like languages, databases, platforms, etc.
    languages = ["Python", "SQL", "Java", "JavaScript", "Ruby", "PHP", "C++", "Swift", "Scala", "R", "Rust", "Julia"]
    wide_stack = extract_vector_cols(wide_stack, "LanguageWorkedWith", languages)
    
    databases = ["MySQL", "Microsoft SQL Server", "MongoDB", "PostgreSQL", "Oracle", "IBM DB2", "Redis", "SQLite", "MariaDB"]
    wide_stack = extract_vector_cols(wide_stack, "DatabaseWorkedWith", databases)
    
    platforms = ["Microsoft Azure", "Google Cloud", "IBM Cloud or Watson", "Kubernetes", "Linux", "Windows"]
    wide_stack = extract_vector_cols(wide_stack, "PlatformWorkedWith", platforms)
    
    # Process AWS-related platforms
    aws_entries = {"aws": ["AWS", "aws", "Amazon Web Services", "Amazon Web Services (AWS)"]}
    wide_stack = post_build_mutations(wide_stack)
    wide_stack = extract_list_cols(wide_stack, "PlatformWorkedWith", aws_entries)
    
    # Save the wide data to CSV if persist is True
    if persist:
        wide_stack.to_csv(wide_stack_fn, index=False)
    
    return wide_stack