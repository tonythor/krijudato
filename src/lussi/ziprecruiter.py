import os
import time
import pandas as pd
from selenium import webdriver
from bs4 import BeautifulSoup

# Define the file name at the top of the file
ZIP_FILENAME = 'combined_salaries.csv'

# Base URL for the salary data
BASE_URL = "https://www.ziprecruiter.com/Salaries/What-Is-the-Average-"

def extract_salary_table(url, job_title):
    """
    Extract the salary table from a given ZipRecruiter URL.
    
    Parameters:
    url (str): The URL to scrape the salary data from.
    job_title (str): The job title for which the salary data is being scraped.
    
    Returns:
    pd.DataFrame: DataFrame containing the salary data for the given job title.
    
    Raises:
    Exception: If no salary table is found on the page.
    """
    # Set up Selenium WebDriver
    driver = webdriver.Chrome()  # Make sure ChromeDriver is installed and accessible
    driver.get(url)
    
    # Allow time for the page to load
    time.sleep(5)
    
    # Parse the page content using BeautifulSoup
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    table = soup.find('table')

    if not table:
        driver.quit()
        raise Exception(f"No table found on the page: {url}")
    
    # Extract table headers and rows
    headers = [header.text.strip() for header in table.find_all('th')]
    rows = [
        [col.text.strip() for col in row.find_all('td')]
        for row in table.find_all('tr')[1:]  # Skip header row
    ]

    # Create DataFrame and add a 'Job Title' column
    df = pd.DataFrame(rows, columns=headers)
    df['Job Title'] = job_title
    
    # Close the WebDriver
    driver.quit()
    return df

def load_zip(data_dir: str):
    """
    Load the CSV file from the specified data directory if it exists; otherwise, raise an error.
    
    Parameters:
    data_dir (str): The directory where the data files are stored.
    
    Returns:
    pd.DataFrame: The loaded DataFrame.
    
    Raises:
    FileNotFoundError: If the file does not exist.
    """
    zip_filename = os.path.join(data_dir, ZIP_FILENAME)
    if os.path.exists(zip_filename):
        print(f"Loading data from {zip_filename}")
        return pd.read_csv(zip_filename)
    else:
        raise FileNotFoundError(f"The file '{zip_filename}' does not exist.")

def process_job_urls(job_urls):
    """
    Process a list of job URLs to extract salary data for multiple job titles.
    
    Parameters:
    job_urls (list): List of tuples containing (URL suffix, job title).
    
    Returns:
    pd.DataFrame: Combined DataFrame of all extracted data.
    """
    dfs = []
    for url_suffix, job_title in job_urls:
        full_url = BASE_URL + url_suffix
        try:
            df = extract_salary_table(full_url, job_title)
            dfs.append(df)
            print(f"Successfully extracted data for {job_title}")
        except Exception as e:
            print(f"Failed to extract data for {job_title}: {e}")
    
    if dfs:
        # Concatenate all DataFrames into one combined DataFrame
        return pd.concat(dfs, ignore_index=True)
    else:
        print("No data was extracted.")
        return pd.DataFrame()


def build_zip(data_dir: str):
    """
    Build the salary data file by downloading data from the provided job URLs
    and saving it to a CSV file in the specified data directory.
    
    Parameters:
    data_dir (str): The directory where the data files should be saved.
    """
    # Ensure the data directory exists
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        print(f"Created directory: {data_dir}")

    zip_filename = os.path.join(data_dir, 'combined_salaries.csv')

    # List of job URL suffixes and corresponding job titles
    job_urls = [
        ("DATA-Scientist-Salary-by-State", "Data Scientist"),
        ("Data-Engineer-Salary-by-State", "Data Engineer"),
        ("Data-Analyst-Salary-by-State", "Data Analyst"),
        ("Machine-Learning-Engineer-Salary-by-State", "Machine Learning Engineer"),
        ("Quantitative-Analyst-Salary-by-State", "Quantitative Analyst"),
        ("BIG-DATA-Engineer-Salary-by-State", "Big Data Engineer"),
        ("Statistician-Salary-by-State", "Statistician")
    ]
    
    # Process the job URLs and extract salary data
    df_combined = process_job_urls(job_urls)
    
    # Save the combined DataFrame if data was successfully extracted
    if not df_combined.empty:
        df_combined.to_csv(zip_filename, index=False)
        print(f"Combined data saved to {zip_filename}")
    else:
        print("No data to save.")