clmemo provides some commands and minor modes for ChangeLog MEMO.

`ChangeLog MEMO' is a kind of concept that writing memo into _ONE_
file in ChangeLog format.  You can take a memo about address book,
bookmark, diary, idea, memo, news, schedule, time table, todo list,
citation from book, one-liner that you wrote but will forget, etc....

(1) Why one file?

* Easy for you to copy and move file, to edit memo, and to find
  something important.

* Obvious that text you want is in this file.  In other words, if not
  in this file, you didn't take a memo about it.  You will be free
  from searching all of the files for what you have taken or might
  have not.

(2) Why ChangeLog format?

* One of well known format.

* A plain text file.  Binary is usually difficult to edit and search.
  File size gets bigger.  And most of binary file needs special soft.
  You should check that your soft is distributed permanently.

* Easier to read than HTML and TeX.

* Entries are automatically sorted by chronological order.  The
  record when you wrote memo is stored.


Ref.

* ChangeLog

 - Change Logs in `GNU Emacs Reference Manual'

* ChangeLog MEMO

 - http://0xcc.net/unimag/1/ (Japanese)


[Acknowledgement]

Special thanks to rubikitch for clmemo-yank, clmemo-indent-region,
and bug fix of quitting title.  Great thanks goes to Tetsuya Irie,
Souhei Kawazu, Shun-ichi Goto, Hideaki Shirai, Keiichi Suzuki, Yuuji
Hirose, Katsuwo Mogi, and ELF ML members for all their help.


[How to install]

The latest clmemo.el is available at:

  https://github.com/ataka/clmemo


Put this in your .emacs file:

  (autoload 'clmemo "clmemo" "ChangeLog memo mode." t)

And bind it to your favourite key and set titles of MEMO.

Example:

  (global-set-key "\C-xM" 'clmemo)
  (setq clmemo-title-list
       '("Emacs" "Music" ("lotr" . "The Load of the Rings") etc...))


Finally, put this at the bottom of your ChangeLog MEMO file.

  ^L
  Local Variables:
  mode: change-log
  clmemo-mode: t
  End:

This code tells Emacs to set major mode change-log and toggle minor
mode clmemo-mode ON in your ChangeLog MEMO.  For more information,
see section "File Variables" in `GNU Emacs Reference Manual'.

`^L' is a page delimiter.  You can insert it by `C-q C-l'.

If you are Japanese, it is good idea to specify file coding system
like this;

  ^L
  Local Variables:
  mode: change-log
  clmemo-mode: t
  coding: utf-8
  End:


[Usage]

`M-x clmemo' directly open ChangeLog MEMO file in ChangeLog MEMO
mode.  Select your favourite title with completion.  User option
`clmemo-title-list' is used for completion.


[Related Softwares]

* clgrep -- ChangeLog GREP
  A grep command specialized for ChangeLog Memo.

  - clgrep (Ruby)
      http://0xcc.net/unimag/1/
  - blgrep (EmacsLisp)
      https://github.com/ataka/blgrep

* chalow -- CHAnge Log On the Web
  A ChangeLog Memo to HTML converter.

  - chalow (Perl)
      http://chalow.org/
