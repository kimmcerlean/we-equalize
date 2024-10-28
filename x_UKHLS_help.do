********************************************************************************
********************************************************************************
* Code owner: Kimberly McErlean
* Started: September 2024
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This code is to send to UKHLS help forum to investigate relationship start 
* / end date mismatches across partners
* this is a cut down version of my code to facilitate troubleshooting

********************************************************************************
* Prep step 1: first update spouse id for BHPS so it's pidp NOT pid
********************************************************************************
use "$ukhls\xwaveid_bh.dta" // data file directly from UKHLS (6614)

keep pidp pid
rename pid sppid_bh
rename pidp partner_pidp_bh

save "$temp\spid_lookup.dta", replace

********************************************************************************
* Prep step 2: partner history file for later
********************************************************************************
use "$input/phistory_wide.dta", clear // data file directly from UKHLS (8473)

foreach var in status* partner* starty* startm* endy* endm* divorcey* divorcem* mrgend* cohend* ongoing* ttl_spells ttl_married ttl_civil_partnership ttl_cohabit ever_married ever_civil_partnership ever_cohabit lastintdate lastinty lastintm hhorig{
	rename `var' mh_`var' // renaming for ease of finding later, especially when matching partner info
}

save "$temp\partner_history_tomatch.dta", replace

********************************************************************************
* Import main individual respondent file and append necessary files
********************************************************************************
use "$outputpath/UKHLS_long_all.dta", clear // this is all waves of the BHPS / UKHLS appended together
drop if pidp==. 

gen partnered=0
replace partnered=1 if inlist(marital_status_defacto,1,2)

// first I update so all partner ids are pidp (the bhps ones were pid)
merge m:1 sppid_bh using "$temp\spid_lookup.dta" // reated above
drop if _merge==2
// browse survey pidp pid sppid_bh partner_pidp_bh _merge
inspect sppid_bh if partnered==1
inspect partner_pidp_bh if partnered==1
drop _merge

gen long partner_id = .
replace partner_id = ppid if survey==1
replace partner_id = partner_pidp_bh if survey==2 // okay will try to use pidp instead
replace partner_id = . if partner_id <=0 // inapplicable / spouse not in HH

inspect partner_id
inspect partner_id if partnered==1

// Now I append relationship history variables
merge m:1 pidp using "$temp\partner_history_tomatch.dta", keepusing(mh_*)
tab marital_status_defacto _merge, row
drop if _merge==2
drop _merge

// create information on current relationship based on relationship number and partner ids
abel define status_new 1 "Marriage" 2 "Cohab"
foreach var in mh_status1 mh_status2 mh_status3 mh_status4 mh_status5 mh_status6 mh_status7 mh_status8 mh_status9 mh_status10 mh_status11 mh_status12 mh_status13 mh_status14{
	gen x_`var' = `var'
	replace `var' = 1 if inlist(`var',2,3)
	replace `var' = 2 if `var'==10
	label values `var' .
	label values `var' status_new
}

gen rel_no=. // add this to get lookup for current relationship start and end dates
forvalues r=1/14{
	replace rel_no = `r' if mh_status`r' == marital_status_defacto & mh_partner`r' == partner_id & partner_id!=.
}

tab rel_no if inlist(marital_status_defacto,1,2), m // so about 4% missing. come back to this

// I am going to create individual level versions of these variables for now and then check in next file against partners to make sure they match.
gen current_rel_start_year=.
gen current_rel_start_month=.
gen current_rel_end_year=.
gen current_rel_end_month=.
gen current_rel_ongoing=.
gen current_rel_marr_end=.
gen current_rel_coh_end=.

forvalues r=1/14{
	replace current_rel_start_year = mh_starty`r' if rel_no==`r'
	replace current_rel_start_month = mh_startm`r' if rel_no==`r'
	replace current_rel_end_year = mh_endy`r' if rel_no==`r'
	replace current_rel_end_month = mh_endm`r' if rel_no==`r'
	replace current_rel_ongoing = mh_ongoing`r' if rel_no==`r'
	replace current_rel_marr_end = mh_mrgend`r' if rel_no==`r'
	replace current_rel_coh_end = mh_cohend`r' if rel_no==`r'
}

replace current_rel_start_year=. if current_rel_start_year==-9
replace current_rel_start_month=. if current_rel_start_month==-9
replace current_rel_end_year=. if current_rel_end_year==-9
replace current_rel_end_month=. if current_rel_end_month==-9

label values current_rel_ongoing ongoing
label values current_rel_marr_end mrgend
label values current_rel_coh_end cohend
 
