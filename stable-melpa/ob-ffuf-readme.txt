Org-Babel support for web fuzzing with ffuf.

Write your HTTP request inside a source code block with fuzzing
input inserted where the fuzzing keyword (FUZZ by default) is placed
(and the ffuf backend permits it).  Input either comes from an
Orgmode table or a wordlist file (:wordlist-table or :wordlist-files
respectively, see README.org).

Further configuration may come either by specifying a user config
file via :config-file or by naming a source code block with
configuration in the exact format (see
<https://github.com/ffuf/ffuf/blob/master/ffufrc.example>) for
details.
