/*
FDI inflow
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

import excel "$rawData/fdi_inflow.xls", firstrow

** bring years back to the top as variable
foreach v of varlist _all {
    local lbl : variable label `v' //extracts the label of the variable v and store it  in the local macro lbl
    local lbl_clean = strtoname("`lbl'") //cleans the label by coverting into a valid stata name using strtoname()
    rename `v' `lbl_clean'
}



replace Indicator_Name ="FDI_inflow" if Indicator_Name=="Foreign direct investment, net inflows (% of GDP)"
drop Indicator_Code 

**Reshape

sort Country_Name
reshape long _, i(Country_Name) j(year) // reshape long using identifiers

reshape wide _, i(year Country_Name) j(Indicator_Name) string

rename Country_Name country
rename Country_Code c_code
order country c_code
rename _FDI_inflow FDI_inflow

drop if year<1999
label var FDI_inflow "Foreign direct investment, net inflows (% of GDP)"

replace country= "DR Congo" if country=="Congo, Dem. Rep."
replace country= "Central African Rep." if country=="Central African Republic"
replace country= "Congo" if country=="Congo, Rep."
replace country ="Gambia" if country =="Gambia, The"

save "$deriveData/fdi.dta"
