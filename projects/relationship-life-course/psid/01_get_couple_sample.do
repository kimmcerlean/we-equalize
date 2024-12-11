
********************************************************************************
* Project: Relationship Life Course Analysis
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
// browse if inlist(unique_id, 16032, 16176)

// first create partner ids before I drop partners
gen id_ref=.
replace id_ref = unique_id if inlist(RELATION_,1,10) & SEQ_NUMBER_==1
replace id_ref = unique_id if inlist(RELATION_,1,10) & survey_yr==1968
bysort survey_yr FAMILY_INTERVIEW_NUM_ (id_ref): replace id_ref = id_ref[1]

gen id_wife=.
replace id_wife = unique_id if inlist(RELATION_,2,20,22) & SEQ_NUMBER_==2
replace id_wife = unique_id if inlist(RELATION_,2,20,22) & survey_yr==1968
bysort survey_yr FAMILY_INTERVIEW_NUM_ (id_wife): replace id_wife = id_wife[1]

sort unique_id survey_yr
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr RELATION_ id_ref id_wife

gen partner_id_v1=.
replace partner_id_v1 = id_ref if inlist(RELATION_,2,20,22) & SEQ_NUMBER_==2 // so need opposite id
replace partner_id_v1 = id_ref if inlist(RELATION_,2,20,22) & survey_yr==1968 // so need opposite id
replace partner_id_v1 = id_wife if inlist(RELATION_,1,10) & SEQ_NUMBER_==1
replace partner_id_v1 = id_wife if inlist(RELATION_,1,10) & survey_yr==1968

// okay,I think this is actually flawed, see what happens when I use marital pairs? Except, most are in couple 1? so is maybe not necessary
tab MARITAL_PAIRS_,m 

gen id_mp1_m=.
replace id_mp1_m= unique_id if SEX==1 & MARITAL_PAIRS_==1
gen id_mp1_w=.
replace id_mp1_w=unique_id if SEX==2 & MARITAL_PAIRS_==1

gen id_mp2_m=.
replace id_mp2_m= unique_id if SEX==1 & MARITAL_PAIRS_==2
gen id_mp2_w=.
replace id_mp2_w=unique_id if SEX==2 & MARITAL_PAIRS_==2

gen id_mp3_m=.
replace id_mp3_m= unique_id if SEX==1 & MARITAL_PAIRS_==3
gen id_mp3_w=.
replace id_mp3_w=unique_id if SEX==2 & MARITAL_PAIRS_==3


