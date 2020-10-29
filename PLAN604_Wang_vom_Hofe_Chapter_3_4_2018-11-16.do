/*-------1---------2---------3---------4---------5---------6--------*/
/* Start Log File: Change working directory to project directory    */
/*-------1---------2---------3---------4---------5---------6--------*/

capture log close   // suppress error and close any open logs
log using PLAN604_Wang_vom_Hofe_Chapter_3_4_2018-11-16, replace text
/********-*********-*********-*********-*********-*********-*********/
/* Description of Program                                           */
/********-*********-*********-*********-*********-*********-*********/
* program:    PLAN604_Wang_vom_Hofe_Chapter_3_4_2018-11-16.do
* task:       Replicate Wang and vom Hofe 2006 section 3.4
*				Compares models of population projections for a county
* version:    Fourth draft
* project:    PLAN 604 
* author:     Nathanael Rosenheim \ November 8, 2018

/*------------------------------------------------------------------*/
/* Note to Program Users                                            */
/*------------------------------------------------------------------*/
/*
This program is based on work presented in 
Wang, X. and vom Hofe, R. 2006. Research Methods in Urban and Regional Planning, 
	Springer.  Available for download through Texas A&M University Library: 
	https://link-springer-com.lib-ezproxy.tamu.edu:9443/book/10.1007%2F978-3-540-49658-8
	
This program is desiged to produced population projections for any 
community with historic population data.

Program requires that general questions about the data and 
the desired population projections be changed in the first sections 
of the program.

The program will create a Word Document with results of population
methods and models.
*/


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

* Copy and paste historic population data
* REMOVE all commas from numbers, edit-find-replace (Ctrl+H) may help 
* Data Source: 1790-2010 - NHGIS
* Data Source: After 2010 ACS 1 year estimates
* 				https://factfinder.census.gov/bkmk/table/1.0/en/ACS/17_1YR/S0101/0500000US42049


* Table 3.9 Wang and vom Hofe
input year pop
1990 57589
1991 60574
1992 62897
1993 65318
1994 67554
1995 70017
1996 72860
1997 76162
1998 79818
1999 83349
2000 85991
end

list

/********-*********-*********-*********-*********-*********-*********/
/* General Questions - Specific to county and state data            */
/********-*********-*********-*********-*********-*********-*********/
* What is the county FIPS Code, Name, and State?
global countyname = "Boone County"
global state = "Kentucky"
global FIPSCounty = "21015"

* What years will be used for the population projections models?
* The base year varies depending on the community and the data avaialable
* Each population model can have a different base year.
global base_year_share     = 1990
global base_year_linear    = 1990
global base_year_geometric = 1990
global base_year_parabolic = 1990
global base_year_logistic  = 1990

* The launch year is the last year with observed population data:
global launch_year = 2000

* The target year is in the future.
global target_year = 2010 // Projected Population Year

* This shift-share and share of growth methods require data for 
* a larger region - usually the state.

* The population of the state or larger region in the base year for
* the share of growth and shift-share models and launch years
*Source: Wang and vom Hofe 2006
global pop_large_region_base = 3686891
global pop_large_region_launch = 4041769

*  The projected population of the state or larger region in target year
*Source: Wang and vom Hofe 2006
global pop_large_region_target = 4374591

* For the logistic model what is the counties assumed growth limit?
* In other words what is a maximum population size for the county?
global pop_ceiling = 250000

/********-*********-*********-*********-*********-*********-*********/
/* Clean Data                                                       */
/********-*********-*********-*********-*********-*********-*********/

* Label Variables
label variable year "Year"
label variable pop "Observed Population"
format pop %8.0fc // format variable with commas, no decimals, easier to read

notes pop: Data Source: Wang and vom Hofe 2006 Table 3.4

* To model future population we need to add rows for the years to predict
* Stata has two helpful variables _N and _n
* _N equals current number of rows
* _n is the row number
* Add observations for years after launch and to the target year
local rows_to_add ${target_year} - ${launch_year}
local current_number_of_rows = _N
local rows_need = `current_number_of_rows' + `rows_to_add'
set obs `rows_need'
* Add missing year variables
replace year = ${launch_year} + _n - `current_number_of_rows'

