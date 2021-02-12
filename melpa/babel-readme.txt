; Overview ==========================================================

This module provides an Emacs interface to different translation
services available on the Internet. You give it a word or paragraph
to translate and select the source and destination languages, and
it connects to the translation server, retrieves the data, and
presents it in a special *babel* buffer. Currently the following
backends are available:

 * the FOSS MT platform Apertium
 * the Google service at translate.google.com
 * the Transparent Language motor at FreeTranslation.com


Entry points: either 'M-x babel', which prompts for a phrase, a
language pair and a backend, or 'M-x babel-region', which prompts
for a language pair and backend, then translates the currently
selected region, and 'M-x babel-buffer' to translate the current
buffer.


If you ask for a language combination which several backends could
translate, babel.el will allow you to choose which backend to
use. Since most servers have limits on the quantity of text
translated, babel.el will split long requests into translatable
chunks and submit them sequentially.

Please note that the washing process (which takes the raw HTML
returned by a translation server and attempts to extract the useful
information) is fragile, and can easily be broken by a change in
the server's output format. In that case, check whether a new
version is available (and if not, warn me; I don't translate into
Welsh very often).

Also note that by accessing an online translation service you are
bound by its Terms and Conditions; in particular
FreeTranslation.com is for "personal, non-commercial use only".


Installation ========================================================

Place this file in a directory in your load-path (to see a list of
appropriate directories, type 'C-h v load-path RET'). Optionally
byte-compile the file (for example using the 'B' key when the
cursor is on the filename in a dired buffer). Then add the
following lines to your ~/.emacs.el initialization file:

  (autoload 'babel "babel"
    "Use a web translation service to translate the message MSG." t)
  (autoload 'babel-region "babel"
    "Use a web translation service to translate the current region." t)
  (autoload 'babel-as-string "babel"
    "Use a web translation service to translate MSG, returning a string." t)
  (autoload 'babel-buffer "babel"
    "Use a web translation service to translate the current buffer." t)

babel.el requires emacs >= 23


Backend information =================================================

A babel backend named <zob> must provide three functions:

   (babel-<zob>-translation from to)

   where FROM and TO are three-letter language abbreviations from
   the alist `babel-languages'. This should return non-nil if the
   backend is capable of translating between these two languages.

   (babel-<zob>-fetch msg from to)

   where FROM and TO are as above, and MSG is the text to
   translate. Connect to the appropriate server and fetch the raw
   HTML corresponding to the request.

   (babel-<zob>-wash)

   When called on a buffer containing the raw HTML provided by the
   server, remove all the uninteresting text and HTML markup.

I would be glad to incorporate backends for new translation servers
which are accessible to the general public.

babel.el was inspired by a posting to the ding list by Steinar Bang
<sb@metis.no>. Morten Eriksen <mortene@sim.no> provided several
patches to improve InterTrans washing. Thanks to Per Abrahamsen and
Thomas Lofgren for pointing out a bug in the keymap code. Matt
Hodges <pczmph@unix.ccc.nottingham.ac.uk> suggested ignoring case
on completion. Colin Marquardt suggested
`babel-preferred-to-language'. David Masterson suggested adding a
menu item. Andy Stewart provided
`babel-remember-window-configuration' functionality, output window
adjustments and more improvements.

User quotes: Dieses ist die größte Sache seit geschnittenem Brot.
                -- Stainless Steel Rat <ratinox@peorth.gweep.net>

; History

   Discontinued Log (Use GIT: git://github.com/juergenhoetzel/babel.git)

   1.4 * `babel-region' now yank the translation instead insert him at
         point.

   1.3 n* Added new Google languages

   1.2 * Added FOSS MT platform Apertium
        (by Kevin Brubeck Unhammer)
  * Assume UTF-8, if HTTP header missing

   1.1 * Fixed invalid language code mapping for serveral
         languages

   1.0 * Fixed Google backend (new regex)
       * New custom variables `babel-buffer-name',
        `babel-echo-area', `babel-select-output-window'
       * Disable use of echo area usage on xemacs if lines > 1
         (resize of minibuffer does not work reliable)
       * `babel-url-retrieve' fix for xemacs from Uwe Brauer

   0.9  * Use `babel-buffer-name' for output buffer

   0.8  * Remember window config if `babel-remember-window-configuration'
          is non-nil.
        * made *babel* buffer read-only
        * use echo area (like `shell-command')
        * New functions `babel-as-string-default',`babel-region-default',
          `babel-buffer-default', `babel-smart' (provided by Andy)


   0.7  * error handling if no backend is available for translating
          the supplied languages
   * rely on url-* functions (for charset decoding) on GNU emacs
        * increased chunk size for better performance
        * added support for all Google languages
        * `babel-region' with prefix argument inserts the translation
           output at point.

   0.6  * get rid of w3-region (implementend basic html entity parsing)
        * get rid of w3-form-encode-xwfu (using mm-url-form-encode-xwfu)
        * no character classes in regex (for xemacs compatibility)
        * default backend: Google

   0.5: * Fixed Google and Babelfish backends

   0.4: * revised FreeTranslation backend

;   0.3: * removed non-working backends: systran, intertrans, leo, e-PROMPT
;        * added Google backend
;        * revised UTF-8 handling
;        * Added customizable variables: babel-preferred-to-language, babel-preferred-from-language
;        * revised history handling
;        * added helper function: babel-wash-regex


TODO:

* select multiple engines at once

* Adjust output window height. Current versions use
 `with-current-buffer' instead `with-output-to-temp-buffer'. So
 `temp-buffer-show-hook' will fail to adjust output window height
 -> Use (fit-window-to-buffer nil babel-max-window-height) to
 adjust output window height in new version.

* use non-blocking `url-retrieve'

* improve function `babel-simple-html-parse'.

* In `babel-quite' function, should be add (boundp
  'babel-previous-window-configuration) to make value of
  `babel-previous-window-configuration' is valid
