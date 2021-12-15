;;; debpaste.el --- Interface for getting/posting/deleting pastes from paste.debian.net

;; Copyright (C) 2013-2014 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 3 Dec 2013
;; Version: 0.1.5
;; Package-Version: 20160113.2347
;; Package-Commit: 6f2a400665062468ebd03a2ce1de2a73d9084958
;; Package-Requires: ((xml-rpc "1.6.7"))
;; URL: http://github.com/alezost/debpaste.el
;; Keywords: paste

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides an interface for receiving, posting and
;; deleting pastes from <http://paste.debian.net/>.

;; You can install the package from MELPA.  If you prefer the manual
;; installation, the easiest way is to put these lines into your
;; init-file:
;;   (add-to-list 'load-path "/path/to/debpaste-dir")
;;   (require 'debpaste)

;; Basic interactive commands:
;; - `debpaste-display-paste',
;; - `debpaste-paste-region',
;; - `debpaste-delete-paste'.

;; The package provides a keymap, that can be bound like this:
;;   (global-set-key (kbd "M-D") 'debpaste-command-map)

;; You will probably want to modify a default poster name:
;;   (setq debpaste-user-name user-login-name)

;; For full description, see <http://github.com/alezost/debpaste.el>.

;; For information about features provided by debian paste server,
;; read <http://paste.debian.net/rpc-interface.html>.

;;; Code:

(require 'cl-macs)
(require 'xml-rpc)
(require 'url-expand)

(defgroup debpaste nil
  "Emacs interface for debian paste server."
  :group 'xml-rpc
  :group 'url)


;;; URLs

(defcustom debpaste-base-url "http://paste.debian.net/"
  "Root URL of the paste server."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-server-url
  (url-expand-file-name "server.pl" debpaste-base-url)
  "URL of the XML-RPC paste server."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-paste-url-regexp
  (concat "^" (regexp-quote debpaste-base-url)
          "/?" ; `debpaste-base-url' may end with "/" or not
          "\\([0-9]+\\)")
  "Regexp matching URL of a non-hidden paste.
The first parenthesized expression should match ID of the paste."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-hidden-paste-url-regexp
  (concat "^" (regexp-quote debpaste-base-url)
          "/?hidden/\\([0-9a-f]+\\)")
  "Regexp matching URL of a hidden paste.
The first parenthesized expression should match ID of the paste."
  :type 'string
  :group 'debpaste)

(defun debpaste-get-id-by-url (url)
  "Return ID from a paste URL.
Return nil if URL doesn't match `debpaste-paste-url-regexp' or
`debpaste-hidden-paste-url-regexp'."
  (and (or (string-match debpaste-paste-url-regexp url)
           (string-match debpaste-hidden-paste-url-regexp url))
       (match-string 1 url)))


;;; Interaction with the paste server

(defun debpaste-send-command (cmd &rest opts)
  "Send command CMD with options OPTS to the paste server.
CMD is a symbol from `debpaste-commands'."
  (apply #'xml-rpc-method-call
         debpaste-server-url
         (debpaste-get-command-name cmd)
         opts))

(cl-defun debpaste-action (&key cmd opts filters)
  "Send command to the server and make some actions with output.

After sending command (method) CMD with option list OPTS, the
paste server returns some information which is transformed into
alist of parameters and values by `xml-rpc-method-call'.  This
alist (it is called \"info\" in this package) is passed as an
argument to the first function from the list FILTERS, the
returned result is passed to the second function from that list
and so on.

Each filter function should accept a single argument - info alist
and should return info alist.  Functions may add associations to
the alist.  In this case you might want to add descriptions of
the added symbols into `debpaste-param-description-alist'.

`debpaste-filter-intern' should be the first in the FILTERS list
as other functions from this package use symbols for working with
info parameters (see `debpaste-param-alist')."
  (let ((info (apply 'debpaste-send-command cmd opts)))
    (mapc (lambda (fun)
            (setq info (funcall fun info)))
          filters)))


;;; Server commands and returned parameters

(defvar debpaste-command-alist
  '((get-paste         . "paste.getPaste")
    (add-paste         . "paste.addPaste")
    (del-paste         . "paste.deletePaste")
    (get-langs         . "paste.getLanguages")
    (add-short-url     . "paste.addShortURL")
    (resolve-short-url . "paste.resolveShortURL")
    (short-url-clicks  . "paste.ShortURLClicks"))
  "Association list of symbols and names of server commands (methods).

Car of each assoc is a symbol used in code of this package;
cdr - is a command name (string) sent to the paste server.")

(defvar debpaste-param-alist
  '((ret          . "rc")
    (status       . "statusmessage")
    (text         . "code")
    (lang         . "lang")
    (submitter    . "submitter")
    (id           . "id")
    (base-url     . "base_url")
    (view-url     . "view_url")
    (download-url . "download_url")
    (delete-url   . "delete_url")
    (digest       . "digest")
    (hidden       . "hidden")
    (submit-date  . "submitdate")
    (expire-sec   . "expiredate"))
  "Association list of symbols and names of info parameters.

Car of each assoc is a symbol used in code of this package;
cdr - is a parameter name (string) returned by paste server.")

(defcustom debpaste-param-description-alist
  '((id           . "ID")
    (ret          . "Return code")
    (status       . "Server message")
    (lang         . "Language")
    (base-url     . "Base URL")
    (view-url     . "View URL")
    (download-url . "Download URL")
    (delete-url   . "Delete URL")
    (digest       . "Digest (SHA1 value for deleting a paste)")
    (hidden       . "Hidden")
    (submitter    . "Submitter")
    (submit-date  . "Submitting date")
    (expire-date  . "Expiration date")
    (expire-sec   . "Expiration time (seconds)"))
  "Association list of symbols and descriptions of parameters.

Descriptions are used for displaying paste information.

Symbols are either from `debpaste-param-alist' or are added
by filter functions.  See `debpaste-action' for details."
  :type '(alist :key-type symbol :value-type string)
  :group 'debpaste)

(defun debpaste-get-command-name (cmd)
  "Return a name (string) of a command CMD."
  (cdr (assoc cmd debpaste-command-alist)))

(defun debpaste-get-param-name (param-symbol)
  "Return a name of a parameter PARAM-SYMBOL."
  (cdr (assoc param-symbol debpaste-param-alist)))

(defun debpaste-get-param-symbol (param-name)
  "Return a symbol of a parameter PARAM-NAME."
  (car (rassoc param-name debpaste-param-alist)))

(defun debpaste-get-param-description (param-symbol)
  "Return a description of a parameter PARAM-SYMBOL."
  (cdr (assoc param-symbol debpaste-param-description-alist)))

(defun debpaste-get-param-val (param info)
  "Return a value of a parameter PARAM from paste INFO."
  (cdr (assoc param info)))


;;; General filters for processing info alist

(defcustom debpaste-date-format
  "%Y-%m-%d %T"
  "Time format used to represent submit and expire dates of a paste.
For information about time formats, see `format-time-string'."
  :type 'string
  :group 'debpaste)

(defun debpaste-filter-intern (info)
  "Return INFO with names of parameters replaced with symbols.
For names and symbols of parameters, see `debpaste-param-alist'."
  (delq nil
        (mapcar (lambda (param)
                  (let* ((param-name (car param))
                         (param-symbol (debpaste-get-param-symbol param-name))
                         (param-val (cdr param)))
                    (if param-symbol
                        (cons param-symbol param-val)
                      (message "Warning: paste server has returned unknown parameter %s.  It will be omitted."
                               param-name)
                      nil)))
                info)))

(defun debpaste-filter-error-check (info)
  "Check INFO for server errors.
Return INFO."
  (if (= 0 (debpaste-get-param-val 'ret info))
      info
    (error "Server error: %s" (debpaste-get-param-val 'status info))))

(defun debpaste-filter-hidden (info)
  "Substitute 0/1 with no/yes value for hidden parameter of INFO.
Return INFO."
  (let ((val (debpaste-get-param-val 'hidden info)))
    (when val
      (cond
       ((equal 0 val)
        (setcdr (assoc 'hidden info) "no"))
       ((equal 1 val)
        (setcdr (assoc 'hidden info) "yes")))))
  info)

(defun debpaste-filter-url (info)
  "Add \"http:\" string to url parameters from paste INFO.
Return modified info."
  (mapc (lambda (param)
          (let ((param-name (symbol-name (car param)))
                (param-val (cdr param)))
            (and (string-match "url$" param-name)
                 (setcdr param (concat "http:" param-val)))))
        info)
  info)

(defun debpaste-filter-date (info)
  "Format dates of paste INFO with `debpaste-date-format'.
Add `expire-date' symbol to the info alist.
Return modified info."
  (let ((submit-time (date-to-time
                      (debpaste-get-param-val 'submit-date info)))
        (expire-time (debpaste-get-param-val 'expire-sec info)))
    (setq expire-time
          (if (equal expire-time -1)
              "never"
            (format-time-string debpaste-date-format
                                (time-add submit-time
                                          (seconds-to-time expire-time)))))
    (setcdr (assoc 'submit-date info)
            (format-time-string debpaste-date-format submit-time))
    (add-to-list 'info (cons 'expire-date expire-time))))


;;; Languages and major-modes

;; you can help with this, if you know what server language can be
;; used for highlighting a particular major-mode or what major-mode
;; suits a language better
(defcustom debpaste-language-alist
  '(("Cucumber")
    ("abap")
    ("ada" . ada-mode)
    ("ahk")
    ("antlr")
    ("antlr-as")
    ("antlr-cpp" . c++-mode)
    ("antlr-csharp" . csharp-mode)
    ("antlr-java" . java-mode)
    ("antlr-objc" . objc-mode)
    ("antlr-perl" . perl-mode)
    ("antlr-python" . python-mode)
    ("antlr-ruby" . ruby-mode)
    ("apacheconf")
    ("applescript")
    ("as")
    ("as3")
    ("aspx-cs")
    ("aspx-vb")
    ("asy")
    ("awk" . awk-mode)
    ("basemake")
    ("bash" . sh-mode)
    ("bash" . shell-mode)
    ("bat")
    ("bbcode")
    ("befunge")
    ("blitzmax")
    ("boo")
    ("brainfuck")
    ("bro")
    ("c" . c-mode)
    ("c-objdump")
    ("cfengine3")
    ("cfm")
    ("cfs")
    ("cheetah")
    ("clojure" . clojure-mode)
    ("cmake" . cmake-mode)
    ("coffee-script")
    ("common-lisp" . lisp-mode)
    ("console")
    ("control")
    ("coq")
    ("cpp" . c++-mode)
    ("cpp-objdump" . c++-mode)
    ("csharp" . csharp-mode)
    ("css" . css-mode)
    ("css+django" . css-mode)
    ("css+erb" . css-mode)
    ("css+genshitext" . css-mode)
    ("css+mako" . css-mode)
    ("css+myghty" . css-mode)
    ("css+php" . css-mode)
    ("css+smarty" . css-mode)
    ("cython" . python-mode)
    ("d")
    ("d-objdump")
    ("dart")
    ("delphi" . delphi-mode)
    ("diff" . diff-mode)
    ("django" . python-mode)
    ("dpatch")
    ("dtd")
    ("duel")
    ("dylan")
    ("ec")
    ("ecl")
    ("elixir")
    ("erb")
    ("erl")
    ("erlang" . erlang-mode)
    ("evoque")
    ("factor")
    ("fan")
    ("fancy")
    ("felix")
    ("fortran" . fortran-mode)
    ("fsharp")
    ("gas")
    ("genshi")
    ("genshitext")
    ("glsl" . glsl-mode)
    ("gnuplot" . gnuplot-mode)
    ("go")
    ("gooddata-cl")
    ("gosu")
    ("groff" . nroff-mode)
    ("groovy")
    ("gst")
    ("haml")
    ("haskell" . haskell-mode)
    ("html" . html-mode)
    ("html+cheetah" . html-mode)
    ("html+django" . html-mode)
    ("html+evoque" . html-mode)
    ("html+genshi" . html-mode)
    ("html+mako" . html-mode)
    ("html+myghty" . html-mode)
    ("html+php" . html-mode)
    ("html+smarty" . html-mode)
    ("html+velocity" . html-mode)
    ("http")
    ("hx")
    ("hybris")
    ("iex")
    ("ini" . conf-mode)
    ("ini" . conf-colon-mode)
    ("ini" . conf-space-mode)
    ("ini" . conf-unix-mode)
    ("ini" . conf-windows-mode)
    ("ini" . conf-xdefaults-mode)
    ("io")
    ("ioke")
    ("irc")
    ("jade")
    ("java" . java-mode)
    ("js" . js-mode)
    ("js+cheetah" . js-mode)
    ("js+django" . js-mode)
    ("js+erb" . js-mode)
    ("js+genshitext" . js-mode)
    ("js+mako" . js-mode)
    ("js+myghty" . js-mode)
    ("js+php" . js-mode)
    ("js+smarty" . js-mode)
    ("json")
    ("jsp")
    ("kotlin")
    ("lhs")
    ("lighty")
    ("llvm")
    ("logtalk")
    ("lua" . lua-mode)
    ("make" . makefile-mode)
    ("make" . makefile-automake-mode)
    ("make" . makefile-bsdmake-mode)
    ("make" . makefile-gmake-mode)
    ("make" . makefile-imake-mode)
    ("make" . makefile-makepp-mode)
    ("mako")
    ("maql")
    ("mason")
    ("matlab" . matlab-mode)
    ("matlabsession")
    ("minid")
    ("modelica")
    ("modula2")
    ("moocode")
    ("moon")
    ("mupad")
    ("mxml" . nxml-mode)
    ("myghty")
    ("mysql" . sql-mode)
    ("nasm" . asm-mode)
    ("nemerle")
    ;; Debian paste service uses Pygments <http://pygments.org/> to
    ;; highlight languages for web-interface.  As Pygments doesn't
    ;; support elisp yet, i decided to pick some rarely used language
    ;; (newlisp) for associating it with emacs-lisp.  So when you post
    ;; a paste from emacs-lisp-mode, it is sent with "newlisp" as a
    ;; language parameter, and when this paste is received (with
    ;; `debpaste-display-paste') emacs-lisp-mode is enabled for it.
    ("newlisp" . emacs-lisp-mode)
    ("newlisp" . lisp-interaction-mode)
    ("newspeak")
    ("nginx")
    ("nimrod")
    ("numpy")
    ("objdump")
    ("objective-c" . objc-mode)
    ("objective-j")
    ("ocaml" . ocaml-mode)
    ("ocaml" . tuareg-mode)
    ("octave" . octave-mode)
    ("ooc")
    ("opa")
    ("openedge")
    ("perl" . perl-mode)
    ("php" . php-mode)
    ("plpgsql" . sql-mode)
    ("postgresql" . sql-mode)
    ("postscript")
    ("pot")
    ("pov")
    ("powershell")
    ("prolog" . prolog-mode)
    ("properties")
    ("protobuf")
    ("psql" . sql-mode)
    ("py3tb")
    ("pycon")
    ("pypylog")
    ("pytb")
    ("python" . inferior-python-mode)
    ("python" . jython-mode)
    ("python" . python-mode)
    ("python3" . python-mode)
    ("ragel")
    ("ragel-c")
    ("ragel-cpp" . c++-mode)
    ("ragel-d")
    ("ragel-em")
    ("ragel-java" . java-mode)
    ("ragel-objc" . objc-mode)
    ("ragel-ruby" . ruby-mode)
    ("raw")
    ("rb")
    ("rbcon")
    ("rconsole")
    ("rebol")
    ("redcode")
    ("rhtml" . html-mode)
    ("rst")
    ("sass")
    ("scala")
    ("scaml")
    ("scheme" . scheme-mode)
    ("scilab")
    ("scss")
    ("smalltalk")
    ("smarty")
    ("sml")
    ("snobol")
    ("sourceslist")
    ("splus")
    ("sql" . sql-mode)
    ("sqlite3" . sql-mode)
    ("squidconf")
    ("ssp")
    ("sv")
    ("tcl" . tcl-mode)
    ("tcsh")
    ("tea")
    ("tex" . tex-mode)
    ("text" . text-mode)
    ("trac-wiki")
    ("urbiscript")
    ("v")
    ("vala")
    ("vb.net")
    ("velocity")
    ("vhdl")
    ("vim")
    ("xml" . nxml-mode)
    ("xml+cheetah" . nxml-mode)
    ("xml+django" . nxml-mode)
    ("xml+erb" . nxml-mode)
    ("xml+evoque" . nxml-mode)
    ("xml+mako" . nxml-mode)
    ("xml+myghty" . nxml-mode)
    ("xml+php" . nxml-mode)
    ("xml+smarty" . nxml-mode)
    ("xml+velocity" . nxml-mode)
    ("xquery")
    ("xslt")
    ("yaml" . yaml-mode))
  "Association list of server languages and major modes."
  :type '(alist :key-type string :value-type symbol)
  :group 'debpaste)

(defcustom debpaste-paste-language "text"
  "Default language used for a posting paste.
It is used if there is no association for current major mode in
`debpaste-language-alist'."
  :type 'string
  :group 'debpaste)

(defun debpaste-get-lang-name (mode)
  "Return a name of the language for a major mode MODE.
If there is no association for the MODE in
`debpaste-language-alist', return `debpaste-paste-language'."
  (or (car (rassoc mode debpaste-language-alist))
      debpaste-paste-language))

(defun debpaste-get-lang-mode (name)
  "Return a major mode of the paste language NAME.
If there is no association for the NAME in
`debpaste-language-alist', return `fundamental-mode'"
  (or (cdr (assoc name debpaste-language-alist))
      'fundamental-mode))


;;; Debpaste buffers

(defcustom debpaste-buffer-name-regexp
  "^\\*debpaste .*\\*$"
  "Regexp matching debpaste buffers.
Used for killing and quitting debpaste buffers."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-received-paste-buffer-name-function
  'debpaste-received-paste-buffer-name-default
  "Function returning the name of a buffer with a received paste.
This function should accept one argument (info alist)."
  :type 'function
  :group 'debpaste)

(defcustom debpaste-received-info-buffer-name-function
  'debpaste-received-info-buffer-name-default
  "Function returning the name of a buffer with a received info.
This function should accept one argument (info alist)."
  :type 'function
  :group 'debpaste)

(defcustom debpaste-posted-info-buffer-name-function
  'debpaste-posted-info-buffer-name-default
  "Function returning the name of a buffer with a posted info.
This function should accept one argument (info alist)."
  :type 'function
  :group 'debpaste)

(defun debpaste-received-paste-buffer-name-default (info)
  "Return the default name of a buffer for displaying received paste.
INFO is alist of paste parameters."
  (format "*debpaste %s*"
          (debpaste-get-param-val 'id info)))

(defun debpaste-received-info-buffer-name-default (info)
  "Return the default name of a buffer for displaying received info.
INFO is alist of paste parameters."
  (format "*debpaste %s (received info)*"
          (debpaste-get-param-val 'id info)))

(defun debpaste-posted-info-buffer-name-default (info)
  "Return the default name of a buffer for displaying posted info.
INFO is alist of paste parameters."
  (format "*debpaste %s (posted info)*"
          (debpaste-get-param-val 'id info)))

;; wild name, isn't it?
(defun debpaste-debpaste-bufferp (buffer-or-name)
  "Return non-nil if BUFFER-OR-NAME is a debpaste buffer.
BUFFER-OR-NAME must be either a string (buffer name) or a buffer."
  (let ((name (if (bufferp buffer-or-name)
                  (buffer-name buffer-or-name)
                buffer-or-name)))
    (string-match debpaste-buffer-name-regexp name)))

(defun debpaste-kill-all-buffers ()
  "Kill all debpaste buffers.
Buffers are defined by `debpaste-buffer-name-regexp'."
  (interactive)
  (mapc (lambda (buf)
          (and (debpaste-debpaste-bufferp buf)
               (kill-buffer buf)))
        (buffer-list))
  (message "All debpaste buffers were killed."))

(defun debpaste-quit-buffers ()
  "Bury debpaste buffers.
Buffers are defined by `debpaste-buffer-name-regexp'."
  (interactive)
  (mapc (lambda (win)
          ;; `select-window' is essential, otherwise (bury-buffer buf)
          ;; will not bury buffer
          (select-window win)
          (let ((buf (window-buffer win)))
            (and (debpaste-debpaste-bufferp buf)
                 (bury-buffer))))
        (window-list)))


;;; Displaying info

(defcustom debpaste-info-buffer-format "%s: %s\n"
  "String used to format each parameter for info displayed in buffer.
It should contain 2 '%s'-sequences for a description and a value."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-info-minibuffer-format "%s: %s\n"
  "String used to format each parameter for info displayed in minibuffer.
It should contain 2 '%s'-sequences for a description and a value."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-ignore-empty-params t
  "If non-nil, do not display empty parameters of a paste info."
  :type 'boolean
  :group 'debpaste)

(defun debpaste-get-info-string (info fmt &optional params)
  "Return a string containing INFO.

FMT is a string to format descriptions and values of parameters.

PARAMS is a list of parameters included in a returned string.  If
it is not specified, show all info parameters (respecting
`debpaste-ignore-empty-params').

Parameters and their descriptions got from
`debpaste-param-description-alist'."
  (unless params
    (setq params (mapcar #'car info)))
  (mapconcat (lambda (param)
               (let ((desc (debpaste-get-param-description param))
                     (val (debpaste-get-param-val param info)))
                 (if (and debpaste-ignore-empty-params
                          (null val))
                     ""                 ; delete empty params
                   (format fmt desc (or val "")))))
             params
             ""))

(defun debpaste-display-info-in-buffer (buffer-or-name info &optional params)
  "Display INFO in a separate buffer BUFFER-OR-NAME.
Return INFO.

BUFFER-OR-NAME may be a buffer or a string (a buffer name).

Use `debpaste-info-buffer-format' to format displayed info.
See `debpaste-get-info-string' for description of FMT and PARAMS."
  (let ((info-str (debpaste-get-info-string
                   info debpaste-info-buffer-format params)))
    (unless (get-buffer buffer-or-name)
      (with-current-buffer (get-buffer-create buffer-or-name)
        (insert info-str)
        (text-mode) ;; i don't like this
        (view-mode) ;; and this (any suggestions?)
        (goto-char (point-min))))
    (let ((win (get-buffer-window buffer-or-name)))
      (if win
          (select-window win)
        (display-buffer buffer-or-name '((display-buffer-same-window))))))
  info)

(defun debpaste-display-info-in-minibuffer (info &optional params)
  "Display INFO in the minibuffer.
Return INFO.

Use `debpaste-info-minibuffer-format' to format displayed info.
See `debpaste-get-info-string' for description of FMT and PARAMS."
  (message (debpaste-get-info-string
            info debpaste-info-minibuffer-format params))
  info)


;;; Getting (receiving) a paste

(defcustom debpaste-received-filter-functions
  '(debpaste-filter-intern debpaste-filter-error-check
    debpaste-add-id-to-info debpaste-filter-url debpaste-filter-date
    debpaste-save-last-received-info debpaste-display-received-paste
    debpaste-display-received-info-in-minibuffer)
  "List of functions for filtering info returned after receiving a paste.
See `debpaste-action' for details."
  :type '(repeat function)
  :group 'debpaste)

(defcustom debpaste-received-info-buffer-params
  '(id status lang submitter submit-date expire-date)
  "List of info parameters of a received paste displayed in buffer.
If nil, display all parameters.
Parameters are symbols from `debpaste-param-description-alist'."
  :type '(repeat symbol)
  :group 'debpaste)

(defcustom debpaste-received-info-minibuffer-params
  '(submitter submit-date expire-date)
  "List of info parameters of a received paste displayed in minibuffer.
If nil, display all parameters.
Parameters are symbols from `debpaste-param-description-alist'."
  :type '(repeat symbol)
  :group 'debpaste)

(defcustom debpaste-confirm-id-at-point nil
  "If non-nil, prompt for ID even if there is a paste URL at point.
See `debpaste-display-paste'."
  :type 'boolean
  :group 'debpaste)

(defvar-local debpaste-info nil
  "Alist with additional info of the current paste.

Car of each assoc is a symbol from `debpaste-param-description-alist';
cdr - is a value of that parameter.")
(put 'debpaste-info 'permanent-local t) ; (info "(elisp) Creating Buffer-Local")

(defvar debpaste-paste-id nil
  "Temporary value of a paste ID.")

(defun debpaste-add-id-to-info (info)
  "Add id parameter to the INFO.
Return modified info."
  ;; id parameter is vital for info; as the server doesn't return it,
  ;; we add it here using `debpaste-paste-id'
  ;; (`debpaste-display-paste' should bother about this variable)
  (or (debpaste-get-param-val 'id info)
      (add-to-list 'info (cons 'id debpaste-paste-id)))
  info)

(defvar debpaste-last-received-info nil
  "Alist with info of the last received paste.")

(defun debpaste-save-last-received-info (info)
  "Set `debpaste-last-received-info' to INFO value.
Return INFO."
  (setq debpaste-last-received-info info))

(defun debpaste-get-received-info ()
  "Return info of a received paste.

If current buffer contains a received paste, return info of this
paste; otherwise return info of the last received paste."
  (or (and (local-variable-p 'debpaste-info)
           debpaste-info)
      debpaste-last-received-info
      (error "You have not received pastes in this session")))

(defun debpaste-display-received-info-in-buffer (info)
  "Display INFO of a received paste in a separate buffer.
Return INFO.
See `debpaste-get-received-info' for details.

Display parameters from `debpaste-received-info-buffer-params'
using `debpaste-info-buffer-format' to format info text.

Use `debpaste-received-info-buffer-name-function' for buffer name."
  (interactive (list (debpaste-get-received-info)))
  (debpaste-display-info-in-buffer
   (funcall debpaste-received-info-buffer-name-function
            info)
   info debpaste-received-info-buffer-params))

(defun debpaste-display-received-info-in-minibuffer (info)
  "Display INFO of a received paste in the minibuffer.
Return INFO.
See `debpaste-get-received-info' for details.

Display parameters from `debpaste-received-info-minibuffer-params'
using `debpaste-info-minibuffer-format' to format info text."
  (interactive (list (debpaste-get-received-info)))
  (debpaste-display-info-in-minibuffer
   info debpaste-received-info-minibuffer-params))

(defun debpaste-display-received-paste (info)
  "Display text parameter from INFO in a debpaste buffer.
Return INFO.
Store additional info (without paste text) in a buffer-local
`debpaste-info' variable."
  (let ((buf (get-buffer-create
              (funcall debpaste-received-paste-buffer-name-function
                       info)))
        (paste-text (debpaste-get-param-val 'text info))
        (paste-info (cl-delete-if (lambda (param) (equal (car param) 'text))
                                  info))
        (mode (debpaste-get-lang-mode
               (debpaste-get-param-val 'lang info))))
    (with-current-buffer buf
      (erase-buffer)
      (insert paste-text)
      (and (fboundp mode) (funcall mode))
      (goto-char (point-min))
      (setq debpaste-info paste-info))
    (let ((win (get-buffer-window buf)))
      (if win
          (select-window win)
        (display-buffer buf '((display-buffer-same-window))))))
  info)

;;;###autoload
(defun debpaste-display-paste (id)
  "Receive and display a paste with numeric or string ID.
Interactively, prompt for ID unless there is a paste URL at point
and `debpaste-confirm-id-at-point' is nil."
  (interactive
   (list (let* ((url (thing-at-point 'url))
                (id (and url (debpaste-get-id-by-url url))))
           (if (or (null id) debpaste-confirm-id-at-point)
               (read-string "Paste ID: " id)
             id))))
  (when (numberp id)
    (setq id (number-to-string id)))
  (let ((debpaste-paste-id id))
    (debpaste-action :cmd 'get-paste
                     :opts (list id)
                     :filters debpaste-received-filter-functions)))


;;; Adding (posting) a paste

(defcustom debpaste-posted-filter-functions
  '(debpaste-filter-intern debpaste-filter-error-check debpaste-filter-hidden
    debpaste-filter-url debpaste-save-last-posted-info
    debpaste-posted-kill-url-display-summary)
  "List of functions for filtering info returned after posting a paste.
See `debpaste-action' for details."
  :type '(repeat function)
  :group 'debpaste)

(defcustom debpaste-posted-info-buffer-params
  '(id digest hidden view-url download-url delete-url)
  "List of info parameters of a posted paste displayed in buffer.
If nil, display all parameters.
Parameters are symbols from `debpaste-param-description-alist'."
  :type '(repeat symbol)
  :group 'debpaste)

(defcustom debpaste-posted-info-minibuffer-params
  '(download-url delete-url)
  "List of info parameters of a posted paste displayed in minibuffer.
If nil, display all parameters.
Parameters are symbols from `debpaste-param-description-alist'."
  :type '(repeat symbol)
  :group 'debpaste)

(defcustom debpaste-completing-read-function
  'ido-completing-read
  "Function for reading a string in the minibuffer.
It is used to prompt for paste options.
Usual values are: `completing-read' or `ido-completing-read'."
  :type 'function
  :group 'debpaste)

(defcustom debpaste-user-name "anonymous"
  "Default user name used for a posting paste."
  :type 'string
  :group 'debpaste)

(defcustom debpaste-expire-time (* 24 3600)
  "Default expiration time (in seconds) for a posting paste."
  :type 'integer
  :group 'debpaste)

(defcustom debpaste-expire-time-alist
  `((3600           . "1 hour")
    (,(* 12 3600)   . "12 hours")
    (,(* 24 3600)   . "1 day")
    (,(* 3 24 3600) . "3 days")
    (,(* 7 24 3600) . "7 days")
    (-1             . "never"))
  "Association list of time values (in seconds) and strings for prompting."
  :type '(alist :key-type integer :value-type string)
  :group 'debpaste)

(defcustom debpaste-paste-is-hidden nil
  "If non-nil, post hidden pastes (not shown on a frontpage)."
  :type 'boolean
  :group 'debpaste)

(defcustom debpaste-prompted-paste-options nil
  "List of prompted options for a posting paste.

If list, prompt for values of options specified in this list and
use default values for other options.  Each option from the list
is one of these symbols: `user', `expire-sec', `lang', `hidden'.

If nil, use default values for all paste options without
prompting."
  :type '(repeat symbol)
  :group 'debpaste)

(defun debpaste-prompt-for-user-name ()
  "Prompt for and return user name for a posting paste."
  (funcall debpaste-completing-read-function
           "User name: " nil nil nil debpaste-user-name))

(defun debpaste-prompt-for-expire-time ()
  "Prompt for and return expiration time for a posting paste."
  (let ((time (funcall debpaste-completing-read-function
                       "Expiration time (seconds or completion value): "
                       (mapcar #'cdr debpaste-expire-time-alist))))
    (or (car (rassoc time debpaste-expire-time-alist))
        (string-to-number time))))

(defun debpaste-prompt-for-lang ()
  "Prompt for and return language for a posting paste."
  (funcall debpaste-completing-read-function
           "Language: "
           (mapcar #'car debpaste-language-alist)
           nil nil nil nil (debpaste-get-lang-name major-mode)))

(defun debpaste-prompt-for-hidden ()
  "Prompt for and return hidden option (t or nil) for a posting paste."
  (y-or-n-p "Hidden paste?"))

(defun debpaste-url-to-kill-ring (info)
  "Add view-url parameter from INFO to the `kill-ring'.
Return INFO."
  (kill-new (debpaste-get-param-val 'view-url info))
  info)

;;;###autoload
(defun debpaste-paste-region (start end)
  "Send a text between START and END to the paste server.
Interactively use current region.

Prompt for additional options specified in
`debpaste-prompted-paste-options'.
With \\[universal-argument] prompt for all paste options."
  (interactive "r")
  (let ((opt-list (if (equal current-prefix-arg '(4))
                      '(user expire-sec lang hidden)
                    debpaste-prompted-paste-options)))
    (cl-flet ((get-opt-val (opt default prompt-fun &rest args)
                           (if (member opt opt-list)
                               (apply prompt-fun args)
                             default)))
      (let ((text (buffer-substring-no-properties start end))
            (user (get-opt-val 'user debpaste-user-name
                               'debpaste-prompt-for-user-name))
            (expire (get-opt-val 'expire-sec debpaste-expire-time
                                 'debpaste-prompt-for-expire-time))
            (lang (get-opt-val 'lang (debpaste-get-lang-name major-mode)
                               'debpaste-prompt-for-lang))
            (hidden (if (get-opt-val 'hidden debpaste-paste-is-hidden
                                     'debpaste-prompt-for-hidden)
                        1
                      0)))
        (debpaste-action :cmd 'add-paste
                         :opts (list text user expire lang hidden)
                         :filters debpaste-posted-filter-functions)))))

;;;###autoload
(defun debpaste-paste-buffer (buffer-or-name)
  "Send a buffer BUFFER-OR-NAME to the paste server.
Interactively use current buffer."
  (interactive (list (current-buffer)))
  (with-current-buffer buffer-or-name
    (debpaste-paste-region (point-min) (point-max))))

(defvar debpaste-last-posted-info nil
  "Alist with info about last posted paste.")

(defun debpaste-save-last-posted-info (info)
  "Set `debpaste-last-posted-info' to INFO value.
Return INFO."
  (setq debpaste-last-posted-info info))

(defun debpaste-get-posted-info ()
  "Return info of a last posted paste."
  (or debpaste-last-posted-info
      (error "You have not posted pastes in this session")))

(defun debpaste-display-posted-info-in-buffer (info)
  "Display INFO of a posted paste in a separate buffer.
Return INFO.

Interactively, display info of the last posted paste.

Display parameters from `debpaste-posted-info-buffer-params'
using `debpaste-info-buffer-format' to format info text.

Use `debpaste-posted-info-buffer-name-function' for buffer name."
  (interactive (list (debpaste-get-posted-info)))
  (debpaste-display-info-in-buffer
   (funcall debpaste-posted-info-buffer-name-function
            info)
   info debpaste-posted-info-buffer-params))

(defun debpaste-display-posted-info-in-minibuffer (info)
  "Display INFO of a posted paste in the minibuffer.
Return INFO.

Interactively, display info of the last posted paste.

Display parameters from `debpaste-posted-info-minibuffer-params'
using `debpaste-info-minibuffer-format' to format info text."
  (interactive (list (debpaste-get-posted-info)))
  (message "Your paste has been posted successfully.\n%s"
           (debpaste-get-info-string
            info debpaste-info-minibuffer-format
            debpaste-posted-info-minibuffer-params))
  info)

(defun debpaste-posted-kill-url-display-summary (info)
  "Add paste URL to the `kill-ring' and display paste summary.
Return INFO.

Interactively, use info of the last posted paste.

See `debpaste-url-to-kill-ring'."
  (interactive (list (debpaste-get-posted-info)))
  (debpaste-url-to-kill-ring info)
  (message "Your paste has been posted successfully.
Paste URL has been added to the kill ring.\n%s"
           (debpaste-get-info-string
            info debpaste-info-minibuffer-format
            '(digest)))
  info)


;;; Deleting a paste

(defcustom debpaste-deleted-filter-functions
  '(debpaste-filter-intern debpaste-filter-error-check
    debpaste-display-deleted-info-in-minibuffer)
  "List of functions for filtering info returned after deleting a paste.
See `debpaste-action' for details."
  :type '(repeat function)
  :group 'debpaste)

(defun debpaste-display-deleted-info-in-minibuffer (info)
  "Display info about deleted paste.
Return INFO."
  (debpaste-display-info-in-minibuffer
   info '(status)))

;;;###autoload
(defun debpaste-delete-paste (digest)
  "Delete a paste with specified DIGEST from the paste server.

Interactively, prompt for DIGEST.  If there is SHA1 digest at
point, it will be used as initial input.

You receive DIGEST after posting a paste."
  (interactive
   (list (read-string "Paste digest: "
                      (debpaste-sha1-at-point))))
  (debpaste-action :cmd 'del-paste
                   :opts (list digest)
                   :filters debpaste-deleted-filter-functions))

(defun debpaste-sha1-at-point ()
  "Return the SHA1 digest at point, or nil if none is found.
SHA1 (Secure Hash Algorithm) digest is a word of 40 hexadecimal symbols."
  (let ((word (thing-at-point 'word)))
    (and word
         (string-match "^[0-9a-f]\\{40\\}$" word)
         word)))


;;; Keymap with commands

;;;###autoload
(defvar debpaste-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map "r" 'debpaste-display-paste) ; receive
    (define-key map "g" 'debpaste-display-paste) ; get
    (define-key map "p" 'debpaste-paste-region)  ; post
    (define-key map "a" 'debpaste-paste-region)  ; add
    (define-key map "P" 'debpaste-paste-buffer)
    (define-key map "A" 'debpaste-paste-buffer)
    (define-key map "d" 'debpaste-delete-paste)
    (define-key map "ir" 'debpaste-display-received-info-in-buffer)
    (define-key map "ig" 'debpaste-display-received-info-in-buffer)
    (define-key map "ip" 'debpaste-display-posted-info-in-buffer)
    (define-key map "ia" 'debpaste-display-posted-info-in-buffer)
    (define-key map "k" 'debpaste-kill-all-buffers)
    (define-key map "q" 'debpaste-quit-buffers)
    map)
  "Keymap for debpaste commands.")

;;;###autoload
(fset 'debpaste-command-map debpaste-command-map)

(provide 'debpaste)

;;; debpaste.el ends here
