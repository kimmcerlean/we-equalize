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

tab partnered partner_match, m
// tabstat jbhrs, by(age_all) // is there an age before which they don't ask these questions? I guess, the age of the survey respondents is only 15+, so I guess not; they seem to ask everyone

sort pidp year
browse pidp year partnered partner_id partner_match sex sex_sp howlng howlng_sp jbhrs jbhrs_sp  hubuys hubuys_sp age_all age_all_sp 

tab sex sex_sp, m
drop if sex==1 & sex_sp==1 // get rid of same gender?
drop if sex==2 & sex_sp==2

********************************************************************************
* Create gendered versions of all key variables
********************************************************************************
local individ_vars "psu strata jbstat aidhh aidxhh aidhrs jbhas jbhrs jbot jbotpd jbttwt howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv nchild_dv rach16_dv hiqual_dv hubuys hufrys humops huiron husits huboss age_all dob_year college_degree country_all  marital_status_legal marital_status_defacto partnered employed total_hours race_use mh_status1 mh_partner1 mh_starty1 mh_startm1 mh_endy1 mh_endm1 mh_divorcey1 mh_divorcem1 mh_mrgend1 mh_cohend1 mh_status2 mh_partner2 mh_starty2 mh_startm2 mh_endy2 mh_endm2 mh_divorcey2 mh_divorcem2 mh_mrgend2 mh_cohend2 mh_ongoing2 mh_status3 mh_partner3 mh_starty3 mh_startm3 mh_endy3 mh_endm3 mh_divorcey3 mh_divorcem3 mh_mrgend3 mh_cohend3 mh_ongoing3 mh_status4 mh_partner4 mh_starty4 mh_startm4 mh_endy4 mh_endm4 mh_divorcey4 mh_divorcem4 mh_mrgend4 mh_cohend4 mh_ongoing4 mh_status5 mh_partner5 mh_starty5 mh_startm5 mh_endy5 mh_endm5 mh_divorcey5 mh_divorcem5 mh_mrgend5 mh_cohend5 mh_ongoing5 mh_status6 mh_partner6 mh_starty6 mh_startm6 mh_endy6 mh_endm6 mh_divorcey6 mh_divorcem6 mh_mrgend6 mh_cohend6 mh_ongoing6 mh_status7 mh_partner7 mh_starty7 mh_startm7 mh_endy7 mh_endm7 mh_divorcey7 mh_divorcem7 mh_mrgend7 mh_cohend7 mh_ongoing7 mh_status8 mh_partner8 mh_starty8 mh_startm8 mh_endy8 mh_endm8 mh_divorcey8 mh_divorcem8 mh_mrgend8 mh_cohend8 mh_ongoing8 mh_status9 mh_partner9 mh_starty9 mh_startm9 mh_endy9 mh_endm9 mh_divorcey9 mh_divorcem9 mh_mrgend9 mh_cohend9 mh_ongoing9 mh_status10 mh_partner10 mh_starty10 mh_startm10 mh_endy10 mh_endm10 mh_divorcey10 mh_divorcem10 mh_mrgend10 mh_cohend10 mh_ongoing10 mh_status11 mh_partner11 mh_starty11 mh_startm11 mh_endy11 mh_endm11 mh_divorcey11 mh_divorcem11 mh_mrgend11 mh_cohend11 mh_ongoing11 mh_status12 mh_partner12 mh_starty12 mh_startm12 mh_endy12 mh_endm12 mh_divorcey12 mh_divorcem12 mh_mrgend12 mh_cohend12 mh_ongoing12 h_status13 mh_partner13 mh_starty13 mh_startm13 mh_endy13 mh_endm13 mh_divorcey13 mh_divorcem13 mh_mrgend13 mh_cohend13 mh_ongoing13 mh_status14 mh_partner14 mh_starty14 mh_startm14 mh_endy14 mh_endm14 mh_divorcey14 mh_divorcem14 mh_mrgend14 mh_cohend14 mh_ongoing14 mh_ttl_married mh_ttl_civil_partnership mh_ttl_cohabit mh_ever_married mh_ever_civil_partnership mh_ever_cohabit mh_lastintdate mh_lastinty mh_lastintm mh_hhorig indinub_xw indinus_xw indinus_lw indinub_lw"

local hhvars "hhsize fihhmngrs_dv hrpid ncouple_dv nkids_dv nch02_dv nch34_dv nch511_dv nch1215_dv agechy_dv npens_dv nemp_dv tenure_dv nchild_015 hhdenus_xw hhdenub_xw"

foreach var in `individ_vars'{
	gen `var'_wom = `var' if sex==2
	replace `var'_wom = `var'_sp if sex==1
	
	gen `var'_man = `var' if sex==1
	replace `var'_man = `var'_sp if sex==2
}

// then denote some variables as HH specific for reference
foreach var in `hhvars'{
	rename `var' `var'_hh
}

// for ease, let's just keep these core variables - so drop original versions of above as well as non-used variables atm - but first check this seemed to work
// keep pidp hidp sex year intdatey survey partner_id partner_match *_wom *_man *_hh

save "$outputpath/UKHLS_full_sample.dta", replace

********************************************************************************
* Create variables for couples
********************************************************************************

********************************************************************************
* Get rid of deduplicated records
********************************************************************************