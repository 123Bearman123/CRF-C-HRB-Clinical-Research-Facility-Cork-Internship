# This script enables you to retrieve survey information
# from Castor through R and display it as a tidy rectangular data frame

# Please enter relavent information here before running this script
study_id <- "" 
your_key <- ""
your_secret <- ""


# Packages #
library('httr')
library('stringr')
library('glue') 
library('jsonlite') 
library('tidyverse')
library('janitor')
library('castoRedc')
library('lubridate')

# Login
castoRedc::CastorData
url <-  "https://data.castoredc.com/"
castor_api <- CastorData$new(key = your_key, secret = your_secret,base_url = url)

# Inofrmation needed for api commands
app <- oauth_app(
  "example-test",
  key = "2CB18ACF-C2E7-4FA2-ADA1-8C0655F2DDF3",
  secret = "da4e4c2e39b1c6ae82b1c8428247d43d"
)
api <- oauth_endpoint(
  request = NULL,
  authorize = "oauth/authorize",
  access = "oauth/token",
  base_url = url
)
token <- oauth2.0_token(
  app = app,
  endpoint = api,
  client_credentials = TRUE,
  cache = FALSE
)  

# field retrieves a dataframe with every variable possible in a survey and
# fieldv2 takes that dataframe and deltes irelavent inofrmation
field <- castor_api$getFieldInfo(study_id)
fieldv2 <- subset (field, select = -c(id, parent_id, field_number, field_label, field_type:option_group.fields))

### Rerives patient ansers to the survey for all surveys but in an untidy way
incomplete_info <- GET(url = url, path = glue("api/study/{study_id}/data-point-collection/survey-instance"),
         query = list(page_size = 5000),
         config(token = token))
complete_untidy <- fromJSON(content(incomplete_info, as = "text", encoding = "UTF-8"))$`_embedded`$items

# Seperates the updated on column to retain the date and delete the time
Hourss <- format(as.POSIXct(strptime(complete_untidy$updated_on,"%Y-%m-%d %H:%M:%S",tz="")) ,format = "%H:%M:%S")
Datess <- format(as.POSIXct(strptime(complete_untidy$updated_on,"%Y-%m-%d %H:%M:%S",tz="")) ,format = "%Y-%m-%d")
complete_untidy$Datess <- Datess
complete_untidy$Hourss <- Hourss
complete_untidy_deleted <- subset (complete_untidy, select = -c(updated_on, Hourss))

# Merges the two dataframes by field id and deletes irelevent information
merged_dataframe = merge(complete_untidy_deleted, fieldv2, by= "field_id", all=TRUE)
merged_dataframev2 = merged_dataframe %>% drop_na()
merged_dataframev3 <- subset (merged_dataframev2, select = -field_id)

# Change it into a wider dataset for visibility
merged_dataframev4 <- merged_dataframev3%>% 
  pivot_wider(values_from = field_value, names_from = field_variable_name)
view(merged_dataframev4)
