This minor mode highlights the last visible line when scrolling
full windows.  It was inspired by the postscript viewer gv which
does a similar thing using a line across the screen.  It honours the
variable next-screen-context-lines.

Enable it for the current session with
    M-x highlight-context-line-mode
or permanently by putting
    (highlight-context-line-mode 1)
in your init file.

; ChangeLog

2.0   March 2017
      - Total rewrite
      - No more XEmacs support, I am afraid
1.5   January  2003
      - GNU Emacs compatibility due to request of
        Sami Salkosuo (http://members.fortunecity.com/salkosuo)
      - untabify file
1.3   December 2002
      CVS, "official" webpage

Written in 2002, the year I finally started writing some serious
elisp
