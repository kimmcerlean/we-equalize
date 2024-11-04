
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: life_course_sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files gets the eligible couples for analysis and creates
* necessary variables to conduct analysis

********************************************************************************
* Import data and small final sample cleanup
********************************************************************************
use "$created_data\PSID_partners_cleaned.dta", clear
// use "G:\Other computers\My Laptop\Documents\Research Projects\Growth Curves\PAA 2025 submission\data\PSID_partners_cleaned.dta", clear

// first create partner ids before I drop partners
gen id_ref=.
replace id_ref = unique_id if inlist(RELATION_,1,10) 
bysort survey_yr FAMILY_INTERVIEW_NUM_ (id_ref): replace id_ref = id_ref[1]

gen id_wife=.
replace id_wife = unique_id if inlist(RELATION_,2,20,22) 
bysort survey_yr FAMILY_INTERVIEW_NUM_ (id_wife): replace id_wife = id_wife[1]

sort unique_id survey_yr
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ id_ref id_wife

gen partner_id=.
replace partner_id = id_ref if inlist(RELATION_,2,20,22)  // so need opposite id
replace partner_id = id_wife if inlist(RELATION_,1,10)

browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ partner_id id_ref id_wife
sort unique_id survey_yr

// now restrict to one record per HH
tab SEX marital_status_updated if SEX_HEAD_==1
// tab SEX marital_status_updated if SEX_HEAD_==1 & survey_yr < 2021 // validate it matches

/* need to end up with this amount of respondents after the below

INDIVIDUAL | Married (  Partnered |     Total
-----------+----------------------+----------
      Male |   163,449     11,543 |   174,992 
    Female |   163,429     11,499 |   174,928 
-----------+----------------------+----------
     Total |   326,878     23,042 |   349,920 

*/

drop if SEX_HEAD_!=1
tab rel_start_yr SEX, m // is either one's data more reliable?

// keep only one respondent per household (bc all data recorded for all)
sort survey_yr FAMILY_INTERVIEW_NUM_  unique_id   
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_start_yr female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

gen has_rel_info=0
replace has_rel_info=1 if rel_start_yr!=.

bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_info = max(has_rel_info)
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_info has_rel_info rel_start_yr female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

* first drop the partner WITHOUT rel info if at least one of them does
drop if has_rel_info==0 & rel_info==1

*then rank the remaining members
bysort survey_yr FAMILY_INTERVIEW_NUM_ : egen per_id = rank(unique_id) // so if there is only one member left after above, will get a 1
browse survey_yr FAMILY_INTERVIEW_NUM_  unique_id per_id

tab per_id // 1s should approximately total above
keep if per_id==1

tab marital_status_updated
/* k pretty close

-------------------+-----------------------------------
Married (or pre77) |    163,239       93.45       93.45
         Partnered |     11,435        6.55      100.00
-------------------+-----------------------------------

*/

// think I need to fix duration because for some, I think clock might start again when they transition to cohabitation? get minimum year within a couple as main start date?
sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr rel_start_yr marital_status_updated relationship_duration

bysort unique_id partner_id: egen rel_start_all = min(rel_start_yr)
gen dur=survey_yr - rel_start_all
browse unique_id partner_id survey_yr rel_start_all rel_start_yr marital_status_updated dur relationship_duration rel_rank_est count_rel_est rel_number

tab dur, m
tab relationship_duration, m
unique unique_id partner_id, by(marital_status_updated)

// should I restrict to certain years? aka to help with the cohab problem? well probably should from a time standpoint... and to match to the british one, at least do 1990+?
tab survey_yr marital_status_updated
tab rel_start_yr marital_status_updated, m

unique unique_id
unique unique_id if rel_start_yr >= 1990 // nearly half of sample goes away. okay let's decide later...
unique unique_id if rel_start_all >= 1990 // nearly half of sample goes away. okay let's decide later...
unique unique_id if rel_start_yr >= 1980 // compromise with 1980? ugh idk
* we want to keep people who started after 1990, who we observed their start, and who started before 2011, so we have 10 years of observations
* first, min and max duration
bysort unique_id partner_id: egen min_dur = min(dur)
bysort unique_id partner_id: egen max_dur = max(dur)
bysort unique_id partner_id: egen last_yr_observed = max(survey_yr)

browse unique_id partner_id survey_yr rel_start_all rel_end_yr relationship_duration min_dur max_dur
keep if rel_start_all >= 1990 & inlist(min_dur,0,1)
keep if rel_start_all <= 2011

