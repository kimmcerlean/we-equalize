
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
* This files uses the individual level data from the couples to impute base data
* necessary for final analysis.

** INSTALL THESE FIRST
ssc install sq
ssc install moremata

net sj 17-3 st0486 // SADI
net install st0486

net sj 16-3 st0445 // MICT
net install st0445
net get st0445 // these go into working directory (the ancillary files); pwd shows current working directory

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
keep unique_id FIRST_BIRTH_YR in_sample_* relationship_* MARITAL_PAIRS_* SEX AGE_INDV* YRS_EDUCATION_INDV* EDUC1_WIFE_* EDUC1_HEAD_* EDUC_WIFE_* EDUC_HEAD_* LABOR_INCOME_T1_WIFE_* LABOR_INCOME_T2_WIFE_* WAGES_T1_WIFE_* LABOR_INCOME_T1_HEAD_* LABOR_INCOME_T2_HEAD_* WAGES_T1_HEAD_* TAXABLE_T1_HEAD_WIFE_* WEEKLY_HRS1_T1_WIFE_* WEEKLY_HRS_T1_WIFE_* WEEKLY_HRS1_T1_HEAD_* WEEKLY_HRS_T1_HEAD_* HOUSEWORK_HEAD_* HOUSEWORK_WIFE_* TOTAL_HOUSEWORK_T1_HW_* MOST_HOUSEWORK_T1* EMPLOY_STATUS_HEAD_* EMPLOY_STATUS1_HEAD_* EMPLOY_STATUS2_HEAD_* EMPLOY_STATUS3_HEAD_* EMPLOY_STATUS_WIFE_* EMPLOY_STATUS1_WIFE_* EMPLOY_STATUS2_WIFE_* EMPLOY_STATUS3_WIFE_* NUM_CHILDREN_* AGE_YOUNG_CHILD_* AGE_HEAD_* AGE_WIFE_* TOTAL_INCOME_T1_FAMILY_* FAMILY_INTERVIEW_NUM_* EMPLOY_STATUS_T2_HEAD_* EMPLOY_STATUS_T2_WIFE_* WEEKLY_HRS_T2_HEAD_* WEEKLY_HRS_T2_WIFE_* START_YR_EMPLOYER_HEAD_* START_YR_EMPLOYER_WIFE_* START_YR_CURRENT_HEAD_* START_YR_CURRENT_WIFE_* START_YR_PREV_HEAD_* START_YR_PREV_WIFE_* YRS_CURRENT_EMPLOY_HEAD_* YRS_CURRENT_EMPLOY_WIFE_*  WEEKLY_HRS_T2_INDV_* ANNUAL_HOURS_T1_INDV_* ANNUAL_HOURS_T1_HEAD* ANNUAL_HOURS_T1_WIFE* EMPLOYMENT_INDV* LABOR_INCOME_T1_INDV* LABOR_INCOME_T2_INDV* TOTAL_INCOME_T1_INDV*


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

foreach var in AGE_INDV_ YRS_EDUCATION_INDV_ EDUC1_WIFE_ EDUC1_HEAD_ EDUC_WIFE_ EDUC_HEAD_ LABOR_INCOME_T1_WIFE_ LABOR_INCOME_T2_WIFE_ WAGES_T1_WIFE_ LABOR_INCOME_T1_HEAD_ LABOR_INCOME_T2_HEAD_ WAGES_T1_HEAD_ TAXABLE_T1_HEAD_WIFE_ WEEKLY_HRS1_T1_WIFE_ WEEKLY_HRS_T1_WIFE_ WEEKLY_HRS1_T1_HEAD_ WEEKLY_HRS_T1_HEAD_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_T1_HW_ MOST_HOUSEWORK_T1_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ AGE_HEAD_ AGE_WIFE_ TOTAL_INCOME_T1_FAMILY_ FAMILY_INTERVIEW_NUM_ EMPLOY_STATUS_T2_HEAD_ EMPLOY_STATUS_T2_WIFE_ WEEKLY_HRS_T2_HEAD_ WEEKLY_HRS_T2_WIFE_ START_YR_EMPLOYER_HEAD_ START_YR_EMPLOYER_WIFE_ START_YR_CURRENT_HEAD_ START_YR_CURRENT_WIFE_ START_YR_PREV_HEAD_ START_YR_PREV_WIFE_ YRS_CURRENT_EMPLOY_HEAD_ YRS_CURRENT_EMPLOY_WIFE_  WEEKLY_HRS_T2_INDV_ ANNUAL_HOURS_T1_INDV_ ANNUAL_HOURS_T1_HEAD_ ANNUAL_HOURS_T1_WIFE_ EMPLOYMENT_INDV_ LABOR_INCOME_T1_INDV_ LABOR_INCOME_T2_INDV_ TOTAL_INCOME_T1_INDV_{
	forvalues y=1968/1987{
		capture drop `var'`y' // in case var not in all years
	}
}

