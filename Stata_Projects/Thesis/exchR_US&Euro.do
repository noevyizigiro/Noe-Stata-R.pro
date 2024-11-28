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

import excel "$rawData/exchange_rate_US&Euro.xlsx", firstrow //(make the first row variables instead of the stata generated ones. )


drop in 1/1
rename (A B) (Country series) //rename some of the variables


** keep the labels:
/*
"Exchange Rates, National Currency Per U.S. Dollar, Period Average, Rate" to_USD
"Exchange Rates, Domestic Currency per Euro, Period Average, Rate" to_Euro


*/

**rename the series

replace series ="to_USD" if series=="Exchange Rates, National Currency Per U.S. Dollar, Period Average, Rate"
replace series ="to_Euro" if series =="Exchange Rates, Domestic Currency per Euro, Period Average, Rate"

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
reshape long to_USD to_Euro, i(country_id year) j(month) string 

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

drop if year<1999

*** Compute the volatility
egen c_year =group(year Country)

egen to_USD_sd = sd(to_USD), by(c_year)
egen to_Euro_sd =sd(to_Euro), by(c_year)

egen mean_to_USD =mean(to_USD), by(c_year)
egen mean_to_Euro =mean(to_Euro), by(c_year)

gen vol_er_usd = to_USD_sd/mean_to_USD
gen vol_er_euro = to_Euro_sd/mean_to_Euro

//rename some countries
replace Country= "DR Congo" if Country=="Congo, Dem. Rep. of the"
replace Country= "Ethiopia" if Country=="Ethiopia, The Federal Dem. Rep. of"
replace Country= "Lesotho" if Country=="Lesotho, Kingdom of"
replace Country= "Madagascar" if Country=="Madagascar, Rep. of"
replace Country= "Mauritania" if Country=="Mauritania, Islamic Rep. of"
replace Country= "Mozambique" if Country=="Mozambique, Rep. of"
replace Country= "South Sudan" if Country=="South Sudan, Rep. of"
replace Country= "Tanzania" if Country=="Tanzania, United Rep. of"
replace Country= "Eswatini" if Country=="Eswatini, Kingdom of"
replace Country= "Eritrea" if Country=="Eritrea, The State of"
replace Country= "Equatorial Guinea" if Country=="Equatorial Guinea, Rep. of"
replace Country= "Congo" if Country=="Congo, Rep. of"

rename Country country
exit
//save monthly first before collapse
save "$deriveData/montly_exchangeRate_US&Euro", replace

//make it annual
collapse (mean) vol_er_usd vol_er_euro, by(country year) 

** save final dataset to the cleaned data folder

save "$deriveData/Vy_exchangeRate_US&Euro", replace
