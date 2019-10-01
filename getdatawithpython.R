library(reticulate)

use_python("/usr/bin/python3", required=TRUE)
  
source_python("getdata.py")

data <- get_data()