* For the program to run for any community, for any period of time
* The program needs to know which rows are for specific years
* add row_index 
gen row_index = _n
sum row_index if year == ${base_year_share}
global base_share = `r(mean)' 
display "The row in the datafile with the data for the $base_year is " $base

sum row_index if year == ${launch_year}
global launch = `r(mean)' 
display "The row in the datafile with the data for the $launch_year is " $launch

sum row_index if year == ${target_year}
global target = `r(mean)' 
display "The row in the datafile with the data for the $target_year is " $target

* For the linear regresion models (linear, geometric, parabolic, and logistic)
* Each model needs an index year variable
foreach model in linear parabolic geometric logistic {
gen year_index_`model' = year - ${base_year_`model'}+1 if year >= ${base_year_`model'}
label variable year_index_`model' "Year Index for `model' model"
}

gen FIPSCounty = "${FIPSCounty}"
label variable FIPSCounty "County FIPS Code"

gen countyname = "${countyname}"
label variable countyname "County Name"

gen state = "${state}"
label variable state "State"

/********-*********-*********-*********-*********-*********-*********/
/* 3.4 Trend Extrapolation Methods                                  */
/********-*********-*********-*********-*********-*********-*********/
* Stata can create word documents with the command putdocx
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("3.4 Trend Extrapolation Methods")

* Figure 3.6
twoway(line pop year, lwidth(thick)) ///
	  (scatter pop year, msymbol(S)) ///
	  if year < ${launch_year}, graphregion(color(white)) ylabel(, angle(0))
graph export "Pop_${countyname}_${state}_${base_year}-${launch_year}.emf", replace
putdocx paragraph, halign(center)
putdocx image "Pop_${countyname}_${state}_${base_year}-${launch_year}.emf"
putdocx paragraph, halign(center)
putdocx text ("Figure 3.6 "), bold
local first_year = year[1]
putdocx text ("Population of ${countyname}, ${state}, `first_year'-${launch_year}")

* Look at simple population extrapolation methods AAAC and AAPC
* Save key variables for AAAC and AAPC equations
local pop_base = pop[$base_share]
local pop_launch = pop[$launch]
* Calculate the number of years between launch and base
local n = $launch_year - $base_year_share

