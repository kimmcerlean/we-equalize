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
**# import orig data, merge to marital history, and create nec relationship variables
********************************************************************************
use "$created_data\PSID_partners.dta", clear

// merge on marital history
merge m:1 unique_id using "$temp\marital_history_wide.dta"
drop if _merge==2

gen in_marital_history=0
replace in_marital_history=1 if _merge==3
drop _merge

// Need to figure our how to get relationship number and duration. can I use with what is here? or need to merge marital history?! also, will this work for cohabiting relationships?! can I also use if started during PSID?. so key question is whether this covers cohab...I feel like in theory no, but in practice, it might?

// this is just for those where marital history not cutting it (either not in it OR cohab)
tab marital_status_updated rel_start
gen rel_start_yr_est = survey_yr if rel_start==1
unique rel_start_yr_est if rel_start==1, by(unique_id) gen(count_rel_est)
browse unique_id survey_yr rel_start_yr_est count_rel_est
bysort unique_id: egen rel_rank_est = rank(rel_start_yr_est)
// bysort unique_id (count_rel_est): replace count_rel_est = count_rel_est[1]
// bysort unique_id (rel_start_yr_est): replace rel_start_yr_est = rel_start_yr_est[1] if count_rel_est==1

sort unique_id survey_yr
browse unique_id survey_yr rel_start_yr_est count_rel_est rel_rank_est

