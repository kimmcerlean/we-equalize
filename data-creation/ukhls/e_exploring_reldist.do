********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: exploring_reldist
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This file explores the relative distributions of variables
ssc install reldist, replace
ssc install moremata, replace

********************************************************************************
* Input data and restrict to matched couples
********************************************************************************
use "$outputpath/UKHLS_matched_cleaned.dta", clear // created in step c.

// variables: all work hours - total_hours total_hours_sp paid_couple_total_ot
// variables: housework - howlng howlng_sp unpaid_couple_total

reldist pdf total_hours if total_hours > 0, by(sex)
reldist graph // so this creates the relative density? where females have higehr hours at lower end (above 1), but males have higher hours at upper end, which makes sense?

reldist pdf howlng if howlng > 0, by(sex) graph // then this is essentially inverse - females do less at lower end, but more at upper end

reldist hist total_hours, by(sex) graph // just histogram instead of line? not as useful
reldist hist howlng, by(sex) graph

reldist cdf total_hours, by(sex) graph // this is like relative distribution
reldist cdf howlng, by(sex) graph

reldist divergence total_hours, by(sex)
reldist divergence howlng, by(sex)

reldist mrp total_hours, by(sex) // so negative because women less than men (and I think women reference?)
reldist mrp howlng, by(sex) // then here positive. essentially like ratio of medians, I *think*

reldist sum total_hours, by(sex)
reldist sum howlng, by(sex)

// I wanted to see a plot of the distributions by sex; this is just a basic histogram
histogram total_hours if total_hours>0 & total_hours<100, by(sex)
twoway (histogram total_hours if total_hours>0 & total_hours<100 & sex==1, color(blue%50)) (histogram total_hours if total_hours>0 & total_hours<100 & sex==2, color(red%50)), legend(order(1 "Men" 2 "Women" ) rows(1) position(6)) xtitle(`"Weekly Paid Work Hours"') // ytitle(`"% Female Contributions"')

twoway (histogram howlng if howlng<40 & sex==1, color(blue%50) width(3)) (histogram howlng if howlng<40 & sex==2, color(red%50) width(3)),  legend(order(1 "Men" 2 "Women" ) rows(1) position(6)) xtitle(`"Weekly Housework Hours"') 
