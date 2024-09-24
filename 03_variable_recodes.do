********************************************************************************
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: variable_recodes
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes sample of couples and recodes to get ready for analysis


********************************************************************************
* First try to get marital history data to merge on
********************************************************************************
use "$PSID\mh_85_19.dta", clear

gen unique_id = (MH2*1000) + MH3
browse MH3 MH2 unique_id
gen unique_id_spouse = (MH7*1000) + MH8

/* first rename for ease*/
rename MH1 releaseno
rename MH2 fam_id
rename MH3 main_per_id
rename MH4 sex
rename MH5 mo_born
rename MH6 yr_born
rename MH7 fam_id_spouse
rename MH8 per_no_spouse
rename MH9 marrno 
rename MH10 mo_married
rename MH11 yr_married
rename MH12 status
rename MH13 mo_widdiv
rename MH14 yr_widdiv
rename MH15 mo_sep
rename MH16 yr_sep
rename MH17 history
rename MH18 num_marriages
rename MH19 marital_status
rename MH20 num_records

label define status 1 "Intact" 3 "Widow" 4 "Divorce" 5 "Separation" 7 "Other" 8 "DK" 9 "Never Married"
label values status status

egen yr_end = rowmin(yr_widdiv yr_sep)
browse unique_id marrno status yr_widdiv yr_sep yr_end

// this is currently LONG - one record per marriage. want to make WIDE

drop mo_born mo_widdiv yr_widdiv mo_sep yr_sep history
bysort unique_id: egen year_birth = min(yr_born)
drop yr_born

reshape wide unique_id_spouse fam_id_spouse per_no_spouse mo_married yr_married status yr_end, i(unique_id main_per_id fam_id) j(marrno)
gen INTERVIEW_NUM_1968 = fam_id

foreach var in *{
	rename `var' mh_`var' // so I know it came from marital history
}

rename mh_fam_id fam_id
rename mh_main_per_id main_per_id
rename mh_unique_id unique_id
rename mh_year_birth year_birth 
rename mh_INTERVIEW_NUM_1968 INTERVIEW_NUM_1968

save "$temp\marital_history_wide.dta", replace

********************************************************************************
* import orig data, merge to marital history, and create nec relationship variables
********************************************************************************
use "$created_data\PSID_partners.dta", clear

// merge on marital history
merge m:1 unique_id using "$temp\marital_history_wide.dta"
drop if _merge==2

gen in_marital_history=0
replace in_marital_history=1 if _merge==3
drop _merge

// Need to figure our how to get relationship number and duration. can I use with what is here? or need to merge marital history?! also, will this work for cohabiting relationships?! can I also use if started during PSID?. so key question is whether this covers cohab...I feel like in theory no, but in practice, it might?
tab marital_status_updated rel_start
gen rel_start_yr = survey_yr if rel_start==1

browse unique_id survey_yr RELATION_ marital_status_updated marr_trans rel_start_yr FIRST_MARRIAGE_YR_START mh_yr_married1 mh_yr_end1 mh_status1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history // FAMILY_INTERVIEW_NUM_ so will compare what is provided in individual file, what is provided in MH, what I calculated based on observed transitions
tab  FIRST_MARRIAGE_YR_START if in_marital_history==0 // oh I think this is populated from marital history GAH

gen rel_number=.
forvalues r=1/9{
	replace rel_number=`r' if survey_yr >=mh_yr_married`r' & survey_yr <= mh_yr_end`r'
}
forvalues r=12/13{
	replace rel_number=`r' if survey_yr >=mh_yr_married`r' & survey_yr <= mh_yr_end`r'
}
forvalues r=98/99{
	replace rel_number=`r' if survey_yr >=mh_yr_married`r' & survey_yr <= mh_yr_end`r'
}

browse unique_id survey_yr marital_status_updated rel_number rel_start_yr FIRST_MARRIAGE_YR_START mh_yr_married1 mh_yr_end1 mh_status1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history
