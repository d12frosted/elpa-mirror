;;; crossword.el --- Download and play crossword puzzles -*- lexical-binding: t; coding: utf-8;  -*-

;; Copyright (C) 2018-2021 Boruch Baum <boruch-baum@gmx.com>

;; Author/Maintainer:  Boruch Baum <boruch-baum@gmx.com>
;; Homepage: https://github.com/Boruch-Baum/emacs-crossword
;; License: GPL3+
;; Keywords: games
;; Package-Version: 20210614.633
;; Package-Commit: a8594b6e13f5e276aa9bc810ac74a8032bb1f678
;; Package: crossword
;; Version: 1.0
;; Package-Requires: ((emacs "26.1"))

;; This file is NOT part of GNU Emacs.

;; This is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; * Download and play crossword puzzles in Emacs.
;;
;; * Includes a browser to view puzzles' detailed metadata, including
;;   progress of partially played puzzles.

;; * Optionally, play against the clock, with the built-in timer.



;;
;;; Dependencies: (all already part of core Emacs)
;;
;; seq            - for `seq--into-vector'
;; tabulated-list - for `tabulated-list-mode', etal.
;; hl-line        - for `hl-line-mode'
;; calendar       - for `calendar-read' etal.

;;
;;; Dependencies: (external to Emacs)
;;
;; The package uses either `wget' or `curl' to download packages from
;; the network. These are both long-established standard programs and
;; at least one is probably already installed on your computer.



;;
;;; Installation:
;;
;;  1) Evaluate or load or install this file.
;;
;;  2) Optionally, define a global keybinding or defalias for functions
;;     `crossword'
;;
;;        (global-set-key (kbd "foo") 'crossword))
;;        (defalias 'crossword 'foo)
;;
;;     Depending on your temperament and style, you might also want to
;;     set direct keybindings and aliases for functions
;;     `crossword-download', `crossword-display', and `crossword-load';
;;     however, they're just one menu-selection away from function
;;     `crossword'.



;;
;;; Configuration:
;;
;;  M-x `customize-group' <RET> crossword <RET>
;;
;;  Initially, you may want to change the default download path
;;  `crossword-save-path', but otherwise, try using the mode first
;;  without any customization.

;;  There exist four customizations for how POINT advances after you
;;  fill-in a square or navigate: `crossword-arrow-changes-direction'
;;  `crossword-wrap-on-entry-or-nav', `crossword-tab-to-next-unfilled'
;;  `crossword-auto-nav-only-within-clue'.

;;  If you don't usually play more than one crossword in a sitting,
;;  you may want to set `crossword-quit-to-browser' to NIL to save
;;  yourself a keystroke on exit.

;;  You can also customize the download sources to be used for network
;;  downloading (do share, please).
;;
;;  There are also several 'faces' defined to allow custom colorization
;;  and fontification. Knock yourself out.



;;
;;; Operation:
;;
;;  M-x `crossword' presents a menu with three options. Unless you
;;  already have local puzzle files, you'll want to connect to the
;;  network, and decide what puzzle to download and for what date.
;;  Select a download source from the download menu, noting that the
;;  label for each download source includes the days of the week on
;;  which puzzles are published. Then enter the date of the puzzle you
;;  want. Different download sources have different archive retention
;;  policies, so you can try downloading 'old' puzzles. The puzzle files
;;  are tiny, so the download should be instantaneous for most, but
;;  YMMV.
;;
;;  M-x `crossword' a second time. If you choose to directly load a
;;  puzzle, you will be prompted to navigate to it. If you choose the
;;  browser, you're in for a small treat, as you'll be presented with a
;;  handy-dandy nifty screenshot-suitable metadata browser of all your
;;  known puzzle files, courtesy of Emacs' built-in
;;  `tabulated-list-mode'. Entries can be sorted by any column by
;;  navigating POINT there and pressing 'S' once or twice. Press <RET>
;;  to play the puzzle at point. You can also delete files here ('d').
;;
;;    IMPORTANT: The mode supports a single save file for each puzzle.
;;    These save files do not over-write the original file, so the
;;    partially- or completely- played puzzles appear in the browser
;;    alongside the untouched original. Save files can be identified in
;;    the browser and on youor compuer disk by their file-name extension
;;    `puz-emacs'. You can at any time start a puzzle over from scratch
;;    by selecting the untouched copy. BUT... If you don't want to lose
;;    your partially played session, you will need to back-up the save
;;    file.
;;
;; Play occurs in a single window of single dedicated frame, although
;; that frame is divided into three dedicated windows, each displaying
;; its own dedicated buffer. You should never need to leave the playable
;; 'Crossword grid' buffer.
;;
;; At any time, you can save your current state-of-play or restore your
;; saved stated. Quitting a game will prompt you to save or discard it:
;;
;;                 M-q           crossword-quit
;;                 C-x C-s       crossword-backup
;;                 C-c C-x C-f   crossword-restore
;;
;; If, while playing, you delete the crossword frame or one of its
;; windows, you can use command M-x `crossword-recover-game-in-progress'.
;; If you kill a clue buffer, you'll need to save, quit, and restore
;; the saved game.
;;
;; General navigation within the grid buffer should be intuitive, using
;; all the usual keys. Additionally, filling in a square will advance
;; POINT to the next sensible one. Grids begin with an 'across'
;; navigation for solving across clues, but that's easily changed:
;;
;;                 M-a           crossword-nav-dir-across
;;                 M-d           crossword-nav-dir-down
;;                 M-<SPC>       crossword-nav-dir-toggle
;;
;; Notice that when you change direction, the font of the current clue
;; changes accordingly, within the grid, and for the clues' text below
;; the grid and in their dedicated buffers.
;;
;; Additionally, you can always navigate directly to any specific clue
;; by its number, using the '/' key:
;;
;;                 /             crossword-goto-clue
;;
;; You can enter pretty much any character I can think of into any
;; square, but any non-alphabetic characters of the puzzle's language
;; will be ignored (ie. you can make signs for yourself). All lower case
;; alphabetic characters are immediately converted to uppercase.
;;
;; At some point, you'll want to check your work. You have three options
;; for this:
;;
;;                 M-c l         crossword-check-letter
;;                 M-c w         crossword-check-word
;;                 M-c p         crossword-check-puzzle
;;
;; All correctly and incorrectly solved squares will be fontified
;; accordingly. Correctly solved square can no longer be edited. Errors
;; for each square are logged and you are reminded of them at the bottom
;; of the grid buffer when you visit the square in the future.
;;
;; You can also ask the program to give you a break and solve parts of
;; the puzzle for you:
;;
;;                 M-s l         crossword-solve-letter
;;                 M-s w         crossword-solve-word
;;                 M-s p         crossword-solve-puzzle
;;
;; You can browse the list of clues in the other two buffers by setting
;; your current navigation direction (ie. across or down) and using an
;; intuitive keybinding with a 'Meta' prefix. I don't expect that you'll
;; need to use these features much because as you navigate within the
;; grid, the program auto-magically re-centers the other buffers around
;; the whatever are the current clues. Anyway, here are the command
;; names ad default key-bindings:
;;
;;                 M-up>         crossword-clue-scroll-up
;;                 M-down>       crossword-clue-scroll-down
;;                 M-<next>      crossword-clue-scroll-page-up
;;                 M-<prior>     crossword-clue-scroll-page-down
;;                 M-<home>      crossword-clue-scroll-page-home
;;                 M-<end>       crossword-clue-scroll-page-end
;;
;; If you want to play against the clock, toggle the timer on (and off):
;;
;;                 M-p           crossword-pause-unpause-time
;;                 M-t           crossword-pause-unpause-timer
;;
;; That about does it, doesn't it? Here are some of the 'intuitive'
;; navigation keybindings given special attentionL
;;
;;                <left>         crossword-prior-char
;;                <right>        crossword-next-char
;;                <RET>          crossword-next-char
;;                <delete>       crossword-del-char
;;                SPC            crossword-del-char
;;                <baskspace>    crossword-bsp-char
;;                C-a            crossword-begin-field
;;                C-e            crossword-end-field
;;                <TAB>          crossword-next-field
;;                <backtab>      crossword-prior-field



;;
;;; Feedback:
;;
;; It's best to contact me by opening an 'issue' on the program's github
;; repository (see above) or, distant second-best, by direct e-mail.
;;
;; Code contributions are welcome and github starring is appreciated.
;;
;; Please share your knowledge of other download resources, free
;; software resources, and puzzle formats.



;;
;;; Compatibility:
;;
;; The software has been tested on emacs version 26.1 and and emacs 28
;; snapshot, both in debian on a linux terminal (non-GUI).

;; Several puzzle file formats exist. This software, as currently
;; written, parses the `.puz' file format created sometime in the 1990's
;; by Literate Software LLC[1] and used initially by them for their
;; `across' line of software for creating, solving and sharing crossword
;; puzzles. This format has supposedly since become the de facto
;; standard for the genre[2].
;;
;; [1] http://www.litsoft.com/
;; [2] http://fileformats.archiveteam.org/wiki/PUZ_%28crossword_puzzles%29
;; [3] https://code.google.com/archive/p/puz/wikis/FileFormat.wiki
;;     The contents at this URL were mangled, so I reformatted it to
;;     properly display its tables and code blocks in an `org-mode`
;;     file. See `docs/crossword_puz_format.org`.



;;
;;; Download resources:

;; This project wouldn't be useful without people sharing puzzles for
;; free network download. A big thanks are due to `Martin_Herbach' for
;; being the provider of all the default download resources
;; pre-configured in this sotware.
;;
;; Please let me know of other resources that can be added.
;;
;; Check these URLs for links to other puzzles. In many cases, you
;; need to look for a link labeled something like 'across-lite format'
;; or 'puz format':
;;
;; * https://crosswordlinks.substack.com/?no_cover=true
;;   * aggregator, pointing to pages which have download links
;;   * RSS: https://crosswordlinks.substack.com/feed
;;
;; * https://crosswordfiend.com/download/
;;   * The download links appear only with javascript enabled



;;
;;; Comparable software:

;; I'm not aware of any other similar software for the linux terminal.
;; The following may be of interest to readers. Please let me know of
;; other projects.
;;
;; * xword - Linux GUI package
;;     https://sourceforge.net/projects/wx-xword/
;;
;; * shortyz - Android GUI package
;;     https://f-droid.org/en/packages/com.totsp.crossword.shortyz/



;;
;;; Code:



;;
;;; Dependencies:
(require 'seq)            ;; for seq--into-vector
(require 'tabulated-list) ;; for tabulated list mode
(require 'hl-line)        ;; for hl-line-mode
(require 'calendar)       ;; for calendar-read and related functions



;;
;;; Customization variables

(defgroup crossword nil
  "Settings for the Emacs crossword puzzle game/downloader."
  :group 'games
  :prefix "crossword-")

(defcustom crossword-save-path "~/Crosswords/"
  "Directory where crossword data is to be stored."
  :type  'directory)

(defcustom crossword-quit-to-browser t
  "Whether quitting a puzzle opens a puzzle browser.
Set this NIL to totally exit 'crossword' immediately."
  :type  'boolean)

(defcustom crossword-auto-check-completed t
  "Whether to automatically check a puzzle when completely filled.
Set this NIL to be able to self-check first and avoid registering
any errors."
  :type  'boolean)

(defcustom crossword-empty-position-char "▦"
  "Character denoting non-insertion squares.
The single character to use to denote a positon on the board
that is not for data entry, ie. not part of the solutions for
clues. If NIL or empty, a period (full-stop) is used, since
that is what is used in the .puz standard format. Ideas tried:

     ⊞ 00229E SQUARED PLUS
     🞖 01F796 SQUARE TARGET
     ⬚ 002B1A DOTTED SQUARE
     ⁜ 00205C DOTTED CROSS
     🗵01F5F5 BALLOT BOX WITH SCRIPT X
     🗷 01F5F7 BALLOT BOX WITH BOLD SCRIPT X
     ╳ 002573 BOX DRAWINGS LIGHT DIAGONAL CROSS
     ▦ 0025A6 SQUARE WITH ORTHOGONAL CROSSHATCH FILL"
  :type 'string)

(defcustom crossword-wrap-on-entry-or-nav t
  "How to advance at ends of puzzle.

When non-NIL, automatically return to top-left when at final
lower-right position and either entering data or navigating
forward. This value will also be used for navigating backward
from the top-left position to wrap to lower-right. When NIL,
POINT is not advanced in such circumstances."
  :type 'boolean)

(defcustom crossword-auto-nav-only-within-clue t
  "Stay within a clue when entering or deleting data.
Don't ever automatically proceed to the first square of the next
clue. If all squares of the current clue have alpha characters,
then stay at the current square. Otherwise, auto advance to the
next non-alpha character square of the current clue,
wrapping-around if necessary."
  :type 'boolean)


(defcustom crossword-arrow-changes-direction t
  "Arrow keys also change current clue direction across/down.
When nil, arrow keys always navigate to next square in their
direction. When non-nil, arrow keys only navigate in the current
clue direction, and if that doesn't match the arrow direction,
the clue direction is changed."
  :type 'boolean)


(defcustom crossword-tab-to-next-unfilled t
  "Tabbing navigates to first empty square in next field.
When NIL, functions `crossword-next-field' and
`crossword-prior-field' always navigate to the first square of
the next/prior field. When non-NIL, they navigate to the first
empty square in the next/prior that has an empty square, which
could be several fields distant."
  :type 'boolean)


(defcustom crossword-download-puz-alist '(
  ("Universal Daily (Daily 15x15)"
     "http://herbach.dnsalias.com/uc/uc%y%m%d.puz")
  ("Universal Daily (Sunday bonus, 21x21)"
     "http://herbach.dnsalias.com/uc/ucs%y%m%d.puz")
  ("Wall Street Journal (Mondays-Saturdays)"
     "http://herbach.dnsalias.com/wsj/wsj%y%m%d.puz")
  ("Washington Post (Sundays)"
     "http://herbach.dnsalias.com/WaPo/wp%y%m%d.puz")
  ("Matt Jones' (Thursdays)"
     "http://herbach.dnsalias.com/Jonesin/jz%y%m%d.puz"))
  "Download resources for .puz files."
  :type '(repeat (list (string :tag "Resource description")
                       (string :tag "URL"))))


(defcustom crossword-download-xml-alist '(
  ("Los Angeles Times" .
     "http://cdn.games.arkadiumhosted.com/latimes/assets/DailyCrossword/la%y%m%d.xml")
  ("Newsday" .
     "http://picayune.uclick.com/comics/crnet/data/crnet%y%m%d-data.xml")
  ("USA Today (Monday-Saturday?)" .
     "http://picayune.uclick.com/comics/usaon/data/usaon%y%m%d-data.xml")
  ("Universal" .
     "http://picayune.uclick.com/comics/fcx/data/fcx%y%m%d-data.xml")
  ("LA Times Sunday" .
     "http://picayune.uclick.com/comics/lacal/data/lacal%y%m%d-data.xml"))
  "Download resources for .xml file.
NOTE: Support for this file format has not yet been written!"
  :type '(repeat (cons (string :tag "Resource description")
                       (string :tag "URL"))))


(defcustom crossword-puzzle-file-coding 'iso-8859-1
  "Coding system for reading puz files.
Only change this if you are having problems reading a puz file."
  :type 'coding-system)



;;
;;; Faces

(defface crossword-current-face
 '((((class color) (background light))
        (:background "lightgreen" :foreground "black" :inherit 'normal))
   (((class color) (background dark))
        (:background "darkgreen" :foreground "black" :inherit 'normal))
   (t   (:background "darkgreen" :foreground "black" :inherit 'normal)))
 "For the current clue and word.")


(defface crossword-other-dir-face
 '((((class color) (background light))
        (:background "darkgrey" :foreground "black" :inherit 'normal))
   (((class color) (background dark))
        (:background "brightblack" :foreground "black" :inherit 'normal))
   (t   (:background "brightblack" :foreground "black" :inherit 'normal)))
 "For the current clue and word.")


(defface crossword-error-face
 '((t (:background "red" :foreground "black" :inherit 'normal)))
 "For a letter that has been checked and is wrong.")


(defface crossword-error-inverse-face
 '((t (:inverse-video t :inherit 'crossword-error-face)))
 "For a letter that has been checked and is wrong.")


(defface crossword-checked-face
 '((t (:foreground "cyan" :inherit 'normal)))
 "For a letter that has been checked and is correct.")


(defface crossword-solved-face
 '((((class color) (background light))
        (:background "cyan" :inherit 'normal))
   (((class color) (background dark))
        (:foreground "brightyellow" :inherit 'normal))
   (t   (:foreground "brightyellow" :inherit 'normal)))
 "For a letter that the user has asked to be solved.")


(defface crossword-grid-face
 '((((class color) (background light))
        (:foreground "blue" :inherit 'normal))
   (((class color) (background dark))
        (:foreground "blue" :inherit 'normal))
   (t   (:foreground "blue" :inherit 'normal)))
 "For un-writable squares and grid-lines.")



;;
;;; Constants

(defconst crossword--max-width  30
  "Arbitrarily set, for sanity checking.")

(defconst crossword--max-height 30
  "Arbitrarily set, for sanity checking.")

(defconst crossword--grid-characters
  (format "[^\n|%s]" crossword-empty-position-char)
  "Characters not part of the grid layout.
These mark un-writable positions of the grid. This variable is
used to auto-advance to the next across position when inserting a
character.")



;;
;;; Buffer-local variables (only for crossword-grid buffer)

(defvar-local crossword--version       nil
  "Version used to create puz-emacs file.
For format and data structure compatability purposes.")

(defvar-local crossword--filename      nil)
(defvar-local crossword--hash          nil)
(defvar-local crossword--date          nil)
(defvar-local crossword--across-buffer nil)
(defvar-local crossword--down-buffer   nil)

;; Useful static positions within a "Crossword grid" buffer.
(defvar-local crossword--first-square nil)
(defvar-local crossword--last-square nil)
(defvar-local crossword--timer-state-pos 0)
(defvar-local crossword--timer-value-pos 0)
(defvar-local crossword--checked-count-pos 0)
(defvar-local crossword--error-count-pos 0)
(defvar-local crossword--cheat-count-pos 0)
(defvar-local crossword--solved-percent-pos 0)
(defvar-local crossword--completion-percent-pos 0)
(defvar-local crossword--grid-end 0)
(defvar-local crossword--prior-point 1
  "Used by function `crossword--update-faces'.")
(defvar-local crossword--first-column 3
  "Really a constant. Placed here among similar symbols.")
(defvar-local crossword--last-column 0)

;; Tallies for progress statistics feedback
(defvar-local crossword--total-count 0
  "Total number of puzzles squares to be solved.")
(defvar-local crossword--completed-count 0
  "Number of squares filled.")
(defvar-local crossword--solved-count 0
  "Number of puzzle squares verified as correctly solved.")
(defvar-local crossword--error-count 0
  "Number of unique letters checked and found incorrect.")
(defvar-local crossword--checked-count 0
  "Number of unique letters checked.")
(defvar-local crossword--cheat-count 0
  "Number of unique letters asked for as hints.")

;; Timer-related
(defvar-local crossword--timer-elapsed 0)
(defvar-local crossword--timer-object nil)


(defvar-local crossword--across-clue-list nil
  "Bounds data structure for across clues.
A list, each member of which comprises six elements: The clue
number; The clue string; The first buffer position of the clue;
The final buffer position of the clue, and; The beginning and end
positions of the clue in the `crossword--across-buffer'..")

(defvar-local crossword--down-clue-list nil
  "Bounds data structure for down clues.
A list, each member of which comprises five elements: The clue
number; The clue string; a list of buffer positions of the clue,
and; The beginning and end positions of the clue in the
`crossword--down-buffer'.")

(defvar-local crossword--nav-dir 'across
  "Current navigation direction within the puzzle,
either 'across or 'down.")

(defvar-local crossword--downloading-available
  (load "crossword-download" t)
  "The crossword downloader is optional and independent.")

(defvar-local crossword--local-proc nil
  "Stores a process object for a download.")

(defvar-local crossword--called-interactively-p nil
  "Record if containing function was called interactively.")


;;
;;; Buffer-local variables (only for crossword-download buffer)


(defvar-local crossword--download-processes-list nil)



;;
;;; Keymap and Mode definitions

(defvar crossword-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-s")       'crossword-backup)
    (define-key map (kbd "C-c C-x C-f")   'crossword-restore)
    (define-key map (kbd "<left>")        'crossword-prior-char)
    (define-key map (kbd "<right>")       'crossword-next-char)
    (define-key map (kbd "<RET>")         'crossword-next-char)
    (define-key map (kbd "<deletechar>")  'crossword-del-char)
    (define-key map (kbd "SPC")           'crossword-del-char)
    (define-key map (kbd "DEL")           'crossword-bsp-char)
    (define-key map (kbd "M-a")           'crossword-nav-dir-across)
    (define-key map (kbd "M-d")           'crossword-nav-dir-down)
    (define-key map (kbd "M-<SPC>")       'crossword-nav-dir-toggle)
    (define-key map (kbd "C-a")           'crossword-begin-field)
    (define-key map (kbd "C-e")           'crossword-end-field)
    (define-key map "\t"                  'crossword-next-field)
    (define-key map (kbd "<backtab>")     'crossword-prior-field)
    (define-key map (kbd "/")             'crossword-goto-clue)
    (define-key map (kbd "M-<")           'crossword-first-square)
    (define-key map (kbd "M->")           'crossword-last-square)
    (define-key map (kbd "M-c l")         'crossword-check-letter)
    (define-key map (kbd "M-c w")         'crossword-check-word)
    (define-key map (kbd "M-c p")         'crossword-check-puzzle)
    (define-key map (kbd "M-s l")         'crossword-solve-letter)
    (define-key map (kbd "M-s w")         'crossword-solve-word)
    (define-key map (kbd "M-s p")         'crossword-solve-puzzle)
    (define-key map (kbd "M-p")           'crossword-pause-unpause-timer)
    (define-key map (kbd "M-t")           'crossword-pause-unpause-timer)
    (define-key map (kbd "M-q")           'crossword-quit)
    (define-key map [remap next-line]     'crossword-next-line)
    (define-key map [remap previous-line] 'crossword-previous-line)
    (define-key map (kbd "<M-up>")        'crossword-clue-scroll-up)
    (define-key map (kbd "<M-down>")      'crossword-clue-scroll-down)
    (define-key map (kbd "M-<next>")      'crossword-clue-scroll-page-up)
    (define-key map (kbd "M-<prior>")    'crossword-clue-scroll-page-down)
    (define-key map (kbd "M-<home>")      'crossword-clue-scroll-page-home)
    (define-key map (kbd "M-<end>")       'crossword-clue-scroll-page-end)
    map))


(defvar crossword-summary-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q")      'crossword-quit)
    (define-key map (kbd "M-q")    'crossword-quit)
    (define-key map (kbd "<RET>")  'crossword-summary-select)
    (define-key map (kbd "d")      'crossword-summary-delete)
    (define-key map "\t"              'crossword-summary-tab-forward)
    (define-key map (kbd "<backtab>") 'crossword-summary-tab-backward)
    (define-key map (kbd "g")      'crossword-summary-revert-buffer)
    (define-key map (kbd "S")      'crossword-summary-sort)
    map))


(define-derived-mode crossword-mode fundamental-mode "Crossword"
  "Operate on puz file format crossword puzzles.
\\{crossword-mode-map}"
  (add-hook 'post-command-hook #'crossword--update-faces t t)
  (overwrite-mode)
  (face-remap-add-relative 'default :family "Monospace")
  (advice-add #'self-insert-command
              :around #'crossword--advice-around-self-insert-command)
  (advice-add #'call-interactively
              :around #'crossword--advice-around-call-interactively))


(define-derived-mode crossword-summary-mode tabulated-list-mode
  "Known crossword puzzles"
  "Mode for displayed crossword summary lists."
  (setq tabulated-list-format
       `[("filename" 10 t)
         ("extension" 9 t)
         ("date" 10 t)
         ("title" 30 t)
         ("author" 30 t)
         ("publisher/copyright" 25 t)
         ("%%filled" 7 t :right-align t)
         ("%%solved" 7 t :right-align t)
         ("checked" 7 t :right-align t)
         ("errors" 7 t :right-align t)
         ("cheats" 7 t :right-align t)
         ("time" 5 t)])
  (setq tabulated-list-sort-key (cons "date" 'flip))
  (setq tabulated-list-padding 2)
  (setq tabulated-list-entries #'crossword--summary-list-entries)
  (add-hook 'tabulated-list-revert-hook #'crossword--summary-revert-hook-function nil t)
  (hl-line-mode)
  (tabulated-list-init-header))



;;
;;; Macros


(defmacro crossword--get-date (file)
  "Return a consistent date string for FILE."
  `(format-time-string "%Y/%m/%d" (nth 6 (file-attributes ,file))))


(defmacro crossword--summary-file ()
  "Return the path to the expected crossword summary file."
  `(concat (file-name-as-directory crossword-save-path) "puz-emacs.data"))

(defmacro crossword--puzzle-file-list ()
  "Return list of known puzzle files."
  `(directory-files crossword-save-path 'full "\\.puz\\(-emacs\\)?$"))



;;
;;; Hook functions


(defun crossword--kill-grid-buffer-hook-function ()
  "Hook function for `kill-buffer-hook'."
  (when crossword--timer-object
    (cancel-timer crossword--timer-object))
  (let ((crossword-quit-to-browser nil))
    (crossword-quit)))


(defun crossword--kill-all-asociated-processes ()
  "Crossword-download buffer hook function for `kill-buffer-hook'."
  (let (x)
    (while (setq x (pop crossword--download-processes-list))
      (when (processp (car x))
        (delete-process (car x)))
      (when (bufferp (cdr x))
        (kill-buffer (cdr x))))))


;;(defun crossword--kill-associated-process () t)
(defun crossword--kill-associated-process ()
  "Crossword-download buffer hook function for `kill-buffer-hook'.
PROC should have been set as a local variable at buffer creation."
  (if (not (processp crossword--local-proc))
    (message "Warning: no process found to kill (crossword-download).")
   (delete-process crossword--local-proc)
   (assq-delete-all crossword--local-proc crossword--download-processes-list)))


(defun crossword--face-current-remove (start end)
  "Remove just `crossword-current-face' from region START END.
Leave alone any other faces."
  (let ((pos start)
        this-face)
    (while (< pos end)
      (when (setq this-face (get-text-property pos 'face))
        (if (eq this-face 'crossword-current-face)
          (remove-text-properties pos (1+ pos) '(face))
         (when (listp this-face)
           (put-text-property pos (1+ pos)
             'face (delq 'crossword-current-face this-face)))))
      (cl-incf pos))))

(defun crossword--face-current-add (start end)
  "Conditionally apply `crossword-current-face' to region START END.
Only do so at points that have no other face."
  ;; FIXME: This seems no longer necessary
  (add-face-text-property start end 'crossword-current-face t))

(defun crossword--update-faces (&optional force)
  "Called mainly as a `post-command-hook' function for `crossword-mode'.
Called also by `crossword-restore', in which case the optional FORCE
arg is non-nil in order to ensure that clue buffers are properly
fontified. Also called by `crossword--start-game'.

This function operates upon all three crossword buffers, and
expects the current buffer to be the crossword grid-buffer."
  (when (or (not (equal (point) crossword--prior-point))
            force)
    (let ((grid-buffer (current-buffer))
          (across-buffer crossword--across-buffer)
          (down-buffer   crossword--down-buffer)
          (nav-dir       crossword--nav-dir)
          (inhibit-read-only t)
          (return-pos (point))
          (this-clue-across (get-text-property (point) 'clue-across))
          (this-clue-down (get-text-property (point) 'clue-down))
          clue prior-clue-num pos pos-max pos-list)
      ;; Grid buffer: across calculations
      (setq prior-clue-num (get-text-property crossword--prior-point 'clue-across))
      (when (or (not (eq prior-clue-num this-clue-across))
                force)
        (when prior-clue-num
          (setq clue (assq prior-clue-num crossword--across-clue-list)
                pos (nth 2 clue)
                pos-max (nth 3 clue))
          (while (< pos pos-max)
            (unless (and (eq nav-dir 'down) this-clue-down
                         (eq this-clue-down
                             (get-text-property pos 'clue-down)))
              (crossword--face-current-remove pos (1+ pos)))
              (cl-incf pos))
          (with-current-buffer across-buffer
            (remove-text-properties (nth 4 clue) (nth 5 clue) '(face))))
        (when this-clue-across
          (setq clue (assq this-clue-across crossword--across-clue-list))
          (when (eq nav-dir 'across)
            (crossword--face-current-add (nth 2 clue) (nth 3 clue)))))
      ;; Grid buffer: down calculations
      (setq prior-clue-num (get-text-property crossword--prior-point 'clue-down))
      (when (or (not (eq prior-clue-num this-clue-down))
                force)
        (when prior-clue-num
          (setq clue (assq prior-clue-num crossword--down-clue-list))
          (setq pos-list (nth 2 clue))
          (while (setq pos (pop pos-list))
            (unless (and (eq nav-dir 'across)
                         (eq this-clue-across
                             (get-text-property pos 'clue-across)))
              (crossword--face-current-remove pos (1+ pos))))
          (with-current-buffer down-buffer
            (remove-text-properties (nth 3 clue) (nth 4 clue) '(face))))
        (when this-clue-down
          (setq clue (assq this-clue-down crossword--down-clue-list))
          (when (eq nav-dir 'down)
            (setq pos-list (nth 2 clue))
            (while (setq pos (pop pos-list))
              (crossword--face-current-add pos (1+ pos))))))
      ;; Across-clues buffer
      (when this-clue-across
        (setq clue (assq this-clue-across crossword--across-clue-list))
        (pop-to-buffer across-buffer)
        (goto-char (nth 4 clue))
        (put-text-property (point) (nth 5 clue)
                           'face (if (eq nav-dir 'across)
                                   'crossword-current-face
                                  'crossword-other-dir-face))
        (recenter)
        (while (pos-visible-in-window-p (point-max))
          (scroll-down 1)))
      (pop-to-buffer grid-buffer) ;; to access buffer-local variable
      ;; Down-clues buffer
      (when this-clue-down
        (setq clue (assq this-clue-down crossword--down-clue-list))
        (pop-to-buffer down-buffer)
        (goto-char (nth 3 clue))
        (put-text-property (point) (nth 4 clue)
                           'face (if (eq nav-dir 'down)
                                   'crossword-current-face
                                  'crossword-other-dir-face))
        (recenter)
        (while (pos-visible-in-window-p (point-max))
          (scroll-down 1)))
      ;; Grid clues (bottom of the grid buffer)
      (pop-to-buffer grid-buffer)
      (crossword--update-grid-clues this-clue-across this-clue-down)
      (goto-char (setq crossword--prior-point (min return-pos (point-max)))))))


(defun crossword--update-grid-clues (this-clue-across this-clue-down)
  "Update the clue text appearing below the crossword grid.
THIS-CLUE-ACROSS and THIS-CLUE-DOWN are integers values."
  (let ((return-pos (point))
        elem)
    (goto-char crossword--grid-end)
    (delete-region (point) (point-max))
    (setq return-pos (min return-pos (point-max)))
    (insert
      (format " Across:\n\n%s\n Down:\n\n%s%s"
        (if (not this-clue-across) ""
         (setq elem (assq this-clue-across crossword--across-clue-list))
         (with-current-buffer crossword--across-buffer
           (buffer-substring (nth 4 elem) (nth 5 elem))))
        (if (not this-clue-down) ""
         (setq elem (assq this-clue-down crossword--down-clue-list))
         (with-current-buffer crossword--down-buffer
           (buffer-substring (nth 3 elem) (nth 4 elem))))
        (if (not (setq elem (get-text-property return-pos 'errors))) ""
         (format "\n Errors:\n\n  %s"
                 (propertize (substring (format "%s" elem) 1 -1)
                             'face 'crossword-error-inverse-face)))))
    (goto-char return-pos)))


(defun crossword--summary-revert-hook-function ()
  "Hook function for `tabulated-list-revert-hook'.
See mode `crossword-summary-mode'."
  (crossword-summary-rebuild-data)
  (tabulated-list-init-header)
  (tabulated-list-print t)
  (recenter))



;;
;;; Advice functions

(defun crossword--advice-around-self-insert-command (oldfun &rest args)
  "Advice for handling insertions in the 'Crossword grid' buffer.

While this function needs no arguments for itself, the advised
function does: OLDFUN is the advised function, per function
`advice-add' and ARGS are per function `self-insert-command'.

This function is a central part of the package, as it controls
data-entry, fontification, advances POINT to the next grid
position, and updates the puzzle's completion statistics."
  (if (not (and crossword--called-interactively-p
             (eq major-mode 'crossword-mode)
             (get-text-property (point) 'answer)
             (not (get-text-property (point) 'solved))))
    (apply oldfun args)
   (setq crossword--called-interactively-p nil)
   (crossword--insert-char)
   (if crossword-auto-nav-only-within-clue
     (crossword--next-square-in-clue 'wrap)
    (crossword--next-logical-square))))


(defun crossword--advice-around-call-interactively (oldfun func &rest args)
  "Possibly set variable `crossword--called-interactively-p'.
This is necessary to enable advising around
`self-insert-command'. OLDFUN is the advised function, per function
`advice-add' and FUNC and ARGS are per function `call-interactively'."
  (when  (and (eq func 'self-insert-command)
              (eq major-mode 'crossword-mode)
              (get-text-property (point) 'answer)
              (not (get-text-property (point) 'solved)))
    (setq crossword--called-interactively-p t))
  (apply oldfun func args))



;;
;;; Internal functions


(defun crossword--check-and-create-save-path ()
  "Check that a crossword save directory exists.
If not, prompts the user to create one. Return non-nil on
sucess."
  (let ((save-dir crossword-save-path))
   (cond
    ((file-directory-p save-dir) t)
    ((yes-or-no-p (format "Save directory '%s' does not exist.\nWe can create it now, or you can choose another save-path.\nDo so now? " save-dir))
      (while (not (setq save-dir (read-file-name "? " nil "Crosswords"))))
      (make-directory  save-dir t)
      (setq crossword-save-path (file-name-as-directory save-dir)))
    (t nil))))


(defun crossword--calendar-read-date ()
  "Prompt for Gregorian date.  Return a list (day month year).
This function is based upon function `calendar-read-date' of
package calendar.el. See Emacs bug report 32105 for the relevant
discussion and patch submission. Additionally, this version
orders its return list to be consistent with function
`encode-time'."
  (let* ((today (calendar-current-date))
         (year (calendar-read
                "Year (>0): "
                (lambda (x) (> x 0))
                (number-to-string (calendar-extract-year today))))
         (month-array calendar-month-name-array)
         (completion-ignore-case t)
         (month (cdr (assoc-string
                       (completing-read
                        "Month name: "
                        (mapcar #'list (append month-array nil))
                        nil t nil nil
                        (aref month-array (1- (calendar-extract-month today))))
                      (calendar-make-alist month-array 1) t)))
         (last (calendar-last-day-of-month month year)))
    (list (calendar-read (format "Day (1-%d): " last)
                         (lambda (x) (and (< 0 x) (<= x last)))
                         (number-to-string (calendar-extract-day today)))
          month
          year)))


(defun crossword--window-resize-function (frame)
  "How to respond to window/frame resize events.
FRAME is expected to be the `selected-frame'. This function is
meant for variable `window-size-change-functions'. It rebalances
the frame's three windows, auto-fills the contents of the two
clue listing buffers, and updates the clue data-structures."
(when (and (equal "Crossword"
                  (cdr (assq 'name (frame-parameters frame))))
           (not (minibuffer-window-active-p (active-minibuffer-window))))
  (balance-windows)
  ;; snippet based upon part of function `crossword--start-game-puz'
  (let (grid-buffer
        (across-buffer    crossword--across-buffer)
        (down-buffer      crossword--down-buffer)
        (across-clue-list crossword--across-clue-list)
        (down-clue-list   crossword--down-clue-list)
        (inhibit-read-only t))
    (when (setq grid-buffer (get-buffer "Crossword grid"))
      (set-buffer grid-buffer)
      (cl-flet ((strip2 (x) (mapcar (lambda (elem) (butlast elem 2)) x)))
        (setq across-clue-list
          (crossword--insert-clues across-buffer
                                   'clue-across
                                   (strip2 across-clue-list)
                                   "--- Across clues for crossword"))
        (setq down-clue-list
          (crossword--insert-clues down-buffer
                                   'clue-down
                                   (strip2 down-clue-list)
                                   "--- Down clues for crossword")))
      ;; ** Finish in grid buffer
      (set-buffer grid-buffer)
      (setq crossword--across-clue-list across-clue-list
            crossword--down-clue-list   down-clue-list)
      (crossword--update-faces 'force)))))


(defun crossword--insert-char ()
  "Insert a character into a crossword grid square.
Update the puzzle's completion statistics, and fontify the
character as needed.

The function, as a major component of function
`crossword--advice-around-self-insert-command', is a central part
of `crossword', as it controls data-entry, fontification, and
updates the puzzle's completion statistics. It works because it
sets variable `last-input-event' to nil after using its value."
    (let ((inhibit-read-only t)
          (char-to-insert (upcase (char-to-string last-input-event)))
          (char-current (buffer-substring-no-properties (point) (1+ (point))))
          (face-at-point (get-text-property (point) 'face))
          (goto-pos (point)))
      (setq last-input-event nil)
      ;; ** Insert a character into grid
      (forward-char)
      (insert-and-inherit char-to-insert)
      (backward-char)
      (delete-char -1)
      ;; ** Update the square's face
      (if (not (member char-to-insert (get-text-property (point) 'errors)))
        (when (listp face-at-point)
          (setq face-at-point (delq 'crossword-error-face face-at-point)))
       (add-face-text-property (point) (1+ (point)) 'crossword-error-face)
       (setq face-at-point (get-text-property (point) 'face)))
      (when (listp face-at-point)
        (put-text-property (point) (1+ (point)) 'face
          (setq face-at-point (delq nil face-at-point))))
      ;; ** Update puzzle completion sattistics
      (cond
       ((string-match "[[:upper:]]" char-to-insert)
        (when (and (not (member char-to-insert (get-text-property (point) 'errors)))
                   (or (not (string-match "[[:upper:]]" char-current))
                       (member char-current (get-text-property (point) 'errors))))
          (crossword--incf-completion-count 1))
        (when (and crossword-auto-check-completed
                   (>= crossword--completed-count crossword--total-count))
            (crossword-check-puzzle)))
       (t ; ie. (not (string-match "[[:upper:]]" char-to-insert))
        (when (and (string-match "[[:upper:]]" char-current)
                   (not (member char-current (get-text-property (point) 'errors))))
          (crossword--incf-completion-count -1))))
      (goto-char goto-pos))
    (setq buffer-read-only t))


(defun crossword--is-empty-square (&optional pos)
  "Return non-NIL if square at POS is considered 'empty'.
If POS is NIL, acts on POINT. In this context, 'empty' means not
:upper: and not a known error."
  (let* ((pos (or pos (point)))
         (this (buffer-substring pos (1+ pos))))
    (or (not (string-match "[[:upper:]]" this))
        (member this (get-text-property pos 'errors)))))


(defun crossword--timer-update ()
  "Update the timer and its display."
  ;; FIXME: Does not update when buffer visible but not selected
  (when (< crossword--timer-elapsed 5999) ; Don't overflow mm:ss format
    (with-current-buffer "Crossword grid"
      (let* ((inhibit-read-only t)
             (seconds (cl-incf crossword--timer-elapsed))
             (minutes (min (/ seconds 60) 99))
             (seconds (% seconds 60))
             (pos (point)))
        (goto-char crossword--timer-value-pos)
        (re-search-forward "....." nil t)
        (replace-match
          (propertize (format "%02d:%02d" minutes seconds)
            'face 'crossword-checked-face))
        (goto-char pos)))))


(defun crossword--local-vars-list ()
  "Return a list of local variables, suitable for save-files."
  ;; NOTE: (emacs v26): This function was written because of trouble
  ;;   using function `read' to parse the output function
  ;;   `buffer-local-variables' produces for buffer objects. It has the
  ;;   added benefit of excluding many seemingly unnecessary
  ;;   variables.
  (let (result)
    (dolist
      (var '(crossword--version
             crossword--filename
             crossword--date
             crossword--first-square
             crossword--last-square
             crossword--timer-state-pos
             crossword--timer-value-pos
             crossword--checked-count-pos
             crossword--error-count-pos
             crossword--completed-count
             crossword--solved-percent-pos
             crossword--completion-percent-pos
             crossword--cheat-count-pos
             crossword--first-column
             crossword--last-column
             crossword--grid-end
             crossword--prior-point
             crossword--total-count
             crossword--solved-count
             crossword--error-count
             crossword--checked-count
             crossword--cheat-count
             crossword--timer-elapsed
             crossword--timer-object
             crossword--across-clue-list
             crossword--down-clue-list
             crossword--nav-dir
             crossword--downloading-available))
      (push (cons var (or (eval var) nil)) result))
    result))


(defun crossword--pos-above-is-void (pos)
  "Check grid position above POS.
Return t if position above current point is not a writable
puzzle position. POS is expected to be set to current-point."
  (let ((column (current-column)) result)
    (forward-line -1)
    (move-to-column column)
    (when (/= ?- (char-after (point)))
      (setq result t))
    (goto-char pos)
    result))


(defun crossword--fwd-avail (limit)
  "Internal snippet to find next non [[:upper:]] square in buffer.
Searches from POINT to LIMIT. Does not perform down-clue logic.
If an available square is found, set POINT to it and return
POINT. Otherwise returns NIL."
  (let (found test-pos)
    (while (and (not found)
                (re-search-forward crossword--grid-characters limit t))
      (when (crossword--is-empty-square (setq test-pos (1- (point))))
        (goto-char (setq found test-pos))))
    found))

(defun crossword--next-square-in-clue (&optional wrap)
  "Navigate to the next unsolved square in the current clue.
WARNING: This is not the converse of the similar-sounding
function `crossword--prev-square-in-clue'. This function does not
advance to squares containing alpha characters, and when optional
arg WRAP is non-nil, this function wraps-around to the first
square of the current clue."
  (cond
   ((eq crossword--nav-dir 'across)
     (let* ((clue-elem (assq (get-text-property (point) 'clue-across)
                             crossword--across-clue-list))
            (this-pos  (point))
            (begin-pos (nth 2 clue-elem))
            (end-pos   (nth 3 clue-elem)))
       (forward-char)
       (when (and (not (crossword--fwd-avail end-pos))
                  wrap)
         (goto-char begin-pos)
         (unless (crossword--fwd-avail (1+ this-pos))
           (goto-char this-pos)))
       (when (= (point) end-pos)
         (backward-char))))
   (t ;; (eq crossword--nav-dir 'down)
     (let* ((squares (nth 2 (assq (get-text-property (point) 'clue-down)
                                  crossword--down-clue-list)))
            (index (cl-position (point) squares))
            (limit (1- (length squares)))
            test-pos found)
       (when (< index limit)
         (cl-loop
           for  i from (1+ index) to limit
           do   (setq test-pos (nth i squares))
           when (crossword--is-empty-square test-pos)
           return (setq found (goto-char test-pos))))
       (when (and (not found)
                  wrap
                  (not (zerop index)))
         (cl-loop
           for  i from 0 to (1- index)
           do   (setq test-pos (nth i squares))
           when (and (crossword--is-empty-square test-pos)
                     (goto-char test-pos))
           return test-pos))))))


(defun crossword--prev-square-in-clue ()
  "Navigate to the prior unsolved square in the current clue.
WARNING: This is not the converse of the similar-sounding
function `crossword--next-square-in-clue'. This function does not
wrap-around to the final square of the current clue, and it does
advance to squares containing alpha characters."
  (cond
   ((eq crossword--nav-dir 'across)
     (re-search-backward
       crossword--grid-characters
       (nth 2 (assq (get-text-property (point) 'clue-across)
                    crossword--across-clue-list))
       t))
   (t ;; (eq crossword--nav-dir 'down)
     (let* ((squares (nth 2 (assq (get-text-property (point) 'clue-down)
                                  crossword--down-clue-list)))
            (index (cl-position (point) squares)))
       (when (> index 0)
         (goto-char (nth (1- index) squares)))))))


(defun crossword--next-logical-square (&optional arg)
  "Set POINT to next logical clue square.
With optional integer ARG, repeat ARG times."
  (let ((n -1) (max (or arg 1)))
    (while (< (cl-incf n) max)
      (cond
       ((eq crossword--nav-dir 'across)
         (forward-char)
         (if (re-search-forward crossword--grid-characters
                                  crossword--grid-end t)
           (backward-char)
          (if crossword-wrap-on-entry-or-nav
            (goto-char (nth 2 (nth 0 crossword--across-clue-list)))
           (backward-char)
           (setq n arg))))
       (t ;; (eq crossword--nav-dir 'down)
         (let* ((clue-elem (assq (get-text-property (point) 'clue-down)
                                 crossword--down-clue-list))
                (goto-pos (cadr (member (point)
                           (nth 2 clue-elem)))))
           (cond
            (goto-pos ; There is a next position of the current clue
              (goto-char goto-pos))
            ((setq clue-elem ; There is a next clue
               (cadr (memq clue-elem crossword--down-clue-list)))
              (goto-char (car (nth 2 clue-elem))))
            (crossword-wrap-on-entry-or-nav ; Goto beginning of puzzle
              (goto-char (car (nth 2 (car crossword--down-clue-list)))))
            (t
             (setq n arg)))))))))


(defun crossword--prev-logical-square (&optional arg)
  "Set POINT to previous logical clue square.
With optional integer ARG, repeat ARG times."
  (let ((n -1) (max (or arg 1)))
    (while (< (cl-incf n) max)
      (cond
       ((eq crossword--nav-dir 'across)
         (re-search-backward crossword--grid-characters nil t)
         (when (< (point) crossword--first-square)
           (if crossword-wrap-on-entry-or-nav
             (goto-char crossword--last-square)
            (goto-char crossword--first-square)
            (setq n arg))))
       (t ;; (eq crossword--nav-dir 'down)
         (let* ((clue-elem (assq (get-text-property (point) 'clue-down)
                                 crossword--down-clue-list))
                (squares (nth 2 clue-elem))
                (index (cl-position (point) squares)))
           (cond
            ((> index 0)
              (goto-char (nth (1- index) squares)))
            ((> (setq index (cl-position clue-elem crossword--down-clue-list))
                0)
              (goto-char (car (last (nth 2 (nth (1- index) crossword--down-clue-list))))))
            (crossword-wrap-on-entry-or-nav
              (goto-char crossword--last-square))
            (t
              (setq n arg)))))))))


(defun crossword--end-across-clue-pos (pos clue-across)
  "Return the position after the final letter of CLUE-ACROSS at POS.
This will be used for updating the clue's FACESPEC. This function
also sets the 'clue-across property for all cells of the clue."
  (when (search-forward crossword-empty-position-char nil t)
    (put-text-property
      pos (1- (match-beginning 0)) 'clue-across clue-across)
    (goto-char pos)
    (1- (match-beginning 0))))


(defun crossword--list-down-clue-pos (pos clue-down)
  "Return a list of CLUE-DOWN positions at for the clue at POS.
This will be used for updating the clue's FACESPEC. This
function also sets the 'clue-down property for all cells of the
clue."
  (put-text-property pos (1+ pos) 'clue-down clue-down)
  (let ((col (current-column)) (result (list pos)))
    (while (and (forward-line)
                (move-to-column col)
                (eq ?- (char-after (point))))
      (put-text-property (point) (1+ (point)) 'clue-down clue-down)
      (push (point) result))
    (goto-char pos)
    (nreverse result)))

(defun crossword--insert-grid (grid-width colophon clean-grid answer-grid clue-list)
  "Insert a beginning grid into a grid buffer.
This includes crossword COLOPHON, status-line, and grid into an
empty buffer, apply text properties to grid positions, and create
variables `crossword--across-clue-list' and
`crossword--down-clue-list'. GRID-WIDTH is an integer taken from
the puzzle file encoding. COLOPHON, CLEAN-GRID, ANSWER-GRID and CLUE-LIST
are substrings of the puzzle file."
  (let* ((divider "|")
         (block-cell (concat crossword-empty-position-char divider))
         (block-line
           (concat (replace-regexp-in-string
                      "-" block-cell
                      (make-string (+ 1 grid-width) ?-))))
         ;; FIXME: This does not work with lexical binding, so for now the
         ;;        propertizing is done individually with the let*.
         ;; (dolist (var (list 'divider 'block-cell 'crossword-new-line 'block-line))
         ;;   (set var (propertize (symbol-value var) 'face 'crossword-grid-face)))
         (divider    (propertize divider 'face 'crossword-grid-face))
         (block-cell (propertize block-cell 'face 'crossword-grid-face))
         (block-line (propertize block-line 'face 'crossword-grid-face))
         ;; END: FIXME
         (crossword-new-line (concat block-cell "\n" divider block-cell))
         (clue-across 0)
         (clue-down 0)
         start-pos pos)
    (insert " " colophon "\n")
    (decode-coding-region (point-min) (point-max) 'prefer-utf-8-dos)
    (setq start-pos (point))
    (setq crossword--total-count
      (cl-loop with start = 0
               for count from 0
               while (string-match "-" clean-grid start)
               do (setq start (match-end 0))
               finally return count))
    (insert
      (format " Filled:    0%% (  0/%3d) Timer: [off] 00:00\n" crossword--total-count)
      (format " Solved:    0%% (  0/%3d)\n" crossword--total-count)
              " Checked:   0  Errors:   0  Cheats:   0\n\n")
    (setq crossword--completion-percent-pos (+  10 start-pos)
          crossword--timer-state-pos        (+  33 start-pos)
          crossword--timer-value-pos        (+  38 start-pos)
          crossword--solved-percent-pos     (+  54 start-pos)
          crossword--checked-count-pos      (+  79 start-pos)
          crossword--error-count-pos        (+  92 start-pos)
          crossword--cheat-count-pos        (+ 105 start-pos))
    (insert divider block-line)
    (insert crossword-new-line)
    (setq start-pos (point)
          pos start-pos)
    (insert clean-grid)
    (goto-char start-pos)
    (while (not (eobp))
      (forward-char grid-width)
      (insert crossword-new-line))
    (insert block-line)
    (goto-char start-pos)
    (while (search-forward "-" nil t)
       (insert divider))
    (when (and crossword-empty-position-char
               (= 1 (length crossword-empty-position-char)))
      (goto-char start-pos)
      (while (search-forward "." nil t)
        (replace-match block-cell)))
    ;; Identify clue bounds and build data structures for quicker clue navigation
    (goto-char start-pos)
    (while (not (eobp))
      (when (= ?- (char-after pos))
        (cond
         ((/= ?- (char-after (- pos 2))) ; prior position isn't clue square
            (setq clue-across (1+ (max clue-across clue-down)))
            (push
              (list clue-across
                    (pop clue-list)
                    pos
                    (crossword--end-across-clue-pos pos clue-across))
              crossword--across-clue-list)
            (when (crossword--pos-above-is-void pos)
              (setq clue-down clue-across)
              (push
                (list clue-down
                      (pop clue-list)
                      (crossword--list-down-clue-pos pos clue-down))
                crossword--down-clue-list)))
         ((crossword--pos-above-is-void pos) ; position above isn't clue square
            (setq clue-down (1+ (max clue-across clue-down)))
            (push
              (list clue-down
                    (pop clue-list)
                    (crossword--list-down-clue-pos pos clue-down))
              crossword--down-clue-list)))
        (put-text-property pos (1+ pos) 'answer (substring answer-grid 0 1))
        (setq answer-grid (substring answer-grid 1)))
      (goto-char (setq pos (1+ pos))))
    (setq crossword--grid-end (+ 2 (goto-char (point-max))))
    (insert "\n\n Across:\n\n\n\n Down:")
    (goto-char start-pos)
    (setq crossword--across-clue-list (nreverse crossword--across-clue-list))
    (setq crossword--down-clue-list (nreverse crossword--down-clue-list))))

(defun crossword--insert-clues (buf prop clue-list header)
  "Fill a clues buffer with clues text, and return updated data.
BUF is the buffer object on which to operate, and should be
either the buffer labeled \"Crossword across\" or \"Crossword
down\". PROP is the text property for the clues, and should be
either 'clue-across or 'clue-down. CLUE-LIST is either the data
structure `crossword--across-clue-list' or
`crossword--down-clue-list'. HEADER is a string for the buffer's
header line."
  (set-buffer buf)
  (erase-buffer)
  (let ((fill-prefix "    ")
        (fill-column (- (window-text-width) 2))
        (pos (point-min))
        new-clue-data new-clue-list)
    (setq header-line-format header)
    (dolist (clue clue-list)
      (insert (propertize (format "%3s  %s\n\n" (car clue) (cadr clue))
                          prop (car clue)))
      (fill-region pos (point))
      (decode-coding-region pos (point) 'prefer-utf-8-dos)
      (setq new-clue-data (append clue (list pos (1- (point)))))
      (push new-clue-data new-clue-list)
      (setq pos (point)))
    (setq buffer-read-only t)
    (goto-char (point-min))
    (nreverse new-clue-list)))


(defun crossword--select-frame ()
  "Select the \"Crossword\" frame, possibly creating it."
  (unless (equal (frame-parameter nil 'name) "Crossword")
    (condition-case nil
      (select-frame-by-name "Crossword")
      (error (select-frame
               (make-frame (list '(name   . "Crossword")
                                 '(menu-bar-lines .  0)
                                 '(tool-bar-lines .  0)
                                 '(height .  43)
                                 '(width  . 140))))))))


(defun crossword--construct-clue-buffers ()
  "Inserts clues into clue buffers and updates data structures."
  (let ((grid-window      (selected-window))
        (across-clue-list crossword--across-clue-list)
        (down-clue-list   crossword--down-clue-list)
        (across-buffer    crossword--across-buffer)
        (down-buffer      crossword--down-buffer))
  ;; ** Fill across buffer
  (setq across-clue-list
    (crossword--insert-clues across-buffer
                             'clue-across
                             across-clue-list
                             "--- Across clues for crossword"))
  ;; ** Fill down buffer
  (setq down-clue-list
    (crossword--insert-clues down-buffer
                             'clue-down
                             down-clue-list
                             "--- Down clues for crossword"))
  (select-window grid-window 'norecord)
  (setq crossword--across-clue-list across-clue-list
        crossword--down-clue-list   down-clue-list)))


(defun crossword--recover-game-in-progress ()
  "Restore frame, windows, and buffers of a game in progress.
If no game is in progress, returns to caller, otherwise signals a
`user-error'."
  (let ((inhibit-read-only t)
        (grid-buffer (get-buffer "Crossword grid"))
        across-buffer down-buffer
        grid-window across-window down-window)
    (when grid-buffer
      (message "Game in progress. Restoring...")
      (condition-case nil
        (progn
          (select-frame-by-name "Crossword")
          (delete-frame nil 'force))
        (error nil))
      (crossword--select-frame)
      (delete-other-windows)
      (switch-to-buffer grid-buffer)
      (setq grid-window   (selected-window)
            across-buffer (setq crossword--across-buffer
                            (get-buffer-create  "Crossword across"))
            down-buffer   (setq crossword--down-buffer
                            (get-buffer-create  "Crossword down"))
            down-window   (split-window-right)
            across-window (split-window-right))
      (set-window-dedicated-p nil nil)
      (switch-to-buffer grid-buffer 'norecord 'force)
      (set-window-dedicated-p nil t)
      (select-window across-window 'norecord)
      (set-window-dedicated-p nil nil)
      (buffer-disable-undo
        (switch-to-buffer across-buffer 'norecord 'force))
      (set-window-dedicated-p nil t)
      (select-window down-window 'norecord)
      (set-window-dedicated-p nil nil)
      (buffer-disable-undo
        (switch-to-buffer down-buffer 'norecord 'force))
      (set-window-dedicated-p nil t)
      (select-window grid-window 'norecord)
      (crossword--construct-clue-buffers)
      (user-error "Game in progress. Restoring... complete"))))


(defun crossword--start-game-puz (puz-file grid-window)
  "Parse PUZ-FILE for '.puz' format file and begins play.
GRID-WINDOW is the dedicated crossword-grid window."
  (let ((coding-system-for-read crossword-puzzle-file-coding)
        grid-width grid-height grid-size
        colophon clean-grid answer-grid
        clue-list)
   (select-window grid-window 'norecord) ;; FIXME: should be unnecessary, remove
   (insert-file-contents (setq crossword--filename puz-file))
   ;; ** Sanity checks for 'puz' file format
   (cond
    ((not (string= "ACROSS&DOWN" (buffer-substring-no-properties 3 14)))
       (error "File invalid: incorrect magic number"))
    ((< crossword--max-width (setq grid-width (char-after 45)))
       (error "Puzzle width exceeds our arbitrary maximum"))
    ((< crossword--max-height (setq grid-height (char-after 46)))
       (error "Puzzle height exceeds our arbitrary maximum"))
    (t t))
   ;; ** Parse 'puz' file
   (setq grid-size (* grid-width grid-height))
   (delete-region 1 53) ; remove binary header
   (setq answer-grid
     (replace-regexp-in-string "\\." "" (buffer-substring 1 (1+ grid-size))))
   (delete-region 1 (1+ grid-size))
   (setq clean-grid (buffer-substring 1 (1+ grid-size)))
   (delete-region 1 (1+ grid-size))
   (while (search-forward  "\x00" nil t)
     (replace-match "\n"))
   (goto-char 1)
   (forward-line 3)
   (setq colophon
     (replace-regexp-in-string "\n" "\n " (buffer-substring 1 (point))))
   (delete-region 1 (point))
   (setq clue-list
     (split-string (buffer-substring 1 (point-max)) "\n"))
   (erase-buffer)
   (crossword--insert-grid grid-width colophon clean-grid answer-grid clue-list)
   (crossword--construct-clue-buffers)
   (crossword--incf-completion-count 0)
   (setq crossword--version          "1.0"
         crossword--last-square      (1- (nth 3 (car (last crossword--across-clue-list))))
         crossword--first-square     (nth 2 (nth 0 crossword--across-clue-list))
         crossword--first-column     3
         crossword--date             (crossword--get-date crossword--filename))
   (goto-char crossword--first-square)
   (move-end-of-line nil)
   (setq crossword--last-column (- (current-column) 4))
   (goto-char crossword--first-square)
   (crossword-nav-dir-across)
   (crossword--update-faces)))


(defun crossword--start-game (&optional puz-file)
  "Start a crossword puzzle session.
Prompts for a compatable puzzle file unless optional PUZ-FILE is
provided, prepares the frame/window/buffer environment, parses
the file and begins a crossword puzzle session.

Creates a dedicated three-window frame, with each window
dedicated to a specific crossword buffer. The main crossword
buffer is \"Crossword grid\", which is where game play occurs.
Buffers \"Crossword across\" and \"Crossword down\" list the
puzzle's clues."
  (let (grid-window across-window down-window
        across-buffer down-buffer)
   (unless puz-file
     (while (not (file-readable-p
                   (setq puz-file
                     (read-file-name "Puzzle file: " nil nil t nil))))))
   (crossword--select-frame)
   (set-window-dedicated-p nil nil)
;; FIXME: see TODO note at end of file
;; (setq delete-frame-functions (list #'crossword-quit))
   (setq window-size-change-functions
     ;; FIXME: Maybe 'add-to-list' instead?
     (list #'crossword--window-resize-function))
   ;; Create window and buffer for grid
   (setq grid-window (selected-window))
   (buffer-disable-undo
     (switch-to-buffer (get-buffer-create "Crossword grid")
                       'norecord 'force))
   (set-window-dedicated-p grid-window t)
   (crossword-mode)
   (setq header-line-format " Crossword grid")
   (erase-buffer)
   ;; ** Create window and buffer for ACROSS clues
   (select-window
     (setq across-window (split-window-right))
      t)
   (buffer-disable-undo
     (switch-to-buffer
       (setq across-buffer
         (get-buffer-create "Crossword across"))
       'norecord 'force))
   (set-window-dedicated-p across-window t)
   (erase-buffer) ; Unnecessary, but satisfies neuroses.
   (face-remap-add-relative 'default :family "Monospace")
   ;; ** Create window and buffer for DOWN clues
   (select-window
     (setq down-window (split-window-right))
     t)
   (buffer-disable-undo
     (switch-to-buffer
       (setq down-buffer (get-buffer-create "Crossword down"))
       'norecord 'force))
   (set-window-dedicated-p down-window t)
   (erase-buffer) ; Unnecessary, but satisfies neuroses.
   ;; ** Balance windows now so we can properly fill-paragraphs
   (balance-windows)
   ;; ** Finish in grid buffer
   (select-window grid-window 'norecord)
   (setq crossword--across-buffer    across-buffer
         crossword--down-buffer      down-buffer)
   (add-hook 'kill-buffer-hook #'crossword--kill-grid-buffer-hook-function nil t)
;  (when crossword--downloading-available
;    (add-hook 'kill-buffer-hook 'crossword--kill-all-asociated-processes  nil t))
;  (crossword--update-faces)
   (if (string-match "\\.puz-emacs$" puz-file)
     (crossword-restore puz-file)
    (crossword--start-game-puz puz-file grid-window))
   (setq crossword--hash
     (secure-hash 'md5 (buffer-substring-no-properties
                         (point-min) crossword--grid-end)))
   (setq buffer-read-only t)
   (setq inhibit-read-only nil)))


(defun crossword--summary-list-entries ()
  "For variable `tabulated-list-entries'.
Output is a list, each element of which is (ID [STRING ..
STRING])."
  (let (data result
        (orig-buf (current-buffer))
        (id 0)
        (temp-buf (set-buffer (get-buffer-create "Crossword temporary"))))
    (insert-file-contents (crossword--summary-file))
    (setq data (read temp-buf))
    (kill-buffer temp-buf)
    (set-buffer orig-buf)
    (dolist (elem data result)
      (push (list (cl-incf id) (seq--into-vector elem)) result))))


(defun crossword--date-matcher (str)
  "Return non-nil if STR matches a particular date regex.
This is NOT a general purpose function. It only responds to a
particular observed issue.
The return value is the `match-end' of the regex."
;; Regex to remove date string from Washington Post copyright string:
;; Example: "January 31, 2021, ". Ref: variable `parse-time-months'
  (let ((months (list "January" "February" "March" "April" "May" "June" "July"
                      "August" "September" "October" "November" "December"))
        month found)
    (and
      (progn
        (while (and (not found)
                    (setq month (pop months)))
          (when (string-match month str)
            (setq found (match-end 0))))
        found)
      (string-match " [[:digit:]]?[[:digit:]], [[:digit:]]\\{4\\}, " str found)
      (match-end 0))))


(defun crossword--incf-completion-count (arg)
  "Incrememnt the puzzle 'completion' count by ARG."
  (let ((pos (point)))
    (cl-incf crossword--completed-count arg)
    (goto-char crossword--completion-percent-pos)
    (when (re-search-forward "...% (.../...)" nil t)
      (replace-match
        (format "%3d%% (%3d/%3d)"
          (/ (* 100 crossword--completed-count) crossword--total-count)
          crossword--completed-count
          crossword--total-count)))
    (goto-char pos)))


(defun crossword--incf-error-count ()
  "Incrememnt the puzzle 'error' count."
  (let ((pos (point)))
    (cl-incf crossword--error-count)
    (goto-char crossword--error-count-pos)
    (re-search-forward "..." nil t)
    (replace-match
      (propertize (format "%3d" crossword--error-count)
        'face 'crossword-error-inverse-face))
    (goto-char pos)))


(defun crossword--incf-solved-count ()
  "Incrememnt the puzzle 'solved' count."
  (let ((pos (point)))
    (cl-incf crossword--solved-count)
    (goto-char crossword--solved-percent-pos)
    (when (re-search-forward "...% (.../...)" nil t)
      (replace-match
        (propertize
          (format "%3d%% (%3d/%3d)"
            (/ (* 100 crossword--solved-count) crossword--total-count)
            crossword--solved-count
            crossword--total-count)
          'face
          (if (/= crossword--solved-count crossword--total-count)
            'default
           (add-face-text-property (point-at-bol) (point-at-eol) 'bold)
           'crossword-solved-face))))
    (goto-char pos)))


(defun crossword--incf-checked-count ()
  "Incrememnt the puzzle 'checked' count."
  (let ((pos (point)))
    (cl-incf crossword--checked-count)
    (goto-char crossword--checked-count-pos)
    (re-search-forward "..." nil t)
    (replace-match
      (propertize (format "%3d" crossword--checked-count)
        'face 'crossword-solved-face))
    (goto-char pos)))


(defun crossword--incf-cheat-count ()
  "Incrememnt the puzzle 'cheat' count."
  (let ((pos (point)))
    (cl-incf crossword--cheat-count)
    (goto-char crossword--cheat-count-pos)
    (when (re-search-forward "..." nil t)
      (replace-match
        (propertize
          (format "%3d" crossword--cheat-count)
          'face 'crossword-error-inverse-face)))
    (goto-char pos)))


(defun crossword--cheat-count--get-corrected-positions ()
  "Return correct current position, with 'cheat count' feature.
For puz-emacs files was created before the 'cheat'count feature
was introduced, we need to modify the buffer, and so must also
change the positions of many elements and position variables."
  (if (not (zerop crossword--cheat-count-pos))
    (point)
   (let ((inhibit-read-only t)
         (pos (+ (point) 13)))
     (goto-char crossword--error-count-pos)
     (end-of-line)
     (setq crossword--cheat-count-pos (+ crossword--error-count-pos 13))
     (insert "  Cheats:   0")
     (cl-incf crossword--first-square 13)
     (cl-incf crossword--last-square 13)
     (cl-incf crossword--grid-end 13)
     (dolist (clue crossword--across-clue-list)
       (cl-incf (nth 2 clue) 13)
       (cl-incf (nth 3 clue) 13))
     (setq crossword--down-clue-list
       (mapcar (lambda (clue) (let (squares)
                                (dolist (square (nth 2 clue))
                                  (push (cl-incf square 13) squares))
                                (setf (nth 2 clue) (nreverse squares)))
                                clue)
               crossword--down-clue-list))
     (goto-char pos))))


(defun crossword--minimize-copyright-string (str)
  "Returns a possibly-shortened STR."
  (setq str
    (replace-regexp-in-string
      "^\\( +\\)?\xa9?©?\\( +\\)?\\([[:digit:]]+,? +\\)?" "" str))
  (substring str (crossword--date-matcher str)))


(defun crossword--summary-colophon-list (colophon)
  "Format elements of raw COLOPHON list."
  (list
    (replace-regexp-in-string "^\\( +\\)?" "" (nth 0 colophon))
    (replace-regexp-in-string "^\\( +\\)?\\([Bb]y +\\)?" "" (nth 1 colophon))
    (crossword--minimize-copyright-string (nth 2 colophon))))

(defun crossword--summary-data-puz (file)
  "Get summary data for .puz FILE.
See function `crossword-summary-rebuild-data' for details."
  (let ((coding-system-for-read crossword-puzzle-file-coding)
        grid-width grid-height)
    (with-temp-buffer
      ;; Reference similar code in function `crossword--start-game'
      (insert-file-contents file)
      (cond
       ((not (string= "ACROSS&DOWN" (buffer-substring-no-properties 3 14)))
          (message "File invalid: incorrect magic number: %s" file)
          nil)
       ((< crossword--max-width (setq grid-width (char-after 45)))
          (message "Puzzle width exceeds our arbitrary maximum: %s" file)
          nil)
       ((< crossword--max-height (setq grid-height (char-after 46)))
          (message "Puzzle height exceeds our arbitrary maximum: %s" file)
          nil)
       (t
         (delete-region 1 (+ 51 (* 2 (1+ (* grid-width grid-height)))))
         (dotimes (_n 3)
           (search-forward  "\x00" nil t)
           (replace-match "\n"))
         (nconc
           (list (file-name-sans-extension (file-name-nondirectory file))
                 (file-name-extension file)
                 (crossword--get-date file))
           (crossword--summary-colophon-list
             (butlast (split-string (buffer-substring 1 (point))
                                    "\n" nil)))
           (list "0" "0" "0" "0" "0" "00:00")))))))


(defun crossword--summary-add-current ()
  "Add data from current puzzle to known puzzle data."
  (cl-flet ((getval (start length)
              (replace-regexp-in-string "\n" ""
                (buffer-substring-no-properties start (+ start length)))))
    (goto-char (point-min))
    (nconc (list (file-name-sans-extension (file-name-nondirectory crossword--filename))
                 (file-name-extension crossword--filename)
                 crossword--date)
           (crossword--summary-colophon-list
             (butlast (split-string (buffer-substring-no-properties
                                      1 (1+ (search-forward "\n" nil nil 3)))
                                    "\n")))
           (list
             (getval crossword--completion-percent-pos 3)
             (getval crossword--solved-percent-pos 3)
             (getval crossword--checked-count-pos 3)
             (getval crossword--error-count-pos 3)
             (if (zerop crossword--cheat-count-pos)
               ;; File pre-dates introduction of this feature
               "???"
              (getval crossword--cheat-count-pos 3))
             (getval crossword--timer-value-pos 5)))))


(defun crossword--summary-data-puz-emacs (file)
  "Get summary data for .puz-emacs FILE.
See function `crossword-summary-rebuild-data' for details."
  (let ((temp-buf (set-buffer (get-buffer-create "Crossword temporary")))
        (inhibit-read-only t))
    (insert-file-contents file)
    (with-temp-buffer
      (insert (read temp-buf)) ; grid-buf contents
      (read temp-buf) ; POINT in grid-buf (not needed)
      (dolist (elem (read temp-buf))
        (set (car elem) (cdr elem)))
      (setq crossword--filename file)
      (crossword--summary-add-current))))


(defun crossword--download (url path title)
  "Download a crossword puzzle file from URL.
TITLE is a string. PATH is the destination."
  (let* (proc
        (buf (generate-new-buffer "*crossword-download*"))
        (msg-fmt "%s\n\n  %s \n\n  %s\n\n")
        cmd-str cmd)
    (cond
     ((executable-find "wget")
       (setq cmd-str (format "wget -P %s %s" path url)
             cmd     (list "wget" "-P" path url)))
     ((executable-find "curl")
       (setq cmd-str (format "curl -o %s%s %s" path (file-name-nondirectory url) url)
             cmd     (list "curl" "-o"
                           (concat path (file-name-nondirectory url))
                           url)))
     (t (error "Missing executable 'wget' or 'curl'")))
    (with-current-buffer buf
      (insert (format msg-fmt
                (current-time-string) (or title " ") cmd-str))
      (setq crossword--local-proc (setq proc
        (apply #'start-process "crossword-download" buf cmd)))
      (push (cons proc buf) crossword--download-processes-list)
      (add-hook 'kill-buffer-hook #'crossword--kill-associated-process nil t)
      (message "Requesting download.")
      (set-process-sentinel proc
        (lambda (proc event)
          (let ((buf (process-buffer proc)))
           (with-current-buffer buf (insert event))
           (cond
            ((string-match "^finished" event)
              (message "Download complete")
              (assq-delete-all proc crossword--download-processes-list)
              ;; Is the assq-delete-all safe for race conditions?
              (kill-buffer buf))
            ((string-match "^open" event) t)
            ((string-match "^deleted" event) t)
            (t (message "Download error. Check buffer %s for details." buf)))))))))



;;
;;; Commands


(defun crossword-pause-unpause-timer ()
  "Toggle the crossword game timer on/off."
  (interactive)
  (let ((pos (point))
        (inhibit-read-only t)
        (buffer-undo-list t))
   (cond
    (crossword--timer-object
     (cancel-timer crossword--timer-object)
     (setq crossword--timer-object nil)
     (goto-char crossword--timer-state-pos)
     (re-search-forward "..." nil t)
     (replace-match "off"))
    (t
     (goto-char crossword--timer-state-pos)
     (re-search-forward "..." nil t)
     (replace-match (propertize " on" 'face 'crossword-solved-face))
     (setq crossword--timer-object
       (run-at-time "1 sec" 1 #'crossword--timer-update))))
   (goto-char pos)))


(defun crossword-nav-dir-across ()
  "Set the navigation direction to follow across clues.
Update all relevant faces: In the grid buffer, the current
down-clue's squares will be un-highlighted, and the current
across-clues squares will be highlighted. In the across-clue
buffer, the current clue is highlighted as current, and in the
down-clue buffer, the current clue is highlighted as
other-direction."
  (interactive)
  (unless (eq crossword--nav-dir 'across)
    (setq crossword--nav-dir 'across)
    (let ((inhibit-read-only t)
          (this-clue-across (get-text-property (point) 'clue-across))
          (this-clue-down   (get-text-property (point) 'clue-down))
          clue pos-list pos)
      (when this-clue-down
        (setq clue (assq this-clue-down crossword--down-clue-list))
        (setq pos-list (nth 2 clue))
        (while (setq pos (pop pos-list))
          (crossword--face-current-remove pos (1+ pos)))
        (with-current-buffer crossword--down-buffer
          (put-text-property (nth 3 clue) (nth 4 clue) 'face 'crossword-other-dir-face))
        (setq clue (assq this-clue-across crossword--across-clue-list))
        (crossword--face-current-add (nth 2 clue) (nth 3 clue))
        (with-current-buffer crossword--across-buffer
          (put-text-property (nth 4 clue) (nth 5 clue) 'face 'crossword-current-face))
        (crossword--update-grid-clues this-clue-across this-clue-down)
        (redisplay)))))


(defun crossword-nav-dir-down ()
  "Set the navigation direction to follow down clues.
Update all relevant faces: In the grid buffer, the current
across-clue's squares will be un-highlighted, and the current
down-clues squares will be highlighted. In the down-clue
buffer, the current clue is highlighted as current, and in the
across-clue buffer, the current clue is highlighted as
other-direction."
  (interactive)
  (unless (eq crossword--nav-dir 'down)
    (setq crossword--nav-dir 'down)
    (let ((inhibit-read-only t)
          (this-clue-across (get-text-property (point) 'clue-across))
          (this-clue-down   (get-text-property (point) 'clue-down))
          clue pos-list pos)
      (when this-clue-across
        (setq clue (assq this-clue-across crossword--across-clue-list))
        (crossword--face-current-remove (nth 2 clue) (nth 3 clue))
        (with-current-buffer crossword--across-buffer
          (put-text-property (nth 4 clue) (nth 5 clue) 'face 'crossword-other-dir-face))
        (setq clue (assq this-clue-down crossword--down-clue-list))
        (setq pos-list (nth 2 clue))
        (while (setq pos (pop pos-list))
          (crossword--face-current-add pos (1+ pos)))
        (with-current-buffer crossword--down-buffer
          (put-text-property (nth 3 clue) (nth 4 clue) 'face 'crossword-current-face))
        (crossword--update-grid-clues this-clue-across this-clue-down)
        (redisplay)))))


(defun crossword-nav-dir-toggle ()
  "Toggle between navigating across and down clues."
  (interactive)
  (if (eq crossword--nav-dir 'across)
    (crossword-nav-dir-down)
   (crossword-nav-dir-across)))


(defun crossword-previous-line (&optional arg)
  "Move POINT to clue square above the current field.
Optionally, repeat ARG times."
  (interactive "p")
  (let ((col (min (max (current-column) crossword--first-column)
                       crossword--last-column))
        (n -1) found pos)
    (while (< (cl-incf n) arg)
      (if (and crossword-arrow-changes-direction
               (eq crossword--nav-dir 'across))
        (crossword-nav-dir-down)
       (setq pos (point))
       (while (and (not found)
                   (> (line-beginning-position) crossword--first-square))
         (forward-line -1)
         (move-to-column col)
         (setq found (get-text-property (point) 'answer)))
       (when (not found)
         (goto-char pos)
         (user-error "No previous line directly up")))
       (setq found nil))))


(defun crossword-next-line (&optional arg)
  "Move POINT to clue square below the current field.
Optionally, repeat ARG times."
  (interactive "p")
  (let ((col (min (max (current-column) crossword--first-column)
                       crossword--last-column))
        (n -1) found pos)
    (while (< (cl-incf n) arg)
      (if (and crossword-arrow-changes-direction
               (eq crossword--nav-dir 'across))
        (crossword-nav-dir-down)
       (setq pos (point))
       (while (and (not found)
                   (< (line-end-position) crossword--last-square))
         (forward-line 1)
         (move-to-column col)
         (setq found (get-text-property (point) 'answer)))
       (when (not found)
         (goto-char pos)
         (user-error "No previous line directly down")))
       (setq found nil))))


(defun crossword-begin-field ()
  "Move POINT to the first cell of the current field."
  (interactive)
  (if (> (point) crossword--last-square)
    (goto-char crossword--last-square)
   (when (< (point) crossword--first-square)
    (goto-char crossword--first-square)))
  (cond
   ((eq crossword--nav-dir 'across)
     (goto-char (nth 2 (assq
       (get-text-property (point) 'clue-across) crossword--across-clue-list))))
   ((eq crossword--nav-dir 'down)
     (goto-char (car (nth 2 (assq
       (get-text-property (point) 'clue-down) crossword--down-clue-list)))))))


(defun crossword-end-field ()
  "Move POINT to the final cell of the current field."
  (interactive)
  (if (> (point) crossword--last-square)
    (goto-char crossword--last-square)
   (when (< (point) crossword--first-square)
    (goto-char crossword--first-square)))
  (cond
   ((eq crossword--nav-dir 'across)
     (goto-char (1- (nth 3 (assq
       (get-text-property (point) 'clue-across) crossword--across-clue-list)))))
   ((eq crossword--nav-dir 'down)
     (goto-char (car (last (nth 2 (assq
       (get-text-property (point) 'clue-down) crossword--down-clue-list))))))))


(defun crossword-next-field (&optional arg)
  "Move POINT to the first cell of the next field.
Optionally, repeat ARG times."
  (interactive "p")
  (let ((repeat -1))
   (while (< (cl-incf repeat) arg)
    (cond
     ((eq crossword--nav-dir 'across)
       (if (or (< (point) crossword--first-square)
               (> (point) crossword--last-square))
          (goto-char crossword--first-square)
        (let* ((start (point)) we-have-wrapped done
               prev next this)
          (setq this
            (or (get-text-property (point) 'clue-across)
                (get-text-property
                  (setq prev (or (previous-single-property-change (point) 'clue-across)
                                 crossword--first-square)) ; should never happen
                  'clue-across)))
          (if (setq next(cadr (memq (assq this crossword--across-clue-list)
                                     crossword--across-clue-list)))
            (goto-char (nth 2 next))
           (when crossword-wrap-on-entry-or-nav
             (setq we-have-wrapped t)
             (goto-char crossword--first-square)))
          (when (and crossword-tab-to-next-unfilled
                     (/= crossword--solved-count crossword--total-count))
            (while (not done)
              (backward-char)
              (if (crossword--fwd-avail (nth 3 next))
                (setq done t)
               (backward-char)
               (setq next (cadr (memq (assq (get-text-property (point) 'clue-across)
                                            crossword--across-clue-list)
                                      crossword--across-clue-list)))
               (cond
                (next
                  (if (or (not crossword-wrap-on-entry-or-nav)
                          (not we-have-wrapped)
                          (< (nth 2 next) start))
                    (goto-char (nth 2 next))
                   (setq done t)
                   (goto-char start)))
                ((not crossword-wrap-on-entry-or-nav)
                  (setq done t)
                  (goto-char start))
                (t; ie. crossword-wrap-on-entry-or-nav and at end
                  (setq we-have-wrapped t)
                  (goto-char crossword--first-square)))))))))
     ((eq crossword--nav-dir 'down)
       (cond
        ((or (< (point) crossword--first-square)
             (> (point) crossword--last-square))
          (goto-char crossword--first-square))
        ((not (get-text-property (point) 'clue-down))
          (let ((crossword--nav-dir 'across))
            (while (and (crossword-next-char 1)
                        (not (crossword--pos-above-is-void (point)))))))
        (t ; ie. within grid, on a clue down square
          (let ((next (cadr (memq (assq (get-text-property (point) 'clue-down)
                                        crossword--down-clue-list)
                                  crossword--down-clue-list)))
                (start (point))
                done we-have-wrapped)
            (if next
              (goto-char (car (nth 2 next)))
             (when crossword-wrap-on-entry-or-nav
               (goto-char (car (nth 2 (car crossword--down-clue-list))))))
            (when (and crossword-tab-to-next-unfilled
                       (/= crossword--solved-count crossword--total-count))
              (while (not done)
                (if (crossword--is-empty-square)
                  (setq done t)
                 (crossword--next-square-in-clue)
                 (if (crossword--is-empty-square)
                   (setq done t)
                  (setq next (cadr (memq (assq (get-text-property (point) 'clue-down)
                                               crossword--down-clue-list)
                                         crossword--down-clue-list)))
                  (cond
                   (next
                     (if (or (not crossword-wrap-on-entry-or-nav)
                             (not we-have-wrapped)
                             (< (car (nth 2 next)) start))
                       (goto-char (car (nth 2 next)))
                      (setq done t)
                      (goto-char start)))
                   ((not crossword-wrap-on-entry-or-nav)
                     (setq done t)
                     (goto-char start))
                   (t; ie. crossword-wrap-on-entry-or-nav and at end
                     (setq we-have-wrapped t)
                     (goto-char crossword--first-square)))))))))))))))


(defun crossword-prior-field (&optional arg)
  "Move POINT to the first cell of the prior field.
Optionally, repeat ARG times."
  (interactive "p")
  (let ((repeat -1))
  (while (< (cl-incf repeat) arg)
    (cond
     ((eq crossword--nav-dir 'across)
       (let ((this (or (get-text-property (point) 'clue-across)
                       (get-text-property
                         (or (next-single-property-change (point) 'clue-across)
                             (point-max))
                         'clue-across)))
             (start-pos (point))
             start index elem done we-have-wrapped)
        (cond
         ((not this)
           (goto-char (nth 2 (setq elem (car (last crossword--across-clue-list)))))
           (setq start (setq index (1- (length crossword--across-clue-list)))))
         (t ; ie. this
           (setq start (setq index (cl-position (assq this crossword--across-clue-list)
                                                crossword--across-clue-list)))
           (unless (and (not crossword-wrap-on-entry-or-nav)
                        (= index 0))
             (goto-char
               (nth 2 (setq elem
                        (if (> index 0)
                          (nth (cl-decf index) crossword--across-clue-list)
                         (setq we-have-wrapped t)
                         (setq index (1- (length crossword--across-clue-list)))
                         (car (last crossword--across-clue-list)))))))))
        (when (and crossword-tab-to-next-unfilled
                   (/= crossword--solved-count crossword--total-count))
          ;; This is a bit weird because we are moving to the FIRST
          ;; character of the PRIOR field, then, advancing forward
          ;; toward the end of that field, then moving to the PRIOR
          ;; field.
          (while (not done)
             (backward-char)
             (cond
              ((crossword--fwd-avail (nth 3 elem))
                (setq done t))
              ((or (and we-have-wrapped
                        (= index start))
                   (and (not crossword-wrap-on-entry-or-nav)
                        (= index 0)))
                (goto-char start-pos)
                (setq done t))
              ((> index 0)
                (goto-char (nth 2 (setq elem
                                    (nth (cl-decf index)
                                         crossword--across-clue-list)))))
              (t ; ie. index=0 && crossword-wrap-on-entry-or-nav
                (setq we-have-wrapped t)
                (setq index (1- (length crossword--across-clue-list)))
                (goto-char (nth 2 (setq elem
                                    (car (last crossword--across-clue-list)))))))))))
     ((eq crossword--nav-dir 'down)
       (if (not (get-text-property (point) 'clue-down))
         (let ((crossword--nav-dir 'across))
           (while (and (crossword-prior-char 1)
                       (not (crossword--pos-above-is-void (point))))))
        (let* ((index (cl-position (assq (get-text-property (point) 'clue-down)
                                         crossword--down-clue-list)
                                   crossword--down-clue-list))
              (start index)
              (start-pos (point))
              done we-have-wrapped)
           (unless (and (not crossword-wrap-on-entry-or-nav)
                        (= index 0))
             (goto-char (car (nth 2 (if (> index 0)
                                      (nth (cl-decf index) crossword--down-clue-list)
                                     (setq index (1- (length crossword--down-clue-list)))
                                     (car (last crossword--down-clue-list)))))))
           (when (and crossword-tab-to-next-unfilled
                      (/= crossword--solved-count crossword--total-count))
             ;; This is a bit weird because we are moving to the FIRST
             ;; character of the PRIOR field, then, advancing forward
             ;; toward the end of that field, then moving to the PRIOR
             ;; field.
             (while (not done)
               (if (crossword--is-empty-square)
                 (setq done t)
                (crossword--next-square-in-clue)
                (cond
                 ((crossword--is-empty-square)
                   (setq done t))
                 ((or (and (not crossword-wrap-on-entry-or-nav)
                           (zerop index))
                      (and we-have-wrapped
                       (= index start)))
                   (goto-char start-pos)
                   (setq done t))
                 ((> index 0)
                   (goto-char (car (nth 2 (nth (cl-decf index) crossword--down-clue-list)))))
                 (t ; ie. crossword-wrap-on-entry-or-nav && at beginning
                   (goto-char (car (nth 2 (car (last crossword--down-clue-list)))))
                   (setq index (1- (length crossword--down-clue-list)))))))))))))))


(defun crossword-prior-char (&optional arg)
  "Advance one or ARG clue squares backward.
Use a prefix argument for navigating more than position."
  (interactive "p")
  (let ((n -1))
    (while (< (cl-incf n) arg)
      (cond
       ((and crossword-arrow-changes-direction
             (eq crossword--nav-dir 'down))
         (crossword-nav-dir-across))
       ((<= (point) crossword--first-square)
         (if crossword-wrap-on-entry-or-nav
           (goto-char crossword--last-square)
          (goto-char crossword--first-square)
          (setq n arg)))
       (t
         (let (found)
           (while (not found)
             (goto-char (previous-single-property-change
                          (point) 'answer nil crossword--first-square))
             (setq found (get-text-property (point) 'answer)))))))
    t))


(defun crossword-next-char (&optional arg)
  "Advance one or ARG clue squares forward.
Use a prefix argument for navigating more than position."
  (interactive "p")
  (let ((n -1))
    (while (< (cl-incf n) arg)
      (cond
       ((and crossword-arrow-changes-direction
             (eq crossword--nav-dir 'down))
         (crossword-nav-dir-across))
       ((>= (point) crossword--last-square)
         (if crossword-wrap-on-entry-or-nav
           (goto-char crossword--first-square)
          (goto-char crossword--last-square)
          (setq n arg)))
       (t
         (let (found)
           (while (not found)
             (goto-char (next-single-property-change
                          (1+ (point)) 'answer nil crossword--last-square))
             (setq found (get-text-property (point) 'answer)))))))
    t))


(defun crossword-del-char (&optional arg)
  "Delete the contents at POINT, and navigate forward.
If the square at POINT has been checked to be 'solved', it is not
altered. Optionally, repeat ARG times."
  (interactive "p")
  (dotimes (_n arg)
    (unless (get-text-property (point) 'solved)
      (setq last-input-event 32)
      (crossword--insert-char))
    (if (not crossword-auto-nav-only-within-clue)
      (crossword--next-logical-square)
     (let* ((pos (point))
            (prop (if (eq crossword--nav-dir 'across) 'clue-across 'clue-down))
            (clue (get-text-property (point) prop)))
       (crossword--next-logical-square)
       (unless (eq clue (get-text-property (point) prop))
         (goto-char pos))))))


(defun crossword-bsp-char (&optional arg)
  "Delete the contents at POINT, and navigate backward.
If the square at POINT has been checked to be 'solved', it is not
altered. Optionally, repeat ARG times."
  (interactive "p")
  (dotimes (_n arg)
    (unless (get-text-property (point) 'solved)
      (setq last-input-event 32)
      (crossword--insert-char))
    (if crossword-auto-nav-only-within-clue
      (crossword--prev-square-in-clue)
     (crossword--prev-logical-square))))


(defun crossword-goto-clue (clue)
  "Navigate to a specific CLUE square.
Supply the CLUE number as a prefix-ARG or be prompted."
  (interactive "nNavigate to clue number: ")
  (let (elem)
    (cond
     ((setq elem (assq clue crossword--across-clue-list))
       (goto-char (nth 2 elem)))
     ((setq elem  (assq clue crossword--down-clue-list))
       (goto-char (car (nth 2 elem))))
     (t (user-error "Invalid entry: %d" clue)))))


(defun crossword-first-square ()
  "Navigate to the first square of the puzzle."
  (interactive)
  (goto-char crossword--first-square))


(defun crossword-last-square ()
  "Navigate to the first square of the puzzle."
  (interactive)
  (goto-char crossword--last-square))


(defun crossword-clue-scroll-up (&optional lines)
  "Scroll up in the clue buffer in the current direction.
For use from the 'Crossword grid' buffer.
Optionally, repeat LINES times."
  (interactive "p")
  (let ((buf (current-buffer))
        (scroll-error-top-bottom t))
    (pop-to-buffer (if (eq crossword--nav-dir 'across)
                     crossword--across-buffer
                    crossword--down-buffer))
    (with-demoted-errors
      (scroll-down lines)) ; Yes, Emacs is inconsistent with this
    (pop-to-buffer buf)))


(defun crossword-clue-scroll-down (&optional lines)
  "Scroll down in the 'Crossword across' buffer.
For use from the 'Crossword grid' buffer. Per Emacs, 'scrolling
down' means proceeding up in the buffer.
Optionally, repeat LINES times."
  (interactive "p")
  (let ((buf (current-buffer)))
    (pop-to-buffer (if (eq crossword--nav-dir 'across)
                     crossword--across-buffer
                    crossword--down-buffer))
    (with-demoted-errors
      (scroll-up lines)) ; Yes, Emacs is inconsistent with this
    (pop-to-buffer buf)))


(defun crossword-clue-scroll-page-up ()
  "Scroll up in the 'Crossword across' buffer.
For use from the 'Crossword grid' buffer. Per Emacs, 'scrolling
up' means proceeding down in the buffer."
  (interactive)
  (let ((buf (current-buffer))
        (scroll-error-top-bottom t))
    (pop-to-buffer (if (eq crossword--nav-dir 'across)
                     crossword--across-buffer
                    crossword--down-buffer))
    (with-demoted-errors
      (scroll-up-command))
    (pop-to-buffer buf)))


(defun crossword-clue-scroll-page-down ()
  "Scroll down in the 'Crossword across' buffer.
For use from the 'Crossword grid' buffer. Per Emacs, 'scrolling
down' means proceeding up in the buffer."
  (interactive)
  (let ((buf (current-buffer))
        (scroll-error-top-bottom t))
    (pop-to-buffer (if (eq crossword--nav-dir 'across)
                     crossword--across-buffer
                    crossword--down-buffer))
    (with-demoted-errors
      (scroll-down-command))
    (pop-to-buffer buf)))


(defun crossword-clue-scroll-page-home ()
  "Scroll down in the 'Crossword across' buffer.
For use from the 'Crossword grid' buffer. Per Emacs, 'scrolling
down' means proceeding up in the buffer."
  (interactive)
  (let ((buf (current-buffer)))
    (pop-to-buffer (if (eq crossword--nav-dir 'across)
                     crossword--across-buffer
                    crossword--down-buffer))
    (goto-char (point-min))
    (pop-to-buffer buf)))


(defun crossword-clue-scroll-page-end ()
  "Scroll down in the 'Crossword across' buffer.
For use from the 'Crossword grid' buffer. Per Emacs, 'scrolling
down' means proceeding up in the buffer."
  (interactive)
  (let ((buf (current-buffer)))
    (pop-to-buffer (if (eq crossword--nav-dir 'across)
                     crossword--across-buffer
                    crossword--down-buffer))
    (goto-char (point-max))
    (pop-to-buffer buf)))


(defun crossword-backup ()
  "Save the current state of the current puzzle and pause timer.
Data reflecting your work on the current puzzle will be saved to
a file in the same directory as the `.puz' file, with the same
basename, and with an extension `.puz-emacs'."
  (interactive)
  (when crossword--timer-object
    (crossword-pause-unpause-timer))
  (let ((filename
          (concat crossword-save-path
                  (file-name-sans-extension
                    (file-name-nondirectory  crossword--filename))
                  ".puz-emacs"))
        (data-buf (buffer-string))
        (data-pos (point))
        (data-list (crossword--local-vars-list)))
    (with-temp-file filename
      (prin1 data-buf (current-buffer))
      (prin1 data-pos (current-buffer))
      (prin1 data-list (current-buffer)))
  (message "Puzzle backup saved: %s" filename)))


(defun crossword-restore (&optional file)
  "Restore a puzzle saved using function `crossword-backup'.
Prompts for FILE if not provided. This function expects that the
crossword frame/windows/buffers environment exists."
  (interactive)
  (unless file
    (setq file (read-file-name "Puzzle file to restore: "
                               crossword-save-path nil t nil
                               (lambda (x) (string-match "\\.puz-emacs$" x)))))
  (let* ((grid-buffer   (current-buffer))
         (across-buffer crossword--across-buffer)
         (down-buffer   crossword--down-buffer)
         (temp-buf (set-buffer (get-buffer-create "Crossword temporary")))
         (inhibit-read-only t)
         grid-pos
         across-clue-list down-clue-list)
   (insert-file-contents file)
   (pop-to-buffer grid-buffer)
   (erase-buffer)
   (insert (read temp-buf))
   (setq grid-pos (read temp-buf))
   (dolist (elem (read temp-buf))
     (set (car elem) (cdr elem)))
   (kill-buffer temp-buf)
   (setq across-clue-list crossword--across-clue-list
         down-clue-list   crossword--down-clue-list
         crossword--across-buffer across-buffer
         crossword--down-buffer   down-buffer)
   (crossword--insert-clues across-buffer
                            'clue-across
                            across-clue-list
                            "--- Across clues for crossword")
   (crossword--insert-clues down-buffer
                            'clue-down
                            down-clue-list
                            "--- Down clues for crossword")
   (pop-to-buffer grid-buffer)
   (goto-char grid-pos)
   (crossword--update-faces 'force)))


(defun crossword-check-letter ()
  "Check whether the letter at POINT is a correct solution.
If correct, it will highlighted per `crossword-solved-face'; If
not, per `crossword-error-face'. Wrong guesses are stored and
will be displayed at the bottom of the crossword grid window."
  (interactive)
  (let* ((inhibit-read-only t)
         (beg (point))
         (end (1+ beg))
         (letter (buffer-substring-no-properties beg end))
         (errors-list (get-text-property beg 'errors)))
   (when (and (string-match "[[:upper:]]" letter)
              (not (get-text-property beg 'solved))
              (not (member letter errors-list)))
     (crossword--incf-checked-count)
     (cond
      ((string= letter (get-text-property beg 'answer))
        (add-face-text-property beg end 'crossword-solved-face)
        (put-text-property beg end 'solved t)
        (crossword--incf-solved-count))
      (t
       (add-face-text-property beg end 'crossword-error-face)
       (put-text-property beg end 'errors
         (sort (nconc (list letter) errors-list) 'string<))
       (crossword--incf-completion-count -1)
       (crossword--incf-error-count))))
   ;; Maybe this next should be withinthe 'when' level?
   (crossword--update-grid-clues (get-text-property beg 'clue-across)
                                 (get-text-property beg 'clue-down))
   (goto-char beg))) ;; FIXME: This is probably no longer necessary.



(defun crossword-check-word ()
  "Check the word at POINT for errors.
Similar to `crossword-check-letter', See there for details."
  (interactive)
  (cond
   ((eq crossword--nav-dir 'across)
     (let* ((orig-pos (point))
            (clue-num (get-text-property (point) 'clue-across))
            (clue (assq clue-num crossword--across-clue-list))
            (pos (nth 2 clue))
            (end (nth 3 clue)))
       (while (< pos end)
         (goto-char pos)
         (crossword-check-letter)
         (setq pos (1+ pos)))
       (goto-char orig-pos)))
   ((eq crossword--nav-dir 'down)
     (let* ((orig-pos (point))
            (clue-num (get-text-property (point) 'clue-down))
            (clue (assq clue-num crossword--down-clue-list))
            pos
            (pos-list (nth 2 clue)))
       (while (setq pos (pop pos-list))
         (goto-char pos)
         (crossword-check-letter))
       (goto-char orig-pos))))
  (let ((inhibit-read-only t))
    (crossword--update-grid-clues
      (get-text-property (point) 'clue-across)
      (get-text-property (point) 'clue-down))))


(defun crossword-check-puzzle ()
  "Check the entire puzzle for errors.
Similar to `crossword-check-letter', See there for details."
  (interactive)
  (let ((orig-pos (point))
        (pos crossword--first-square)
        (end (1+ crossword--last-square)))
    (while (< pos end)
      (goto-char pos)
      (when (get-text-property pos 'answer)
        (crossword-check-letter))
      (setq pos (1+ pos)))
    (goto-char orig-pos)
    (let ((inhibit-read-only t))
      (crossword--update-grid-clues
        (get-text-property orig-pos 'clue-across)
        (get-text-property orig-pos 'clue-down)))))


(defun crossword-solve-letter ()
  "Solve the letter at POINT.
It will highlighted per `crossword-solved-face'."
  (interactive)
  (let* ((inhibit-read-only t)
         (beg (crossword--cheat-count--get-corrected-positions))
         (end (1+ beg))
         (answer (get-text-property beg 'answer))
         letter errors-list)
    (when (and answer
               (not (get-text-property beg 'solved)))
      (unless (string= answer
                       (setq letter (buffer-substring-no-properties beg end)))
        (crossword--incf-cheat-count)
        (when (not (member letter (setq errors-list (get-text-property beg 'errors))))
          (crossword--incf-error-count)
          (when (string-match "[[:upper:]]" letter)
            (put-text-property beg end 'errors
              (sort (nconc (list letter) errors-list) 'string<)))))
      (crossword--incf-checked-count)
      (crossword--incf-solved-count)
      (setq last-input-event (string-to-char answer))
      (put-text-property beg end 'face 'crossword-solved-face)
      (put-text-property beg end 'solved t)
      (crossword--insert-char))))


(defun crossword-solve-word ()
  "Solve the word at POINT.
Similar to `crossword-solve-letter', See there for details."
  (interactive)
  (cond
   ((eq crossword--nav-dir 'across)
     (let* ((orig-pos (crossword--cheat-count--get-corrected-positions))
            (clue-num (get-text-property (point) 'clue-across))
            (clue (assq clue-num crossword--across-clue-list))
            (pos (nth 2 clue))
            (end (nth 3 clue)))
       (while (< pos end)
         (goto-char pos)
         (crossword-solve-letter)
         (cl-incf pos 2))
       (goto-char orig-pos)))
   ((eq crossword--nav-dir 'down)
     (let* ((orig-pos (point))
            (clue-num (get-text-property (point) 'clue-down))
            (clue (assq clue-num crossword--down-clue-list))
            pos
            (pos-list (nth 2 clue)))
       (while (setq pos (pop pos-list))
         (goto-char pos)
         (crossword-solve-letter))
       (goto-char orig-pos)))))


(defun crossword-solve-puzzle ()
  "Solve the entire puzzle.
Similar to `crossword-solve-letter', See there for details."
  (interactive)
  (when crossword--timer-object
    (crossword-pause-unpause-timer))
  (let ((inhibit-read-only t)
        (orig-pos (crossword--cheat-count--get-corrected-positions))
        (pos crossword--first-square)
        (end (+ 2 crossword--last-square)))
    (goto-char pos)
    (while (re-search-forward crossword--grid-characters end t)
      (backward-char)
      (crossword-solve-letter)
      (forward-char))
    (goto-char orig-pos)
    (crossword--update-faces 'force)))


(defun crossword-summary-sort (&optional column)
  "Wrapper for `tabulated-list-sort'.
Without optional arg COLUMN, sort the column at POINT. Note that
COLUMN numbers start at zero."
  (interactive "P")
  (tabulated-list-sort column)
  (recenter))

(defun crossword-summary-revert-buffer ()
  "Refresh/update the Crossword summary buffer."
  (interactive)
  (crossword--summary-revert-hook-function))


(defun crossword-summary-rebuild-data ()
  "Builds database from files in `crossword-save-path'.
The prior database is deleted and is replaced with a new
`puz-emacs.data' file. Files with extensions `.puz' and
`.puz-emacs' are parsed, so played puzzles will appear twice,
once for their 0% completion state, and once in their current
state. Internally, each entry is a list of ten strings:
   1: filename
   2: date
   3: title
   4: author
   5: publisher/copyright
   6: %filled
   7: %solved
   8: num checked
   9: num errors
  10: num cheats
  11: timer elapsed time."
  (let ((orig-buf (current-buffer))
        result)
    (dolist (file (crossword--puzzle-file-list))
      (push (if (string-match "\\.puz$" file)
              (crossword--summary-data-puz file)
             (crossword--summary-data-puz-emacs file))
            result))
    (with-temp-file (crossword--summary-file)
      (prin1 result (current-buffer)))
    (set-buffer orig-buf)))


(defun crossword-summary-tab-backward (&optional n)
  "Navigated N column entries backward in tabulated listing.
Default is to advance one column."
  (interactive "p")
  (crossword-summary-tab-forward (- n)))


(defun crossword-summary-tab-forward (&optional n)
  "Navigate N column entries forward in tabulated listing.
Default is to advance one column."
  ;; ref: https://lists.gnu.org/archive/html/emacs-devel/2021-01/msg00901.html
  (interactive "p")
  (let* ((direction (if (< 0 n)
                      'next-single-property-change
                     (setq n (- n))
                     'previous-single-property-change))
         (pos (point))
         (rep -1))
    (while (< (cl-incf rep) n)
      (if (not pos)
        (setq rep n)
       (while (and (setq pos (funcall direction pos 'tabulated-list-column-name))
                   (not (get-text-property pos 'tabulated-list-entry))))))
    (goto-char (or pos (if (eq direction 'next-property-change)
                         (point-max)
                        (point-min))))))


(defun crossword-summary-delete()
  "Delete the puzzle file at POINT in a `crossword-summary' buffer.
If REGION is active, delete all puzzle files within it."
  (interactive)
  (unless (eq major-mode 'crossword-summary-mode)
    (user-error "Not in Crossword summary mode"))
  (let (puz-files msg pos end entry num (plural ""))
    (if (not (region-active-p))
      (setq puz-files
        (list (when (setq entry (tabulated-list-get-entry))
                (concat (aref entry 0) "." (aref entry 1)))))
     (setq pos (point)
           end (region-end))
     (goto-char (region-beginning))
     (while (and (<= (point) end)
                 (setq entry (tabulated-list-get-entry)))
       (push (concat (aref entry 0) "." (aref entry 1))
             puz-files)
       (forward-line 1))
     (goto-char pos))
    (unless (car puz-files)
      (user-error "Nothing selected to delete"))
    (when (< 1 (setq num (length puz-files)))
      (setq plural "s"))
    (setq num (if (or (not num) (= 1 num)) "" (format " %d" num)))
    (setq msg (format "Do you really want to delete the%s file%s %s? "
                      num plural puz-files))
    (when (yes-or-no-p msg)
      (while (setq entry (pop puz-files))
        (delete-file (concat crossword-save-path entry)))
      (crossword--summary-revert-hook-function))))


(defun crossword-summary-select()
  "Play the puzzle at POINT in a `crossword-summary' buffer."
  (interactive)
  (unless (eq major-mode 'crossword-summary-mode)
    (user-error "Not in Crossword summary mode"))
  (let* ((entry (tabulated-list-get-entry))
         (puz-file (if (not entry)
                     (user-error "No puzzle selected")
                    (concat crossword-save-path
                            (aref entry 0) "." (aref entry 1)))))
    (unless (file-readable-p puz-file)
      (error "File unreadable: %s" puz-file))
    (kill-buffer)
    (crossword--start-game puz-file)))


(defun crossword-recover-game-in-progress ()
  "Attempt to recover an 'deleted' game.
In this context, 'deleted' means that either the frame or its
clue buffer(s) was/were deleted."
  (interactive)
  (crossword--recover-game-in-progress))


(defun crossword-quit ()
  "Gracefully exit crossword play.
Prompt to save current state, then kill buffers, windows, and frame."
  (interactive)
  (when (and (called-interactively-p 'interactive)
             (condition-case nil
               (set-buffer "Crossword grid")
               (error nil))
             (pop-to-buffer "Crossword grid")
             crossword--filename
             (not (string= crossword--hash
                           (secure-hash 'md5 (buffer-substring-no-properties
                                               (point-min) crossword--grid-end))))
             (yes-or-no-p "Save current puzzle state before quitting? "))
    (crossword-backup)
    (let ((data (crossword--summary-add-current)))
      (with-temp-buffer
        (prin1 data)
        (write-region nil nil (crossword--summary-file) 'append))))
  (message "")
  (advice-remove #'self-insert-command #'crossword--advice-around-self-insert-command)
  (advice-remove #'call-interactively  #'crossword--advice-around-call-interactively)
  (let* ((file (file-name-sans-extension
                 (file-name-nondirectory
                   (or crossword--filename ""))))
         (the-list-buffer "Crossword list")
         (crossword-quit-to-browser
           (unless (equal the-list-buffer (buffer-name))
             crossword-quit-to-browser))
         (bufs (list "Crossword across"
                     "Crossword down"
                     "Crossword temporary"))
          buf)
    (unless crossword-quit-to-browser
      (push the-list-buffer bufs))
    (dolist (buf-str bufs)
      (when (setq buf (get-buffer buf-str))
        (kill-buffer buf)))
    (when (and (called-interactively-p 'interactive)
               (setq buf (get-buffer "Crossword grid")))
        (kill-buffer buf))
    (cond
     (crossword-quit-to-browser
       (crossword-summary)
       (let (entry puz-pos (next t))
         ;; (goto-char (point-min)) ; unnecessary
         (while next
           (setq entry (get-text-property (point) 'tabulated-list-entry))
           (when (string= file (elt entry 0))
             (when (string= "puz-emacs" (elt entry 1))
               (setq next nil))
             (setq puz-pos (point)))
           (goto-char
             (or (setq next
                   (next-single-property-change (point) 'tabulated-list-entry))
                 puz-pos
                 (point-min))))))
     (t ; ie. (not crossword-quit-to-browser)
       (condition-case nil
         (progn
           (select-frame-by-name "Crossword")
           (delete-frame nil))
         (error nil))
       (select-frame (previous-frame))))))



;;
;;; Autoloaded commands:


;;;###autoload
(defun crossword-summary ()
  "Display detailed meta-data of known puzzle files.
This includes progress for partially played puzzles. Data can be
sorted by any column, and individual entries can be deleted.
Puzzles can be played by pressing <RET> on their entry."
  (interactive)
  (unless (crossword--check-and-create-save-path)
    (crossword-quit))
  (crossword--select-frame)
;; FIXME: see TODO note at end of file
;;    (setq delete-frame-functions #'crossword-quit)))
  (crossword--recover-game-in-progress)
  (unless (get-buffer "Crossword list")
    (set-window-dedicated-p nil nil)
    (pop-to-buffer (set-buffer (get-buffer-create "Crossword list")))
    (set-window-dedicated-p nil t)
    (setq window-size-change-functions
      ;; FIXME: Maybe 'add-to-list' instead?
      (list #'crossword--window-resize-function))
    (setq buffer-read-only nil)
    (setq crossword--filename nil)
    (delete-other-windows)
    (crossword-summary-rebuild-data)
    (crossword-summary-mode)
    (tabulated-list-print))
    (recenter))


;;;###autoload
(defun crossword-download (&optional from date)
  "Download a crossword puzzle from the network.
Optional arg FROM is a download source, expected to be `equal' to
the CAR of an element of `crossword-download-puz-alist'. Optional
arg DATE is expected to be a list of integers '(mm dd yyy)."
  ;; TODO: Allow the arg 'from' to be url.
  (interactive)
  (unless (crossword--check-and-create-save-path)
    (user-error "No existing download path configured"))
  (let (entry url
        (save-dir (expand-file-name crossword-save-path)))
   (if from
     (unless (setq entry (assoc from crossword-download-puz-alist))
       (error "Unrecognized download resource: %s" from))
    (setq from (completing-read "Download from: "
      (mapcar (lambda (x) (car x)) crossword-download-puz-alist) nil t))
    (setq entry (assoc from crossword-download-puz-alist)))
   ;; NOTE: Earlier commits included here logic to check the day of the
   ;; week against a sub-list in the relevant entry of
   ;; `crossword-download-puz-alist' and reject mis-matches. The code
   ;; and the data structure element were removed because the
   ;; information was shown to be inaccurate and ever-changing. Now,
   ;; include a short note in an entry's description.
   (while (not date)
     (condition-case nil
       (setq date (crossword--calendar-read-date))
     (end-of-file (read-key "You must enter day of month.
Press any key to continue."))))
   (setq url (format-time-string (cadr entry) (apply 'encode-time 0 0 0 date)))
   (crossword--download url save-dir from)))


;;;###autoload
(defun crossword-load ()
  "Find (and play) a local crossword puzzle file.
You probably don't want to use this command unless you have a
file in a non-default directory (see `crossword-save-path') and
want to keep it in its current location. If you've used
`crossword-download' to get a puzzle, it should appear in the
puzzle browser when the download completes."
  (interactive)
  (crossword--recover-game-in-progress)
  (condition-case nil
    (select-frame-by-name "Crossword")
    (error
      (crossword--start-game))))


;;;###autoload
(defun crossword ()
  "Entry function for `crossword' mode.
Presents a menu offering to either download a crossword puzzle
from a configured network source, browse puzzles previously
dowloaded, or directly find a puzzle file.

From the puzzle browser one can load a puzzle to play by selecting
it. The browser presents all puzzles' metadata including
completion details of played puzzles."
  (interactive)
  (crossword--recover-game-in-progress)
  (unless (crossword--check-and-create-save-path)
    (user-error "No existing download path configured"))
  (let ((choices
          (list (when (crossword--puzzle-file-list)
                  (cons "Use the local crossword browser" #'crossword-summary))
                (cons "Download a crossword puzzle" #'crossword-download)
                (cons "Directly load a crossword from a local file" #'crossword-load))))
    (funcall (cdr (assoc-string
                    (completing-read "Welcome to Emacs crossword! "
                      (mapcar (lambda (x) (car x)) choices) nil t (caar choices))
                  choices)))))


;;
;;; TODO'S:

;; FIXME: In emacs28-snapshot -nw only: Error during redisplay:
;;        (crossword--window-resize-function #<frame Crossword 0x563c3e801e58>)
;;        signaled (wrong-type-argument stringp nil)
;;        NOTE: This doesn't seem to affect the operation of window
;;        resizing or the crossword autofill, and it isn't being caught
;;        by toggle-debug-on-error

;; TODO: Support common GUI events
;;       * frame-kill should crossword-quit: only if crossword-frame;
;;         remove the crossword-quit element (ie. itself) from the
;;         variable `delete-frame-functions'. See commented code above.

;; TODO: Experiment with refactoring the across-clues data structure
;;       to be identical with the down-clues data structure. Replace
;;       the START END elements with a list of positions. This may
;;       lead to the possibility of combining code.

;; TODO: Change the way date of the puzzle is determined. Possibly use
;;       the date portion of the filename itself.

;; TODO: `crossword-summary' should allow for annotated with an
;;       integer `difficulty-level' and a `notes' string, both of
;;       which will be stored in the `puz-emacs.data' file (maybe also
;;       the `puz-emacs' file?). BUT: How to preserve the data when
;;       rebuilding the database?

;; TODO: Don't require existence of clue buffers, and option not to display them.
;;       Currently the clue text presented at the bottom of the grid
;;       buffer is taken from these buffers.
;;         (defcustom crossword-display-clue-buffers t
;;           "Display dedicated buffers with complete clue lists.
;;         One buffer each for across and down clues."
;;           :type  'bool
;;           :group 'crossword)

;; TODO: Faces: It may be a bug how 'checked' is (not)used in favor of
;;       'solved'

;; TODO: Fix annoying flickering of display when navigating in emacs26.
;;       NOTE: Problem does not exist in emacs27 or emacs28snaphot.

;; TODO: Unicode decoding: The puzzles so far seem to all be what
;;       emacs calls either `prefer-utf-8-dos' for the purpose of
;;       function `decode-coding-region'. So far, the commit of
;;       2021-01-25 has been sufficient, as tested by the the
;;       available puz data (all files for the copyright symbol,
;;       jz180531 for ñ.

;; TODO: Support puzzles with 'circled' squares.
;;       Example: wsj210201.puz

;; TODO: Support "scrambled" .puz files.
;;       The format includes an option for basic encryption of the
;;       puzzle solution, based upon a four-digit key.
;;       Ref: http://www.muppetlabs.com/~breadbox/txt/acre.html
;;            http://www.muppetlabs.com/~breadbox/txt/scramble-c.txt

;; TODO: In function `crossword--start-game', at comment "** Sanity
;;       checks for 'puz' file format": Do we want to bother
;;       validating all the checksums in the file?
;;       REF: http://www.muppetlabs.com/~breadbox/txt/acre.html

;; TODO: Support ipuz and other formats? Who uses them? Where to
;;       download puzzles from? Where are the specs?
;;       http://fileformats.archiveteam.org/wiki/IPUZ

;; TODO: NOTE: This is an old todo from 2018-10 that I found in an old
;;       2018 version of `crossword-download.el', so I'm not sure it
;;       makes sense: Rename downloads to conform with format produced
;;       by `shortyz' so that users can easily understand what each
;;       file is, and so that users who sometimes download files from
;;       `shortyz' will not have needless duplicates.



;;
;;; Conclusion:

(provide 'crossword)

;;; crossword.el ends here
