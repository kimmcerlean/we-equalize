********************************************************************************
*** PSID-SHELF DATA PROJECT                                           **********
*** Construction - 00 Create programs                                 **********
*** Last update: 2023.10.09, DD                                       **********
********************************************************************************

*-------------------------------------------------------------------------*
* File preamble
*-------------------------------------------------------------------------*

/*
* This file is used to construct the PSID's Social, Health, and Economic 
* Longitudinal File (PSID-SHELF). The "00 Create programs" file creates several 
* Stata programs that are used in PSID-SHELF's construction files to collect 
* variables and asssess year-to-year consistency of the original PSID variables.
*/


*-------------------------------------------------------------------------*
* Program attribution
*-------------------------------------------------------------------------*

/*
* These original programs were created solely by Davis Daumler. They are in
* beta version and have not been published or formalized as Stata ado files.

* Please acknowledge Davis Daumler if you use these programs for any projects 
* or activities beyond the construction of the PSID-SHELF data. 

* Please contact Davis Daumler (daumler@umich.edu): (1) if you identify any
* errors in the code; (2) if you wish to modify these programs for your own 
* usage; or (3) if you have any suggestions for improving the code.
*/


*-------------------------------------------------------------------------*
* Loop through subset of survey years
*-------------------------------------------------------------------------*

/*
* NOTE: The "rsubsetpsid" program works consistently on the first run of all 
* variable lists in the PSID-SHELF construction files. However, occasionally, 
* when an attempt is made to run the program, for a second time, on the same 
* variable list (i.e., directly after having run the program on the same
* variable list in the previous command), the program has produced an error.
* The problem is likely due to the input locals (e.g., `set_psid_yr_all')
* being passed to the program (i.e., `1'); or due to the rresulting locals
* that are being produced by the program (e.g., `r(n_year_avail)'). 

* This issue has not yet been debugged. The temporary solution is to run a 
* completely different command that does not use the "rsubsetpsid" program and 
* then to rerun the program with the same variable list as its input.
*/

