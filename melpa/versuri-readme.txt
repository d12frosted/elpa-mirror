A package to fetch lyrics from well-known websites and store them in a local
sqlite database.

Features:
- makeitpersonal, genius, songlyrics, metrolyrics, musixmatch and azlyrics
are all supported
- add new websites or modify existing ones with `versuri-add-website'
- search the database with `completing-read' and either for all the entries in the
database, all the entries for a given artist or all the entries where the
lyrics field contains a given string.
- synchronous bulk request for lyrics for a given list of songs.