drop *_1968

save "$temp\individual_sample_info.dta", replace

********************************************************************************
**# Now merge this info on to individuals and recode core variables
* JUST for individuals; not doing any couple-level
********************************************************************************
use "$created_data\couple_list_individ.dta", clear

merge m:1 unique_id using "$temp\individual_sample_info.dta" //
drop if _merge==2
drop _merge

drop *_sp_*
drop SEX_sp

save "$temp\inidividual_vars_imputation_wide.dta", replace

// use "$temp\inidividual_vars_imputation_wide.dta", clear

reshape long MARITAL_PAIRS_ in_sample_ relationship_ FAMILY_INTERVIEW_NUM_ AGE_INDV_ YRS_EDUCATION_INDV_ EDUC1_WIFE_ EDUC1_HEAD_ EDUC_WIFE_ EDUC_HEAD_ LABOR_INCOME_T1_WIFE_ LABOR_INCOME_T2_WIFE_ WAGES_T1_WIFE_ LABOR_INCOME_T1_HEAD_ LABOR_INCOME_T2_HEAD_ WAGES_T1_HEAD_ TAXABLE_T1_HEAD_WIFE_ WEEKLY_HRS1_T1_WIFE_ WEEKLY_HRS_T1_WIFE_ WEEKLY_HRS1_T1_HEAD_ WEEKLY_HRS_T1_HEAD_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_T1_HW_ MOST_HOUSEWORK_T1_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ AGE_HEAD_ AGE_WIFE_ TOTAL_INCOME_T1_FAMILY_ EMPLOY_STATUS_T2_HEAD_ EMPLOY_STATUS_T2_WIFE_ WEEKLY_HRS_T2_HEAD_ WEEKLY_HRS_T2_WIFE_ START_YR_EMPLOYER_HEAD_ START_YR_EMPLOYER_WIFE_ START_YR_CURRENT_HEAD_ START_YR_CURRENT_WIFE_ START_YR_PREV_HEAD_ START_YR_PREV_WIFE_ YRS_CURRENT_EMPLOY_HEAD_ YRS_CURRENT_EMPLOY_WIFE_  WEEKLY_HRS_T2_INDV_ ANNUAL_HOURS_T1_INDV_ ANNUAL_HOURS_T1_HEAD_ ANNUAL_HOURS_T1_WIFE_ EMPLOYMENT_INDV_ LABOR_INCOME_T1_INDV_ LABOR_INCOME_T2_INDV_ TOTAL_INCOME_T1_INDV_, ///
 i(unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX) j(survey_yr)

// want consecutive waves to make some things easier later
egen wave = group(survey_yr)

********************************************************************************
**# Now that it's long, recode core variables.
* JUST for individuals; not doing any couple-level
********************************************************************************
// t-1 income
browse unique_id survey_yr FAMILY_INTERVIEW_NUM_ TAXABLE_T1_HEAD_WIFE TOTAL_INCOME_T1_FAMILY LABOR_INCOME_T1_HEAD WAGES_T1_HEAD LABOR_INCOME_T1_WIFE_ WAGES_T1_WIFE_ 

	// to use: WAGES_HEAD_ WAGES_WIFE_ -- wife not asked until 1993? okay labor income??
	// wages and labor income asked for head whole time. labor income wife 1968-1993, wages for wife, 1993 onwards

gen earnings_t1_wife=.
replace earnings_t1_wife = LABOR_INCOME_T1_WIFE_ if inrange(survey_yr,1968,1993)
replace earnings_t1_wife = WAGES_T1_WIFE_ if inrange(survey_yr,1994,2021)
replace earnings_t1_wife=. if earnings_t1_wife== 9999999

gen earnings_t1_head=.
replace earnings_t1_head = LABOR_INCOME_T1_HEAD if inrange(survey_yr,1968,1993)
replace earnings_t1_head = WAGES_T1_HEAD if inrange(survey_yr,1994,2021)
replace earnings_t1_head=. if earnings_t1_head== 9999999

// t-1 weekly hours
browse unique_id survey_yr WEEKLY_HRS1_T1_WIFE_ WEEKLY_HRS_T1_WIFE_ WEEKLY_HRS1_T1_HEAD_ WEEKLY_HRS_T1_HEAD_