forvalues r=1/6{
	gen rel_start_est`r'=.
	replace rel_start_est`r' = rel_start_yr_est if rel_rank_est==`r'
	bysort unique_id (rel_start_est`r'): replace rel_start_est`r' = rel_start_est`r'[1]
}

sort unique_id survey_yr
browse unique_id survey_yr rel_start_yr_est rel_start_est* count_rel_est rel_rank_est

// filling in marital history
browse unique_id survey_yr RELATION_ marital_status_updated marr_trans rel_start_yr_est FIRST_MARRIAGE_YR_START mh_yr_married1 mh_yr_end1 mh_status1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history // FAMILY_INTERVIEW_NUM_ so will compare what is provided in individual file, what is provided in MH, what I calculated based on observed transitions
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

browse unique_id survey_yr marital_status_updated rel_number rel_start_yr_est FIRST_MARRIAGE_YR_START mh_yr_married1 mh_yr_end1 mh_status1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history

tab rel_number, m
tab rel_number in_marital_history, m // so about half of the missing are bc not in marital history, but still a bunch otherwise
tab rel_number marital_status_updated if in_marital_history==1, m // okay, so yes, the vast majority of missing are bc partnered, not married, so that makes sense.

gen rel_start_yr=.
gen rel_end_yr=.
gen rel_status=.

forvalues r=1/9{
	replace rel_start_yr=mh_yr_married`r' if rel_number==`r'
	replace rel_end_yr=mh_yr_end`r' if rel_number==`r'
	replace rel_status=mh_status`r' if rel_number==`r'
}
forvalues r=12/13{
	replace rel_start_yr=mh_yr_married`r' if rel_number==`r'
	replace rel_end_yr=mh_yr_end`r' if rel_number==`r'
	replace rel_status=mh_status`r' if rel_number==`r'
}
forvalues r=98/99{
	replace rel_start_yr=mh_yr_married`r' if rel_number==`r'
	replace rel_end_yr=mh_yr_end`r' if rel_number==`r'
	replace rel_status=mh_status`r' if rel_number==`r'
}

browse unique_id survey_yr marital_status_updated rel_number rel_start_yr rel_end_yr rel_start_yr_est count_rel_est FIRST_MARRIAGE_YR_START mh_yr_married1 mh_yr_end1 mh_status1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 mh_yr_married4 mh_yr_end4 in_marital_history

gen flag=0
replace flag=1 if rel_start_yr==. // aka need to add manually

forvalues r=1/5{
	local s = `r'+1
	display `s'
	replace rel_start_yr = rel_start_est`r' if survey_yr >=rel_start_est`r' & survey_yr < mh_yr_end`s' & flag==1 // only for those where above didn't work
}
replace rel_start_yr = rel_start_est6 if survey_yr >=rel_start_est6 & flag==1 // 6 is max

// wait what if it ended?! come back to this. think it's fine because those rows should be gone, liek wouldn't be partnered anymore or would have a new end date (based on browse)

browse  unique_id survey_yr marital_status_updated flag rel_number rel_start_yr rel_end_yr rel_start_yr_est rel_start_est*
inspect rel_start_yr if in_marital_history==1
inspect rel_start_yr if marital_status_updated==1
inspect rel_start_yr if marital_status_updated==2

browse unique_id survey_yr marital_status_updated flag rel_number rel_start_yr mh_yr_married1 FIRST_MARRIAGE_YR_START FIRST_MARRIAGE_YR_HEAD_ LAST_MARRIAGE_YR_HEAD_ first_survey_yr

browse unique_id survey_yr marital_status_updated flag rel_number rel_start_yr mh_yr_married1 FIRST_MARRIAGE_YR_START FIRST_MARRIAGE_YR_HEAD_ LAST_MARRIAGE_YR_HEAD_ first_survey_yr if marital_status_updated==2

// okay will try another way to fill in more cohab
gen rel_start_est_cohab = survey_yr if survey_yr==first_survey_yr & marital_status_updated==2
bysort unique_id (rel_start_est_cohab): replace rel_start_est_cohab = rel_start_est_cohab[1]
sort unique_id survey_yr
browse unique_id survey_yr marital_status_updated flag rel_number rel_start_est_cohab rel_start_yr mh_yr_married1 FIRST_MARRIAGE_YR_START FIRST_MARRIAGE_YR_HEAD_ LAST_MARRIAGE_YR_HEAD_ first_survey_yr if marital_status_updated==2

replace rel_start_yr=rel_start_est_cohab if rel_start_yr==. & marital_status_updated==2

gen relationship_duration = survey_yr - rel_start_yr

browse unique_id survey_yr marital_status_updated rel_start_yr relationship_duration

********************************************************************************
**# Other variable recodes now, like DoL and sociodemographics
* A lot of this code repurposed from union dissolution work - file 01a
********************************************************************************
// education
browse unique_id survey_yr  SEX  EDUC1_HEAD_ EDUC_HEAD_ EDUC1_WIFE_ EDUC_WIFE_ YRS_EDUCATION_ // can also use yrs education but this is individual not HH, so need to match to appropriate person
tabstat YRS_EDUCATION_, by(survey_yr) // is that asked in all years? Can i also fill in wife info this way? so seems like 1969 and 1974 missing?

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

recode EDUC1_WIFE_ (0/3=1)(4/5=2)(6=3)(7/8=4)(9=.), gen(educ_wife_early)
recode EDUC1_HEAD_ (0/3=1)(4/5=2)(6=3)(7/8=4)(9=.), gen(educ_head_early)
recode EDUC_WIFE_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_wife_1975)
recode EDUC_HEAD_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_head_1975)
recode YRS_EDUCATION_ (0/11=1) (12=2) (13/15=3) (16/17=4) (98/99=.), gen(educ_completed) // okay no, can't use this, because I guess it's not actually comparable? because head / wife ONLY recorded against those specific ones.

label define educ 1 "LTHS" 2 "HS" 3 "Some College" 4 "College"
label values educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 educ_completed educ

gen educ_wife=.
replace educ_wife=educ_wife_early if inrange(survey_yr,1968,1990)
replace educ_wife=educ_wife_1975 if inrange(survey_yr,1991,2019)
tab survey_yr educ_wife, m // so 69, 70, 71

gen educ_head=.
replace educ_head=educ_head_early if inrange(survey_yr,1968,1990)
replace educ_head=educ_head_1975 if inrange(survey_yr,1991,2019)

