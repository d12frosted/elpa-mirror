
 This package is for people who use Anki as SRS but would like to
 make cards in Org-mode.

 With this package, you can make cards from something like:
 (which is inspired by `org-dirll')

 * Item                     :emacs:lisp:programming:
   :PROPERTIES:
   :ANKI_DECK: Computing
   :ANKI_NOTE_TYPE: Basic
   :END:
 ** Front
    How to hello world in elisp ?
 ** Back
    #+BEGIN_SRC emacs-lisp
      (message "Hello, world!")
    #+END_SRC

 This package extends Org-mode's built-in HTML backend to generate
 HTML for contents of note fields with specific syntax (e.g. latex)
 translated to Anki style, then save the note to Anki.

 For this package to work, you have to setup these external dependencies:
 - curl
 - AnkiConnect, an Anki addon that runs an HTTP server to expose
                Anki functions as RESTful APIs, see
                https://github.com/FooSoft/anki-connect#installation
                for installation instructions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
