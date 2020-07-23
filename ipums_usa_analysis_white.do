cd "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata"

use ipums_usa_1840_2018_white_black.dta, clear 
keep if race == 1
drop if sample == 197004
//keep if year >= 1960
//
//append using "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata\ipums_usa_1840_1940.dta"
//
//* keep only wife and husband
//keep if relate == 1 | relate == 2 
//
//* drop women out of range 
//drop if sex == 2 &  age < 45
//drop if sex == 2 &  age > 50

* Save Main data

//save "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata\ipums_usa_1840_1940_women.dta", replace 
******** Special cleaning for before 1950

	* drop samples
	// drop if sample == 840185001
	// drop if sample == 840188001

******** 
//use "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata\ipums_usa_1840_1940_women.dta", clear 
	* 

	* keep whites before 1870 and samples 
	//keep if race == 10 | race == 1
	gen marst_1870 = .
	replace marst_1870 = 1 if relate == 2 & year <= 1870

	* fill in marit status wife and husband
	bysort year sample serial: egen marst_2 = max(marst_1870) if year <= 1870
	replace marst_1870 = 1 if relate == 1 & marst_2 == 1 & year <= 1870

	replace marst = 1 if marst_1870 == 1 
	* keep ever married
	//keep if marst == 2 |marst == 3 | marst == 4  

	drop if marst == 6 
	* keep only white women
	//keep if race == 10 

	* Drop not citizen 
	* Lets assume 1870 all were nationals 
	

	drop if citizen >=  3 & citizen != .

save "ipums_usa_1840_2018_clean", replace 

//preserve 
//	* keep older women 
//	keep if sex == 2
//
//    * Graphs 
//    keep if inrange(age,45,50)
//
//    * race
//    keep if race == 10
//
//    bysort sample: egen pop = count(pernum)
//    gen tot_pop = pop * perwt
//
//    bysort sample : egen pop_2 = mean(tot_pop)
//
//	twoway (bar pop_2 year)
//
//restore 




* Cleaning data 
	use "ipums_usa_1840_2018_clean" , clear 
	* Get education from partner in case we can identify household 
	gen ocscorus_hus = occscore if relate == 1 & sex == 1 & year <= 1930
	replace ocscorus_hus = occscore if relate == 2 & sex == 1 & year <= 1930
	bysort  sample serial: egen ocscorus_hus_2 = max(ocscorus_hus) if year <= 1930

	gen school_hus = school if relate == 1 & sex == 1 & year <= 1930
	replace school_hus = school if relate == 2 & sex == 1 & year <= 1930
	bysort sample serial: egen school_hus_2 = max(school_hus) if year <= 1930

	gen lit_hus = lit if relate == 1 & sex == 1 & year <= 1930
	replace lit_hus = lit if relate == 2 & sex == 1 & year <= 1930
	bysort  sample serial: egen lit_hus_2 = max(lit_hus) if year <= 1930


	gen ed_hus = educ if relate == 1 & sex == 1 & year > 1930
	replace ed_hus = educ if relate == 2 & sex == 1 & year > 1930
	bysort  sample serial: egen ed_hus_2 = max(ed_hus) if year > 1930

	gen ed_d_hus = educd if relate == 1 & sex == 1 & year > 1930
	replace ed_d_hus = educd if relate == 2 & sex == 1 & year > 1930
	bysort  sample serial: egen ed_d_hus_2 = max(ed_d_hus) if year > 1930

	* keep older women 
	keep if sex == 2
	//keep if age >= 45

    * Graphs 
    // drop if missing(educ_cont)
    // drop if missing(educ_sp_cont)
    //keep if inrange(age,45,50)

    * Get families with larger number of children 
    br if famsize - nchild > 2 & nchild == 9
    replace nchild = famsize-2 if (famsize - nchild > 2 & nchild == 9)
	save "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata\ipums_usa_1840_2018_clean_2.dta", replace 

*** Create Means of Fertility 


* Education values
use "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata\ipums_usa_1840_2018_clean_2.dta", clear 

*	Fertility by cohorts 

	* Create cohorts of ten years 
	gen yob = year - age
	//gen cohort = floor(yob/5)*5
	gen cohort = floor(yob/10)*10

	gen fert_cohort = .

	* Avge number of children by cohort 
	levelsof cohort, local(cohort)
	foreach c of local cohort{
			summarize nchild [w=perwt] if cohort == `c' , detail 
	   		replace fert_cohort = r(mean) if cohort == `c'  
	} 


