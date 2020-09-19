#Analyze book data and predict price of books

library(tidyverse)

#Retrieve book data

rhbdata = read.csv(file = 'rhbdata.csv')

#remove rows without a price or pages
rhbdata = rhbdata[rhbdata$priceusa != 0, ]
rhbdata = rhbdata[rhbdata$pages != 0, ]
rhbdata = rhbdata[,!names(rhbdata) %in% c("X")] 

#make sure dates are date types
rhbdata$onsaledate = as.Date(rhbdata$onsaledate, '%Y-%m-%d')
rhbdata$isbn = as.character(rhbdata$isbn)


#turn categorical data into numerical

#split age range into 2 columns with lower and upper range
# not sure what to do with blanks here, they are usually adult books so lets assume 18+
rhbdata[,8][rhbdata[,8]==0] = "1899"
rhbdata$agerangecode <- gsub('UP', '99', rhbdata$agerangecode)
rhbdata$lowerage = as.integer(substr(rhbdata$agerangecode, start = 1, stop = 2))
rhbdata$upperage = as.integer(substr(rhbdata$agerangecode, start = 3, stop = 4))
rhbdata$agerangecode <- NULL

#keep those categories that are at least 1% frequent in the data
#combine the rest to an 'Other' category
categories = rhbdata %>%
  count(category) %>%
  mutate(freq = floor(n / sum(n)*100))
rhbdata$category[!rhbdata$category %in% categories[categories$freq >=1,][,1]] = 'OTH'
rhbdata$category = factor(rhbdata$category)
rm(categories)

#keep those divisions that are at least 1% frequent in the data
#combine the rest to an 'Other' division
divisions = rhbdata %>%
  count(division) %>%
  mutate(freq = floor(n / sum(n)*100))
rhbdata$division[!rhbdata$division %in% divisions[divisions$freq >=1,][,1]] = 'Other'
rhbdata$division = factor(rhbdata$division)
rm(divisions)

rhbdata = rhbdata[ !rhbdata$formatname %in% c('iPhone/iPad App', 'Video', 'Package', 'Boxed Set', 'Non-traditional book'), ] #remove values that aren't books
sort(table(rhbdata$formatname))
rhbdata$formatname = factor(rhbdata$formatname)

#remove any duplicate rows (there shouldn't be any, but just in case)
rhbdata %>% distinct()


#Review info for errors

summary(rhbdata)

# there are some very expensive books that might need to be considered outliers
pricedata = rhbdata[order(rhbdata$priceusa),]
boxplot(pricedata$priceusa)
tail(pricedata, 100)
rm(pricedata)
#checked out the isbns online of the high dollar ones
#most of them over $100 are signed copies or limited edition
#we do not want those as part of our study, so remove those over 100 in price
#might be able to bump this down more, but lets see how our fit does first
rhbdata = rhbdata[rhbdata$priceusa <=100, ]
hist(rhbdata$priceusa)#still very left heavy, but better

#there is an error in pages - the 9000 is inaccurate (although the rest are surprisingly accurate)
rhbdata = rhbdata[rhbdata$pages < 9000, ]


#create model

#and year and month as columns
rhbdata$saleyear <- as.numeric(format(rhbdata$onsaledate,'%Y'))
rhbdata$salemonth <- as.numeric(format(rhbdata$onsaledate,'%m'))

#relevel factors so we can use them
rhbdata$division = relevel(rhbdata$division, "Other")
rhbdata$formatname = relevel(rhbdata$formatname, "eBook")
rhbdata$category = relevel(rhbdata$category, "FIC")

#split to create testing and training sets
library(caTools)
set.seed(100)
split = sample.split(rhbdata$saleyear, .75)
train = subset(rhbdata, split == TRUE)
test = subset(rhbdata, split == FALSE)

#we have multiple variables so lets logistical regression it
model1 = lm(priceusa ~ division + formatname + pages + category + lowerage + upperage, train)
summary(model1)

#based off initial testing age range does not seem to matter 
model2 = lm(priceusa ~ division + formatname + pages + category, train)
summary(model2)

#predict based on our model2
prediction2 = predict(model2, test)
summary(prediction2)
plot(test$priceusa, prediction2) #visual of our outcome vs prediction

#does our model work better on smaller prices?
train2 = train[train$priceusa <=40, ]
test2 = test[test$priceusa <=40, ]
model3 = lm(priceusa ~ division + formatname + pages + category, train2)
summary(model3) #yes it does

#predict based on our model3
prediction3 = predict(model3, test2)
summary(prediction3)
plot(test2$priceusa, prediction3)

