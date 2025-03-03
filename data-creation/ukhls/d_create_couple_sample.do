********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: c_create_couple_sample.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* Restrict sample to just partnered
* decide later if should restrict to just survey years with the unpaid labor questions

********************************************************************************
********************************************************************************
**# Updated file format
********************************************************************************
********************************************************************************
use "$created_data_ukhls/UKHLS_full_sample_deduped.dta", clear

keep if record_type==3
keep if inlist(wavename, 1, 2, 4, 6, 8, 10, 12, 14) | inrange(wavename, 15, 32) // only keep waves with housework

gen long id_sp = pidp if sex==2
replace id_sp = partner_id if sex==1 & sex_sp==2
	
gen long id_rp = pidp if sex==1
replace id_rp = partner_id if sex==2 & sex_sp==1

browse pidp partner_id sex sex_sp id_sp id_rp

rename int_year_wom year_sp
rename int_year_man year_rp
rename ind_weight_wom weight_sp
rename ind_weight_man weight_rp
rename age_all_wom age_sp
rename age_all_man age_rp
rename howlng_wom hw_sp
rename howlng_man hw_rp
rename hh_weight_hh weight_hh
rename wavename wave

drop sex_sp

gen sex_sp = 2
gen sex_rp = 1

keep id_rp id_sp wave year_rp year_sp weight_rp weight_sp weight_hh age_rp age_sp hw_rp hw_sp sex_rp sex_sp

egen hhid = group(id_rp id_sp)
sort id_rp id_sp year_rp

save "$created_data_ukhls/UKHLS_relative_density.dta", replace

********************************************************************************
********************************************************************************
**# Original
********************************************************************************
********************************************************************************

********************************************************************************
* Import data
********************************************************************************
use "$created_data_ukhls/UKHLS_matched.dta", clear

********************************************************************************
* Relationship recodes
********************************************************************************

sort pidp year
browse pidp year partnered marital_status_defacto rel_start marr_trans rel_end partner_id howlng howlng_sp
// this pidp did have transition 16339 - okay confirmed it worked. (I moved up the relationship transition codes)

// drop people without partners
keep if partnered==1 | rel_start==1 | marr_trans==1 | rel_end==1

// drop same-sex couples?!
tab sex sex_sp, m
drop if sex==sex_sp
drop if inlist(sex,-9,0) | inlist(sex_sp,-9,0)

// okay want to try to figure out things like relationship duration and relationship order, as some might have married prior to entering the survey. not sure if I have to merge partner history.
tab nmar survey, m // ukhls, but a lot of inapplicable? I think this variable is only for new entrants?! is there one maybe in the cross-wave file, then?!
tab nmar_bh survey, m // same with bhps
tab mh_ttl_spells survey, m

browse pidp marital_status_defacto partner_id mh_partner1 mh_status1 mh_partner2 mh_status2 mh_partner3 mh_status3 mh_partner4 mh_status4

// okay duration info
gen current_rel_duration=.
replace current_rel_duration = int_year-current_rel_start_year
browse pidp int_year istrtdatm current_rel_duration current_rel_start_year current_rel_start_month

********************************************************************************
* Division of Labor recodes
********************************************************************************
// create DoL variables for the two continuous variables

**Paid labor: no overtime
egen paid_couple_total = rowtotal(jbhrs jbhrs_sp)
gen paid_wife_pct=jbhrs / paid_couple_total if sex==2 & sex_sp==1
replace paid_wife_pct=jbhrs_sp / paid_couple_total if sex==1 & sex_sp==2
sum paid_wife_pct
browse pidp year sex sex_sp jbhrs jbhrs_sp paid_couple_total paid_wife_pct

gen paid_dol=.
replace paid_dol = 1 if paid_wife_pct>=0.400000 & paid_wife_pct<=0.600000 // shared
replace paid_dol = 2 if paid_wife_pct <0.400000 & paid_wife_pct!=. // husband does more
replace paid_dol = 3 if paid_wife_pct >0.600000 & paid_wife_pct!=. // wife does more
replace paid_dol = 4 if jbhrs==0 & jbhrs_sp==0 // neither works

