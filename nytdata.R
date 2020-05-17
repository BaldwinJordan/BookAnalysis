library(httr)
library(jsonlite)

nyturl = "https://api.nytimes.com/svc/books/v3/lists/best-sellers/history.json" 
nyt_qparams = list('api-key' = "E2AlO2GgUegFeNJbcTqCgCEQFhVnU1Zd", isbn = 9780399178573)
nytdata = GET(nyturl, query = nyt_qparams)
