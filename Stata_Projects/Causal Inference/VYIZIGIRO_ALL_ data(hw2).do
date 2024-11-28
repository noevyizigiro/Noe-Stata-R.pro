/*
Noe Vyizigiro
Causal Inference
Fall 2024

Assignment 2: Difference in Difference
*/

clear all

global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /Fall_24/Causal Inference/Assignment2/Analysis"

cd "$noeVy"

global pathDoFile 	"$noeVy/Program_Files" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global Data 	"$noeVy/Data" //where data data is located

use "$Data/CPS Fertility 1979-1995.dta"


ssc install estout

merge m:1 state using "$Data/ELA coding.dta", keep(match) nogen

order state state_name

tab state_name , sum(elayear_bailey) means nof
tab state_name , sum(abortion_bailey) means nof

** creating age at first birth dummies
//creating ELA 
gen ELA_to_pill =0
replace ELA_to_pill=1 if yob+20>=elayear_bailey
//elayear_bailey: year when pill was extended to people below 21 without parental consent; yob: cohort yob


gen ELA_abortion =0
replace ELA_abortion =1 if yob+20 >=abortion_bailey

//interaction between abortion and pill
gen pill_abortion =ELA_to_pill*ELA_abortion

gen fb_before22 =0
replace fb_before22=1 if age_1birth<22


gen fb_before19 =0
replace fb_before19=1 if age_1birth<19

gen fb_before36 =0
replace fb_before36=1 if age_1birth<36

//create sample that is in bailey sample
gen inbl_sample=0
replace inbl_sample =1 if (ageyrs<=44 & ageyrs>=36) & (yob>=1935 & yob<=1960) & num_births>0 & (flag_1birth!=1 & flag_numbirth!=1)


//allocation flag, if is equal to 1 it means something is wrong in the data(probably the questions were unswered inconsistently), the data collector decided to flag them. so, 

**create variables for robustness checks

gen newsample1=0, //change age to between 22 and 44
replace newsample1 =1 if (ageyrs<=44 & ageyrs>=22) & (yob>=1935 & yob<=1960) & num_births>0 & (flag_1birth!=1 & flag_numbirth!=1)

gen newsample2=0, //including those who haven't given birth
replace newsample2 =1 if (ageyrs<=44 & ageyrs>=36) & (yob>=1935 & yob<=1960) & (flag_1birth!=1 & flag_numbirth!=1)


gen ELA_myers =0 //using professor myers's coding
replace ELA_myers=1 if yob+20>=elayear_myers

 
summarize fb_before22 if inbl_sample==1
estadd local mean_fb_before22 = r(mean)
//estadd scalar mean1 = `mean_fb_before22'

summarize fb_before19 if inbl_sample==1
estadd local mean_fb_before19 = r(mean)
//estadd scalar mean2 = `mean_fb_before19'

summarize fb_before36 if inbl_sample==1
estadd local mean_fb_before36 = r(mean)
//estadd scalar mean3 = `mean_fb_before36'

sum fb_before22 fb_before19 fb_before36 num_births if inbl_sample==1

**** using estosto
eststo clear
eststo model1: qui reg fb_before22 ELA_to_pill i.state i.yob if inbl_sample==1 [aweight=weight], robust
estadd local fe = "SC"

eststo model2: qui reg fb_before22 ELA_to_pill i.state i.yob i.state#c.yob if inbl_sample==1 [aweight=weight], robust 
estadd local fe = "SC"
estadd local str = "SxC"


eststo model3: qui reg fb_before22 ELA_to_pill ELA_abortion pill_abortion i.state i.yob  i.state#c.yob if inbl_sample==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

eststo model4: qui reg fb_before19 ELA_to_pill ELA_abortion pill_abortion i.state i.yob i.state#c.yob i.state#c.yob if inbl_sample==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

eststo model5: qui reg fb_before36 ELA_to_pill ELA_abortion pill_abortion i.state i.yob i.state#c.yob if inbl_sample==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

eststo model6: qui reg num_births ELA_to_pill ELA_abortion pill_abortion i.state i.yob i.state#c.yob if inbl_sample==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

esttab model1 model2 model3 model4 model5 model6 using "$pathOutput/Table1_rep.csv", keep(ELA_to_pill ELA_abortion pill_abortion) b(4) se(3) stats(fe str N mean_fb_before22, fmt(%9.0f)labels("Fixed effects" " " "Observations")) coeflabels(ELA_to_pill "ELA to pill" ELA_abortion "Early legal access to abortion" pill_abortion "ELA to pill and abortion" ) addnotes(add notes here) replace 

//what i.state#c.yob: taking each state and multiplying that with year of birth: there is one interaction per state because yob is continuous. it is wrong to have interaction of state to every year of birth because (i.state#i.yob=state linear time trend, allowing every state to have a linear anual average change in ELA than another state: state might trending differently and ELA might have introduced in different years) it would be perfect colinear with ELA; if we know someone's state and year of birth, we know that they are ELA .

***Robustness check of model 2

eststo m1: qui reg fb_before22 ELA_to_pill i.state i.yob i.state#c.yob if inbl_sample==1 [aweight=weight], robust 
estadd local fe = "SC"
estadd local str = "SxC"

eststo m2: qui reg fb_before22 ELA_to_pill i.state i.yob i.state#c.yob if newsample1==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

eststo m3: qui reg fb_before22 ELA_to_pill i.state i.yob i.state#c.yob if newsample2==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

eststo m4: qui reg fb_before22 ELA_myers i.state i.yob i.state#c.yob if inbl_sample==1 [aweight=weight], robust
estadd local fe = "SC"
estadd local str = "SxC"

eststo m5: qui reg fb_before22 ELA_to_pill i.state i.yob i.state#c.yob if inbl_sample==1 & center500==1 [aweight=weight], robust

estadd local fe = "SC"
estadd local str = "SxC" 


esttab m1 m2 m3 m4 m5 using "$pathOutput/Table2_robust.csv",  keep(ELA_to_pill ELA_myers) b(4) se(3) stats(fe str N , fmt(%9.0f)labels("Fixed effects" " " "Observations")) coeflabels(ELA_to_pill "ELA to pill" ELA_myers "ELA to pill by Myers") addnotes(add notes here) replace
/*
options to run fixed effects:

1. regress y x i.state i.yob
2. xtset state
xtreg y x i.yob , fe
3. reghdfe y x , absorb(state yob)

*/

