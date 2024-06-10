# Create one R script called src-tidy-ABS-tbl-2-3.R that does the following.
#
# (0) Downloads and spreadsheets Australian Bureau of Statistics (ABS)
# (1) Merges the Index and the Data sheets to create one dataset.
# (2) Extracts only the measurements on the mean and standard deviation
#     for each measurement.
# (3) Uses descriptive activity names to name the activities in the dataset
# (4) Appropriately labels the dataset with descriptive variable names.
# (5) From the data set in step 4, creates a second, independent tidy dataset
#
# xlsx used to aread and write source and target data
# dplyr used to aggregate data using functions melt and dcast

# Load necessary libraries
packages <- c("readxl", "dplyr", "stringr", "tidyr", "httr")

lapply(packages, function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE, repos = "https://cran.csiro.au")
    library(x, character.only = TRUE)
  }
})

# URLs of the Australian Bureau of Statistics (ABS) spreadsheet
urls <- c(
  "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/5206003_Expenditure_Current_Price.xlsx",
  "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/5206002_Expenditure_Volume_Measures.xlsx"
)

# Function to read an Excel file and take the sheet number as an argument
readXL <- function(temp_file_path, sheet_nbr, header) {
  read_excel(temp_file_path, sheet = sheet_nbr, skip = header)
}

# Function to clean the data
clean_data <- function(df) {
  df %>%
    rename(`Time Period` = `Series ID`) %>%
    pivot_longer(cols = -c(`Time Period`), names_to = "Series ID", values_to = "Observation Value")
}

# Function to clean the headers
clean_headers <- function(df) {
  df %>%
    filter(!str_detect(`Data Item Description`, '© Commonwealth of Australia')) %>%
    select(where(~ !all(is.na(.))))
}

iteration <- 0

for (url in urls) {
  print(paste("Downloading...", url))
  
  file_name <- basename(url)
  temp_file_path <- tempfile(fileext = ".xlsx")
  GET(url, write_disk(temp_file_path, overwrite = TRUE))
  
  df_headers <- readXL(temp_file_path, 1, 9)
  df <- readXL(temp_file_path, 2, 9)
  
  if (iteration == 1) {
    df_2 <- readXL(temp_file_path, 3, 9)
    df <- bind_rows(df, df_2)
  }
  
  iteration <- iteration + 1
  
  print(paste("Applying transformations...", file_name))
  df_headers <- clean_headers(df_headers)
  df <- clean_data(df)
  df <- inner_join(df_headers, df, by = 'Series ID')
  write.csv(df, file_name)
  print("Done!")
}