tab partner_match paid_dol, m // okay not quite sure what to do for the couples without a match...or when one partner is missing and the other is not. count as 0s? or ignore?
browse partner_match age_all age_all_sp jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct if paid_dol==. & partner_match==1 //
browse partner_match paid_dol age_all age_all_sp jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct // also a lot of neither works... is that concerning? so a bunch are retirement age, but also a lot are not... but should probably make an upper age limit?
tab paid_dol if age_all<=65

label define paid_dol 1 "Shared" 2 "Husband more" 3 "Wife more" 4 "Neither works"
label values paid_dol paid_dol

**Paid labor: with overtime
egen paid_couple_total_ot = rowtotal(total_hours total_hours_sp)
gen paid_wife_pct_ot=total_hours / paid_couple_total_ot if sex==2 & sex_sp==1
replace paid_wife_pct_ot=total_hours_sp / paid_couple_total_ot if sex==1 & sex_sp==2
sum paid_wife_pct
sum paid_wife_pct_ot

browse pidp year sex sex_sp total_hours total_hours_sp paid_couple_total_ot paid_wife_pct_ot

gen paid_dol_ot=.
replace paid_dol_ot = 1 if paid_wife_pct_ot>=0.400000 & paid_wife_pct_ot<=0.600000 // shared
replace paid_dol_ot = 2 if paid_wife_pct_ot <0.400000 & paid_wife_pct_ot!=. // husband does more
replace paid_dol_ot = 3 if paid_wife_pct_ot >0.600000 & paid_wife_pct_ot!=. // wife does more
replace paid_dol_ot = 4 if total_hours==0 & total_hours_sp==0 // neither works

label values paid_dol_ot paid_dol

**Paid labor: earnings.
/*
https://www.understandingsociety.ac.uk/documentation/mainstage/user-guides/main-survey-user-guide/individual-income-variables/.
fimnlabnet_dv // net labor (but I think only waves 1-13) . I feel like i should use this per guide, but is there a bhps equivalent?
// this is the sum of: net usual pay (w_paynu_dv); net self-employment income (w_seearnnet_dv); net pay in second job (w_j2paynet_dv). so I only poulled in net usual pay?
paynu_dv // usual net pay per month: current job - okay so this is all waves
w_seearnnet_dv // okay this is only ukhls (i didn't pull this in)
j2paynet_dv // okay also only ukhls
fimngrs_dv // total monthly personal income gross - so more than labor
payg_dv // gross pay per month in current job: last payment. not sure how this is diff to above? okay when it's there, quite similar, but has a lot of inapplicable
paygu_dv // usual gross pay per month: current job. derived from above, also not sure how diff to total gross. is this because just one job not total? same here
payn_dv // net pay per month in current job: last payment. okay yeah also not sure how diff to paynu
paynl // takehome pay at last payment
*/

browse pidp survey year employed fimnlabgrs_dv fimnlabnet_dv paynu_dv // there are a lot of 0s in net pay where gross is not 0, which doesn't make sense.

inspect fimnlabgrs_dv // total monthly labor income gross - this would probably be second choice?
inspect fimnlabnet_dv // total monthly labor income net - only wave 1-13, probably first choice
inspect paynu_dv // in bhps, only component of above I think, but ukhls has more, so might be less than above
// other option. compare the net v. gross at least for ukhls and see how much of a big deal it is?

// okay actually create variable. okay will this be problematic because of negative? lol yes
egen paid_couple_earnings = rowtotal(fimnlabgrs_dv fimnlabgrs_dv_sp)
gen paid_earn_pct=fimnlabgrs_dv / paid_couple_earnings if sex==2 & sex_sp==1
replace paid_earn_pct=fimnlabgrs_dv_sp / paid_couple_earnings if sex==1 & sex_sp==2
sum paid_earn_pct
browse pidp year employed partner_match sex sex_sp fimnlabgrs_dv fimnlabgrs_dv_sp paid_couple_earnings paid_earn_pct if paid_earn_pct < 0 | (paid_earn_pct > 1 & paid_earn_pct!=.)