capture program drop rsubsetpsid
program define rsubsetpsid, rclass /* eclass properties(mi) */
    * capture drop etemp_*
    
    di " "
    di `"[START OF PROGRAM]"'
    di " "

    * Run program only if input #1 exists:
    capture confirm existence `1'
    if !_rc {
        
        * Identify the complete list of PSID survey years:
        local year_all = "`1'"
        local n_year_all = wordcount("`year_all'")
    }
    else {
        
        * Error message:
        di `"[ATTENTION] The "esubsetpsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "esubsetpsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< esubsetpsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< esubsetpsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "esubsetpsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'    
        di " "
        di `"[ERROR RECORDED WHEN "esubsetpsid" PROGRAM TRIED TO CONFIRM EXISTENCE OF INPUT #1.]"'
    }
         
    * Run program only if input #2 exists:
    capture confirm existence `2'
    if !_rc {
        
        * Identify the list of PSID survey years in which the original
        * variables are unavailable:
        numlist "`2'"
        local year_miss = r(numlist)
        local n_year_miss = wordcount("`year_miss'")
    }
    else {
        
        * Error message:
        di `"[ATTENTION] The "esubsetpsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "esubsetpsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< esubsetpsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< esubsetpsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "esubsetpsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'            
        di " "
        di `"[ERROR RECORDED WHEN "esubsetpsid" PROGRAM TRIED TO CONFIRM EXISTENCE OF INPUT #2.]"'
    }
        
    * Run program only if input #3 exists:
    capture confirm existence `3'
    if !_rc {
        
        * Identify the list of original variables for the years in which 
        * they are available:
        local var_avail = subinstr("`3'", ".", " ", .)
        local n_var_avail = wordcount("`var_avail'")   
    }
    else {
        
        * Error message:
        di `"[ATTENTION] The "esubsetpsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "esubsetpsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< esubsetpsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< esubsetpsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "esubsetpsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'            
        di " "
        di `"[ERROR RECORDED WHEN "esubsetpsid" PROGRAM TRIED TO CONFIRM EXISTENCE OF INPUT #3.]"'        
    }
    
    * Run program only if the number of items in input #1 equals the sum of the 
    * number of items in inputs #2 and #3:
    if `n_year_all' == `= (`n_year_miss'+`n_var_avail')' di " " /* `"[INPUTS RECORDED BY "esubsetpsid" PROGRAM]"' */
    else {
        
        * Error message:
        di `"[ATTENTION] The "esubsetpsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "esubsetpsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< esubsetpsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< esubsetpsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "esubsetpsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'            
        di " "
        di `"[ERROR RECORDED WHEN "esubsetpsid" PROGRAM CONFIRMED INPUTS #1 EQUALS SUM OF #2 AND #3.]"'
    }
    
    * Now, remove the survey years in which the original variables are unavailable 
    * from the main macro for all survey years (defined at the start of the file): 
    local year_avail = "`year_all'"
    numlist "1/`n_year_all'"
    local i_avail = r(numlist)

    foreach x of numlist 1/`n_year_miss' {
        local year_unavail: word `x' of `year_miss'
        local year_avail = subinstr("`year_avail'", "`year_unavail'", "", .)
        
        foreach i of numlist 1/`n_year_all' {
            local yr: word `i' of `year_all'
            if (`year_unavail'==`yr') local i_avail = subinstr(" `i_avail' ", " `i' ", " ", .) /* (Note: The spaces within the 'subinstr' function (e.g., " `i' ") are essential.) */
        }
    }

    local n_i_avail = wordcount("`i_avail'")
    local n_year_avail = wordcount("`year_avail'")
    
    * Prepare to pass local macros when program has finished running:
    return local n_year_avail "`n_year_avail'"
    return local n_var_avail "`n_var_avail'"
    return local n_i_avail "`n_i_avail'"
    
    return local year_avail "`year_avail'"
    return local var_avail "`var_avail'"
    return local i_avail "`i_avail'"
    
    * List the resulting local macros:
    di `"[RSUBSETPSID PROGRAM]"' 
    di " "
    di `"PROGRAM INPUTS (QUANTITIES):"'
    di `"    N total years = `n_year_all'."'
    di `"    N missing years = `n_year_miss'."'
    di `"    N available variables = `n_var_avail'."'
    di " "
    di " "
    di `"RESULTING LOCAL MACROS (QUANTITIES):"'
    di " "
    di `"[LOCAL MACRO: r(n_year_avail)]"' 
    di `"[LOCAL MACRO: r(n_var_avail)]"' 
    * di `"[LOCAL MACRO: r(n_i_avail)]"' 
    di " "
    di `"    N available years = `n_year_avail'."'
    di " "
    di `"    N available variables = `n_var_avail'."'
    /*
    di " "
    di `"    N obs to loop through (from original list of total years) = `n_i_avail'."'
    */ 
    di " "
    di " "
    di `"RESULTING LOCAL MACROS (LISTS):"'
    di " "
    di `"[LOCAL MACRO: r(year_avail)]"' 
    di `"[LOCAL MACRO: r(var_avail)]"' 
    * di `"[LOCAL MACRO: r(i_avail)]"' 
    di " "
    di `"    Available years:  << `year_avail' >> ."'
    di " "
    di `"    Available variables:  << `var_avail' >> ."'
    /*
    di " "
    di `"    Obs to loop through (from original list of total years): << `i_avail' >> ."'
    */
    di " "
    di " "
    di `"[END OF PROGRAM]"'
    
    * capture drop etemp_*
end


*-------------------------------------------------------------------------*
* Describe and identify missing values and possible top-/bottom-codes
*-------------------------------------------------------------------------*

capture program drop rvalcodespsid
program define rvalcodespsid, rclass /* eclass properties(mi) */
    * capture drop etemp_*
    
    di " "
    di `"[START OF PROGRAM]"'
    di " "

    * Run program only if input #1 exists:
    capture confirm existence `1'
    if !_rc {
        
        * Identify the complete list of PSID survey years:
        local year_all = "`1'"
        local n_year_all = wordcount("`year_all'")
    }
    else {
        
        * Error message:
        di `"[ATTENTION] The "rvalcodespsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "rvalcodespsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< rvalcodespsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< rvalcodespsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "rvalcodespsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'    
        di " "
        di `"[ERROR RECORDED WHEN "rvalcodespsid" PROGRAM TRIED TO CONFIRM EXISTENCE OF INPUT #1.]"'
    }
         
    * Run program only if input #2 exists:
    capture confirm existence `2'
    if !_rc {
        
        if ("`2'" == "0") {
            di `"[NOTE: INPUT #2 IS EQUAL TO ZERO; THEREFORE, PROGRAM ASSUMES NO MISSING VARIABLES IN EACH SURVEY YEAR.]"'
            local n_year_miss = 0
        }
        else {
        
            * Identify the list of PSID survey years in which the original
            * variables are unavailable:
            numlist "`2'"
            local year_miss = r(numlist)
            local n_year_miss = wordcount("`year_miss'")
        }
    }
    else {
        
        * Error message:
        di `"[ATTENTION] The "rvalcodespsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "rvalcodespsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< rvalcodespsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< rvalcodespsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "rvalcodespsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'            
        di " "
        di `"[ERROR RECORDED WHEN "rvalcodespsid" PROGRAM TRIED TO CONFIRM EXISTENCE OF INPUT #2.]"'
    }
        
    * Run program only if input #3 exists:
    capture confirm existence `3'
    if !_rc {
        
        * Identify the list of original variables for the years in which 
        * they are available:
        local var_avail = subinstr("`3'", ".", " ", .)
        local n_var_avail = wordcount("`var_avail'")   
    }
    else {
        
        * Error message:
        di `"[ATTENTION] The "rvalcodespsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "rvalcodespsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< rvalcodespsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< rvalcodespsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "rvalcodespsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'            
        di " "
        di `"[ERROR RECORDED WHEN "rvalcodespsid" PROGRAM TRIED TO CONFIRM EXISTENCE OF INPUT #3.]"'        
    }
    
    * Run program only if the number of items in input #1 equals the sum of the 
    * number of items in inputs #2 and #3:
    if `n_year_all' == `= (`n_year_miss'+`n_var_avail')' di " " /* `"[INPUTS RECORDED BY "rvalcodespsid" PROGRAM]"' */
    else {
        
        * Error message:
        di `"[ATTENTION] The "rvalcodespsid" program requires three inputs."'
        di "*"
        di `"REQUIRED INPUTS:"'
        di `" (1) A chronological list of all survey years;"'
        di `" (2) A chronological list of the specific survey years in which a"' 
        di `"     variable is missing or not available; and"' 
        di `" (3) A chronological list of the original variables in each of the"'
        di `"     survey years that the variable is available."' 
        di " "
        di `"NOTE: Failure to provide these three required inputs will result in"' 
        di `"the program "rvalcodespsid" not running properly."' 
        di " "
        di `"POSSIBLE ISSUES MIGHT INCLUDE:"'
        di `" (a) Not having the required number of inputs for the program to run;"'
        di `" (b) Not enclosing each input within quotation marks, so that each"'
        di `"     list of items is treated as multiple inputs;"'
        di `" (c) Providing inputs that are not commensurate quantities, such that"'
        di `"     the number of total survey years listed [input 1] does not the"'
        di `"     sum of the number of missing survey years listed [input 2] and"'
        di `"     the the number of available variables listed [input 3]."'
        di " "
        di `"OVERVIEW OF THE PROGRAM'S COMMAND STRUCTURE:"'
        di `"<< rvalcodespsid   "[ALL_YEARS]"   "[UNAVAIL_YEARS]"   "[AVAIL_VARS]" >> "'
        di " "
        di `"EXAMPLE OF A COMMAND LINE TO RUN THE PROGRAM:"'
        di `"E.g.: An example of a command line to run the program:"'
        di `"<< rvalcodespsid   "1968/1997 1999(2)2019"   "1968 1982/1984"   ".           V1015         V1766       V2345       V2979       V3310       V3730       V4231       V5113       V5681       V6220       V6814         V7456       V8110       .           .           .           V12443      V13682      V14732      V16207      V17584        V18936      V20236      V21542      V23356      ER4159R     ER6999R     ER9250R     ER12223R                ER16447                   ER20393                 ER24170                 ER28069                 ER41059                 ER47003                   ER52427                 ER58245                 ER65481                 ER71560                 ER77621" >> "'
        di " "
        di `"NOTE: This example provides a complete list of 41 survey years, ranging"'
        di `"from 1968 to 1997, annually, and 1999 to 2019, biennially [input 1];"'
        di `"a list of four survey years that a variable is unavailable (1968, 1982,"'
        di `"1983, 1984) [input 2]; and a list of 37 available variables (excluding"'
        di `"periods, which are the only character that are automatically removed"' 
        di `"from lists by the "rvalcodespsid" program) [input 3]. Therefore, total"'
        di `"years (41) = missing years (4) + available variables (37)."'            
        di " "
        di `"[ERROR RECORDED WHEN "rvalcodespsid" PROGRAM CONFIRMED INPUTS #1 EQUALS SUM OF #2 AND #3.]"'
    }
    
    * Now, remove the survey years in which the original variables are unavailable 
    * from the main macro for all survey years (defined at the start of the file): 
    local year_avail = "`year_all'"
    numlist "1/`n_year_all'"
    local i_avail = r(numlist)

    if ("`2'"=="0") {
        di " "
    }
    else {        
        foreach x of numlist 1/`n_year_miss' {
            local year_unavail: word `x' of `year_miss'
            local year_avail = subinstr("`year_avail'", "`year_unavail'", "", .)
            
            foreach i of numlist 1/`n_year_all' {
                local yr: word `i' of `year_all'
                if (`year_unavail'==`yr') local i_avail = subinstr(" `i_avail' ", " `i' ", " ", .) /* (Note: The spaces within the 'subinstr' function (e.g., " `i' ") are essential.) */
            }
        }
    }

    local n_i_avail = wordcount("`i_avail'")
    local n_year_avail = wordcount("`year_avail'")
    
    * Loop through the original variables that are available in each survey year:
    capture quietly drop _val*    
    foreach i of numlist 1/`n_year_avail' {
        local y:   word `i' of `year_avail'
        local var: word `i' of `var_avail'
        
        * Inspect the values of total family income:
        quietly count if inrange(`var', -999999999999, 999999999999)
        local n_var`y'_n=`=r(N)'
        gen _valn_`var'=(inrange(`var', -999999999999, 999999999999))
        gen _valn_`y'=(inrange(`var', -999999999999, 999999999999))
        local var_n "`var_n' _valn_`var'"        
        local y_n "`y_n' _valn_`y'"
        quietly count if inlist(`var', 0)
        local n_var`y'_0=`=r(N)'
        gen _val0_`var'=(inlist(`var', 0))
        gen _val0_`y'=(inlist(`var', 0))
        local var_0 "`var_0' _val0_`var'"        
        local y_0 "`y_0' _val0_`y'"        
        quietly count if inlist(`var', 1)
        local n_var`y'_1=`=r(N)'
        gen _val1_`var'=(inlist(`var', 1))
        gen _val1_`y'=(inlist(`var', 1))
        local var_1 "`var_1'_val1_`var'"        
        local y_1 "`y_1' _val1_`y'"        
        quietly count if inlist(`var', /* 9999, 9998, 9997, */ 99999, 99998, 99997, 999999, 999998, 999997, 9999999, 9999998, 9999997, 99999999, 99999998, 99999997, 999999999, 999999998, 999999997, 9999999999, 9999999998, 9999999997, 99999999999, 99999999998, 99999999997, 999999999999, 999999999998, 999999999997)
        local n_var`y'_tc=`=r(N)'
        gen _valtc_`var'=(inlist(`var', /* 9999, 9998, 9997, */ 99999, 99998, 99997, 999999, 999998, 999997, 9999999, 9999998, 9999997, 99999999, 99999998, 99999997, 999999999, 999999998, 999999997, 9999999999, 9999999998, 9999999997, 99999999999, 99999999998, 99999999997, 999999999999, 999999999998, 999999999997))
        gen _valtc_`y'=(inlist(`var', /* 9999, 9998, 9997, */ 99998, 99997, 999999, 999998, 999997, 9999999, 9999998, 9999997, 99999999, 99999998, 99999997, 999999999, 999999998, 999999997, 9999999999, 9999999998, 9999999997, 99999999999, 99999999998, 99999999997, 999999999999, 999999999998, 999999999997))
        local var_tc "`var_tc' _valtc_`var'"        
        local y_tc "`y_tc' _valtc_`y'"        
        quietly count if inlist(`var', /* -9999, -9998, -9997, */ -99999, -99998, -99997, -999999, -999998, -999997, -9999999, -9999998, -9999997, -99999999, -99999998, -99999997, -999999999, -999999998, -999999997, -9999999999, -9999999998, -9999999997, -99999999999, -99999999998, -99999999997, -999999999999, -999999999998, -999999999997)
        local n_var`y'_bc=`=r(N)'
        gen _valbc_`var'=(inlist(`var', /* -9999, -9998, -9997, */ -99999, -99998, -99997, -999999, -999998, -999997, -9999999, -9999998, -9999997, -99999999, -99999998, -99999997, -999999999, -999999998, -999999997, -9999999999, -9999999998, -9999999997, -99999999999, -99999999998, -99999999997, -999999999999, -999999999998, -999999999997))
        gen _valbc_`y'=(inlist(`var', /* -9999, -9998, -9997, */ -99999, -99998, -99997, -999999, -999998, -999997, -9999999, -9999998, -9999997, -99999999, -99999998, -99999997, -999999999, -999999998, -999999997, -9999999999, -9999999998, -9999999997, -99999999999, -99999999998, -99999999997, -999999999999, -999999999998, -999999999997))
        local var_bc "`var_bc' _valbc_`var'"        
        local y_bc "`y_bc' _valbc_`y'"        
        quietly count if inrange(`var', -999999999999, -0.000000000001)
        local n_var`y'_neg=`=r(N)'
        gen _valneg_`var'=(inrange(`var', -999999999999, -0.000000000001))
        gen _valneg_`y'=(inrange(`var', -999999999999, -0.000000000001))
        local var_neg "`var_neg' _valneg_`var'"        
        local y_neg "`y_neg' _valneg_`y'"        
        quietly summarize `var'
        local val_var`y'_min=`=r(min)'
        local val_var`y'_max=`=r(max)'
        gen _valmin_`var'=(`var'==`val_var`y'_min')
        gen _valmax_`var'=(`var'==`val_var`y'_max')
        gen _valmin_`y'=(`var'==`val_var`y'_min')
        gen _valmax_`y'=(`var'==`val_var`y'_max')
        local var_min "`var_min' _valmin_`var'"        
        local var_max "`var_max' _valmax_`var'"        
        local y_min "`y_min' _valmin_`y'"        
        local y_max "`y_max' _valmax_`y'"        
        quietly count if (`var'==`val_var`y'_min')
        local n_var`y'_min=`=r(N)'
        quietly count if (`var'==`val_var`y'_max')
        local n_var`y'_max=`=r(N)'
    }
    
    * Generate 11 different macros containing the text to describe the number 
    * of missing value codes and top/bottom codes in each survey year:
    foreach j of numlist 1/11 {
        local macro`j'_nchar_tot = 0
    }
    
    * Identify the year-specific length of macro (in characters) and calculate
    * the cross-year total length of the macro:
    foreach i of numlist 1/`n_year_avail' {
        local y:   word `i' of `year_avail'
        local var: word `i' of `var_avail'
        
        local macro1_`y' = "[`y': `var']"
        local macro1_nchar_`y' = strlen("`macro1_`y''")
        local macro1_nchar_tot = max(`macro1_nchar_`y'', `macro1_nchar_tot')

        local macro2_`y' = "`n_var`y'_n'."
        local macro2_nchar_`y' = strlen("`macro2_`y''")
        local macro2_nchar_tot = max(`macro2_nchar_`y'', `macro2_nchar_tot')
        
        local macro3_`y' = "`n_var`y'_1'."
        local macro3_nchar_`y' = strlen("`macro3_`y''")
        local macro3_nchar_tot = max(`macro3_nchar_`y'', `macro3_nchar_tot')
        
        local macro4_`y' = "`n_var`y'_0'."
        local macro4_nchar_`y' = strlen("`macro4_`y''")
        local macro4_nchar_tot = max(`macro4_nchar_`y'', `macro4_nchar_tot')
        
        local macro5_`y' = "`n_var`y'_neg'."
        local macro5_nchar_`y' = strlen("`macro5_`y''")
        local macro5_nchar_tot = max(`macro5_nchar_`y'', `macro5_nchar_tot')

        local macro6_`y' = "`n_var`y'_tc'."
        local macro6_nchar_`y' = strlen("`macro6_`y''")
        local macro6_nchar_tot = max(`macro6_nchar_`y'', `macro6_nchar_tot')
        
        local macro7_`y' = "`n_var`y'_max'"
        local macro7_nchar_`y' = strlen("`macro7_`y''")
        local macro7_nchar_tot = max(`macro7_nchar_`y'', `macro7_nchar_tot')

        local macro8_`y' = "(`val_var`y'_max')."
        local macro8_nchar_`y' = strlen("`macro8_`y''")
        local macro8_nchar_tot = max(`macro8_nchar_`y'', `macro8_nchar_tot')

        local macro9_`y' = "`n_var`y'_bc'."
        local macro9_nchar_`y' = strlen("`macro9_`y''")
        local macro9_nchar_tot = max(`macro9_nchar_`y'', `macro9_nchar_tot')
                
        local macro10_`y' = "`n_var`y'_min'"
        local macro10_nchar_`y' = strlen("`macro10_`y''")
        local macro10_nchar_tot = max(`macro10_nchar_`y'', `macro10_nchar_tot')
                
        local macro11_`y' = "(`val_var`y'_min')."
        local macro11_nchar_`y' = strlen("`macro11_`y''")
        local macro11_nchar_tot = max(`macro11_nchar_`y'', `macro11_nchar_tot')        
    }
    
    * Add spaces to each year-specific macro to bring it to the maximum length, 
    * so that the columns of the output is evenly spaced:
    foreach j of numlist 1/11 {
        foreach i of numlist 1/`n_year_avail' {
            local y:   word `i' of `year_avail'
            local var: word `i' of `var_avail'
        
            local macro`j'_nchar_`y'_add = (`macro`j'_nchar_tot' - `macro`j'_nchar_`y'')
            
            if (`macro`j'_nchar_`y'_add'==0) {
                local macro`j'_`y' = "`macro`j'_`y''"
            }
            else {
                foreach x of numlist 1/`macro`j'_nchar_`y'_add' {
                    local macro`j'_`y' = "`macro`j'_`y'' "
                }
            }
        }
    }
    
    * List the resulting local macros:
    di `"[RVALCODESPSID PROGRAM]"' 
    di " "
    di `"PROGRAM INPUTS (QUANTITIES):"'
    di `"    N total years = `n_year_all'."'
    di `"    N missing years = `n_year_miss'."'
    di `"    N available variables = `n_var_avail'."'
    di " "
    di " "
    di `"RESULTING LOCAL MACROS (IDENTIFIERS) [SUFFIX = YEARS]:"'
    di " "
    di `"    Vars identifying nonmissing: `y_n'."' 
    di " "
    di `"    Vars identifying ones: `y_1'."' 
    di " "
    di `"    Vars identifying zeros: `y_0'."' 
    di " "
    di `"    Vars identifying neg: `y_neg'."' 
    di " "
    di `"    Vars identifying 99tc: `y_tc'."' 
    di " "
    di `"    Vars identifying max: `y_max'."' 
    di " "
    di `"    Vars identifying -99bc: `y_bc'."' 
    di " "
    di `"    Vars identifying min: `y_min'."' 
    di " "
    di " "
    di `"RESULTING LOCAL MACROS (IDENTIFIERS) [SUFFIX = VARNAME]:"'
    di " "
    di `"    Vars identifying nonmissing: `var_n'."' 
    di " "
    di `"    Vars identifying ones: `var_1'."' 
    di " "
    di `"    Vars identifying zeros: `var_0'."' 
    di " "
    di `"    Vars identifying neg: `var_neg'."' 
    di " "
    di `"    Vars identifying 99tc: `var_tc'."' 
    di " "
    di `"    Vars identifying max: `var_max'."' 
    di " "
    di `"    Vars identifying -99bc: `var_bc'."' 
    di " "
    di `"    Vars identifying min: `var_min'."' 
    di " "
    di " "
    di `"KEY DEFINITIONS:"'
    di `"[N]       Number, within the range of (-999999999999, 999999999999)."'    
    di `"[Ones]    Exact value, equal to 1.0000."'    
    di `"[Zeros]   Exact value, equal to 0.0000."'    
    di `"[Neg]     Negative value, within the range of (-999999999999, -0.000000000001)."'    
    di `"[99tc]    Possible top codes, equal to one of the following values:"'
    * di `"             * 9999, 9998, 9997;"'
    di `"             * 99999, 99998, 99997;"'
    di `"             * 999999, 999998, 999997;"'
    di `"             * 9999999, 9999998, 9999997;"'
    di `"             * 99999999, 99999998, 99999997;"'
    di `"             * 999999999, 999999998, 999999997;"'
    di `"             * 9999999999, 9999999998, 9999999997;"'
    di `"             * 99999999999, 99999999998, 99999999997;"'
    di `"             * 999999999999, 999999999998, 999999999997."'
    di `"[–99bc]   Possible bottom codes, equal to the negative of any value contained in the [99tc] list."'
    di `"[Min]     Exact value, equal to the lowest observed value of the year-specific variable."'    
    di `"[Max]     Exact value, equal to the highest observed value of the year-specific variable."'    
    di " "
    di " "
    di `"IDENTIFY POTENTIAL MISSING VALUE CODES AND TOP/BOTTOM CODES:"'
    di " "
    di `"[Note: Looping through the original variables that are available in each survey year (N available years = `n_var_avail')"'
    di " "
    di `"[#1: NUMBER OF OBSERVATIONS WITH EXACT VALUES OF ONE, ZERO, OR A NEGATIVE VALUE.]"'
    di " "
    foreach i of numlist 1/`n_year_avail' {
        local y:   word `i' of `year_avail'
        local var: word `i' of `var_avail'
        
        di "    `macro1_`y''     N: `macro2_`y''     Ones: `macro3_`y''     Zeros: `macro4_`y''     Neg: `macro5_`y''"
    }
    di " "
    di `"[#2: OBSERVATIONS WITH POSSIBLE TOP CODES, BOTTOM CODES, OR EQUAL TO THE MIN OR MAX VALUES.]"'
    di " "
    foreach i of numlist 1/`n_year_avail' {
        local y:   word `i' of `year_avail'
        local var: word `i' of `var_avail'
        
        di "    `macro1_`y''     99tc: `macro6_`y''     Max: `macro7_`y'' `macro8_`y''     -99bc: `macro9_`y''     Min: `macro10_`y'' `macro11_`y''"
    }
    di " "
    di " "
    di `"[END OF PROGRAM]"'
    
    * capture drop etemp_*
end
