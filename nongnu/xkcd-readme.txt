			      ━━━━━━━━━━━━
			       EMACS-XKCD
			      ━━━━━━━━━━━━


Table of Contents
─────────────────

1. Installation
.. 1. Via package.el
.. 2. Via el-get
.. 3. Via Git
2. Screenshot:
3. Viewing comics:
4. Customization
5. Keybindings:
6. Stuff yet to be added:
.. 1. TODO View title in user-defined faces.
.. 2. TODO Handle links to xkcd in Emacs with xkcd-get.


[https://travis-ci.org/vibhavp/emacs-xkcd.png]

[file:http://melpa.org/packages/xkcd-badge.svg]

Implementation of an [xkcd] reader for GNU Emacs.


[https://travis-ci.org/vibhavp/emacs-xkcd.png]
<https://travis-ci.org/vibhavp/emacs-xkcd>

[file:http://melpa.org/packages/xkcd-badge.svg]
<http://melpa.org/#/xkcd>

[xkcd] <https://xkcd.com>


1 Installation
══════════════

1.1 Via package.el
──────────────────

  emacs-xkcd is available on [MELPA] and [Marmalade]. Just add any of
  these to your package archives, and install the package with `M-x
  package-install xkcd'.


[MELPA] <http://melpa.milkbox.net>

[Marmalade] <https://marmalade-repo.org/>


1.2 Via el-get
──────────────

  Emacs xkcd can also be installed using [el-get]. To do so, run `M-x
  el-get-install xkcd'


[el-get] <https://github.com/dimitri/el-get>


1.3 Via Git
───────────

  Clone this repo to a desired location, add the directory to your load
  path:
  ┌────
  │ (add-to-list 'load-path (expand-file-name "/path/to/emacs-xkcd"))
  │ (require 'xkcd)
  └────


2 Screenshot:
═════════════

  <file:./images/screenshot.png>


3 Viewing comics:
═════════════════

  ⁃ `xkcd-get' loads a user-specific xkcd.
  Files are cached (for later offline viewing) by default to
  `~/.emacs.d/xkcd/'.  This can be changed by changing `xkcd-cache-dir'
  in emacs-xkcd's customize menu.  (`customize-group xkcd')

  ⁃ `xkcd' loads the latest xkcd.


4 Customization
═══════════════

  emacs-xkcd can be customized with `M-x customize-group xkcd'.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Option               Use                                                   Default value            
  ─────────────────────────────────────────────────────────────────────────────────────────────────────
   `xkcd-cache-dir'     Directory where images and json files are cached      `~/.emacs.d/xkcd/'       
   `xkcd-cache-latest'  File where the latest cached xkcd's number is stored  `~/.emacs.d/xkcd/latest' 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


5 Keybindings:
══════════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Keybinding  Use                              Function        
  ──────────────────────────────────────────────────────────────
   `r'         Load a random xkcd               (xkcd-rand)     
   `t'         Show alt-text in the minibuffer  (xkcd-alt-text) 
   `<right>'   Load next xkcd                   (xkcd-next)     
   `<left>'    Loads previous xkcd              (xkcd-prev)     
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


6 Stuff yet to be added:
════════════════════════

6.1 TODO View title in user-defined faces.
──────────────────────────────────────────


6.2 TODO Handle links to xkcd in Emacs with xkcd-get.
─────────────────────────────────────────────────────