gen hh_earn_type=.
replace hh_earn_type = 1 if paid_earn_pct>=0.400000 & paid_earn_pct<=0.600000 // shared
replace hh_earn_type = 2 if paid_earn_pct <0.400000 & paid_earn_pct!=. // husband does more
replace hh_earn_type = 3 if paid_earn_pct >0.600000 & paid_earn_pct!=. // wife does more
replace hh_earn_type = 4 if fimnlabgrs_dv==0 & fimnlabgrs_dv_sp==0 // neither works
replace hh_earn_type=. if paid_earn_pct < 0 | (paid_earn_pct > 1 & paid_earn_pct!=.)

label values hh_earn_type paid_dol

tab partner_match paid_dol, m // okay not quite sure what to do for the couples without a match...or when one partner is missing and the other is not. count as 0s? or ignore?
browse partner_match age_all age_all_sp jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct if paid_dol==. & partner_match==1 //
browse partner_match paid_dol age_all age_all_sp jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct // also a lot of neither works... is that concerning? so a bunch are retirement age, but also a lot are not... but should probably make an upper age limit?
tab paid_dol if age_all<=65

**Unpaid labor
egen unpaid_couple_total = rowtotal(howlng howlng_sp)
gen unpaid_wife_pct=howlng / unpaid_couple_total if sex==2 & sex_sp==1
replace unpaid_wife_pct=howlng_sp / unpaid_couple_total if sex==1 & sex_sp==2
sum unpaid_wife_pct
browse pidp year sex sex_sp howlng howlng_sp unpaid_couple_total unpaid_wife_pct

gen unpaid_dol=.
replace unpaid_dol = 1 if unpaid_wife_pct>=0.400000 & unpaid_wife_pct<=0.600000 // shared
replace unpaid_dol = 2 if unpaid_wife_pct >0.600000 & unpaid_wife_pct!=. // wife does more
replace unpaid_dol = 3 if unpaid_wife_pct <0.400000 & unpaid_wife_pct!=. // husband does more
replace unpaid_dol = 4 if howlng==0 & howlng_sp==0 // neither works

label define unpaid_dol 1 "Shared" 2 "Wife more" 3 "Husband more" 4 "No one"
label values unpaid_dol unpaid_dol

tab partner_match unpaid_dol if howlng_flag==1, m row
tab wavename unpaid_dol, m

browse partner_match howlng howlng_sp unpaid_couple_total unpaid_wife_pct if unpaid_dol==. & howlng_flag==1 // okay a lot of missing, even when matched. need to figure out eligibility. okay, at one point says only asked January to June? need to figure it out, because coverage looks very high in the codebook... okay, but did a lot of checks and it actually seems right...
browse survey year wavename istrtdatm howlng if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31)

tab howlng howlng_flag, m

********************************************************************************
* Other recodes
********************************************************************************
// children
gen kids_in_hh=0
replace kids_in_hh=1 if nkids_dv > 0 & nkids_dv!=. // binary as to whether or not they have kids currently

// need to figure out how to INCREMENT births. do same I did in US - if number of kids goes up AND the age of youngest child is either 0/1 (look at codebook) - okay think it's 0 because otherwise it's inapplicable
tab agechy_dv survey, m
tab nch02_dv survey, m
tab nkids_dv, m

browse pidp year nkids_dv nch02_dv agechy_dv

gen had_birth=0
replace had_birth=1 if nch02_dv == nch02_dv[_n-1]+1 & agechy_dv==0 & pidp==pidp[_n-1] & year==year[_n-1]+1
// browse pidp year nkids_dv nch02_dv agechy_dv had_birth

// gen had_first_birth=0 // want to do this, but need to figure out how to get this info (not currently in file, might be in cross wave files?
// replace had_first_birth=1 if had_birth==1 & (survey_yr==FIRST_BIRTH_YR | survey_yr==FIRST_BIRTH_YR+1) // think sometimes recorded a year late

gen had_first_birth_alt=0
replace had_first_birth_alt=1 if nkids_dv==1 & nkids_dv[_n-1]==0 & agechy_dv==0 & pidp==pidp[_n-1] & year==year[_n-1]+1 // use number of kids NOT kids under 2, because they could have older kids, so this is the most restrictive, like no kids at all prior? 
browse pidp year nkids_dv nch02_dv agechy_dv had_birth had_first_birth_alt

