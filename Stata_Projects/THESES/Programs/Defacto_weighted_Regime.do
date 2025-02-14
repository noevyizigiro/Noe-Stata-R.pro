/*
FDI inflow
by
Noe Vyizigiro

This scripts wrangles data about exchange rate regime
source: Ethan Ilzetzki, Carmen Reinhart and Ken Rogoff, Rethinking Exchange Rate Regimes (with Carmen Reinhart and Ken Rogoff). Handbook of International Economics, vol 5, Gita Gopinath, Elhanan Helpman and Kenneth Rogoff, eds, 2021.(IRR),

gathered by : Philipp Harms & Jakub Knaze, 2021. "Effective Exchange Rate Regimes and Inflation",  Working Paper 2102, Gutenberg School of Management and Economics, Johannes Gutenberg-Universität Mainz.
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES" // replace this with your own directory

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

import excel "$rawData/Weighted_DeFacto_Regimes_2022.xlsx", firstrow

replace country ="Cote d-Ivoire" if country =="Cote d'Ivoire"

local ssa `" "Angola" "Botswana" "Burundi" "Eswatini" "Ethiopia" "Lesotho" "Malawi" "Rwanda" "Uganda" "Zambia" "Benin" "Burkina Faso" "Guinea-Bissau" "Mali" "Niger" "Cote d-Ivoire" "Senegal" "Togo" "Cameroon" "Central African Republic" "Chad" "Congo, Republic of" "Gabon" "Congo, Democratic Republic of"  "Djibouti" "Eritrea" "Gambia" "Ghana" "Guinea" "Kenya" "Liberia" "Madagascar" "Mauritius" "Mauritania" "Mozambique" "Namibia" "Nigeria" "Sierra Leone" "Somalia" "South Africa" "Sudan" "Tanzania" "Uganda" "Zimbabwe" "'

gen retained =0

foreach c of local ssa {
	replace retained =1 if country =="`c'"	
}
drop if retained!=1

** rename some country
capture replace country= "DR Congo" if country=="Congo, Democratic Republic of"
capture replace country= "Central African Rep." if country=="Central African Republic"
capture replace country= "Congo" if country=="Congo, Republic of"
capture replace country ="Gambia" if country =="Gambia, The"
capture replace country ="Cote d-Ivoire" if country =="Cte d'Ivoire"

drop iso ifs effective_* retained independence_dummy


foreach i of varlist *_dummy {
    local newname = subinstr("`i'", "_dummy", "", .)  // Remove "_dummy" from the variable name
    rename `i' `newname'
}

save "$deriveData/Rogoff_regime.dta", replace

exit

encode country, gen (country2)
collapse (count) country2, by(year dual_market)
drop if regime ==""
reshape wide c_currency, i(year) j(regime) string