gen weekly_hrs_t1_wife = .
replace weekly_hrs_t1_wife = WEEKLY_HRS1_T1_WIFE_ if survey_yr > 1969 & survey_yr <1994
replace weekly_hrs_t1_wife = WEEKLY_HRS_T1_WIFE_ if survey_yr >=1994
replace weekly_hrs_t1_wife = 0 if inrange(survey_yr,1968,1969) & inlist(WEEKLY_HRS1_T1_WIFE_,9,0)
replace weekly_hrs_t1_wife = 10 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==1
replace weekly_hrs_t1_wife = 27 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==2
replace weekly_hrs_t1_wife = 35 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==3
replace weekly_hrs_t1_wife = 40 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==4
replace weekly_hrs_t1_wife = 45 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==5
replace weekly_hrs_t1_wife = 48 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==6
replace weekly_hrs_t1_wife = 55 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_WIFE_ ==7
replace weekly_hrs_t1_wife = 60 if inrange(survey_yr,1968,1969)  & WEEKLY_HRS1_T1_WIFE_ ==8
replace weekly_hrs_t1_wife=. if weekly_hrs_t1_wife==999

gen weekly_hrs_t1_head = .
replace weekly_hrs_t1_head = WEEKLY_HRS1_T1_HEAD_ if survey_yr > 1969 & survey_yr <1994
replace weekly_hrs_t1_head = WEEKLY_HRS_T1_HEAD_ if survey_yr >=1994
replace weekly_hrs_t1_head = 0 if inrange(survey_yr,1968,1969) & inlist(WEEKLY_HRS1_T1_HEAD_,9,0)
replace weekly_hrs_t1_head = 10 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==1
replace weekly_hrs_t1_head = 27 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==2
replace weekly_hrs_t1_head = 35 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==3
replace weekly_hrs_t1_head = 40 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==4
replace weekly_hrs_t1_head = 45 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==5
replace weekly_hrs_t1_head = 48 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==6
replace weekly_hrs_t1_head = 55 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_T1_HEAD_ ==7
replace weekly_hrs_t1_head = 60 if inrange(survey_yr,1968,1969)  & WEEKLY_HRS1_T1_HEAD_ ==8
replace weekly_hrs_t1_head=. if weekly_hrs_t1_head==999

// create individual variable using annual version? no but that's not helpful either, because only through 1993? I guess better than nothing
browse unique_id survey_yr relationship_ ANNUAL_HOURS_T1_INDV
gen weekly_hrs_t1_indv = round(ANNUAL_HOURS_T1_INDV / 52,1)
browse unique_id survey_yr relationship_ weekly_hrs_t1_indv weekly_hrs_t1_head weekly_hrs_t1_wife ANNUAL_HOURS_T1_INDV

// current employment
browse unique_id survey_yr EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_
// not numbered until 1994; 1-3 arose in 1994. codes match
// wife not asked until 1976?

gen employ_head=0
replace employ_head=1 if EMPLOY_STATUS_HEAD_==1
gen employ1_head=0
replace employ1_head=1 if EMPLOY_STATUS1_HEAD_==1
gen employ2_head=0
replace employ2_head=1 if EMPLOY_STATUS2_HEAD_==1
gen employ3_head=0
replace employ3_head=1 if EMPLOY_STATUS3_HEAD_==1
egen employed_head=rowtotal(employ_head employ1_head employ2_head employ3_head)
replace employed_head=1 if employed_head==2

gen employ_wife=0
replace employ_wife=1 if EMPLOY_STATUS_WIFE_==1
gen employ1_wife=0
replace employ1_wife=1 if EMPLOY_STATUS1_WIFE_==1
gen employ2_wife=0
replace employ2_wife=1 if EMPLOY_STATUS2_WIFE_==1
gen employ3_wife=0
replace employ3_wife=1 if EMPLOY_STATUS3_WIFE_==1
egen employed_wife=rowtotal(employ_wife employ1_wife employ2_wife employ3_wife)
replace employed_wife=1 if employed_wife==2

browse unique_id survey_yr employed_head employed_wife employ_head employ1_head employ_wife employ1_wife

browse unique_id survey_yr  EMPLOYMENT_INDV
gen employed_indv=.
replace employed_indv=0 if inrange(EMPLOYMENT_INDV,2,9)
replace employed_indv=1 if EMPLOYMENT_INDV==1

// t-1 employment (need to create based on earnings)
gen employed_t1_head=0
replace employed_t1_head=1 if earnings_t1_head > 0 & earnings_t1_head!=.

gen employed_t1_wife=0
replace employed_t1_wife=1 if earnings_t1_wife > 0 & earnings_t1_wife!=.

gen employed_t1_indv=0
replace employed_t1_indv=1 if LABOR_INCOME_T1_INDV > 0 & LABOR_INCOME_T1_INDV!=.

