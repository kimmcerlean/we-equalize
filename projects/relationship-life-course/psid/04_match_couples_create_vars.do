
********************************************************************************
* Project: Relationship Life Course Analysis
* Owner: Kimberly McErlean
* Started: September 2024
* File: match_couples_create_vars
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the imputed data from step 3 at an individual level and
* matches the corresponding imputed partner data.
* It also creates couple-level variables.

use "$created_data/psid_individs_imputed_long_bysex", clear

capture drop var
mi update

mi passive: generate var = 
