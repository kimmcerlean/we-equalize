
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
misstable summarize FIRST_BIRTH_YR age_focal*, all

egen nmis_workhrs = rmiss(weekly_hrs_t1_focal*)
tab nmis_workhrs, m

egen nmis_hwhrs = rmiss(housework_focal*)
tab nmis_hwhrs, m

egen nmis_age = rmiss(age_focal*)
tab nmis_age, m

drop if nmis_age==17 // for now, just so this is actually complete

mi set wide
mi register imputed weekly_hrs_t1_focal* housework_focal* employed_focal* earnings_t1_focal* educ_focal* college_focal* children* NUM_CHILDREN_* AGE_YOUNG_CHILD_* relationship_* partnered* TOTAL_INCOME_T1_FAMILY_* race_fixed_focal
mi register regular FIRST_BIRTH_YR age_focal* birth_yr_all rel_start_all

#delimit ;

mi impute chained

/* Employment hours */
(pmm, knn(5) include (          weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16 housework_focal4 i.employed_focal4 earnings_t1_focal4 i.educ_focal4 i.children4 i.NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 i.relationship_4 i.partnered4 TOTAL_INCOME_T1_FAMILY_4 i.race_fixed_focal)) weekly_hrs_t1_focal4
(pmm, knn(5) include (         weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16  housework_focal5 i.employed_focal5 earnings_t1_focal5 i.educ_focal5 i.children5 i.NUM_CHILDREN_5 AGE_YOUNG_CHILD_5 i.relationship_5 i.partnered5 TOTAL_INCOME_T1_FAMILY_5 i.race_fixed_focal)) weekly_hrs_t1_focal5
(pmm, knn(5) include (        weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16   housework_focal6 i.employed_focal6 earnings_t1_focal6 i.educ_focal6 i.children6 i.NUM_CHILDREN_6 AGE_YOUNG_CHILD_6 i.relationship_6 i.partnered6 TOTAL_INCOME_T1_FAMILY_6 i.race_fixed_focal)) weekly_hrs_t1_focal6
(pmm, knn(5) include (       weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16    housework_focal7 i.employed_focal7 earnings_t1_focal7 i.educ_focal7 i.children7 i.NUM_CHILDREN_7 AGE_YOUNG_CHILD_7 i.relationship_7 i.partnered7 TOTAL_INCOME_T1_FAMILY_7 i.race_fixed_focal)) weekly_hrs_t1_focal7
(pmm, knn(5) include (      weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16     housework_focal8 i.employed_focal8 earnings_t1_focal8 i.educ_focal8 i.children8 i.NUM_CHILDREN_8 AGE_YOUNG_CHILD_8 i.relationship_8 i.partnered8 TOTAL_INCOME_T1_FAMILY_8 i.race_fixed_focal)) weekly_hrs_t1_focal8
(pmm, knn(5) include (     weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16      housework_focal9 i.employed_focal9 earnings_t1_focal9 i.educ_focal9 i.children9 i.NUM_CHILDREN_9 AGE_YOUNG_CHILD_9 i.relationship_9 i.partnered9 TOTAL_INCOME_T1_FAMILY_9 i.race_fixed_focal)) weekly_hrs_t1_focal9
(pmm, knn(5) include (    weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16       housework_focal10 i.employed_focal10 earnings_t1_focal10 i.educ_focal10 i.children10 i.NUM_CHILDREN_10 AGE_YOUNG_CHILD_10 i.relationship_10 i.partnered10 TOTAL_INCOME_T1_FAMILY_10 i.race_fixed_focal)) weekly_hrs_t1_focal10
(pmm, knn(5) include (   weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16        housework_focal11 i.employed_focal11 earnings_t1_focal11 i.educ_focal11 i.children11 i.NUM_CHILDREN_11 AGE_YOUNG_CHILD_11 i.relationship_11 i.partnered11 TOTAL_INCOME_T1_FAMILY_11 i.race_fixed_focal)) weekly_hrs_t1_focal11
(pmm, knn(5) include (  weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16         housework_focal12 i.employed_focal12 earnings_t1_focal12 i.educ_focal12 i.children12 i.NUM_CHILDREN_12 AGE_YOUNG_CHILD_12 i.relationship_12 i.partnered12 TOTAL_INCOME_T1_FAMILY_12 i.race_fixed_focal)) weekly_hrs_t1_focal12
(pmm, knn(5) include ( weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16          housework_focal13 i.employed_focal13 earnings_t1_focal13 i.educ_focal13 i.children13 i.NUM_CHILDREN_13 AGE_YOUNG_CHILD_13 i.relationship_13 i.partnered13 TOTAL_INCOME_T1_FAMILY_13 i.race_fixed_focal)) weekly_hrs_t1_focal13
(pmm, knn(5) include (weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16           housework_focal14 i.employed_focal14 earnings_t1_focal14 i.educ_focal14 i.children14 i.NUM_CHILDREN_14 AGE_YOUNG_CHILD_14 i.relationship_14 i.partnered14 TOTAL_INCOME_T1_FAMILY_14 i.race_fixed_focal)) weekly_hrs_t1_focal14