gen ft_pt_t1_head=.
replace ft_pt_t1_head = 0 if weekly_hrs_t1_head==0
replace ft_pt_t1_head = 1 if weekly_hrs_t1_head > 0 & weekly_hrs_t1_head<=35
replace ft_pt_t1_head = 2 if weekly_hrs_t1_head > 35 & weekly_hrs_t1_head < 999

gen ft_pt_t1_wife=.
replace ft_pt_t1_wife = 0 if weekly_hrs_t1_wife==0
replace ft_pt_t1_wife = 1 if weekly_hrs_t1_wife > 0 & weekly_hrs_t1_wife<=35
replace ft_pt_t1_wife = 2 if weekly_hrs_t1_wife > 35 & weekly_hrs_t1_wife < 999

label define ft_pt 0 "Not Employed" 1 "PT" 2 "FT"
label values ft_pt_t1_head ft_pt_t1_wife ft_pt

gen ft_t1_head=0
replace ft_t1_head=1 if ft_pt_t1_head==2

gen ft_t1_wife=0
replace ft_t1_wife=1 if ft_pt_t1_wife==2

// housework hours - not totally sure if accurate prior to 1976 (asked annually not weekly - and was t-1. missing head/wife specific in 1968, 1975, 1982
browse unique_id survey_yr HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_T1_HW MOST_HOUSEWORK_T1 // total and most HW stopped after 1974

gen housework_head = HOUSEWORK_HEAD_
replace housework_head = (HOUSEWORK_HEAD_/52) if inrange(survey_yr,1968,1974)
replace housework_head=. if inlist(housework_head,998,999)
gen housework_wife = HOUSEWORK_WIFE_
replace housework_wife = (HOUSEWORK_WIFE_/52) if inrange(survey_yr,1968,1974)
replace housework_wife=. if inlist(housework_wife,998,999)
gen total_housework_weekly = TOTAL_HOUSEWORK_T1_HW / 52

// Education recode
browse unique_id survey_yr  SEX  EDUC1_HEAD_ EDUC_HEAD_ EDUC1_WIFE_ EDUC_WIFE_ YRS_EDUCATION_INDV // can also use yrs education but this is individual not HH, so need to match to appropriate person
tabstat YRS_EDUCATION_INDV, by(survey_yr) // is that asked in all years? Can i also fill in wife info this way? so seems like 1969 and 1974 missing?

/*
educ1 until 1990, but educ started 1975, okay but then a gap until 1991? wife not asked 1969-1971 - might be able to fill in if she is in sample either 1968 or 1972? (match to the id)

codes are also different between the two, use educ1 until 1990, then educ 1991 post
early educ:
0. cannot read
1. 0-5th grade
2. 6-8th grade
3. 9-11 grade
4/5. 12 grade
6. college no degree
7/8. college / advanced degree
9. dk

later educ: years of education
*/

recode EDUC1_WIFE_ (1/3=1)(4/5=2)(6=3)(7/8=4)(9=.)(0=.), gen(educ_wife_early)
recode EDUC1_HEAD_ (0/3=1)(4/5=2)(6=3)(7/8=4)(9=.), gen(educ_head_early)
recode EDUC_WIFE_ (1/11=1) (12=2) (13/15=3) (16/17=4) (99=.)(0=.), gen(educ_wife_1975)
recode EDUC_HEAD_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_head_1975)
recode YRS_EDUCATION_INDV (1/11=1) (12=2) (13/15=3) (16/17=4) (98/99=.)(0=.), gen(educ_completed) // okay no, can't use this, because I guess it's not actually comparable? because head / wife ONLY recorded against those specific ones.

label define educ 1 "LTHS" 2 "HS" 3 "Some College" 4 "College"
label values educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 educ_completed educ

gen educ_wife=.
replace educ_wife=educ_wife_early if inrange(survey_yr,1968,1990)
replace educ_wife=educ_wife_1975 if inrange(survey_yr,1991,2021)
tab survey_yr educ_wife, m // so 69, 70, 71

gen educ_head=.
replace educ_head=educ_head_early if inrange(survey_yr,1968,1990)
replace educ_head=educ_head_1975 if inrange(survey_yr,1991,2021)

label values educ_wife educ_head educ

	// trying to fill in missing wife years when possible
	browse unique_id survey_yr educ_wife
	bysort unique_id (educ_wife): replace educ_wife=educ_wife[1] if educ_wife==.
	replace educ_wife=. if relationship_==0
	// can I also use years of education? okay no.

sort unique_id survey_yr

gen college_complete_wife=.
replace college_complete_wife=0 if inrange(educ_wife,1,3)
replace college_complete_wife=1 if educ_wife==4

gen college_complete_head=.
replace college_complete_head=0 if inrange(educ_head,1,3)
replace college_complete_head=1 if educ_head==4

