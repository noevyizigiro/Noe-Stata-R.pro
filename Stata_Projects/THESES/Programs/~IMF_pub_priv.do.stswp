/*
FDI inflow
by
Noe Vyizigiro

This scripts wrangles pannel data from the IMF
*/

clear all


**Define global location
global noeVy "/Users/noevyizigiro/iCloud Drive (Archive)/Documents/Documents /THESES"

cd "$noeVy"

global pathDoFile 	"$noeVy/Programs" //where new do files go
global pathOutput 	"$noeVy/Output" //where the results are stored (charts and tables)
global rawData 	"$noeVy/Data/Raw" //where raw data is located
global deriveData "$noeVy/Data/Derived" //where cleaned data is saved

foreach data in PGCS_Public_investment_as_percentag PGCS_Private_investment_as_percentag{
	
	import delimited "$rawData/`data'.csv", clear varnames(2) //this will make the second raw, which contains years becomes labels because numbers cannot become variables names
	//import excel "$rawData/fdi_inflow.xls", firstrow

	**drop variables whose labels are not years
	//exit
	label var v1 "country"
	foreach var of varlist _all {
		if "`: variable label `var''" == "" {  //if variable label is equal to "", then drop it
			drop `var'
		}
	}

	//exit

	foreach v of varlist _all {
		local lbl : variable label `v' //extracts the label of the variable v and store it  in the local macro lbl
		local lbl_clean = strtoname("`lbl'") //cleans the label by coverting into a valid stata name using strtoname()
		rename `v' `lbl_clean'	
	}

	//exit


	//local newname = substr("_1990_B",1, strpos("_1990_B", "_") -1)

	**Reshape

	reshape long _, i(country) j(year) // reshape long using identifiers

	//reshape wide _, i(year Country_Name) j(Indicator_Name) string

	drop if year<1999
	
	if "`data'" =="PGCS_Public_investment_as_percentag"{
		rename _ pub_inv
		label var pub_inv "Public Investment (% of GDP), from IMF"
	}
	else if "`data'" == "PGCS_Private_investment_as_percentag"{
		rename _ priv_inv
		label var priv_inv "Private Investment (% of GDP), from IMF"
	}
		
	

	** change country names

	capture replace country= "DR Congo" if country=="Congo, Democratic Republic of the"
	capture replace country= "Central African Rep." if country=="Central African Republic"
	capture replace country= "Congo" if country=="Congo, Republic of"
	capture replace country ="Gambia" if country =="Gambia, The"
	capture replace country ="Cote d'Ivoire" if country =="Cte d'Ivoire"
	
	** generate ids:
	egen id =group (country year)
	order country id
	
	//tempfile temp
	//save `temp', replace
	save "$deriveData/privInv.dta", replace
	capture preserve
	
	
}

restore

merge 1:1 country year using "$deriveData/privInv.dta", 
drop _merge id
drop if country =="Algeria"
drop if country =="Cabo Verde"


save "$deriveData/public_priv_inv.dta", replace