/* Housework hours */
(pmm, knn(5) include (          housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal5 housework_focal6 housework_focal7 housework_focal8         weekly_hrs_t1_focal4 i.employed_focal4 earnings_t1_focal4 i.educ_focal4 i.children4 i.NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 i.relationship_4 i.partnered4 TOTAL_INCOME_T1_FAMILY_4 i.race_fixed_focal)) housework_focal4
(pmm, knn(5) include (          housework_focal1 housework_focal2 housework_focal3 housework_focal4 housework_focal6 housework_focal7 housework_focal8 housework_focal9         weekly_hrs_t1_focal5 i.employed_focal5 earnings_t1_focal5 i.educ_focal5 i.children5 i.NUM_CHILDREN_5 AGE_YOUNG_CHILD_5 i.relationship_5 i.partnered5 TOTAL_INCOME_T1_FAMILY_5 i.race_fixed_focal)) housework_focal5
(pmm, knn(5) include (          housework_focal2 housework_focal3 housework_focal4 housework_focal5 housework_focal7 housework_focal8 housework_focal9 housework_focal10         weekly_hrs_t1_focal6 i.employed_focal6 earnings_t1_focal6 i.educ_focal6 i.children6 i.NUM_CHILDREN_6 AGE_YOUNG_CHILD_6 i.relationship_6 i.partnered6 TOTAL_INCOME_T1_FAMILY_6 i.race_fixed_focal)) housework_focal6
(pmm, knn(5) include (          housework_focal3 housework_focal4 housework_focal5 housework_focal6 housework_focal8 housework_focal9 housework_focal10 housework_focal11         weekly_hrs_t1_focal7 i.employed_focal7 earnings_t1_focal7 i.educ_focal7 i.children7 i.NUM_CHILDREN_7 AGE_YOUNG_CHILD_7 i.relationship_7 i.partnered7 TOTAL_INCOME_T1_FAMILY_7 i.race_fixed_focal)) housework_focal7
(pmm, knn(5) include (          housework_focal4 housework_focal5 housework_focal6 housework_focal7 housework_focal9 housework_focal10 housework_focal11 housework_focal12         weekly_hrs_t1_focal8 i.employed_focal8 earnings_t1_focal8 i.educ_focal8 i.children8 i.NUM_CHILDREN_8 AGE_YOUNG_CHILD_8 i.relationship_8 i.partnered8 TOTAL_INCOME_T1_FAMILY_8 i.race_fixed_focal)) housework_focal8
(pmm, knn(5) include (          housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal10 housework_focal11 housework_focal12 housework_focal13         weekly_hrs_t1_focal9 i.employed_focal9 earnings_t1_focal9 i.educ_focal9 i.children9 i.NUM_CHILDREN_9 AGE_YOUNG_CHILD_9 i.relationship_9 i.partnered9 TOTAL_INCOME_T1_FAMILY_9 i.race_fixed_focal)) housework_focal9
(pmm, knn(5) include (          housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal11 housework_focal12 housework_focal13 housework_focal14         weekly_hrs_t1_focal10 i.employed_focal10 earnings_t1_focal10 i.educ_focal10 i.children10 i.NUM_CHILDREN_10 AGE_YOUNG_CHILD_10 i.relationship_10 i.partnered10 TOTAL_INCOME_T1_FAMILY_10 i.race_fixed_focal)) housework_focal10
(pmm, knn(5) include (          housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal12 housework_focal13 housework_focal14 housework_focal15         weekly_hrs_t1_focal11 i.employed_focal11 earnings_t1_focal11 i.educ_focal11 i.children11 i.NUM_CHILDREN_11 AGE_YOUNG_CHILD_11 i.relationship_11 i.partnered11 TOTAL_INCOME_T1_FAMILY_11 i.race_fixed_focal)) housework_focal11
(pmm, knn(5) include (          housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal13 housework_focal14 housework_focal15 housework_focal16         weekly_hrs_t1_focal12 i.employed_focal12 earnings_t1_focal12 i.educ_focal12 i.children12 i.NUM_CHILDREN_12 AGE_YOUNG_CHILD_12 i.relationship_12 i.partnered12 TOTAL_INCOME_T1_FAMILY_12 i.race_fixed_focal)) housework_focal12
(pmm, knn(5) include (          housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal14 housework_focal15 housework_focal16          weekly_hrs_t1_focal13 i.employed_focal13 earnings_t1_focal13 i.educ_focal13 i.children13 i.NUM_CHILDREN_13 AGE_YOUNG_CHILD_13 i.relationship_13 i.partnered13 TOTAL_INCOME_T1_FAMILY_13 i.race_fixed_focal)) housework_focal13
(pmm, knn(5) include (          housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal15 housework_focal16           weekly_hrs_t1_focal14 i.employed_focal14 earnings_t1_focal14 i.educ_focal14 i.children14 i.NUM_CHILDREN_14 AGE_YOUNG_CHILD_14 i.relationship_14 i.partnered14 TOTAL_INCOME_T1_FAMILY_14 i.race_fixed_focal)) housework_focal14

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all, chaindots force add(10) rseed(12345) noimputed noisily augment

