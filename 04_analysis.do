********************************************************************************
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: analysis
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files actually conducts the analysis

********************************************************************************
* Import data and small final sample cleanup
********************************************************************************
use "$created_data\PSID_partners_cleaned.dta", clear

tab SEX marital_status_updated if SEX_HEAD_==1
/* need to end up with this amount of respondents after the below
           | marital_status_update
    SEX OF |           d
INDIVIDUAL | Married (  Partnered |     Total
-----------+----------------------+----------
      Male |   159,508     10,819 |   170,327 
    Female |   159,508     10,803 |   170,311 
-----------+----------------------+----------
     Total |   319,016     21,622 |   340,638 
*/

drop if SEX_HEAD_!=1
tab rel_start_yr SEX, m // is either one's data more reliable?

// keep only one respondent per household (bc all data recorded for all)
sort survey_yr FAMILY_INTERVIEW_NUM_  unique_id   
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_start_yr female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

gen has_rel_info=0
replace has_rel_info=1 if rel_start_yr!=.

bysort survey_yr FAMILY_INTERVIEW_NUM_: egen rel_info = max(has_rel_info)
browse unique_id FAMILY_INTERVIEW_NUM_ survey_yr SEX marital_status_updated rel_info has_rel_info rel_start_yr female_earn_pct hh_earn_type female_hours_pct hh_hours_type wife_housework_pct housework_bkt

* first drop the partner WITHOUT rel info if at least one of them does
drop if has_rel_info==0 & rel_info==1

*then rank the remaining members
bysort survey_yr FAMILY_INTERVIEW_NUM_ : egen per_id = rank(unique_id) // so if there is only one member left after above, will get a 1
browse survey_yr FAMILY_INTERVIEW_NUM_  unique_id per_id

tab per_id // 1s should approximately total above
keep if per_id==1

/* k pretty close

. tab marital_status_updated

marital_status_upd |
              ated |      Freq.     Percent        Cum.
-------------------+-----------------------------------
Married (or pre77) |    159,316       93.69       93.69
         Partnered |     10,730        6.31      100.00
-------------------+-----------------------------------
             Total |    170,046      100.00
*/

// should I restrict to certain years? aka to help with the cohab problem? well probably should from a time standpoint...
tab survey_yr marital_status_updated
tab rel_start_yr marital_status_updated, m

// restrict to working age?
tab AGE_REF_ employed_ly_head, row
keep if (AGE_REF_>=18 & AGE_REF_<=60) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=60) // sort of drops off a cliff after 60?

// identify couples who ever transitioned to marriage - but need to do WITHIN a given relationship?! except do cohab and marriage of same couple have diff start / end dates? because can just sort by unique ID and rel start year?! because those cover all records. okay yeah, crap, they do, let's try to figure this out.
tab marital_status_updated marr_trans, m

bysort unique_id (marr_trans): egen ever_transition = max(marr_trans)
gen year_transitioned=survey_yr if marr_trans==1
bysort unique_id (year_transitioned): replace year_transitioned = year_transitioned[1]

sort unique_id survey_yr
browse unique_id survey_yr marital_status_updated marr_trans rel_start_yr ever_transition year_transitioned

gen keep_flag=0
replace keep_flag=1 if ever_transition==1 & marital_status_updated==2 // keep all cohabs (except do have some risk that have multiple cohabs...)
replace keep_flag=1 if ever_transition==1 & marital_status_updated==1 & survey_yr >= year_transitioned // so only keep married AFTER year of transition. so might help weed out otehr marriages? that is why I want to test before I drop
replace keep_flag=0 if ever_transition==1 & rel_start_yr > year_transitioned+1 // soo if NEW relationship started post transition to marriage, shouldn't keep? that will rule out the multiple cohab issue I mention above - except will this knock out people if marriage year recorded as new year? so restrict to cohabs? add a one window buffer?

browse unique_id survey_yr marital_status_updated marr_trans rel_start_yr keep_flag ever_transition year_transitioned

********************************************************************************
**# okay make analytical sample and recode duration relative to marital transition
********************************************************************************
keep if keep_flag==1

gen duration_cohab=.
replace duration_cohab = survey_yr - year_transitioned

browse unique_id survey_yr marital_status_updated marr_trans rel_start_yr year_transitioned duration_cohab relationship_duration
tab duration_cohab, m

recode duration_cohab(-34/-11=-5)(-10/-7=-4)(-6/-5=-3)(-4/-3=-2)(-2/-1=-1)(0=0)(1/2=1)(3/4=2)(5/6=3)(7/8=4)(9/10=5)(11/12=6)(13/20=7)(21/40=8), gen(dur) // smoothing (bc the switch to every other year makes this wonky)

********************************************************************************
**# ANALYSIS (finally lol)
********************************************************************************
// descriptive

preserve
collapse (median) female_earn_pct female_hours_pct wife_housework_pct, by(dur)
twoway line female_earn_pct dur if dur>=-4 & dur <=6
twoway line female_hours_pct dur if dur>=-4 & dur <=6
twoway line wife_housework_pct dur if dur>=-4 & dur <=6

twoway (line female_earn_pct dur if dur>=-4 & dur <=6) (line wife_housework_pct dur if dur>=-4 & dur <=6)
twoway (line female_earn_pct dur if dur>=-4 & dur <=6) (line wife_housework_pct dur if dur>=-4 & dur <=6, yaxis(2))
restore