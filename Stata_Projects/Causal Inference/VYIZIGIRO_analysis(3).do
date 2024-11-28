/*
Noe Vyizigiro
Causal Inference
Fall 2024

Assignment 3: Event Study Designs/Analysis
*/

clear all

global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /Fall_24/Causal Inference/Assignment3/Analysis"


cd "$noeVy"

global pathDoFile 	"$noeVy/Program_Files" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global Data 	"$noeVy/Data" //where data data is located

use "$Data/Clean Data.dta"

**install packages***
*ssc install regsave 
*ssc install eventdd
*ssc install regsave
*ssc install matsort

*===============================================================================*
* Event Study and DiD estimation
*===============================================================================*

**generate expansion, which is equal to 1 if medicaid expansion year is between 2014 and 2017

gen expanded = year >=tstar 
replace expanded =0 if tsta==0
gen expansion =0
foreach i in 2014 2015 2016 2017{
	replace expansion =1 if tstar==`i'
	
}

**rescale median income
gen medincome2 =medincome/10000 //rescaling median income by $10,000

**limit the sample
gen insample_male = agegroup =="55-64 years" & !inlist(postal, "MA", "DC", "VT", "NY", "DE") & gender =="Male" & race =="Total"

gen insample_female = agegroup =="55-64 years" & !inlist(postal, "MA", "DC", "VT", "NY", "DE") & gender =="Female" & race =="Total"

**weight
bysort state_fips: egen popweight =mean(population)

**generating j, time variable
gen j =year-tstar 
replace j= . if tstar==0

**log mortality rate
gen log_mortrate =log(mortrate) 

**run event study model by gender**

//1. male
# delimit ;
eventdd log_mortrate i.year i.state_fips [aweight = popweight] if insample_male==1, 
	cluster(state_fips)
	timevar(j)  
	coef_op(mcolor(navy)) 
	ci(rcap, color(navy%30)) 
	leads(6) /*specify leads (those correspond to negative event times)*/
	lags(3) /*specify lagss (those correspond to positive event times)*/
	accum   /*I'm telling it to bin or "accumulate" all event times at the ends*/
	noend   /*I'm telling it not to graph the binned ends*/
	noline /*I'm suppressing the package's line at j=-1 so I can format my own*/
	graph_op(
		ylabel(-0.03(0.01)0.03)
		xline(-1,lpattern(dot) lcolor(gs5))
		xlabel(-5(1)3)
		legend(off)
		title("Effect of Medicaid Expansions on Mortality for Men Aged 55-64")
		ytitle("Change in log mortality rate")
		xtitle("Time since policy change")
		name(eventdd_male, replace)
		
	)
	
	;		
# delimit cr

// bins: 6 and 3 (6 yrs before and 3 years after)
graph export "$pathOutput/male.png", replace

//2. female
# delimit ;
eventdd log_mortrate i.year i.state_fips [aweight = popweight] if insample_female==1, 
	cluster(state_fips)
	timevar(j)  
	coef_op(mcolor(navy)) 
	ci(rcap, color(navy%30)) 
	leads(6) /*specify leads (those correspond to negative event times)*/
	lags(3) /*specify lagss (those correspond to positive event times)*/
	accum   /*I'm telling it to bin or "accumulate" all event times at the ends*/
	noend   /*I'm telling it not to graph the binned ends*/
	noline /*I'm suppressing the package's line at j=-1 so I can format my own*/
	graph_op(
		ylabel(-0.03(0.01)0.03)
		xline(-1,lpattern(dot) lcolor(gs5))
		xlabel(-5(1)3)
		legend(off)
		title("Effect of Medicaid Expansions on Mortality for Women Aged 55-64")
		ytitle("Change in log mortality rate")
		xtitle("Time since policy change")
		name(eventdd_fem, replace)
	)
	;		
# delimit cr
graph export "$pathOutput/female.png", replace



**DiD estimation**

est clear

foreach r in Total White Black Hispanic Asian{
	
qui eststo model_female_`r': regress log_mortrate expanded urate medincome2 pctpoverty i.year i.state_fips [aweight = popweight] if agegroup =="55-64 years" & !inlist(postal, "MA", "DC", "VT", "NY", "DE") & gender =="Female" & race =="`r'", cluster(state_fips) 

estadd local sfe ="Yes"
estadd local yfe ="Yes"

local Female `"`Female' model_female_`r' "'
}

