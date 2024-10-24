********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: c_create_total_sample.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* create file used to track DoL variables over time
* Consider age restrictions based on who answers the relevant questions

use "$outputpath/UKHLS_matched.dta", clear // okay file I created at end of step b has ALL people and their potential partner matches, even if not partnered, so use this to start.
unique pidp // 109651, 772472 total py
unique pidp partner_id // 126305	
unique pidp, by(sex) // 52397 m, 57362 w
unique pidp, by(partnered) // 55858 0, 68410 1

tab partnered partner_match, m
// tabstat jbhrs, by(age_all) // is there an age before which they don't ask these questions? I guess, the age of the survey respondents is only 15+, so I guess not; they seem to ask everyone

sort pidp year
browse pidp year partnered partner_id partner_match sex sex_sp howlng howlng_sp jbhrs jbhrs_sp  hubuys hubuys_sp age_all age_all_sp 

tab sex sex_sp, m
drop if sex==1 & sex_sp==1 // get rid of same gender?
drop if sex==2 & sex_sp==2
drop if inlist(sex,-9,0)
drop if inlist(sex_sp,-9,0)

********************************************************************************
* Create gendered versions of all key variables
********************************************************************************
local individ_vars "psu strata jbstat aidhh aidxhh aidhrs jbhas jbhrs jbot jbotpd jbttwt howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv nchild_dv rach16_dv hiqual_dv hubuys hufrys humops huiron husits huboss age_all dob_year college_degree country_all  marital_status_legal marital_status_defacto partnered employed total_hours race_use mh_status1 mh_starty1 mh_startm1 mh_endy1 mh_endm1 mh_divorcey1 mh_divorcem1 mh_mrgend1 mh_cohend1 mh_status2 mh_starty2 mh_startm2 mh_endy2 mh_endm2 mh_divorcey2 mh_divorcem2 mh_mrgend2 mh_cohend2 mh_ongoing2 mh_status3 mh_starty3 mh_startm3 mh_endy3 mh_endm3 mh_divorcey3 mh_divorcem3 mh_mrgend3 mh_cohend3 mh_ongoing3 mh_status4 mh_starty4 mh_startm4 mh_endy4 mh_endm4 mh_divorcey4 mh_divorcem4 mh_mrgend4 mh_cohend4 mh_ongoing4 mh_status5 mh_starty5 mh_startm5 mh_endy5 mh_endm5 mh_divorcey5 mh_divorcem5 mh_mrgend5 mh_cohend5 mh_ongoing5 mh_status6 mh_starty6 mh_startm6 mh_endy6 mh_endm6 mh_divorcey6 mh_divorcem6 mh_mrgend6 mh_cohend6 mh_ongoing6 mh_status7 mh_starty7 mh_startm7 mh_endy7 mh_endm7 mh_divorcey7 mh_divorcem7 mh_mrgend7 mh_cohend7 mh_ongoing7 mh_status8 mh_starty8 mh_startm8 mh_endy8 mh_endm8 mh_divorcey8 mh_divorcem8 mh_mrgend8 mh_cohend8 mh_ongoing8 mh_status9 mh_starty9 mh_startm9 mh_endy9 mh_endm9 mh_divorcey9 mh_divorcem9 mh_mrgend9 mh_cohend9 mh_ongoing9 mh_status10 mh_starty10 mh_startm10 mh_endy10 mh_endm10 mh_divorcey10 mh_divorcem10 mh_mrgend10 mh_cohend10 mh_ongoing10 mh_status11 mh_starty11 mh_startm11 mh_endy11 mh_endm11 mh_divorcey11 mh_divorcem11 mh_mrgend11 mh_cohend11 mh_ongoing11 mh_status12 mh_starty12 mh_startm12 mh_endy12 mh_endm12 mh_divorcey12 mh_divorcem12 mh_mrgend12 mh_cohend12 mh_ongoing12 mh_status13 mh_starty13 mh_startm13 mh_endy13 mh_endm13 mh_divorcey13 mh_divorcem13 mh_mrgend13 mh_cohend13 mh_ongoing13 mh_status14 mh_starty14 mh_startm14 mh_endy14 mh_endm14 mh_divorcey14 mh_divorcem14 mh_mrgend14 mh_cohend14 mh_ongoing14 mh_ttl_married mh_ttl_civil_partnership mh_ttl_cohabit mh_ever_married mh_ever_civil_partnership mh_ever_cohabit mh_lastintdate mh_lastinty mh_lastintm mh_hhorig rel_no current_rel_start_year current_rel_start_month current_rel_end_year current_rel_end_month current_rel_ongoing current_rel_marr_end current_rel_coh_end indinub_xw indinus_xw indinus_lw indinub_lw"

