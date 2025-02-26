// Extract UK data with multiple respondents per household from MTUS_haf
// Assign unique id for each individual-diary (each individual reported 7- or 2-day diaries) 
// Create time-use variables at individual level

use "$data\MTUS_haf.dta", clear

// Extract UK data with multiple respondents per household 

tab country 

tab country, nolab /* UK = 235 */

keep if country == 235 

drop if survey == 1961 | survey == 1974 | survey == 1995 | survey == 2005 /* these waves only interviewed one person per household and the partner id cannot be created in 1974, now have waves 1983, 1987, 2000, 2014 */

// Assign unique ids for each individual 

gen padded_hldid = string(hldid, "%08.0f")

gen individualid = string(survey) + padded_hldid + string(persid) + string(id)

unique individualid /* verify that each observation (person-diary) has its own id */

// Create time-use variables at individual level 

* paidwork already defined = paidwork

gen housework = foodprep + cleanetc + maintain + shopserv + garden + main27

gen chcare = pkidcare + ikidcare

* adult care already defined = eldcare 

gen mergeid = individualid

save "$moddata\mtusuk_individual.dta", replace 
