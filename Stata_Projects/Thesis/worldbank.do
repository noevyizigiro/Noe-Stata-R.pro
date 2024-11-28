/*
World Bank Data
by
Noe Vyizigiro
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

import excel "$rawData/World_Development_Indicators.xlsx", firstrow

**remove the double dots in the dataset

foreach v of varlist YR1999 - YR2023{
	qui replace `v'="." if `v'==".."
}

qui destring, replace  //destring all variables containing numerics

sort CountryName
drop if SeriesName==""
egen id= group (CountryName SeriesName)
order id CountryName
sort id
drop SeriesCode 
encode SeriesName, gen(series2)

order id CountryName CountryCode SeriesName series2

local namelist "electricity agri_va_pgdp agri_va_gr bmoney_pgdp bmoney_gr gov_debt coal_rent cpi est_corrupt rank_corrupt cost_busi cr_pi depo_int busi_ease energy_impo expense fpi fdi_inflow fdi_outflow ff_consump fuel_expo fuel_impo GDP GDP_growth GDPP_growth gove_est gove_indx gcf_pgdp gcf_gr GDS_pgdp GDS_curr HCI ind_va_pgdp ind_va_gr inflation int_migr lend_int man_va_pgdp man_va_gr march_trade min_rent ngas_rent oil_rent real_int tax_rev totnr_rent "

local counter = 1 //creating a counter to keep track of the the position of the namelist
forval k =1/46 {
    local var_name : word `counter' of `namelist' //extracting an element from the namelist
    qui replace SeriesName = "`var_name'" if series2 == `k'
    local counter = `counter' + 1
}

/*used to keep specific series
gen to_keep = 0  // Create a flag variable to identify rows to keep

foreach i of local list {
    replace to_keep = 1 if serial_code == "`i'" //loop through each value in the list and set to_keep ==1 for each raw where serial code matches one of the value in the list
}

keep if to_keep == 1 //keep those raws that have been found matches
*/


drop series2 
** Reshape the data to get the format wanted
/*
to reshape your data into long format:
1) make sure your data has a id that uniquely identify the obervation; if not create one
2) use command reshape long + the variables that you want to turn into colums, then id then the name of your column in j
*/

//i: antity identifier
//j: time identifier

reshape long YR, i(id) j(year) // reshape long using identifiers

drop id
reshape wide YR, i(year CountryName) j(SeriesName) string //reshape wide
rename YR* * //remove y on the variable
rename CountryName country
rename CountryCode c_code


order country c_code year  //rearrange the variables

** label my variables
local var1 "GDP GDPP_growth GDP_growth GDS_curr GDS_pgdp HCI agri_va_gr agri_va_pgdp bmoney_gr bmoney_pgdp busi_ease coal_rent cost_busi cpi cr_pi depo_int electricity energy_impo est_corrupt expense fdi_inflow fdi_outflow ff_consump fpi"

local mylabels1 `" "GDP (current US$)" "GDP per capita growth (annual %)" "GDP growth (annual %)" "Gross domestic savings (current US$)" "Gross domestic savings (% of GDP)" "Human capital index (HCI) (scale 0-1)" "Agriculture, forestry, and fishing, value added (annual % growth)" "Agriculture, forestry, and fishing, value added (% of GDP)" "Broad money growth (annual %)" "Broad money (% of GDP)" "Ease of doing business score (0 = lowest performance to 100 = best performance)" "Coal rents (% of GDP)" "Cost of business start-up procedures (% of GNI per capita)" "Consumer price index (2010 = 100)" "Crop production index(2014-2016 = 100)" "Deposit interest rate (%)" "Access to electricity (% of population)" "Energy imports, net (% of energy use)" "Control of Corruption: Estimate" "Expense (% of GDP)" "Foreign direct investment, net inflows (% of GDP)" "Foreign direct investment, net outflows (% of GDP)" "Fossil fuel energy consumption (% of total)" "Food production index (2014-2016 = 100)" "'  

forval n = 1/24 {
    local a: word `n' of `mylabels1'
    local b: word `n' of `var1'
    di "variable `b', label `a'"
    label var `b' "`a'"
}


local var2  "fuel_expo fuel_impo gcf_gr gcf_pgdp gov_debt gove_est gove_indx ind_va_gr ind_va_pgdp inflation int_migr lend_int man_va_gr man_va_pgdp march_trade min_rent ngas_rent oil_rent rank_corrupt real_int tax_rev totnr_rent" 

local mylabels2 `" "Fuel exports (% of merchandise exports)" "Fuel imports(% of merchandise imports)" "Gross capital formation (annual % growth)" "Gross capital formation (% of GDP)" "Central government debt, total (% of GDP)" "Government Effectiveness: Estimate" "Government Effectiveness: Percentile Rank" "Industry (including construction), value added (annual % growth)" "Industry (including construction), value added (% of GDP)" "Inflation, consumer prices (annual %)" "International migrant stock (% of population)" "Lending interest rate (%)" "Manufacturing, value added (annual % growth)" "Manufacturing, value added (% of GDP)" "Merchandise trade (% of GDP)" "Mineral rents (% of GDP)" "Natural gas rents (% of GDP)" "Oil rents (% of GDP)" "Control of Corruption: Percentile Rank" "Real interest rate (%)" "Tax revenue (% of GDP)" "Total natural resources rents (% of GDP)" "'
 

forval n = 1/22 {
    local a: word `n' of `mylabels2'
    local b: word `n' of `var2'
    di "variable `b', label `a'"
    label var `b' "`a'"
}

** drop variables with lots of missing values

foreach d of local namelist{
	count if !missing(`d')
	 if r(N) < 1000 {
        drop `d'
        di "`d' dropped because it has less than 1000 non-missing observations"
    }
	
}
//drop more variables
drop if year ==2023
sort country



//ds or describe, simple: to look at variable names; des: to look at them with their descriptions; codebook: to look at them all with everything.
// Use describe to store the variable names in a local macro


local varlist "GDS_curr coal_rent fpi inflation rank_corrupt c_code GDS_pgdp cpi gcf_pgdp man_va_pgdp totnr_rent agri_va_gr cr_pi gove_est march_trade GDP agri_va_pgdp electricity gove_indx min_rent GDPP_growth bmoney_gr est_corrupt ind_va_gr ngas_rent GDP_growth bmoney_pgdp fdi_inflow ind_va_pgdp oil_rent"

// Get a list of unique countries
levelsof country, local(countries)

// Loop through each country
foreach c of local countries {
   qui count if country == "`c'" & !missing(GDP)
    // If total non-missing values across all variables are less than 20, drop the country
    if r(N) < 20 {
        drop if country == "`c'"
        di "`c' dropped because it has less than 20 non-missing values across variables."
    }
}

// rename countries

replace country= "DR Congo" if country=="Congo, Dem. Rep."
replace country= "Central African Rep." if country=="Central African Republic"
replace country= "Congo" if country=="Congo, Rep."
replace country ="Gambia" if country =="Gambia, The"

egen c_id = group(country)

** merge it with fdi data
merge 1:1 country year using "$deriveData/fdi.dta", keep(match) nogen
 
save "$deriveData/Vy_worldbank2", replace

 
 
 



  