label values educ_wife educ_head educ

	// trying to fill in missing wife years when possible
	browse id survey_yr educ_wife if inlist(id,3,12,25,117)
	bysort id (educ_wife): replace educ_wife=educ_wife[1] if educ_wife==.
	// can I also use years of education? okay no.

sort unique_id survey_yr

gen college_complete_wife=0
replace college_complete_wife=1 if educ_wife==4
gen college_complete_head=0
replace college_complete_head=1 if educ_head==4

gen couple_educ_gp=0
replace couple_educ_gp=1 if (college_complete_wife==1 | college_complete_head==1)

label define couple_educ 0 "Neither College" 1 "At Least One College"
label values couple_educ_gp couple_educ

gen educ_type=.
replace educ_type=1 if educ_head > educ_wife & educ_head!=. & educ_wife!=.
replace educ_type=2 if educ_head < educ_wife & educ_head!=. & educ_wife!=.
replace educ_type=3 if educ_head == educ_wife & educ_head!=. & educ_wife!=.

label define educ_type 1 "Hyper" 2 "Hypo" 3 "Homo"
label values educ_type educ_type

// income and division of paid labor
browse unique_id survey_yr FAMILY_INTERVIEW_NUM_ TAXABLE_HEAD_WIFE_ TOTAL_FAMILY_INCOME_ LABOR_INCOME_HEAD_ WAGES_HEAD_  LABOR_INCOME_WIFE_ WAGES_WIFE_ 

	// to use: WAGES_HEAD_ WAGES_WIFE_ -- wife not asked until 1993? okay labor income??
	// wages and labor income asked for head whole time. labor income wife 1968-1993, wages for wife, 1993 onwards

gen earnings_wife=.
replace earnings_wife = LABOR_INCOME_WIFE_ if inrange(survey_yr,1968,1993)
replace earnings_wife = WAGES_WIFE_ if inrange(survey_yr,1994,2019)
replace earnings_wife=. if earnings_wife== 9999999

gen earnings_head=.
replace earnings_head = LABOR_INCOME_HEAD_ if inrange(survey_yr,1968,1993)
replace earnings_head = WAGES_HEAD_ if inrange(survey_yr,1994,2019)
replace earnings_head=. if earnings_head== 9999999

egen couple_earnings = rowtotal(earnings_wife earnings_head)
browse unique_id survey_yr TAXABLE_HEAD_WIFE_ couple_earnings earnings_wife earnings_head
	
gen female_earn_pct = earnings_wife/(couple_earnings)

gen hh_earn_type=.
replace hh_earn_type=1 if female_earn_pct >=.4000 & female_earn_pct <=.6000
replace hh_earn_type=2 if female_earn_pct < .4000 & female_earn_pct >=0
replace hh_earn_type=3 if female_earn_pct > .6000 & female_earn_pct <=1
replace hh_earn_type=4 if earnings_head==0 & earnings_wife==0

label define hh_earn_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_earn_type hh_earn_type

sort unique_id survey_yr