* Average Annual Absolute Change(AAAC)
local AAAC = (`pop_launch'-`pop_base')/`n'
putdocx paragraph
local AAAC_text : display %6.0fc `AAAC'
putdocx text ("The Average Annual Absolute Change between ${base_year}-${launch_year} was `AAAC_text'")

* Averge Annual Percent Change (AAPC)
local AAPC = (`pop_launch'/`pop_base')^(1/`n')-1
putdocx paragraph
local AAPC_text : display %6.3f `AAPC'
putdocx text ("The Averge Annual Percent Change between ${base_year}-${launch_year} was `AAPC_text'")

* Target population using AAAC
gen pop_AAAC = `pop_launch' + (year-${launch_year}) * (`AAAC') if year >= ${launch_year}
label variable pop_AAAC "AAAC Projection"

* Target population using AAPC
gen pop_AAPC = `pop_launch' * (1 + `AAPC')^(year-${launch_year}) if year >= ${launch_year}
label variable pop_AAPC "AAPC Projection"

* Format population numbers in table
format pop* %8.0fc // format variable with commas, no decimals, easier to read

* Figure 3.7
twoway(scatter pop_AAAC year, msymbol(D)) ///
	  (scatter pop_AAPC year, msymbol(S)) if year >= ${launch_year}, ///
	  graphregion(color(white)) ytitle("Population") ylabel(, angle(0))
graph export "Pop_${countyname}_${state}_AAAC_AAPC.emf", replace
putdocx paragraph, halign(center)
putdocx image "Pop_${countyname}_${state}_AAAC_AAPC.emf"
putdocx paragraph, halign(center)
putdocx text ("Figure 3.7 "), bold
putdocx text ("${countyname} population projections based on AAAC and AAPC, ${launch_year}-${target_year}")


/********-*********-*********-*********-*********-*********-*********/
/* 3.4.1 Share of Growth Method                                     */
/********-*********-*********-*********-*********-*********-*********/
putdocx paragraph, style(Heading2)
putdocx text ("3.4.1 Share of Growth Method")

putdocx paragraph, halign(center)
putdocx text ("Table 3.10 "), bold
putdocx text ("${countyname} and ${state} population statistics, ${base_year_share} - ${target_year}")
* Make a table with 4 rows and 3 columns
putdocx table tbl310 = (4,3), ///
		border(all, nil) border(bottom, single) border(top, single)
* Fill in Column 1
putdocx table tbl310(1,1) = ("Year")
putdocx table tbl310(2,1) = ("${base_year_share}")
putdocx table tbl310(3,1) = ("${launch_year}")
putdocx table tbl310(4,1) = ("${target_year}")

* Fill in Column 2
putdocx table tbl310(1,2) = ("${state}")
putdocx table tbl310(2,2) = ("${pop_large_region_base}")
putdocx table tbl310(3,2) = ("${pop_large_region_launch}")
putdocx table tbl310(4,2) = ("${pop_large_region_target}")

* Fill in Column 3
*  1. The population of the county in base and launch years
global pop_smaller_area_base = pop[$base_share]
global pop_smaller_area_launch = pop[$launch]

putdocx table tbl310(1,3) = ("${countyname}")
putdocx table tbl310(2,3) = ("${pop_smaller_area_base}")
putdocx table tbl310(3,3) = ("${pop_smaller_area_launch}")

* Format table
* Center text first column
putdocx table tbl310(.,1), halign(center) valign(center)
* Right justify numbers in columns 2 to 3
putdocx table tbl310(.,2/3), halign(right) valign(center) nformat(%10.0fc) 
* Center top row headers
putdocx table tbl310(1,.), halign(center) valign(center)
* Format borders
putdocx table tbl310(1,1/3), /// add top and bottom border to first row
	border(top, single) border(bottom, single)

putdocx paragraph, halign(left)
putdocx text ("Source: Kentucky State Data Center,")
putdocx text (" Summary table for Kentucky and Counties: ")
putdocx text ("http://ksdc.louisville.edu/kpr/pro/Summary_Table.xls.")


* Step 1 - calculate the growth share
local growthshare1 = ${pop_smaller_area_launch} - ${pop_smaller_area_base}
local growthshare2 = ${pop_large_region_launch} - ${pop_large_region_base}
local growthshare = `growthshare1'/`growthshare2'
putdocx paragraph, halign(left)
local growthshare_text : display %4.3f `growthshare'
putdocx text ("The growth share equals `growthshare_text'")

* Step 2 - Assume that share of growth will remain constant and
* 			use this to project population for the county
local pop_smaller_area_target = ${pop_smaller_area_launch} + ///
	`growthshare'*(${pop_large_region_target} - ${pop_large_region_launch})
putdocx paragraph, halign(left)
local pop_smaller_area_target_text : display %8.0fc `pop_smaller_area_target'
putdocx text ("The projected county population for ${target_year} is `pop_smaller_area_target_text'")

* Add Share of Growth Population
gen sharegrowth = `pop_smaller_area_target' if year == ${target_year}
format sharegrowth %8.0fc // format variable with commas, no decimals, easier to read
label variable sharegrowth "Share of Growth Method"

* NOTE - values differ from Wang and vom Hofe due to rounding

/********-*********-*********-*********-*********-*********-*********/
/* 3.4.2 Shift-Share Method                                         */
/********-*********-*********-*********-*********-*********-*********/
putdocx paragraph, style(Heading2)
putdocx text ("3.4.2 Shift-Share Method")

* What is the smaller area's share of the total population?
* 1. In the base year?
local share_base = ${pop_smaller_area_base}/${pop_large_region_base}
* 2. In the launch year?
local share_launch = ${pop_smaller_area_launch}/${pop_large_region_launch}

* How many years between launch and target (the projection period)?
local years_pp = ${target_year} - ${launch_year}
* How many years between base and launch (the base period)?
local years_bp = ${launch_year} - ${base_year_share}

* Step 1: Calculate the shift-share
local shiftshare = `share_launch' + (`years_pp'/`years_bp')*(`share_launch' - `share_base')
* Step 2: Multiply the shift-share times the larger regions projected population
local pop_smaller_area_target =  ${pop_large_region_target} * `shiftshare'
putdocx paragraph, halign(left)
local pop_smaller_area_target_text : display %8.0fc `pop_smaller_area_target'
putdocx text ("The projected county population for ${target_year} is `pop_smaller_area_target_text'")