local individ_long "mh_partner1 mh_partner2 mh_partner3 mh_partner4 mh_partner5 mh_partner6 mh_partner7 mh_partner8 mh_partner9 mh_partner10 mh_partner11 mh_partner12 mh_partner13 mh_partner14"

local hhvars "hhsize fihhmngrs_dv hrpid ncouple_dv nkids_dv nch02_dv nch34_dv nch511_dv nch1215_dv agechy_dv npens_dv nemp_dv tenure_dv nchild_015 hhdenus_xw hhdenub_xw"

foreach var in `individ_vars'{
	gen `var'_wom = `var' if sex==2
	replace `var'_wom = `var'_sp if sex==1 & sex_sp==2 // this will ensure they have a match?
	
	gen `var'_man = `var' if sex==1
	replace `var'_man = `var'_sp if sex==2 & sex_sp==1
}

foreach var in `individ_long'{
	gen long `var'_wom = `var' if sex==2
	replace `var'_wom = `var'_sp if sex==1 & sex_sp==2
	
	gen long `var'_man = `var' if sex==1
	replace `var'_man = `var'_sp if sex==2 & sex_sp==1
}


// then denote some variables as HH specific for reference
foreach var in `hhvars'{
	rename `var' `var'_hh
}

// for ease, let's just keep these core variables - so drop original versions of above as well as non-used variables atm - but first check this seemed to work
browse pidp partner_id year partner_match sex sex_sp howlng_wom howlng_man howlng howlng_sp total_hours_wom total_hours_man total_hours total_hours_sp

gen woman_records=0
replace woman_records = 1 if sex==2
replace woman_records = 1 if sex==1 & sex_sp==2
tab woman_records, m
inspect total_hours_wom if woman_records==1
tab marital_status_defacto_wom if woman_record==1, m

keep pidp hidp sex sex_sp year wavename intdatey intdatem survey partner_id partner_match *_wom *_man *_hh

tab partnered_wom partnered_man
tab partnered_wom partnered_man if partner_match==1

********************************************************************************
* Create variables for couples (only doing those with matched partner)
********************************************************************************

// Division of Labor variables \\

**Paid labor: hours, no overtime
egen paid_couple_total = rowtotal(jbhrs_wom jbhrs_man) if partner_match==1
gen paid_wife_pct=jbhrs_wom / paid_couple_total if partner_match==1
sum paid_wife_pct
browse pidp year sex sex_sp jbhrs_wom jbhrs_man paid_couple_total paid_wife_pct

gen paid_dol=.
replace paid_dol = 1 if paid_wife_pct>=0.400000 & paid_wife_pct<=0.600000 & partner_match==1 // shared
replace paid_dol = 2 if paid_wife_pct <0.400000 & paid_wife_pct!=. & partner_match==1 // husband does more
replace paid_dol = 3 if paid_wife_pct >0.600000 & paid_wife_pct!=. & partner_match==1 // wife does more
replace paid_dol = 4 if jbhrs_wom==0 & jbhrs_man==0 & partner_match==1 // neither works

tab partner_match paid_dol, m // okay not quite sure what to do for the couples without a match...or when one partner is missing and the other is not. count as 0s? or ignore?
tab partner_match paid_dol if age_all_wom<=65 & age_all_man<=65, m

label define paid_dol 1 "Shared" 2 "Husband more" 3 "Wife more" 4 "Neither works"
label values paid_dol paid_dol

**Paid labor: hours, with overtime
egen paid_couple_total_ot = rowtotal(total_hours_wom total_hours_man) if partner_match==1
gen paid_wife_pct_ot=total_hours_wom / paid_couple_total_ot if partner_match==1
sum paid_wife_pct
sum paid_wife_pct_ot

gen paid_dol_ot=.
replace paid_dol_ot = 1 if paid_wife_pct_ot>=0.400000 & paid_wife_pct_ot<=0.600000  & partner_match==1 // shared
replace paid_dol_ot = 2 if paid_wife_pct_ot <0.400000 & paid_wife_pct_ot!=. & partner_match==1  // husband does more
replace paid_dol_ot = 3 if paid_wife_pct_ot >0.600000 & paid_wife_pct_ot!=. & partner_match==1 // wife does more
replace paid_dol_ot = 4 if total_hours_wom==0 & total_hours_man==0  & partner_match==1  // neither works

label values paid_dol_ot paid_dol

**Paid labor: earnings
egen paid_couple_earnings = rowtotal(fimnlabgrs_dv_wom fimnlabgrs_dv_man) if partner_match==1
gen paid_earn_pct=fimnlabgrs_dv_wom / paid_couple_earnings if partner_match==1
sum paid_earn_pct