gen college_complete_indv=.
replace college_complete_indv=0 if inrange(educ_completed,1,3)
replace college_complete_indv=1 if educ_completed==4

// number of children
gen children=0
replace children=1 if NUM_CHILDREN_>=1

********************************************************************************
**# now need to allocate variables to individual based on relationship
* so that we have FOCAL variables, not head / sex versions
********************************************************************************

* Let's start with t-1 variables
// weekly hours
browse unique_id survey_yr relationship  weekly_hrs_t1_head weekly_hrs_t1_wife weekly_hrs_t1_indv
gen weekly_hrs_t1_focal=.
replace weekly_hrs_t1_focal=weekly_hrs_t1_head if relationship_==1
replace weekly_hrs_t1_focal=weekly_hrs_t1_wife if relationship_==2
replace weekly_hrs_t1_focal=weekly_hrs_t1_indv if relationship_==3

// annual earnings
browse unique_id survey_yr relationship earnings_t1_head earnings_t1_wife LABOR_INCOME_T1_INDV
gen earnings_t1_focal=.
replace earnings_t1_focal=earnings_t1_head if relationship_==1
replace earnings_t1_focal=earnings_t1_wife if relationship_==2
replace earnings_t1_focal=LABOR_INCOME_T1_INDV if relationship_==3

* t variables
// weekly HW hours
browse unique_id survey_yr relationship housework_head housework_wife
gen housework_focal=.
replace housework_focal=housework_head if relationship_==1
replace housework_focal=housework_wife if relationship_==2
replace housework_focal=. if relationship_==3

// Current employment status
browse unique_id survey_yr relationship_ employed_head employed_wife employed_indv
gen employed_focal=.
replace employed_focal=employed_head if relationship_==1
replace employed_focal=employed_wife if relationship_==2
replace employed_focal=employed_indv if relationship_==3

// Education
browse unique_id survey_yr relationship_ educ_head educ_wife educ_completed college_*
gen educ_focal=.
replace educ_focal=educ_head if relationship_==1
replace educ_focal=educ_wife if relationship_==2
replace educ_focal=educ_completed if relationship_==3

gen college_focal=.
replace college_focal = 0 if inrange(educ_focal,1,3)
replace college_focal = 1 if educ_focal==4

// Age
browse unique_id survey_yr relationship_ AGE_*
gen age_focal = AGE_INDV

* t-2 variables
// weekly hours
browse unique_id survey_yr relationship_ WEEKLY_HRS_T2_HEAD WEEKLY_HRS_T2_WIFE WEEKLY_HRS_T2_INDV

gen weekly_hrs_t2_focal=.
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_INDV if inrange(survey_yr,1999,2001)
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_HEAD if relationship_==1 & inrange(survey_yr,2003,2021)
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_WIFE if relationship_==2 & inrange(survey_yr,2003,2021)
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_INDV if relationship_==3 & inrange(survey_yr,2003,2021)
browse unique_id survey_yr relationship_ weekly_hrs_t2_focal WEEKLY_HRS_T2_HEAD WEEKLY_HRS_T2_WIFE WEEKLY_HRS_T2_INDV

// annual earnings
browse unique_id survey_yr relationship_ LABOR_INCOME_T2_HEAD_ LABOR_INCOME_T2_WIFE_ LABOR_INCOME_T2_INDV_

gen long earnings_t2_focal=.
replace earnings_t2_focal=LABOR_INCOME_T2_INDV_ if inrange(survey_yr,1999,2001)
replace earnings_t2_focal=LABOR_INCOME_T2_HEAD_ if relationship_==1 & inrange(survey_yr,2003,2021)
replace earnings_t2_focal=LABOR_INCOME_T2_WIFE_ if relationship_==2 & inrange(survey_yr,2003,2021)
replace earnings_t2_focal=LABOR_INCOME_T2_INDV_ if relationship_==3 & inrange(survey_yr,2003,2021)
replace earnings_t2_focal=. if earnings_t2_focal==9999999 | earnings_t2_focal==99999999
browse unique_id survey_yr relationship_ earnings_t2_focal LABOR_INCOME_T2_HEAD_ LABOR_INCOME_T2_WIFE_ LABOR_INCOME_T2_INDV_

// employment status
gen employed_t2_head=.
replace employed_t2_head=0 if EMPLOY_STATUS_T2_HEAD==5
replace employed_t2_head=1 if EMPLOY_STATUS_T2_HEAD==1

gen employed_t2_wife=.
replace employed_t2_wife=0 if EMPLOY_STATUS_T2_WIFE==5
replace employed_t2_wife=1 if EMPLOY_STATUS_T2_WIFE==1

