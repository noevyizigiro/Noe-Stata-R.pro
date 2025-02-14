/*
FDI inflow
by
Noe Vyizigiro

regional Gross domestic investment and foreign direct investment
Source: World Develolpment Indicator.
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

//import excel "$rawData/fdi_inflow.xls", firstrow
import delimited "$rawData/WDI_Region_inv_Data.csv"

//exit

** remove the double dots and destring

foreach v of varlist _all{
	capture qui replace `v'="." if `v'==".."
}

qui destring, replace  //destring all variables containing numerics


** drop the empty and comment raws in the dataset
local country_name `" "Sub-Saharan Africa" "Low income" "High income" "Latin America & Caribbean" "South Asia" "Middle income" "'

gen todrop =0
foreach i of local country_name{
	replace todrop =1 if countryname == "`i'"
}
drop if todrop==0 
drop todrop seriescode


** remame the series name
replace seriesname ="FDI" if seriesname=="Foreign direct investment, net inflows (% of GDP)"
replace seriesname ="GCF" if seriesname=="Gross capital formation (% of GDP)"


**Reshape
egen id =group(countryname seriesname)
order countryname id
sort countryname

reshape long yr, i(id) j(year) // reshape long using identifiers
drop id

reshape wide yr, i(year countryname countrycode) j(seriesname) string

rename countryname country
rename countrycode c_code
order country c_code year
rename yr* * //remove yr from the variable names.

label var FDI "Foreign direct investment, net inflows (% of GDP)"
label var GCF "Gross capital formation (% of GDP)"

gen GDI =GCF-FDI

#delimit ;
twoway (line FDI year if country == "South Asia", lcolor(red)) ||
	   (line FDI year if country == "Latin America & Caribbean", lcolor(green)) ||
       (line FDI year if country == "Sub-Saharan Africa", lcolor(blue) lpattern(dash)) ||
	   (line FDI year if country == "High income", lcolor(black)),
        title("FDI") 
		//subtitle("Average 1974-2023")
        ytitle("FDI Inflow (net, %GDP)") xtitle("Year")
       legend(order(4 "High Income" 3 "SSA" 2 "Latin America" 1 "South Asia") position(9) ring(0))
	   name(FDI, replace);
#delimit cr;

#delimit ;
twoway (line GDI year if country == "South Asia", lcolor(red)) ||
	   (line GDI year if country == "Latin America & Caribbean", lcolor(green)) ||
       (line GDI year if country == "Sub-Saharan Africa", lcolor(blue) lpattern(dash)) ||
	   (line GDI year if country == "High income", lcolor(black)),
        title("GDI") 
		//subtitle("Average 1974-2023")
        ytitle(" GDI (%GDP)") xtitle("Year")
       legend(order(4 "High Income" 3 "SSA" 2 "Latin America" 1 "South Asia") position(7) ring(0))
	   name(GDI, replace)
;
#delimit cr;

graph combine FDI GDI, name(graphR, replace)

graph export "$pathOutput/FDI_DI_regions.png", replace

save "$deriveData/fdi_gcf.dta", replace



