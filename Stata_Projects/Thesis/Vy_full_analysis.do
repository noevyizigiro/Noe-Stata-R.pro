/*
Senior Thesis
by
Noe Vyizigiro

This is a do-file for analyis. it combines all the cleaned dataset used for this study
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

use "$deriveData/Vy_worldbank2.dta"

** Merge dataset
//merge m:1 country year using "$deriveData/Vy_exchRegime.dta",assert(3) keep(3) nogen

merge 1:1 country year using "$deriveData/Vy_exchRegime.dta" , keep(match) nogen
merge 1:1 country year using  "$deriveData/Vy_exchangeRate_US&Euro.dta" , keep(match) nogen

drop if country =="Somalia"
drop if country =="Zimbabwe" //has lots of missing data on exchange rate (2009-2019)
drop if country =="Liberia"


/*
foreach var of varlist _all {
    // Check if the variable is numeric
    capture confirm numeric variable `var'
    if !_rc {  // If numeric, apply the numeric format
        format `var' %9.2f
    }
}
*/


gen cfa_xof=0
gen cfa_xaf =0

local cfa_central `""Benin" "Burkina Faso" "Guinea-Bissau" "Mali" "Niger" "Senegal" "Togo""'
foreach c of local cfa_central{
	replace cfa_xof =1 if country =="`c'"
}

local cemac `" "Cameroon" "Central African Rep." "Chad" "Congo" "Gabon" "' 
foreach ce of local cemac{
	replace cfa_xaf =2 if country =="`ce'"
}

preserve

collapse (mean) GDS_pgdp cr_pi gove_indx ngas_rent crawlike peg_conv agri_va_gr electricity ind_va_gr oil_rent curr_board peg_crawl agri_va_pgdp est_corrupt ind_va_pgdp rank_corrupt ffloating peg_hband GDP bmoney_gr fdi_inflow FDI_inflow inflation totnr_rent floating stabilized GDPP_growth bmoney_pgdp fpi man_va_pgdp Fixed manfloating vol_er_usd GDP_growth coal_rent gcf_pgdp march_trade Managed no_seplt  vol_er_euro GDS_curr cpi gove_est min_rent Floating omanaged [aweight = GDP], by(year cfa_xof)

drop if cfa_xof ==0
replace cfa_xof =3 if cfa_xof==1

tempfile temp
save `temp'

restore

append using `temp'
replace country ="CFA_XOF" if country ==""
replace c_code ="CFXF" if c_code==""


preserve

collapse (mean) GDS_pgdp cr_pi gove_indx ngas_rent crawlike peg_conv agri_va_gr electricity ind_va_gr oil_rent curr_board peg_crawl agri_va_pgdp est_corrupt ind_va_pgdp rank_corrupt ffloating peg_hband GDP bmoney_gr fdi_inflow FDI_inflow inflation totnr_rent floating stabilized GDPP_growth bmoney_pgdp fpi man_va_pgdp Fixed manfloating vol_er_usd GDP_growth coal_rent gcf_pgdp march_trade Managed no_seplt vol_er_euro GDS_curr cpi gove_est min_rent Floating omanaged [aweight = GDP], by(year cfa_xaf)

drop if cfa_xaf ==0
drop if cfa_xaf==.
replace cfa_xaf = 4 if cfa_xaf==2

tempfile temp2
save `temp2'
restore

append using `temp2'

replace country ="CEMAC" if country ==""
replace c_code ="CMC" if c_code==""

//now done grouping the country that use the same currency together.
**drop the individual countries

drop if cfa_xof==1 
drop if cfa_xaf== 2
drop cfa_xaf cfa_xof

sort country
egen country_id = group(country)
order country country_id
xtset country_id year

* generate a DI or domestic capital formaton variable
gen di = gcf_pgdp - fdi_inflow
label var di "Gross Domestic Capital formaton; this can be used as a proxy of DI"
rename di GDI

