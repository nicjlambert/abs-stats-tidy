import tempfile
import urllib.request
import pandas as pd

# URL of the Australian Bureau of Statistics (ABS) spreadsheet
url = "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/5206003_Expenditure_Current_Price.xlsx"

# Create a temporary file to download the spreadsheet
with tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx") as temp_file:
    temp_file_path = temp_file.name
    urllib.request.urlretrieve(url, temp_file_path)

# function to read an excel file and take as an argument the sheet number
def readXL(temp_file_path, sheet_nbr, header):
    return pd.read_excel(temp_file_path, sheet_name = sheet_nbr, header = header)

df_headers = readXL(temp_file_path, 0, header = 9)
df_data1 = readXL(temp_file_path, 1, header = 9)

def clean_data(df):
    df = df.rename(columns={"Series ID": "Time Period"})
    df = df.melt(id_vars=["Time Period"], var_name="Series ID", value_name="Observation Value")
    return df

def clean_headers(df):
    df = df.dropna(axis=0, how="all")
    df = df[~df['Data Item Description'].str.contains('© Commonwealth of Australia', na=False)]
    df = df.dropna(axis=1, how='all')
  
    return df

df_headers = clean_headers(df_headers)
df_data1 = clean_data(df_data1)

print(df_data1.head())
print(df_headers.tail())