// restrict to working age?
tab AGE_REF_ employed_ly_head, row
keep if (AGE_REF_>=18 & AGE_REF_<=60) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=60) // sort of drops off a cliff after 60?

// did i observe it end?
bysort unique_id partner_id: egen ended = max(rel_end_pre)
sort unique_id partner_id survey_yr

browse unique_id partner_id survey_yr rel_start_all rel_end_yr last_yr_observed rel_status ended relationship_duration min_dur max_dur // these rel_end rel_status only cover marriage not cohab bc from marital history

// get deduped list of couples to match their info on later
preserve

collapse (first) rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended, by(unique_id partner_id)

save "$created_data\couple_list.dta", replace

restore

// do some QA checks using this couple information to compare to below
unique unique_id partner_id, by(max_dur) // okay this exactly matches
unique unique_id partner_id if rel_end_pre, by(max_dur) 

gen observation_20=0
replace observation_20=1 if inrange(dur,0,20)

bysort unique_id partner_id: egen num_observations_20 = sum(observation_20)
sort unique_id partner_id survey_yr
browse unique_id partner_id dur max_dur num_observations_20

gen percent_tracked = num_observations_20 / max_dur if max_dur < 21
sum percent_tracked, detail // but this won't be 100% because not imputed, so 50% is good

tab dur ended, row

********************************************************************************
**# Now get survey history for these couples from main file
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
keep unique_id FIRST_BIRTH_YR in_sample_* relationship_* MARITAL_PAIRS_* SEX EDUC1_WIFE_* EDUC1_HEAD_* EDUC_WIFE_* EDUC_HEAD_* LABOR_INCOME_WIFE_* WAGES_WIFE_* LABOR_INCOME_HEAD_* WAGES_HEAD_* TAXABLE_HEAD_WIFE_* WEEKLY_HRS1_WIFE_* WEEKLY_HRS_WIFE_* WEEKLY_HRS1_HEAD_* WEEKLY_HRS_HEAD_* HOUSEWORK_HEAD_* HOUSEWORK_WIFE_* TOTAL_HOUSEWORK_HW_* MOST_HOUSEWORK_* EMPLOY_STATUS_HEAD_* EMPLOY_STATUS1_HEAD_* EMPLOY_STATUS2_HEAD_* EMPLOY_STATUS3_HEAD_* EMPLOY_STATUS_WIFE_* EMPLOY_STATUS1_WIFE_* EMPLOY_STATUS2_WIFE_* EMPLOY_STATUS3_WIFE_* NUM_CHILDREN_* AGE_YOUNG_CHILD_* AGE_REF_* AGE_SPOUSE_* TOTAL_FAMILY_INCOME_* FAMILY_INTERVIEW_NUM_*

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

foreach var in EDUC1_WIFE_ EDUC1_HEAD_ EDUC_WIFE_ EDUC_HEAD_ LABOR_INCOME_WIFE_ WAGES_WIFE_ LABOR_INCOME_HEAD_ WAGES_HEAD_ TAXABLE_HEAD_WIFE_ WEEKLY_HRS1_WIFE_ WEEKLY_HRS_WIFE_ WEEKLY_HRS1_HEAD_ WEEKLY_HRS_HEAD_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ AGE_REF_ AGE_SPOUSE_ FAMILY_INTERVIEW_NUM_ TOTAL_FAMILY_INCOME_{
	forvalues y=1968/1987{
		capture drop `var'`y' // in case var not in all years
	}
}

drop *_1968

save "$temp\partner_sample_info.dta", replace

********************************************************************************
**# Now match couples to survey data and create some recodes
********************************************************************************
use "$created_data\couple_list.dta", clear

merge m:1 unique_id using "$temp\partner_sample_info.dta"
drop if _merge==2
drop _merge

drop *_sp_*
drop SEX_sp

merge m:1 partner_id using  "$temp\partner_sample_info.dta", keepusing(*_sp_* SEX_sp)
drop if _merge==2
drop _merge

browse unique_id partner_id rel_start_all last_yr_observed SEX* in_sample* HOUSEWORK_WIFE_*

save "$temp\couple_sample_details_wide.dta", replace

**# recodes
use "$temp\couple_sample_details_wide.dta", clear

