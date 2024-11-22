
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: imputation_for_individs
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files uses the wide data and examines multiple methods of imputing missing data

********************************************************************************
* Stata MI Impute
********************************************************************************
use "$created_data\individs_by_duration_wide.dta", clear
misstable summarize FIRST_BIRTH_YR age_focal* birth_yr_all SEX raceth_fixed_focal sample_type rel_start_all, all

egen nmis_workhrs = rmiss(weekly_hrs_t1_focal*)
tab nmis_workhrs, m

egen nmis_hwhrs = rmiss(housework_focal*)
tab nmis_hwhrs, m

egen nmis_age = rmiss(age_focal*)
tab nmis_age, m

drop if nmis_age==17 // for now, just so this is actually complete
drop if birth_yr_all==. // for now, just so this is actually complete
drop if raceth_fixed_focal==. // for now, just so this is actually complete

********************************************************************************
* Attempting all core variables 
********************************************************************************
mi set wide
mi register imputed weekly_hrs_t_focal* housework_focal* employed_focal* earnings_t_focal* educ_focal* college_focal* children* NUM_CHILDREN_* AGE_YOUNG_CHILD_* relationship_* partnered* TOTAL_INCOME_T_FAMILY*
mi register regular FIRST_BIRTH_YR birth_yr_all rel_start_all SEX raceth_fixed_focal sample_type

#delimit ;

mi impute chained

/* Employment hours */
(pmm, knn(5) include (                weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16 housework_focal0)) weekly_hrs_t_focal0
(pmm, knn(5) include (               weekly_hrs_t_focal0 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16  housework_focal1)) weekly_hrs_t_focal1
(pmm, knn(5) include (              weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16   housework_focal2)) weekly_hrs_t_focal2
(pmm, knn(5) include (             weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16    housework_focal3)) weekly_hrs_t_focal3
(pmm, knn(5) include (            weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16     housework_focal4)) weekly_hrs_t_focal4
(pmm, knn(5) include (           weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16      housework_focal5)) weekly_hrs_t_focal5
(pmm, knn(5) include (          weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16       housework_focal6)) weekly_hrs_t_focal6
(pmm, knn(5) include (         weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16        housework_focal7)) weekly_hrs_t_focal7
(pmm, knn(5) include (        weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16         housework_focal8)) weekly_hrs_t_focal8
(pmm, knn(5) include (       weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16          housework_focal9)) weekly_hrs_t_focal9
(pmm, knn(5) include (      weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16           housework_focal10)) weekly_hrs_t_focal10
(pmm, knn(5) include (     weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16            housework_focal11)) weekly_hrs_t_focal11
(pmm, knn(5) include (    weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16             housework_focal12)) weekly_hrs_t_focal12
(pmm, knn(5) include (   weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16              housework_focal13)) weekly_hrs_t_focal13
(pmm, knn(5) include (  weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal15 weekly_hrs_t_focal16               housework_focal14)) weekly_hrs_t_focal14
(pmm, knn(5) include ( weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal16                housework_focal15)) weekly_hrs_t_focal15
(pmm, knn(5) include (weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15                 housework_focal16)) weekly_hrs_t_focal16


