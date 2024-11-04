********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: life_course_analysis.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This file conducts preliminary descriptive analysis
* Note: this will just be the couple-level analysis; I currently do not have data for years after they dissolve (if they dissolve)
* Eventually need to move this probably to the other folder, but for now, this is where the data is, so this works...

********************************************************************************
* Input data and restrict to couples in our time frame / age range
********************************************************************************
use "$outputpath/UKHLS_matched_cleaned.dta", clear

// think I need to fix duration because for some, I think clock might start again when they transition to cohabitation? get minimum year within a couple as main start date?
sort pidp partner_id year
browse pidp partner_id year current_rel_start_year marital_status_defacto current_rel_duration

bysort pidp partner_id: egen rel_start_all = min(current_rel_start_year)
gen duration=year - rel_start_all

browse pidp partner_id year current_rel_start_year rel_start_all current_rel_duration duration marital_status_defacto 

bysort pidp partner_id: egen min_dur = min(duration)
bysort pidp partner_id: egen max_dur = max(duration)
bysort pidp partner_id: egen last_yr_observed = max(year)

sort  pidp partner_id year
browse pidp partner_id year rel_start_all last_yr_observed duration min_dur max_dur

keep if current_rel_start_year >= 1990 & inlist(min_dur,0,1) // started after 1990 and we observed
keep if current_rel_start_year <= 2011 // so we have 10 years of data

unique pidp partner_id // there are A LOT of unique couples. is this odd? okay, well one problem was I had duplicates in HHs DUH kim
unique pidp partner_id if year >= 2010 // trying to validate against other research. this aligns with wang and cheng 2024. See also Raz-Turovich and Okun

// restrict to working age?
tab age_all employed, row
tab age_all_sp employed_sp, row
keep if (age_all>=18 & age_all<=60) &  (age_all_sp>=18 & age_all_sp<=60) // sort of drops off a cliff after 60?

// wait, do I currently have two records per HH? yes, I think, so need to delete one? or just restrict to women, for now?
sort hidp pidp year
browse hidp pidp partner_id year

// rank HH members
bysort year hidp : egen per_id = rank(pidp) // so if there is only one member left after above, will get a 1
browse hidp pidp partner_id year per_id
keep if per_id==1

********************************************************************************
**# Recenter on duration
********************************************************************************
browse pidp partner_id year istrtdaty current_rel_start_year current_rel_duration duration

tab duration, m
// keep if duration >=-4 // keep up to 5 years prior, jic - okay, don't have this data for UKHLS atm
keep if duration <=12 // up to 10/11 for now - but adding a few extra years so I can do the lookups below and still retain up to 10

// gen duration_rec=duration+4 // negatives won't work in reshape - so make -5 0

tab duration hh_earn_type, row nofreq
tab duration hh_earn_type if max_dur>=10, row nofreq
tab duration unpaid_dol, row nofreq
tab duration unpaid_dol if max_dur>=10, row nofreq

// okay let's reshape and maybe try to fill in the off years of unpaid dol. right now, keeping the bare minimum, but will add more later
keep pidp partner_id rel_start_all min_dur max_dur last_yr_observed sex sex_sp hidp psu strata duration hhsize nkids_dv nchild_015 agechy_dv marital_status_defacto hubuys hufrys humops huiron husits huboss hufrys_sp humops_sp huiron_sp husits_sp huboss_sp age_all age_all_sp survey employed employed_sp current_rel_end_year marr_trans current_rel_ongoing paid_couple_total paid_wife_pct paid_dol total_hours total_hours_sp paid_couple_total_ot paid_wife_pct_ot paid_dol_ot paid_couple_earnings paid_earn_pct hh_earn_type unpaid_couple_total unpaid_wife_pct unpaid_dol unpaid_flag kids_in_hh had_birth had_first_birth_alt college_degree college_degree_sp country_all wavename