foreach var in id_mp1_m id_mp1_w id_mp2_m id_mp2_w id_mp3_m id_mp3_w{
	bysort survey_yr FAMILY_INTERVIEW_NUM_ (`var'): replace `var' = `var'[1]
}

gen partner_id_v2=.
replace partner_id_v2=id_mp1_w if SEX==1 & MARITAL_PAIRS_==1
replace partner_id_v2=id_mp1_m if SEX==2 & MARITAL_PAIRS_==1
replace partner_id_v2=id_mp2_w if SEX==1 & MARITAL_PAIRS_==2
replace partner_id_v2=id_mp2_m if SEX==2 & MARITAL_PAIRS_==2
replace partner_id_v2=id_mp3_w if SEX==1 & MARITAL_PAIRS_==3
replace partner_id_v2=id_mp3_m if SEX==2 & MARITAL_PAIRS_==3

browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEQ_NUMBER_ partner_id_v1 partner_id_v2  RELATION_ MARITAL_PAIRS_ id_ref id_wife id_mp1_m id_mp1_w id_mp2_m id_mp2_w id_mp3_m id_mp3_w rel_start_yr
sort unique_id survey_yr

gen id_check=.
replace id_check=0 if partner_id_v1!=partner_id_v2
replace id_check=1 if partner_id_v1==partner_id_v2 & partner_id_v1!=. & partner_id_v2!=.

gen partner_id=partner_id_v2
replace partner_id=partner_id_v1 if partner_id==.

egen couple_id = group(unique_id partner_id)

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
tab rel_start_yr SEX, m // is either one's data more reliable? I tink I fixed this in previous step

// figuring out some missing relationship info
sort survey_yr FAMILY_INTERVIEW_NUM_  unique_id   
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_start_yr female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

gen has_rel_info=0
replace has_rel_info=1 if rel_start_yr!=.

bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_info = max(has_rel_info)
bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_start_yr_couple = min(rel_start_yr) // can i fill in the missing partner's data?
bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_end_yr_couple = min(rel_end_yr) // can i fill in the missing partner's data?

sort unique_id partner_id survey_yr
browse unique_id partner_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_info has_rel_info rel_start_yr rel_start_yr_couple rel_end_yr rel_end_yr_couple female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

// think I need to fix duration because for some, I think clock might start again when they transition to cohabitation? get minimum year within a couple as main start date?
sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr rel_start_yr_couple rel_end_yr_couple marital_status_updated relationship_duration

bysort unique_id partner_id: egen rel_start_all = min(rel_start_yr_couple)
gen dur=survey_yr - rel_start_all
bysort unique_id partner_id: egen rel_end_all = max(rel_end_yr_couple)

tab dur, m
tab relationship_duration, m
unique unique_id partner_id, by(marital_status_updated)

// trying to fill in missing end dates and status, at least for the relevant sample here
label define rel_status 1 "Intact" 3 "Widow" 4 "Divorce" 5 "Separated" 6 "Attrited"
label values rel_status mh_status* rel_status

gen rel_end_all_orig = rel_end_all // let's retain the original with missing, and I'll work on filling in a new version below based on attrition info
gen rel_status_orig = rel_status

inspect rel_end_all if rel_start_all >=1990
inspect rel_status if rel_start_all >=1990
tab rel_end_all rel_status if rel_start_all >=1990, m col
tab rel_end_all marital_status_updated if rel_start_all >=1990, m col // is this largely cohab?
tab rel_status marital_status_updated if rel_start_all >=1990, m col

	*if observed as partnered in 2021, will put end date as 9999 and consider intact
	gen observed_2021 = .
	replace observed_2021 = 1 if survey_yr==2021
	bysort unique_id partner_id (observed_2021): replace observed_2021 = observed_2021[1]
	// browse unique_id partner_id survey_yr observed_2021 rel_start_all rel_end_all rel_status
	replace rel_end_all=9999 if observed_2021 == 1 & rel_end_all==.
	replace rel_status=1 if observed_2021 == 1 & rel_status==.
	* their years of nonresponse are not accurate if died, so will update with mine for that
	replace rel_end_all=last_survey_yr if permanent_attrit == 2 & rel_end_all==.
	replace rel_status=3 if permanent_attrit == 2 & rel_status==.
	replace rel_end_all=last_survey_yr if permanent_attrit == 1 & rel_end_all==.
	replace rel_status=6 if permanent_attrit == 1 & rel_status==.
	* so, want to update rel_end_all with attrition year if they attrited and we don't know what happened (even though pernament attrit not labeled)
	replace rel_end_all=last_survey_yr if rel_end_all==.
	replace rel_status=6 if rel_status==. // these people left over are definitely attrition ftm

sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr dur marital_status_updated rel_start_all rel_end_all rel_status rel_start_yr_couple rel_end_yr_couple dur relationship_duration mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 YR_NONRESPONSE_RECENT YR_NONRESPONSE_FIRST last_survey_yr permanent_attrit ANY_ATTRITION MOVED_ MOVED_YEAR_ SEQ_NUMBER_ if rel_start_all >=1990 & rel_end_all==.

tab rel_status marital_status_updated if rel_start_all >=1990, m col  // I think some people who are married but intact might actually be attrition? For cohab, that was obvious, because I didn't have the end date to use from history. leave for now, but perhaps update in later stage
tab last_survey_yr if rel_end_all==9999, m // so, about half are in intact AND in the last survey yr
browse unique_id partner_id survey_yr dur marital_status_updated rel_start_all rel_end_all rel_status last_survey_yr RELATION_ if rel_start_all >=1990 & rel_end_all==9999

// want to create at time-constant indicator of relationship type
bysort unique_id partner_id (marr_trans): egen ever_transition = max(marr_trans)
gen rel_type_constant=.
replace rel_type_constant = 1 if ever_transition==0 & marital_status_updated==1
replace rel_type_constant = 2 if ever_transition==0 & marital_status_updated==2
replace rel_type_constant = 3 if ever_transition==1

label define rel_type_constant 1 "Married" 2 "Cohab" 3 "Transitioned"
label values rel_type_constant rel_type_constant
tab rel_type_constant,m 
quietly unique rel_type_constant, by(couple_id)
bysort couple_id (_Unique): replace _Unique = _Unique[1]
tab _Unique, m
replace rel_type_constant=3 if _Unique==2

// and an indicator of year transitioned from cohab to marriage for later
browse unique_id partner_id survey_yr rel_start_all marital_status_updated marr_trans
gen transition_yr = survey_yr if marr_trans == 1 // this is the year they are married; year prior is partnered
bysort unique_id partner_id (transition_yr): replace transition_yr = transition_yr[1]

gen transition_yr_est = .
forvalues m=1/9{
	replace transition_yr_est = mh_yr_married`m' if rel_type_constant==3 & marital_status_updated==1 & survey_yr >=mh_yr_married`m' & survey_yr <=mh_yr_end`m'
}

bysort unique_id partner_id (transition_yr_est): replace transition_yr_est = transition_yr_est[1]

tab transition_yr rel_type_constant, m
tab transition_yr_est rel_type_constant if rel_start_all > 1990, m col

replace transition_yr_est = transition_yr if rel_type_constant==3 & transition_yr_est==. // this is more accurate if it occurs in non-survey year

browse unique_id partner_id survey_yr rel_start_all marital_status_updated marr_trans transition_yr transition_yr_est mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 if rel_type_constant==3 & transition_yr_est==. & rel_start_all > 1990 // these seem to be people actually partnered the whole time?

// unique unique_id partner_id
// unique unique_id partner_id rel_type_constant
// browse unique_id partner_id survey_yr rel_type_constant marital_status_updated ever_transition marr_trans if _Unique==2

// should I restrict to certain years? aka to help with the cohab problem? well probably should from a time standpoint... and to match to the british one, at least do 1990+?
tab survey_yr marital_status_updated
tab rel_start_yr marital_status_updated, m

* we want to keep people who started after 1990, who we observed their start, and who started before 2011, so we have 10 years of observations
* first, min and max duration
bysort unique_id partner_id: egen min_dur = min(dur)
bysort unique_id partner_id: egen max_dur = max(dur)
bysort unique_id partner_id: egen last_yr_observed = max(survey_yr)

browse unique_id partner_id survey_yr SEQ_NUMBER_ main_fam_id FAMILY_INTERVIEW_NUM_ min_dur max_dur rel_start_all rel_start_yr_couple rel_start_yr RELATION_ MARITAL_PAIRS_   if inlist(unique_id, 16032, 16170, 16176)

browse unique_id partner_id survey_yr rel_start_all rel_end_all last_yr_observed relationship_duration min_dur max_dur 
keep if rel_start_all >= 1990 & inlist(min_dur,0,1) // keeping up to two, because if got married in 2001, say, might not appear in survey until 2003, which is a problem. 
keep if rel_start_all <= 2011

// restrict to working age?
tab AGE_HEAD_ employed_t1_head, row
keep if (AGE_HEAD_>=18 & AGE_HEAD_<=60) &  (AGE_WIFE_>=18 & AGE_WIFE_<=60) // sort of drops off a cliff after 60?

// did i observe it end?
bysort unique_id partner_id: egen ended = max(rel_end_pre)
sort unique_id partner_id survey_yr

browse unique_id partner_id survey_yr rel_type_constant rel_start_all rel_end_all last_yr_observed rel_status ended relationship_duration min_dur max_dur // these rel_end rel_status only cover marriage not cohab bc from marital history
tab min_dur rel_type_constant, col // this is the problem. for cohab, I need to make a choice. if not married in 2001, and appear married 2003, and I don't have other info, which date do I use? i was using the earlier date because that seems to align with HH info? but I feel like it's maybe the off year? which I don't always know?

// make sure couple info is unique one last time
unique unique_id partner_id
unique unique_id partner_id rel_start_all rel_end_all // okay, so rel_status is the problem - duh KIM - for people hwo transitioned from cohab to marriage
unique unique_id partner_id rel_start_all rel_end_all rel_status 

quietly unique rel_start_all rel_end_all rel_status, by(couple_id) gen(info_count)
bysort couple_id (info_count): replace info_count = info_count[1]

tab rel_type_constant info_count

bysort unique_id partner_id: egen max_rel_status = max (rel_status_orig)
replace rel_status = max_rel_status if info_count> 1

sort unique_id partner_id survey
browse unique_id partner_id survey_yr marital_status_updated rel_start_all rel_end_all rel_status rel_status_orig max_rel_status rel_type_constant min_dur max_dur last_yr_observed ended transition_yr_est info_count if info_count > 1


********************************************************************************
**# get NON-deduped list of couples to match their info on later
********************************************************************************
preserve

collapse (first) rel_start_all rel_end_all rel_status rel_type_constant min_dur max_dur last_yr_observed ended transition_yr_est, by(unique_id partner_id)

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

collapse (first) rel_start_all rel_end_all rel_status rel_type_constant min_dur max_dur last_yr_observed ended transition_yr_est, by(unique_id partner_id)

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