reshape long MARITAL_PAIRS_ in_sample_ relationship_ MARITAL_PAIRS_sp_ in_sample_sp_ relationship_sp_ FAMILY_INTERVIEW_NUM_ EDUC1_WIFE_ EDUC1_HEAD_ EDUC_WIFE_ EDUC_HEAD_ LABOR_INCOME_WIFE_ WAGES_WIFE_ WAGES_HEAD_PRE_ WAGES_WIFE_PRE_ LABOR_INCOME_HEAD_ WAGES_HEAD_ TAXABLE_HEAD_WIFE_ WEEKLY_HRS1_WIFE_ WEEKLY_HRS_WIFE_ WEEKLY_HRS1_HEAD_ WEEKLY_HRS_HEAD_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ AGE_REF_ AGE_SPOUSE_ TOTAL_FAMILY_INCOME_, ///
 i(unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX SEX_sp) j(survey_yr)

// want consecutive waves to make some things easier later
egen wave = group(survey_yr)

// sample / partnership indicator
gen coupled_in_sample = 0
replace coupled_in_sample = 1 if in_sample_==1 & in_sample_sp_==1 & inrange(MARITAL_PAIRS_,1,3) & inrange(MARITAL_PAIRS_sp_,1,3)

gen single_in_sample_wom = 0
replace single_in_sample_wom = 1 if in_sample_==1 & in_sample_sp_==0 & SEX ==2 // so main person is in sample and is a woman
replace single_in_sample_wom = 1 if in_sample_==0 & in_sample_sp_==1 & SEX_sp ==2 // so partner is in sample and is a woman

gen single_in_sample_man = 0
replace single_in_sample_man = 1 if in_sample_==1 & in_sample_sp_==0 & SEX ==1
replace single_in_sample_man = 1 if in_sample_==0 & in_sample_sp_==1 & SEX_sp ==1

gen single_in_sample_both=0
replace single_in_sample_both = 1 if in_sample_==1 & in_sample_sp_==1 & (survey_yr < rel_start_all | survey_yr > last_yr_observed)

gen not_in_sample=0
replace not_in_sample=1 if in_sample_==0 & in_sample_sp_ ==0

gen status=.
replace status=1 if coupled_in_sample==1
replace status=2 if single_in_sample_wom==1
replace status=3 if single_in_sample_man==1
replace status=4 if single_in_sample_both==1
replace status=0 if not_in_sample==1
replace status=1 if in_sample_==1 & in_sample_sp==1 & status==.

label define status 1 "coupled" 2 "single: woman" 3 "single: man" 4 "single:both" 0 "missing"
label values status status
tab status, m

gen pair=MARITAL_PAIRS_
gen pair_sp=MARITAL_PAIRS_sp_

// education recodes
browse unique_id survey_yr in_sample_* relationship_* EDUC_*

recode EDUC1_WIFE_ (0/3=1)(4/5=2)(6=3)(7/8=4)(9=.), gen(educ_wife_early)
recode EDUC1_HEAD_ (0/3=1)(4/5=2)(6=3)(7/8=4)(9=.), gen(educ_head_early)
recode EDUC_WIFE_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_wife_1975)
recode EDUC_HEAD_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_head_1975)

label define educ 1 "LTHS" 2 "HS" 3 "Some College" 4 "College"
label values educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 educ

gen educ_wife=.
replace educ_wife=educ_wife_early if inrange(survey_yr,1968,1990)
replace educ_wife=educ_wife_1975 if inrange(survey_yr,1991,2021)
tab survey_yr educ_wife if in_sample_==1, m

gen educ_head=.
replace educ_head=educ_head_early if inrange(survey_yr,1968,1990)
replace educ_head=educ_head_1975 if inrange(survey_yr,1991,2021)
tab survey_yr educ_head if in_sample_==1, m

label values educ_wife educ_head educ

	// trying to fill in missing educ years when possible
	bysort unique_id (educ_wife): replace educ_wife=educ_wife[1] if educ_wife==. & in_sample_==1
	bysort unique_id (educ_head): replace educ_head=educ_head[1] if educ_head==. & in_sample_==1

sort unique_id survey_yr

gen college_complete_wife=0
replace college_complete_wife=1 if educ_wife==4
gen college_complete_head=0
replace college_complete_head=1 if educ_head==4

gen couple_educ_gp=0
replace couple_educ_gp=1 if (college_complete_wife==1 | college_complete_head==1) & status==1

label define couple_educ 0 "Neither College" 1 "At Least One College"
label values couple_educ_gp couple_educ