/* Housework hours */
(pmm, knn(5) include (                housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16 weekly_hrs_t_focal0)) housework_focal0
(pmm, knn(5) include (               housework_focal0 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16  weekly_hrs_t_focal1)) housework_focal1
(pmm, knn(5) include (              housework_focal0 housework_focal1 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16   weekly_hrs_t_focal2)) housework_focal2
(pmm, knn(5) include (             housework_focal0 housework_focal1 housework_focal2 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16    weekly_hrs_t_focal3)) housework_focal3
(pmm, knn(5) include (            housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16     weekly_hrs_t_focal4)) housework_focal4
(pmm, knn(5) include (           housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16      weekly_hrs_t_focal5)) housework_focal5
(pmm, knn(5) include (          housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16       weekly_hrs_t_focal6)) housework_focal6
(pmm, knn(5) include (         housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16        weekly_hrs_t_focal7)) housework_focal7
(pmm, knn(5) include (        housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16         weekly_hrs_t_focal8)) housework_focal8
(pmm, knn(5) include (       housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16          weekly_hrs_t_focal9)) housework_focal9
(pmm, knn(5) include (      housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16           weekly_hrs_t_focal10)) housework_focal10
(pmm, knn(5) include (     housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16            weekly_hrs_t_focal11)) housework_focal11
(pmm, knn(5) include (    housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal13 housework_focal14 housework_focal15 housework_focal16             weekly_hrs_t_focal12)) housework_focal12
(pmm, knn(5) include (   housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal14 housework_focal15 housework_focal16              weekly_hrs_t_focal13)) housework_focal13
(pmm, knn(5) include (  housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal15 housework_focal16               weekly_hrs_t_focal14)) housework_focal14
(pmm, knn(5) include ( housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal16                weekly_hrs_t_focal15)) housework_focal15
(pmm, knn(5) include (housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15                 weekly_hrs_t_focal16)) housework_focal16

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all i.SEX i.raceth_fixed_focal i.sample_type, chaindots add(10) rseed(12345) noimputed // dryrun // force augment noisily

;
#delimit cr

save "$created_data/psid_individs_imputed_wide", replace

// reshape back to long to look at descriptives
mi reshape long in_sample_ relationship_  partnered weekly_hrs_t1_focal earnings_t1_focal housework_focal employed_focal educ_focal college_focal age_focal weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal start_yr_employer_focal yrs_employer_focal children FAMILY_INTERVIEW_NUM_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ TOTAL_INCOME_T1_FAMILY_ hours_type_t1_focal hw_hours_gp raceth_focal weekly_hrs_t_focal earnings_t_focal TOTAL_INCOME_T_FAMILY childcare_focal adultcare_focal TOTAL_INCOME_T2_FAMILY_ ///
, i(couple_id unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX) j(duration_rec)

mi convert flong

browse couple_id unique_id partner_id duration_rec weekly_hrs_t_focal housework_focal _mi_miss _mi_m _mi_id
gen imputed=0
replace imputed=1 if inrange(_mi_m,1,10)

inspect weekly_hrs_t_focal if imputed==0
inspect weekly_hrs_t_focal if imputed==1

inspect housework_focal if imputed==0
inspect housework_focal if imputed==1

// mi register regular n

save "$created_data/psid_individs_imputed_long", replace

********************************************************************************
*  Let's look at some descriptives
********************************************************************************
tabstat weekly_hrs_t_focal housework_focal, by(imputed) stats(mean sd p50)

preserve

collapse (mean) weekly_hrs_t_focal housework_focal, by(duration_rec imputed)

twoway (line weekly_hrs_t_focal duration_rec if imputed==0) (line weekly_hrs_t_focal duration_rec if imputed==1), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))
twoway (line housework_focal duration_rec if imputed==0) (line housework_focal duration_rec if imputed==1), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))

restore

********************************************************************************
**# * Let's try by sex
********************************************************************************
use "$created_data\individs_by_duration_wide.dta", clear

egen nmis_age = rmiss(age_focal*)
tab nmis_age, m

drop if nmis_age==17 // for now, just so this is actually complete
drop if birth_yr_all==. // for now, just so this is actually complete
drop if raceth_fixed_focal==. // for now, just so this is actually complete

mi set wide
mi register imputed weekly_hrs_t_focal* housework_focal* employed_focal* earnings_t_focal* educ_focal* college_focal* children* NUM_CHILDREN_* AGE_YOUNG_CHILD_* relationship_* partnered* TOTAL_INCOME_T_FAMILY*
mi register regular FIRST_BIRTH_YR birth_yr_all rel_start_all SEX raceth_fixed_focal sample_type

#delimit ;

mi impute chained