* generate a variable that is the mean FDI-inflow  and di for each country 
bys country: egen fdi_avg=mean(FDI_inflow)

bys country: egen vol_avg = mean(vol_er_usd)
bys country: egen di_avg = mean(GDI)


** generate regime variable
gen regime =""
replace regime ="Managed" if Managed==1
replace regime ="Floating" if Floating==1
replace regime ="Fixed" if Fixed ==1
encode regime, gen(Regime)

replace peg_crawl=1 if peg_hband==1 & country =="Sudan" //it has only one observation
drop peg_hband
drop curr_board //there is no country with a current board in our sample

gen regime2 =""
replace regime2 ="Crawlike" if crawlike==1
replace regime2 ="Free_Floating" if ffloating==1
replace regime2 ="Floating" if floating==1
replace regime2 ="Man_Floating" if manfloating==1
replace regime2 ="No_Seplt" if no_seplt==1
replace regime2 ="O_Managed" if omanaged==1
replace regime2 ="Conv_ped" if peg_conv==1
replace regime2 ="Crawl_peg" if peg_crawl==1
replace regime2 ="Stabilized" if stabilized==1
encode regime2, gen(Regime2)


** generate countries based on their geographic location
local landlock `""Botswana" "Burundi" "Eswatini" "Ethiopia" "Lesotho" "Malawi" "Rwanda" "Uganda" "Zambia""'
  
gen landlocked =0
foreach i of local landlock{
	replace landlocked=1 if country =="`i'"
}


encode country, gen(c_currency)
order country c_currency



*============================================================================*
* Summary Statistics
*===========================================================================*

tab country, sum(fdi_inflow) means nof
tab country, sum(vol_avg) means nof
tab c_code, sum(GDI) means nof


** 1. Summary of the variables used in the model**
estpost tabstat fdi_inflow GDI vol_er_usd  GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation fpi march_trade, c(stat) stat( mean sd min max n)
//ereturn list

   
#delimit;
esttab using "$pathOutput/summaryTable.tex", replace
 cells("mean(fmt(2)) sd min max count(fmt(0))") nonumber
  nomtitle nonote noobs nolabel booktabs 
  collabels("Mean" "SD" "Min" "Max" "Obs") 
  title("Summary Statistics \label{table1stata}")
  coeflabels(fdi_inflow "FDI-Inflow(\%GDP)" GDI "G.Domestic Investment" vol_er_usd "Volatility-ExRate(to USD)" GDPP_growth "Per Capita GDP Growth" GDS_pgdp "G.Domestic Saving" bmoney_gr "Board Money Growth" electricity "Electrification" est_corrupt "Corruption control" gove_est "Gov.Effectiveness" cr_pi "Crop Prod. Index" inflation  "Inflation" fpi "Food Prod Index" march_trade "Marchandise Trade")

;
#delimit cr;



** summary by country**

estpost tabstat fdi_inflow GDI vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation fpi march_trade, by(country) c(stat) stat( mean sd) 

 
#delimit;
esttab using "$pathOutput/summaryTable2.tex", replace
cells(mean(fmt(2)) sd(par)) nonumber unstack
   nonote noobs nolabel 
   collabels(none) gap 
   //eqlabels("Angola" "North Central" "South" "West") /// 
    title("Summary Statistics on Country Level \label{table1stata}")
	coeflabels(fdi_inflow "FDI-Inflow(\%GDP)" GDI "G.Domestic Investment" vol_er_usd "Volatility-ExRate(to USD)" GDPP_growth "Per Capita GDP Growth" GDS_pgdp "G.Domestic Saving" bmoney_gr "Board Money Growth" electricity "Electrification" est_corrupt "Corruption control" gove_est "Gov.Effectiveness" cr_pi "Crop Prod. Index" inflation "Inflation" fpi "Food Prod Index"  march_trade "Marchandise Trade")
	
	
	substitute( //this is to ajust the table's size. we use substitute: tell stata to replace the first by the second
	{table} {sidewaystable} //rotating the table
	"[htbp]" "[!htbp]"
	"\begin{tabular}" "\begin{adjustbox} {max width = \linewidth}\begin{tabular}"
	"\end{tabular}" "\end{tabular}\end{adjustbox}"
)
addnotes("This is a summary table per country's currency level. Standard errors are in paranthesis")
;
#delimit cr;

