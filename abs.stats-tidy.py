import tempfile
import urllib.request
import pandas as pd

# URL of the Australian Bureau of Statistics (ABS) spreadsheet
url = "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/5206003_Expenditure_Current_Price.xlsx"

# Create a temporary file to download the spreadsheet
with tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx") as temp_file:
    temp_file_path = temp_file.name
    urllib.request.urlretrieve(url, temp_file_path)

# Read the data from the downloaded ABS spreadsheet
df = pd.read_excel(temp_file_path)

# Display the first few rows of the DataFrame
print(df.head())