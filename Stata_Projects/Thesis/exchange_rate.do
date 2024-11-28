/*
World Bank Data
by
Noe Vyizigiro

This is the exchange rate data downloaded from the IMF; I will use this data to compute montly exchange rate volatility. 
I will then compute the annual average, which I will merge with the world bank data.
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

import excel "$rawData/International_Financial_Statistics_.xlsx", firstrow //(make the first row variables instead of the stata generated ones. )

rename (A B) (Country series) //rename some of the variables


** keep the labels:
/*
"Exchange Rates, National Currency Per U.S. Dollar, Period Average, Rate" Aver_exchr
"Exchange Rates, Nominal Effective Exchange Rate, Index" eff_exchr
"Exchange Rates, Real Effective Exchange Rate based on Consumer Price Index, Index"reff_exchr

*/
** rename values of the series
local list `" "Exchange Rates, National Currency Per U.S. Dollar, Period Average, Rate" "Exchange Rates, Nominal Effective Exchange Rate, Index" "Exchange Rates, Real Effective Exchange Rate based on Consumer Price Index, Index" "'

local namelist "Aver_exchr eff_exchr reff_exchr"

**rename the series

local counter = 1 //creating a counter to keep track of the the position of the namelist
foreach k of local list {
    local var_name : word `counter' of `namelist' //extracting an element from the namelist
    replace series = "`var_name'" if series == "`k'"
    local counter = `counter' + 1
}
		
** generate ids	
egen country_id =group(Country)
order Country country_id
egen serie_id = group(series)
order Country country_id serie_id series 

**Reshape the data

//reshape long
reshape long Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec, i(country_id serie_id) j(year) 
drop serie_id

//reshape wide
reshape wide Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec, i(country_id year) j(series) string 

//rename the variable to make it easier to reshape long again
rename (Jan* Feb* Mar* Apr* May* Jun* Jul* Aug* Sep* Oct* Nov* Dec*) (*Jan *Feb *Mar *Apr *May *Jun *Jul *Aug *Sep *Oct *Nov *Dec) 

//reshape long again
reshape long Aver_exchr eff_exchr reff_exchr, i(country_id year) j(month) string 

** formate dates and sort the data by month
gen date = monthly(month + string(year), "MY")
format date %tmMon_CCYY

gen month_num = .
replace month_num = 1 if month == "Jan"
replace month_num = 2 if month == "Feb"
replace month_num = 3 if month == "Mar"
replace month_num = 4 if month == "Apr"
replace month_num = 5 if month == "May"
replace month_num = 6 if month == "Jun"
replace month_num = 7 if month == "Jul"
replace month_num = 8 if month == "Aug"
replace month_num = 9 if month == "Sep"
replace month_num = 10 if month == "Oct"
replace month_num = 11 if month == "Nov"
replace month_num = 12 if month == "Dec"

sort country_id year month_num

order country_id date Country year month //ordeer the variables

how to calculate sd?

//calculte percentage change of echange rate betwen two month; %change of log