//coal_rent "Coal Rents" ngas_rent "Natural Gas Rents" min_rent "Mineral Rents" oil_rent "Oil Rents" totnr_rent "Total Rents"



// we using instrument to analyze the causal impact between excange rate vol and investment, using instrument prvent reverse causality.

save "$deriveData/Vy_worldbank3", replace
**Further tests



*============================================================================*
* Regression Models
*===========================================================================*
ssc install estout
eststo clear

reg vol_er_usd i.Regime2, robust

qui reg vol_er_usd Fixed Floating i.year i.c_currency, robust //the f-statistc less than 10

 reg vol_er_usd crawlike ffloating floating manfloating peg_conv omanaged no_seplt peg_crawl, robust //f-test: 92.88
predict y_hat //the mean of the predicted value is equal to the actual mean of the original value, which is vol_er_usd. this is because the difference between predicted value and actual value is the residual 


**try this:

reg vol_er_usd crawlike ffloating floating manfloating peg_conv omanaged no_seplt peg_crawl GDPP_growth GDS_pgdp bmoney_gr est_corrupt gove_est cr_pi inflation march_trade i.c_currency, robust
**F-stat: 13.42
predict yhat 


**using ivregress**

// ivregress 2sls fdi_inflow GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade  i.c_currency ( vol_er_usd= crawlike ffloating floating manfloating peg_conv omanaged no_seplt peg_crawl), first robust

eststo clear

*** Foreign Direct Investment***

local notes1 "Robust standard errors are in parentheses. Model 1 is estimated without fixed effects; from model (4), both time and currency fixed effects are used to estimate the models. The dependent variable is Foreign direct investment, net inflow, and percentage of GDP. The sample include 26 currencies, from 1999-2021, used in 36 sub-Saharan African countries.The Stars are significant level where * 0.10 ** 0.05 *** 0.01. "

local title1 "Regression Table: Foreign Direct Investment Net Inflow"


eststo m1 : qui reg fdi_inflow yhat i.c_currency i.year, robust 

estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m2 : qui reg fdi_inflow yhat est_corrupt GDPP_growth i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m3 : qui reg fdi_inflow yhat GDPP_growth est_corrupt electricity gove_est inflation i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m4 : qui reg fdi_inflow yhat GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade  i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m5 : qui reg fdi_inflow vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade  i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"

esttab m1 m2 m3 m4 m5, keep(yhat vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade) nonumber


#delimit ;
esttab m1 m2 m3 m4 m5 using "$pathOutput/Regression Table_FDI.tex", replace 
    keep(yhat vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade) 
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    nomtitle
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	coeflab(yhat "Exchange Rate Volatility(IV)" vol_er_usd "Exchange Rate Volatility" GDPP_growth "GDP per Capita Growth" GDS_pgdp "Gross Domestic Saving" bmoney_gr "Broad Money Growth" est_corrupt "Corruption control" gove_est "Government Effectiveness" cr_pi "Crop Prod. Index" inflation "Inflation" march_trade "Marchandise Trade(\%gdp)")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`title1'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{5}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{6}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} 
	\footnotesize \item `notes1' \end{table})
	;
#delimit cr;



**Domestic investment***

local notes2 "Robust standard errors are in parentheses. Model 1 is estimated without fixed effects; from model (4), both time and currency fixed effects are used to estimate the models. The dependent variable is the Gross Domestic Investment, which is the difference between Gross capital investment and foreign direct investment,net inflow, both in percentage of GDP. The sample include 26 currencies, from 1999-2021, used in 36 sub-Saharan African countries.The Stars are significant level where * 0.10 ** 0.05 *** 0.01"

