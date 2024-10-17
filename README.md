This code compiles the harmonized UKHLS and BHPS data files (available from: https://beta.ukdataservice.ac.uk/datacatalogue/studies/study?id=6614) to identify couples over time.
The current code tests two different ways of identifying and following couples:
  using ppidp (partner id provided in individual respondent data files); see file b_match_partners.do
  using egoalt files which provides dyadic relationship information that can then be merged with the details from the individual respondent files; see file f_compile_egoalt.do
The two codes provide about 99%+ alignment in terms of identifying and following partners. Most of the analysis relies on the matched partner data from just the individual respondent files.

To properly leverage the macros throughout the code, it is recommended to make your own copy of the setup file and replace all of the macros under the "Personal Computer" section with your own file paths. 