/* Employment hours */
(pmm, knn(5) include (                weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16 housework_focal0)) weekly_hrs_t_focal0
(pmm, knn(5) include (               weekly_hrs_t_focal0 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16  housework_focal1)) weekly_hrs_t_focal1
(pmm, knn(5) include (              weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16   housework_focal2)) weekly_hrs_t_focal2
(pmm, knn(5) include (             weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16    housework_focal3)) weekly_hrs_t_focal3
(pmm, knn(5) include (            weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16     housework_focal4)) weekly_hrs_t_focal4
(pmm, knn(5) include (           weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16      housework_focal5)) weekly_hrs_t_focal5
(pmm, knn(5) include (          weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16       housework_focal6)) weekly_hrs_t_focal6
(pmm, knn(5) include (         weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16        housework_focal7)) weekly_hrs_t_focal7
(pmm, knn(5) include (        weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16         housework_focal8)) weekly_hrs_t_focal8
(pmm, knn(5) include (       weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16          housework_focal9)) weekly_hrs_t_focal9
(pmm, knn(5) include (      weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16           housework_focal10)) weekly_hrs_t_focal10
(pmm, knn(5) include (     weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16            housework_focal11)) weekly_hrs_t_focal11
(pmm, knn(5) include (    weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16             housework_focal12)) weekly_hrs_t_focal12
(pmm, knn(5) include (   weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal14 weekly_hrs_t_focal15 weekly_hrs_t_focal16              housework_focal13)) weekly_hrs_t_focal13
(pmm, knn(5) include (  weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal15 weekly_hrs_t_focal16               housework_focal14)) weekly_hrs_t_focal14
(pmm, knn(5) include ( weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal16                housework_focal15)) weekly_hrs_t_focal15
(pmm, knn(5) include (weekly_hrs_t_focal0 weekly_hrs_t_focal1 weekly_hrs_t_focal2 weekly_hrs_t_focal3 weekly_hrs_t_focal4 weekly_hrs_t_focal5 weekly_hrs_t_focal6 weekly_hrs_t_focal7 weekly_hrs_t_focal8 weekly_hrs_t_focal9 weekly_hrs_t_focal10 weekly_hrs_t_focal11 weekly_hrs_t_focal12 weekly_hrs_t_focal13 weekly_hrs_t_focal14 weekly_hrs_t_focal15                 housework_focal16)) weekly_hrs_t_focal16


/* Housework hours */
(pmm, knn(5) include (                housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16 weekly_hrs_t_focal0)) housework_focal0
(pmm, knn(5) include (               housework_focal0 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16  weekly_hrs_t_focal1)) housework_focal1
(pmm, knn(5) include (              housework_focal0 housework_focal1 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16   weekly_hrs_t_focal2)) housework_focal2
(pmm, knn(5) include (             housework_focal0 housework_focal1 housework_focal2 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16    weekly_hrs_t_focal3)) housework_focal3
(pmm, knn(5) include (            housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16     weekly_hrs_t_focal4)) housework_focal4
(pmm, knn(5) include (           housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16      weekly_hrs_t_focal5)) housework_focal5
(pmm, knn(5) include (          housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16       weekly_hrs_t_focal6)) housework_focal6
(pmm, knn(5) include (         housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16        weekly_hrs_t_focal7)) housework_focal7
(pmm, knn(5) include (        housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16         weekly_hrs_t_focal8)) housework_focal8
(pmm, knn(5) include (       housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16          weekly_hrs_t_focal9)) housework_focal9
(pmm, knn(5) include (      housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16           weekly_hrs_t_focal10)) housework_focal10
(pmm, knn(5) include (     housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16            weekly_hrs_t_focal11)) housework_focal11
(pmm, knn(5) include (    housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal13 housework_focal14 housework_focal15 housework_focal16             weekly_hrs_t_focal12)) housework_focal12
(pmm, knn(5) include (   housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal14 housework_focal15 housework_focal16              weekly_hrs_t_focal13)) housework_focal13
(pmm, knn(5) include (  housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal15 housework_focal16               weekly_hrs_t_focal14)) housework_focal14
(pmm, knn(5) include ( housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal16                weekly_hrs_t_focal15)) housework_focal15
(pmm, knn(5) include (housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15                 weekly_hrs_t_focal16)) housework_focal16

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all i.raceth_fixed_focal i.sample_type, chaindots add(10) rseed(12345) noimputed by(SEX) // dryrun force augment noisily

