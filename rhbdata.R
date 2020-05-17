# Retrieve book data from Penguin Random House Books api

library(httr)
library(jsonlite)

rhburl = "https://reststop.randomhouse.com/resources/titles"
num_rows = 15000
rhb_start = 0
rhb_num = 99 #cannot be greater than 100
date_min = "01/05/2010"
date_max = "12/31/2019"

rhb_qparams = list(start = rhb_start, max = rhb_num, expandLevel=1, format = "HC", onsaleStart = date_min, onsaleEnd = date_max)
keep_vars = c("agerangecode", "subjectcategory1", "onsaledate", "pages", "priceusa", "isbn", "author", "division")
auth = authenticate("testuser", "testpassword", type = "basic")

#call rhb api to retrieve book data (api returns max of 100 rows per call)
rhb_interval = rhb_num + 1
while (rhb_qparams['start'] < num_rows){
  rhbdata = GET(rhburl, config = auth, query = rhb_qparams)
  rhb = fromJSON(rawToChar(rhbdata$content))
  rhb = rhb$title[ , (names(rhb$title) %in% keep_vars) ]
  
  if(exists('reviewdata'))
    reviewdata = rbind(reviewdata, rhb)
  else
    reviewdata = rhb
  
  rhb_qparams['start'] = rhb_qparams[['start']] + rhb_interval
  rhb_qparams['max'] = rhb_qparams[['max']] + rhb_interval
}

#format book data
reviewdata$category = substring(reviewdata$subjectcategory1, 1, 3)
reviewdata = reviewdata[,!names(reviewdata) %in% c("subjectcategory1")]
reviewdata[is.na(reviewdata)] = 0

#save results to csv for easy later retrieval
write.csv(reviewdata, "rhbdata.csv")
