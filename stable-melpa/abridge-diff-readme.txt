
A simple Emacs package for abridging refined diff hunks (for
example in magit).  Why abridge a diff hunk?  Most diffs are line
based.  If you are working on files with very long lines, for
example LaTeX files, or text files with full paragraphs per line
(often using `visual-line-mode`), line-based diffs can be very
challenging to read, even with "hunk refining" enabled
(highlighting the words which changed).

Usage:

Once installed and enabled , abridge-diff will immediately start
abridging all refined (word-change-highlighted) diff hunks,
shortening them by replacing unnecessary surround context with
ellipses (...) . You can enable and disable showing the abridged
version using abridge-diff-toggle-hiding.  If magit is installed,
abridge-diff automatically configures itself to work with it,
adding a new `D a' diff setup command to toggle the abridging in
diff and status buffers.  Hunks are shown as abridged by default.

Settings:

You can customize settings with these variables; just M-x
 customize-group abridge-diff (with [default value]):

 abridge-diff-word-buffer [3]: Minimum number of words to preserve
   around refined regions.

 abridge-diff-first-words-preserve [4]: Keep at least this many
   words visible at the beginning of an abridged line with refined
   diffs.

 abridge-diff-invisible-min [5]: Minimum region length (in
   characters) between refined areas that can be made invisible.

 abridge-diff-no-change-line-words [12]: Number of words to keep at
   the beginning of a line without any refined diffs.
