********************************************************************************
********************************************************************************
* Project: PSID Data Compilation
* Owner: Kimberly McErlean
* Started: September 2024
* File: individual_recodes
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the full PSID dataset in long format
* Then recodes variables for congruence across time and for clarity
* Then matches to focal person (based on relationship)

use "$temp_psid\PSID_full_long.dta", clear // use long data for now, bc easier to manage
egen wave = group(survey_yr) // this will make years consecutive, easier for later

********************************************************************************
**# First create some technical recodes that will make things easier
********************************************************************************

gen in_sample=. // right now, everyone is here, regardless of whether in sample in a given year
replace in_sample=0 if SEQ_NUMBER_==0 | inrange(SEQ_NUMBER_,60,90)
replace in_sample=1 if inrange(SEQ_NUMBER_,1,59)

replace in_sample=0 if survey_yr==1968 & RELATION_==0 // no seq number in 1968
replace in_sample=1 if survey_yr==1968 & RELATION_!=0 // no seq number in 1968

gen hh_status_=.
replace hh_status_=0 if SEQ_NUMBER_==0 
replace hh_status_=1 if inrange(SEQ_NUMBER_,1,20) // in sample
replace hh_status_=2 if inrange(SEQ_NUMBER_,51,59) // institutionalized
replace hh_status_=3 if inrange(SEQ_NUMBER_,71,80) // new HH 
replace hh_status_=4 if inrange(SEQ_NUMBER_,81,89) // died
replace hh_status = 0 if survey_yr==1968 & in_sample==0
replace hh_status = 1 if survey_yr==1968 & in_sample==1

label define hh_status 0 "not in sample" 1 "in sample" 2 "institutionalized" 3 "new hh" 4 "died"
label values hh_status_ hh_status

tab hh_status in_sample, m 

gen has_psid_gene=0
replace has_psid_gene = 1 if inlist(SAMPLE,1,2)

label define sample 0 "not sample" 1 "original sample" 2 "born-in" 3 "moved in" 4 "joint inclusion" 5 "followable nonsample parent" 6 "nonsample elderly"
label values SAMPLE sample

bysort unique_id (survey_yr): egen first_survey_yr = min(survey_yr) if in_sample==1
bysort unique_id (first_survey_yr): replace first_survey_yr=first_survey_yr[1]
bysort unique_id (survey_yr): egen last_survey_yr = max(survey_yr) if in_sample==1
bysort unique_id (last_survey_yr): replace last_survey_yr=last_survey_yr[1]
sort unique_id survey_yr
// browse unique_id survey_yr first_survey_yr last_survey_yr hh_status in_sample AGE_INDV_

gen relationship=.
replace relationship=0 if RELATION_==0
replace relationship=1 if inlist(RELATION_,1,10)
replace relationship=2 if inlist(RELATION_,2,20,22,88)
replace relationship=3 if inrange(RELATION_,23,87) | inrange(RELATION_,90,98) | inrange(RELATION_,3,9)
label define relationship 0 "not in sample" 1 "head" 2 "partner" 3 "other"
label values relationship relationship

gen moved = 0
replace moved = 1 if inlist(MOVED_,1,2) & inlist(SPLITOFF_,1,3) // moved in
replace moved = 2 if inlist(MOVED_,1,2) & inlist(SPLITOFF_,2,4) // splitoff
replace moved = 3 if inlist(MOVED_,5,6) // moved out
replace moved = 4 if MOVED_==1 & SPLITOFF_==0 // born
replace moved = 5 if MOVED_==7

label define moved 0 "no" 1 "Moved in" 2 "Splitoff" 3 "Moved out" 4 "Born" 5 "Died"
label values moved moved
tab moved in_sample, m

tab AGE_INDV_ moved

gen permanent_attrit=0
replace permanent_attrit=1 if PERMANENT_ATTRITION==1 // attrited
replace permanent_attrit=2 if inlist(PERMANENT_ATTRITION,2,3) // marked as died
label define perm 0 "no" 1 "attrited" 2 "died"
label values permanent_attrit perm

tab MOVED_YEAR_ SPLITOFF_YEAR_ if MOVED_YEAR_!=0 & SPLITOFF_YEAR_ !=0, m

gen change_yr=.
replace change_yr = MOVED_YEAR_ if MOVED_YEAR_ >0 & MOVED_YEAR_ <9000
replace change_yr = SPLITOFF_YEAR_ if SPLITOFF_YEAR_ >0 & SPLITOFF_YEAR_ <9000

bysort unique_id: egen entrance_no=rank(change_yr) if inlist(moved,1,4), track
bysort unique_id: egen leave_no=rank(change_yr) if inlist(moved,2,3,5), track
tab entrance_no, m
tab leave_no, m

********************************************************************************
**# Demographic recodes
********************************************************************************
// think sometimes not in sample given 0 and sometimes missing (esp for individuals) - let's make all missing
misstable summarize *_INDV*, all
// misstable summarize *_HEAD*, all
// misstable summarize *_WIFE*, all

foreach var in AGE_INDV_ BIRTH_YR_INDV_ EMPLOYMENT_INDV_ COLLEGE_INDV_ BACHELOR_YR_INDV_ STUDENT_CURRENT_INDV_ YRS_EDUCATION_INDV_ NUM_JOBS_T1_INDV_ LABOR_INCOME_T1_INDV_ TOTAL_INCOME_T1_INDV_ ANNUAL_HOURS_T1_INDV_ STUDENT_T1_INDV_ WEEKLY_HRS_T2_INDV_ LABOR_INCOME_T2_INDV_ HOUSEWORK_INDV_ WEEKS_WORKED_T2_INDV_{
	replace `var'=. if in_sample==0
}

// fill in missing birthdates from age if possible (And check against age)
browse unique_id survey_yr BIRTH_YR_INDV_ AGE_INDV_
replace AGE_INDV_=. if AGE_INDV_==999
replace BIRTH_YR_INDV_ = survey_yr - AGE_INDV_ if BIRTH_YR_INDV_==.
bysort unique_id: egen birth_yr = mode(BIRTH_YR_INDV_), minmode
replace AGE_INDV_ = survey_yr - birth_yr if AGE_INDV_==. & in_sample==1
// browse unique_id survey_yr birth_yr BIRTH_YR_INDV_ AGE_INDV_

// partnership status
gen partnered=.
replace partnered=0 if in_sample==1 & MARITAL_PAIRS_==0
replace partnered=1 if in_sample==1 & inrange(MARITAL_PAIRS_,1,3)

// t-1 income
browse unique_id survey_yr FAMILY_INTERVIEW_NUM_ TOTAL_INCOME_T1_FAMILY TAXABLE_T1_HEAD_WIFE LABOR_INCOME_T1_INDV LABOR_INCOME_T1_HEAD WAGES_T1_HEAD LABOR_INCOME_T1_WIFE_ WAGES_T1_WIFE_ 

	// to use: WAGES_T1_HEAD_ WAGES_T1_WIFE_ -- wife not asked until 1993? okay labor income??
	// wages and labor income asked for head whole time, but wages doesn't seem to match labor income until 1970.
	// Oh I think it might have been grouped until then.
	// labor income wife 1968-1993, wages for wife, 1993 onwards

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

// create individual variable using annual version? this variable only through 1993, but I guess better than nothing
browse unique_id survey_yr relationship ANNUAL_HOURS_T1_INDV
gen weekly_hrs_t1_indv = round(ANNUAL_HOURS_T1_INDV / 52,1) if ANNUAL_HOURS_T1_INDV!=9999
browse unique_id survey_yr relationship weekly_hrs_t1_indv weekly_hrs_t1_head weekly_hrs_t1_wife ANNUAL_HOURS_T1_INDV WEEKLY_HRS1_T1_WIFE_ WEEKLY_HRS_T1_WIFE_ WEEKLY_HRS1_T1_HEAD_ WEEKLY_HRS_T1_HEAD_

// current employment
browse unique_id survey_yr relationship EMPLOYMENT_INDV EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_
// not numbered until 1994; 1-3 arose in 1994. codes match
// wife not asked until 1976?
// indiv only 1979-2021

gen employ_head=.
replace employ_head=0 if inrange(EMPLOY_STATUS_HEAD_,2,9)
replace employ_head=1 if EMPLOY_STATUS_HEAD_==1
gen employ1_head=.
replace employ1_head=0 if inrange(EMPLOY_STATUS1_HEAD_,2,8)
replace employ1_head=1 if EMPLOY_STATUS1_HEAD_==1
gen employ2_head=.
replace employ2_head=0 if EMPLOY_STATUS2_HEAD_==0 | inrange(EMPLOY_STATUS2_HEAD_,2,8)
replace employ2_head=1 if EMPLOY_STATUS2_HEAD_==1
gen employ3_head=.
replace employ3_head=0 if EMPLOY_STATUS3_HEAD_==0 | inrange(EMPLOY_STATUS3_HEAD_,2,8)
replace employ3_head=1 if EMPLOY_STATUS3_HEAD_==1

browse employ_head employ1_head employ2_head employ3_head
egen employed_head=rowtotal(employ_head employ1_head employ2_head employ3_head), missing
replace employed_head=1 if employed_head==2

gen employ_wife=.
replace employ_wife=0 if inrange(EMPLOY_STATUS_WIFE_,2,9)
replace employ_wife=1 if EMPLOY_STATUS_WIFE_==1
gen employ1_wife=.
replace employ1_wife=0 if inrange(EMPLOY_STATUS1_WIFE_,2,8)
replace employ1_wife=1 if EMPLOY_STATUS1_WIFE_==1
gen employ2_wife=.
replace employ2_wife=0 if EMPLOY_STATUS2_WIFE_==0 | inrange(EMPLOY_STATUS2_WIFE_,2,8)
replace employ2_wife=1 if EMPLOY_STATUS2_WIFE_==1
gen employ3_wife=.
replace employ3_wife=0 if EMPLOY_STATUS3_WIFE_==0 | inrange(EMPLOY_STATUS3_WIFE_,2,8)
replace employ3_wife=1 if EMPLOY_STATUS3_WIFE_==1

egen employed_wife=rowtotal(employ_wife employ1_wife employ2_wife employ3_wife), missing
replace employed_wife=1 if employed_wife==2

browse unique_id survey_yr employed_head employed_wife employ_head employ1_head employ_wife employ1_wife

browse unique_id survey_yr  EMPLOYMENT_INDV
gen employed_indv=.
replace employed_indv=0 if inrange(EMPLOYMENT_INDV,2,9)
replace employed_indv=1 if EMPLOYMENT_INDV==1

// t-1 employment (need to create based on earnings)
gen employed_t1_head=.
replace employed_t1_head=0 if earnings_t1_head == 0
replace employed_t1_head=1 if earnings_t1_head > 0 & earnings_t1_head!=.

gen employed_t1_wife=.
replace employed_t1_wife=0 if earnings_t1_wife == 0
replace employed_t1_wife=1 if earnings_t1_wife > 0 & earnings_t1_wife!=.

gen employed_t1_indv=.
replace employed_t1_indv=0 if LABOR_INCOME_T1_INDV == 0
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
replace ft_t1_head=. if ft_pt_t1_head==.

gen ft_t1_wife=0
replace ft_t1_wife=1 if ft_pt_t1_wife==2
replace ft_t1_wife=. if ft_pt_t1_wife==.

// housework hours - not totally sure if accurate prior to 1976 (asked annually not weekly - and was t-1. missing head/wife specific in 1968, 1975, 1982
browse unique_id survey_yr relationship HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ HOUSEWORK_INDV_ TOTAL_HOUSEWORK_T1_HW MOST_HOUSEWORK_T1
// total and most HW stopped after 1974 (and it was in 1975 that head / wife versions changed) inividual stopped 1986.
// could use individual until 1975, which is when the head / wife ones shifted from annual t-1 to weekly t
	// tabstat HOUSEWORK_INDV_, by(survey_yr) // okay also missing 68,75,82
	// tabstat HOUSEWORK_HEAD_, by(survey_yr)

gen housework_head = HOUSEWORK_HEAD_
replace housework_head = (HOUSEWORK_HEAD_/52) if inrange(survey_yr,1968,1974)
replace housework_head = HOUSEWORK_INDV_ if relationship==1 & inrange(survey_yr,1968,1974) & HOUSEWORK_INDV_!=.
replace housework_head=. if inlist(housework_head,998,999)

gen housework_wife = HOUSEWORK_WIFE_
replace housework_wife = (HOUSEWORK_WIFE_/52) if inrange(survey_yr,1968,1974)
replace housework_wife = HOUSEWORK_INDV_ if relationship==2 & inrange(survey_yr,1968,1974) & HOUSEWORK_INDV_!=.
replace housework_wife=. if inlist(housework_wife,998,999)

gen total_housework_weekly = TOTAL_HOUSEWORK_T1_HW / 52

browse unique_id survey_yr relationship housework_head housework_wife HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ HOUSEWORK_INDV_

// Education recode
browse unique_id survey_yr relationship SEX  EDUC1_HEAD_ EDUC_HEAD_ EDUC1_WIFE_ EDUC_WIFE_ YRS_EDUCATION_INDV COLLEGE_WIFE_ COLLEGE_HEAD_ COLLEGE_INDV_ BACHELOR_YR_WIFE_ BACHELOR_YR_HEAD_ BACHELOR_YR_INDV_  ENROLLED_WIFE_ ENROLLED_HEAD_ STUDENT_T1_INDV_ STUDENT_CURRENT_INDV_ // can also use yrs education but this is individual not HH, so need to match to appropriate person

/*
foreach var in EDUC1_HEAD_ EDUC_HEAD_ EDUC1_WIFE_ EDUC_WIFE_ YRS_EDUCATION_INDV COLLEGE_WIFE_ COLLEGE_HEAD_ COLLEGE_INDV_ ENROLLED_WIFE_ ENROLLED_HEAD_ STUDENT_T1_INDV_ STUDENT_CURRENT_INDV_ BACHELOR_YR_WIFE_ BACHELOR_YR_HEAD_ BACHELOR_YR_INDV_{
	tabstat `var', by(survey_yr) // want to see which variables asked when	
}

