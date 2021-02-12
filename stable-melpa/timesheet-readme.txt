Debian-depends: emacs24 make gawk sed git tar rubber texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra evince

This library adds timetracking and invoice generation to org-mode
and relies heavily on
org clocking http://orgmode.org/org.html#Clocking-work-time
and TODO items http://orgmode.org/org.html#TODO-Items
and org spreadsheets http://orgmode.org/org.html#The-spreadsheet

This library attempts to conform to packaging conventions:
https://www.gnu.org/software/emacs/manual/html_node/elisp/Packaging.html
Bugs, enhancements welcome!

; Usage

Ensure TEXINPUTS is set to (in your ~/.bashrc)
export TEXINPUTS=.:$HOME/.emacs.d/elpa/auctex-11.87.4/latex:

Start by creating an example client...
  M-x timesheet-example
  You will be viewing the buffer yoyodyne.org that already has some example
  time entries... Create an invoice with
  M-x timesheet-invoice-this

Next steps...
- customize your name (in defs.tex) and logo (in logo.pdf).
- update some time entries.

Example key bindings
 see example.emacs.d/foo/bindings.el