reshape wide hidp psu strata hhsize nkids_dv nchild_015 agechy_dv marital_status_defacto hubuys hufrys humops huiron husits huboss hufrys_sp humops_sp huiron_sp husits_sp huboss_sp age_all age_all_sp survey employed employed_sp current_rel_end_year marr_trans current_rel_ongoing paid_couple_total paid_wife_pct paid_dol total_hours total_hours_sp paid_couple_total_ot paid_wife_pct_ot paid_dol_ot paid_couple_earnings paid_earn_pct hh_earn_type unpaid_couple_total unpaid_wife_pct unpaid_dol unpaid_flag kids_in_hh had_birth had_first_birth_alt college_degree college_degree_sp country_all wavename, i(pidp partner_id rel_start_all min_dur max_dur last_yr_observed sex sex_sp) j(duration)

unique pidp partner_id
unique pidp partner_id if max_dur>=10 // so this will cut it down some

sort rel_start_all pidp partner_id
browse pidp partner_id rel_start_all min_dur max_dur last_yr_observed sex sex_sp 

// going to try to fill in HW for the years not asked - this mainly affects ukhls, not bhps. ukhls is when it was intermittent years. this is not to replace missings in general, this is to sort out the not asked years specifically
browse pidp partner_id rel_start_all max_dur survey* wavename* hh_earn_type* unpaid_dol*

forvalues b=0/11{
	local c = `b'+1
	replace unpaid_dol`b' = unpaid_dol`c' if unpaid_dol`b'==. & unpaid_dol`c'!=. & survey`b'==1 & survey`c'==1 // replace off-year with next year's value if in UKHLS years
}

// now create combined indicator with updated HW variables
label define earn_housework 1 "Egal" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All others"

forvalues d=0/12{
	gen earn_housework`d'=.
	replace earn_housework`d'=1 if hh_earn_type`d'==1 & unpaid_dol`d'==1 // dual both (egal)
	replace earn_housework`d'=2 if hh_earn_type`d'==1 & unpaid_dol`d'==2 // dual earner, female HM (second shift)
	replace earn_housework`d'=3 if hh_earn_type`d'==2 & unpaid_dol`d'==2 // male BW, female HM (traditional)
	replace earn_housework`d'=4 if hh_earn_type`d'==3 & unpaid_dol`d'==3 // female BW, male HM (counter-traditional)
	replace earn_housework`d'=5 if earn_housework`d'==. & hh_earn_type`d'!=. & unpaid_dol`d'!=. // all others
	label values earn_housework`d' earn_housework 
}

browse pidp partner_id rel_start_all max_dur hh_earn_type* unpaid_dol* earn_housework*
gen duration=last_yr_observed-rel_start_all
browse pidp partner_id rel_start_all last_yr_observed max_dur duration

gen duration_10=0
replace duration_10=1 if duration>=10

// want to merge info on kid status PLUS dol - let's just do for hours of paid labor and unpaid labor separately
label define parent_paid_type 1 "no kids, dual" 2 "no kids, male BW" 3 "no kids, female BW" 4 "no kids, no earners" 5 "kids, dual" 6 "kids, male BW" 7 "kids, female BW" 8 "kids, no earners" 

forvalues d=0/12{
	gen parent_paid_type`d'=.
	replace parent_paid_type`d'=1 if kids_in_hh`d'==0 & paid_dol_ot`d'==1 // no kids, dual
	replace parent_paid_type`d'=2 if kids_in_hh`d'==0 & paid_dol_ot`d'==2 // no kids, male BW
	replace parent_paid_type`d'=3 if kids_in_hh`d'==0 & paid_dol_ot`d'==3 // no kids, female BW
	replace parent_paid_type`d'=4 if kids_in_hh`d'==0 & paid_dol_ot`d'==4 // no kids, no earners

	replace parent_paid_type`d'=5 if kids_in_hh`d'==1 & paid_dol_ot`d'==1 // kids, dual
	replace parent_paid_type`d'=6 if kids_in_hh`d'==1 & paid_dol_ot`d'==2 // kids, male BW
	replace parent_paid_type`d'=7 if kids_in_hh`d'==1 & paid_dol_ot`d'==3 // kids, female BW
	replace parent_paid_type`d'=8 if kids_in_hh`d'==1 & paid_dol_ot`d'==4 // kids, no earners
	
	label values parent_paid_type`d' parent_paid_type 
}

