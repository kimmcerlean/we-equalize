
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: get_couple_sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files gets the eligible couples for analysis

********************************************************************************
* Import data and small final sample cleanup
********************************************************************************
use "$created_data_psid\PSID_partners_cleaned.dta", clear
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

browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ partner_id id_ref id_wife rel_start_yr
sort unique_id survey_yr

// start to get data ready to deduplicate
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

// figuring out some missing relationship info
sort survey_yr FAMILY_INTERVIEW_NUM_  unique_id   
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_start_yr female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

gen has_rel_info=0
replace has_rel_info=1 if rel_start_yr!=.

bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_info = max(has_rel_info)
bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_start_yr_couple = min(rel_start_yr) // can i fill in the missing partner's data?

sort unique_id partner_id survey_yr
browse unique_id partner_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_info has_rel_info rel_start_yr rel_start_yr_couple female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

// think I need to fix duration because for some, I think clock might start again when they transition to cohabitation? get minimum year within a couple as main start date?
sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr rel_start_yr marital_status_updated relationship_duration

bysort unique_id partner_id: egen rel_start_all = min(rel_start_yr_couple)
gen dur=survey_yr - rel_start_all
browse unique_id partner_id survey_yr rel_start_all rel_start_yr_couple marital_status_updated dur relationship_duration rel_rank_est count_rel_est rel_number

tab dur, m
tab relationship_duration, m
unique unique_id partner_id, by(marital_status_updated)

// should I restrict to certain years? aka to help with the cohab problem? well probably should from a time standpoint... and to match to the british one, at least do 1990+?
tab survey_yr marital_status_updated
tab rel_start_yr marital_status_updated, m

unique unique_id
unique unique_id if rel_start_yr_couple >= 1990 // nearly half of sample goes away. okay let's decide later...
unique unique_id if rel_start_all >= 1990 // nearly half of sample goes away. okay let's decide later...
unique unique_id if rel_start_yr_couple >= 1980 // compromise with 1980? ugh idk
* we want to keep people who started after 1990, who we observed their start, and who started before 2011, so we have 10 years of observations
* first, min and max duration
bysort unique_id partner_id: egen min_dur = min(dur)
bysort unique_id partner_id: egen max_dur = max(dur)
bysort unique_id partner_id: egen last_yr_observed = max(survey_yr)

browse unique_id partner_id survey_yr rel_start_all rel_end_yr relationship_duration min_dur max_dur
keep if rel_start_all >= 1990 & inlist(min_dur,0,1)
keep if rel_start_all <= 2011

// restrict to working age?
tab AGE_HEAD_ employed_t1_head, row
keep if (AGE_HEAD_>=18 & AGE_HEAD_<=60) &  (AGE_WIFE_>=18 & AGE_WIFE_<=60) // sort of drops off a cliff after 60?

// did i observe it end?
bysort unique_id partner_id: egen ended = max(rel_end_pre)
sort unique_id partner_id survey_yr

browse unique_id partner_id survey_yr rel_start_all rel_end_yr last_yr_observed rel_status ended relationship_duration min_dur max_dur // these rel_end rel_status only cover marriage not cohab bc from marital history

********************************************************************************
**# get NON-deduped list of couples to match their info on later
********************************************************************************

unique unique_id partner_id

preserve

collapse (first) rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended, by(unique_id partner_id)

save "$created_data\couple_list_individ.dta", replace

restore

********************************************************************************
**# get deduped list of couples to match their info on later
********************************************************************************

* first drop the partner WITHOUT rel info if at least one of them does
drop if has_rel_info==0 & rel_info==1

*then rank the remaining members
bysort survey_yr FAMILY_INTERVIEW_NUM_ : egen per_id = rank(unique_id) // so if there is only one member left after above, will get a 1
browse survey_yr FAMILY_INTERVIEW_NUM_  unique_id per_id

tab per_id // 1s should approximately total above

keep if per_id==1

tab marital_status_updated // won't match above anymore bc removed lots of people
unique unique_id partner_id

preserve

collapse (first) rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended, by(unique_id partner_id)

save "$created_data\couple_list.dta", replace

restore

********************************************************************************
* do some QA checks using this couple information to compare to later matrix
********************************************************************************

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