* Add Share of Growth Population
gen shiftshare = `pop_smaller_area_target' if year == ${target_year}
format shiftshare %8.0fc // format variable with commas, no decimals, easier to read
label variable shiftshare "Shift-Share Method"

* NOTE - values differ from Wang and vom Hofe due to rounding

/********-*********-*********-*********-*********-*********-*********/
/* 3.4.3 Linear Population Model                                    */
/********-*********-*********-*********-*********-*********-*********/
putdocx paragraph, style(Heading2)
putdocx text ("3.4.3 Linear Population Model")

* Assume constant Annual Absolute Change -
* which means that the population will change by a constant number of people
* Linear regression equation 3.15
regress pop year_index_linear

* What is the y-intercept for the linear model?
putdocx paragraph
global alpha_linear : display %8.0fc _b[_cons]
putdocx text ("The y-intercept (year=${base_year_linear}) for the geometric model is ${alpha_linear}")

* What is the Annual Aboslute Change?
putdocx paragraph
global beta1_linear : display %6.0fc _b[year_index_linear]
putdocx text ("The slope for the linear model (Annual Absolute Change) is ${beta1_linear}")

* Look at predicted population values from the linear model
gen pop_linear = _b[_cons] + _b[year_index_linear] * year_index_linear
label variable pop_linear "Linear Population Model"
format pop_linear %8.0fc // format variable with commas, no decimals, easier to read

* Figure 3.8
twoway(line pop year, lwidth(thick)) (scatter pop_linear year, msymbol(D)) ///
	  if year <= ${launch_year}, ///
	  graphregion(color(white)) ytitle("Population")
graph export "Pop_${countyname}_${state}_linear.emf", replace
putdocx paragraph, halign(center)
putdocx image "Pop_${countyname}_${state}_linear.emf"
putdocx paragraph, halign(center)
putdocx text ("Figure 3.8 "), bold
putdocx text ("The linear trend line for ${countyname}, ${state} population data")

	
* Look at residuals for model
gen residual_linear = pop - pop_linear
label variable residual_linear "Residual Linear Population Model"
format residual_linear %8.0fc // format variable with commas, no decimals, easier to read

* Look at adjustment factor using the observed and predicted values
local adjust_linear = residual_linear[$launch]
display "The adjustment factor is " `adjust_linear'

* Calculate linear regression model with adjustment factor
gen pop_linear2 = pop_linear + `adjust_linear'
label variable pop_linear2 "Linear Population Model - Adjusted"
format pop_linear2 %8.0fc // format variable with commas, no decimals, easier to read

/********-*********-*********-*********-*********-*********-*********/
/* 3.4.4 Geometric Population Model                                 */
/********-*********-*********-*********-*********-*********-*********/
putdocx paragraph, style(Heading2)
putdocx text ("3.4.4 Geometric Population Model")

* Assume constant Annual Percent Change -
* which means that the population will change by a constant growth rate
* To use the "Ordinary Least-Square" criterion (regress command)
* need to take the log of population (logarithmic transformation)

gen pop_log = log(pop)
regress pop_log year_index_geometric

* What is the y-intercept for the geometric model?
putdocx paragraph
global alpha_geometric : display %8.0fc exp(_b[_cons])
putdocx text ("The y-intercept (year=${base_year_geometric}) for the geometric model is ${alpha_geometric}")

* What is the Annual Percent Change?
putdocx paragraph
global beta1_geometric : display %6.4f exp(_b[year_index_geometric])
putdocx text ("The growth rate for the geometric model is  ${beta1_geometric}")
putdocx paragraph
local growth_factor : display %6.4f (exp(_b[year_index_geometric]) - 1)
putdocx text ("The actual growth factor for the geometric model is `growth_factor'")

* Look at predicted population values from the geometric model
gen pop_geometric = exp(_b[_cons])*exp(_b[year_index_geometric])^year_index_geometric
label variable pop_geometric "Geometric Population Model"
format pop_geometric %8.0fc