esttab `Female', keep(expanded urate medincome2 pctpoverty) mtitle("Total" "White" "Black" "Hispanic" "Asian") nonumber


foreach r in Total White Black Hispanic Asian{
	
qui eststo model_male_`r': regress log_mortrate expanded urate medincome2 pctpoverty i.year i.state_fips [aweight = popweight] if agegroup =="55-64 years" & !inlist(postal, "MA", "DC", "VT", "NY", "DE") & gender =="Male" & race =="`r'", cluster(state_fips) 

estadd local sfe ="Yes"
estadd local yfe ="Yes"

local Male `"`Male' model_male_`r' "'
}


esttab `Male', keep(expanded urate medincome2 pctpoverty) mtitle("Total" "White" "Black" "Hispanic" "Asian") nonumber


***Panel**

local title "Impact of Medicaid Expansion on Mortality Rates for Individuals Aged 55-65"


local notes "This analysis summarizes the Difference-in-Differences (DiD) estimation across all post-expansion years. The dependent variable is the log of the mortality rate in state s and year t. Results are estimated for different racial groups, including the total population, which aggregates data across all races.In addition to controlling for state and year fixed effects, the model incorporates key economic variables: the unemployment rate at the state level for a given year, state median income(which I scale by 10,000; it's no longer 1 dollar change , but 10,000 dollar change in median income), and the percentage of people in poverty in each state and year. Robust standard errors, clustered at the state level, are reported in parentheses. Each model is weighted by the mean population at the state level. * p$<$0.05, ** p$<$0.01, *** p$<$0.001"


#delimit ;
esttab `Female' using "$pathOutput/DiD.tex", replace 
	keep(expanded urate medincome2 pctpoverty)
    b(3) //coefficient with 3 decimals
	se(3) // se with 3 decimals
	//nomtitle
	mtitle("Total" "White" "Black" "Hispanic" "Asian")
	star(* 0.10 ** 0.05 *** 0.01)
	booktabs
	scalars("N" "sfe State fixed-effects" "yfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3)
	nonotes 
	coeflab(expanded "ExpansionXpost(DiD)" urate "Unemployment Rate" medincome2 "Median Income" pctpoverty "Poverty Rate")
	prehead("\begin{table}[H] \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{`title'} \begin{adjustbox}{max width=\textwidth} \begin{tabular}{l*{5}{c}} \\ \hline\hline") 
    posthead(\hline \addlinespace \multicolumn{5}{l}{\textbf{\textit{Panel A: Female}}} \\  \addlinespace[2pt])
	fragment
;
#delimit cr;


#delimit ;
esttab `Male' using "$pathOutput/DiD.tex", append 
	keep(expanded urate medincome2 pctpoverty)
    b(3)
	se(3)
	//mtitle("Total" "White" "Black" "Hispanic" "Asian")
	nomtitle
	nonumber
	star(* 0.10 ** 0.05 *** 0.01)
	booktabs
	nonotes
	coeflab(expanded "ExpansionXpost(DiD)" urate "Unemployment Rate" medincome2 "Median Income" pctpoverty "Poverty Rate")
	scalars("N" "sfe State fixed-effects" "yfe Time Fixed-effects" "r2 R^{2}") sfmt(3 3) 
	posthead(\hline \addlinespace \multicolumn{5}{l}{\textbf{\textit{Panel B: Male}}} \\  \addlinespace[2pt])
    postfoot(\bottomrule \end{tabular} \end{adjustbox} \footnotesize \item `notes' \end{table})
	fragment
;
#delimit cr;

**end**
