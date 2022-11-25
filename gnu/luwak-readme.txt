	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    LUWAK: A SIMPLE EMACS WEB BROWSER BASED ON LYNX
				 -DUMP
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Overview
2. Install and use
3. Naming
4. TODOs
5. Contact and license





1 Overview
══════════

  luwak mode is a simple Emacs web browser based on `lynx -dump'.  It is
  currently text-only and GET-only.

  Features:

  • Asynchronous loading
  • Some usual browser features: open, reload, search with a search
    engine, follow links, go forward / backward in history, copy url of
    the current page or link at point
  • Completion from persistent history in prompt to open a url
  • Multiple ways of rendering links: numbered, forward-sexp or hide
    altogether
  • Quickly open a link on the page with completion for url / link id
  • imenu support, from all unindented strings (which look like
    headings)
  • Support of storing and capturing for org mode, guessing the title
    (first imenu item)
  • Write the dump of the current page to a file
  • Render a buffer containing a lynx dump in the luwak mode
  • Browse with or without torsocks


2 Install and use
═════════════════

  To use, clone this repo, add to `load-path' and `require'.  Make sure
  you have lynx installed in your system (`apt install lynx', `pacman -S
  lynx' etc.).  By default the browser does not torsocks, which can be
  disabled with a prefix arg or switching `luwak-tor-switch' to `nil'.

  ┌────
  │ (add-to-list 'load-path "~/.emacs.d/luwak")
  │ (require 'luwak)
  └────

  There are three entry points:

  • `luwak-open': open a url
  • `luwak-search': search a query using a customisable default search
    engine
  • `luwak-render-buffer': render a lynx dump file in luwak mode


3 Naming
════════

  lynx dump -> feline excretion -> Kopi Luwak


4 TODOs
═══════

  • Multiple search engines
  • Support for images
  • Support for POST


5 Contact and license
═════════════════════

  luwak is maintained by Yuchen Pei (id@ypei.org).  It is covered by
  [GNU AGPLv3+].  You may find the license text in a file named
  COPYING.agpl3 in the project tree.


[GNU AGPLv3+] <https://www.gnu.org/licenses/agpl-3.0.en.html>