gen employed_t2_focal=.
replace employed_t2_focal=employed_t2_head if relationship_==1
replace employed_t2_focal=employed_t2_wife if relationship_==2
replace employed_t2_focal=1 if inrange(survey_yr,1999,2001) & WEEKLY_HRS_T2_INDV>0 & WEEKLY_HRS_T2_INDV!=.
replace employed_t2_focal=0 if inrange(survey_yr,1999,2001) & WEEKLY_HRS_T2_INDV==0

browse unique_id survey_yr relationship_ employed_t2_focal employed_t2_head WEEKLY_HRS_T2_HEAD WEEKLY_HRS_T2_INDV // can I use hours to fill in the gaps?

* employment history to fill the gaps
sum START_YR_CURRENT_HEAD, detail
replace START_YR_CURRENT_HEAD=. if inrange(START_YR_CURRENT_HEAD,9000,9999)
replace START_YR_CURRENT_HEAD=. if START_YR_CURRENT_HEAD==0
tabstat START_YR_CURRENT_HEAD, by(survey_yr)
replace START_YR_CURRENT_HEAD=1900+START_YR_CURRENT_HEAD if START_YR_CURRENT_HEAD<100

sum START_YR_PREV_HEAD, detail
replace START_YR_PREV_HEAD=. if inrange(START_YR_PREV_HEAD,9000,9999)
replace START_YR_PREV_HEAD=. if START_YR_PREV_HEAD==0
tabstat START_YR_PREV_HEAD, by(survey_yr)
replace START_YR_PREV_HEAD=1900+START_YR_PREV_HEAD if START_YR_PREV_HEAD<100

sum START_YR_EMPLOYER_HEAD, detail
replace START_YR_EMPLOYER_HEAD=. if inrange(START_YR_EMPLOYER_HEAD,9000,9999)
replace START_YR_EMPLOYER_HEAD=. if START_YR_EMPLOYER_HEAD==0

gen start_yr_employer_head=.
replace start_yr_employer_head = START_YR_CURRENT_HEAD if inrange(survey_yr,1988,2001) & START_YR_CURRENT_HEAD!=.
replace start_yr_employer_head = START_YR_PREV_HEAD if inrange(survey_yr,1988,2001) & START_YR_PREV_HEAD!=.
replace start_yr_employer_head = START_YR_EMPLOYER_HEAD if inrange(survey_yr,2003,2021)

browse unique_id survey_yr relationship_ start_yr_employer_head START_YR_EMPLOYER_HEAD START_YR_CURRENT_HEAD START_YR_PREV_HEAD YRS_CURRENT_EMPLOY_HEAD

sum START_YR_CURRENT_WIFE, detail
replace START_YR_CURRENT_WIFE=. if inrange(START_YR_CURRENT_WIFE,9000,9999)
replace START_YR_CURRENT_WIFE=. if START_YR_CURRENT_WIFE==0
tabstat START_YR_CURRENT_WIFE, by(survey_yr)
replace START_YR_CURRENT_WIFE=1900+START_YR_CURRENT_WIFE if START_YR_CURRENT_WIFE<100

sum START_YR_PREV_WIFE, detail
replace START_YR_PREV_WIFE=. if inrange(START_YR_PREV_WIFE,9000,9999)
replace START_YR_PREV_WIFE=. if START_YR_PREV_WIFE==0
tabstat START_YR_PREV_WIFE, by(survey_yr)
replace START_YR_PREV_WIFE=1900+START_YR_PREV_WIFE if START_YR_PREV_WIFE<100

sum START_YR_EMPLOYER_WIFE, detail
replace START_YR_EMPLOYER_WIFE=. if inrange(START_YR_EMPLOYER_WIFE,9000,9999)
replace START_YR_EMPLOYER_WIFE=. if START_YR_EMPLOYER_WIFE==0

gen start_yr_employer_wife=.
replace start_yr_employer_wife = START_YR_CURRENT_WIFE if inrange(survey_yr,1988,2001) & START_YR_CURRENT_WIFE!=.
replace start_yr_employer_wife = START_YR_PREV_WIFE if inrange(survey_yr,1988,2001) & START_YR_PREV_WIFE!=.
replace start_yr_employer_wife = START_YR_EMPLOYER_WIFE if inrange(survey_yr,2003,2021)

gen start_yr_employer_focal = .
replace start_yr_employer_focal = start_yr_employer_head if relationship_==1 
replace start_yr_employer_focal = start_yr_employer_wife if relationship_==2

gen yrs_employer_focal = .
replace yrs_employer_focal=YRS_CURRENT_EMPLOY_HEAD if relationship_==1
replace yrs_employer_focal=YRS_CURRENT_EMPLOY_WIFE if relationship_==2

