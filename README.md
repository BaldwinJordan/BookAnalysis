# The Price of Books :

A Study of Books Published By Penguin Random House 



**_The Question:_**

Can we accurately predict the price of a book based on the data available from the Penguin Random House public api?

**_The Answer:_** 

We can predict the price of a book with approximately 60% accuracy, and typically within $5. We are more likely to accurately predict the price for books under $30.


# Introducing the Data

Our data consisted of 91K unique books available on sale from Jan-2010 to Feb-2018.

The price of our books ranged from $.99 to $100, after removing outliers, with the greatest concentration of books being between $5 and $10. The average price of a book was $13.28, with a median price of $10.99. Books greater than $30 were specialty editions, leather bound, or otherwise rare books. This information was discovered by independently researching the isbns from a random selection.

The key data points that we used to determine our predicted price were: the type of book (ebook, hardback, paperback, ect.), the publishing division, the category of book (Fiction, Nonfiction, Historical, ect.), the number of pages, the suggested age range, and the year and month that the book went on sale. Detailed information on the categorical data points can be found in Appendix A.


# Method and Results of Analysis

Logistic Regression was the method of choice to create our final predictive model. 

A first Model 1 found that the data point of suggested age range was not statistically significant and was cut from a second Model 2’s coefficients. It was also found that the accuracy was greatly increased for the &lt; $40 range, so a final Model 3 was created using only those. Model 2 and Model3 had very similar results. 


<table>
  <tr>
   <td>
   </td>
   <td>Adjusted R-squared
   </td>
   <td>p-value
   </td>
   <td>RMSE (All)
   </td>
   <td>RMSE (&lt;$40)
   </td>
   <td>Avg. RMSE
   </td>
  </tr>
  <tr>
   <td>Model 2
   </td>
   <td>0.5956
   </td>
   <td>2.2e-16
   </td>
   <td>5.39
   </td>
   <td>4.16
   </td>
   <td>4.77
   </td>
  </tr>
  <tr>
   <td>Model 3
   </td>
   <td>0.6506
   </td>
   <td>2.2e-16
   </td>
   <td>5.56
   </td>
   <td>3.98
   </td>
   <td>4.77
   </td>
  </tr>
</table>


Model 3 was our final choice of model based on the greater degree of accuracy for smaller prices, which was the majority of our data. The final coefficients can be seen in Appendix C.


# Final Thoughts

Based on the high amount of spread in our data (CV = 1.5), and a lack of any significant correlation between price and our available data (correlation can be seen in Appendix B), we did not expect to be able to achieve a high degree of accuracy. Still, our analysis could benefit from a more accurate model or the inclusion of additional correlated data points. Text analysis of the books’ themes could be a data point to explore in the future. 