;
#delimit cr

save "$created_data/psid_individs_imputed_wide_bysex", replace

// reshape back to long to look at descriptives
mi reshape long in_sample_ relationship_  partnered weekly_hrs_t1_focal earnings_t1_focal housework_focal employed_focal educ_focal college_focal age_focal weekly_hrs_t2_focal earnings_t2_focal employed_t2_focal start_yr_employer_focal yrs_employer_focal children FAMILY_INTERVIEW_NUM_ NUM_CHILDREN_ AGE_YOUNG_CHILD_ TOTAL_INCOME_T1_FAMILY_ hours_type_t1_focal hw_hours_gp raceth_focal weekly_hrs_t_focal earnings_t_focal TOTAL_INCOME_T_FAMILY childcare_focal adultcare_focal TOTAL_INCOME_T2_FAMILY_ ///
, i(couple_id unique_id partner_id rel_start_all min_dur max_dur rel_end_yr last_yr_observed ended SEX) j(duration_rec)

mi convert flong

browse couple_id unique_id partner_id SEX duration_rec weekly_hrs_t_focal housework_focal _mi_miss _mi_m _mi_id
gen imputed=0
replace imputed=1 if inrange(_mi_m,1,10)

inspect weekly_hrs_t_focal if imputed==0
inspect weekly_hrs_t_focal if imputed==1

inspect housework_focal if imputed==0
inspect housework_focal if imputed==1

// mi register regular n

save "$created_data/psid_individs_imputed_long_bysex", replace

********************************************************************************
*  Let's look at some descriptives
********************************************************************************
tabstat weekly_hrs_t_focal housework_focal, by(imputed) stats(mean sd p50)
tabstat weekly_hrs_t_focal housework_focal if SEX==1, by(imputed) stats(mean sd p50)
tabstat weekly_hrs_t_focal housework_focal if SEX==2, by(imputed) stats(mean sd p50)

preserve

collapse (mean) weekly_hrs_t_focal housework_focal, by(duration_rec imputed)

twoway (line weekly_hrs_t_focal duration_rec if imputed==0) (line weekly_hrs_t_focal duration_rec if imputed==1), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))
twoway (line housework_focal duration_rec if imputed==0) (line housework_focal duration_rec if imputed==1), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))

restore

preserve

collapse (mean) weekly_hrs_t_focal housework_focal, by(SEX duration_rec imputed)

// men
twoway (line weekly_hrs_t_focal duration_rec if imputed==0 & SEX==1) (line weekly_hrs_t_focal duration_rec if imputed==1 & SEX==1), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))
twoway (line housework_focal duration_rec if imputed==0 & SEX==1) (line housework_focal duration_rec if imputed==1 & SEX==1), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))

// women - okay so it is women where the disparities are primarily. is it bc of EMPLOYMENT STATUS?! need to do conditional on that? let's see if it improves with other predictors, bc employment status not currently included
twoway (line weekly_hrs_t_focal duration_rec if imputed==0 & SEX==2) (line weekly_hrs_t_focal duration_rec if imputed==1 & SEX==2), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))
twoway (line housework_focal duration_rec if imputed==0 & SEX==2) (line housework_focal duration_rec if imputed==1 & SEX==2), legend(order(1 "Observed" 2 "Imputed") rows(1) position(6))

restore

********************************************************************************
********************************************************************************
**# * Troubleshooting area
********************************************************************************
********************************************************************************

********************************************************************************
* Can I get this to work with just one time varying variable?
********************************************************************************

mi set wide
mi register imputed weekly_hrs_t1_focal*
mi register regular FIRST_BIRTH_YR birth_yr_all rel_start_all

#delimit ;

mi impute chained