* Graph Fertility vs percentile for years before 1930  
	/* Since we have no information on education before 1940 we use 
	percentile information about income  */
	

	* fill in percentile mean child by cohort 
	local cohort_1 "1800 1810 1820 1830 1850 1860 1870 1880"
	local cohort_2 "1890 1900 1910 1920 1930 1940 1960 1970"


	* Divide people by tertiles according median income by labor group 
		foreach c of local cohort_1 {
		    xtile pct_`c'  = ocscorus_hus_2 if cohort == `c', nquantiles(3)
		}

		gen pct = pct_1850 if !missing(pct_1850)

		foreach c of local cohort_1 {
		    replace pct = pct_`c' if cohort == `c' & !missing(pct_`c')
		}

	* Generate variable with children mean by tertiles 
		gen mean_child_pct_h = . 
		gen mean_child_pct_w = . 

	* Percentile 

		//levelsof cohort, local(cohort)
		levelsof pct, local(percentil)

		foreach c of local cohort_1{
			foreach p of local percentil{
				summarize nchild [w=perwt] if cohort == `c' & pct == `p', detail 
		   		replace mean_child_pct_h = r(mean) if cohort == `c' & pct == `p' 
			}
		} 

		* fill in percentile mean child by cohort 
		//levelsof cohort, local(cohort)
		levelsof pct, local(percentil)

		foreach c of local cohort_1{
			foreach p of local percentil{
				summarize nchild [w=perwt] if cohort == `c' & pct == `p', detail 
		   		replace mean_child_pct_w = r(mean) if cohort == `c' & pct == `p' 
			}
		} 




	* literacy 
		gen lit_hus_3 = 1 if lit_hus_2==4 & year <= 1930
		replace lit_hus_3 = 0 if lit_hus_2 < 4 & year <= 1930
		
		gen mean_child_lit_h = .

		* fill in percentile mean child by literacy 
		levelsof cohort, local(cohort)
		levelsof lit_hus_3, local(literacy)

		foreach c of local cohort{
			foreach l of local literacy{
				summarize nchild [w=perwt] if cohort == `c' & lit_hus_3 == `l', detail 
		   		replace mean_child_lit_h = r(mean) if cohort == `c' & lit_hus_3 == `l' 
			}
		} 



	* Drop when no information about education
	* gen education variable for husband 
	drop if cohort == 1900

	gen ed_group_h = 1 if inrange(ed_hus_2, 0, 5)
	replace ed_group_h = 2 if inrange(ed_hus_2, 6, 6)
	replace ed_group_h = 3 if inrange(ed_hus_2, 7, 9)
	replace ed_group_h = 4 if inrange(ed_hus_2, 10, 11)


	* gen education variable for wife 
	gen ed_group_w = 1 if inrange(educ, 0, 5)
	replace ed_group_w = 2 if inrange(educ, 6, 6)
	replace ed_group_w = 3 if inrange(educ, 7, 9)
	replace ed_group_w = 4 if inrange(educ, 10, 11)

	gen mean_child_ed_h = .
	gen mean_child_ed_w = .
	

	* Education groups 
		* fill in education group husband  mean child by cohort 
		levelsof cohort, local(cohort)
		levelsof ed_group_h, local(education_h)

		foreach c of local cohort{
			foreach e of local education_h{
				summarize nchild [w=perwt] if cohort == `c' & ed_group_h == `e', detail 
		   		replace mean_child_ed_h = r(mean) if cohort == `c' & ed_group_h == `e' 
			}
		} 

		* fill in education group wife  mean child by cohort 
		levelsof cohort, local(cohort)
		levelsof ed_group_w, local(education_w)

		foreach c of local cohort{
			foreach e of local education_w{
				summarize nchild [w=perwt] if cohort == `c' & ed_group_w == `e', detail 
		   		replace mean_child_ed_w = r(mean) if cohort == `c' & ed_group_w == `e' 
			}
		} 


	* Drop if no info in pct and education group 
	//drop if missing(pct) & missing(ed_group_h) 



* Combining graphs 

gen mean_child_pct_educ  = mean_child_pct_h if mean_child_pct_h != .
replace mean_child_pct_educ = mean_child_ed_h if mean_child_ed_h != .




* HS graduated 
	* fill in HS-G child mean by cohort
		gen ed_hs_h = (inrange(ed_hus_2, 6, 11)) if year > 1930 & ed_hus_2 != 0
		gen ed_hs_w = (inrange(educ, 6, 11)) if year > 1930 & educ != 0

		// bysort sample cohort : egen mean_hs = mean(ed_hs_h)

		gen mean_hs = . 
			levelsof cohort, local(cohort)
			foreach c of local cohort{
					summarize ed_hs_h [w=perwt] if cohort == `c' , detail 
			   		replace mean_hs = r(mean) if cohort == `c' 
			} 

		sort cohort mean_hs
		twoway (connected fert_cohort cohort ) ///
				(connected mean_hs cohort)

* Percentage changes educ groups
 tabulate ed_group_h, generate(ed_g_)

		gen perc_ed_1 = . 
		gen perc_ed_2 = . 
		gen perc_ed_3 = . 
		gen perc_ed_4 = . 

			levelsof cohort, local(cohort)
			foreach c of local cohort{
				forvalues i = 1(1)4{
					summarize ed_g_`i' [w=perwt] if cohort == `c' , detail 
			   		replace perc_ed_`i' = r(mean) if cohort == `c' 
				} 
			}

		gen perc_lit = .
			levelsof cohort, local(cohort)
			foreach c of local cohort{
					summarize lit_hus_3 [w=perwt] if cohort == `c' , detail 
			   		replace perc_lit = r(mean) if cohort == `c' 
				
			}
save "G:\My Drive\MQE_LMU\SS_2020\Thesis\Fert_Educ\A_Microdata\ipums_usa_1840_2018_graphs.dta", replace 


I modified this file. 