gen educ_type=.
replace educ_type=1 if educ_head > educ_wife & educ_head!=. & educ_wife!=.  & status==1
replace educ_type=2 if educ_head < educ_wife & educ_head!=. & educ_wife!=.  & status==1
replace educ_type=3 if educ_head == educ_wife & educ_head!=. & educ_wife!=.  & status==1

label define educ_type 1 "Hyper" 2 "Hypo" 3 "Homo"
label values educ_type educ_type

// income and division of paid labor
browse unique_id survey_yr FAMILY_INTERVIEW_NUM_ TAXABLE_HEAD_WIFE_ TOTAL_FAMILY_INCOME_ LABOR_INCOME_HEAD_ WAGES_HEAD_  LABOR_INCOME_WIFE_ WAGES_WIFE_ 

	// to use: WAGES_HEAD_ WAGES_WIFE_ -- wife not asked until 1993? okay labor income??
	// wages and labor income asked for head whole time. labor income wife 1968-1993, wages for wife, 1993 onwards

gen earnings_wife=.
replace earnings_wife = LABOR_INCOME_WIFE_ if inrange(survey_yr,1968,1993)
replace earnings_wife = WAGES_WIFE_ if inrange(survey_yr,1994,2021)
replace earnings_wife=. if earnings_wife== 9999999

gen earnings_head=.
replace earnings_head = LABOR_INCOME_HEAD_ if inrange(survey_yr,1968,1993)
replace earnings_head = WAGES_HEAD_ if inrange(survey_yr,1994,2021)
replace earnings_head=. if earnings_head== 9999999

egen couple_earnings = rowtotal(earnings_wife earnings_head) if status==1
browse unique_id survey_yr TAXABLE_HEAD_WIFE_ couple_earnings earnings_wife earnings_head
	
gen female_earn_pct = earnings_wife/(couple_earnings) if status==1

gen hh_earn_type=.
replace hh_earn_type=1 if female_earn_pct >=.4000 & female_earn_pct <=.6000 & status==1
replace hh_earn_type=2 if female_earn_pct < .4000 & female_earn_pct >=0  & status==1
replace hh_earn_type=3 if female_earn_pct > .6000 & female_earn_pct <=1  & status==1
replace hh_earn_type=4 if earnings_head==0 & earnings_wife==0  & status==1

label define hh_earn_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_earn_type hh_earn_type
tab hh_earn_type if in_sample_==1, m
tab hh_earn_type if status==1, m

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

egen couple_hours = rowtotal(weekly_hrs_wife weekly_hrs_head) if status==1
gen female_hours_pct = weekly_hrs_wife/couple_hours  if status==1

gen hh_hours_type=.
replace hh_hours_type=1 if female_hours_pct >=.4000 & female_hours_pct <=.6000 & status==1
replace hh_hours_type=2 if female_hours_pct <.4000 & status==1
replace hh_hours_type=3 if female_hours_pct >.6000 & female_hours_pct!=. & status==1
replace hh_hours_type=4 if weekly_hrs_head==0 & weekly_hrs_wife==0 & status==1

label define hh_hours_type 1 "Dual Earner" 2 "Male BW" 3 "Female BW" 4 "No Earners"
label values hh_hours_type hh_hours_type
tab hh_hours_type if status==1, m

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

egen couple_housework = rowtotal (housework_wife housework_head) if status==1
browse unique_id survey_yr housework_head housework_wife couple_housework total_housework_weekly TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_

gen wife_housework_pct = housework_wife / couple_housework  if status==1

gen housework_bkt=.
replace housework_bkt=1 if wife_housework_pct >=.4000 & wife_housework_pct <=.6000 & status==1
replace housework_bkt=2 if wife_housework_pct >.6000 & wife_housework_pct!=. & status==1
replace housework_bkt=3 if wife_housework_pct <.4000 & status==1
replace housework_bkt=4 if housework_wife==0 & housework_head==0 & status==1

label define housework_bkt 1 "Dual HW" 2 "Female Primary" 3 "Male Primary" 4 "NA"
label values housework_bkt housework_bkt
tab housework_bkt if status==1, m

browse unique_id survey_yr partner_id HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ housework_head housework_wife couple_housework wife_housework_pct housework_bkt

