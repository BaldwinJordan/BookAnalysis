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
model1 = lm(priceusa ~ division + formatname + pages + category + saleyear + salemonth + lowerage + upperage, train)
summary(model1)

#based off initial testing age range does not seem to matter 
model2 = lm(priceusa ~ division + formatname + pages + category + saleyear + salemonth, train)
summary(model2)

#predict based on our model2
prediction2 = predict(model2, test)

#check accuracy and calculate error
summary(prediction2)
R2 = 1-sum((test$priceusa - prediction2)^2)/sum((test$priceusa - mean(test$priceusa))^2)
RMSE2 = sqrt(sum(((test$priceusa - prediction2)^2)/nrow(test)))

plot(test$priceusa, prediction2) #visual of our outcome vs prediction

#does our model work better on smaller prices?
trainsmall = train[train$priceusa <=40, ]
testsmall = test[test$priceusa <=40, ]
model3 = lm(priceusa ~ division + formatname + pages + category + saleyear + salemonth, trainsmall)
summary(model3) 

#predict based on our model3
prediction3 = predict(model3, testsmall)
summary(prediction3)
R3 = 1-sum((testsmall$priceusa - prediction3)^2)/sum((testsmall$priceusa - mean(testsmall$priceusa))^2)
RMSE3 = sqrt(sum(((testsmall$priceusa - prediction3)^2)/nrow(testsmall)))

#yes it does, but does it on the larger set too?
prediction3l = predict(model3, test)
summary(prediction3l)
R3l = 1-sum((test$priceusa - prediction3l)^2)/sum((test$priceusa - mean(test$priceusa))^2)
RMSE3l = sqrt(sum(((test$priceusa - prediction3l)^2)/nrow(test))) 
#its very similar, although our model 2 does slightly better

#how about the first model for everything on the smaller set
prediction2s = predict(model2, testsmall)
summary(prediction2s)
R2s = 1-sum((testsmall$priceusa - prediction2s)^2)/sum((testsmall$priceusa - mean(testsmall$priceusa))^2)
RMSE2s = sqrt(sum(((testsmall$priceusa - prediction2s)^2)/nrow(testsmall))) 
#its very similar, although our model 3 does slightly better

(RMSE2+RMSE2s)/2
(RMSE3+RMSE3l)/2 
#very slight win on average for model based on smaller prices
#since this is 99% of our data lets plot it and see where it tends to be off
plot(prediction3l, test$priceusa, type = 'p', main = "Model 3 Prediction", xlab = "Predicted Price", ylab = "Actual Price")
abline(a=0, b=1, col = 'red')
# usually off on the higher price items (as expected)
# better on the small items by .18 (cents)
# and worse on large items by .175 (cents)
# since we would rather be closer on the 99% lets use model3 (although I don't think it really matters)


#plots and data for our analysis write up

#separating price into bins to plot count
rhbdata$pricegroup = cut(rhbdata$priceusa, 
                  breaks=c(0,5,10,15,20,25,30,100), 
                  include.lowest=TRUE, 
                  right=FALSE, 
                  labels=c("$0-5","$5-10", "$10-15", "$15-20", "$20-25", "$25-30", "$30+"))
ggplot(data = as_tibble(rhbdata$pricegroup), mapping = aes(x=value)) + 
  geom_bar(fill="light green", color="white", alpha=0.7) + 
  stat_count(geom="text", aes(label=sprintf("%.2f%%",..count../length(rhbdata$pricegroup)*100)), vjust=-0.5) +
  labs(title = 'Number of Books by Price Range', x = 'Price', y = "Number of Books") +
  expand_limits(y = c(0, 50000)) +
  theme_bw()

summary(rhbdata)
sd(rhbdata$priceusa)
13.28/8.605371 # mean/sd to get CV

#summarizing categorical data
datagroup = rhbdata %>%
  group_by(category)%>% 
  summarise(Count=length(priceusa), Mean=mean(priceusa), Median=median(priceusa), Min=min(priceusa), Max=max(priceusa))

#decided not to use but useful for future perhaps
ggplot(data = rhbdata, aes(x = category, y = priceusa))  +
  geom_jitter(width = .2, color="light green", alpha=.4) +
  geom_boxplot(outlier.shape = NA, fill = 'grey', alpha = .15) +
  labs(title = 'Price of Books by Category', x = 'Category', y = "Price of Books") +
  theme_bw()

#plotting correlation for numerical data
datagroup = rhbdata %>%
  group_by(saleyear)%>% 
  summarise(mean=mean(priceusa), median=median(priceusa))
datagroup = melt(datagroup, id = "saleyear")
ggplot(data = datagroup, aes(x = saleyear, y = value,  color = variable)) + 
  geom_point(aes(group = variable)) +
  geom_line(aes(group = variable)) +
  scale_color_manual(values = c('mean' = 'light green','median' = 'light blue')) +
  labs(title = 'Year Correlation', x = 'Year', y = "Price of Books", color = '') +
  theme_bw()


