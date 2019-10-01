library(reticulate)

source_python("getdata.py")

data <- get_data()
