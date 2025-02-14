/*
FDI inflow
by
Noe Vyizigiro

This scripts wrangles pannel data from the UNCTAD
source: https://unctadstat.unctad.org/datacentre/dataviewer/US.PopGR
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved


import delimited "$rawData/UNCTAD_FDI_inflow.csv", clear varnames(1)
rename percentage_of_gross_domestic_pro FDI_INFLOW
rename economy_label economy

preserve
import delimited "$rawData/UNCTAD_fdi_outflow.csv", clear varnames(1)
rename percentage_of_gross_domestic_pro FDI_OUTFLOW
rename economy_label economy
tempfile temp1
save `temp1'
restore
merge 1:1 economy year using `temp1', keep(3) nogen

preserve
import delimited "$rawData/UNCTAD_rgdpp_growth.csv", clear varnames(1)
rename annual_average_growth_rate_per_c GDPP_growth
rename economy_label economy
rename period_label year

tempfile temp2
save `temp2'

restore
merge 1:1 economy year using `temp2', keep(3) nogen

preserve
import delimited "$rawData/UNCTAD_popgrowth.csv", clear varnames(1)
rename annual_average_growth_rate_value Pop_growth
rename economy_label economy
rename period_label year

tempfile temp3
save `temp3'

restore

merge 1:1 economy year using `temp3', keep(3) nogen

preserve
import delimited "$rawData/unctad_fdinf_pw.csv", clear varnames(1)
rename percentage_of_total_world_value fdi_inflow_pw
rename economy_label economy

tempfile temp4
save `temp4'

restore
merge 1:1 economy year using `temp4', keep(3) nogen


preserve
import delimited "$rawData/unctad_fdiouf_pw.csv", clear varnames(1)
rename percentage_of_total_world_value fdi_outflow_pw
rename economy_label economy

tempfile temp5
save `temp5'

restore
merge 1:1 economy year using `temp5', keep(3) nogen

gen fdi_netinflow = FDI_INFLOW-FDI_OUTFLOW
gen fdi_netinflow_pw =fdi_inflow_pw-fdi_outflow_pw

***Visualization***
**Africa;  Asia; Sub-Saharan Africa; Southern Asia; Latin America and the Caribbean; Northern America; Europe
***FDI percentage of GDP=



#delimit ;
twoway (line FDI_INFLOW year if economy == "Europe", lcolor(black) lpattern(dash) lwidth(medium)) ||
       (line FDI_INFLOW year if economy == "Latin America and the Caribbean", lcolor(green)) ||
       (line FDI_INFLOW year if economy == "Asia", lcolor(blue)) ||
       (line FDI_INFLOW year if economy == "Northern America", lcolor(black)) ||
       (line FDI_INFLOW year if economy == "Africa", lcolor(red) lpattern(dash)),
	   title("FDI-Inflow")
        ytitle("FDI Inflow (%GDP)") 
        xtitle("Year")
        legend(order(5 "Africa" 4 "N-America" 3 "Asia" 2 "Latin America" 1 "Europe") position(1) ring(0))
        name(FDI_inflow, replace);
#delimit cr;

#delimit ;
twoway (line GDPP_growth year if economy == "Europe", lcolor(black) lpattern(dash) lwidth(medium)) ||
	   (line GDPP_growth year if economy == "Latin America and the Caribbean", lcolor(green)) ||
       (line GDPP_growth year if economy == "Asia", lcolor(blue)) ||
	   (line GDPP_growth year if economy == "Northern America", lcolor(black)) ||
	   (line GDPP_growth year if economy == "Africa", lcolor(red) lpattern(dash)),
        title("GDP-Growth") 
        ytitle("GDP-perCapita Growth") 
		xtitle("Year")
       legend(order(5 "Africa" 4 "N-America" 3 "Asia" 2 "Latin America" 1 "Europe") position(1) ring(0))
	   name(gdp, replace);
#delimit cr;

graph combine FDI_inflow gdp, name(unctad_fdi_gdp, replace)
graph export "$pathOutput/unctad_fdi_gdp.png", replace

**FDI inflow percentage of the whole world

#delimit ;
twoway (line fdi_inflow_pw year if economy == "Europe", lcolor(black) lpattern(dash) lwidth(medium)) ||
       (line fdi_inflow_pw year if economy == "Latin America and the Caribbean", lcolor(green)) ||
       (line fdi_inflow_pw year if economy == "Asia", lcolor(blue)) ||
       (line fdi_inflow_pw year if economy == "Northern America", lcolor(black)) ||
       (line fdi_inflow_pw year if economy == "Africa", lcolor(red) lpattern(dash)),
	   title("FDI")
        ytitle("FDI Inflow (%World)") 
        xtitle("Year")
		xlabel(1990(5)2023)
        legend(order(5 "Africa" 4 "N-America" 3 "Asia" 2 "Latin America" 1 "Europe") position(1) ring(0))
        name(fdi, replace);
#delimit cr;

graph combine fdi gdp, name(unct_pw_fdi_gdp, replace)
graph export "$pathOutput/unct_pw_fdi_gdp.png", replace

**REgions

#delimit ;
twoway (line fdi_inflow_pw year if economy == "Southern Europe", lcolor(black)) ||
       (line fdi_inflow_pw year if economy == "Latin America and the Caribbean", lcolor(green)) ||
       (line fdi_inflow_pw year if economy == "Southern Asia", lcolor(blue)) ||
       (line fdi_inflow_pw year if economy == "Sub-Saharan Africa", lcolor(red) lpattern(dash)),
	   title("FDI")
        ytitle("FDI Inflow (%World)") 
        xtitle("Year")
		xlabel(1990(5)2023)
        legend(order(4 "SSA" 3 "S-Asia" 2 "Latin America" 1 "S-Europe") position(1) ring(0))
        name(fdi_re, replace);
#delimit cr;

#delimit ;
twoway (line GDPP_growth year if economy == "Southern Europe", lcolor(black)) ||
       (line GDPP_growth year if economy == "Latin America and the Caribbean", lcolor(green)) ||
       (line GDPP_growth year if economy == "Southern Asia", lcolor(blue)) ||
       (line GDPP_growth year if economy == "Sub-Saharan Africa", lcolor(red) lpattern(dash)),
	   title("GDP-Growth")
        ytitle("GDP-perCapita Growth") 
        xtitle("Year")
		xlabel(1990(5)2023)
        legend(order(4 "SSA" 3 "S-Asia" 2 "Latin America" 1 "S-Europe") position(1) ring(0))
        name(gdp_re, replace);
#delimit cr;

graph combine fdi_re gdp_re, name(unctad_fdi_gdp_re, replace)
graph export "$pathOutput/unct_fdi_gdp_re.png", replace

graph combine fdi fdi_re, name(un_fdi2, replace)
graph export "$pathOutput/un_fdi2.png", replace



#delimit ;
twoway (line fdi_netinflow_pw year if economy == "Europe", lcolor(black) lpattern(dash) lwidth(medium)) ||
       (line fdi_netinflow_pw year if economy == "Latin America and the Caribbean", lcolor(green)) ||
       (line fdi_netinflow_pw year if economy == "Asia", lcolor(blue)) ||
       (line fdi_netinflow_pw year if economy == "Northern America", lcolor(black)) ||
       (line fdi_netinflow_pw year if economy == "Africa", lcolor(red) lpattern(dash)),
	   title("Net-FDI Inflow")
        ytitle("FDI Inflow (%World)") 
        xtitle("Year")
        legend(order(5 "Africa" 4 "N-America" 3 "Asia" 2 "Latin America" 1 "Europe") position(1) ring(0))
        name(netfdiinpw, replace);
#delimit cr;
graph export "$pathOutput/unct_fdinetinfl-pw.png", replace

//histogram

bys economy: egen mean_fdi =mean(fdi_inflow_pw)

preserve

keep if inlist(economy,"Europe", "Latin America and the Caribbean", "Asia", "Northern America", "Africa","Sub-Saharan Africa","Southern Asia","Southern Europe" )

replace economy ="Latin America" if economy=="Latin America and the Caribbean"
replace economy ="SSA" if economy=="Sub-Saharan Africa"
replace economy ="S.Europe" if economy=="Southern Europe"
replace economy ="N.America" if economy=="Northern America"
replace economy ="S.Asia" if economy =="Southern Asia"


graph bar mean_fdi, over(economy, label(angle(45))) ///
    bar(1, color(gray)) ///
    ytitle("Average FDI")

graph export "$pathOutput/FDI-region.png"
	

restore
   
save "$deriveData/UNCTAD_cleaned.dta", replace
