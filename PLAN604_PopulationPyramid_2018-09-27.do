* program:    PLAN604_PopulationPyramid_2018-09-27.do
* task:       Population Pyramids
* Make a population pyramid for any county in the US for 2000 or 2010
* The program generates population pyramid for the total population
* The program also generates four comparison pyramids by race and ethnicity 
* version:    Second draft
* project:    PLAN 604
* author:     Nathanael Rosenheim \ Nov 7 2017

/*------------------------------------------------------------------*/
/* Control Stata                                                    */
/*------------------------------------------------------------------*/
* Generic do file that sets up stata environment
clear all          // Clear existing data files
macro drop _all    // Drop macros from memory
version 14         // Set Version
set more off       // Tell Stata to not pause for --more-- messages

/********-*********-*********-*********-*********-*********-*********/
/* Obtain Data                                                      */
/********-*********-*********-*********-*********-*********-*********/

use "PLAN604_PopulationPyramid_2018-09-27.dta", clear

/* Citation:
Surveillance, Epidemiology, and End Results (SEER) Program 
(www.seer.cancer.gov) SEER*Stat Database: Populations - Total U.S.
(1990-2015) Katrina/Rita Adjustment
- Total U.S., 1990-2015 Counties, National Cancer Institute,
DCCPS, Surveillance Research Program, released October 2016.
downloaded on Oct 23, 2017 from https:"//seer.cancer.gov/popdata/download.html"
*/

/********-*********-*********-*********-*********-*********-*********/
/* Explore Data                                                     */
/********-*********-*********-*********-*********-*********-*********/
* Select your county by it FIPS Code
* For example Brazos County has a FIPS code of 48041
local CountySelect = "48041"
local year = 2010
local CountyName = "Brazos County, TX"
/*-------------------------------------------------------------------*/
/* Generate Populatin Pyramids by total, race, and Hispanic          */
/*-------------------------------------------------------------------*/

* Create population Pyramid for Total Population
local popvar maletotalprct

* Create a variable that will label the max percantage values
quietly summarize `popvar' if year == `year' & FIPSCounty == "`CountySelect'"
local malemaxprct = r(min)
local malemax = string(-100*`malemaxprct',"%4.1f")+ "%"
quietly summarize fe`popvar' if year == `year' & FIPSCounty == "`CountySelect'"
local femalemaxprct = r(max)
local femalemax = string(100*`femalemaxprct',"%4.1f")+ "%"

* Generate Bar Graphs by AgeGroup and Sex
twoway bar `popvar' agegrp if year == `year' & FIPSCounty == "`CountySelect'", ///
horizontal bfc(gs7) blc(gs7) || ///
bar fe`popvar' agegrp if year == `year' & FIPSCounty == "`CountySelect'", ///
horizontal bfc(gs11) blc(gs11) || ///
scatter agegrp zero, mlabel(agegrp) mlabcolor(black) msymbol(none) ///
title("Population Pyramid for Total Population,") ///
subtitle("`CountyName', `year'") ///
graphregion(color(white)) ///
ytitle("") yscale(noline) ylabel(none) ///
note("Source: Surveillance, Epidemiology, and End Results (SEER) Program, 2016", size(vsmall)) ///
xlabel( `malemaxprct' "`malemax'" 0 "0%" `femalemaxprct' "`femalemax'") ///
legend(off) text(15 `malemaxprct' "Male") text(15 `femalemaxprct' "Female") ///
name(total) 


* loop through each category of pyramid
foreach race in white black asian hispanic {

* Set titles
if "`race'" == "white" local title = "White Alone, Not Hispanic" 
if "`race'" == "black" local title = "Black Alone, Not Hispanic" 	
if "`race'" == "asian" local title = "Asian Alone, Not Hispanic" 	
if "`race'" == "hispanic" local title = "Hispanic" 	
display "`title'"

local popvar male`race'prct

* Create a variable that will label the max percantage values
quietly summarize `popvar' if year == `year' & FIPSCounty == "`CountySelect'"
local malemaxprct = r(min)
local malemax = string(-100*`malemaxprct',"%4.1f")+ "%"
quietly summarize fe`popvar' if year == `year' & FIPSCounty == "`CountySelect'"
local femalemaxprct = r(max)
local femalemax = string(100*`femalemaxprct',"%4.1f")+ "%"

twoway bar `popvar' agegrp if year == `year' & FIPSCounty == "`CountySelect'", ///
horizontal bfc(gs7) blc(gs7) || ///
bar fe`popvar' agegrp if year == `year' & FIPSCounty == "`CountySelect'", ///
horizontal bfc(gs11) blc(gs11) ///
title("`title'") ///
graphregion(color(white)) ///
ytitle("") yscale(noline) ylabel(none) ///
xlabel( `malemaxprct' "`malemax'" 0 "0%" `femalemaxprct' "`femalemax'") ///
legend(off) text(15 `malemaxprct' "Male") text(15 `femalemaxprct' "Female") ///
name(`race'2) 
}
graph combine white2 black2 asian2 hispanic2, rows(2) ///
note("Source: Surveillance, Epidemiology, and End Results (SEER) Program, 2016", size(vsmall)) ///
title("Comparison of Population Pyramids by Race and Ethincity, ", size(medium)) ///
subtitle("`CountyName', `year'") ///
graphregion(color(white)) ///
name(comparison)

/*-------------------------------------------------------------------*/
/* Export Graphs                                                     */
/*-------------------------------------------------------------------*/

graph export "PLAN604_PopulationPyramid_2018-09-27_`CountySelect'`year'_total.png", ///
name(total) replace

graph export "PLAN604_PopulationPyramid_2018-09-27_`CountySelect'`year'_comparison.png", ///
name(comparison) replace

/*-------------------------------------------------------------------*/
/* End Program                                                       */
/*-------------------------------------------------------------------*/

exit