sort unique_id survey_yr
gen housework_bkt_lag=.
replace housework_bkt_lag=housework_bkt[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
label values housework_bkt_lag housework_bkt

gen wife_hw_pct_lag=.
replace wife_hw_pct_lag=wife_housework_pct[_n-1] if unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

// combined indicator
gen earn_housework=.
replace earn_housework=1 if hh_earn_type==1 & housework_bkt==1 & status==1 // dual both (egal)
replace earn_housework=2 if hh_earn_type==1 & housework_bkt==2 & status==1 // dual earner, female HM (second shift)
replace earn_housework=3 if hh_earn_type==2 & housework_bkt==2 & status==1 // male BW, female HM (traditional)
replace earn_housework=4 if hh_earn_type==3 & housework_bkt==3 & status==1 // female BW, male HM (counter-traditional)
replace earn_housework=5 if earn_housework==. & hh_earn_type!=. & housework_bkt!=. & status==1 // all others

label define earn_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"
label values earn_housework earn_housework 
tab earn_housework if status==1, m

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

browse unique_id survey_yr employed_head employed_wife employ_head employ1_head employ_wife employ1_wife

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

// any children - need to get more specific; think I need to append childbirth history also?!
gen children=0
replace children=1 if NUM_CHILDREN_>=1

bysort unique_id: egen children_ever = max(NUM_CHILDREN_)
replace children_ever=1 if children_ever>0

// use incremental births? okay come back to this with childbirth history
gen had_birth=0
replace had_birth=1 if NUM_CHILDREN_ == NUM_CHILDREN_[_n-1]+1 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen had_first_birth=0
replace had_first_birth=1 if had_birth==1 & (survey_yr==FIRST_BIRTH_YR | survey_yr==FIRST_BIRTH_YR+1) // think sometimes recorded a year late

gen had_first_birth_alt=0
replace had_first_birth_alt=1 if NUM_CHILDREN_==1 & NUM_CHILDREN_[_n-1]==0 & AGE_YOUNG_CHILD_==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
browse unique_id survey_yr SEX NUM_CHILDREN_ AGE_YOUNG_CHILD_  had_birth had_first_birth had_first_birth_alt FIRST_BIRTH_YR

// some age things
gen yr_born_head = survey_yr - AGE_REF_
gen yr_born_wife = survey_yr- AGE_SPOUSE_

gen age_mar_head = rel_start_all -  yr_born_head if status==1
gen age_mar_wife = rel_start_all -  yr_born_wife if status==1
browse unique_id survey_yr status SEX yr_born_head  yr_born_wife AGE_REF_ AGE_SPOUSE_ rel_start_all age_mar_head age_mar_wife

save "$temp\compiled_couple_data.dta", replace

********************************************************************************
**# Now recenter on duration
********************************************************************************
use "$temp\compiled_couple_data.dta", clear

gen duration = survey_yr - rel_start_all
browse unique_id partner_id survey_yr rel_start_all duration last_yr_observed in_sample_ in_sample_sp_  relationship_ relationship_sp_ pair pair_sp

tab duration, m
keep if duration >=-4 // keep up to 5 years prior, jic
keep if duration <=12 // up to 10/11 for now - but adding a few extra years so I can do the lookups below and still retain up to 20

gen duration_rec=duration+4 // negatives won't work in reshape - so make -5 0

tab duration, m
tab duration if status==1, m

label values relationship_sp_ relationship
browse unique_id survey_yr duration max_dur partner_id in_sample* status relationship*

tab relationship_ relationship_sp_ if status==1, m

gen either_head=0
replace either_head=1 if relationship_==1 | relationship_sp_==1
replace either_head=. if status!=1

tab either_head if status==1, m

// all couples, not imputed
tab duration hh_earn_type if status==1 & either_head==1, row nofreq
tab duration hh_hours_type if status==1 & either_head==1, row nofreq
tab duration housework_bkt if status==1 & either_head==1, row nofreq
tab duration earn_housework if status==1 & either_head==1, row nofreq

// all coupless who made it at least 10 years, not imputed
tab duration hh_earn_type if status==1 & either_head==1 & max_dur>=10, row nofreq
tab duration hh_hours_type if status==1 & either_head==1 & max_dur>=10, row nofreq
tab duration housework_bkt if status==1 & either_head==1 & max_dur>=10, row nofreq
tab duration earn_housework if status==1 & either_head==1 & max_dur>=10, row nofreq

// okay this isn't going to work, I need to reshape and attempt to fill it in
drop MARITAL_PAIRS_ MARITAL_PAIRS_sp_ survey_yr duration housework_bkt_lag  earn_housework_lag EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ WAGES_HEAD_PRE_ WAGES_WIFE_PRE_ WEEKLY_HRS_HEAD_ WEEKLY_HRS_WIFE_ WAGES_HEAD_ LABOR_INCOME_HEAD_ WAGES_WIFE_ TAXABLE_HEAD_WIFE_ TOTAL_FAMILY_INCOME_ EDUC_HEAD_ EDUC_WIFE_ EDUC1_WIFE_ EDUC1_HEAD_ LABOR_INCOME_WIFE_ WEEKLY_HRS1_WIFE_ WEEKLY_HRS1_HEAD_ TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS_WIFE_ wave educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 hh_earn_type_lag female_earn_pct_lag hh_hours_type_lag female_hours_pct_lag employ_head employ1_head employ2_head employ3_head  employ_wife employ1_wife employ2_wife employ3_wife wife_hw_pct_lag

reshape wide coupled_in_sample single_in_sample_wom single_in_sample_man single_in_sample_both not_in_sample status in_sample_ relationship_ in_sample_sp_ relationship_sp_ pair pair_sp housework_head housework_wife total_housework_weekly couple_housework wife_housework_pct housework_bkt earn_housework educ_wife educ_head college_complete_wife college_complete_head couple_educ_gp educ_type earnings_wife earnings_head couple_earnings female_earn_pct hh_earn_type weekly_hrs_wife weekly_hrs_head couple_hours female_hours_pct hh_hours_type employed_head employed_wife employed_ly_head employed_ly_wife ft_pt_head ft_pt_wife ft_head ft_wife children children_ever had_birth had_first_birth had_first_birth_alt yr_born_head yr_born_wife age_mar_head age_mar_wife either_head AGE_REF_ AGE_SPOUSE_ FAMILY_INTERVIEW_NUM_, i(unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX SEX_sp) j(duration_rec)

********************************************************************************
**# attempt to fill in missing years
********************************************************************************
forvalues s=0/16{
	replace status`s'=5 if status`s'==.
}

label define status_x 0 "True Missing" 1 "Coupled" 2 "Single Woman" 3 "Single Man Only" 4 "Off year" 5 "Censored" // put both in women heree. will make this better in another variable.

forvalues s=0/16{
	gen status_x`s'=.
	replace status_x`s'=0 if status`s'==0
	replace status_x`s'=1 if status`s'==1
	replace status_x`s'=2 if inlist(status`s',2,4)
	replace status_x`s'=3 if status`s'==3
	replace status_x`s'=4 if status`s'==5
	label values status_x`s' status_x
}

// just replacing the missings

forvalues b=1/15{
	local a = `b'-1
	local c = `b'+1
	replace status_x`b' = 0 if status_x`a'==0 & status_x`c'==0 & status_x`b'==4 // so is status is off year, but both sides are missing, call this missing
}

forvalues b=1/15{
	local a = `b'-1
	local c = `b'+1
	replace status_x`b' = 5 if status_x`a'==4 & status_x`c'==4 & status_x`b'==4 // so if it becomes all off-years, this actually means censored.
}

forvalues b=1/15{
	local a = `b'-1
	local c = `b'+1
	replace status_x`b' = 5 if status_x`a'==5 & status_x`c'==5 & status_x`b'==4 // not working for all so if off-year till surrounded by censored, this is censored
}

// now let's attempt to fill in all of the off-year data, create new variable for reference
forvalues s=0/16{
	gen status_gp`s'=status_x`s'
	label values status_gp`s' status_x
}

forvalues b=1/15{
	local a = `b'-1
	local c = `b'+1
	replace status_gp`b' = 1 if status_x`b'==4 & status_x`a'==1 & status_x`c'==1 // replace off-year with coupled if both years around are coupled
	replace status_gp`b' = 2 if status_x`b'==4 & status_x`a'==2 & status_x`c'==2 // repeat for all
	replace status_gp`b' = 3 if status_x`b'==4 & status_x`a'==3 & status_x`c'==3 // repeat for all
}

rename status_gp0 status_gp_neg4
rename status_gp1 status_gp_neg3
rename status_gp2 status_gp_neg2
rename status_gp3 status_gp_neg1

forvalues s=4/16{ // okay, I think I need to do some duration finagling, so need to reset these
	local a = `s'-4
	rename status_gp`s' status_gp`a'

}

gen duration=last_yr_observed-rel_start_all

browse unique_id partner_id rel_start_all last_yr_observed duration status_gp*

forvalues b=0/11{
	local c = `b'+1
	replace status_gp`b' = status_gp`c' if duration < `b' & status_gp`b'==4
}

rename hh_earn_type0 hh_earn_type_neg4
rename hh_earn_type1 hh_earn_type_neg3
rename hh_earn_type2 hh_earn_type_neg2
rename hh_earn_type3 hh_earn_type_neg1
rename hh_hours_type0 hh_hours_type_neg4
rename hh_hours_type1 hh_hours_type_neg3
rename hh_hours_type2 hh_hours_type_neg2
rename hh_hours_type3 hh_hours_type_neg1
rename housework_bkt0 housework_bkt_neg4
rename housework_bkt1 housework_bkt_neg3
rename housework_bkt2 housework_bkt_neg2
rename housework_bkt3 housework_bkt_neg1
rename earn_housework0 earn_housework_neg4
rename earn_housework1 earn_housework_neg3
rename earn_housework2 earn_housework_neg2
rename earn_housework3 earn_housework_neg1
rename either_head0 either_head_neg4
rename either_head1 either_head_neg3
rename either_head2 either_head_neg2
rename either_head3 either_head_neg1

forvalues s=4/16{ // okay, I think I need to do some duration finagling, so need to reset these
	local a = `s'-4
	rename hh_earn_type`s' hh_earn_type`a'
	rename hh_hours_type`s' hh_hours_type`a'
	rename housework_bkt`s' housework_bkt`a'
	rename earn_housework`s' earn_housework`a'
	rename either_head`s' either_head`a'
}

browse unique_id partner_id rel_start_all last_yr_observed duration status_gp* hh_earn_type* either_head*

forvalues b=0/11{
	local c = `b'+1
	replace hh_earn_type`b' = hh_earn_type`c' if hh_earn_type`b'==. & hh_earn_type`c'!=. & status_gp`b'==1 & status_gp`c'==1 & (either_head`b'==1 | either_head`c'==1) // replace off-year with next year's value if coupled
	replace hh_hours_type`b' = hh_hours_type`c' if hh_hours_type`b'==. & hh_hours_type`c'!=. & status_gp`b'==1 & status_gp`c'==1 & (either_head`b'==1 | either_head`c'==1)
	replace housework_bkt`b' = housework_bkt`c' if housework_bkt`b'==. & housework_bkt`c'!=. & status_gp`b'==1 & status_gp`c'==1 & (either_head`b'==1 | either_head`c'==1)
	replace earn_housework`b' = earn_housework`c' if earn_housework`b'==. & earn_housework`c'!=. & status_gp`b'==1 & status_gp`c'==1 & (either_head`b'==1 | either_head`c'==1)
}

gen duration_10=0
replace duration_10=1 if duration>=9

browse unique_id partner_id rel_start_all last_yr_observed duration status_gp* hh_earn_type* housework_bkt* if duration_10==1

// want to merge info on kid status PLUS dol - let's just do for hours of paid labor and unpaid labor separately
label define parent_paid_type 1 "no kids, dual" 2 "no kids, male BW" 3 "no kids, female BW" 4 "no kids, no earners" 5 "kids, dual" 6 "kids, male BW" 7 "kids, female BW" 8 "kids, no earners" 

forvalues d=0/12{
	gen parent_paid_type`d'=.
	replace parent_paid_type`d'=1 if children`d'==0 & hh_hours_type`d'==1 // no kids, dual
	replace parent_paid_type`d'=2 if children`d'==0 & hh_hours_type`d'==2 // no kids, male BW
	replace parent_paid_type`d'=3 if children`d'==0 & hh_hours_type`d'==3 // no kids, female BW
	replace parent_paid_type`d'=4 if children`d'==0 & hh_hours_type`d'==4 // no kids, no earners

	replace parent_paid_type`d'=5 if children`d'==1 & hh_hours_type`d'==1 // kids, dual
	replace parent_paid_type`d'=6 if children`d'==1 & hh_hours_type`d'==2 // kids, male BW
	replace parent_paid_type`d'=7 if children`d'==1 & hh_hours_type`d'==3 // kids, female BW
	replace parent_paid_type`d'=8 if children`d'==1 & hh_hours_type`d'==4 // kids, no earners
	
	label values parent_paid_type`d' parent_paid_type 
}

label define parent_unpaid_type 1 "no kids, dual" 2 "no kids, female HW" 3 "no kids, male HW" 4 "kids, dual" 5 "kids, female HW" 6 "kids, male HW"

forvalues d=0/12{
	gen parent_unpaid_type`d'=.
	replace parent_unpaid_type`d'=1 if children`d'==0 & housework_bkt`d'==1 // no kids, dual
	replace parent_unpaid_type`d'=2 if children`d'==0 & housework_bkt`d'==2 // no kids, female HW
	replace parent_unpaid_type`d'=3 if children`d'==0 & housework_bkt`d'==3 // no kids, male HW

	replace parent_unpaid_type`d'=4 if children`d'==1 & housework_bkt`d'==1 // kids, dual
	replace parent_unpaid_type`d'=5 if children`d'==1 & housework_bkt`d'==2 // kids, female HW
	replace parent_unpaid_type`d'=6 if children`d'==1 & housework_bkt`d'==3 // kids, male HW

	label values parent_unpaid_type`d' parent_unpaid_type 
}

save "$temp\compiled_couple_data_wide.dta", replace

********************************************************************************
**# attempt to summarize data
********************************************************************************
use "$temp\compiled_couple_data_wide.dta", clear

drop *_neg*
drop hh_earn_type11 hh_earn_type12 hh_hours_type11 hh_hours_type12 housework_bkt11 housework_bkt12 earn_housework11 earn_housework12

// all
putexcel set "$results/psid_life course dol", sheet(all) replace
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x'
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
	tab hh_hours_type`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x'
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
	tab housework_bkt`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x'
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x'
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}

**# just 10 years +
drop if duration_10==0

putexcel set "$results/psid_life course dol", sheet(10yrs) modify
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x'
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_hours_type`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x'
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
//	tab housework_bkt`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x'
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
//	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x'
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}

**# just 10 yrs + kid status (no kids)
putexcel set "$results/psid_life course dol", sheet(nokids) modify
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x' if children`s'==0
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_hours_type`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x' if children`s'==0
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
//	tab housework_bkt`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x' if children`s'==0
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
//	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x' if children`s'==0
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}