foreach var in YRS_EDUCATION_INDV COLLEGE_INDV_ STUDENT_T1_INDV_ STUDENT_CURRENT_INDV_ BACHELOR_YR_INDV_{
	tabstat `var', by(relationship) // are they asked for all?
}
*/

/*
educ1 until 1990, but educ started 1975, okay but then a gap until 1991? wife not asked 1969-1971 - might be able to fill in if she is in sample either 1968 or 1972? (match to the id). also look at yrs education (missing 69 and 74?)

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

* clean up intermediary variables
label values YRS_EDUCATION_INDV .

gen hs_head=.
replace hs_head=1 if inlist(HS_GRAD_HEAD_,1,2)
replace hs_head=0 if HS_GRAD_HEAD_==3

gen hs_wife=.
replace hs_wife=1 if inlist(HS_GRAD_WIFE_,1,2)
replace hs_wife=0 if HS_GRAD_WIFE_==3

gen attended_college_head=.
replace attended_college_head= 0 if ATTENDED_COLLEGE_HEAD_==5
replace attended_college_head= 1 if ATTENDED_COLLEGE_HEAD_==1

gen attended_college_wife=.
replace attended_college_wife= 0 if ATTENDED_COLLEGE_WIFE_==5
replace attended_college_wife= 1 if ATTENDED_COLLEGE_WIFE_==1

gen completed_college_head=.
replace completed_college_head= 0 if COLLEGE_HEAD_==5
replace completed_college_head= 1 if COLLEGE_HEAD_==1
replace completed_college_head= 0 if attended_college_head==0

gen completed_college_wife=.
replace completed_college_wife= 0 if COLLEGE_WIFE_==5
replace completed_college_wife= 1 if COLLEGE_WIFE_==1
replace completed_college_wife= 0 if attended_college_wife==0

gen completed_college_indv=.
replace completed_college_indv= 0 if COLLEGE_INDV_==5
replace completed_college_indv= 1 if COLLEGE_INDV_==1

gen college_degree_head=.
replace college_degree_head=0 if HIGHEST_DEGREE_HEAD_==0
replace college_degree_head=1 if HIGHEST_DEGREE_HEAD_==1 // associates
replace college_degree_head=2 if inrange(HIGHEST_DEGREE_HEAD_,2,6) // bachelor's plus

gen college_degree_wife=.
replace college_degree_wife=0 if HIGHEST_DEGREE_WIFE_==0
replace college_degree_wife=1 if HIGHEST_DEGREE_WIFE_==1 // associates
replace college_degree_wife=2 if inrange(HIGHEST_DEGREE_WIFE_,2,6) // bachelor's plus

label define degree 0 "No Coll" 1 "Assoc" 2 "BA+"
label values college_degree_head college_degree_wife

tab attended_college_head completed_college_head, m
tab completed_college_head college_degree_head, m

replace NEW_HEAD_YEAR = 1900+NEW_HEAD_YEAR if NEW_HEAD_YEAR>0 & NEW_HEAD_YEAR<100
replace NEW_WIFE_YEAR = 1900+NEW_WIFE_YEAR if NEW_WIFE_YEAR>0 & NEW_WIFE_YEAR<100

recode EDUC1_WIFE_ (1/3=1)(4/5=2)(6=3)(7/8=4)(9=.)(0=.), gen(educ_wife_early)
recode EDUC1_HEAD_ (0/3=1)(4/5=2)(6=3)(7/8=4)(9=.), gen(educ_head_early)
recode EDUC_WIFE_ (1/11=1) (12=2) (13/15=3) (16/17=4) (99=.)(0=.), gen(educ_wife_1975)
recode EDUC_HEAD_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_head_1975)
recode YRS_EDUCATION_INDV (1/11=1) (12=2) (13/15=3) (16/17=4) (98/99=.)(0=.), gen(educ_completed) // okay this is hard to use because head / wife ONLY recorded against those specific ones so they don't always have values here

label define educ 1 "LTHS" 2 "HS" 3 "Some College" 4 "College"
label values educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 educ_completed educ

browse unique_id survey_yr in_sample relationship YRS_EDUCATION_INDV educ_completed educ_head_early educ_head_1975 hs_head HS_GRAD_HEAD attended_college_head completed_college_head college_degree_head BACHELOR_YR_HEAD_ YR_EDUC_UPD_HEAD_ NEW_HEAD_ NEW_HEAD_YEAR if relationship==1 // using head right now to wrap my head around

* create final education variables
gen educ_head_est=.
replace educ_head_est=1 if hs_head==0
replace educ_head_est=2 if hs_head==1 & attended_college_head==0
replace educ_head_est=3 if hs_head==1 & attended_college_head==1 & completed_college_head==0
replace educ_head_est=3 if completed_college_head==1 & college_degree_head==1
replace educ_head_est=4 if completed_college_head==1 & college_degree_head==2

gen educ_head=.
replace educ_head=educ_head_early if inrange(survey_yr,1968,1990)
replace educ_head=educ_head_1975 if inrange(survey_yr,1991,2021)

tab educ_head educ_head_est, m
tab educ_completed educ_head_est if relationship==1, m
tab educ_head educ_completed if educ_head_est==., m
replace educ_head_est = educ_completed if educ_head_est==. & educ_completed!=.
replace educ_head_est = educ_head if educ_head_est==. & educ_head!=.

browse unique_id survey_yr educ_head educ_completed educ_head_est YRS_EDUCATION_INDV  hs_head attended_college_head completed_college_head college_degree_head if relationship==1 

gen educ_wife_est=.
replace educ_wife_est=1 if hs_wife==0
replace educ_wife_est=2 if hs_wife==1 & attended_college_wife==0
replace educ_wife_est=3 if hs_wife==1 & attended_college_wife==1 & completed_college_wife==0
replace educ_wife_est=3 if completed_college_wife==1 & college_degree_wife==1
replace educ_wife_est=4 if completed_college_wife==1 & college_degree_wife==2

gen educ_wife=.
replace educ_wife=educ_wife_early if inrange(survey_yr,1968,1990)
replace educ_wife=educ_wife_1975 if inrange(survey_yr,1991,2021)
tab survey_yr educ_wife, m 

replace educ_wife_est = educ_completed if educ_wife_est==. & educ_completed!=.
replace educ_wife_est = educ_wife if educ_wife_est==. & educ_wife!=.

tab educ_wife educ_wife_est, m
tab educ_completed educ_wife_est if relationship==2, m
tab educ_wife educ_completed if educ_wife_est==., m

label values educ_head educ_wife educ_head_est educ_wife_est educ

gen college_wife=.
replace college_wife=0 if inrange(educ_wife_est,1,3)
replace college_wife=1 if educ_wife_est==4

gen college_head=.
replace college_head=0 if inrange(educ_head_est,1,3)
replace college_head=1 if educ_head_est==4
tab college_degree_head college_head, m

gen college_indv=.
replace college_indv=0 if inrange(educ_completed,1,3)
replace college_indv=1 if educ_completed==4

// number of children
gen children=.
replace children=0 if NUM_CHILDREN_==0
replace children=1 if NUM_CHILDREN_>=1 & NUM_CHILDREN_!=.

// race
browse unique_id survey_yr RACE_1_WIFE_ RACE_2_WIFE_ RACE_3_WIFE_ RACE_1_HEAD_ RACE_2_HEAD_ RACE_3_HEAD_ RACE_4_HEAD_
// wait race of wife not asked until 1985?! that's wild. also need to see if codes changed in between. try to fill in historical for wife if in survey in 1985 and prior.
/*
1968-1984: 1=White; 2=Negro; 3=PR or Mexican; 7=Other
1985-1989: 1=White; 2=Black; 3=Am Indian 4=Asian 7=Other; 8 =more than 2
1990-2003: 1=White; 2=Black; 3=Am India; 4=Asian; 5=Latino; 6=Other; 7=Other
2005-2019: 1=White; 2=Black; 3=Am India; 4=Asian; 5=Native Hawaiian/Pac Is; 7=Other
*/

gen race_1_head_rec=.
replace race_1_head_rec=1 if RACE_1_HEAD_==1
replace race_1_head_rec=2 if RACE_1_HEAD_==2
replace race_1_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_1_HEAD_==3)
replace race_1_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_1_HEAD_==4)
replace race_1_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_1_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_1_HEAD_==5)
replace race_1_head_rec=6 if RACE_1_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_1_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_1_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_1_HEAD_==8)

gen race_2_head_rec=.
replace race_2_head_rec=1 if RACE_2_HEAD_==1
replace race_2_head_rec=2 if RACE_2_HEAD_==2
replace race_2_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_2_HEAD_==3)
replace race_2_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_2_HEAD_==4)
replace race_2_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_2_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_2_HEAD_==5)
replace race_2_head_rec=6 if RACE_2_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_2_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_2_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_2_HEAD_==8)

gen race_3_head_rec=.
replace race_3_head_rec=1 if RACE_3_HEAD_==1
replace race_3_head_rec=2 if RACE_3_HEAD_==2
replace race_3_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_3_HEAD_==3)
replace race_3_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_3_HEAD_==4)
replace race_3_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_3_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_3_HEAD_==5)
replace race_3_head_rec=6 if RACE_3_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_3_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_3_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_3_HEAD_==8)

gen race_4_head_rec=.
replace race_4_head_rec=1 if RACE_4_HEAD_==1
replace race_4_head_rec=2 if RACE_4_HEAD_==2
replace race_4_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_4_HEAD_==3)
replace race_4_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_4_HEAD_==4)
replace race_4_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_4_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_4_HEAD_==5)
replace race_4_head_rec=6 if RACE_4_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_4_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_4_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_4_HEAD_==8)

gen race_1_wife_rec=.
replace race_1_wife_rec=1 if RACE_1_WIFE_==1
replace race_1_wife_rec=2 if RACE_1_WIFE_==2
replace race_1_wife_rec=3 if (inrange(survey_yr,1985,2019) & RACE_1_WIFE_==3)
replace race_1_wife_rec=4 if (inrange(survey_yr,1985,2019) & RACE_1_WIFE_==4)
replace race_1_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_1_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_1_WIFE_==5)
replace race_1_wife_rec=6 if RACE_1_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_1_WIFE_==6) | (inrange(survey_yr,2005,2019) & RACE_1_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_1_WIFE_==8)

gen race_2_wife_rec=.
replace race_2_wife_rec=1 if RACE_2_WIFE_==1
replace race_2_wife_rec=2 if RACE_2_WIFE_==2
replace race_2_wife_rec=3 if (inrange(survey_yr,1985,2019) & RACE_2_WIFE_==3)
replace race_2_wife_rec=4 if (inrange(survey_yr,1985,2019) & RACE_2_WIFE_==4)
replace race_2_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_2_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_2_WIFE_==5)
replace race_2_wife_rec=6 if RACE_2_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_2_WIFE_==6) | (inrange(survey_yr,2005,2019) & RACE_2_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_2_WIFE_==8)

gen race_3_wife_rec=.
replace race_3_wife_rec=1 if RACE_3_WIFE_==1
replace race_3_wife_rec=2 if RACE_3_WIFE_==2
replace race_3_wife_rec=3 if (inrange(survey_yr,1985,2019) & RACE_3_WIFE_==3)
replace race_3_wife_rec=4 if (inrange(survey_yr,1985,2019) & RACE_3_WIFE_==4)
replace race_3_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_3_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_3_WIFE_==5)
replace race_3_wife_rec=6 if RACE_3_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_3_WIFE_==6) | (inrange(survey_yr,2005,2019) & RACE_3_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_3_WIFE_==8)

gen race_4_wife_rec=.
replace race_4_wife_rec=1 if RACE_4_WIFE_==1
replace race_4_wife_rec=2 if RACE_4_WIFE_==2
replace race_4_wife_rec=3 if (inrange(survey_yr,1985,2021) & RACE_4_WIFE_==3)
replace race_4_wife_rec=4 if (inrange(survey_yr,1985,2021) & RACE_4_WIFE_==4)
replace race_4_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_4_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_4_WIFE_==5)
replace race_4_wife_rec=6 if RACE_4_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_4_WIFE_==6) | (inrange(survey_yr,2005,2021) & RACE_4_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_4_WIFE_==8)

browse unique_id race_1_head_rec race_2_head_rec race_3_head_rec race_4_head_rec

// based on first mention (that is one option they use in SHELF)
gen race_wife=race_1_wife_rec
replace race_wife=7 if race_2_wife_rec!=.

gen race_head=race_1_head_rec
replace race_head=7 if race_2_head_rec!=.

label define race 1 "White" 2 "Black" 3 "Indian" 4 "Asian" 5 "Latino" 6 "Other" 7 "Multi-racial"
label values race_wife race_head race

// ethnicity
gen hispanic_head=.
replace hispanic_head=0 if HISPANICITY_HEAD_==0
replace hispanic_head=1 if inrange(HISPANICITY_HEAD_,1,7)

gen hispanic_wife=.
replace hispanic_wife=0 if HISPANICITY_WIFE_==0
replace hispanic_wife=1 if inrange(HISPANICITY_WIFE_,1,7)

tab race_head hispanic_head, m

// combined
gen raceth_head=.
replace raceth_head=1 if race_head==1 & (hispanic_head==0 | hispanic_head==.)
replace raceth_head=2 if race_head==2
replace raceth_head=3 if hispanic_head==1 & race_head!=2 // hispanic, non-black
replace raceth_head=3 if race_head==5 & (hispanic_head==0 | hispanic_head==.)
replace raceth_head=4 if race_head==4 & (hispanic_head==0 | hispanic_head==.)
replace raceth_head=5 if inlist(race_head,3,6,7) & (hispanic_head==0 | hispanic_head==.)

tab raceth_head, m
tab race_head raceth_head, m

gen raceth_wife=.
replace raceth_wife=1 if race_wife==1 & (hispanic_wife==0 | hispanic_wife==.)
replace raceth_wife=2 if race_wife==2
replace raceth_wife=3 if hispanic_wife==1 & race_wife!=2 // hispanic, non-black
replace raceth_wife=3 if race_wife==5 & (hispanic_wife==0 | hispanic_wife==.)
replace raceth_wife=4 if race_wife==4 & (hispanic_wife==0 | hispanic_wife==.)
replace raceth_wife=5 if inlist(race_wife,3,6,7) & (hispanic_wife==0 | hispanic_wife==.)

label define raceth 1 "NH White" 2 "Black" 3 "Hispanic" 4 "NH Asian" 5 "NH Other"
labe values raceth_head raceth_wife raceth

// figure out how to make time invariant, re: SHELF
tab raceth_head in_sample, m
tab raceth_wife in_sample, m
browse unique_id survey_yr raceth_head raceth_wife

// bysort unique_id: egen raceth_head_fixed = median(raceth_head)
bysort unique_id: egen raceth_head_fixed = mode(raceth_head) // majority
tab raceth_head_fixed, m
gen last_race_head=raceth_head if survey_yr==last_survey_yr // tie break with last reported
bysort unique_id (last_race_head): replace last_race_head = last_race_head[1]
sort unique_id survey_yr
browse unique_id survey_yr last_survey_yr raceth_head raceth_head_fixed last_race_head
// replace raceth_head_fixed=last_race_head if inlist(raceth_head_fixed,1.5,2.5,3.5,4.5)
replace raceth_head_fixed=last_race_head if raceth_head_fixed==.
tab raceth_head if raceth_head_fixed==., m

bysort unique_id: egen raceth_wife_fixed = mode(raceth_wife) // majority
tab raceth_wife_fixed, m
gen last_race_wife=raceth_wife if survey_yr==last_survey_yr // tie break with last reported
bysort unique_id (last_race_wife): replace last_race_wife = last_race_wife[1]
sort unique_id survey_yr
browse unique_id survey_yr last_survey_yr raceth_wife raceth_wife_fixed last_race_wife
// replace raceth_wife_fixed=last_race_wife if inlist(raceth_wife_fixed,1.5,2.5,3.5,4.5)
replace raceth_wife_fixed=last_race_wife if raceth_wife_fixed==.

// realizing - I shouldn't do this this way becauase the head / wife can change over time (one reason that head / wife might seemingly change over time rather than data errors for the same person)
// so - first need to assign race/eth to FOCAL person, then do this. Revisit once I get to that step below

// religion
tabstat RELIGION_WIFE_ RELIGION_HEAD_, by(survey_yr) // just to get a sense of when asked to start.
label values RELIGION_WIFE_ RELIGION_HEAD_ . // these values are v wrong
/* head was 1970-1977, 1979-2021. wife was 1976, 1985-2021
Okay, but some weird things with how asked: 
In 1979, when this question was reinstated in the questionnaire, values were not brought forward for families with unchanged Heads since 1977.
For those cases with the same Heads from 1977 through the present, please use 1977 religious preference, V5617
So, most missings after 1977 can be interpreted as no new head, so use 1977 value? Is this another that might help if I edit once I have the variables assigned to the focal person?
Okay, but I *think* starting in 1985, was asked to everyone again? Because number of 0s goes down and the note is gone. okay, carried forward again starting 1986.
So carry through 1977-1984 if in sample and same head / partner?

The codes changed wildly over the years?
1970-1984 - 0: No or Other, 1: Baptist, 2: Methodist, 3: Episcopalian, 4: Presbyterian, 5: Lutheran, 6: Unitarian, Mormon, and related, 7: Other Protestant, 8: Catholic, 9: Jewish
1985-1987 - 0: None, 1: Roman Catholic, 2: Jewish, 3: Baptist, 4: Lutheran, 5: Methodist, 6: Presbyterian, 7: Episcopalian, 8: Protestant unspecified, 9: Other Protestant, 10: Other non-Christian, 11: LDS, 12: Jehvah's Witnesses
13: Greek Orthodox, 14: "Christian", 15: Unitarian, 16: Christian Science, 17: 7th day Adventist, 18: Pentecostal, 19: Amish, 20: Quaker, 99: NA/DK
-- in 1987, the label specifically says None, atheist, agnostic
1988-1993 - 0: None, atheist, agnostic, 1: Roman Catholic, 2: Jewish, 3: Baptist, 4: Lutheran, 5: Methodist, 6: Presbyterian, 7: Episcopalian, 8: Protestant unspecified, 9: Other Protestant, 10: Other non-Christian, 11: LDS, 12: Jehvah's Witnesses
13: Greek Orthodox, 14: "Christian", 15: Unitarian, 16: Christian Science, 17: 7th day Adventist, 18: Pentecostal, 19: Amish, 20: Quaker, 21: Church of God, 22: United Church of Christ, 23: Reformed, 24: Disciples of Christ, 25: CHurches of Christ, 97: Other, 99: NA/DK
-- so, up to 20 is the same as above, just added 21-25.
1994-2017 - 0: None, 1: Catholic, 2: Jewish, 8: Protestant unspecified, 10: Other non-Christian, 13: Greek Orthodox, 97: Other, 98: DK, 99: NA // so these large categories do match above in terms of coding (like 8 is the same, 13, etc. just way less groups)
-- In 1994, DENOMINATION was added as a separate question, so all of the detail goes to a separate question (which I don't believe I pulled in at the moment). so, I guess decide if that is worth adding.
2019-2021 - 0: Inapp (no partner), 1: None, 2: Atheist, 3: Agnostic, 4: Roman Catholic, 5: Greek Orthodox, 6: Baptist, 7: Episcopalian, 8: Jehovah's Witness, 9: Lutheran, 10: Methodist, 11: Pentecostal, 12: Presbyterian, 13: Protestant unspecified, 14: Christian, unspecified, 15: Christian, non-denominational, 16: Jewish, 17: Muslim, 18: Buddhist, 19: Other non-christian, 20: Other protestant, 21: LDS, 22: Unitarian, 23: Christian Science, 24: Adventist, 25: Amish, 26: Quaker, 27: Church of God, 28: United Church of Christ, 29: Reformed, 30: Disciples of Christ, 31: Churches of Christ, 97: Other, 98: DK, 99: NA
-- lol so DENOMINATION ends in 2017 and is integrated BACK to this question lord and the codes change AGAIN.

Denomination
1994-2017 - 0: None, atheist, agnostic, not Protestant OR no spouse (this is a lot in one), 3: Baptist, 4: Lutheran, 5: Methodist, 6: Presbyterian, 7: Episcopalian, 8: Protestant unspecified, 9: Other Protestant, 11: LDS, 12: Jehovah's witness, 14: Christian, 15: Unitarian, 16: Christian Science, 17: Adventist, 18: Pentecostal, 19: Amish, 20: Quaker, 21: Church of God, 22: United Church of Christ, 23: Reformed, 24: Disciples of Christ, 25: CHurches of Christ, 97: Other, 98: DK, 99: NA
-- so, I think aligns with how asked 1985-1993. I think if I combine the two I actually get all the same codes 0-25 (that's why some are missing)

This might be helpful: https://www.pewresearch.org/religion/2015/05/12/appendix-b-classification-of-protestant-denominations/
https://en.wikipedia.org/wiki/Protestantism_in_the_United_States#Mainline_Protestantism
https://www.thegospelcoalition.org/blogs/trevin-wax/quick-guide-christian-denominations/ - the big three are Eastern Orthodox; Catholic; Protestant
https://truthandgracecounseling.com/understanding-the-difference-between-evangelical-and-mainline-protestant-churches/
https://woollyscreamsmiracle.wordpress.com/evangelical-vs-mainline-protestant-denominations-an-overview/
-- ideally could have evangelical Protestantism, mainline Protestantism and historically black Protestantism
-- okay no because these denominations spain mainline and evangelical in their classification
*/
tab DENOMINATION_HEAD_ RELIGION_HEAD_ if inrange(survey_yr,1994,2017), m col // want to clarify how these map on so I can decide what catgories to use. so all of these are protestant denominations??

browse unique_id survey_yr RELIGION_HEAD_ DENOMINATION_HEAD_ RELIGION_WIFE_ DENOMINATION_WIFE_

gen religion_head=.
replace religion_head=0 if inrange(survey_yr,1970,1984) & RELIGION_HEAD_==0 // no religion
replace religion_head=0 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==0
replace religion_head=0 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==0
replace religion_head=0 if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,1,2,3)
replace religion_head=1 if inrange(survey_yr,1970,1984) & RELIGION_HEAD_==8 // catholic
replace religion_head=1 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==1
replace religion_head=1 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==1
replace religion_head=1 if inrange(survey_yr,2019,2021) & RELIGION_HEAD_==4
replace religion_head=2 if inrange(survey_yr,1970,1984) & RELIGION_HEAD_==9 // jewish
replace religion_head=2 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==2
replace religion_head=2 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==2
replace religion_head=2 if inrange(survey_yr,2019,2021) & RELIGION_HEAD_==16
replace religion_head=3 if inrange(survey_yr,1970,1984) & RELIGION_HEAD_==1 // baptist
replace religion_head=3 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==3
replace religion_head=3 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==8 & DENOMINATION_HEAD_==3
replace religion_head=3 if inrange(survey_yr,2019,2021) & RELIGION_HEAD_==6
replace religion_head=4 if inrange(survey_yr,1970,1984) & inlist(RELIGION_HEAD_,2,3,4,5) // mainline protestant
replace religion_head=4 if inrange(survey_yr,1985,1993) & inlist(RELIGION_HEAD_,4,5,6,7,22,23,24)
replace religion_head=4 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==8 & inlist(DENOMINATION_HEAD_,4,5,6,7,22,23,24)
replace religion_head=4 if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,7,9,10,12,28,29,30)
// replace religion_head=5 if inrange(survey_yr,1970,1984) & inlist(RELIGION_HEAD_,) // evangelical protestant - none in first waves
replace religion_head=5 if inrange(survey_yr,1985,1993) & inlist(RELIGION_HEAD_,17,18,21,25)
replace religion_head=5 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==8 & inlist(DENOMINATION_HEAD_,17,18,21,25)
replace religion_head=5 if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,11,24,27,31)
replace religion_head=6 if inrange(survey_yr,1970,1984) & RELIGION_HEAD_==7 // other protestant
replace religion_head=6 if inrange(survey_yr,1985,1993) & inlist(RELIGION_HEAD_,8,9,19,20)
replace religion_head=6 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==8 & inlist(DENOMINATION_HEAD_,8,9,19,20,97,98,99)
replace religion_head=6 if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,13,20,25,26)
// replace religion_head=7 if inrange(survey_yr,1970,1984) & inlist(RELIGION_HEAD_,) // eastern orthodox
replace religion_head=7 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==13
replace religion_head=7 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==13
replace religion_head=7 if inrange(survey_yr,2019,2021) & RELIGION_HEAD_==5
replace religion_head=8 if inrange(survey_yr,1970,1984) & RELIGION_HEAD_==6 // other christian
replace religion_head=8 if inrange(survey_yr,1985,1993) & inlist(RELIGION_HEAD_,11,12,14,15,16)
replace religion_head=8 if inrange(survey_yr,1994,2017) & inlist(DENOMINATION_HEAD_,11,12,14,15,16)
replace religion_head=8 if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,8,14,15,21,22,23)
// replace religion_head=9 if inrange(survey_yr,1970,1984) & inlist(RELIGION_HEAD_,) // other non-christian
replace religion_head=9 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==10
replace religion_head=9 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==10
replace religion_head=9 if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,17,18,19)
// replace religion_head=10 if inrange(survey_yr,1970,1984) & inlist(RELIGION_HEAD_,) // other other
replace religion_head=10 if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==97
replace religion_head=10 if inrange(survey_yr,1994,2017) & RELIGION_HEAD_==97
replace religion_head=10 if inrange(survey_yr,2019,2021) & RELIGION_HEAD_==97
// replace religion_head=. if inrange(survey_yr,1970,1984) & inlist(RELIGION_HEAD_,) // missing
replace religion_head=. if inrange(survey_yr,1985,1993) & RELIGION_HEAD_==99
replace religion_head=. if inrange(survey_yr,1994,2017) & inlist(RELIGION_HEAD_,98,99)
replace religion_head=. if inrange(survey_yr,2019,2021) & inlist(RELIGION_HEAD_,98,99)

gen religion_wife=.
replace religion_wife=0 if inrange(survey_yr,1970,1984) & RELIGION_WIFE_==0 // no religion
replace religion_wife=0 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==0
replace religion_wife=0 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==0
replace religion_wife=0 if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,1,2,3)
replace religion_wife=1 if inrange(survey_yr,1970,1984) & RELIGION_WIFE_==8 // catholic
replace religion_wife=1 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==1
replace religion_wife=1 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==1
replace religion_wife=1 if inrange(survey_yr,2019,2021) & RELIGION_WIFE_==4
replace religion_wife=2 if inrange(survey_yr,1970,1984) & RELIGION_WIFE_==9 // jewish
replace religion_wife=2 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==2
replace religion_wife=2 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==2
replace religion_wife=2 if inrange(survey_yr,2019,2021) & RELIGION_WIFE_==16
replace religion_wife=3 if inrange(survey_yr,1970,1984) & RELIGION_WIFE_==1 // baptist
replace religion_wife=3 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==3
replace religion_wife=3 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==8 & DENOMINATION_WIFE_==3
replace religion_wife=3 if inrange(survey_yr,2019,2021) & RELIGION_WIFE_==6
replace religion_wife=4 if inrange(survey_yr,1970,1984) & inlist(RELIGION_WIFE_,2,3,4,5) // mainline protestant
replace religion_wife=4 if inrange(survey_yr,1985,1993) & inlist(RELIGION_WIFE_,4,5,6,7,22,23,24)
replace religion_wife=4 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==8 & inlist(DENOMINATION_WIFE_,4,5,6,7,22,23,24)
replace religion_wife=4 if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,7,9,10,12,28,29,30)
// replace religion_wife=5 if inrange(survey_yr,1970,1984) & inlist(RELIGION_WIFE_,) // evangelical protestant - none in first waves
replace religion_wife=5 if inrange(survey_yr,1985,1993) & inlist(RELIGION_WIFE_,17,18,21,25)
replace religion_wife=5 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==8 & inlist(DENOMINATION_WIFE_,17,18,21,25)
replace religion_wife=5 if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,11,24,27,31)
replace religion_wife=6 if inrange(survey_yr,1970,1984) & RELIGION_WIFE_==7 // other protestant
replace religion_wife=6 if inrange(survey_yr,1985,1993) & inlist(RELIGION_WIFE_,8,9,19,20)
replace religion_wife=6 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==8 & inlist(DENOMINATION_WIFE_,8,9,19,20,97,98,99)
replace religion_wife=6 if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,13,20,25,26)
// replace religion_wife=7 if inrange(survey_yr,1970,1984) & inlist(RELIGION_WIFE_,) // eastern orthodox
replace religion_wife=7 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==13
replace religion_wife=7 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==13
replace religion_wife=7 if inrange(survey_yr,2019,2021) & RELIGION_WIFE_==5
replace religion_wife=8 if inrange(survey_yr,1970,1984) & RELIGION_WIFE_==6 // other christian
replace religion_wife=8 if inrange(survey_yr,1985,1993) & inlist(RELIGION_WIFE_,11,12,14,15,16)
replace religion_wife=8 if inrange(survey_yr,1994,2017) & inlist(DENOMINATION_WIFE_,11,12,14,15,16)
replace religion_wife=8 if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,8,14,15,21,22,23)
// replace religion_wife=9 if inrange(survey_yr,1970,1984) & inlist(RELIGION_WIFE_,) // other non-christian
replace religion_wife=9 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==10
replace religion_wife=9 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==10
replace religion_wife=9 if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,17,18,19)
// replace religion_wife=10 if inrange(survey_yr,1970,1984) & inlist(RELIGION_WIFE_,) // other other
replace religion_wife=10 if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==97
replace religion_wife=10 if inrange(survey_yr,1994,2017) & RELIGION_WIFE_==97
replace religion_wife=10 if inrange(survey_yr,2019,2021) & RELIGION_WIFE_==97
// replace religion_wife=. if inrange(survey_yr,1970,1984) & inlist(RELIGION_WIFE_,) // missing
replace religion_wife=. if inrange(survey_yr,1985,1993) & RELIGION_WIFE_==99
replace religion_wife=. if inrange(survey_yr,1994,2017) & inlist(RELIGION_WIFE_,98,99)
replace religion_wife=. if inrange(survey_yr,2019,2021) & inlist(RELIGION_WIFE_,98,99)

label define religion 0 "No religion" 1 "Catholic" 2 "Jewish" 3 "Baptist" 4 "Mainline Protestant" 5 "Evangelical Protestant" 6 "Other Protestant" 7 "Eastern Orthodox" 8 "Other Christian" 9 "Other Non-Christian" 10 "Other Other"
label values religion_head religion_wife religion
tab religion_head, m
tab RELIGION_HEAD_ religion_head, m

tab religion_wife, m
tab RELIGION_WIFE_ religion_wife, m

// like with race/ethnicity, while this CAN change within people over time, there are going to be a lot of missing I think in the 70s/80s bc of who / when they asked so neeed to pull forward.
// SO, when I have this assigned to the focal person, THEN figure out if I can fill in that info and reduce the amount of missings.

save "$created_data_psid\PSID_individ_recodes.dta", replace

********************************************************************************
**# Now assign variables to FOCAL person rather than just head / wife / individ
********************************************************************************
/* variables that need focal version:
earnings_t1_wife earnings_t1_head weekly_hrs_t1_wife weekly_hrs_t1_head weekly_hrs_t1_indv employed_head employed_wife employed_indv
employed_t1_head employed_t1_wife employed_t1_indv housework_head housework_wife
educ_completed educ_head_est educ_wife_est college_wife college_head college_indv raceth_head raceth_wife religion_head religion_wife
// think need to recreate these: raceth_head_fixed last_race_head raceth_wife_fixed last_race_wife
// not sure I need these / can create with weekly hours: ft_pt_t1_head ft_pt_t1_wife ft_t1_head ft_t1_wife 
*/

use "$created_data_psid\PSID_individ_recodes.dta", clear

* Let's start with t-1 variables
// weekly hours
browse unique_id survey_yr relationship  weekly_hrs_t1_head weekly_hrs_t1_wife weekly_hrs_t1_indv
gen weekly_hrs_t1_focal=.
replace weekly_hrs_t1_focal=weekly_hrs_t1_head if relationship==1
replace weekly_hrs_t1_focal=weekly_hrs_t1_wife if relationship==2
replace weekly_hrs_t1_focal=weekly_hrs_t1_indv if relationship==3

// annual earnings
browse unique_id survey_yr relationship earnings_t1_head earnings_t1_wife LABOR_INCOME_T1_INDV
gen earnings_t1_focal=.
replace earnings_t1_focal=earnings_t1_head if relationship==1
replace earnings_t1_focal=earnings_t1_wife if relationship==2
replace earnings_t1_focal=LABOR_INCOME_T1_INDV if relationship==3

// previously created t1 employment - this was based on earnings
gen employed_t1_earn_focal=.
replace employed_t1_earn_focal=employed_t1_head if relationship==1
replace employed_t1_earn_focal=employed_t1_wife if relationship==2
replace employed_t1_earn_focal=employed_t1_indv if relationship==3

// births - based on PSID variables NOT birth history. can add that later
gen any_psid_births_t1_focal=.
replace any_psid_births_t1_focal = 0 if relationship==1 & BIRTHS_T1_HEAD_==0 & BIRTHS_T1_BOTH_==0
replace any_psid_births_t1_focal = 1 if relationship==1 & (inrange(BIRTHS_T1_HEAD_,1,3) |  inrange(BIRTHS_T1_BOTH_,1,3))
replace any_psid_births_t1_focal = 0 if relationship==2 & BIRTHS_T1_WIFE_==0 & BIRTHS_T1_BOTH_==0
replace any_psid_births_t1_focal = 1 if relationship==2 & (inrange(BIRTHS_T1_WIFE_,1,3) | inrange(BIRTHS_T1_BOTH_,1,3))

gen any_psid_births_t1_hh=. // because, even if not head/  wife - if head / wife HAD a birth, that is technically a new kid in HH, even if that person didn't have the kid
replace any_psid_births_t1_hh = 0 if BIRTHS_T1_HEAD_==0 & BIRTHS_T1_WIFE_ & BIRTHS_T1_BOTH_==0
replace any_psid_births_t1_hh = 1 if inrange(BIRTHS_T1_WIFE_,1,3) | inrange(BIRTHS_T1_BOTH_,1,3) | inrange(BIRTHS_T1_WIFE_,1,3)

* t variables
// weekly HW hours
browse unique_id survey_yr relationship housework_head housework_wife HOUSEWORK_INDV_
gen housework_focal=.
replace housework_focal=housework_head if relationship==1
replace housework_focal=housework_wife if relationship==2
replace housework_focal=HOUSEWORK_INDV_ if relationship==3
// replace housework_focal=. if relationship==3

// weekly childcare
gen childcare_focal=.
replace childcare_focal=CHILDCARE_HEAD if relationship==1
replace childcare_focal=CHILDCARE_WIFE if relationship==2

// weekly adultcare
gen adultcare_focal=.
replace adultcare_focal=ADULTCARE_HEAD if relationship==1
replace adultcare_focal=ADULTCARE_WIFE if relationship==2

// Current employment status
browse unique_id survey_yr relationship employed_head employed_wife employed_indv
gen employed_focal=.
replace employed_focal=employed_head if relationship==1
replace employed_focal=employed_wife if relationship==2
replace employed_focal=employed_indv if relationship==3

// Education
tab educ_head_est educ_completed if relationship==1
tab educ_wife_est educ_completed if relationship==2

gen educ_focal=.
replace educ_focal = educ_completed if educ_completed!=. // let's prioritize indiivdual levels of education because that is asked annually even when head / ref is not, and sometimes updated for head / ref
replace educ_focal=educ_head_est if relationship==1 & educ_completed==. // then fill in otherwise here
replace educ_focal=educ_wife_est if relationship==2 & educ_completed==.
replace educ_focal=educ_completed if relationship==3

bysort unique_id: egen max_educ_focal = max(educ_focal)
label values educ_focal max_educ_focal educ

browse unique_id survey_yr relationship educ_focal max_educ_focal educ_completed educ_head_est educ_wife_est NEW_HEAD_YEAR NEW_WIFE_YEAR YR_EDUC_UPD_HEAD_ YR_EDUC_UPD_WIFE_  // YRS_EDUCATION_INDV_ edulevel_match edulevelmax_match YRS_EDUCATION_INDV_ completed_college_indv educ_head max_educ_head educ_wife max_educ_wife completed_college_head completed_college_wife 

gen college_focal=.
replace college_focal = 0 if inrange(educ_focal,1,3)
replace college_focal = 1 if educ_focal==4

// Age
gen age_focal = AGE_INDV
replace age_focal = survey_yr - birth_yr if age_focal==. & birth_yr!=9999
browse unique_id survey_yr relationship birth_yr age_focal AGE_*

// race - revisit this. possibly use the non-fixed head / wife version THEN update (because the head / wife could change? so will be more accurate to do later? so follow same process once allocated to focal)
gen raceth_focal=.
replace raceth_focal=raceth_head if relationship==1
replace raceth_focal=raceth_wife if relationship==2

bysort unique_id: egen raceth_fixed_focal = mode(raceth_focal) // majority
tab raceth_fixed_focal, m
gen last_race_focal=raceth_focal if survey_yr==last_survey_yr // tie break with last reported
bysort unique_id (last_race_focal): replace last_race_focal = last_race_focal[1]
sort unique_id survey_yr
browse unique_id survey_yr last_survey_yr relationship raceth_focal raceth_fixed_focal last_race_focal raceth_head_fixed raceth_wife_fixed
replace raceth_fixed_focal=last_race_focal if raceth_fixed_focal==.
label values raceth_focal raceth_fixed_focal raceth

tab raceth_focal if raceth_fixed_focal==., m
tab raceth_head if raceth_fixed_focal==. & relationship==1, m
tab raceth_fixed_focal relationship, m

// religion
gen religion_focal=.
replace religion_focal=religion_head if relationship==1
replace religion_focal=religion_wife if relationship==2
tab religion_focal, m

	// can I attempt to fill in the missings?
	quietly unique religion_focal if religion_focal!=., by(unique_id) gen(religion_change)
	bysort unique_id (religion_change): replace religion_change=religion_change[1]
	tab religion_change, m
	tab religion_focal religion_change, m // so 0 means all missing, 1 means stayed the same whole time, 2 means changed 1 (because this is unique count essentially not # of changes)
	sort unique_id survey_yr
	browse unique_id survey_yr last_survey_yr relationship religion_focal religion_change religion_head religion_wife
	
	bysort unique_id (religion_focal): replace religion_focal=religion_focal[1] if religion_change==1
	label values religion_focal religion
	
	// also, the 1977 notes - can carry that through until 1985 if same head / partner, when reasked
	gen religion_1977_focal = religion_head if survey_yr==1977 & relationship==1
	replace religion_1977_focal = religion_wife if survey_yr==1976 & relationship==2 // wife not asked in 1977, but rather, 1976, so use that value
	bysort unique_id (religion_1977_focal): replace religion_1977_focal=religion_1977_focal[1]
	label values religion_1977_focal religion
	
	sort unique_id survey_yr
	browse unique_id survey_yr last_survey_yr relationship religion_focal religion_1977_focal religion_change religion_head religion_wife
	
	replace religion_focal = religion_1977_focal if inrange(survey_yr,1977,1984) & inlist(religion_focal,0,.) & inlist(relationship,1,2) // because 0 OR missing are because same head / partner.
	
* t-2 variables
// weekly hours
gen weekly_hrs_t2_focal=.
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_INDV if inrange(survey_yr,1999,2001)
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_HEAD if relationship==1 & inrange(survey_yr,2003,2021)
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_WIFE if relationship==2 & inrange(survey_yr,2003,2021)
replace weekly_hrs_t2_focal=WEEKLY_HRS_T2_INDV if relationship==3 & inrange(survey_yr,2003,2021)
browse unique_id survey_yr relationship weekly_hrs_t2_focal WEEKLY_HRS_T2_HEAD WEEKLY_HRS_T2_WIFE WEEKLY_HRS_T2_INDV

// annual earnings
gen long earnings_t2_focal=.
replace earnings_t2_focal=LABOR_INCOME_T2_INDV_ if inrange(survey_yr,1999,2001)
replace earnings_t2_focal=LABOR_INCOME_T2_HEAD_ if relationship==1 & inrange(survey_yr,2003,2021)
replace earnings_t2_focal=LABOR_INCOME_T2_WIFE_ if relationship==2 & inrange(survey_yr,2003,2021)
replace earnings_t2_focal=LABOR_INCOME_T2_INDV_ if relationship==3 & inrange(survey_yr,2003,2021)
replace earnings_t2_focal=. if earnings_t2_focal==9999999 | earnings_t2_focal==99999999
browse unique_id survey_yr relationship earnings_t2_focal LABOR_INCOME_T2_HEAD_ LABOR_INCOME_T2_WIFE_ LABOR_INCOME_T2_INDV_

// employment status
gen employed_t2_indv=.
replace employed_t2_indv=0 if WEEKS_WORKED_T2_INDV_==0
replace employed_t2_indv=1 if inrange(WEEKS_WORKED_T2_INDV_,1,52)

gen employed_t2_head=.
replace employed_t2_head=0 if EMPLOY_STATUS_T2_HEAD==5
replace employed_t2_head=1 if EMPLOY_STATUS_T2_HEAD==1

gen employed_t2_wife=.
replace employed_t2_wife=0 if EMPLOY_STATUS_T2_WIFE==5
replace employed_t2_wife=1 if EMPLOY_STATUS_T2_WIFE==1

browse unique_id survey_yr relationship  employed_t2*

gen employed_t2_focal=.
replace employed_t2_focal = employed_t2_indv if inlist(survey_yr,1999,2001)
replace employed_t2_focal=employed_t2_head if relationship==1 & inrange(survey_yr,2003,2021)
replace employed_t2_focal=employed_t2_wife if relationship==2 & inrange(survey_yr,2003,2021)
replace employed_t2_focal=employed_t2_indv if relationship==3 & inrange(survey_yr,2003,2021)
replace employed_t2_focal=1 if inrange(survey_yr,1999,2001) & WEEKLY_HRS_T2_INDV>0 & WEEKLY_HRS_T2_INDV<900
replace employed_t2_focal=0 if inrange(survey_yr,1999,2001) & WEEKLY_HRS_T2_INDV==0

// trying to make an indicator of t-1 employment status
browse survey_yr earnings_t1_focal weekly_hrs_t1_focal earnings_t2_focal weekly_hrs_t2_focal employed_t2_focal

gen has_hours_t1=.
replace has_hours_t1=0 if weekly_hrs_t1_focal==0
replace has_hours_t1=1 if weekly_hrs_t1_focal>0 & weekly_hrs_t1_focal!=.

gen has_earnings_t1=.
replace has_earnings_t1=0 if earnings_t1_focal==0
replace has_earnings_t1=1 if earnings_t1_focal>0 & earnings_t1_focal!=.

tab has_hours_t1 has_earnings_t1, m // sometimes has hours but not earnings and vice versa, which is v. confusing. i guess hours is my primary interest, so use that

gen employed_t1_hrs_focal=.
replace employed_t1_hrs_focal=0 if weekly_hrs_t1_focal==0
replace employed_t1_hrs_focal=1 if weekly_hrs_t1_focal>0 & weekly_hrs_t1_focal!=.

tab employed_t1_hrs_focal employed_t1_earn_focal, m

gen has_hours_t2=.
replace has_hours_t2=0 if weekly_hrs_t2_focal==0
replace has_hours_t2=1 if weekly_hrs_t2_focal>0 & weekly_hrs_t2_focal!=.

gen has_earnings_t2=.
replace has_earnings_t2=0 if earnings_t2_focal==0
replace has_earnings_t2=1 if earnings_t2_focal>0 & earnings_t2_focal!=.

tab has_hours_t2 has_earnings_t2, m // t-2 has way more missing, but is a lot better
tab employed_t2_focal has_hours_t2, m
tab employed_t2_focal has_earnings_t2, m

// gen new_in_hh
gen new_in_hh=.
replace new_in_hh = NEW_HEAD_YEAR if relationship==1
replace new_in_hh = NEW_WIFE_YEAR if relationship==2
browse unique_id survey_yr relationship new_in_hh NEW_HEAD_YEAR NEW_WIFE_YEAR

// drop unneeded / intermediate variables to make file smaller / easier to reshape
drop employ_head employ1_head employ2_head employ3_head employ_wife employ1_wife employ2_wife employ3_wife total_housework_weekly ///
hs_head hs_wife attended_college_head attended_college_wife completed_college_head completed_college_wife completed_college_indv ///
college_degree_head college_degree_wife educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 race_1_head_rec ///
race_2_head_rec race_3_head_rec race_4_head_rec race_1_wife_rec race_2_wife_rec race_3_wife_rec race_4_wife_rec race_wife ///
race_head hispanic_head hispanic_wife MOTHER_MARITALSTATUSB1 RELEASE_NUM_ AGE_HEAD_ AGE_WIFE_ EMPLOY_STATUS1_HEAD_ ///
EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ WORK_MONEY_HEAD_ START_YR_EMPLOYER_HEAD_ WAGES_CURRENT_HEAD_ HRLY_RATE_CURRENT_HEAD_ ///
YRS_CURRENT_EMPLOY_HEAD_ LABOR_INC_J1_T1_HEAD_ LABOR_INC_J2_T1_HEAD_ LABOR_INC_J3_T1_HEAD_ LABOR_INC_J4_T1_HEAD_ CURRENTLY_WORK_HEAD_ ///
EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ WORK_MONEY_WIFE_ START_YR_EMPLOYER_WIFE_ WAGES_CURRENT_WIFE_ ///
HRLY_RATE_CURRENT_WIFE_ YRS_CURRENT_EMPLOY_WIFE_ LABOR_INC_J1_T1_WIFE_ LABOR_INC_J2_T1_WIFE_ LABOR_INC_J3_T1_WIFE_ ///
LABOR_INC_J4_T1_WIFE_ CURRENTLY_WORK_WIFE_ HOUSEWORK_HEAD_ CHILDCARE_HEAD_ ADULTCARE_HEAD_ HOUSEWORK_WIFE_ CHILDCARE_WIFE_ ///
ADULTCARE_WIFE_ WAGES_ALT_T1_HEAD_ DIVIDENDS_HEAD_ DIVIDENDS_JOINT_ INTEREST_JOINT_ WELFARE_HEAD_2_ WAGES_ALT_T1_WIFE_ ///
DIVIDENDS_WIFE_ WELFARE_WIFE_2_ HEALTH_INSURANCE_FAM_ FATHER_EDUC_WIFE_ MOTHER_EDUC_WIFE_ FAMILY_STRUCTURE_WIFE_ HISPANICITY_WIFE_ ///
RACE_1_WIFE_ RACE_2_WIFE_ RACE_3_WIFE_ RACE_4_WIFE_ ETHNIC_WIFE_ YR_EDUC_UPD_WIFE_ WHERE_EDUC_WIFE_ HS_GRAD_WIFE_ ///
ATTENDED_COLLEGE_WIFE_ COLLEGE_WIFE_ HIGHEST_DEGREE_WIFE_ BACHELOR_YR_WIFE_ FOREIGN_DEG_WIFE_ ENROLLED_WIFE_ RELIGION_WIFE_ ///
FATHER_EDUC_HEAD_ MOTHER_EDUC_HEAD_ FAMILY_STRUCTURE_HEAD_ HISPANICITY_HEAD_ RACE_1_HEAD_ RACE_2_HEAD_ RACE_3_HEAD_ RACE_4_HEAD_ ///
ETHNIC_HEAD_ YR_EDUC_UPD_HEAD_ WHERE_EDUC_HEAD_ HS_GRAD_HEAD_ ATTENDED_COLLEGE_HEAD_ COLLEGE_HEAD_ HIGHEST_DEGREE_HEAD_  ///
BACHELOR_YR_HEAD_ FOREIGN_DEG_HEAD_ ENROLLED_HEAD_ RELIGION_HEAD_ EMPLOY_STATUS_T2_HEAD_ WEEKLY_HRS_T2_HEAD_ LABOR_INCOME_T2_HEAD_ ///
EMPLOY_STATUS_T2_WIFE_ WEEKLY_HRS_T2_WIFE_ LABOR_INCOME_T2_WIFE_ WEEKLY_HRS_T1_HEAD_ ANNUAL_HOURS_T1_HEAD_ WEEKLY_HRS_T1_WIFE_ ///
ANNUAL_HOURS_T1_WIFE_ WAGES_T1_HEAD_ LABOR_INCOME_T1_HEAD_ WAGES2_T1_WIFE_ WAGES_T1_WIFE_ TAXABLE_T1_HEAD_WIFE_ WELFARE_HEAD_1_ ///
WELFARE_WIFE_1_ HRLY_RATE_T1_HEAD_ HRLY_RATE_T1_WIFE_ STOCKS_MF_ EDUC_HEAD_ EDUC_WIFE_ EMPLOYMENT_INDV_ COLLEGE_INDV_ ///
BACHELOR_YR_INDV_ STUDENT_CURRENT_INDV_ YRS_EDUCATION_INDV_ NUM_JOBS_T1_INDV_ LABOR_INCOME_T1_INDV_ TOTAL_INCOME_T1_INDV_ ///
ANNUAL_HOURS_T1_INDV_ EMPLOY_STATUS_HEAD_ WIDOW_LENGTH_HEAD_ LABOR_INCOME_T1_WIFE_ EDUC1_HEAD_ EDUC1_WIFE_ WEEKLY_HRS1_T1_WIFE_ ///
WEEKLY_HRS1_T1_HEAD_ TOTAL_HOUSEWORK_T1_HW_ MOST_HOUSEWORK_T1_ SALARY_TYPE_HEAD_ FIRST_MARRIAGE_YR_WIFE_ EMPLOY_STATUS_WIFE_ ///
SALARY_TYPE_WIFE_ RESEPONDENT_WIFE_ EVER_MARRIED_HEAD_ STUDENT_T1_INDV_ RELATION_TO_HEAD_ NUM_MARRIED_HEAD_ FIRST_MARRIAGE_YR_HEAD_ ///
FIRST_MARRIAGE_END_HEAD_ FIRST_WIDOW_YR_HEAD_ FIRST_DIVORCE_YR_HEAD_ FIRST_SEPARATED_YR_HEAD_ LAST_MARRIAGE_YR_HEAD_ ///
LAST_WIDOW_YR_HEAD_ LAST_DIVORCE_YR_HEAD_ LAST_SEPARATED_YR_HEAD_ NUM_MARRIED_WIFE_ FIRST_MARRIAGE_END_WIFE_ FIRST_WIDOW_YR_WIFE_ ///
FIRST_DIVORCE_YR_WIFE_ FIRST_SEPARATED_YR_WIFE_ LAST_MARRIAGE_YR_WIFE_ LAST_WIDOW_YR_WIFE_ LAST_DIVORCE_YR_WIFE_ LAST_SEPARATED_YR_WIFE_ ///
TOTAL_WEEKS_T1_HEAD_ ANNUAL_HOURS2_T1_HEAD_ TOTAL_WEEKS_T1_WIFE_ ANNUAL_HOURS2_T1_WIFE_ START_YR_CURRENT_HEAD_ START_YR_CURRENT_WIFE_ ///
START_YR_PREV_HEAD_ START_YR_PREV_WIFE_ WEEKLY_HRS_T2_INDV_ LABOR_INCOME_T2_INDV_ HOUSEWORK_INDV_ WEEKS_WORKED_T2_INDV_ DENOMINATION_HEAD_ ///
DENOMINATION_WIFE_ id BIRTH_YR_INDV_ AGE_INDV_ RELEASE_ RELEASE_NUM2_ WELFARE_JOINT_ wave religion_1977_focal

save "$created_data_psid\PSID_individ_recodes.dta", replace

********************************************************************************
**# now reshape back to wide to fill in the off years with t-2 data where possible
********************************************************************************
use "$created_data_psid\PSID_individ_recodes.dta", clear

drop earnings_t1_wife earnings_t1_head weekly_hrs_t1_wife weekly_hrs_t1_head  weekly_hrs_t1_indv employed_head employed_wife employed_indv ///
employed_t1_head employed_t1_wife employed_t1_indv ft_pt_t1_head ft_pt_t1_wife ft_t1_head ft_t1_wife housework_head housework_wife educ_completed ///
educ_head_est educ_head educ_wife_est educ_wife college_wife college_head college_indv raceth_head raceth_wife raceth_head_fixed last_race_head ///
raceth_wife_fixed last_race_wife religion_head religion_wife employed_t2_indv employed_t2_head employed_t2_wife 

reshape wide FAMILY_INTERVIEW_NUM_ STATE_ SPLITOFF_ COMPOSITION_CHANGE_ NUM_IN_HH_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ ///
NUM_NONFU_IN_HH_ X1968_PERSON_NUM_ HOUSE_STATUS_ HOUSE_VALUE_ ///
RENT_COST_V2_ CHILDCARE_COSTS_ FOOD_STAMPS_ VEHICLE_OWN_ NEW_WIFE_ NEW_HEAD_ RESPONDENT_WHO_ TRANSFER_INCOME_ ///
TOTAL_INCOME_T1_FAMILY_ VEHICLE_VALUE_ OTHER_ASSETS_ WEALTH_NO_EQUITY_ WEALTH_EQUITY_ TOTAL_HOUSING_ MORTGAGE_COST_ ///
POVERTY_THRESHOLD_ REGION_ METRO_ MARST_DEFACTO_HEAD_ COUPLE_STATUS_HEAD_ NEW_HEAD_YEAR_ NEW_WIFE_YEAR_ BIRTHS_T1_HEAD_ ///
BIRTHS_T1_WIFE_ BIRTHS_T1_BOTH_ SEQ_NUMBER_ RELATION_ MARITAL_PAIRS_ MOVED_ MOVED_MONTH_ MOVED_YEAR_ RESPONDENT_ ///
SPLITOFF_MONTH_ SPLITOFF_YEAR_ FAMILY_ID_SO_ INTERVIEW_NUM_ TYPE_OF_INCOME_ TOTAL_MONEY_INCOME_ FAMILY_COMPOSITION_ ///
RENT_COST_V1_ AGE_OLDEST_CHILD_ TYPE_TAXABLE_INCOME_ BANK_ASSETS_ TOTAL_INCOME_T2_FAMILY_ SEX_HEAD_ SEX_WIFE_ children ///
MARST_LEGAL_HEAD_ CDS_ELIGIBLE_ hh_status_ in_sample relationship partnered moved change_yr entrance_no leave_no ///
COR_IMM_WT_ LONG_WT_ CROSS_SECTION_WT_ CORE_WEIGHT_ CROSS_SECTION_FAM_WT_ FOLLOW_STATUS_ DATA_RECORD_TYPE_  ///
weekly_hrs_t1_focal earnings_t1_focal employed_t1_earn_focal any_psid_births_t1_focal any_psid_births_t1_hh ///
housework_focal childcare_focal adultcare_focal employed_focal educ_focal college_focal age_focal raceth_focal ///
religion_focal religion_change weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal has_hours_t1 has_earnings_t1 ///
employed_t1_hrs_focal has_hours_t2 has_earnings_t2 new_in_hh ///
, i(unique_id first_survey_yr last_survey_yr) j(survey_yr)

misstable summarize *focal*, all

// weekly hours
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

// family income
forvalues y=1998(2)2020{
	local z=`y'+1
	gen long TOTAL_INCOME_T1_FAMILY_`y'=TOTAL_INCOME_T2_FAMILY_`z'
}

