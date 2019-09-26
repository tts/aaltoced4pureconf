library(tidyverse)
library(httr)
library(jsonlite)

#---------------------------------------------
# Research output metadata from Pure REST API
#---------------------------------------------

key = Sys.getenv("PUREAPIKEY")
size = 1000
offset = 0
after = "2017-01-01"
before = "2019-08-15"


do_args <- function(s, o, a, b) {
  
  list(
    size = s,
    offset = o, 
    fields = list(
      "title.value",
      "electronicVersions.doi",
      "publicationStatuses.current",
      "publicationStatuses.publicationDate.year",
      "managingOrganisationalUnit.externalId", 
      "managingOrganisationalUnit.name.text.value"
    ),
    locales = list(
      "en_GB"
    ),
    publicationStatuses = list(
      "/dk/atira/pure/researchoutput/status/published"
    ),
    publishedBeforeDate = b,
    publishedAfterDate = a,
    typeUris = list(
      "/dk/atira/pure/researchoutput/researchoutputtypes/contributiontojournal/article"
    ),
    publicationCategories = list(
      "/dk/atira/pure/researchoutput/category/scientific"
    )
  ) -> args
  
  return(args)
}



get_items <- function(s, o, a, b) {
  
  httr::POST(
    url = paste0("https://acris-test.aalto.fi/ws/api/515/research-outputs?apiKey=", key), accept("application/json"),
    encode = "json", 
    body = do_args(s, o, a, b),
    httr::verbose()
  ) -> res
  
  return(res)
  
}


result <- get_items(size, offset, after, before)
first_p <- httr::content(result, "parsed")
itemcount <- first_p$count
pages <- seq(size+offset, # because we already have the first page
             itemcount, 
             by = size) 


resultset <- sapply(pages, function(x) { 
  r <- get_items(size, x, after, before) 
  r_p <- httr::content(r, "parsed")
  r_p$items
}) 

saveRDS(resultset, "items2017-2019.RDS")

resultset <- readRDS("items2017-2019.RDS")


# https://stackoverflow.com/a/54010908
simple_rapply <- function(x, fn)
{
  if(is.list(x))
  {
    lapply(x, simple_rapply, fn)
  } else
  {
    fn(x)
  }
}    

non.null.l <- simple_rapply(resultset, function(x) if(is.null(x)) NA else x)
non.null.l_first <- simple_rapply(first_p, function(x) if(is.null(x)) NA else x)

# To do: with purrr:map but note that the last list has fewer rows than the previous ones
res_df1 <- map_df(map(non.null.l[[1]], unlist),bind_rows)
res_df2 <- map_df(map(non.null.l[[2]], unlist),bind_rows)
res_df3 <- map_df(map(non.null.l[[3]], unlist),bind_rows)
res_df4 <- map_df(map(non.null.l[[4]], unlist),bind_rows)
res_df5 <- map_df(map(non.null.l[[5]], unlist),bind_rows)

res_df_f <- map_df(map(non.null.l_first$items, unlist), bind_rows)

res_df <- rbind(res_df_f, res_df1, res_df2, res_df3, res_df4, res_df5)

names(res_df) <- c("Title", "UnitID", "Unit", "Status", "Year", "DOI")

# Nr of items w/o a DOI
nodoi <- nrow(res_df[is.na(res_df$DOI),])
# 259

#--------------------------------------------------------------------------------
# To continue 1) clean DOIs, 2) query CrossRef API 3) join result with org data
#
# For 1-2 see https://github.com/tts/aaltoced/blob/master/getdata.R
#--------------------------------------------------------------------------------

org <- readRDS("org.RDS")

items_org_rg <- inner_join(org, res_df, by = c("Research group"="Unit"))
items_org_dept <- inner_join(org, res_df, by = c("Department or research area"="Unit"))
items_org_school <- inner_join(org, res_df, by = c("School"="Unit"))
items_org_univ <- inner_join(org, res_df, by = c("University or research org"="Unit"))

items_org_raw <- rbind(items_org_rg, items_org_dept, items_org_school, items_org_univ)