**# just 10 yrs + kid status (has kids)
putexcel set "$results/psid_life course dol", sheet(kids) modify
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x' if children`s'==1
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_hours_type`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x' if children`s'==1
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
//	tab housework_bkt`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x' if children`s'==1
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
//	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x' if children`s'==1
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}


**# combined parent view
putexcel set "$results/psid_life course dol", sheet(parental_status) modify
putexcel A3 = "Duration"
putexcel B1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:O1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel B2:E2 = "No Kids", merge border(bottom) hcenter bold
putexcel F2:I2 = "Kids", merge border(bottom) hcenter bold
putexcel J2:L2 = "No Kids", merge border(bottom) hcenter bold
putexcel M2:O2 = "Kids", merge border(bottom) hcenter bold

putexcel B3 = "Dual"
putexcel C3 = "Male BW"
putexcel D3 = "Female BW"
putexcel E3 = "No Earners"
putexcel F3 = "Dual"
putexcel G3 = "Male BW"
putexcel H3 = "Female BW"
putexcel I3 = "No Earners"
putexcel J3 = "Dual"
putexcel K3 = "Female HW"
putexcel L3 = "Male HW"
putexcel M3 = "Dual"
putexcel N3 = "Female HW"
putexcel O3 = "Male HW"


// Means
putexcel A4 = "Duration 0"
putexcel A5 = "Duration 1"
putexcel A6 = "Duration 2"
putexcel A7 = "Duration 3"
putexcel A8 = "Duration 4"
putexcel A9 = "Duration 5"
putexcel A10 = "Duration 6"
putexcel A11 = "Duration 7"
putexcel A12 = "Duration 8"
putexcel A13 = "Duration 9"
putexcel A14 = "Duration 10"


local colu "B C D E F G H I"

forvalues s=0/10{
	local row = `s' + 4
	tab parent_paid_type`s', gen(kidpaid`s'_)
	forvalues x=1/8{ 
		local col: word `x' of `colu'
		mean kidpaid`s'_`x'
		matrix kidpaid`s'_`x'= e(b)
		putexcel `col'`row' = matrix(kidpaid`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M N O"

forvalues s=0/10{
	local row = `s' + 4
	tab parent_unpaid_type`s', gen(kidhw`s'_)
	forvalues x=1/6{ 
		local col: word `x' of `colu'
		mean kidhw`s'_`x'
		matrix kidhw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(kidhw`s'_`x'), nformat(#.#%)
	}
}