browse TOTAL_INCOME_T1_FAMILY_1998 TOTAL_INCOME_T1_FAMILY_1999 TOTAL_INCOME_T2_FAMILY_1999

// employment status - here, I actually shouldn't need t-2, because I have t? so it needs to be t and t-1?
tab employed_focal2001 employed_t2_focal2003  // so these should match...but they really don't...
tab employed_focal1996 employed_t1_hrs_focal1997 // thsee should match -- also don't
tab employed_focal1996 employed_t1_earn_focal1997 // thsee should match -- also don't. also think it could be based on point in time? v. annual status

forvalues y=1998(2)2020{
	local z=`y'+1
	gen employed_focal`y'=employed_t1_hrs_focal`z'
}

// let's try to fill in education for the years where the surrounding years are the same
browse unique_id educ_focal*

forvalues y=1998(2)2020{
	local z=`y'+1
	local x=`y'-1
	gen educ_focal`y'=.
	replace educ_focal`y' = educ_focal`x' if educ_focal`x' == educ_focal`z'
	label values educ_focal`y' educ
}

// also need to realign the t-1 variables
forvalues y=1969/2021{
	local x=`y'-1
	gen long TOTAL_INCOME_T_FAMILY`x' = TOTAL_INCOME_T1_FAMILY_`y'
	gen weekly_hrs_t_focal`x' = weekly_hrs_t1_focal`y'
	gen earnings_t_focal`x' = earnings_t1_focal`y'
	capture gen any_psid_births_t_focal`x' = any_psid_births_t1_focal`y'
	capture gen any_psid_births_t_hh`x' = any_psid_births_t1_hh`y'
}

