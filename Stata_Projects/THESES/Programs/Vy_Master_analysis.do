/*
Senior Thesis
by
Noe Vyizigiro

This is a master do-file for my analyis. it combines all the cleaned dataset used for this study
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
replace country ="Cote d'Ivoire" if country=="Côte dʹIvoire"

** Merge dataset
//merge m:1 country year using "$deriveData/Vy_exchRegime.dta",assert(3) keep(3) nogen

merge 1:1 country year using "$deriveData/Vy_exchRegime.dta" , keep(match) nogen
merge 1:1 country year using  "$deriveData/Vy_exchangeRate_US&Euro.dta",keep(match) nogen

merge 1:1 country year using "$deriveData/public_priv_inv.dta"
drop _merge

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
replace vol_er_usd=vol_er_usd*100 //scaling the exchange rate volatility to a 100 to streamline the interpretation

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

collapse (mean) GDS_pgdp cr_pi gove_indx ngas_rent crawlike peg_conv agri_va_gr electricity ind_va_gr oil_rent curr_board peg_crawl agri_va_pgdp est_corrupt ind_va_pgdp rank_corrupt ffloating peg_hband GDP bmoney_gr fdi_inflow FDI_inflow inflation totnr_rent floating stabilized GDPP_growth bmoney_pgdp fpi man_va_pgdp Fixed manfloating vol_er_usd GDP_growth coal_rent gcf_pgdp march_trade Managed no_seplt  vol_er_euro GDS_curr cpi gove_est min_rent Floating omanaged pub_inv priv_inv [aweight = GDP], by(year cfa_xof)

drop if cfa_xof ==0
replace cfa_xof =3 if cfa_xof==1

tempfile temp
save `temp'

restore

append using `temp'
replace country ="CFA_XOF" if country ==""
replace c_code ="CFXF" if c_code==""


preserve

collapse (mean) GDS_pgdp cr_pi gove_indx ngas_rent crawlike peg_conv agri_va_gr electricity ind_va_gr oil_rent curr_board peg_crawl agri_va_pgdp est_corrupt ind_va_pgdp rank_corrupt ffloating peg_hband GDP bmoney_gr fdi_inflow FDI_inflow inflation totnr_rent floating stabilized GDPP_growth bmoney_pgdp fpi man_va_pgdp Fixed manfloating vol_er_usd GDP_growth coal_rent gcf_pgdp march_trade Managed no_seplt vol_er_euro GDS_curr cpi gove_est min_rent Floating omanaged pub_inv priv_inv [aweight = GDP], by(year cfa_xaf)

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
ssc install asdoc 

tab country, sum(fdi_inflow) means nof
tab country, sum(vol_avg) means nof
tab c_code, sum(GDI) means nof

//asdoc tabulate regime year, row replace



** 1. Summary of the variables used in the model**
estpost tabstat fdi_inflow pub_inv priv_inv GDI vol_er_usd  GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation fpi march_trade, c(stat) stat( mean sd min max n)
//ereturn list

   
#delimit;
esttab using "$pathOutput/summaryTable.tex", replace
 cells("mean(fmt(2)) sd min max count(fmt(0))") nonumber
  nomtitle nonote noobs nolabel booktabs 
  collabels("Mean" "SD" "Min" "Max" "Obs") 
  title("Summary Statistics \label{table1stata}")
  coeflabels(fdi_inflow "FDI-Inflow(\%GDP)" pub_inv "Public Investment(\%GDP)" priv_inv "Private Investment(\%GDP)" GDI "G.Domestic Investment(\%GDP)" vol_er_usd "Volatility-ExRate(to USD)" GDPP_growth "Per Capita GDP Growth" GDS_pgdp "G.Domestic Saving" bmoney_gr "Board Money Growth" electricity "Electrification" est_corrupt "Corruption control" totnr_rent "Totoal N. Resource Rents" cr_pi "Crop Prod. Index" inflation  "Inflation" fpi "Food Prod Index" march_trade "Marchandise Trade")

;
#delimit cr;



** summary by country**

estpost tabstat fdi_inflow GDI pub_inv priv_inv vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation fpi march_trade, by(country) c(stat) stat( mean sd) 

 
#delimit;
esttab using "$pathOutput/summaryTable2.tex", replace
cells(mean(fmt(2)) sd(par)) nonumber unstack
   nonote noobs nolabel 
   collabels(none) gap 
   //eqlabels("Angola" "North Central" "South" "West") /// 
    title("Summary Statistics on Country Level \label{table1stata}")
	coeflabels(fdi_inflow "FDI-Inflow(\%GDP)" pub_inv "Public Investment(\%GDP)" priv_inv "Private Investment(\%GDP)" GDI "G.Domestic Investment(\%GDP)" vol_er_usd "Volatility-ExRate(to USD)" GDPP_growth "Per Capita GDP Growth" GDS_pgdp "G.Domestic Saving" bmoney_gr "Board Money Growth" electricity "Electrification" est_corrupt "Corruption control" totnr_rent "Totoal N. Resource Rents" cr_pi "Crop Prod. Index" inflation "Inflation" fpi "Food Prod Index"  march_trade "Marchandise Trade")
	
	
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

drop if year>2017

*============================================================================*
* Regression Models
*===========================================================================*
ssc install estout
est clear

local reltitle "Exchange Rate Regime with Exchange Rate Volatility(1st Stage)"
local relnote \textit{Note:} "The oucome variable is Exchange Rate Volatility. Robust Standard Errors are in Paranthesis. This first stage regression shows the relationship between exchange rate regime and exchange rate volatility. All regimes, tripartite classification and detailed classification, are included. Columns 6 and 7 have Floating as an omitted(reference) category. The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

**Show relevance** Fist Stage Regression

eststo rel1: qui regress vol_er_usd i.Regime i.c_currency, robust 
estadd local cfe = "Yes"
estadd local tfe = "No"
estadd local contr ="No"

eststo rel2: qui regress vol_er_usd i.Regime i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local contr ="No"

eststo rel3: qui regress vol_er_usd i.Regime GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local contr ="Yes"

eststo rel4: qui regress vol_er_usd i.Regime2 i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local contr ="No"

eststo rel5: qui regress vol_er_usd i.Regime2 GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local contr ="Yes"

eststo rel6: qui regress vol_er_usd Managed Fixed i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local contr ="No"

eststo rel7: qui regress vol_er_usd Managed Fixed GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade i.c_currency i.year, robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local contr ="Yes"

//esttab rel*, keep(2.Regime 3.Regime 2.Regime2 3.Regime2 4.Regime2 5.Regime2 6.Regime2 7.Regime2 8.Regime2 9.Regime2)


#delimit ;
esttab rel* using "$pathOutput/Regression Reltable.tex", replace 
     order(2.Regime 3.Regime Managed Fixed 2.Regime2 3.Regime2 4.Regime2 5.Regime2 6.Regime2 7.Regime2 8.Regime2 9.Regime2) 
	 keep(2.Regime 3.Regime Managed Fixed 2.Regime2 3.Regime2 4.Regime2 5.Regime2 6.Regime2 7.Regime2 8.Regime2 9.Regime2)
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    mtitle("ERV" "ERV" "ERV" "ERV" "ERV" "ERV" "ERV")
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "contr Controls" "r2 R^{2}") sfmt(3 3)
	coeflab(2.Regime "Floating" 3.Regime "Managed" Managed "Managed" Fixed "Fixed" 2.Regime2 "Crawl Peg" 3.Regime2 "Crawlike" 4.Regime2 "Floating" 5.Regime2 "Free Floating" 6.Regime2 "Managed Floating" 7.Regime2 "No Sep. Legal Tender" 8.Regime2 "Other Managed" 9.Regime2 "Stabilized")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`reltitle'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{7}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} \\
	\footnotesize \item `relnote' \end{table})
	;
#delimit cr;


***Reduced forms***
local rtitle "Investment and Exchange Rate Regime, Reduced Form"
local rnotes "This is a reduced form regressing exchange rate regime on investment. Robust standard errors are in paranthesis. The Stars are significant level where * 0.10 ** 0.05 *** 0.01."
foreach r in FDI_inflow GDI pub_inv priv_inv {
	eststo r1_`r': qui reg `r' Fixed Floating  i.c_currency i.year, robust
	 estadd local ctrl = "No"
     estadd local fe = "Yes"
	eststo r2_`r': qui reg `r' Fixed Floating GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade i.c_currency i.year, robust 
	 estadd local ctrl = "Yes"
     estadd local fe = "Yes"

}
//esttab r1* r2*, keep(2.Regime 3.Regime) ///
//scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R-Squared") sfmt(3 3)

#delimit;
esttab r1* r2* using "$pathOutput/inv-regime_redcd.tex",replace keep(Fixed Floating)
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    mtitle("FDI-Inflow" "GDI" "Pub-Inv" "Priv-Inv" "FDI-Inflow" "GDI" "Pub-Inv" "Priv-Inv")
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	scalars("N" "ctrl Controls" "fe Fixed Effects" "r2 R^{2}") sfmt(3 3)
	coeflab( Fixed "Fixed" Floating "Floating" )
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`rtitle'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{8}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{8}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} \\
	\footnotesize \item `rnotes' \end{table})
	;
#delimit cr;



***Second Stage Regression: using IV-2SLS and OLS***

*** 1. Foreign Direct Investment***

local notes1 "Robust standard errors are in parentheses; it is important to use robust due to potential serial correlation, which can lead to understated standard errors and inflated statistical significance. Model 1-3 are estimated with simple OLS. The dependent variable isNet Foreign direct investment inflow (percentage of GDP). The sample include 26 currencies, from 1999-2021, used in 36 sub-Saharan African countries.The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

local title1 "Regression Table: Foreign Direct Investment Net Inflow"

eststo m1 : qui reg fdi_inflow vol_er_usd, robust 
estadd local cfe = "No"
estadd local tfe = "No"
estadd local crtl = "No"

eststo m2 : qui reg fdi_inflow vol_er_usd i.c_currency i.year, robust 
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "No"

eststo m3 : qui reg fdi_inflow vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade  i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"

eststo m4 : qui ivregress 2sls fdi_inflow i.c_currency i.year (vol_er_usd=i.Regime), robust 

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "No"

eststo m5 : qui ivregress 2sls fdi_inflow est_corrupt GDPP_growth i.c_currency i.year (vol_er_usd=i.Regime est_corrupt GDPP_growth), robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"

eststo m6 : qui ivregress 2sls fdi_inflow GDPP_growth est_corrupt electricity totnr_rent inflation i.c_currency i.year (vol_er_usd = i.Regime GDPP_growth est_corrupt electricity totnr_rent inflation), robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"

eststo m7 : qui ivregress 2sls fdi_inflow GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade  i.c_currency i.year (vol_er_usd=i.Regime GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade), robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"


//esttab m*, keep(vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) nonumber


#delimit ;
esttab m* using "$pathOutput/Regression Table_FDI.tex", replace 
    keep(vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) 
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    nomtitle
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	mgroups(FDI:OLS FDI:IV-2SLS, pattern(1 0 0 1) // use the dynamically generated `models`
    prefix(\multicolumn{@span}{c}{) suffix(}) span // set up for group title
    erepeat(\cmidrule(lr){@span})) //underline the group
	//collabels("OLS" "OLS" "OLS" "IV-2SLS" "IV-2SLS" "IV-2SLS" "IV-2SLS")
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility" GDPP_growth "GDP per Capita Growth" GDS_pgdp "Gross Domestic Saving" bmoney_gr "Broad Money Growth" electricity "Electrification" est_corrupt "Corruption control" totnr_rent "Total N.Resource Rents" cr_pi "Crop Prod. Index" inflation "Inflation" march_trade "Marchandise Trade(\%gdp)")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`title1'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{7}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox}
	\footnotesize \item `notes1' \end{table})
	;
#delimit cr;

**2. Domestic investment***

local notes2 "Robust standard errors are in parentheses; it is important to use robust due to potential serial correlation, which can lead to understated standard errors and inflated statistical significance. Model 1-3 are estimated with simple OLS. The dependent variable is Gross Domestic investment (percentage of GDP). The sample include 26 currencies, from 1999-2021, used in 36 sub-Saharan African countries.The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

local title2 "Regression Table: Domestic Investment"


eststo gm1 : qui reg GDI vol_er_usd, robust 
estadd local cfe = "No"
estadd local tfe = "No"
estadd local crtl = "No"

eststo gm2 : qui reg GDI vol_er_usd i.c_currency i.year, robust 
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "No"

eststo gm3 : qui reg GDI vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade  i.c_currency i.year, robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"

eststo gm4 : qui ivregress 2sls GDI i.c_currency i.year (vol_er_usd = i.Regime), robust 

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "No"

eststo gm5 : qui ivregress 2sls GDI est_corrupt GDPP_growth i.c_currency i.year (vol_er_usd=i.Regime est_corrupt GDPP_growth), robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"

eststo gm6 : qui ivregress 2sls GDI GDPP_growth est_corrupt electricity gove_est inflation i.c_currency i.year (vol_er_usd = i.Regime GDPP_growth est_corrupt electricity gove_est inflation), robust
estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"

eststo gm7 : qui ivregress 2sls GDI GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade  i.c_currency i.year (vol_er_usd=i.Regime GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade), robust

estadd local cfe = "Yes"
estadd local tfe = "Yes"
estadd local crtl = "Yes"


//esttab dm*, keep(vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt gove_est cr_pi inflation march_trade) nonumber


#delimit ;
esttab gm* using "$pathOutput/Regression Table_DI.tex", replace 
    keep(vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) 
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    nomtitle
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	mgroups(GDI:OLS GDI:IV-2SLS, pattern(1 0 0 1) // use the dynamically generated `models`
    prefix(\multicolumn{@span}{c}{) suffix(}) span // set up for group title
    erepeat(\cmidrule(lr){@span})) //underline the group
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility" GDPP_growth "GDP per Capita Growth" GDS_pgdp "Gross Domestic Saving" bmoney_gr "Broad Money Growth" electricity "Electrification" est_corrupt "Corruption control" totnr_rent "Total N.Resource Rents" cr_pi "Crop Prod. Index" inflation "Inflation" march_trade "Marchandise Trade(\%gdp)")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`title2'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{7}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} 
	\footnotesize \item `notes2' \end{table})
	;
#delimit cr;



****** Other Investments **** (private and public)
//est clear

local note_priv "Robust standard errors are in parentheses; it is important to use robust due to potential serial correlation, which can lead to understated standard errors and inflated statistical significance. Model 1-3 are estimated with simple OLS. The dependent variable is Private Investment (percentage of GDP). The sample include 26 currencies, from 1999-2017, used in 36 sub-Saharan African countries.The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

local note_pub "Robust standard errors are in parentheses; it is important to use robust due to potential serial correlation, which can lead to understated standard errors and inflated statistical significance. Model 1-3 are estimated with simple OLS. The dependent variable is Public Investment (percentage of GDP). The sample include 26 currencies, from 1999-2017, used in 36 sub-Saharan African countries.The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

local titpriv "Private Investment"
local titpub "Public Investment"

foreach i in priv_inv pub_inv{

	eststo dm1_`i' : qui reg `i' vol_er_usd, robust 
	estadd local cfe = "No"
	estadd local tfe = "No"
	estadd local crtl = "No"

	eststo dm2_`i' : qui reg `i' vol_er_usd i.c_currency i.year, robust 
	estadd local cfe = "Yes"
	estadd local tfe = "Yes"
	estadd local crtl = "No"

	eststo dm3_`i' : qui reg `i' vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade  i.c_currency i.year, robust

	estadd local cfe = "Yes"
	estadd local tfe = "Yes"
	estadd local crtl = "Yes"

	eststo dm4_`i' : qui ivregress 2sls `i' i.c_currency i.year (vol_er_usd = i.Regime), robust 

	estadd local cfe = "Yes"
	estadd local tfe = "Yes"
	estadd local crtl = "No"

	eststo dm5_`i' : qui ivregress 2sls `i' est_corrupt GDPP_growth i.c_currency i.year (vol_er_usd=i.Regime est_corrupt GDPP_growth), robust

	estadd local cfe = "Yes"
	estadd local tfe = "Yes"
	estadd local crtl = "Yes"

	eststo dm6_`i' : qui ivregress 2sls `i' GDPP_growth est_corrupt electricity totnr_rent inflation i.c_currency i.year (vol_er_usd = i.Regime GDPP_growth est_corrupt electricity totnr_rent inflation), robust
	estadd local cfe = "Yes"
	estadd local tfe = "Yes"
	estadd local crtl = "Yes"

	eststo dm7_`i' : qui ivregress 2sls `i' GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade  i.c_currency i.year (vol_er_usd=i.Regime GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade), robust

	estadd local cfe = "Yes"
	estadd local tfe = "Yes"
	estadd local crtl = "Yes"


	esttab dm*, keep(vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) nonumber
	
	local models dm1_`i' dm2_`i' dm3_`i' dm4_`i' dm5_`i' dm6_`i' dm7_`i'
	
	 if "`i'" == "priv_inv" {
        local title "`titpriv'"
        local file_name "Reg_privInv"
		local gname "Priv-Inv"
		local note3 "`note_priv'"
    }
    else if "`i'" == "pub_inv" {
        local title "`titpub'"
        local file_name "Reg_pubInv"
		local gname "Pub-Inv"
		local note3 "`note_pub'"
    }
	

#delimit ;
esttab `models' using "$pathOutput/`file_name'.tex", replace 
    keep(vol_er_usd GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) 
	

    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    nomtitle
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	mgroups(`gname':OLS `gname':IV-2SLS, pattern(1 0 0 1) // use the dynamically generated `models`
    prefix(\multicolumn{@span}{c}{) suffix(}) span // set up for group title
    erepeat(\cmidrule(lr){@span})) //underline the group
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility" GDPP_growth "GDP per Capita Growth" GDS_pgdp "Gross Domestic Saving" bmoney_gr "Broad Money Growth" electricity "Electrification" est_corrupt "Corruption control" totnr_rent "Total N.Resource Rents" cr_pi "Crop Prod. Index" inflation "Inflation" march_trade "Marchandise Trade(\%gdp)")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`title'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{7}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} 
	\footnotesize \item `note3' \end{table})
	;
#delimit cr;
}

gen landlockdXvol = landlocked*vol_er_usd
gen resourceXvol =totnr_rent*vol_er_usd
gen log_pubinv = ln(pub_inv)
gen log_privinv =ln(priv_inv)


*=============================================================================*
* Panels
*=============================================================================*

local panel_title "Exchange Rate Volatility and Investments"
local panel_note "This is a panel of all investments used in this study. Robust standard errors are in parentheses. Model 1-3 are estimated with simple OLS and 4-7 are estimated with two-stage instrumental variable method. Each panel has its own outcome variable. Column 1 and 4 are run without controls and controls are included for other columns( See Appendix section for detailed regression tables with all the controls showns). Also, fixed effects are included in certain columns(see on the bottom of panel D for more information about each column). All the outcome variables are expressed as percentage of GDP. The sample include 26 currencies, used in 36 sub-Saharan African countries covering a period of 1999-2021 (only for FDI and domestic investment) and 1999-2017 (for public and private investment).The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

#delimit ;
esttab m*  
 using "$pathOutput/panel_invt.tex", replace 
	keep(vol_er_usd) 
	b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    nomtitle
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	mgroups(OLS IV-2SLS, pattern(1 0 0 1) // use the dynamically generated `models`
    prefix(\multicolumn{@span}{c}{) suffix(}) span // set up for group title
    erepeat(\cmidrule(lr){@span})) //underline the group
	scalars("N" "r2 R-Squared") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility") 
	prehead("\begin{table}[H]  \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`panel_title'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{7}{c}} \\ \hline\hline") ///
    posthead(\hline\addlinespace \multicolumn{7}{l}{\textbf{\textit{Panel A: FDI Inflow}}} \\  \addlinespace[10pt]) 
	fragment
	;
#delimit cr;

#delimit ;
esttab gm*  
 using "$pathOutput/panel_invt.tex", append 
	keep(vol_er_usd)
	b(3) 
	se(3)
	nonotes
	mlabels(none) 
	nonumbers 
	star(* 0.10 ** 0.05 *** 0.01) 
	booktabs 
	scalars("N" "r2 R-Squared") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility") 
   posthead(\hline\addlinespace \multicolumn{7}{l}{\textbf{\textit{Panel B: Gross Domestic Investment}}} \\  \addlinespace[10pt])
   fragment;
#delimit cr;


#delimit;	
esttab dm*_pub_inv 
using "$pathOutput/panel_invt.tex", append
	keep(vol_er_usd)
	b(3) 
	se(3) 
	nonotes 
	mlabels(none) 
	nonumbers 
	star(* 0.10 ** 0.05 *** 0.01) 
	booktabs 
	scalars("N" "r2 R-Squared") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility")
	posthead(\hline\addlinespace \multicolumn{7}{l}{\textbf{\textit{Panel C: Public Investment}}} \\  \addlinespace[10pt])
   fragment;
#delimit cr;

#delimit;	
esttab dm*_priv_inv 
using "$pathOutput/panel_invt.tex", append
	keep(vol_er_usd)
	b(3) 
	se(3) 
	nonotes 
	mlabels(none) 
	nonumbers 
	star(* 0.10 ** 0.05 *** 0.01) 
	booktabs 
	scalars("N" "r2 R-Squared" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "crtl Controls") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility")
   posthead(\hline \addlinespace \multicolumn{7}{l}{\textbf{\textit{Panel D: Private Investment}}} \\  \addlinespace[10pt]) 
	postfoot(\bottomrule \end{tabular} \end{adjustbox} \\
		\footnotesize \item `panel_note' \end{table}) 
	fragment;
	


#delimit cr;

//exit
*=============================================================================*
* Putting all Investments and key controls together
*=============================================================================*

** create lag of exchange rate volatility that will be used as another IV-2SLS

xtset country_id year
gen lag_vol = L1.vol_er_usd
gen lag_vol2 =L2.vol_er_usd
gen march_trade2 =L1.march_trade


local invtitle "Investment, with key Control Variables"
local invnote "Robust standard errors are in parentheses. Model 1-4 are estimated with simple OLS and 5-8 are estimated with two-stage instrumental variable method. The outcome variables are expressed as percentage of GDP.All models control for time and currency fixed effects. The sample include 26 currencies, used in 36 sub-Saharan African countries covering a period of 1999-2021 (only for FDI and domestic investment) and 1999-2017 (for public and private investment).The Stars are significant level where * 0.10 ** 0.05 *** 0.01."

foreach v in FDI_inflow GDI pub_inv priv_inv {
	eststo all1_`v': qui reg `v' vol_er_usd landlockdXvol est_corrupt GDPP_growth march_trade lag_vol  i.c_currency i.year, robust
	 estadd local cfe = "Yes"
     estadd local tfe = "Yes"
	eststo all2_`v': qui ivregress 2sls `v' landlockdXvol est_corrupt GDPP_growth march_trade i.c_currency i.year (vol_er_usd = i.Regime landlockdXvol est_corrupt GDPP_growth march_trade ), robust 
	 estadd local cfe = "Yes"
     estadd local tfe = "Yes"

}
esttab all1* all2*, keep(vol_er_usd landlockdXvol est_corrupt GDPP_growth march_trade lag_vol) ///
scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R-Squared") sfmt(3 3)


#delimit ;
esttab all1* all2* using "$pathOutput/investments.tex", replace 
    keep(vol_er_usd landlockdXvol est_corrupt GDPP_growth march_trade lag_vol) 
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    mtitle("FDI-Inflow" "GDI" "Pub-Inv" "Priv-Inv" "FDI-Inflow" "GDI" "Pub-Inv" "Priv-Inv")
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	mgroups(OLS IV-2SLS, pattern(1 0 0 0 1) // use the dynamically generated `models`
    prefix(\multicolumn{@span}{c}{) suffix(}) span // set up for group title
    erepeat(\cmidrule(lr){@span})) //underline the group
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	coeflab(vol_er_usd "Exchange Rate Volatility" landlockdXvol "LandlockedXVolatility" est_corrupt "Corruption control" GDPP_growth "GDP per Capita Growth" march_trade "Marchandise Trade(\%gdp)" lag_vol "Exchange Rate Volatility(t-1)" )
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`invtitle'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{8}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{8}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} \\
	\footnotesize \item `invnote' \end{table})
	;
#delimit cr;

///include in the appendix similar table but use lag_march-trade.

*============================================================================*
* More Robustness Checks
*===========================================================================*

local rnote "Robust standard errors are in parentheses. The models are estimated with OLS with one year lag of exchange  rate volatility.The outcome variables are expressed as percentage of GDP. The sample include 26 currencies, used in 36 sub-Saharan African countries covering a period of 1999-2021.The Stars are significant level where * 0.10 ** 0.05 *** 0.01."
local rtitle "FDI and DI, with Lagged Volatility"

est clear
foreach d in fdi_inflow GDI {
  
   eststo rm1_`d' : qui reg `d' lag_vol, robust 
   
   estadd local cfe = "No"
   estadd local tfe = "No"

   eststo rm2_`d' : qui reg `d' lag_vol i.c_currency i.year, robust 
   estadd local cfe = "Yes"
   estadd local tfe = "Yes"

   eststo rm3_`d' : qui reg `d' lag_vol GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi    inflation march_trade  i.c_currency i.year, robust

   estadd local cfe = "Yes"
   estadd local tfe = "Yes"

}

//esttab rm*, keep(lag_vol GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) nonumber


#delimit ;
esttab rm* using "$pathOutput/rTable_FDI_DI.tex", replace 
    keep(lag_vol GDPP_growth GDS_pgdp bmoney_gr electricity est_corrupt totnr_rent cr_pi inflation march_trade) 
    b(3) // coefficient with 3 decimals
    se(3) // standard error with 3 decimals
    mtitle("FDI-Inflow" "FDI-Inflow" "FDI-Inflow" "GDI" "GDI" "GDI")
	booktabs
    star(* 0.10 ** 0.05 *** 0.01)
	nonotes
	//mgroups(GDI:OLS GDI:IV-2SLS, pattern(1 0 0 1) // use the dynamically generated `models`
    //prefix(\multicolumn{@span}{c}{) suffix(}) span // set up for group title
    //erepeat(\cmidrule(lr){@span})) //underline the group
	scalars("N" "cfe Currency fixed-effects" "tfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	coeflab(lag_vol "Exchange Rate Volatility(t-1)" GDPP_growth "GDP per Capita Growth" GDS_pgdp "Gross Domestic Saving" bmoney_gr "Broad Money Growth" electricity "Electrification" est_corrupt "Corruption control" totnr_rent "Total N.Resource Rents" cr_pi "Crop Prod. Index" inflation "Inflation" march_trade "Marchandise Trade(\%gdp)")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`rtitle'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{6}{c}} \\ \hline\hline") 
    posthead("\hline \addlinespace \multicolumn{6}{l}{} \\  \addlinespace[2pt]") 
    postfoot(\bottomrule \end{tabular} \end{adjustbox} \\
	\footnotesize \item `rnote' \end{table})
	;
#delimit cr;

//drop observations that are floating and see what happens


*============================================================================*
* Data Visualization
*===========================================================================*

*** Graphing Currencies by Exchange Rate Regime Over Time: 
preserve

collapse (count) c_currency, by(year regime)
drop if regime ==""
reshape wide c_currency, i(year) j(regime) string
rename c_currency* *

twoway ///
    (line Fixed year, lcolor(blue)) ///
    (line Managed year, lcolor(black)) ///
    (line Floating year, lcolor(green)), ///
    legend(order(1 "Fixed" 2 "Managed" 3 "Floating")) ///
    ytitle("Currency Number") ///
    xtitle("Year")

graph export "$pathOutput/reg_category.png", replace

restore

** graphing exchange rate volatility across regime classificaton

preserve

collapse (mean)vol_er_usd, by(Regime)
graph bar vol_er_usd, over(Regime, label(angle(45))) ///
    bar(1, color(blue)) ///
    ytitle("Volatility against USD")
graph export "$pathOutput/Reg_Vol.png", replace
	
restore



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
bys year: egen mean_pubInv = mean(pub_inv)
bys year: egen mean_privIn = mean(priv_inv)

** investment series:
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
	
**combining investment
#delimit ;
twoway (line pub_inv year if country =="Advanced Economy", lcolor(black)) ||
	   (line pub_inv year if country=="Low Income Developing", lcolor(green)) ||
       (line pub_inv year if country=="Emerging Economy", lcolor(red)) ||
	   (line mean_pubInv year , lcolor(blue) lpattern(dash)),
        title("Public") 
		//subtitle("Average 1974-2023")
        ytitle("Public Inv. (%GDP)") xtitle("Year")
       legend(order(4 "SSA" 3 "Emerging Eco." 2 "Low-income" 1 "Advanced Eco.") position(10) ring(0))
	   name(pub, replace);
#delimit cr;

#delimit ;
twoway (line priv_inv year if country =="Advanced Economy", lcolor(black)) ||
	   (line priv_inv year if country=="Low Income Developing", lcolor(green)) ||
       (line priv_inv year if country=="Emerging Economy", lcolor(red)) ||
	   (line mean_privIn year , lcolor(blue) lpattern(dash)),
        title("Private") 
		//subtitle("Average 1974-2023")
        ytitle("Private Inv. (%GDP)") xtitle("Year")
       legend(order(4 "SSA" 3 "Emerging Eco." 2 "Low-income" 1 "Advanced Eco.") position(5) ring(0))
	   name(priv, replace);
#delimit cr;


graph combine pub priv, name(priv_pub, replace)
graph export "$pathOutput/priv_pub.png", replace

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













