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
* Import data and keep only one respondent per household (bc all data recorded for all)
********************************************************************************
bysort survey_yr FAMILY_INTERVIEW_NUM_ : egen per_id = rank(unique_id)
browse survey_yr FAMILY_INTERVIEW_NUM_  unique_id per_id

browse survey_yr FAMILY_INTERVIEW_NUM_ per_id unique_id if inlist(unique_id,12,13)
keep if per_id==1

// restrict to working age?
browse id survey_yr AGE_ AGE_REF_ AGE_SPOUSE_ RELATION_
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55)