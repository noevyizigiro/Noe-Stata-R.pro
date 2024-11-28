/*
World Bank Data
by
Noe Vyizigiro

This is the exchange rate regime data downloaded from the IMF
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

import excel "$rawData/IMF_AREAER-ExchaRegime.xls", firstrow //(make the first row variables instead of the stata generated ones. )

**EXCHANGE RATE REGIME CLASSIFICATION INTO BIG GROUPS
/*
1. Hard_pegs (Fixed) (no separate legal tender; Currency Board Arrangement; currency board; exchange arrangement with no separate legal tender ) ==> no separate legal tender, currency board==>Fixed
2. Soft_pegs (Managed) (conventional peg; conventional pegged arrangement; Crawl-like arrangement; Crawling peg; Pegged exchange rate within horizontal Bands; Stabilized arrangement; other managed )
3. Floating (Floating) (Floating; Free floating; Independently floating; Managed floating with no pre­determined path for the exchange rate )
*/

encode Category, gen (catnum) //generate a variable that is not a string to enable numlabel
numlabel, add

gen catnum2 =""
replace catnum2 ="peg_conv" if catnum ==1 |catnum==2
replace catnum2 ="crawlike" if catnum ==3
replace catnum2 ="peg_crawl" if catnum ==4
replace catnum2 ="curr_board" if catnum ==5 |catnum==6
replace catnum2 ="no_seplt" if catnum ==7 |catnum==12
replace catnum2 ="floating" if catnum ==8
replace catnum2 ="ffloating" if catnum ==9 |catnum==10
replace catnum2 ="manfloating" if catnum ==11
replace catnum2 ="omanaged" if catnum ==13
replace catnum2 ="peg_hband" if catnum ==14
replace catnum2 ="stabilized" if catnum ==15
	

/*
local fixed `" "No separate legal tender" "Currency board arrangement" "Currency board" "Exchange arrangement with no separate legal tender" "'
local managed `" "Conventional peg" "Conventional pegged arrangement" "Crawl-like arrangement" "Crawling peg" "Pegged exchange rate within horizontal bands" "Stabilized arrangement" "Other managed arrangement" "'
local floating `" "Floating" "Free floating" "Independently floating" "Managed floating with no pre­determined path for the exchange rate" "'

foreach f of local fixed{
	foreach m of local managed{
		foreach fl of local floating{
		replace Category = "Fixed" if Category == "`f'"
		replace Category = "Managed" if Category == "`m'"
		replace Category = "Floating" if Category == "`fl'"
		}
	} 
}

*/
**drop variables, Reshape, and rename
drop IFSCode Code Index catnum Category

reshape wide Status, i(Country Year) j(catnum2) string
rename Status* * //remove the stutus prefix

local varnames "peg_conv crawlike peg_crawl curr_board no_seplt floating ffloating  manfloating omanaged peg_hband stabilized"
foreach var of local varnames{
	replace `var'="1" if `var' =="yes"
	destring `var', replace
	replace `var' =0 if `var'==.
}

//grouping different similar variables
egen Fixed= rowmax(curr_board stabilized)
egen Managed= rowmax(peg_conv peg_crawl no_seplt crawlike stabilized omanaged peg_hband)
egen Floating= rowmax(floating ffloating manfloating)


**label variables the grouped variables

local variables " Fixed Managed Floating"
local mylabels `" "No separate legal; tender Currency board arrangement; Currency board; Exchange arrangement with no separate legal tender" "Conventional peg; Conventional pegged arrangement; Crawl-like arrangement; Crawling peg; Pegged exchange rate within horizontal bands; Stabilized arrangement; Other managed arrangement" "Floating; Free floating; Independently floating; Managed floating with no pre­determined path for the exchange rate"  "'

 forval n = 1/3{
    local a: word `n' of `mylabels'
    local b: word `n' of `variables'
    di "variable `b', label `a'"
    label var `b' "`a'"
 }
 
 **label variables the non grouped variables
 local varlabels `" "Conventional peg; Conventional pegged arrangement" "Crawl-like arrangement" "Crawling peg" "Currency board;Currency board arrangement" "No separate legal tender; Exchange arrangement with no separate legal tender" "Floating" "Free floating; Independently floating" "Managed floating with no pre­determined path for the exchange rate" "Other managed arrangement"  "Pegged exchange rate within horizontal bands" "Stabilized arrangement" "'
 
 forval n = 1/11{
    local a: word `n' of `varlabels'
    local b: word `n' of `varnames'
    di "variable `b', label `a'"
    label var `b' "`a'"
 }
 order Country Year Fixed Managed Floating
 
 ** rename some of the countries:
 replace Country= "DR Congo" if Country=="Congo, Democratic Republic of the"
 replace Country= "Congo" if Country=="Congo, Republic of"
 replace Country= "Gambia" if Country=="Gambia, The"
 replace Country= "Central African Rep." if Country=="Central African Republic"
 
 rename Country country
 rename Year year
 
 ** save final dataset to the cleaned data folder

save "$deriveData/Vy_exchRegime", replace
exit

//other study

bro country year Fixed Managed if Managed ==1 & year>=2006
bro country year Fixed Managed Floating if Floating ==1 & year>=2006
