
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: imputation_for_individs
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files uses the individual level data from the coules to impute base data
* necessary for final analysis.

********************************************************************************
**# First get survey responses for each individual in couple from main file
********************************************************************************
use "$PSID\PSID_full_renamed.dta", clear
rename X1968_PERSON_NUM_1968 main_per_id

gen unique_id = (main_per_id*1000) + INTERVIEW_NUM_1968 // (ER30001 * 1000) + ER30002
browse main_per_id INTERVIEW_NUM_1968 unique_id

// figure out what variables i need / can help me figure this out - need indicator of a. in survey and b. relationship status (easy for non-heads) - so need to be INDIVIDUAL, not family variables, right?!
browse unique_id SEQ_NUMBER_1995 SEQ_NUMBER_1996 MARITAL_PAIRS_1995 MARITAL_PAIRS_1996 RELATION_1995 RELATION_1996

forvalues y=1969/1997{
	gen in_sample_`y'=.
	replace in_sample_`y'=0 if SEQ_NUMBER_`y'==0 | inrange(SEQ_NUMBER_`y',60,90)
	replace in_sample_`y'=1 if inrange(SEQ_NUMBER_`y',1,59)
}

forvalues y=1999(2)2021{
	gen in_sample_`y'=.
	replace in_sample_`y'=0 if SEQ_NUMBER_`y'==0 | inrange(SEQ_NUMBER_`y',60,90)
	replace in_sample_`y'=1 if inrange(SEQ_NUMBER_`y',1,59)	
}

label define relationship 0 "not in sample" 1 "head" 2 "partner" 3 "other"
forvalues y=1969/1997{
	gen relationship_`y'=.
	replace relationship_`y'=0 if RELATION_`y'==0
	replace relationship_`y'=1 if inlist(RELATION_`y',1,10)
	replace relationship_`y'=2 if inlist(RELATION_`y',2,20,22,88)
	replace relationship_`y'=3 if inrange(RELATION_`y',23,87) | inrange(RELATION_`y',90,98) | inrange(RELATION_`y',3,9)
	label values relationship_`y' relationship
}

forvalues y=1999(2)2021{
	gen relationship_`y'=.
	replace relationship_`y'=0 if RELATION_`y'==0
	replace relationship_`y'=1 if inlist(RELATION_`y',1,10)
	replace relationship_`y'=2 if inlist(RELATION_`y',2,20,22,88)
	replace relationship_`y'=3 if inrange(RELATION_`y',23,87) | inrange(RELATION_`y',90,98) | inrange(RELATION_`y',3,9)
	label values relationship_`y' relationship
}


// browse unique_id in_sample_* relationship_* MARITAL_PAIRS_* HOUSEWORK_WIFE_* HOUSEWORK_HEAD_*
keep unique_id FIRST_BIRTH_YR in_sample_* relationship_* MARITAL_PAIRS_* SEX EDUC1_WIFE_* EDUC1_HEAD_* EDUC_WIFE_* EDUC_HEAD_* LABOR_INCOME_WIFE_* WAGES_WIFE_* LABOR_INCOME_HEAD_* WAGES_HEAD_* TAXABLE_HEAD_WIFE_* WEEKLY_HRS1_WIFE_* WEEKLY_HRS_WIFE_* WEEKLY_HRS1_HEAD_* WEEKLY_HRS_HEAD_* HOUSEWORK_HEAD_* HOUSEWORK_WIFE_* TOTAL_HOUSEWORK_HW_* MOST_HOUSEWORK_* EMPLOY_STATUS_HEAD_* EMPLOY_STATUS1_HEAD_* EMPLOY_STATUS2_HEAD_* EMPLOY_STATUS3_HEAD_* EMPLOY_STATUS_WIFE_* EMPLOY_STATUS1_WIFE_* EMPLOY_STATUS2_WIFE_* EMPLOY_STATUS3_WIFE_* NUM_CHILDREN_* AGE_YOUNG_CHILD_* AGE_REF_* AGE_SPOUSE_* TOTAL_FAMILY_INCOME_* FAMILY_INTERVIEW_NUM_* EMPLOY_STATUS_T2_HEAD_* EMPLOY_STATUS_T2_WIFE_* WEEKLY_HRS_T2_WIFE_* START_YR_EMPLOYER_HEAD_* START_YR_EMPLOYER_WIFE_* START_YR_CURRENT_HEAD_* START_YR_CURRENT_WIFE_* START_YR_PREV_HEAD_* START_YR_PREV_WIFE_* YRS_CURRENT_EMPLOY_HEAD_* YRS_CURRENT_EMPLOY_WIFE_* SALARY_T2_HEAD_* SALARY_T2_WIFE_* WEEKLY_HRS_T2_INDV_* SALARY_T2_INDV_*

gen partner_id = unique_id

forvalues y=1969/1997{
	gen in_sample_sp_`y' = in_sample_`y'
	gen relationship_sp_`y' = relationship_`y'
	gen MARITAL_PAIRS_sp_`y' = MARITAL_PAIRS_`y'
}

forvalues y=1999(2)2021{
	gen in_sample_sp_`y' = in_sample_`y'
	gen relationship_sp_`y' = relationship_`y'
	gen MARITAL_PAIRS_sp_`y' = MARITAL_PAIRS_`y'
}

gen SEX_sp = SEX

forvalues y=1969/1987{ // let's keep a few years to see if we have ANY data for people before they were observed
	drop in_sample_`y'
	drop in_sample_sp_`y'
	drop relationship_`y'
	drop relationship_sp_`y'
	drop MARITAL_PAIRS_`y'
	drop MARITAL_PAIRS_sp_`y'
}

foreach var in EDUC1_WIFE_ EDUC1_HEAD_ EDUC_WIFE_ EDUC_HEAD_ LABOR_INCOME_WIFE_ WAGES_WIFE_ LABOR_INCOME_HEAD_ WAGES_HEAD_ TAXABLE_HEAD_WIFE_ WEEKLY_HRS1_WIFE_ WEEKLY_HRS_WIFE_ WEEKLY_HRS1_HEAD_ WEEKLY_HRS_HEAD_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ AGE_REF_ AGE_SPOUSE_ FAMILY_INTERVIEW_NUM_ TOTAL_FAMILY_INCOME_ EMPLOY_STATUS_T2_HEAD_ EMPLOY_STATUS_T2_WIFE_ WEEKLY_HRS_T2_WIFE_ START_YR_EMPLOYER_HEAD_ START_YR_EMPLOYER_WIFE_ START_YR_CURRENT_HEAD_ START_YR_CURRENT_WIFE_ START_YR_PREV_HEAD_ START_YR_PREV_WIFE_ YRS_CURRENT_EMPLOY_HEAD_ YRS_CURRENT_EMPLOY_WIFE_ SALARY_T2_HEAD_ SALARY_T2_WIFE_WEEKLY_HRS_T2_INDV_ SALARY_T2_INDV_{
	forvalues y=1968/1987{
		capture drop `var'`y' // in case var not in all years
	}
}

drop *_1968

save "$temp\partner_sample_info.dta", replace

********************************************************************************
**# Now merge this info on to individuals
********************************************************************************
use "$created_data\couple_list_individ.dta", clear

merge m:1 unique_id using "$temp\partner_sample_info.dta" // created in step 03
drop if _merge==2
drop _merge

drop *_sp_*
drop SEX_sp