;
#delimit cr

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

(pmm, knn(5) include (          weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16)) weekly_hrs_t1_focal4
(pmm, knn(5) include (         weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16 )) weekly_hrs_t1_focal5
(pmm, knn(5) include (        weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16  )) weekly_hrs_t1_focal6
(pmm, knn(5) include (       weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16   )) weekly_hrs_t1_focal7
(pmm, knn(5) include (      weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16    )) weekly_hrs_t1_focal8
(pmm, knn(5) include (     weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16     )) weekly_hrs_t1_focal9
(pmm, knn(5) include (    weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16      )) weekly_hrs_t1_focal10
(pmm, knn(5) include (   weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16       )) weekly_hrs_t1_focal11
(pmm, knn(5) include (  weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal13 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16        )) weekly_hrs_t1_focal12
(pmm, knn(5) include ( weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal14 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16         )) weekly_hrs_t1_focal13
(pmm, knn(5) include (weekly_hrs_t1_focal0 weekly_hrs_t1_focal1 weekly_hrs_t1_focal2 weekly_hrs_t1_focal3 weekly_hrs_t1_focal4 weekly_hrs_t1_focal5 weekly_hrs_t1_focal6 weekly_hrs_t1_focal7 weekly_hrs_t1_focal8 weekly_hrs_t1_focal9 weekly_hrs_t1_focal10 weekly_hrs_t1_focal11 weekly_hrs_t1_focal12 weekly_hrs_t1_focal13 weekly_hrs_t1_focal15 weekly_hrs_t1_focal16          )) weekly_hrs_t1_focal14

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all, chaindots force add(10) rseed(12345) noimputed augment

;
#delimit cr

// do I need less predictors?

mi set wide
mi register imputed weekly_hrs_t1_focal*
mi register regular FIRST_BIRTH_YR birth_yr_all rel_start_all

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

= i.FIRST_BIRTH_YR i.birth_yr_all i.rel_start_all, chaindots force add(10) rseed(12345) augment noimputed

;
#delimit cr

********************************************************************************
* No observations
********************************************************************************

regress housework_focal4 housework_focal0 housework_focal1 housework_focal2 housework_focal3 housework_focal5 housework_focal6 housework_focal7 housework_focal8 housework_focal9 housework_focal10 housework_focal11 housework_focal12 housework_focal13 housework_focal14 housework_focal15 housework_focal16 weekly_hrs_t1_focal4 employed_focal4 earnings_t1_focal4 educ_focal4 children4 NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 relationship_4 partnered4 TOTAL_INCOME_T1_FAMILY_4 race_fixed_focal 

regress housework_focal4 housework_focal2 housework_focal3 housework_focal5 housework_focal6 weekly_hrs_t1_focal4 employed_focal4 earnings_t1_focal4 educ_focal4 children4 NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 relationship_4 partnered4 TOTAL_INCOME_T1_FAMILY_4 race_fixed_focal 

regress housework_focal9 housework_focal7 housework_focal8 housework_focal10 housework_focal11 weekly_hrs_t1_focal4 employed_focal4 earnings_t1_focal4 educ_focal4 children4 NUM_CHILDREN_4 AGE_YOUNG_CHILD_4 relationship_4 partnered4 TOTAL_INCOME_T1_FAMILY_4 race_fixed_focal 