********************************************************************************
* Now I create a temporary copy of the data to match to the partner id
********************************************************************************
// just keep necessary variables
local partnervars "pno sampst sex jbstat qfhigh racel racel_dv nmar aidhh aidxhh aidhrs jbhas jboff jbbgy jbhrs jbot jbotpd jbttwt ccare dinner howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv paygl paynl paygu_dv payg_dv paynu_dv payn_dv ethn_dv nchild_dv ndepchl_dv rach16_dv qfhigh_dv hiqual_dv lcohnpi coh1bm coh1by coh1mr coh1em coh1ey lmar1m lmar1y cohab cohabn lmcbm1 lmcby41 currpart1 lmspm1 lmspy41 lmcbm2 lmcby42 currpart2 lmspm2 lmspy42 lmcbm3 lmcby43 currpart3 lmspm3 lmspy43 lmcbm4 lmcby44 currpart4 lmspm4 lmspy44 hubuys hufrys humops huiron husits huboss lmcbm5 lmcby45 currpart5 lmspm5 lmspy45 lmcbm6 lmcby46 currpart6 lmspm6 lmspy46 lmcbm7 lmcby47 currpart7 lmspm7 lmspy47 isced11_dv region hiqualb_dv huxpch hunurs race qfedhi qfachi isced nmar_bh racel_bh age_all dob_year marital_status_legal marital_status_defacto partnered employed total_hours country_all college_degree race_use psu strata istrtdaty indinub_xw indinus_xw indinus_lw indinub_lw mh_* rel_no current_rel_start_year current_rel_start_month current_rel_end_year current_rel_end_month current_rel_ongoing current_rel_marr_end current_rel_coh_end"

keep pidp pid survey wavename year `partnervars'

// rename them to indicate they are for partner
foreach var in `partnervars'{
	rename `var' `var'_sp
}

// rename pidp to match the name I gave to partner pidp in main file to match
generate long apidp = pidp // so this will also work to match ego alt later for checking
rename pidp partner_id

drop pid survey

save "$temp/UKHLS_partners.dta", replace

********************************************************************************
* Then open main data file and merge on partner characteristics
********************************************************************************
use "$outputpath/UKHLS_long_all_recoded.dta", clear

merge m:1 partner_id wavename using "$temp/UKHLS_partners.dta" // okay it feels like switching to pidp left me with the same number of matches...
drop if _merge==2

tab survey _merge, m
tab survey partnered, m // so, there are more people partnered than matched...
inspect partner_id if _merge==1 & partnered==1 // so there are a bunch with partner ids, so WHY aren't they matching? okay, confirmed it is just partner non-response for a specific wave
inspect partner_id if _merge==1 & partnered==1 & survey==1 //
inspect partner_id if _merge==1 & partnered==1 & survey==2 //

browse survey wavename pidp pid partner_id hubuys _merge

gen partner_match=0
replace partner_match=1 if _merge==3
drop _merge

save "$outputpath/UKHLS_matched.dta", replace

********************************************************************************
**# This is where I started to explore whether the dates matched
********************************************************************************
// Note - instead of leaving variables as ref v. spouse as above, I recoded to be for woman (_wom) v. man (_man) in a step not shown here

// validate relationship info for couples and add duration info
browse pidp partner_id partner_match year current_rel_start_year_wom current_rel_start_year_man rel_no_wom rel_no_man mh_starty1_wom mh_starty1_man mh_starty2_wom mh_starty2_man mh_starty3_wom mh_starty3_man // okay, so they don't always match and sometimes one is missing while the other is not (and vice versa)

gen partner_start_date_match=0
replace partner_start_date_match=1 if current_rel_start_year_wom==current_rel_start_year_man & current_rel_start_year_man!=. & current_rel_start_year_wom!=.
replace partner_start_date_match=2 if current_rel_start_year_wom-current_rel_start_year_man==1 & current_rel_start_year_man!=. & current_rel_start_year_wom!=.
replace partner_start_date_match=2 if current_rel_start_year_man-current_rel_start_year_wom==1 & current_rel_start_year_man!=. & current_rel_start_year_wom!=.
replace partner_start_date_match=3 if partner_match==1 & current_rel_start_year_wom!=. & current_rel_start_year_man==.
replace partner_start_date_match=3 if partner_match==1 & current_rel_start_year_wom==. & current_rel_start_year_man!=.

tab partner_start_date_match, m
tab partner_start_date_match if partner_match==1, m // okay so about 78% match, 5% are within 1 year, and 8% one partner is mising while the other is not. So about 8% don't fall into those categories.

gen partner_end_date_match=0
replace partner_end_date_match=1 if current_rel_end_year_wom==current_rel_end_year_man & current_rel_end_year_man!=. & current_rel_end_year_wom!=.
replace partner_end_date_match=2 if current_rel_end_year_wom-current_rel_end_year_man==1 & current_rel_end_year_man!=. & current_rel_end_year_wom!=.
replace partner_end_date_match=2 if current_rel_end_year_man-current_rel_end_year_wom==1 & current_rel_end_year_man!=. & current_rel_end_year_wom!=.
replace partner_end_date_match=3 if partner_match==1 & current_rel_end_year_wom!=. & current_rel_end_year_man==.
replace partner_end_date_match=3 if partner_match==1 & current_rel_end_year_wom==. & current_rel_end_year_man!=.

tab partner_end_date_match, m
tab partner_end_date_match if partner_match==1, m // end date is slightly worse...

tab current_rel_ongoing_wom current_rel_ongoing_man if partner_match==1 // they don't even agree on whether or not relationship is ongoing?