// drop variables that aren't core (aka were used to create main variables)
drop LABOR_INCOME_T1_WIFE_ WAGES_T1_WIFE_ LABOR_INCOME_T1_HEAD WAGES_T1_HEAD WEEKLY_HRS1_T1_WIFE_ WEEKLY_HRS_T1_WIFE_ WEEKLY_HRS1_T1_HEAD_ WEEKLY_HRS_T1_HEAD_  ANNUAL_HOURS_T1_INDV EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ employ_head employ1_head employ2_head employ3_head employ_wife employ1_wife employ2_wife employ3_wife HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_T1_HW MOST_HOUSEWORK_T1 EDUC1_HEAD_ EDUC_HEAD_ EDUC1_WIFE_ EDUC_WIFE_  educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 START_YR_EMPLOYER_HEAD START_YR_CURRENT_HEAD START_YR_PREV_HEAD YRS_CURRENT_EMPLOY_HEAD START_YR_EMPLOYER_WIFE START_YR_CURRENT_WIFE START_YR_PREV_WIFE YRS_CURRENT_EMPLOY_WIFE total_housework_weekly

save "$temp\inidividual_vars_imputation_long.dta", replace

********************************************************************************
**# now reshape back to wide to fill in the off years where possible (with t-2 data)
********************************************************************************
// use "$temp\inidividual_vars_imputation_long.dta", clear

drop *_head* *_HEAD* *_wife* *_WIFE* *_INDV* *_indv* educ_completed wave

reshape wide in_sample_ relationship_ MARITAL_PAIRS_ weekly_hrs_t1_focal earnings_t1_focal housework_focal employed_focal educ_focal college_focal age_focal weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal start_yr_employer_focal yrs_employer_focal children FAMILY_INTERVIEW_NUM_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ FIRST_BIRTH_YR TOTAL_INCOME_T1_FAMILY_ ///
, i(unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX) j(survey_yr)

// weekly hours
browse unique_id weekly_hrs_t1_focal* weekly_hrs_t2_focal*
// gen weekly_hrs_t1_focal1998=weekly_hrs_t2_focal1999 // so, t-2 for 1999 becomes t-1 for 1998

forvalues y=1998(2)2020{
	local z=`y'+1
	gen weekly_hrs_t1_focal`y'=weekly_hrs_t2_focal`z'
}

browse weekly_hrs_t1_focal1998 weekly_hrs_t1_focal1999 weekly_hrs_t1_focal2000 weekly_hrs_t2_focal1999 weekly_hrs_t2_focal2001

// earnings
forvalues y=1998(2)2020{
	local z=`y'+1
	gen earnings_t1_focal`y'=earnings_t2_focal`z'
}

browse weekly_hrs_t1_focal1998 earnings_t1_focal1998 weekly_hrs_t2_focal1999 earnings_t2_focal1999

/*
// employment status - this won't really work because one is t, not t-1...
forvalues y=1998(2)2020{
	local z=`y'+1
	gen employed_focal`y'=employed_t2_focal`z'
}
*/

********************************************************************************
* BACK to long so can recenter on duration
********************************************************************************
reshape long

browse unique_id survey_yr rel_start_all min_dur max_dur relationship_ in_sample_ weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal

foreach var in weekly_hrs_t1_focal earnings_t1_focal housework_focal employed_focal educ_focal college_focal age_focal weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal start_yr_employer_focal yrs_employer_focal{
	replace `var'=. if in_sample==0
}

gen duration = survey_yr - rel_start_all
browse unique_id partner_id survey_yr rel_start_all duration last_yr_observed

tab duration, m
keep if duration >=-4 // keep up to 5 years prior, jic
keep if duration <=12 // up to 10/11 for now - but adding a few extra years so I can do the lookups below and still retain up to 20

browse unique_id survey_yr rel_start_all duration min_dur max_dur relationship_ in_sample_ weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal

**# Here the data is now long, by duration
save "$created_data\individs_by_duration_long.dta", replace

unique unique_id partner_id
egen couple_id = group(unique_id partner_id)
browse couple_id unique_id partner_id duration SEX

fillin couple_id duration
tab duration
unique couple_id

bysort couple_id (SEX): replace SEX=SEX[1] if SEX==.
bysort couple_id (unique_id): replace unique_id=unique_id[1] if unique_id==.
bysort couple_id (partner_id): replace partner_id=partner_id[1] if partner_id==.

foreach var in rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended{
	bysort couple_id (`var'): replace `var'=`var'[1] if `var'==.
}

gen duration_rec=duration+4 // negatives won't work in reshape or with sq commands - so make -4 0

sort couple_id duration
browse couple_id duration weekly_hrs_t1_focal housework_focal _fillin

replace weekly_hrs_t1_focal=. if weekly_hrs_t1_focal>900 & weekly_hrs_t1_focal!=.

