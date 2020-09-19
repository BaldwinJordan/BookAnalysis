# Retrieve book data from Penguin Random House Books api and save to a csv
library(httr)
library(jsonlite)
library(progress)

#variable setup
rhburl = "https://reststop.randomhouse.com/resources/titles"
num_rows = 100000
rhb_start = 1
rhb_num = 99 #cannot be greater than 100 
date_min = "01/05/2010"
date_max = "12/31/2019"

#setup api call information
rhb_qparams = list(start = rhb_start, max = rhb_num, expandLevel=1, onsaleStart = date_min, onsaleEnd = date_max)
auth = authenticate("testuser", "testpassword", type = "basic")
keep_vars = c("agerangecode", "subjectcategory1", "onsaledate", "pages", "priceusa", "isbn", "author", "division", "formatname")

#call rhb api in loop to retrieve book data (api returns max of 100 rows per call)
rhb_interval = rhb_num + 1
pb <- progress_bar$new(total = (num_rows-rhb_start)/rhb_num) #progress bar to see where we are
while (rhb_qparams['start'] < num_rows){
  pb$tick()  #increment progress bar
  Sys.sleep(1 / 100)
  
  rhbdata = GET(rhburl, config = auth, query = rhb_qparams)
  rhb = fromJSON(rawToChar(rhbdata$content))
  rhb = rhb$title[ , (names(rhb$title) %in% keep_vars) ] #keep only columns we want
  
  #combine calls to single data source
  rhb[keep_vars[!(keep_vars %in% colnames(rhb))]] = 0 #makes sure columns match
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
