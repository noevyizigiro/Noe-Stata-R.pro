/*
Noe Vyizigiro
Causal Inference
Fall 2024

Assignment 1: Lab Experiment: analysis
*/

clear all

global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /Fall_24/Causal Inference/Assignment1/Analysis"

cd "$noeVy"

global pathDoFile 	"$noeVy/Program_Files" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global Data 	"$noeVy/Data" //where data data is located

use "$Data/Vyizigiro_Assignment1_CleanData.dta"

ssc install balancetable

**generate dummies

gen female =0
replace female =1 if gender ==1

gen other_gender =0
replace other_gender =1 if gender ==2 | gender==3


tab income, gen(income_)
rename (income_1 income_2 income_3) (lower_income mid_income  higher_income)

tab race, gen(race_)
rename(race_1 race_2 race_3 race_4 race_5)(white black asian hispanic other)

gen familiar =0
replace familiar=1 if ai_familiar1==1 | ai_familiar1==4

gen other_nofamiliar =0
replace other_nofamiliar =1 if ai_familiar1==2 | ai_familiar1==3 | ai_familiar1 == 5

gen regular_use = 0
replace regular_use = 1 if ai_familiar2 == 1 | ai_familiar2 == 4

gen other_nouse = 0
replace other_nouse = 1 if ai_familiar2 == 2 | ai_familiar2 == 3 | ai_familiar2 == 5

balancetable treated_AI age female other_gender white black asian hispanic other lower_income mid_income higher_income familiar other_nofamiliar regular_use other_nouse using "$pathOutput/balance_table2.xlsx", replace


 
*** Balance table
/*
balance table: control group, Treatment group and difference (main colum titles)
you have age, gender, income, race, Ai familiarity, prior knowledge

create dummy on the AI questions; don't take the mean of categorical variable; show percentage in each category in stead. think about if something is in pre-treatement, if yes, it should be in the balance table

*/



*** graph

#delimit;
graph box score_total, over(treated_AI)  // using box
title("Test Score: Treatment vs. Control Group") 
 ytitle("Score(0-10)") 
 name(score_Graph1, replace) 
;
#delimit cr;
graph export "$pathOutput/score_graph1.png",replace

/*
twoway (histogram score_total if treated_AI == 1, bins(9) color(blue%50)) ///
       (histogram score_total if treated_AI == 0, bins(9) color(red%50)), ///
       title("Histogram of Score Total by Treatment and Control Groups")
	   
*/

** ttes in difference in means
ttest score_total, by(treated_AI)

regress score_total treated_AI, robust

*** add control to the regression
regress score_total treated_AI age white black hispanic other mid_income higher_income, robust

**end do file!


