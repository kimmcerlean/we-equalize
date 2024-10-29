********************************************************************************
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: get_data
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files gets the data from the GSOEP and reorganizes it for analysis

net install soephelp,from("https://git.soep.de/mpetrenz/soephelp/-/raw/master/") replace

********************************************************************************
* First, let's just get a sense of data structure
********************************************************************************
set maxvar 10000

use "$GSOEP\pl.dta", clear

use "$GSOEP\hl.dta", clear