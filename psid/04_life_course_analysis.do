
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: life_course_analysis
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files actually conducts the analysis

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
	forvalues y=1969/1987{
		drop `var'_`y'
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

reshape long MARITAL_PAIRS_ in_sample_ relationship_ MARITAL_PAIRS_sp_ in_sample_sp_ relationship_sp_ , ///
 i(unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX SEX_sp) j(survey_yr)

label values SEX_sp ER32000L
 
browse unique_id partner_id SEX SEX_sp in_sample_ in_sample_sp MARITAL_PAIRS_  MARITAL_PAIRS_sp_
tab MARITAL_PAIRS_ if in_sample_==1 & in_sample_sp_==1 // what to do if both in sample, but not identified as spouse? this isn't just married is it? I don't think tso? oh is it bc of FIRST yr cohabitors?
tab MARITAL_PAIRS_sp_ if in_sample_==1 & in_sample_sp_==1 // what to do if both in sample, but not identified as spouse? this isn't just married is it? I don't think tso?
 
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

// browse unique_id partner_id survey_yr rel_start_all last_yr_observed in_sample_ in_sample_sp_  relationship_ relationship_sp_ pair pair_sp if status==.

gen duration = survey_yr - rel_start_all
browse unique_id partner_id survey_yr rel_start_all duration last_yr_observed in_sample_ in_sample_sp_  relationship_ relationship_sp_ pair pair_sp

// want to reshape on duration. 
tab duration, m
keep if duration >=-5 // keep up to 5 years prior, jic
keep if duration <=22 // up to 20 for now - but adding two extra years so I can do the lookups below and still retain up to 20

gen duration_rec=duration+5  // negatives won't work in reshape - so make -5 0
/*
replace duration_rec = 95 if duration==-5
replace duration_rec = 96 if duration==-4
replace duration_rec = 97 if duration==-3
replace duration_rec = 98 if duration==-2
replace duration_rec = 99 if duration==-1
*/

drop MARITAL_PAIRS_ MARITAL_PAIRS_sp_ survey_yr duration

reshape wide coupled_in_sample single_in_sample_wom single_in_sample_man single_in_sample_both not_in_sample status in_sample_ relationship_ in_sample_sp_ relationship_sp_ pair pair_sp, i(unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX SEX_sp) j(duration_rec)

browse unique_id partner_id rel_start_all last_yr_observed status*
browse in_sample_15 in_sample_sp_15 status15

forvalues s=0/27{
	replace status`s'=5 if status`s'==.
}

label define status_x 0 "True Missing" 1 "Coupled" 2 "Single Woman" 3 "Single Man Only" 4 "Off year" 5 "Censored" // put both in women heree. will make this better in another variable.

forvalues s=0/27{
	gen status_x`s'=.
	replace status_x`s'=0 if status`s'==0
	replace status_x`s'=1 if status`s'==1
	replace status_x`s'=2 if inlist(status`s',2,4)
	replace status_x`s'=3 if status`s'==3
	replace status_x`s'=4 if status`s'==5
	label values status_x`s' status_x
}

gen duration=last_yr_observed-rel_start_all
browse unique_id partner_id rel_start_all last_yr_observed duration status_x*

// just replacing the missings

forvalues b=1/26{
	local a = `b'-1
	local c = `b'+1
	replace status_x`b' = 0 if status_x`a'==0 & status_x`c'==0 & status_x`b'==4 // so is status is off year, but both sides are missing, call this missing
}

forvalues b=1/26{
	local a = `b'-1
	local c = `b'+1
	replace status_x`b' = 5 if status_x`a'==4 & status_x`c'==4 & status_x`b'==4 // so if it becomes all off-years, this actually means censored.
}

forvalues b=1/26{
	local a = `b'-1
	local c = `b'+1
	replace status_x`b' = 5 if status_x`a'==5 & status_x`c'==5 & status_x`b'==4 // not working for all so if off-year till surrounded by censored, this is censored
}

// now let's attempt to fill in all of the off-year data, create new variable for reference
forvalues s=0/27{
	gen status_gp`s'=status_x`s'
	label values status_gp`s' status_x
}

forvalues b=1/26{
	local a = `b'-1
	local c = `b'+1
	replace status_gp`b' = 1 if status_x`b'==4 & status_x`a'==1 & status_x`c'==1 // replace off-year with coupled if both years around are coupled
	replace status_gp`b' = 2 if status_x`b'==4 & status_x`a'==2 & status_x`c'==2 // repeat for all
	replace status_gp`b' = 3 if status_x`b'==4 & status_x`a'==3 & status_x`c'==3 // repeat for all
}

rename status_gp0 status_gp_neg5
rename status_gp1 status_gp_neg4
rename status_gp2 status_gp_neg3
rename status_gp3 status_gp_neg2
rename status_gp4 status_gp_neg1

forvalues s=5/27{ // okay, I think I need to do some duration finagling, so need to reset these
	local a = `s'-5
	rename status_gp`s' status_gp`a'
}

browse unique_id partner_id rel_start_all last_yr_observed duration status_gp*

forvalues b=0/21{
	local c = `b'+1
	replace status_gp`b' = status_gp`c' if duration < `b' & status_gp`b'==4
}

save "$created_data\couple_duration_matrix.dta", replace

// want to do some data checks
egen coupled_years = anycount(status_gp*), values(1)
browse unique_id partner_id rel_start_all last_yr_observed duration coupled_years status_gp*
gen percent_tracked = coupled_years / (duration+1)

gen match=0
replace match=1 if percent_tracked==1

gen match_x=0
replace match_x=1 if percent_tracked>=0.75000 & percent_tracked!=.

sum percent_tracked, detail

gen duration_10=0
replace duration_10=1 if duration>=9

sum percent_tracked if duration_10==1, detail
tab match if duration_10==1
tab match_x if duration_10==1

sum duration

********************************************************************************
**# attempt to export data
********************************************************************************
// detailed
putexcel set "$results/sample_matrix", sheet(detailed) replace
putexcel B1 = "True Missing"
putexcel C1 = "Coupled"
putexcel D1 = "Single Woman"
putexcel E1 = "Single Man Only"
putexcel F1 = "Off-year"
putexcel G1 = "Censored"

// Means
putexcel A2 = "Duration -5"
putexcel A3 = "Duration -4"
putexcel A4 = "Duration -3"
putexcel A5 = "Duration -2"
putexcel A6 = "Duration -1"
putexcel A7 = "Duration 0"
putexcel A8 = "Duration 1"
putexcel A9 = "Duration 2"
putexcel A10 = "Duration 3"
putexcel A11 = "Duration 4"
putexcel A12 = "Duration 5"
putexcel A13 = "Duration 6"
putexcel A14 = "Duration 7"
putexcel A15 = "Duration 8"
putexcel A16 = "Duration 9"
putexcel A17 = "Duration 10"
putexcel A18 = "Duration 11"
putexcel A19 = "Duration 12"
putexcel A20 = "Duration 13"
putexcel A21 = "Duration 14"
putexcel A22 = "Duration 15"
putexcel A23 = "Duration 16"
putexcel A24 = "Duration 17"
putexcel A25 = "Duration 18"
putexcel A26 = "Duration 19"
putexcel A27 = "Duration 20"


local colu "B D E F" // can't be single or coupled in first years

forvalues s=0/4{
	local row = `s' + 2
	tab status_x`s', gen(s`s'_)
	forvalues x=1/4{
		local col: word `x' of `colu'
		mean s`s'_`x'
		matrix s`s'_`x'= e(b)
		putexcel `col'`row' = matrix(s`s'_`x'), nformat(#.#%)
	}
}

local colu "B C D E F G"

forvalues s=5/16{
	local row = `s' + 2
	tab status_x`s', gen(s`s'_)
	forvalues x=1/5{ // censor doesn't appear until 12 (aka 17)
		local col: word `x' of `colu'
		mean s`s'_`x'
		matrix s`s'_`x'= e(b)
		putexcel `col'`row' = matrix(s`s'_`x'), nformat(#.#%)
	}
}

forvalues s=17/25{
	local row = `s' + 2
	tab status_x`s', gen(s`s'_)
	forvalues x=1/6{
		local col: word `x' of `colu'
		mean s`s'_`x'
		matrix s`s'_`x'= e(b)
		putexcel `col'`row' = matrix(s`s'_`x'), nformat(#.#%)
	}
}

// cleaned up
putexcel set "$results/sample_matrix", sheet(cleaned) modify
putexcel B1 = "True Missing"
putexcel C1 = "Coupled"
putexcel D1 = "Single Woman"
putexcel E1 = "Single Man Only"
putexcel F1 = "Off-year"
putexcel G1 = "Censored"

// Means
putexcel A2 = "Duration -1"
putexcel A3 = "Duration -2"
putexcel A4 = "Duration -3"
putexcel A5 = "Duration -4"
putexcel A6 = "Duration -5"
putexcel A7 = "Duration 0"
putexcel A8 = "Duration 1"
putexcel A9 = "Duration 2"
putexcel A10 = "Duration 3"
putexcel A11 = "Duration 4"
putexcel A12 = "Duration 5"
putexcel A13 = "Duration 6"
putexcel A14 = "Duration 7"
putexcel A15 = "Duration 8"
putexcel A16 = "Duration 9"
putexcel A17 = "Duration 10"
putexcel A18 = "Duration 11"
putexcel A19 = "Duration 12"
putexcel A20 = "Duration 13"
putexcel A21 = "Duration 14"
putexcel A22 = "Duration 15"
putexcel A23 = "Duration 16"
putexcel A24 = "Duration 17"
putexcel A25 = "Duration 18"
putexcel A26 = "Duration 19"
putexcel A27 = "Duration 20"

local colu "B D E F" // can't be single or coupled in first years

forvalues s=1/5{
	local row = `s' + 1
	tab status_gp_neg`s', gen(sneg`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean sneg`s'_`x'
		matrix sneg`s'_`x'= e(b)
		putexcel `col'`row' = matrix(sneg`s'_`x'), nformat(#.#%)
	}
}

local colu "B C D E F G"

forvalues s=0/10{
	local row = `s' + 7
	tab status_gp`s', gen(sg`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean sg`s'_`x'
		matrix sg`s'_`x'= e(b)
		putexcel `col'`row' = matrix(sg`s'_`x'), nformat(#.#%)
	}
}

forvalues s=11/20{
	local row = `s' + 7
	tab status_gp`s', gen(sg`s'_)
	forvalues x=1/6{
		local col: word `x' of `colu'
		mean sg`s'_`x'
		matrix sg`s'_`x'= e(b)
		putexcel `col'`row' = matrix(sg`s'_`x'), nformat(#.#%)
	}
}

/* Come back to this - prior way of looking for couples
********************************************************************************
**# How many observations / couples do we have?
********************************************************************************

// did i observe it end?
bysort unique_id partner_id: egen ended = max(rel_end_pre)
tab rel_status ended, m // 1 = intact, the rest of rel status are not, except this is ONLY marriage not cohab.

// let's start with duration of 10
gen observation_10=0
replace observation_10=1 if inrange(dur,0,10) // bt this doesn't necessarily tell us they made it to 10, like if just 2 years, they'd still have observations

bysort unique_id partner_id: egen num_observations_10 = sum(observation_10)
sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr rel_start_all dur max_dur observation_10 num_observations_10 ended rel_status rel_end_pre // indicator that it ended in next year (aka not censored - not to account for thiss somehow too) rel_status, also?

unique unique_id partner_id //  20606
unique unique_id partner_id if dur==10 // 5144
unique unique_id partner_id if max_dur >=10 & max_dur!=. // 9364 - okay but we didn't observe WITHIN duration 10 for all of these - like if older marriages, it might be like durations 20+
unique unique_id partner_id if num_observations_10!=0 // 16678
unique unique_id partner_id if num_observations_10>2 // 10724

tab num_observations_10 if max_dur >=10 // maybe THIS?
unique unique_id if num_observations_10!=0 & max_dur >=10 // 6176
unique unique_id if num_observations_10>2 & max_dur >=10 // 5749 - so at least two observations?
unique unique_id if num_observations_10>=10 & max_dur >=10 // 2296 BUT not even possible to have 10 observations in 10 years once biennial?
tab num_observations_10 if max_dur >=10 & rel_start_all > 1990 & rel_start_all!=.

// okay time frame
unique unique_id partner_id if num_observations_10>2 & max_dur >=10 & rel_start_all > 1990 & rel_start_all!=. // 2349
unique unique_id partner_id if num_observations_10>=5 & max_dur >=10 & rel_start_all > 1990 & rel_start_all!=. // 2045
unique unique_id partner_id if rel_start_all > 1990 & rel_start_all!=. // 9000

// also, didn't observe dissolution?
unique unique_id partner_id if num_observations_10>2 & max_dur >=10 & rel_start_all > 1990 & rel_start_all!=. & ended==0 // 1874
unique unique_id partner_id if num_observations_10>=5 & max_dur >=10 & rel_start_all > 1990 & rel_start_all!=. & ended==0 // 1686
unique unique_id partner_id if rel_start_all > 1990 & rel_start_all!=. & ended==0 // 6054

// try to create flags to make the next part easier and help me validate that what is happening above is what i want
unique unique_id partner_id
 
gen post1990 = 0
replace post1990 = 1 if rel_start_all > 1990 & rel_start_all!=.
unique unique_id partner_id if post1990==1

gen post1990_intact = 0
replace post1990_intact = 1 if rel_start_all > 1990 & rel_start_all!=. & ended==0
unique unique_id partner_id if post1990_intact==1

gen post1990_2obs = 0
replace post1990_2obs = 1 if rel_start_all > 1990 & rel_start_all!=. & ended==0 & num_observations_10>2 & max_dur >=10 
unique unique_id partner_id if post1990_2obs==1

gen post1990_5obs = 0
replace post1990_5obs = 1 if rel_start_all > 1990 & rel_start_all!=. & ended==0 & num_observations_10>=5 & max_dur >=10 
unique unique_id partner_id if post1990_5obs==1

browse unique_id partner_id survey_yr rel_start_all dur max_dur ended num_observations_10 post1990*

********************************************************************************
**# Descriptive comparison
********************************************************************************
// quick recodes
replace AGE_REF_ =. if AGE_REF_==999
replace AGE_SPOUSE_ =. if AGE_SPOUSE_==999
replace age_mar_head = . if age_mar_head>1000
replace age_mar_wife = . if age_mar_wife>1000

recode race_head (1=1)(2=2)(3/7=3), gen(race_gp_head)
recode race_wife (1=1)(2=2)(3/7=3), gen(race_gp_wife)

tab educ_head, gen(educ_head)
tab educ_wife, gen(educ_wife)
tab educ_type, gen(educ_type)
tab ft_pt_head, gen(ft_pt_head)
tab ft_pt_wife, gen(ft_pt_wife)
tab race_gp_head, gen(race_gp_head)
tab race_gp_wife, gen(race_gp_wife)
tab marital_status_updated, gen(marital_status)
tab hh_earn_type, gen(hh_earn_type)
tab housework_bkt, gen(housework_bkt)

* all couples
sum dur // average duration
sum AGE_REF_ // his age
sum AGE_SPOUSE_ // her age
sum age_mar_head // his age at marriage
sum age_mar_wife // her age at marriage
tab educ_head // education: his
tab educ_wife // education: hers
tab educ_type // education: joint
tab ft_pt_head // lfp: hers
tab ft_pt_wife // lfp: his
tab race_gp_head // race: his
tab race_gp_wife // race: hers
sum same_race // same race
tab marital_status_updated // percentage married / cohab
tab hh_earn_type // paid DoL
tab housework_bkt // unpaid DoL
sum children
sum NUM_CHILDREN_ // number of children

* all couples post 1990: if post1990==1
* all couples post 1990 + did not dissolve: if post1990_intact==1
* all couples post 1990 + did not dissolve + lasted 10 years + observed at least twice in 10 years: if post1990_2obs==1
* all couples post 1990 + did not dissolve + lasted 10 years + observed at laest 5x in 10 years (bc of biennial): if post1990_5obs==1


putexcel set "$results/Sample_comparison", replace
putexcel B1 = "All couples"
putexcel C1 = "relation started 1990+"
putexcel D1 = "intact"
putexcel E1 = "lasted 10 years with 2 observation in first 10 yrs"
putexcel F1 = "lasted 10 years with 5 observation in first 10 yrs"

// Means
putexcel A2 = "Uniques"
putexcel A3 = "Couple-years"
putexcel A4 = "Average duration"
putexcel A5 = "His age"
putexcel A6 = "Her age"
putexcel A7 = "His age at marriage"
putexcel A8 = "Her age at marriage"
putexcel A9 = "His educ: LTHS"
putexcel A10 = "His educ: HS"
putexcel A11 = "His educ: Some College"
putexcel A12 = "His educ: College"
putexcel A13 = "Her educ: LTHS"
putexcel A14 = "Her educ: HS"
putexcel A15 = "Her educ: Some College"
putexcel A16 = "Her educ: College"
putexcel A17 = "Hypergamous"
putexcel A18 = "Hypogamous"
putexcel A19 = "Homogamous"
putexcel A20 = "His no work"
putexcel A21 = "His PT"
putexcel A22 = "His FT"
putexcel A23 = "Her no work"
putexcel A24 = "Her PT"
putexcel A25 = "Her FT"
putexcel A26 = "His race: White"
putexcel A27 = "His race: Black"
putexcel A28 = "His race: Other"
putexcel A29 = "Her race: White"
putexcel A30 = "Her race: Black"
putexcel A31 = "Her race: Other"
putexcel A32 = "% Same race"
putexcel A33 = "Married"
putexcel A34 = "Cohabiting"
putexcel A35 = "Paid DoL: Dual Earning HH"
putexcel A36 = "Paid DoL: Male Breadwinner"
putexcel A37 = "Paid DoL: Female Breadwinner"
putexcel A38 = "Paid DoL: No Earners"
putexcel A39 = "Unpaid DoL: Equal"
putexcel A40 = "Unpaid DoL: Female Primary"
putexcel A41 = "Unpaid DoL: Male Primary"
putexcel A42 = "Unpaid DoL: No HW"
putexcel A43 = "Couple has children"
putexcel A44 = "Average number of children"

local vars "dur AGE_REF_ AGE_SPOUSE_ age_mar_head age_mar_wife educ_head1 educ_head2 educ_head3 educ_head4 educ_wife1 educ_wife2 educ_wife3 educ_wife4 educ_type1 educ_type2 educ_type3 ft_pt_head1 ft_pt_head2 ft_pt_head3 ft_pt_wife1 ft_pt_wife2 ft_pt_wife3 race_gp_head1 race_gp_head2 race_gp_head3 race_gp_wife1 race_gp_wife2 race_gp_wife3 same_race marital_status1 marital_status2 hh_earn_type1 hh_earn_type2 hh_earn_type3 hh_earn_type4 housework_bkt1 housework_bkt2 housework_bkt3 housework_bkt4 children NUM_CHILDREN_"

* overall
forvalues w=1/41{
	local row=`w'+3
	local var: word `w' of `vars'
	mean `var'
	matrix t`var'= e(b)
	putexcel B`row' = matrix(t`var'), nformat(#.#%)
}

* all couples post 1990: if post1990==1
forvalues w=1/41{
	local row=`w'+3
	local var: word `w' of `vars'
	mean `var' if post1990==1
	matrix t`var'= e(b)
	putexcel C`row' = matrix(t`var'), nformat(#.#%)
}

* all couples post 1990 + did not dissolve: if post1990_intact==1
forvalues w=1/41{
	local row=`w'+3
	local var: word `w' of `vars'
	mean `var' if post1990_intact==1
	matrix t`var'= e(b)
	putexcel D`row' = matrix(t`var'), nformat(#.#%)
}

* all couples post 1990 + did not dissolve + lasted 10 years + observed at least twice in 10 years: if post1990_2obs==1
forvalues w=1/41{
	local row=`w'+3
	local var: word `w' of `vars'
	mean `var' if post1990_2obs==1
	matrix t`var'= e(b)
	putexcel E`row' = matrix(t`var'), nformat(#.#%)
}

* all couples post 1990 + did not dissolve + lasted 10 years + observed at laest 5x in 10 years (bc of biennial): if post1990_5obs==1
forvalues w=1/41{
	local row=`w'+3
	local var: word `w' of `vars'
	mean `var' if post1990_5obs==1
	matrix t`var'= e(b)
	putexcel F`row' = matrix(t`var'), nformat(#.#%)
}
*/