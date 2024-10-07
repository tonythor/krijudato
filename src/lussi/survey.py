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
    # print(f"Extracting and averaging values from: {year_string}")
    # Extracting and averaging values from: 25-34 years old 
    numbers = list(map(int, re.findall(r"\d+", year_string)))
    return np.mean(numbers) if numbers else np.nan

# Function to construct URLs based on year
def construct_url(year):
    url = f"{url_prefix}y={year}/survey_results_public.csv"
    print(f"Constructed URL for {year}: {url}")
    return url



def rename_and_select(df, rename_dict, add_columns=[]):
    # Add any missing columns from add_columns with NaN values
    for col in add_columns:
        if col not in df.columns:
            print(f"Adding missing column: {col}")
            df[col] = None

    # Rename columns using the provided dictionary
    df = df.rename(columns=rename_dict)

    # Define the complete list of columns to select, including renamed and added columns
    select_cols = ["Year", "OrgSize", "Country", "Employment", "Gender", "EdLevel", "US_State", "Age", "DevType",
                   "Sexuality", "Ethnicity", "DatabaseWorkedWith", "LanguageWorkedWith", "PlatformWorkedWith", 
                   "YearsCodePro", "AnnualSalary"]

    # Add any missing columns from select_cols to the DataFrame with NaN values for consistency
    for col in select_cols:
        if col not in df.columns:
            print(f"Adding missing column for consistency: {col}")
            df[col] = None

    # Print columns before selection for debugging
    print(f"Columns before selection for year {df['Year'].unique()}: {df.columns.tolist()}")

    # Return the dataframe with only the selected columns (filtered by select_cols)
    return df[select_cols]


# Function to merge years' data
# Function to merge years' data
def merge_years(years):
    print("Starting merge process for years:", years)
    
    def process_year(year):
        print(f"Processing data for year: {year}")
        url = construct_url(year)
        print(f"Loading data for year {year} from URL...")
        try:
            df = pd.read_csv(url)  # Load the full dataset for each year
            print(f"Data for year {year} loaded successfully, shape: {df.shape}")
        except Exception as e:
            print(f"Error loading data for year {year} from {url}: {e}")
            return None

        df["Year"] = year
        print(f"Added 'Year' column to data for {year}")

        # Handle column renaming for each year
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
        elif year in [2021, 2022, 2023, 2024]:
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

        print(f"Renaming and selecting columns for year {year} with rename_dict: {rename_dict} and add_columns: {add_columns}")
        try:
            df = rename_and_select(df, rename_dict, add_columns=add_columns)
            print(f"Columns renamed and selected for {year}, shape: {df.shape}")
        except KeyError as ke:
            print(f"Error selecting columns for year {year}: {ke}")
            return None

        return df
    
    print("Processing each year individually...")
    list_of_dfs = [process_year(year) for year in years]
    print(f"Number of valid DataFrames: {len([df for df in list_of_dfs if df is not None])} out of {len(years)} years")
    
    print("Combining all years' data into a single DataFrame...")
    combined_df = pd.concat([df for df in list_of_dfs if df is not None], axis=0)
    print(f"Combined DataFrame shape: {combined_df.shape}")
    print(f"Unique years in combined DataFrame: {combined_df['Year'].unique()}")
    
    # Apply average functions for certain columns
    print("Calculating averages for YearsCodePro, OrgSize, and Age columns...")
    combined_df["YearsCodeProAvg"] = combined_df["YearsCodePro"].apply(lambda x: extract_and_average(str(x)))
    combined_df["OrgSizeAvg"] = combined_df["OrgSize"].apply(lambda x: extract_and_average(str(x)))
    combined_df["AgeAvg"] = combined_df["Age"].apply(lambda x: extract_and_average(str(x)))
    print("Averages calculated and columns added.")
    
    return combined_df

