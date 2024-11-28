/*
Senior Thesis
by
Noe Vyizigiro

This is a do-file for analyis. Event study
*/

clear all

**install packages***
*ssc install regsave 
*ssc install eventdd
*ssc install regsave
*ssc install matsort


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

use "$deriveData/Vy_worldbank3.dta"


** most of country had a floating regime since 1999 and the regime ended at different times. I consider the country who had a floating regime and when they adopt a new policy (switched from floating to a new one)

xtset country_id year
local newp2005 "MRT"
local newp2006 "AGO ETH RWA NGA SLE"
local newp2007 "MWI"
local newp2009 "BDI"
local newp2010 "SDN COD"
local newp2016 "KEN TZA"


gen npstar = 0

foreach year in 2005 2006 2007 2009 2010 2016{
    local curr = "`newp`year''"
    
    foreach c of local curr {
        replace npstar = `year' if c_code == "`c'"
    }
}

tab c_code, sum(npstar) means nof

gen j =year-npstar 
replace j= . if npstar==0



**event study**
//vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade

# delimit ;
eventdd vol_er_usd i.year i.c_currency, 
	cluster(country_id)
	timevar(j)  
	coef_op(mcolor(navy)) 
	ci(rcap, color(navy%30)) 
	leads(6) /*specify leads (those correspond to negative event times)*/
	lags(5) /*specify lagss (those correspond to positive event times)*/
	accum   /*I'm telling it to bin or "accumulate" all event times at the ends*/
	noend   /*I'm telling it not to graph the binned ends*/
	noline /*I'm suppressing the package's line at j=-1 so I can format my own*/
	graph_op(
		ylabel(-0.3(0.01)0.3)
		xline(-1,lpattern(dot) lcolor(gs5))
		xlabel(-6(1)5)
		legend(off)
		title("Effect of Exchange Rate Policy change on FDI")
		ytitle("Change in FDI infoow")
		xtitle("Time since policy change")
		name(eventdd_male, replace)
		
	)
	
	;		
# delimit cr
