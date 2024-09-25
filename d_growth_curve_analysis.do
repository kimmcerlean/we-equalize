********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: growth_curve_analysis.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This file conducts descriptive and statistical analysis
* Eventually need to move this probably to the other folder, but for now, this is where the data is, so this works...

********************************************************************************
* Input data and restrict to cohabiting couples / one record per HH
********************************************************************************
use "$outputpath/UKHLS_matched_cleaned.dta", clear

// first drop if there isn't a matching partner
drop if partner_match==0
drop if sex==. | sex_sp==.

sort  hidp year pidp
browse pidp year hidp rel_no partner_id partner1 partner2  marital_status_defacto marr_trans current_rel_start_year starty1 starty2 current_rel_duration current_rel_end_year current_rel_ongoing sex sex_sp jbhrs jbhrs_sp paid_couple_total paid_wife_pct if inlist(pidp, 478004645, 478004649)

// okay so sometimes partners don't have the same relationship start year? should I use the one that said it was happening longest? or just stick with plan to use the female?
keep if sex==2

// restrict to working age?
tab age_all employed, row
keep if (age_all>=18 & age_all<60) &  (age_all_sp>=18 & age_all_sp<60) // sort of drops off a cliff after 60?

// identify couples who ever transitioned to marriage - but need to do WITHIN a given relationship?! this should be easier than PSID bc I have partner ids? that are consistent across waves
tab marital_status_defacto marr_trans, m

bysort pidp partner_id (marr_trans): egen ever_transition = max(marr_trans) // so this is in the confines of a given relationship?
gen year_transitioned=istrtdaty if marr_trans==1
bysort pidp partner_id (year_transitioned): replace year_transitioned = year_transitioned[1]

sort pidp partner_id istrtdaty
browse pidp partner_id istrtdaty marital_status_defacto marr_trans current_rel_start_year ever_transition year_transitioned

// think because i can match to partner, I should just keep all of those who ever transitioned.
keep if ever_transition==1

replace istrtdaty=year if inlist(istrtdaty,-8,-9)

gen duration_cohab=.
replace duration_cohab = istrtdaty - year_transitioned

tab duration_cohab, m

browse pidp partner_id istrtdaty marital_status_defacto marr_trans current_rel_start_year ever_transition year_transitioned duration_cohab current_rel_duration

********************************************************************************
**# ANALYSIS
********************************************************************************
// descriptive

preserve

collapse (median) paid_wife_pct_ot unpaid_wife_pct, by(duration_cohab) // oh, slight problem - kim, you didn't do EARNINGS percentage yet GAH. need to update. think that is my preference? But ask Lea?
twoway line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10
twoway line paid_wife_pct_ot duration_cohab if duration_cohab>=-10 & duration_cohab <=15
twoway line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10
twoway line unpaid_wife_pct duration_cohab if duration_cohab>=-10 & duration_cohab <=15

twoway (line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10)
twoway (line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) 

restore

collapse (median) paid_wife_pct_ot unpaid_wife_pct, by(duration_cohab kids_in_hh)  // results for kids don't make sense, because need to scale it to TIME from children, because right now, it's all muddled. so doing NO KIDS in HH to show the results has the advantage of like OKAY it's not JUST because of children, but need to more formally investigate the role of children.

twoway (line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) 

twoway (line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==1) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==1, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) 

twoway (line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) by(kids_in_hh, graphregion(margin(tiny)))

restore