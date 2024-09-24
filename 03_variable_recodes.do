********************************************************************************
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: variable_recodes
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes sample of couples and recodes to get ready for analysis

********************************************************************************
* import data and create nec relationship variables
********************************************************************************
use "$created_data\PSID_partners.dta", clear

// Need to figure our how to get relationship number and duration. can I use with what is here? or need to merge marital history?!