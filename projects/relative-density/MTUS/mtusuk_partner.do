// Create unique id for each individual's partner (if in couple & partner id is identifiable) 
// Copy time-use variables for partner

use "$moddata\mtusuk_individual.dta", clear

// Assign unique ids for each individual's partner

keep if partid > 0

browse survey hldid persid id civstat relrefp partid 

gen new_partid = string(survey) + padded_hldid + string(partid) + string(id) 

browse survey hldid civstat relrefp individualid new_partid 

// Duplicate time-use variables for partner

gen sp_paidwork = paidwork

gen sp_housework = housework

gen sp_chcare = chcare

gen sp_eldcare = eldcare

// Duplicate datasets for partner

drop mergeid 

gen mergeid = new_partid 

save "$moddata\mtusuk_partner.dta", replace 