// eventually need to figure out when first birth was (if not during survey a la above) to denote in time relative to marriage


********************************************************************************
* Finally drop if no partner match or sex of each partner is unclear
********************************************************************************
drop if partner_match==0
drop if sex==. | sex_sp==.

save "$created_data_ukhls/UKHLS_matched_cleaned.dta", replace

********************************************************************************
**# Create some preliminary descriptive statistics
* Eventually will automate this once more things are figured out
********************************************************************************
tab sex if partner_match==1 & partnered==1, m // so just use women's responses because right now, have multiple records per HH, right?
browse survey year partnered pidp partner_id hidp

// unique couples - then by marital status (married, cohab, transitioned)
unique pidp partner_id if partner_match==1 & partnered==1
unique pidp partner_id if partner_match==1 & partnered==1 & sex==2
unique pidp partner_id if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
// unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & wavename!=14
// unique pidp partner_id if partner_match==1 & partnered==1 & sex==2  & wavename!=14, by(marital_status_defacto) // this matches existing codebook exactly
tab marital_status_defacto if partner_match==1 & partnered==1 & sex==2

unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & howlng_flag==1
unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & howlng_flag==1, by(marital_status_defacto)
// unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & howlng_flag==1 & wavename!=14
// unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & howlng_flag==1 & wavename!=14, by(marital_status_defacto)
tab marital_status_defacto if partner_match==1 & partnered==1 & sex==2 & howlng_flag==1

// then DoL - but not quite sure what to do when unmatched...
**Paid / Unpaid
sum jbhrs if partner_match==1 & partnered==1 & sex==2, detail
sum jbhrs_sp if partner_match==1 & partnered==1 & sex==2, detail // do these match (e.g. if spouse of woman or man himself replying?) essentially yes
sum jbhrs if partner_match==1 & partnered==1 & sex==1, detail // do these match?

sum total_hours if partner_match==1 & partnered==1 & sex==2, detail
sum total_hours_sp if partner_match==1 & partnered==1 & sex==2, detail

sum total_hours if partner_match==1 & partnered==1 & sex==2 & employed==1, detail
sum total_hours_sp if partner_match==1 & partnered==1 & sex==2 & employed_sp==1, detail

tabstat jbhrs_sp jbhrs total_hours_sp total_hours if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tabstat jbhrs_sp total_hours_sp if partner_match==1 & partnered==1 & sex==2 & employed_sp==1, by(marital_status_defacto)
tabstat jbhrs total_hours if partner_match==1 & partnered==1 & sex==2 & employed==1, by(marital_status_defacto)

tabstat paid_wife_pct_ot unpaid_wife_pct if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tab marital_status_defacto paid_dol_ot if partner_match==1 & partnered==1 & sex==2, row
tabstat howlng howlng_sp unpaid_wife_pct if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tab marital_status_defacto unpaid_dol if partner_match==1 & partnered==1 & sex==2, row

**Categorical by gender
tab marital_status_defacto hubuys if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
// tab marital_status_defacto hubuys_sp if partner_match==1 & partnered==1 & sex==2, row // men's responses
tab marital_status_defacto hubuys if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto hufrys if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto hufrys if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto huiron if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto huiron if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto humops if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto humops if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto huboss if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto huboss if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto husits if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto husits if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

// then describe couples (age, education, race - except need to figure some of these out, might need to get from cross-wave file)
tabstat current_rel_duration age_all age_all_sp if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)

tab marital_status_defacto country_all if partner_match==1 & partnered==1 & sex==2, row nofreq

tab marital_status_defacto kids_in_hh if partner_match==1 & partnered==1 & sex==2, row

fre hiqual_dv
tab marital_status_defacto hiqual_dv if partner_match==1 & partnered==1 & sex==2, row nofreq // this is probably not the best education to use, but will use for now.
tab marital_status_defacto hiqual_dv_sp if partner_match==1 & partnered==1 & sex==2, row nofreq // this is probably not the best education to use, but will use for now.
tab marital_status_defacto hiqual_dv if partner_match==1 & partnered==1 & sex==1, row nofreq // this is probably not the best education to use, but will use for now.