browse weekly_hrs_t_focal1996 weekly_hrs_t_focal1997 weekly_hrs_t1_focal1996 weekly_hrs_t1_focal1997 weekly_hrs_t1_focal1998

// before reshaping, get first observed educational
egen first_educ_focal=rowfirst(educ_focal*)
browse first_educ_focal educ_focal*
label values first_educ_focal educ

********************************************************************************
**# Back to long where i can then merge this to respondent info elsewhere or use as is
********************************************************************************

reshape long FAMILY_INTERVIEW_NUM_ STATE_ SPLITOFF_ COMPOSITION_CHANGE_ NUM_IN_HH_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ ///
NUM_NONFU_IN_HH_ X1968_PERSON_NUM_ HOUSE_STATUS_ HOUSE_VALUE_ ///
RENT_COST_V2_ CHILDCARE_COSTS_ FOOD_STAMPS_ VEHICLE_OWN_ NEW_WIFE_ NEW_HEAD_ RESPONDENT_WHO_ TRANSFER_INCOME_ ///
TOTAL_INCOME_T1_FAMILY_ VEHICLE_VALUE_ OTHER_ASSETS_ WEALTH_NO_EQUITY_ WEALTH_EQUITY_ TOTAL_HOUSING_ MORTGAGE_COST_ ///
POVERTY_THRESHOLD_ REGION_ METRO_ MARST_DEFACTO_HEAD_ COUPLE_STATUS_HEAD_ NEW_HEAD_YEAR_ NEW_WIFE_YEAR_ BIRTHS_T1_HEAD_ ///
BIRTHS_T1_WIFE_ BIRTHS_T1_BOTH_ SEQ_NUMBER_ RELATION_ MARITAL_PAIRS_ MOVED_ MOVED_MONTH_ MOVED_YEAR_ RESPONDENT_ ///
SPLITOFF_MONTH_ SPLITOFF_YEAR_ FAMILY_ID_SO_ INTERVIEW_NUM_ TYPE_OF_INCOME_ TOTAL_MONEY_INCOME_ FAMILY_COMPOSITION_ ///
RENT_COST_V1_ AGE_OLDEST_CHILD_ TYPE_TAXABLE_INCOME_ BANK_ASSETS_ TOTAL_INCOME_T2_FAMILY_ SEX_HEAD_ SEX_WIFE_ children ///
MARST_LEGAL_HEAD_ CDS_ELIGIBLE_ hh_status_ in_sample relationship partnered moved change_yr entrance_no leave_no ///
COR_IMM_WT_ LONG_WT_ CROSS_SECTION_WT_ CORE_WEIGHT_ CROSS_SECTION_FAM_WT_ FOLLOW_STATUS_ DATA_RECORD_TYPE_  ///
weekly_hrs_t1_focal earnings_t1_focal employed_t1_earn_focal any_psid_births_t1_focal any_psid_births_t1_hh ///
housework_focal childcare_focal adultcare_focal employed_focal educ_focal college_focal age_focal raceth_focal ///
religion_focal religion_change weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal has_hours_t1 has_earnings_t1 ///
employed_t1_hrs_focal has_hours_t2 has_earnings_t2 new_in_hh ///
weekly_hrs_t_focal TOTAL_INCOME_T_FAMILY earnings_t_focal any_psid_births_t_focal any_psid_births_t_hh ///
, i(unique_id first_survey_yr last_survey_yr) j(survey_yr)

