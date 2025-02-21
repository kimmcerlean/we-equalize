// Create couple-level data by merging datasets
// Assign time-use variables for wife's and husband's diary entries
// Create time-use variables at couple level 

//  Merge individual and partner datasets

use "$moddata\mtusuk_individual.dta", replace
	merge 1:m mergeid using "$moddata\mtusuk_partner.dta"
	
sort individualid

drop if _merge == 2

browse hldid individualid civstat relrefp paidwork sp_paidwork housework sp_housework chcare sp_chcare eldcare sp_eldcare 

* indicator for those who has partner but no diary for the partner

gen sp_nodiary = 0 if partid > 0 & _merge == 3
	replace sp_nodiary = 1 if partid > 0 & _merge == 1
	
tab sp_nodiary, m  /* missing = no partner or partner id cannot be generated */

* indicator for single women/men

gen single = 0
	replace single = 1 if civstat == 2
	replace single = . if civstat == -8
	
tab single, m

// Assign time-use variables for wife's and husband's diary entries

gen wife = 0
	replace wife = 1 if sex == 2 & civstat == 1
	
gen w_paidwork = paidwork if wife == 1
gen w_housework = housework if wife == 1
gen w_chcare = chcare if wife == 1
gen w_eldcare = eldcare if wife == 1

gen hus_paidwork = sp_paidwork if wife == 1
gen hus_housework = sp_housework if wife == 1
gen hus_chcare = sp_chcare if wife == 1
gen hus_eldcare = sp_eldcare if wife == 1

browse hldid individualid civstat relrefp w_paidwork hus_paidwork w_housework hus_housework w_chcare hus_chcare w_eldcare hus_eldcare 

// Sample indicator

gen sample = 0
	replace sample = 1 if wife == 1 /* partnered women's individual and couple level diary entries, including missing husband's time use values */
	replace sample = 2 if single == 1  /* single women's individual level diary entries */

/* Note from Melody: I prefer not to drop any observations, even if it's redundant because of duplicating datasets. I use sample indicators to set up the scenarios. 

If the analysis is about couple's time use, let sample == 1. In this scenario, 
I choose women as the perspective and attach their partner's time use values to 
women's records. So if want to get partnered women's time use, just go with w_paidwork and so on; and for partnered men's time use, go with hus_paidwork and so on. 

If want to look at single women and men's time use, let sample == 2. And use individual level time use variables, e.g., paidwork, housework, etc. by sex to get time use values for single women and men. 
*/
	
// Time-use variables at couple-level (only for individuals in couple and both have diary entries) 

* percentage of wife's time-use within couple 

gen paidwork_wpercent = w_paidwork / (w_paidwork + hus_paidwork) if sample == 2 & sp_nodiary == 0

gen housework_wpercent = w_housework / (w_housework + hus_housework) if sample == 2 & sp_nodiary == 0

gen chcare_wpercent = w_chcare / (w_chcare + hus_chcare) if sample == 2 & sp_nodiary == 0

gen eldcare_wpercent = w_eldcare / (w_eldcare + hus_eldcare) if sample == 2 & sp_nodiary == 0

* egalitarianism 

gen paidwork_equal = .
	replace paidwork_equal = 1 if paidwork_wpercent >= 0.4 & paidwork_wpercent <= 0.6
	replace paidwork_equal = 2 if paidwork_wpercent >0.6
	replace paidwork_equal = 3 if paidwork_wpercent <0.4
	replace paidwork_equal = 4 if w_paidwork == 0 & hus_paidwork == 0
	
tab paidwork_equal, m

gen housework_equal = .
	replace housework_equal = 1 if housework_wpercent >= 0.4 & housework_wpercent <= 0.6
	replace housework_equal = 2 if housework_wpercent > 0.6
	replace housework_equal = 3 if housework_wpercent < 0.4
	replace housework_equal = 4 if w_housework == 0 & hus_housework == 0
	
tab housework_equal, m 

gen chcare_equal = .
	replace chcare_equal = 1 if chcare_wpercent >= 0.4 & chcare_wpercent <= 0.6
	replace chcare_equal = 2 if chcare_wpercent > 0.6
	replace chcare_equal = 3 if chcare_wpercent < 0.4
	replace chcare_equal = 4 if w_chcare == 0 & hus_chcare == 0
	
tab chcare_equal, m 

gen eldcare_equal = .
	replace eldcare_equal = 1 if eldcare_wpercent >= 0.4 & eldcare_wpercent <= 0.6
	replace eldcare_equal = 2 if eldcare_wpercent > 0.6
	replace eldcare_equal = 3 if eldcare_wpercent < 0.4
	replace eldcare_equal = 4 if w_eldcare == 0 & hus_eldcare == 0
	
tab eldcare_equal, m 

save "$moddata\mtusuk_couple.dta", replace