gen hh_earn_type=.
replace hh_earn_type = 1 if paid_earn_pct>=0.400000 & paid_earn_pct<=0.600000 & partner_match==1 // shared
replace hh_earn_type = 2 if paid_earn_pct <0.400000 & paid_earn_pct!=. & partner_match==1  // husband does more
replace hh_earn_type = 3 if paid_earn_pct >0.600000 & paid_earn_pct!=. & partner_match==1  // wife does more
replace hh_earn_type = 4 if fimnlabgrs_dv_wom==0 & fimnlabgrs_dv_man==0 & partner_match==1  // neither works
replace hh_earn_type=. if (paid_earn_pct < 0 | (paid_earn_pct > 1 & paid_earn_pct!=.)) & partner_match==1 // very miniscule amount of people, but this records negative earnings

label values hh_earn_type paid_dol

**Unpaid labor
egen unpaid_couple_total = rowtotal(howlng_wom howlng_man) if partner_match==1
gen unpaid_wife_pct=howlng_wom / unpaid_couple_total if partner_match==1
sum unpaid_wife_pct

gen unpaid_dol=.
replace unpaid_dol = 1 if unpaid_wife_pct>=0.400000 & unpaid_wife_pct<=0.600000  & partner_match==1 // shared
replace unpaid_dol = 2 if unpaid_wife_pct >0.600000 & unpaid_wife_pct!=. & partner_match==1 // wife does more
replace unpaid_dol = 3 if unpaid_wife_pct <0.400000 & unpaid_wife_pct!=. & partner_match==1 // husband does more
replace unpaid_dol = 4 if howlng_wom==0 & howlng_man==0 & partner_match==1 // neither works

label define unpaid_dol 1 "Shared" 2 "Wife more" 3 "Husband more" 4 "No one"
label values unpaid_dol unpaid_dol

tab partner_match unpaid_dol if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31), m row // there are a lot of missing still, but I QAed this before and it all seemed accurate
tab wavename unpaid_dol if partner_match==1, m

gen unpaid_flag=0
replace unpaid_flag=1 if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31)
replace unpaid_flag=0 if wavename==1 & inrange(intdatem,8,12)
tab unpaid_flag
tab howlng_wom unpaid_flag, m

save "$outputpath/UKHLS_full_sample.dta", replace

// Relationship detail recodes \\

sort pidp year
browse pidp year partner_match partner_id marital_status_defacto_wom total_hours_wom total_hours_man

// identify couples who transitioned from cohab to marriage okay and transitioned into or out of a relationship also
gen marr_trans=0
replace marr_trans=1 if (marital_status_defacto_wom==1 & marital_status_defacto_wom[_n-1]==2) & pidp==pidp[_n-1] & partner_id==partner_id[_n-1] & year==year[_n-1]+1 & partner_match==1 
replace marr_trans=1 if (marital_status_defacto_man==1 & marital_status_defacto_man[_n-1]==2) & pidp==pidp[_n-1] & partner_id==partner_id[_n-1] & year==year[_n-1]+1 & partner_match==1 

gen rel_start=0
replace rel_start=1 if (inlist(marital_status_defacto_wom,1,2) & inlist(marital_status_defacto_wom[_n-1],3,4,5,6)) & pidp==pidp[_n-1] & year==year[_n-1]+1 // won't have partner id in year before
replace rel_start=1 if (inlist(marital_status_defacto_man,1,2) & inlist(marital_status_defacto_man[_n-1],3,4,5,6)) & pidp==pidp[_n-1] & year==year[_n-1]+1 // won't have partner id in year before

gen rel_end=0
replace rel_end=1 if (inlist(marital_status_defacto_wom,3,4,5,6) & inlist(marital_status_defacto_wom[_n-1],1,2)) & pidp==pidp[_n-1] & year==year[_n-1]+1
replace rel_end=1 if (inlist(marital_status_defacto_man,3,4,5,6) & inlist(marital_status_defacto_man[_n-1],1,2)) & pidp==pidp[_n-1] & year==year[_n-1]+1 

browse pidp year partner_match marital_status_defacto_wom marital_status_defacto_man rel_start marr_trans rel_end partner_id total_hours_wom total_hours_man
// this pidp did have transition 16339 - okay confirmed it worked. okay but I dont see them in here, gah, did something go wrong somewhere? they are missing years 1999-2006. is that not true elsewhere?


// tab rel_no_wom if inlist(marital_status_defacto_wom,1,2), m // so about 4% missing. come back to this - can I see if any started during the survey to at least get duration?

// okay duration info
gen current_rel_duration=.
replace current_rel_duration = istrtdaty-current_rel_start_year
browse pidp istrtdaty istrtdatm current_rel_duration current_rel_start_year current_rel_start_month

********************************************************************************
* Get rid of deduplicated records
********************************************************************************