local title2 "Regression Table: Domestic Investment"

eststo m01 : qui reg GDI yhat i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m02 : qui reg GDI yhat est_corrupt GDPP_growth i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m03 : qui reg GDI yhat GDPP_growth est_corrupt gove_est inflation i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m04 : qui reg GDI yhat GDPP_growth GDS_pgdp bmoney_gr est_corrupt gove_est cr_pi inflation march_trade  i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"

eststo m05 : qui reg GDI vol_er_usd GDPP_growth GDS_pgdp bmoney_gr est_corrupt gove_est cr_pi inflation march_trade  i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"

esttab m01 m02 m03 m04 m05, keep(yhat vol_er_usd GDPP_growth GDS_pgdp bmoney_gr est_corrupt gove_est cr_pi inflation march_trade) nonumber


#delimit ;
esttab m01 m02 m03 m04 m05 using "$pathOutput/Regression Table_DI.tex", replace keep(yhat vol_er_usd yhat GDPP_growth GDS_pgdp bmoney_gr est_corrupt gove_est cr_pi inflation march_trade)

b(3) //coefficient with 3 decimals
	se(3) // se with 3 decimals
	nomtitle
	star(* 0.10 ** 0.05 *** 0.01)
	booktabs
	//stats(N cfe tfe r2, fmt(%9.0f %9.0f %9.0f %9.3f)labels("Observations" "Currency fixed-effects" " Time Fixed-effects" "R^{2}"))
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	nonotes //suppress automatically generated notes
	coeflab(yhat "Exchange Rate Volatility(IV)" vol_er_usd "Exchange Rate Volatility" GDPP_growth "GDP per Capita Growth" GDS_pgdp "Gross Domestic Saving" bmoney_gr "Broad Money Growth" est_corrupt "Corruption control" gove_est "Government Effectiveness" cr_pi "Crop Prod. Index" inflation "Inflation" march_trade "Marchandise Trade(\%gdp)")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`title2'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{5}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{5}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} 
	\footnotesize \item `notes2' \end{table})
;
#delimit cr;




*============================================================================*
* Data Visualization
*===========================================================================*



// exchange rate volatility and FDI, averages
twoway (scatter fdi_avg vol_avg if c_code!="MOZ")(lfit di_avg vol_avg if c_code!="MOZ"),xscale(range(0 0.1)) title("FDI and Exchange Rate Volatility") subtitle("averages 1999-2021") ytitle("FDI_mean") xtitle("volatility coefficient") legend(off) name(c_averages, replace)
graph export "$pathOutput/fdi_vol.png", replace

//exchange rate volatility accross exchange rate regimes
graph box vol_avg, over(Regime,sort(Regime)) title("Exchange Rate Volatility Across Exchange Rate Regimes.") subtitle("averages 1999-2021") ytitle("Volatility") legend(off) name(exch_average, replace) nooutsides
graph export "$pathOutput/RateVol_exchR.png", replace

//Investment accross exchange rate regimes
graph box fdi_avg, over(Regime2, sort(fdi_avg) label(angle(45))) title("FDI and Exchange Rate Regimes") subtitle("averages 1999-2021") ytitle("FDI_mean") legend(off) name(c_average, replace) nooutsides
graph export "$pathOutput/fdi_exchR.png", replace

graph box di_avg, over(Regime2, label(angle(45))) title("Domestic Investment and Exchange Rate Regimes") subtitle("averages 1999-2021") ytitle("GDI_mean") legend(off) name(c_average, replace) nooutsides

graph export "$pathOutput/di_exchR.png", replace

bys Regime: egen vol_mR= mean(vol_avg)
 
bys year: egen mean_fdi=mean(fdi_inflow)
bys year: egen mean_GDI=mean(GDI)

