# *******-*********-*********-*********-*********-*********-*********/
#  Description of Program                                           */
# *******-*********-*********-*********-*********-*********-*********/
# program:    PLAN604_Week7_Regression_USexample2_2019-10-03.R
# task:       Replicate Wang and vom Hofe 2006 section 3.4
#       			Compares trend extropolation methods 
#             Use US Population Data
# version:    version 5 - focus on linear and geometric using R
# version:    version 6 - Use population data for the US 1950-2010
# project:    PLAN 604 
# author:     Nathanael Rosenheim \ October 3, 2019

# Follow this program to step through Wang and vom Hofe Ch 3

# *******-*********-*********-*********-*********-*********-*********/
# Obtain Data - Add year and population data manually into R        */
# *******-*********-*********-*********-*********-*********-*********/

# Copy and paste historic population data
# REMOVE all commas from numbers, edit-replace and find (Ctrl+Shift+J) may help 

# Setup year variable
# Create a vector, a list of data, for years
year <- seq(from = 1950, to = 2010, by = 10)

# Create a vector, a list of data, for population
# Population from NHGIS
pop <- c(
  151325799,
  179323177,
  203211926,
  226545805,
  248709873,
  281421906,
  308745538)

# Combine Year and population data into 1 dataframe
yearpop <- data.frame(pop,year)

# *******-*********-*********-*********-*********-*********-*********/
#  Explore Data with Scatterplot                                    */
# *******-*********-*********-*********-*********-*********-*********/

plot(yearpop$year, yearpop$pop,
     ylab = "Population",
     xlab = "Year",
     main = "Population of United States, 1950-2010")

# *******-*********-*********-*********-*********-*********-*********/
#  Add Index Number                                                 */
# *******-*********-*********-*********-*********-*********-*********/

# To simplify the program we will not use a year index
# The predictions will be the same but the y-intercept will be larger

# *******-*********-*********-*********-*********-*********-*********/
#  3.4.3 Linear Population Model                                    */
# *******-*********-*********-*********-*********-*********-*********/
# Assume constant Annual Absolute Change -
# which means that the population will change by a constant number of people
# Linear regression equation 3.15

# Regressing population variable on the year varaible
linearmodel <- lm(pop ~ year, data = yearpop)
summary(linearmodel)

# Display the number of people the model assumes the population
# will grow by each year
coef(linearmodel)["year"]

# *******-*********-*********-*********-*********-*********-*********/
#  Predict Population for future years (Wang & vom Hofe 2006 p. 90) */
# *******-*********-*********-*********-*********-*********-*********/

predict(linearmodel,data.frame(year = 2020))
predict(linearmodel,data.frame(year = 2030))

# *******-*********-*********-*********-*********-*********-*********/
#  3.4.4 Geometric Population Model                                 */
# *******-*********-*********-*********-*********-*********-*********/
# Assume constant Annual Percent Change -
# which means that the population will change by a constant growth rate
# To use the "Ordinary Least-Square" criterion
# need to take the log of population (logarithmic transformation)

yearpop$pop_log <- log10(yearpop$pop)

# Regressing log population variable on the year varaible
geometricmodel <- lm(pop_log ~ year, data = yearpop)
summary(geometricmodel)

# *******-*********-*********-*********-*********-*********-*********/
#  Predict Population for future years (Wang & vom Hofe 2006 p. 95) */
# *******-*********-*********-*********-*********-*********-*********/
10^predict(geometricmodel,data.frame(year = 2020))
10^predict(geometricmodel,data.frame(year = 2030))

# Calculate the constant growth factor - based on slope
coef(geometricmodel)["year"]
growthfactor <- 10^coef(geometricmodel)["year"]
growthfactor

