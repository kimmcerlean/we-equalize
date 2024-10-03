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

// want to export list to qa
preserve

collapse (count) year, by(pidp partner_id)
browse

restore

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

// tab current_rel_start_year - okay realizing in the UK, because of the history, they might actually not all start relationships after the survey started in 1991. howver, it's like less than a few %

// create couple-level education
tab college_degree college_degree_sp

gen couple_educ_gp=0
replace couple_educ_gp = 1 if college_degree==1 | college_degree_sp==1
replace couple_educ_gp=. if college_degree==. & college_degree_sp==.

//  combined indicator of paid and unpaid, using HOURS - okay currently missing for all years that housework hours are
/*
gen hours_housework=.
replace hours_housework=1 if paid_dol_ot==1 & unpaid_dol==1 // dual both (egal)
replace hours_housework=2 if paid_dol_ot==1 & unpaid_dol==2 // dual earner, female HM (second shift)
replace hours_housework=3 if paid_dol_ot==2 & unpaid_dol==1 // male BW, dual HW (mm not sure)
replace hours_housework=4 if paid_dol_ot==2 & unpaid_dol==2 // male BW, female HM (conventional)
replace hours_housework=5 if paid_dol_ot==3 & unpaid_dol==1 // female BW, dual HW (gender-atypical)
replace hours_housework=6 if paid_dol_ot==3 & unpaid_dol==2 // female BW, female HM (undoing gender)
replace hours_housework=7 if unpaid_dol==3  // all where male does more housework (gender-atypical)
replace hours_housework=8 if paid_dol_ot==4  // no earners

label define hours_housework 1 "Egal" 2 "Second Shift" 3 "Male BW, dual HW" 4 "Conventional" 5 "Gender-atypical" 6 "Undoing gender" 7 "Male HW dominant" 8 "No Earners"
label values hours_housework hours_housework 
*/

gen earn_housework=.
replace earn_housework=1 if hh_earn_type==1 & unpaid_dol==1 // dual both (egal)
replace earn_housework=2 if hh_earn_type==1 & unpaid_dol==2 // dual earner, female HM (second shift)
replace earn_housework=3 if hh_earn_type==2 & unpaid_dol==2 // male BW, female HM (traditional)
replace earn_housework=4 if hh_earn_type==3 & unpaid_dol==3 // female BW, male HM (counter-traditional)
replace earn_housework=5 if earn_housework==. & hh_earn_type!=. & unpaid_dol!=. // all others

label define earn_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"
label values earn_housework earn_housework 

********************************************************************************
**# Some descriptive statistics
********************************************************************************

unique pidp partner_id 
unique pidp partner_id year_transitioned
unique pidp partner_id  if dur==0

sum duration_cohab if duration_cohab < 0 // average cohab duration
sum duration_cohab if duration_cohab > 0 & duration_cohab !=. // average marital duration

tab couple_educ_gp
tab couple_educ_gp if dur==0

tab kids_in_hh
tab kids_in_hh if dur==0

tab had_birth
unique pidp partner_id  if had_birth==1 // use this for % experiencing a birth
unique pidp partner_id  if had_birth==1 & duration_cohab==0
tab had_birth if duration_cohab==0

sum paid_earn_pct
tab hh_earn_type
sum paid_wife_pct_ot
sum unpaid_wife_pct
tab unpaid_dol
tab earn_housework

sum paid_earn_pct if dur==0
tab hh_earn_type if dur==0
sum paid_wife_pct_ot if dur==0
sum unpaid_wife_pct if dur==0
tab unpaid_dol if dur==0
tab earn_housework if dur==0

********************************************************************************
**# ANALYSIS
********************************************************************************
// descriptive

** total sample
preserve

collapse (median) paid_wife_pct_ot paid_earn_pct unpaid_wife_pct , by(duration_cohab) 
twoway line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10
// twoway line paid_wife_pct_ot duration_cohab if duration_cohab>=-10 & duration_cohab <=15
twoway line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10
twoway line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10
// twoway line unpaid_wife_pct duration_cohab if duration_cohab>=-10 & duration_cohab <=15

twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10)
twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) 

restore

** split by presence of children
preserve

collapse (median) paid_wife_pct_ot paid_earn_pct unpaid_wife_pct, by(duration_cohab kids_in_hh)  // results for kids don't make sense, because need to scale it to TIME from children, because right now, it's all muddled. so doing NO KIDS in HH to show the results has the advantage of like OKAY it's not JUST because of children, but need to more formally investigate the role of children.

twoway line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0
twoway line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0

twoway (line paid_wife_pct_ot duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0) (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0)

twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==0, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) 

twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==1) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & kids_in_hh==1, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) 

twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"Paid Labor"') ylabel(, valuelabel) ytitle(`"Unpaid Labor"', axis(2)) by(kids_in_hh, graphregion(margin(tiny)))

restore

** split by having a college degree (either, for now))
preserve

collapse (median) paid_wife_pct_ot paid_earn_pct unpaid_wife_pct, by(duration_cohab couple_educ_gp)

line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0
line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1
line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0
line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1

// by type of labor
twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0) (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1), legend(order(1 "No College" 2 "College") rows(1) position(6))
twoway (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1), legend(order(1 "No College" 2 "College") rows(1) position(6))

// by degree
twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6))
twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1, yaxis(2)), legend(order(1 "Paid Labor" 2 "Unpaid Labor") rows(1) position(6))

// lol is it crazy to do all? bc it's the same trend, but starting positions are different
twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0, lpattern(dash)) (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0, lpattern(dash) yaxis(2)) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1, yaxis(2)), legend(order(1 "No Paid" 2 "College Paid" 3 "No Unpaid" 4 "College Unpaid") rows(1) position(6))

twoway (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0, lcolor(green)) (line paid_earn_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1, lcolor(blue)) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==0, lpattern(dash) lcolor(green)) (line unpaid_wife_pct duration_cohab if duration_cohab>=-5 & duration_cohab <=10 & couple_educ_gp==1, lpattern(dash) lcolor(blue)), legend(order(1 "No Paid" 2 "College Paid" 3 "No Unpaid" 4 "College Unpaid") rows(1) position(6)) xtitle(`"Duration from Marital Transition"') ytitle(`"% Female Contributions"')

restore

// other charts
tab duration_cohab hh_earn_type if duration_cohab>=-5 & duration_cohab <=10, row nofreq
tab duration_cohab unpaid_dol if duration_cohab>=-5 & duration_cohab <=10, row nofreq
tab duration_cohab earn_housework if duration_cohab>=-5 & duration_cohab <=10, row nofreq
// tab duration_cohab hours_housework if duration_cohab>=-5 & duration_cohab <=10, row nofreq
