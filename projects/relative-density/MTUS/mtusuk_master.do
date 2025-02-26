*******************************************************************
*                                                                 *
*  Reassessing The Gendered Division of Labor at the Couple Level *
*  Using Different Time-Use Data Sources                          *
*  A Proof of Concept with The United Kingdom                     *
*                                                                 *
*******************************************************************

/******************************************************************
CREATED [Melody Ge Gao] [Feb.19, 2025]
EDITED 
PURPOSE [Creating the master .do file]
NOTES & CHANGES:
- [Feb.19, 2025]: Set globals to define ref folders for data
- [Feb.20, 2025]: Cleaned and created individual- & couple-level time-use variables

*******************************************************************/

clear all
macro drop _all
set more off

/*Where and when are you working on this?*/
	global date: di %tdYND daily("$S_DATE", "DMY")	// YYMMDD. Update to avoid saving over previous work
	global comp "melody"	// change who is working

/*What do you want this program to do?*/
	global databuild = 1 //==1 if want to build analysis file from raw data
	global rda = 0  //==1 if want to analyze analysis file

/*Setting directories based on ${comp}*/
	if ("${comp}"=="melody") {
		global root "C:\Users\singh\OneDrive\Documents\postdoc\WE_C1_Relative Density Approach"
			}
	if ("${comp}"=="lea") {
		global root	"working directory"
		}	

// define globals
global data "$root\original data"
global moddata "$root\modified data"
global tables "$root\tables"
global results "$root\results"
global code "$root\code"
global graphs "$root\graphs"
global other "$root\other"
global rda "$root\rda" /* relative density approach */

cd "$code"

capture log using "$result\rda_$(date).log", append

/*Build the analytical dataset*/

	if (${databuild}==1) {
	
	// Starting data analysis
	
		// 1. Extract UK data with multiple respondents per household from MTUS_haf	& 
		// assign unique id for each individual-diary (each individual reported 7- or 2-day diaries) &
		// create time-use variables at individual level
		do "$code\mtusuk_individual.do"
		
		// 2. Create unique id for each individual's partner (if in couple & partner id is identifiable) &
		// copy time-use variables for partner 
		do "$code\mtusuk_partner.do"

		// 3. Create couple-level data by merging datasets &
		// assign time-use variables for wife's and husband's diary entries &
		// create time-use variables at couple level 
		do "$code\mtusuk_couple.do"

}

/*Relative Density Approach*/

	if (${rda}==1) {
	
	
		
}