// just to get a better sense of the data instead of plotting by the continuous variable
gen hours_type_t1_focal=.
replace hours_type_t1_focal=0 if weekly_hrs_t1_focal==0
replace hours_type_t1_focal=1 if weekly_hrs_t1_focal>0 & weekly_hrs_t1_focal<35
replace hours_type_t1_focal=2 if weekly_hrs_t1_focal>=35 & weekly_hrs_t1_focal!=.

sqset hours_type_t1 couple_id duration_rec
sqindexplot, gapinclude
sqindexplot, gapinclude by(SEX)
// sdchronogram hours_type_t1

// just to get a better sense of the data instead of plotting by the continuous variable
gen hw_hours_gp=.
replace hw_hours_gp=0 if housework_focal==0
replace hw_hours_gp=1 if housework_focal>0 & housework_focal<10
replace hw_hours_gp=2 if housework_focal>=10 & housework_focal!=.

sqset hw_hours_gp couple_id duration_rec
sqindexplot, gapinclude
sqindexplot, gapinclude by(SEX)

********************************************************************************
* reshaping wide for imputation purposes
********************************************************************************

drop survey_yr duration _fillin

reshape wide in_sample_ relationship_ MARITAL_PAIRS_ weekly_hrs_t1_focal earnings_t1_focal housework_focal employed_focal educ_focal college_focal age_focal weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal start_yr_employer_focal yrs_employer_focal children FAMILY_INTERVIEW_NUM_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ FIRST_BIRTH_YR TOTAL_INCOME_T1_FAMILY_ hours_type_t1_focal hw_hours_gp ///
, i(couple_id unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX) j(duration_rec)


**# Here the data is now reshaped wide, by duration
save "$created_data\individs_by_duration_wide.dta", replace
// use "$created_data\individs_by_duration_wide.dta", clear

// first, let's just get a sense of missings
unique unique_id
unique unique_id partner_id

browse unique_id partner_id couple_id weekly_hrs_t1_focal*
browse unique_id housework_focal*

forvalues y=0/16{
	replace weekly_hrs_t1_focal`y' = round(weekly_hrs_t1_focal`y',1)
}

/*
forvalues y=1/16{
	replace hours_type_t1_focal`y' = 4 if hours_type_t1_focal`y'==.
	replace hours_type_t1_focal`y' = 3 if hours_type_t1_focal`y'==0
}
*/

// sdchronogram hours_type_t1_focal0-hours_type_t1_focal16 // this is not working; I am not sure why

** Looking at steps in Halpin 2016
mict_prep weekly_hrs_t1_focal, id(couple_id)

// browse _mct_id _mct_t _mct_state _mct_last _mct_next // last feels off? okay last and next are created...somewhere else? they aren't created here? I am so confused...bc they are supposed to be created here...

// redefine bc they should be regress, not mlogit, but can't use augment when I do that, just fyi
// trying ologit instead of regress bc i think it's predicting non-integer numbers. OKAY if I just remove the i. from next and last is that actually fine??
// okay so that is not converging LOL

capture program drop mict_model_gap
program mict_model_gap
mi impute regress _mct_state ///
_mct_next _mct_last ///
_mct_before* _mct_after*, ///
add(1) force
end

capture program drop mict_model_initial
program mict_model_initial
mi impute regress _mct_state _mct_next _mct_after*, add(1) force
end

capture program drop mict_model_terminal
program mict_model_terminal
mi impute regress _mct_state _mct_last _mct_before*, add(1) force
end

mict_impute, maxgap(6) maxitgap(3) // this is getting stuck with integers. Because the data isn't truly categorical. trying ologit but now it is taking much longer.
// best practice for maxgap seems to be half of total time length. then maxitgap seems to be half of maxgap

// browse _mct_id _mct_t _mct_state _mct_last _mct_next _mct_lg _mct_tw _mct_initgap _mct_termgap _mct_igl _mct_tgl

browse couple_id weekly_hrs_t1_focal* _mct_iter

// let's trying removing cumulative duration. think for hours this is worse than if a true sequence state?
use "$created_data\individs_by_duration_wide.dta", clear

mict_prep weekly_hrs_t1_focal, id(couple_id)

capture program drop mict_model_gap
program mict_model_gap
mi impute regress _mct_state ///
_mct_next _mct_last, ///
add(1) force
end

capture program drop mict_model_initial
program mict_model_initial
mi impute regress _mct_state _mct_next, add(1) force
end

capture program drop mict_model_terminal
program mict_model_terminal
mi impute regress _mct_state _mct_last, add(1) force
end

mict_impute, maxgap(6) maxitgap(3) 

browse couple_id weekly_hrs_t1_focal* _mct_iter