* Look at residuals for model
gen residual_geometric = pop - pop_geometric
label variable residual_geometric "Residual Geometric Population Model"
format residual_geometric %8.0fc // format variable with commas, no decimals, easier to read

* Look at adjustment factor using the observed and predicted values
local adjust_geometric = residual_geometric[$launch]
display "The adjustment factor is " `adjust_geometric'

* Calculate linear regression model with adjustment factor
gen pop_geometric2 = pop_geometric + `adjust_geometric'
label variable pop_geometric2 "Geometric Population Model - Adjusted"
format pop_geometric2 %8.0fc // format variable with commas, no decimals, easier to read


/********-*********-*********-*********-*********-*********-*********/
/* 3.4.5 Parabolic Population Model                                 */
/********-*********-*********-*********-*********-*********-*********/
putdocx paragraph, style(Heading2)
putdocx text ("3.4.5 Parabolic Population Model")

* The parabolic model is similar to the linear regresion but adds 
* a squared term for time 
gen year_index_parabolic_squared = year_index_parabolic^2
regress pop year_index_parabolic year_index_parabolic_squared

* What is the y-intercept for the parabolic model?
putdocx paragraph
global alpha_parabolic : display %8.0fc _b[_cons]
putdocx text ("The y-intercept (year=${base_year_parabolic}) for the parabolic model is ${alpha_parabolic}")

* What is the Beta 1 coeffienct?
putdocx paragraph
global beta1_parabolic : display %6.0fc _b[year_index_parabolic]
putdocx text ("The linear slope parameter is ${beta1_parabolic}")
putdocx paragraph
global beta2_parabolic : display %6.0fc _b[year_index_parabolic_squared]
putdocx text ("The nonlinear slope parameter is ${beta2_parabolic}")

* Look at predicted population values from the linear model
gen pop_parabolic = _b[_cons] + _b[year_index_parabolic] * year_index_parabolic ///
					  + _b[year_index_parabolic_squared] * year_index_parabolic^2
label variable pop_parabolic "Parabolic Population Model"
format pop_parabolic %8.0fc // format variable with commas, no decimals, easier to read

* Look at residuals for model
gen residual_parabolic = pop - pop_parabolic
label variable residual_parabolic "Residual Parabolic Population Model"
format residual_parabolic %8.0fc // format variable with commas, no decimals, easier to read

* Look at adjustment factor using the observed and predicted values
local adjust_parabolic = residual_parabolic[$launch]
display "The adjustment factor is " `adjust_parabolic'

* Calculate linear regression model with adjustment factor
gen pop_parabolic2 = pop_parabolic + `adjust_parabolic'
label variable pop_parabolic2 "Parabolic Population Model - Adjusted"
format pop_parabolic2 %8.0fc // format variable with commas, no decimals, easier to read

/********-*********-*********-*********-*********-*********-*********/
/* 3.4.6 Logistic Population Model                                  */
/********-*********-*********-*********-*********-*********-*********/
putdocx paragraph, style(Heading2)
putdocx text ("3.4.6 Logistic Population Model")
putdocx paragraph
putdocx text ("The assumed upper growth limit is ${pop_ceiling}")

* Assume that upper growth limit  
* Generate a new variable that is the difference between the 
* inverse of the population size and the inverse of the population ceiling

gen log_diff_pop_c = log(1/pop - 1/${pop_ceiling})

* Use linear regression on transformed population 
regress log_diff_pop_c year_index_logistic

* What is the intercept of the trend line for the logistic model?
* To determine this we need to take the exponent of the constant.
* What is the y-intercept for the logistic model?
putdocx paragraph
global alpha_logistic : display %10.9fc exp(_b[_cons])
putdocx text ("The y-intercept (year=${base_year_logistic}) for the logistic model is ${alpha_logistic}")

* What is the Beta 1 coeffienct?
putdocx paragraph
global beta1_logistic : display %6.4f exp(_b[year_index_logistic])
putdocx text ("The slope of the population trend line in logarithmic form is ${beta1_logistic}")
display "The y-intercept for the logistic model is " exp(_b[_cons])


