
This package brings soccer (football) fixtures, results and league
tables into Emacs, for every competition the source site covers.

The entry point is `soccer', a transient menu from which every view is
reachable.  Views open in a `soccer-mode' buffer which has its own
transient bound to "?", so a league table is one keystroke away from the
fixtures of the club under point.

Kick off times are absolute instants and are shown in your own time
zone automatically; set `soccer-timezone' to override that.

The individual commands are still available directly:

Function                     Action
soccer                       Transient menu with everything
soccer-fixtures-next         Fixture for the next match
soccer-fixtures-next-5       Fixtures of the next 5 matches
soccer-fixtures-full-in-org  Full fixtures saved in an org file
soccer-fixtures-all-clubs    Fixtures for all clubs in a league
soccer-results-last          Result of the last match
soccer-results-last-5        Results of the last 5 matches
soccer-results-full-in-org   Full list of results in an org file
soccer-results-all-clubs     Results for all clubs in a league
soccer-table                 Full ranking table
soccer-table-top-4           Ranking table with top 4 teams
soccer-table-bottom-4        Ranking table with bottom 4 teams
soccer-scorecard             Scorecard of a match
