library(httr)
library(tidyverse)

#---------------------------------------------
# Active organisatinal units from Pure REST API
#---------------------------------------------

endpoint <- "https://acris-test.aalto.fi/ws/api/515/organisational-units/active?"
size <- "300"
fields <- "name.text.value,parents.parent.name.text"
locale <- "en_GB"
key <- Sys.getenv("PUREAPIKEY")

query <- paste0(endpoint, "size=", size, "&locale=", locale, "&fields=", fields, "&apiKey=", key)
con <- httr::GET(query, add_headers(Accept = "application/xml"))

doc <- xml2::read_xml(con)

units <- xml2::xml_find_all(doc, "//organisationalUnit")

units_raw <- tibble::tibble(
  child = xml2::xml_text(xml2::xml_find_all(units, "name/text")),
  parent = xml2::xml_text(xml2::xml_find_first(units, "parents/parent/name/text"))
)

units_df <- units_raw %>% 
  filter(!is.na(parent) | is.na(parent) & child == "Aalto University")

#-------------------
# Build hierarchy
#-------------------
h <- inner_join(units_df, units_df, by = c("child"="parent"))

# The only exception is the Signal processing RG, which has a child RG. Ignoring the child here.
h1 <- h %>% 
  mutate(`Research group` = ifelse(substr(child, 1, 6) == 'Depart' | substr(child, 1, 6) == 'Centre', child.y, 
                                   ifelse(substr(child, 1, 6) == 'Signal', child, '-')),
         `Department or research area` = ifelse(parent == 'Aalto University', child.y, 
                                                ifelse(substr(child, 1, 6) == 'Signal', parent, child)),
         School = ifelse(`Research group` == '-', child, 
                         ifelse(substr(child, 1, 6) == 'Signal', 'School of Electrical Engineering', parent)),
         `University or research org` = ifelse(substr(parent, 1, 6) == 'Centre' | substr(parent, 1, 6) == 'Resear', 'Research organisation', 'Aalto University')) %>% 
  select(-child, -parent, -child.y)

h1 <- distinct(h1, `Research group`, `Department or research area`, School, `University or research org`, .keep_all = TRUE)

# Top level
org <- h1 %>% 
  mutate(School = ifelse(School == 'Aalto University', 'University level', School),
         `University or research org` = ifelse(School == 'University level', 'Aalto University', `University or research org`))

saveRDS(org, "org.RDS")