def post_build_mutations(df):
    # Ensure the 'EdLevel' column is a string for consistency in condition matching
    df["EdLevel"] = df["EdLevel"].astype(str)

    # Create a list of boolean conditions for 'EdLevel'
    conditions = [
        df["EdLevel"].str.contains("(?i)master", na=False), 
        df["EdLevel"].str.contains("(?i)associate", na=False), 
        df["EdLevel"].str.contains("(?i)bachelor", na=False), 
        df["EdLevel"].str.contains("(?i)doctoral", na=False),
        df["EdLevel"].str.contains("(?i)professional", na=False), 
        df["EdLevel"].str.contains("(?i)primary", na=False),
        df["EdLevel"].str.contains("(?i)secondary", na=False), 
        df["EdLevel"].str.contains("(?i)college", na=False),
        df["EdLevel"].str.contains("(?i)never", na=False), 
        df["EdLevel"].str.contains("(?i)else", na=False)
    ]

    # Define the corresponding choices for 'EdLevel'
    choices = [
        "Masters", "Associates", "Bachelors", "Doctorate", "Professional", 
        "Primary", "Secondary", "Some College", "No Education", "Something Else"
    ]

    # Apply the conditions to create the 'EdLevel' groups
    df["EdLevel"] = np.select(conditions, choices, default=df["EdLevel"])

    # Handle other groupings similarly, ensuring they are converted to booleans
    df["sexuality_grouped"] = np.where(
        df["Sexuality"].astype(str).str.contains("Straight / Heterosexual|Straight or heterosexual", case=False, na=False), 
        "straight", 
        np.where(
            df["Sexuality"].astype(str).str.contains("Bisexual|Gay or Lesbian|Queer|Asexual|Prefer", case=False, na=False), 
            "lgbtq", 
            np.nan
        )
    )

    df["ethnicity_grouped"] = np.where(
        df["Ethnicity"].astype(str).str.contains("White|European", case=False, na=False), 
        "non-minority", 
        np.where(
            df["Ethnicity"].isin([np.nan, "Prefer not to say", "Or, in your own words:", "I don’t know", "I prefer not to say"]), 
            np.nan, 
            "minority"
        )
    )

    # Map 'Gender' to standard categories
    df["Gender"] = np.where(df["Gender"] == "Woman", "Female", 
                            np.where(df["Gender"] == "Man", "Male", df["Gender"]))

    # Ensure Employment categories are matched correctly
    df["Employment"] = np.select(
        [
            df["Employment"].astype(str).str.contains("(?i)full", na=False), 
            df["Employment"].astype(str).str.contains("(?i)retired", na=False),
            df["Employment"].astype(str).str.contains("(?i)part", na=False), 
            df["Employment"].astype(str).str.contains("(?i)independent", na=False)
        ],
        ["Full-Time", "Retired", "Part-Time", "Self-Employed"], 
        default=df["Employment"]
    )

    # Replace "America" with "United States"
    df["Country"] = np.where(df["Country"].str.contains("(?i)america", na=False), "United States", df["Country"])

    return df


def get_stack_df(load_from_cache=True):
    # build -> # get_stack_df(persist=True, load_from_cache=False)
    persist=True
    raw_stack_fn = "merged_stack_raw.csv"
    wide_stack_fn = "merged_stack_wide.csv"
    years = list(range(2017, 2024))
    
    # Check if data should be loaded from cache
    if load_from_cache:
        if os.path.exists(wide_stack_fn):
            # Load wide file from cache
            return pd.read_csv(wide_stack_fn, low_memory=False)
        elif os.path.exists(raw_stack_fn):
            # Load raw file from cache and build wide file
            raw_stack = pd.read_csv(raw_stack_fn, low_memory=False)
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

def extract_vector_cols(df, colname, values_to_search):
    for value in values_to_search:
        # Create a cleaned column name based on the value
        new_col = re.sub(r"[^a-zA-Z0-9]", "", value.lower())

        # Use \b (word boundary) instead of look-behind/look-ahead assertions
        search_pattern = fr"\b{re.escape(value)}\b"  # Escape the value to handle special characters

        # Apply the pattern and create the new column with "yes" or "no"
        df[new_col] = df[colname].apply(lambda x: "yes" if re.search(search_pattern, str(x), re.IGNORECASE) else "no")

    return df
# Function to extract list columns
def extract_list_cols(df, colname, values_to_search):
    new_col = list(values_to_search.keys())[0]
    search_terms = values_to_search[new_col]
    
    # Instead of look-behind, use a word boundary or simpler pattern to match whole words
    search_pattern = fr"\b({'|'.join(search_terms)})\b"
    
    # Apply the new regex pattern
    df[new_col] = df[colname].apply(lambda x: "yes" if re.search(search_pattern, str(x), re.IGNORECASE) else "no")
    
    return df