gen hh_earn_type_lag=.
replace hh_earn_type_lag=hh_earn_type[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
label values hh_earn_type_lag hh_earn_type

gen female_earn_pct_lag=.
replace female_earn_pct_lag=female_earn_pct[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

browse unique_id survey_yr wave earnings_head earnings_wife hh_earn_type hh_earn_type_lag female_earn_pct female_earn_pct_lag

// hours instead of earnings	
browse unique_id survey_yr WEEKLY_HRS1_WIFE_ WEEKLY_HRS_WIFE_ WEEKLY_HRS1_HEAD_ WEEKLY_HRS_HEAD_

gen weekly_hrs_wife = .
replace weekly_hrs_wife = WEEKLY_HRS1_WIFE_ if survey_yr > 1969 & survey_yr <1994
replace weekly_hrs_wife = WEEKLY_HRS_WIFE_ if survey_yr >=1994
replace weekly_hrs_wife = 0 if inrange(survey_yr,1968,1969) & inlist(WEEKLY_HRS1_WIFE_,9,0)
replace weekly_hrs_wife = 10 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==1
replace weekly_hrs_wife = 27 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==2
replace weekly_hrs_wife = 35 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==3
replace weekly_hrs_wife = 40 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==4
replace weekly_hrs_wife = 45 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==5
replace weekly_hrs_wife = 48 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==6
replace weekly_hrs_wife = 55 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_WIFE_ ==7
replace weekly_hrs_wife = 60 if inrange(survey_yr,1968,1969)  & WEEKLY_HRS1_WIFE_ ==8
replace weekly_hrs_wife=. if weekly_hrs_wife==999

gen weekly_hrs_head = .
replace weekly_hrs_head = WEEKLY_HRS1_HEAD_ if survey_yr > 1969 & survey_yr <1994
replace weekly_hrs_head = WEEKLY_HRS_HEAD_ if survey_yr >=1994
replace weekly_hrs_head = 0 if inrange(survey_yr,1968,1969) & inlist(WEEKLY_HRS1_HEAD_,9,0)
replace weekly_hrs_head = 10 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==1
replace weekly_hrs_head = 27 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==2
replace weekly_hrs_head = 35 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==3
replace weekly_hrs_head = 40 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==4
replace weekly_hrs_head = 45 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==5
replace weekly_hrs_head = 48 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==6
replace weekly_hrs_head = 55 if inrange(survey_yr,1968,1969) & WEEKLY_HRS1_HEAD_ ==7
replace weekly_hrs_head = 60 if inrange(survey_yr,1968,1969)  & WEEKLY_HRS1_HEAD_ ==8
replace weekly_hrs_head=. if weekly_hrs_head==999

egen couple_hours = rowtotal(weekly_hrs_wife weekly_hrs_head)
gen female_hours_pct = weekly_hrs_wife/couple_hours

gen hh_hours_type=.
replace hh_hours_type=1 if female_hours_pct >=.4000 & female_hours_pct <=.6000
replace hh_hours_type=2 if female_hours_pct <.4000
replace hh_hours_type=3 if female_hours_pct >.6000 & female_hours_pct!=.
replace hh_hours_type=4 if weekly_hrs_head==0 & weekly_hrs_wife==0

label define hh_hours_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_hours_type hh_hours_type

gen hh_hours_type_lag=.
replace hh_hours_type_lag=hh_hours_type[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
label values hh_hours_type_lag hh_hours_type

gen female_hours_pct_lag=.
replace female_hours_pct_lag=female_hours_pct[_n-1] if unique_id==unique_id[_n-1]  & wave==wave[_n-1]+1

// housework hours - not totally sure if accurate prior to 1976 (asked annually not weekly). missing head/wife specific in 1968, 1975, 1982
browse unique_id survey_yr HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_ // total and most HW stopped after 1974

gen housework_head = HOUSEWORK_HEAD_
replace housework_head = (HOUSEWORK_HEAD_/52) if inrange(survey_yr,1968,1974)
replace housework_head=. if inlist(housework_head,998,999)
gen housework_wife = HOUSEWORK_WIFE_
replace housework_wife = (HOUSEWORK_WIFE_/52) if inrange(survey_yr,1968,1974)
replace housework_wife=. if inlist(housework_wife,998,999)
gen total_housework_weekly = TOTAL_HOUSEWORK_HW_ / 52

egen couple_housework = rowtotal (housework_wife housework_head)
browse id survey_yr housework_head housework_wife couple_housework total_housework_weekly TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_

gen wife_housework_pct = housework_wife / couple_housework

gen housework_bkt=.
replace housework_bkt=1 if wife_housework_pct >=.4000 & wife_housework_pct <=.6000
replace housework_bkt=2 if wife_housework_pct >.6000 & wife_housework_pct!=.
replace housework_bkt=3 if wife_housework_pct <.4000
replace housework_bkt=4 if housework_wife==0 & housework_head==0

label define housework_bkt 1 "Dual HW" 2 "Female Primary" 3 "Male Primary" 4 "NA"
label values housework_bkt housework_bkt

sort id survey_yr
gen housework_bkt_lag=.
replace housework_bkt_lag=housework_bkt[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
label values housework_bkt_lag housework_bkt

gen wife_hw_pct_lag=.
replace wife_hw_pct_lag=wife_housework_pct[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

//  combined indicator of paid and unpaid, using HOURS - okay currently missing for all years that housework hours are
/*
gen hours_housework=.
replace hours_housework=1 if hh_hours_type==1 & housework_bkt==1 // dual both (egal)
replace hours_housework=2 if hh_hours_type==1 & housework_bkt==2 // dual earner, female HM (second shift)
replace hours_housework=3 if hh_hours_type==2 & housework_bkt==1 // male BW, dual HW (mm not sure)
replace hours_housework=4 if hh_hours_type==2 & housework_bkt==2 // male BW, female HM (conventional)
replace hours_housework=5 if hh_hours_type==3 & housework_bkt==1 // female BW, dual HW (gender-atypical)
replace hours_housework=6 if hh_hours_type==3 & housework_bkt==2 // female BW, female HM (undoing gender)
replace hours_housework=7 if housework_bkt==3  // all where male does more housework (gender-atypical)
replace hours_housework=8 if hh_hours_type==4  // no earners

label define hours_housework 1 "Egal" 2 "Second Shift" 3 "Male BW, dual HW" 4 "Conventional" 5 "Gender-atypical" 6 "Undoing gender" 7 "Male HW dominant" 8 "No Earners"
label values hours_housework hours_housework 
*/

gen earn_housework=.
replace earn_housework=1 if hh_earn_type==1 & housework_bkt==1 // dual both (egal)
replace earn_housework=2 if hh_earn_type==1 & housework_bkt==2 // dual earner, female HM (second shift)
replace earn_housework=3 if hh_earn_type==2 & housework_bkt==2 // male BW, female HM (traditional)
replace earn_housework=4 if hh_earn_type==3 & housework_bkt==3 // female BW, male HM (counter-traditional)
replace earn_housework=5 if earn_housework==. & hh_earn_type!=. & housework_bkt!=. // all others

label define earn_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"
label values earn_housework earn_housework 

gen earn_housework_lag=.
replace earn_housework_lag=earn_housework[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
label values earn_housework_lag earn_housework

// employment
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

gen employ_wife=0
replace employ_wife=1 if EMPLOY_STATUS_WIFE_==1
gen employ1_wife=0
replace employ1_wife=1 if EMPLOY_STATUS1_WIFE_==1
gen employ2_wife=0
replace employ2_wife=1 if EMPLOY_STATUS2_WIFE_==1
gen employ3_wife=0
replace employ3_wife=1 if EMPLOY_STATUS3_WIFE_==1
egen employed_wife=rowtotal(employ_wife employ1_wife employ2_wife employ3_wife)

browse id survey_yr employed_head employed_wife employ_head employ1_head employ_wife employ1_wife

// problem is this employment is NOW not last year. I want last year? use if wages = employ=yes, then no? (or hours)
gen employed_ly_head=0
replace employed_ly_head=1 if earnings_head > 0 & earnings_head!=.

gen employed_ly_wife=0
replace employed_ly_wife=1 if earnings_wife > 0 & earnings_wife!=.

gen ft_pt_head=.
replace ft_pt_head = 0 if weekly_hrs_head==0
replace ft_pt_head = 1 if weekly_hrs_head > 0 & weekly_hrs_head<=35
replace ft_pt_head = 2 if weekly_hrs_head > 35 & weekly_hrs_head < 999

gen ft_pt_wife=.
replace ft_pt_wife = 0 if weekly_hrs_wife==0
replace ft_pt_wife = 1 if weekly_hrs_wife > 0 & weekly_hrs_wife<=35
replace ft_pt_wife = 2 if weekly_hrs_wife > 35 & weekly_hrs_wife < 999

label define ft_pt 0 "Not Employed" 1 "PT" 2 "FT"
label values ft_pt_head ft_pt_wife ft_pt

gen ft_head=0
replace ft_head=1 if ft_pt_head==2

gen ft_wife=0
replace ft_wife=1 if ft_pt_wife==2

// adding other controls right now
gen either_enrolled=0
replace either_enrolled = 1 if ENROLLED_WIFE_==1 | ENROLLED_HEAD_==1

// race
// drop if RACE_1_WIFE_==9 | RACE_1_HEAD_==9

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

gen race_wife=race_1_wife_rec
replace race_wife=7 if race_2_wife_rec!=.

gen race_head=race_1_head_rec
replace race_head=7 if race_2_head_rec!=.

label define race 1 "White" 2 "Black" 3 "Indian" 4 "Asian" 5 "Latino" 6 "Other" 7 "Multi-racial"
label values race_wife race_head race

// wife - not asked until 1985, need to figure out
	browse id survey_yr race_wife if inlist(id,3,12,16)
	bysort id (race_wife): replace race_wife=race_wife[1] if race_wife==.

gen same_race=0
replace same_race=1 if race_head==race_wife & race_head!=.

// any children - need to get more specific; think I need to append childbirth history also?!
gen children=0
replace children=1 if NUM_CHILDREN_>=1

bysort unique_id: egen children_ever = max(NUM_CHILDREN_)
replace children_ever=1 if children_ever>0

// use incremental births? okay come back to this with childbirth history
recode NUM_BIRTHS(98/99=.) // okay this doesn't increment GAH. it must be ever?
recode BIRTHS_BOTH_(8/9=.)
recode BIRTHS_REF_(8/9=.)
recode BIRTHS_BOTH_(8/9=.)
// or if num children goes up AND age of youngest child is 1 (lol it is coded 1 for newborn up to second birthday in most years) aka unique_id 1003 in 1973?!

browse unique_id survey_yr SEX NUM_CHILDREN_ AGE_YOUNG_CHILD_  BIRTHS_BOTH_ BIRTHS_REF_ BIRTH_SPOUSE_  NUM_BIRTHS // okay so these are new births in last year, but not asksed until 1986 GAH

gen had_birth=0
replace had_birth=1 if NUM_CHILDREN_ == NUM_CHILDREN_[_n-1]+1 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen had_first_birth=0
replace had_first_birth=1 if had_birth==1 & (survey_yr==FIRST_BIRTH_YR | survey_yr==FIRST_BIRTH_YR+1) // think sometimes recorded a year late

gen had_first_birth_alt=0
replace had_first_birth_alt=1 if NUM_CHILDREN_==1 & NUM_CHILDREN_[_n-1]==0 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
browse unique_id survey_yr SEX NUM_CHILDREN_ AGE_YOUNG_CHILD_  had_birth had_first_birth had_first_birth_alt FIRST_BIRTH_YR

// also use FIRST_BIRTH_YR to say whether pre / post marital

// some age things
browse unique_id survey_yr SEX year_birth  AGE_ AGE_REF_ AGE_SPOUSE_

gen yr_born_head = survey_yr - AGE_REF_
gen yr_born_wife = survey_yr- AGE_SPOUSE_

gen age_mar_head = rel_start_yr -  yr_born_head
gen age_mar_wife = rel_start_yr -  yr_born_wife
browse unique_id survey_yr SEX year_birth yr_born_head  yr_born_wife AGE_ AGE_REF_ AGE_SPOUSE_ rel_start_yr age_mar_head age_mar_wife

save "$created_data\PSID_partners_cleaned.dta", replace