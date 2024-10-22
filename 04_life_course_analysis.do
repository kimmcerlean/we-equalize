
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


// should I restrict to certain years? aka to help with the cohab problem? well probably should from a time standpoint... and to match to the british one, at least do 1990+?
tab survey_yr marital_status_updated
tab rel_start_yr marital_status_updated, m

unique unique_id
unique unique_id if rel_start_yr >= 1990 // nearly half of sample goes away. okay let's decide later...
unique unique_id if rel_start_yr >= 1980 // compromise with 1980? ugh idk
* we want to keep people who started after 1990, who we observed their start, and who started before 2011, so we have 10 years of observations
* first, min and max duration
bysort unique_id partner_id: egen min_dur = min(dur)
bysort unique_id partner_id: egen max_dur = max(dur)

browse unique_id partner_id survey_yr rel_start_yr relationship_duration min_dur max_dur
keep if rel_start_yr >= 1990 & inlist(min_dur,0,1)
keep if rel_start_yr <= 2011

// restrict to working age?
tab AGE_REF_ employed_ly_head, row
keep if (AGE_REF_>=18 & AGE_REF_<=60) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=60) // sort of drops off a cliff after 60?

// think I need to fix duration because for some, I think clock might start again when they transition to cohabitation? get minimum year within a couple as main start date?
sort unique_id partner_id survey_yr
browse unique_id partner_id survey_yr rel_start_yr marital_status_updated relationship_duration

bysort unique_id partner_id: egen rel_start_all = min(rel_start_yr)
gen dur=survey_yr - rel_start_all
browse unique_id partner_id survey_yr rel_start_all rel_start_yr marital_status_updated dur relationship_duration rel_rank_est count_rel_est rel_number

tab dur, m
tab relationship_duration, m
unique unique_id partner_id, by(marital_status_updated)

// get deduped list of couples to match their info on later
preserve

collapse (first) rel_start_yr min_dur max_dur, by(unique_id partner_id)

save "$created_data\couple_list.dta", replace

restore

********************************************************************************
**# Now get survey history for these couples from main file
********************************************************************************


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
