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
packages <- c("xlsx", "dplyr", "stringr", "readxl", "tidyr")

lapply(packages, function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE, repos = "https://cran.csiro.au")
    library(x, character.only = TRUE)
  }
})

readXL <- function(file, sheet_nbr, start_row) {
  read.xlsx(
    file = tf,
    startRow = start_row, 
    sheetIndex = sheet_nbr,
    header = TRUE
  )
}

clean_pivot <- function(df) {
  df %>%
    rename(Time.Period = Series.ID) %>%
    mutate(Time.Period = as.Date(as.numeric(Time.Period), origin = "1899-12-30")) %>%
    pivot_longer(!Time.Period, names_to = "Series.ID", values_to = "Observation.Value")
}

getHeaders <- function(df) {
  df %>%
    filter(if_any(everything(), ~ !str_detect(., "Commonwealth of Australia"))) %>%
    mutate(across(c(Series.Start, Series.End), ~ as.Date(as.numeric(.), origin = "1899-12-30")))
}

joinDataAndHeaders <- function(data, header) {
  merge(df_data, df_headers, by = "Series.ID", all.x = TRUE) %>%
    relocate(Time.Period, .after = Collection.Month) %>%
    relocate("Observation.Value", .after = Time.Period) %>%
    relocate(Data.Item.Description, .before = Series.ID) %>%
    relocate(Series.Type, .before = Series.ID) %>%
    mutate(Observation.Value = as.numeric(Observation.Value)) %>%
    select(where(~!all(is.na(.))))
}

file_names <- list("5206002_Expenditure_Volume_Measures.xlsx", "5206003_Expenditure_Current_Price.xlsx")

base_url <- "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/"

tf <- tempfile(fileext="xlsx")

for (file in file_names) {
  download.file(
    paste0(base_url, file),
    destfile = tf,
    mode = "wb"
  )
  
  message(paste0("Read and tidy... ", file))
  df_headers <- getHeaders(readXL(file, sheet_nbr = 1, start_row = 9))
  df_data <- clean_pivot(readXL(file, sheet_nbr = 2, start_row = 10))
  
  if (file == "5206003_Expenditure_Current_Price.xlsx") {
    df_data2 <- clean_pivot(readXL(file, sheet_nbr = 3, start_row = 10))
    df_data <- bind_rows(df_data, df_data2)
  }
  
  combined_data <- joinDataAndHeaders(df_data, df_headers)
  
  # Save the combined data if needed
  write.csv(combined_data, paste0("cleaned_", file, ".csv"), row.names = FALSE)
}