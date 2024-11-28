
/*
Noe Vyizigiro
Causal Inference
Fall 2024

Assignment 3: Event Study Designs/Data cleaning
*/

clear all

global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /Fall_24/Causal Inference/Assignment3/Analysis"

cd "$noeVy"

global pathDoFile 	"$noeVy/Program_Files" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global Data 	"$noeVy/Data" //where data data is located


**laod data***

foreach group in Total Hispanic White NativeAmerican Black Asian  {
	import delimited "$Data/mortality_`group'.txt", encoding(ISO-8859-9)  clear
	drop notes *code
	drop if tenyearagegroups == "Not Stated"
	foreach var in population cruderate {
		capture replace `var'="" if `var'=="Suppressed" | `var'=="Unreliable"
		capture destring `var', replace
	}
gen race = "`group'"
tempfile `group' 
save ``group'', replace
}


use `Total', replace

**append data***
foreach group in Hispanic White NativeAmerican Black Asian {
    append using ``group''
}


drop if state==""
rename tenyear agegroup
rename cruderate mortrate
sort state year agegroup gender race
order state year agegroup gender race deaths population mortrate

save "$Data/combined_mortality_data.dta", replace
rename state state_name


** merge with the state fip data set***

merge m:1 state_name using "$Data/state identifiers.dta", keep(match) nogen

rename state_name state
order state state_fips


**Add in the policy variables measuring Medicaid expansion as well as add in some control variables****
local exp2014 "AR AZ CA CO CT HI IL IA KY MD MI MN NJ NM NV ND OH OR RI WA WV"
local exp2015 "NH PA IN"
local exp2016 "AK MT"
local exp2017 "LA"
local exp2019 "ME VA"
local exp2020 "ID NE UT"
local exp2021 "OK MO"
local exp2023 "SD NC"

// a state is coded to have expanded in the subsequent year if they expand on or after july 1 of a given year

gen tstar = 0


foreach year in 2014 2015 2016 2017 2019 2020 2021 2023 {
    local states = "`exp`year''"
    
    foreach s of local states {
        replace tstar = `year' if postal_code == "`s'"
    }
}

//check the match
tab postal_code, sum(tstar) means nof

**merge with stateXyear data**
merge m:1 year state_fips using "$Data/statexyear controls.dta", keep(match) nogen

destring state_fips, replace
sort state_fips year
xtset state_fips  


save "$Data/Clean Data.dta", replace //save the cleaned data


**end**