* Look at predicted population values from the logistic model
gen pop_logistic = 1/((1/${pop_ceiling})+exp(_b[_cons])*exp(_b[year_index_logistic])^year_index_logistic)
label variable pop_logistic "Logistic Population Model"
format pop_logistic %8.0fc

* Look at residuals for model
gen residual_logistic = pop - pop_logistic
label variable residual_logistic "Residual Logistic Population Model"
format residual_logistic %8.0fc // format variable with commas, no decimals, easier to read

* Look at adjustment factor using the observed and predicted values
local adjust_logistic = residual_logistic[$launch]
display "The adjustment factor is " `adjust_logistic'

* Calculate linear regression model with adjustment factor
gen pop_logistic2 = pop_logistic + `adjust_logistic'
label variable pop_logistic2 "Logistic Population Model - Adjusted"
format pop_logistic2 %8.0fc // format variable with commas, no decimals, easier to read


/********-*********-*********-*********-*********-*********-*********/
/* Generate Table 3.15                                              */
/********-*********-*********-*********-*********-*********-*********/

putdocx paragraph, halign(center)
putdocx text ("Table 3.15"), bold
putdocx text (" Comparison of “adjusted” population projections for ${countyname}, ${state}.")
putdocx table tbl315 = data(year sharegrowth shiftshare pop_linear2 pop_geometric2 pop_parabolic2 pop_logistic2) ///
		if year > ${launch_year}, varnames ///
		border(all, nil) border(bottom, single) border(top, single)
* Format table
* Center years in first column
putdocx table tbl315(.,1), halign(center) valign(center)
* Right justify numbers
putdocx table tbl315(.,2/7), halign(right) valign(center)
* Relabel and center top row headers
putdocx table tbl315(1,1) = ("Year")
putdocx table tbl315(1,2) = ("Share of Growth")
putdocx table tbl315(1,3) = ("Shift-share")
putdocx table tbl315(1,4) = ("Linear")
putdocx table tbl315(1,5) = ("Geometric")
putdocx table tbl315(1,6) = ("Parabolic")
putdocx table tbl315(1,7) = ("Logistic")
putdocx table tbl315(1,.), halign(center) valign(center)
* Format borders
putdocx table tbl315(1,1/7), /// add top and bottom border to first row
	border(top, single) border(bottom, single)
	
putdocx save "PLAN604_Wang_vom_Hofe_Chapter_3_4_2018-11-16_${countyname}_${state}_${target_year}.docx", replace

/********-*********-*********-*********-*********-*********-*********/
/* Generate Table 3.17                                              */
/********-*********-*********-*********-*********-*********-*********/
* Table 3.17 has 3 parts
* Part 1 has the coeffiecients from the models
* Part 2 has the observed and predicted values
* Part 3 has the evaluation statistics for the models

putdocx begin
putdocx pagebreak
putdocx paragraph, halign(center)
putdocx text ("Table 3.17 "), bold
putdocx text ("Evaluation of population projections for ${countyname}, ${state}.")

* Part 1 of Table 3.17
* Make a table with 6 rows and 6 columns
putdocx table tbl317p1 = (6,6), ///
		border(all, nil) border(bottom, single) border(top, single)
putdocx table tbl317p1(1,2) = ("Observed Population Data")
putdocx table tbl317p1(1,3) = ("Linear")
putdocx table tbl317p1(1,4) = ("Geometric")
putdocx table tbl317p1(1,5) = ("Parabolic")
putdocx table tbl317p1(1,6) = ("Logistic")
putdocx table tbl317p1(1,.), halign(center) valign(center) 

putdocx table tbl317p1(2,1) = ("Base Year")
putdocx table tbl317p1(3,1) = ("Pop. Limit")
putdocx table tbl317p1(4,1) = ("Alpha")
putdocx table tbl317p1(5,1) = ("Beta 1")
putdocx table tbl317p1(6,1) = ("Beta 2")


