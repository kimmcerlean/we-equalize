
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

forvalues y=1969/1997{
	gen relationship_`y'=.
	replace relationship_`y'=0 if RELATION_`y'==0
	replace relationship_`y'=1 if inlist(RELATION_`y',1,10)
	replace relationship_`y'=2 if inlist(RELATION_`y',2,20,22,88)
	replace relationship_`y'=3 if inrange(RELATION_`y',23,87) | inrange(RELATION_`y',90,98) | inrange(RELATION_`y',3,9)
}

forvalues y=1999(2)2021{
	gen relationship_`y'=.
	replace relationship_`y'=0 if RELATION_`y'==0
	replace relationship_`y'=1 if inlist(RELATION_`y',1,10)
	replace relationship_`y'=2 if inlist(RELATION_`y',2,20,22,88)
	replace relationship_`y'=3 if inrange(RELATION_`y',23,87) | inrange(RELATION_`y',90,98) | inrange(RELATION_`y',3,9)
}

// browse unique_id in_sample_* relationship_* MARITAL_PAIRS_* HOUSEWORK_WIFE_* HOUSEWORK_HEAD_*
keep unique_id in_sample_* relationship_* MARITAL_PAIRS_* SEX EDUC1_WIFE_* EDUC1_HEAD_* EDUC_WIFE_* EDUC_HEAD_* LABOR_INCOME_WIFE_* WAGES_WIFE_* LABOR_INCOME_HEAD_* WAGES_HEAD_* TAXABLE_HEAD_WIFE_* WEEKLY_HRS1_WIFE_* WEEKLY_HRS_WIFE_* WEEKLY_HRS1_HEAD_* WEEKLY_HRS_HEAD_* HOUSEWORK_HEAD_* HOUSEWORK_WIFE_* TOTAL_HOUSEWORK_HW_* MOST_HOUSEWORK_* EMPLOY_STATUS_HEAD_* EMPLOY_STATUS1_HEAD_* EMPLOY_STATUS2_HEAD_* EMPLOY_STATUS3_HEAD_* EMPLOY_STATUS_WIFE_* EMPLOY_STATUS1_WIFE_* EMPLOY_STATUS2_WIFE_* EMPLOY_STATUS3_WIFE_* NUM_CHILDREN_* AGE_YOUNG_CHILD_* AGE_REF_* AGE_SPOUSE_*

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

foreach var in EDUC1_WIFE_ EDUC1_HEAD_ EDUC_WIFE_ EDUC_HEAD_ LABOR_INCOME_WIFE_ WAGES_WIFE_ LABOR_INCOME_HEAD_ WAGES_HEAD_ TAXABLE_HEAD_WIFE_ WEEKLY_HRS1_WIFE_ WEEKLY_HRS_WIFE_ WEEKLY_HRS1_HEAD_ WEEKLY_HRS_HEAD_ HOUSEWORK_HEAD_ HOUSEWORK_WIFE_ TOTAL_HOUSEWORK_HW_ MOST_HOUSEWORK_ EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ AGE_REF_ AGE_SPOUSE_{
	forvalues y=1968/1987{
		capture drop `var'`y' // in case var not in all years
	}
}

drop *_1968

save "$temp\partner_sample_info.dta", replace

********************************************************************************
**# Now match couples to survey data and try to figure out how long we can track, especially post-breakup
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

browse unique_id partner_id rel_start_all last_yr_observed SEX* in_sample*

save "$temp\couple_sample_details_wide.dta", replace