browse unique_id survey_yr relationship in_sample weekly_hrs_t_focal weekly_hrs_t1_focal weekly_hrs_t2_focal housework_focal

// need to fill in the fixed variables for the missing rows - this might not be necessary since these were all fixed? Let's do just in case. oh yes, this was to make rectangular in other code, but I don't need to do that here
foreach var in SEX first_survey_yr last_survey_yr birth_yr sample_type stratum cluster main_fam_id main_per_id SEX IN_UNIT SAMPLE_STATUS_TYPE PERMANENT_ATTRITION ANY_ATTRITION SAMPLE YR_NONRESPONSE_RECENT YR_NONRESPONSE_FIRST NUM_BIRTHS FIRST_BIRTH_YR MARRIAGE_UPDATE NUM_MARRIED FIRST_MARRIAGE_YR_START FIRST_MARRIAGE_STATUS FIRST_MARRIAGE_YR_END FIRST_SEPARATE_YR RECENT_MARRIAGE_YR_START RECENT_MARRIAGE_STATUS RECENT_MARRIAGE_YR_END RECENT_SEPARATE_YR MARITAL_STATUS has_psid_gene permanent_attrit birth_yr max_educ_focal raceth_fixed_focal last_race_focal first_educ_focal{
	bysort unique_id (`var'): replace `var'=`var'[1] if `var'==.
}

sort unique_id survey_yr

// figure out education again?
replace educ_focal = max_educ_focal if educ_focal==. & first_educ_focal==max_educ_focal & max_educ_focal!=. // so if first AND max education are the same, fill in education
replace educ_focal = first_educ_focal if first_educ_focal==4 & educ_focal==.
replace educ_focal = max_educ_focal if max_educ_focal==1 & educ_focal==.

browse unique_id survey_yr in_sample educ_focal first_educ_focal max_educ_focal

save "$created_data_psid\PSID_individ_allyears.dta", replace

