import tempfile
import urllib.request
import pandas as pd
from urllib.parse import urlparse
import os

# URL of the Australian Bureau of Statistics (ABS) spreadsheet

urls = [
    "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/5206003_Expenditure_Current_Price.xlsx",
    "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/5206002_Expenditure_Volume_Measures.xlsx"
]

# function to read an excel file and take as an argument the sheet number
def readXL(temp_file_path, sheet_nbr, header):
    return pd.read_excel(temp_file_path, sheet_name = sheet_nbr, header = header)

# function to clean the data
def clean_data(df):
    df = (df.rename(columns={"Series ID": "Time Period"})
            .melt(id_vars=["Time Period"], var_name="Series ID", value_name="Observation Value"))
    return df

# function to clean the headers
def clean_headers(df):
    df = (df.dropna(axis=0, how="all")
            .loc[~df['Data Item Description'].str.contains('© Commonwealth of Australia', na=False)]
            .dropna(axis=1, how='all'))
    return df

iteration = 0

for url in urls:
    print(f"Downloading... {url}")

    parsed_uri = urlparse(url)
    file_name = os.path.basename(parsed_uri.path)

    with tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx") as temp_file:
        temp_file_path = temp_file.name
        urllib.request.urlretrieve(url, temp_file_path)

    df_headers = readXL(temp_file_path, 0, header=9)
    df = readXL(temp_file_path, 1, header=9)
    
    if iteration == 1:

        df_2 = readXL(temp_file_path, 2, header=9)
        df = pd.concat([df, df_2])    
    
    iteration += 1

    print(f"Applying transformations... {file_name}")
    df_headers = clean_headers(df_headers)
    df = clean_data(df)
    df = pd.merge(df_headers, df, on='Series ID', how='inner')
    print("Done!")