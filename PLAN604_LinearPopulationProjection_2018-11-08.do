/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/

capture log close   // suppress error and close any open logs
log using PLAN604_LinearPopulationProjection_2018-11-08, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
* program:    PLAN604_LinearPopulationProjection_2018-11-08.do
* task:       Explore Population Projections Using Linear Regression
* version:    Frist draft
* project:    PLAN 604 
* author:     Nathanael Rosenheim \ November 8, 2018

/*------------------------------------------------------------------*/
/* Control Stata                                                    */
/*------------------------------------------------------------------*/
* Generic do file that sets up stata environment
clear all          // Clear existing data files
macro drop _all    // Drop macros from memory
version 14       // Set Version
set more off       // Tell Stata to not pause for --more-- messages
set varabbrev off  // Turn off variable abbreviations
set linesize 80    // Set Line Size - 80 Characters for Readability

/********-*********-*********-*********-*********-*********-*********/
/* Obtain Data - Add population data manually into Stata            */
/********-*********-*********-*********-*********-*********-*********/

* Copy and paste Table 4.4 from your midterm
* Notice that for years without data Stata requires a "." which tells
* Stata that the data is MISSING. 

input year pop
1790	.
1800	.
1810	.
1820	.
1830	.
1840	.
1850	614
1860	3096
1870	9205
1880	13576
1890	16650
1900	18859
1910	18919
1920	21975
1930	21835
1940	26977
1950	38390
1960	44895
1970	57978
1980	93588
1990	121862
2000	152415
2010	194851
2011	.
2012	.
2013	.
2014	.
2015	.
2016	.
2017	.
2018	.
2019	.
2020	.
end

list

/********-*********-*********-*********-*********-*********-*********/
/* Clean Data                                                       */
/********-*********-*********-*********-*********-*********-*********/

* Label Variables
label variable year "Year"
label variable pop "Population"
format pop %8.0fc // format variable with commas, no decimals, easier to read

notes pop: Data Source: US Census Bureau Decennial Census 
* Obtain National Historic GIS Data on Population Size by County
/*
    Steven Manson, Jonathan Schroeder, David Van Riper, and Steven Ruggles. 
    IPUMS National Historical Geographic Information System: Version 12.0 [Database]. 
    Minneapolis: University of Minnesota. 2017. 
    http://doi.org/10.18128/D050.V12.0
*/


* What is the county FIPS Code, Name, and State?
global countyname = "Brazos County"
global state = "Texas"

gen FIPSCounty = "48041"
label variable FIPSCounty "County FIPS Code"

gen countyname = "${countyname}"
label variable countyname "County Name"

gen state = "${state}"
label variable state "State"



/********-*********-*********-*********-*********-*********-*********/
/* Explore Data - Round 1                                           */
/********-*********-*********-*********-*********-*********-*********/

scatter pop year, ///
	title("${countyname} ${state} Historic Population") ///
	name(scatter1)
graph export "PLAN604_${countyname}_scatter1.png", name(scatter1) replace

* What is the correlation between population and year
corr pop year

* summarize population
sum pop
sum pop, detail

graph box pop, horizontal name(boxplot1)
graph export "PLAN604_${countyname}_boxplot1.png", name(boxplot1) replace
* Notice that 1990 to 2010 are outliers

/********-*********-*********-*********-*********-*********-*********/
/* Model Data - Round 1                                             */
/********-*********-*********-*********-*********-*********-*********/


* Linear regression  
regress pop year

* Look at predicted values for model
predict pop_predicted1
label variable pop_predicted1 "Predicted Population Round 1"
format pop_predicted1 %8.0fc // format variable with commas, no decimals, easier to read

* Look at residuals for model
gen res1 = pop - pop_predicted1
label variable res1 "Residual between actual and predicted round 1"
format res1 %8.0fc // format variable with commas, no decimals, easier to read


/********-*********-*********-*********-*********-*********-*********/
/* Explore Data - Round 2                                           */
/********-*********-*********-*********-*********-*********-*********/

twoway(scatter pop year) (scatter pop_predicted1 year), ///
	title("${countyname}, ${state} Historic and Predicted Population 1") ///
	name(scatter2)
graph export "PLAN604_${countyname}_scatter2.png",name(scatter2) replace
	
/********-*********-*********-*********-*********-*********-*********/
/* Model Data - Round 2                                             */
/********-*********-*********-*********-*********-*********-*********/

* Use different years to make prediction
* NOTE - each county will need to have a different year selected
* Linear regression  
regress pop year if year >= 1950

* Look at predicted values for model
predict pop_predicted2 if year >= 1950
label variable pop_predicted2 "Predicted Population Round 2"
format pop_predicted2 %8.0fc // format variable with commas, no decimals, easier to read

* Look at residuals for model
gen res2 = pop - pop_predicted2 if year >= 1950
label variable res2 "Residual between actual and predicted round 2"
format res2 %8.0fc // format variable with commas, no decimals, easier to read

/********-*********-*********-*********-*********-*********-*********/
/* Explore Data - Round 3                                           */
/********-*********-*********-*********-*********-*********-*********/

twoway(scatter pop year) (scatter pop_predicted2 year), ///
	title("${countyname}, ${state} Historic and Predicted Population 2") ///
	name(scatter3)
graph export "PLAN604_${countyname}_scatter3.png", name(scatter3) replace

/********-*********-*********-*********-*********-*********-*********/
/* Model Data - Round 3                                             */
/********-*********-*********-*********-*********-*********-*********/

* Use different years to make prediction
* NOTE - each county will need to have a different year selected
* Linear regression  
regress pop year if year >= 1970

* Look at predicted values for model
predict pop_predicted3 if year >= 1970
label variable pop_predicted3 "Predicted Population Round 3"
format pop_predicted3 %8.0fc // format variable with commas, no decimals, easier to read

* Look at residuals for model
gen res3 = pop - pop_predicted3 if year >= 1970
label variable res3 "Residual between actual and predicted round 3"
format res3 %8.0fc // format variable with commas, no decimals, easier to read

/********-*********-*********-*********-*********-*********-*********/
/* Explore Data - Round 4                                           */
/********-*********-*********-*********-*********-*********-*********/

twoway(scatter pop year) (scatter pop_predicted3 year), ///
	title("${countyname}, ${state} Historic and Predicted Population 3") ///
	name(scatter4)
graph export "PLAN604_${countyname}_scatter4.png", name(scatter4) replace

/********-*********-*********-*********-*********-*********-*********/
/* Compare Predicted Values to ACS Estimates                        */
/********-*********-*********-*********-*********-*********-*********/

/* Look at ACS Estimates from American Factifinder 2011 - 2017 1 Year
https://factfinder.census.gov/bkmk/table/1.0/en/ACS/11_1YR/S0101/0500000US48041

*/

* Add ACS population for 2011
gen ACSpop = 197632 if year == 2011
format ACSpop %8.0fc // format variable with commas, no decimals, easier to read
label variable ACSpop "ACS Population Estimate"

* Replace missing values with ACS estimates for 2012 to 2017
* Note have to enter numbers without the comma
replace ACSpop = 200665 if year == 2012
replace ACSpop = 203164 if year == 2013
replace ACSpop = 209152 if year == 2014
replace ACSpop = 215037 if year == 2015
replace ACSpop = 220417 if year == 2016
replace ACSpop = 222830 if year == 2017

/*-------------------------------------------------------------------*/
/* End Log                                                           */
/*-------------------------------------------------------------------*/

log close
exit 
