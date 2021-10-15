
This package brings soccer (football) fixtures, results, table in your Emacs.
Currently it works for

1. Premier League (England)
2. La Liga (Spain)
3. Ligue 1 (France)

Other leagues could be easily included and would be in future.

To get the time of kick off in your local time, you may want to set the
following value accordingly

(setq soccer-time-local-time-utc-offset "+0530") ;; this should be changed to your local one

Common Functions:

This package comes with handy interactive functions to get useful information in your minibuffer.
To invoke a function use "M-x Function" where Function could be any of the following functions

Functions	                Actions
soccer-fixtures-next	Fixture for the Next match
soccer-fixtures-next-5	Fixtures of the Next 5 matches
soccer-fixtures-full-in-org	Full fixtures saved in org file
soccer-fixtures-all-clubs    Fixtures for all clubs in a league
soccer-results-last	        Result of the last match
soccer-results-last-5	Results of the last 5 matches
soccer-results-full-in-org	Full list of results in org file
soccer-results-all-clubs     Results for all clubs in a league
soccer-table                 Full Ranking table
soccer-table-top-4           Ranking table with top 4 teams
soccer-table-bottom-4        Ranking table with bottom 4 teams
soccer-scorecard             Scorecard of a match