label define parent_unpaid_type 1 "no kids, dual" 2 "no kids, female HW" 3 "no kids, male HW" 4 "kids, dual" 5 "kids, female HW" 6 "kids, male HW"

forvalues d=0/12{
	gen parent_unpaid_type`d'=.
	replace parent_unpaid_type`d'=1 if kids_in_hh`d'==0 & unpaid_dol`d'==1 // no kids, dual
	replace parent_unpaid_type`d'=2 if kids_in_hh`d'==0 & unpaid_dol`d'==2 // no kids, female HW
	replace parent_unpaid_type`d'=3 if kids_in_hh`d'==0 & unpaid_dol`d'==3 // no kids, male HW

	replace parent_unpaid_type`d'=4 if kids_in_hh`d'==1 & unpaid_dol`d'==1 // kids, dual
	replace parent_unpaid_type`d'=5 if kids_in_hh`d'==1 & unpaid_dol`d'==2 // kids, female HW
	replace parent_unpaid_type`d'=6 if kids_in_hh`d'==1 & unpaid_dol`d'==3 // kids, male HW

	label values parent_unpaid_type`d' parent_unpaid_type 
}

save "$temp\ukhls_couple_data_wide.dta", replace

********************************************************************************
**# attempt to summarize data
********************************************************************************
// use "$temp\ukhls_couple_data_wide.dta", clear

// all
putexcel set "$results/ukhls_life course dol", sheet(all) replace
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No HW"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x'
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
	tab paid_dol_ot`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x'
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
	tab unpaid_dol`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x'
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x'
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}

// just 10 years +
drop if duration_10==0

putexcel set "$results/ukhls_life course dol", sheet(10yrs) modify
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x'
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
//	tab paid_dol_ot`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x'
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
//	tab unpaid_dol`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x'
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
//	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x'
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}

// 10 years - no kids
putexcel set "$results/ukhls_life course dol", sheet(nokids) modify
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x' if kids_in_hh`s'==0
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
//	tab paid_dol_ot`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x' if kids_in_hh`s'==0
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
//	tab unpaid_dol`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x' if kids_in_hh`s'==0
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
//	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x' if kids_in_hh`s'==0
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}


// 10 years - kids
putexcel set "$results/ukhls_life course dol", sheet(kids) modify
putexcel A2 = "Duration"
putexcel B1:E1 = "Earnings DoL", merge border(bottom) hcenter bold
putexcel F1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:M1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel N1:R1 = "Combo", merge border(bottom) hcenter bold
putexcel B2 = "Dual"
putexcel C2 = "Male BW"
putexcel D2 = "Female BW"
putexcel E2 = "No Earners"
putexcel F2 = "Dual"
putexcel G2 = "Male BW"
putexcel H2 = "Female BW"
putexcel I2 = "No Earners"
putexcel J2 = "Dual"
putexcel K2 = "Female HW"
putexcel L2 = "Male HW"
putexcel M2 = "No Earners"
putexcel N2 = "Egal"
putexcel O2 = "Second shift"
putexcel P2 = "Traditional"
putexcel Q2 = "Counter-Traditional"
putexcel R2 = "Other"

// Means
putexcel A3 = "Duration 0"
putexcel A4 = "Duration 1"
putexcel A5 = "Duration 2"
putexcel A6 = "Duration 3"
putexcel A7 = "Duration 4"
putexcel A8 = "Duration 5"
putexcel A9 = "Duration 6"
putexcel A10 = "Duration 7"
putexcel A11 = "Duration 8"
putexcel A12 = "Duration 9"
putexcel A13 = "Duration 10"


