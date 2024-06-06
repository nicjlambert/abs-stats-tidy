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

# Load required packages
packages <- c("xlsx", "dplyr", "stringr", "readxl", "tidyr")

# Check and install missing packages
lapply(packages, function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE, repos = "https://cran.csiro.au")
    library(x, character.only = TRUE)
  }
})

# Function to read Excel sheets
readXL <- function(file, sheet_nbr, start_row) {
  read.xlsx(
    file = paste0(getwd(), "/data/", file),
    startRow = start_row, 
    sheetIndex = sheet_nbr,
    header = TRUE
  )
}

# Function to clean and pivot the data
clean_pivot <- function(df) {
  df %>%
    rename(Time.Period = Series.ID) %>%
    mutate(Time.Period = as.Date(as.numeric(Time.Period), origin = "1899-12-30")) %>%
    pivot_longer(!Time.Period, names_to = "Series.ID", values_to = "Observation.Value")
}

# Function to clean and format headers
getHeaders <- function(df) {
  df %>%
    filter(if_any(everything(), ~ !str_detect(., "Commonwealth of Australia"))) %>%
    mutate(Series.Start = as.Date(as.numeric(Series.Start), origin = "1899-12-30")) %>%
    mutate(Series.End = as.Date(as.numeric(Series.End), origin = "1899-12-30"))
}

# Function to join data and headers
joinDataAndHeaders <- function(data, header) {
  merge(data, header, by = "Series.ID", all.x = TRUE) %>%
    relocate(Time.Period, .after = Collection.Month) %>%
    relocate("Observation.Value", .after = Time.Period) %>%
    relocate(Data.Item.Description, .before = Series.ID) %>%
    relocate(Series.Type, .before = Series.ID) %>%
    mutate(Observation.Value = as.numeric(Observation.Value)) %>%
    na.exclude()
}

# File names to download
file_names <- list("5206002_Expenditure_Volume_Measures.xlsx", "5206003_Expenditure_Current_Price.xlsx")

# Base URL for downloading files
base_url <- "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/"

# Download files and process data
for (file in file_names) {
  download.file(
    paste0(base_url, file),
    destfile = paste0(getwd(), "/data/", file),
    mode = "wb"
  )

  if (file == "5206002_Expenditure_Volume_Measures.xlsx") {
    message(paste0("Read and tidy... ", file))
    df_headers <- getHeaders(readXL(file, sheet_nbr = 1, start_row = 9))
    df_data <- clean_pivot(readXL(file, sheet_nbr = 2, start_row = 10))
    combined_data <- joinDataAndHeaders(df_data, df_headers)
  }
}

# Extract only the measurements on the mean and standard deviation for each measurement
tidy_data <- combined_data %>%
  filter(str_detect(Data.Item.Description, "mean|standard deviation"))

# Create a second, independent tidy dataset
tidy_dataset <- tidy_data %>%
  group_by(Data.Item.Description, Series.Type) %>%
  summarize(Average = mean(Observation.Value, na.rm = TRUE), SD = sd(Observation.Value, na.rm = TRUE))

# Write the final tidy dataset to an Excel file
write.xlsx(tidy_dataset, file = "tidy_dataset.xlsx", sheetName = "Tidy Data", row.names = FALSE)