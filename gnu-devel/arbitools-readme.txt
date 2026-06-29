REQUIRES:
---------------------------
Some functions require the arbitools python package, written by myself
you can install it by: "pip3 install arbitools"

"pdflatex" by Han The Thanh is necessary in case you want to get pdfs.
           It is distributed under a GPL license.
           https://www.tug.org/applications/pdftex/

"bbpPairings.exe" by Bierema Boyz Programming is necessary to do the
                  pairings. Copy the file to an executable folder,
                  for example /usr/bin.
                  Find bbpPairings in
                  https://github.com/BieremaBoyzProgramming/bbpPairings
                  under GPL license.

USAGE:
---------------------------
arbitools.el is an interface for the python package "arbitools",
designed to manage chess tournament reports.  If you don't install the
python package you can still have the syntax colouring and some native
functions. In the future, all the functions will be translated to ELISP.

FEATURES:
----------------------------
- Syntax colouring for the official trf FIDE files.  This facilitates
manual edition of the files.

- Updating the players ratings. - with python

- Adding players to an existing file. - with python

- Getting standings from a tournament file. -with python

- Getting IT3 Tournament report form. - with python

- Deleting a round. - Native

- Insert result. - Native

- Insert player. - Native

- Insert bye. - Native

- Get the pairing list or results of a round - Native

- Get the list of the players - Native

- Delete player. Adjust all rank numbers - Native

- Adjust points for each player, according to results of rounds - Native

- Print standings - Native

- Calculate performance and ARPO (Average Rating Performance of Opponents -Native
  ARPO calculations are based on the ideas of Miguel Brozos, Marco A. Campo,
  Carlos Díaz and Julio González
  eio.usc.es/pub/julio/desempate/Performance_Recursiva.htm

- Export ELO in FEDA (Spanish Chess Federation) format - with python

- Do pairings - with bbpPairings.exe. In order for this to work,
                remember to add XXR and XXCfields in the file with the number
                of rounds of the tournament.

TODO:
---------------------------------

- Write the add players from file function in ELISP.
- Insert results from a results file created with a pairing program.
  Add the date in the "132" line and the results in the "001" lines.
- Add empty round. Ask for date create empty space in the players lines.
  Add the date in the "132" line.
- Add the rank number and the position automatically when adding players.
- Add team.
- Add player to team. Prompt for team and player number.
- Generate pgn file for a round or the whole tournament.
- Reorder the players list
- Error handling
- Make the interface more friendly
You will find more information in www.dggandara.eu/arbitools.htm