local colu "B C D E"

forvalues s=0/10{
	local row = `s' + 3
//	tab hh_earn_type`s', gen(earn`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean earn`s'_`x' if kids_in_hh`s'==1
		matrix earn`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn`s'_`x'), nformat(#.#%)
	}
}

local colu "F G H I"

forvalues s=0/10{
	local row = `s' + 3
//	tab paid_dol_ot`s', gen(hours`s'_)
	forvalues x=1/4{ 
		local col: word `x' of `colu'
		mean hours`s'_`x' if kids_in_hh`s'==1
		matrix hours`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hours`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M"

forvalues s=0/10{
	local row = `s' + 3
//	tab unpaid_dol`s', gen(hw`s'_)
	forvalues x=1/3{ 
		local col: word `x' of `colu'
		mean hw`s'_`x' if kids_in_hh`s'==1
		matrix hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(hw`s'_`x'), nformat(#.#%)
	}
}

local colu "N O P Q R"

forvalues s=0/10{
	local row = `s' + 3
//	tab earn_housework`s', gen(earn_hw`s'_)
	forvalues x=1/5{ 
		local col: word `x' of `colu'
		mean earn_hw`s'_`x' if kids_in_hh`s'==1
		matrix earn_hw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(earn_hw`s'_`x'), nformat(#.#%)
	}
}

// combined parent view
putexcel set "$results/ukhls_life course dol", sheet(parental_status) modify
putexcel A3 = "Duration"
putexcel B1:I1 = "Hours DoL", merge border(bottom) hcenter bold
putexcel J1:O1 = "Housework DoL", merge border(bottom) hcenter bold
putexcel B2:E2 = "No Kids", merge border(bottom) hcenter bold
putexcel F2:I2 = "Kids", merge border(bottom) hcenter bold
putexcel J2:L2 = "No Kids", merge border(bottom) hcenter bold
putexcel M2:O2 = "Kids", merge border(bottom) hcenter bold

putexcel B3 = "Dual"
putexcel C3 = "Male BW"
putexcel D3 = "Female BW"
putexcel E3 = "No Earners"
putexcel F3 = "Dual"
putexcel G3 = "Male BW"
putexcel H3 = "Female BW"
putexcel I3 = "No Earners"
putexcel J3 = "Dual"
putexcel K3 = "Female HW"
putexcel L3 = "Male HW"
putexcel M3 = "Dual"
putexcel N3 = "Female HW"
putexcel O3 = "Male HW"


// Means
putexcel A4 = "Duration 0"
putexcel A5 = "Duration 1"
putexcel A6 = "Duration 2"
putexcel A7 = "Duration 3"
putexcel A8 = "Duration 4"
putexcel A9 = "Duration 5"
putexcel A10 = "Duration 6"
putexcel A11 = "Duration 7"
putexcel A12 = "Duration 8"
putexcel A13 = "Duration 9"
putexcel A14 = "Duration 10"


local colu "B C D E F G H I"

forvalues s=0/10{
	local row = `s' + 4
	tab parent_paid_type`s', gen(kidpaid`s'_)
	forvalues x=1/8{ 
		local col: word `x' of `colu'
		mean kidpaid`s'_`x'
		matrix kidpaid`s'_`x'= e(b)
		putexcel `col'`row' = matrix(kidpaid`s'_`x'), nformat(#.#%)
	}
}

local colu "J K L M N O"

forvalues s=0/10{
	local row = `s' + 4
	tab parent_unpaid_type`s', gen(kidhw`s'_)
	forvalues x=1/6{ 
		local col: word `x' of `colu'
		mean kidhw`s'_`x'
		matrix kidhw`s'_`x'= e(b)
		putexcel `col'`row' = matrix(kidhw`s'_`x'), nformat(#.#%)
	}
}

