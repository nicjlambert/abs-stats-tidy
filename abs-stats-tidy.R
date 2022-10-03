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
#     xlsx used to aread and write source and target data
#     dplyr used to aggregate data using functions melt and dcast

packages <- c("xlsx"
            , "tidyverse"  # A Grammar of Data Manipulation
)
              
packages.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE, repos = "https://cran.csiro.au")
      library(x, character.only = TRUE)
    }
  }
)

context <- rstudioapi::getActiveDocumentContext()
path <- normalizePath(context$'path')
setwd(dirname(path))

if (!dir.exists("./data")) {
  dir.create("./data")
}

if (!file.exists("./data/5206002_Expenditure_Volume_Measures.xlsx") ||
    !file.exists("./data/5206003_Expenditure_Current_Price.xlsx")) {
  file.create("./data/5206002_Expenditure_Volume_Measures.xlsx")
  file.create("./data/5206003_Expenditure_Current_Price.xlsx")
}

cleanAndPivot <- function(df) {
  names(df) <- df[10,]
  df <- df[-1:-10,] %>%
    rename(`Time Period` = `Series ID`) %>%
    mutate(`Time Period` = as.Date(as.numeric(`Time Period`), origin = "1899-12-30")) %>%
    pivot_longer(!`Time Period`, names_to = "Series ID", values_to = "Observation value")
}

getHeaders <- function(df) {
  names(df) <- df[7, ]
  df_headers <- df[-1:-7, c(-2, -3, -13)] %>%
    filter(if_any(everything(), ~ !str_detect(., "Commonwealth of Australia"))) %>%
    mutate(`Series Start` = as.Date(as.numeric(`Series Start`), origin = "1899-12-30")) %>%
    mutate(`Series End` = as.Date(as.numeric(`Series End`), origin = "1899-12-30"))
}

joinDataAndHeaders <- function(data, header) {
  merge(data, header, by = "Series ID", all.x = TRUE) %>%
    relocate(`Time Period`, .after = `Collection Month`) %>%
    relocate('Observation value', .after = `Time Period`) %>%
    relocate(`Data Item Description`, .before = `Series ID`) %>%
    relocate(`Series Type`, .before = `Series ID`) %>%
    mutate(`Observation value` = as.numeric(`Observation value`)) %>%
    na.exclude()
  
}

readXL <- function(sheet_nbr) {
  read.xlsx(
    file = paste0(getwd(), "/data/", file),
    sheetIndex = sheet_nbr,
    header = FALSE
  )
}

file_names <- list.files(paste0(getwd(), "/data"), pattern = "xlsx")

for (file in file_names) {
  
  base_url <-
    "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release/"
  
  download.file(
    paste0(base_url, file),
    destfile = paste0(getwd(), "/data/", file),
    mode = "wb"
  )
  
  if (file == "5206002_Expenditure_Volume_Measures.xlsx") {
    
      message(paste0("Read and tidy... ", file))
    
    df_headers <- getHeaders(readXL(sheet_nbr=1))
    df_data1 <- cleanAndPivot(readXL(sheet_nbr=2))
    df_data2 <- cleanAndPivot(readXL(sheet_nbr=3))
    df_data <- union(df_data1, df_data2)
    df_output <-sapply(joinDataAndHeaders(df_data, df_headers), as.character)
    
      message(paste0("Writing to file... ", gsub(".xlsx", "", file), ".csv"))
      
    write.table(
      df_output,
      file = paste0(
        getwd(),"/output/",gsub(".xlsx", "", file)," (R Script transformation).csv"),
      row.names = FALSE,
      dec = ".",
      sep = ";",
      quote = TRUE
    )
    
      message(paste0("Done. Refer to .../Output/", gsub(".xlsx", "", file),".csv\n"))
    
  } else {
    
    message(paste0("Read and tidy... ", file))
    
    df_headers <- getHeaders(readXL(sheet_nbr=1))
    df_data <- cleanAndPivot(readXL(sheet_nbr=2))
    df_output <- sapply(joinDataAndHeaders(df_data, df_headers), as.character)
    
      message(paste0("Writing to file... ", gsub(".xlsx", "", file), ".csv"))
    
    write.table(
      df_output,
      file = paste0(getwd(),"/output/",gsub(".xlsx", "", file)," (R Script transformation).csv"),
      row.names = FALSE,
      dec = ".",
      sep = ";",
      quote = TRUE
    )
    
      message(paste0("Done. Refer to .../output/",  gsub(".xlsx", "", file), ".csv"))
    
  }
}