* Add saved alphas and betas from models
local column = 3 // start the loop in column 3 for the linear model
foreach model in linear geometric parabolic logistic {
	putdocx table tbl317p1(2,`column') = ("${base_year_`model'}")
	putdocx table tbl317p1(4,`column') = ("${alpha_`model'}")
	putdocx table tbl317p1(5,`column') = ("${beta1_`model'}")
	putdocx table tbl317p1(6,`column') = ("${beta2_`model'}")
	local column = `column' + 1
}

* Add Population limit for logistic model
local pop_ceiling_text : display %8.0fc ${pop_ceiling}
putdocx table tbl317p1(3,6) = ("`pop_ceiling_text'")

* Format table
* Format borders
putdocx table tbl317p1(1,1/6), /// add top and bottom border to first row
	border(top, single) border(bottom, single)
* Center column 1
putdocx table tbl317p1(.,1), halign(center) valign(center)
* Right justify numbers in columns 3 to 6
putdocx table tbl317p1(2/6,2/6), halign(right) valign(center)

* Part 2 of Table 3.17
putdocx table tbl317p2 = data(year pop pop_linear pop_geometric pop_parabolic pop_logistic) ///
		if year <= ${launch_year} & year >= ${launch_year} - 10 /// 
		| inlist(year,${base_year_share},${base_year_linear}, ///
		${base_year_geometric},${base_year_parabolic},${base_year_logistic}), ///
		border(all, nil) border(bottom, single) border(top, single)
* Format table
* Center years in first column
putdocx table tbl317p2(.,1), halign(center) valign(center)
* Right justify numbers in columns 2 to 6
putdocx table tbl317p2(.,2/6), halign(right) valign(center)

* Part 3 of Table 3.17
putdocx table tbl317p3 = (4,6), ///
		border(all, nil) border(bottom, single) border(top, single)
putdocx table tbl317p3(1,1) = ("Standard Deviation")
putdocx table tbl317p3(2,1) = ("Mean")
putdocx table tbl317p3(3,1) = ("CRV")
putdocx table tbl317p3(4,1) = ("MAPE")

* Calcuate Absolute Percent Error for models
local column = 3 // start the loop in column 3 for the linear model
foreach model in linear geometric parabolic logistic {
	* Calculate the SD, Mean, CRV for each model
	sum pop_`model' if year <= ${launch_year}
	local standard_deviation : display %10.2fc `r(sd)'
	putdocx table tbl317p3(1,`column') = ("`standard_deviation'")
	local mean : display %10.2fc `r(mean)'
	putdocx table tbl317p3(2,`column') = ("`mean'")
	local crv : display %7.4fc `r(sd)'/`r(mean)'*100
	putdocx table tbl317p3(3,`column') = ("`crv'")
	
	* Calculate the Mean Percent Error for Each model
	gen APE_`model' = abs(residual_`model'/pop)*100
	label variable APE_`model' "Absolulte Percentage Error `model' model"
	* Save Mean Absolute Percent Error
	sum APE_`model'
	local MAPE : display %5.4fc `r(mean)'
	putdocx table tbl317p3(4,`column') = ("`MAPE'")
	local column = `column' + 1
}

* Look at mean and sd for the poopulation
sum pop if year <= ${launch_year}
local standard_deviation : display %10.2fc `r(sd)'
putdocx table tbl317p3(1,2) = ("`standard_deviation'")
local mean : display %10.2fc `r(mean)'
putdocx table tbl317p3(2,2) = ("`mean'")

* Format table
* Center years in first column
putdocx table tbl317p3(.,1), halign(center) valign(center)
* Right justify numbers
putdocx table tbl317p3(.,2/6), halign(right) valign(center)


putdocx paragraph, halign(left)
putdocx text ("Notes: Projections do not include adjustment factors.")
putdocx paragraph, halign(left)
putdocx text ("CRV: Coefficient of Relative Variation")
putdocx paragraph, halign(left)
putdocx text ("MAPE: Mean Absolute Percentage Error")

putdocx save "PLAN604_Wang_vom_Hofe_Chapter_3_4_2018-11-16_${countyname}_${state}_${target_year}.docx", append

/********-*********-*********-*********-*********-*********-*********/
/* Save File and Close Log                                          */
/********-*********-*********-*********-*********-*********-*********/

save "PLAN604_Wang_vom_Hofe_Chapter_3_4_2018-11-16.dta", replace

log close
exit