(pmm, knn(5) include (                weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16)) weekly_hrs_t1_focal0
(pmm, knn(5) include (               weekly_hrs_t1_focal0 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16 )) weekly_hrs_t1_focal1
(pmm, knn(5) include (              weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16  )) weekly_hrs_t1_focal2
(pmm, knn(5) include (             weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16   )) weekly_hrs_t1_focal3
(pmm, knn(5) include (            weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16    )) weekly_hrs_t1_focal4
(pmm, knn(5) include (           weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16     )) weekly_hrs_t1_focal5
(pmm, knn(5) include (          weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16      )) weekly_hrs_t1_focal6
(pmm, knn(5) include (         weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16       )) weekly_hrs_t1_focal7
(pmm, knn(5) include (        weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16        )) weekly_hrs_t1_focal8
(pmm, knn(5) include (       weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16         )) weekly_hrs_t1_focal9
(pmm, knn(5) include (      weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16          )) weekly_hrs_t1_focal10
(pmm, knn(5) include (     weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16           )) weekly_hrs_t1_focal11
(pmm, knn(5) include (    weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16            )) weekly_hrs_t1_focal12
(pmm, knn(5) include (   weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16             )) weekly_hrs_t1_focal13
(pmm, knn(5) include (  weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16              )) weekly_hrs_t1_focal14
(pmm, knn(5) include ( weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal16               )) weekly_hrs_t1_focal15
(pmm, knn(5) include (weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15                )) weekly_hrs_t1_focal16

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all, chaindots force add(1) rseed(12345) noimputed // dryrun

;
#delimit cr

/*
do I need less predictors? NO you just needed to include ALL of the weekly hours variables 0 - 16
log using "$logdir/mi_troubleshoot.log", replace

mi set wide
mi register imputed weekly_hrs_t1_focal*
mi register regular FIRST_BIRTH_YR birth_yr_all rel_start_all

// for LP:
mi describe
mi misstable summarize

// run your imputation model with the dryrun option. You can probably remove the augment option for now.

#delimit ;

mi impute chained

(pmm, knn(5) include (          weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8        )) weekly_hrs_t1_focal4
(pmm, knn(5) include (          weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9        )) weekly_hrs_t1_focal5
(pmm, knn(5) include (          weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10        )) weekly_hrs_t1_focal6
(pmm, knn(5) include (          weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11        )) weekly_hrs_t1_focal7
(pmm, knn(5) include (          weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12        )) weekly_hrs_t1_focal8
(pmm, knn(5) include (          weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13        )) weekly_hrs_t1_focal9
(pmm, knn(5) include (          weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14        )) weekly_hrs_t1_focal10
(pmm, knn(5) include (          weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15        )) weekly_hrs_t1_focal11
(pmm, knn(5) include (          weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16        )) weekly_hrs_t1_focal12
(pmm, knn(5) include (          weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16         )) weekly_hrs_t1_focal13
(pmm, knn(5) include (          weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16          )) weekly_hrs_t1_focal14

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all, chaindots force add(10) rseed(12345) dryrun noimputed

;
#delimit cr

log close
*/

********************************************************************************
* No observations
********************************************************************************

regress housework_focal4 housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16 weekly_hrs_t1_focal4 employed_focal4 earnings_t1_focal4 educ_focal4 children4 NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 relationship_4 partnered4 TOTAL_INCOME_T1_FAMILY_4 race_fixed_focal 

regress housework_focal4 housework_focal2 housework_focal3 housework_focal5 housework_focal6 weekly_hrs_t1_focal4 employed_focal4 earnings_t1_focal4 educ_focal4 children4 NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 relationship_4 partnered4 TOTAL_INCOME_T1_FAMILY_4 race_fixed_focal 

regress housework_focal9 housework_focal7 housework_focal8 housework_focal10 housework_focal11 weekly_hrs_t1_focal4 employed_focal4 earnings_t1_focal4 educ_focal4 children4 NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 relationship_4 partnered4 TOTAL_INCOME_T1_FAMILY_4 race_fixed_focal 