**FDI and GDI **
twoway (line mean_fdi year, lcolor(blue) lpattern(solid)) /// 
       (line mean_GDI year, lcolor(red) lpattern(dash)), /// 
       title("Domestic and Foreign Direct Investment, Net Inflow") ///
       subtitle("Averages 1999-2021") ///
       ytitle("Investment (% GDP)") ///
       xtitle("Years") ///
       legend(order(2 "Gross DI" 1 "FDI Net Inflow")) ///
       name(c_averages, replace)
	graph export "$pathOutput/fdi_DI.png", replace   

twoway (line mean_fdi year if country =="Burundi") || (line mean_GDI year if country=="Burundi") 
graph box mean_GDI, over(Regime2) nooutsides

line mean_GDI year if Floating==1 || line mean_GDI year if Managed==1 || line mean_GDI year if Floating==1
**plots for other countries:
twoway line vol_er_usd year if c_code=="BDI", ///
title("Burundi ") ytitle("Volatility") xline(2009, lcolor(red) lpattern(dash)) ///
name(bdi, replace)	//from floating to managed

twoway line vol_er_usd year if country=="Kenya", ///
title("Kenya") ytitle("Volatility") xline(2016, lcolor(red) lpattern(dash)) ///
name(kenya, replace)	//from floating to managed

twoway line vol_er_usd year if country=="Tanzania", ///
title("Tanzania") ytitle("Volatility") xline(2016, lcolor(red) lpattern(dash)) ///
name(Tanzanie, replace)	//from floating to managed

twoway line vol_er_usd year if country=="CEMAC", ///
title("CEMAC") ytitle("Volatility") ///
name(cemac, replace)	//from floating to managed

graph combine bdi kenya Tanzanie cemac, name(per_country, replace)
graph export "$pathOutput/per_country.png", replace

  
** Volatility accross countries***
preserve
//local change2006 "AGO ETH RWA NGA SLE"
keep if inlist(c_code,"AGO","ETH","RWA","NGA","SLE" )
collapse (mean) vol_er_usd fdi_inflow GDI, by(year)

twoway (line GDI year, lcolor(black) lpattern(solid)) ///
       (line fdi_inflow year, lcolor(red) lpattern(solid)), /// 
       title("GDI and FDI-Inflow") ///
       ytitle("Investment (% GDP)") ///
       xtitle("Years") ytitle("Volatility") xline(2006, lcolor(red) lpattern(dash)) ///
       legend(order( 2 "FDI Net Inflow" 1 "Gross DI")) ///
       name(cfdi, replace)
	//graph export "$pathOutput/fdi_DI.png", replace 
twoway line vol_er_usd year, ///
title("Exchange rate volatility") ytitle("Volatility") xline(2006, lcolor(red) lpattern(dash)) ///
name(vol, replace)	

graph combine cfdi vol,  name(vol_int, replace)
graph export "$pathOutput/vol_int.png", replace
*******
restore

preserve
collapse (mean) vol_er_usd fdi_inflow ,by(c_code)
	
gen c_id = _n

#delimit ;
scatter vol_er_usd c_id if vol_er_usd > 0.05, 
 mlabel(c_code) msymbol(circle) || 
scatter vol_er_usd c_id if vol_er_usd <= 0.05, 
        mlabel(c_code) msymbol(circle)
		title("Average Volatility of Exchange Rate in USD by Country") 
       subtitle("from 1999-2021") 
       ytitle("Volatility") xtitle("Country Code") 
	   legend(off)
       name(vol1, replace);
#delimit cr;

 graph export "$pathOutput/volatility.png", replace


 #delimit ;
scatter fdi_inflow c_id if vol_er_usd > 0.05, 
 mlabel(c_code) msymbol(circle) || 
scatter fdi_inflow c_id if vol_er_usd <= 0.05, 
        mlabel(c_code) msymbol(circle)
		title("Average Foreign Direct Investment (% of GDP)") 
       subtitle("from 1999-2021") 
       ytitle("FDI in USD") xtitle("Country Code") 
	   legend(off)
       name(fdi1, replace);
#delimit cr;

graph export "$pathOutput/fdi1.png", replace
restore

















