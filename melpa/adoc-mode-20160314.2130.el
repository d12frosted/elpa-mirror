;;; adoc-mode.el --- a major-mode for editing AsciiDoc files in Emacs
;;
;; Copyright 2010-2013 Florian Kaufmann <sensorflo@gmail.com>
;;
;; Author: Florian Kaufmann <sensorflo@gmail.com>
;; URL: https://github.com/sensorflo/adoc-mode/wiki
;; Package-Version: 20160314.2130
;; Package-Commit: 745884359a1b8826ede2c4cfd2f0b5478953ac40
;; Created: 2009
;; Version: 0.6.6
;; Package-Requires: ((markup-faces "1.0.0"))
;; Keywords: wp AsciiDoc
;; 
;; This file is not part of GNU Emacs.
;; 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;
;; The syntax of the following commentary section is Markdown, so the same text
;; can be used for the wiki page on GitHub. Also, each paragraph, including list
;; items, are separated by blank lines, so it also looks good on Marmalade.
;;; Commentary:
;; 
;; # Introduction 
;; 
;; [AsciiDoc](http://www.methods.co.nz/asciidoc/) is a text document format for
;; writing short documents, articles, books and UNIX man pages. AsciiDoc files
;; can be translated to HTML and DocBook markups.
;; 
;; adoc-mode is an Emacs major mode for editing AsciiDoc files. It emphasizes on
;; the idea that the document is highlighted so it pretty much looks like the
;; final output. What must be bold is bold, what must be italic is italic etc.
;; Meta characters are naturally still visible, but in a faint way, so they can
;; be easily ignored.
;; 
;; 
;; # Download 
;; 
;; The raw file (adoc-mode.el) can be found
;; [here](https://raw.github.com/sensorflo/adoc-mode/master/adoc-mode.el).
;; Optionally you can get the sources from the [git
;; repository](https://github.com/sensorflo/adoc-mode).
;; 
;; You will also need to download the library
;; [markup-faces](https://github.com/sensorflo/markup-faces). If you install
;; adoc-mode via Emacs Lisp Packages, see below, markup-faces is installed
;; automatically if you don't have it yet.
;; 
;; 
;; # Installation 
;; 
;; Installation is as usual, so if you are proficient with Emacs you don't need
;; to read this.
;; 
;; ## Install the traditional way
;; 
;; 1. Copy the file adoc-mode.el to a directory in your load-path, e.g.
;;    \~/.emacs.d. To add a specific directory to the load path, add this to our
;;    initialization file (probably ~/.emacs): `(add-to-list 'load-path
;;    "mypath")`
;; 
;; 2. Add either of the two following lines to your initialization file. The
;;    first only loads adoc mode when necessary, the 2nd always during startup
;;    of Emacs.
;; 
;;    * `(autoload 'adoc-mode "adoc-mode" nil t)`
;; 
;;    * `(require 'adoc-mode)`
;; 
;; 3. Optionally byte compile adoc-mode.el for faster startup: `M-x
;;    byte-compile`
;; 
;; 4. To use adoc mode, call adoc-mode after you opened an AsciiDoc file: `M-x
;;    adoc-mode`
;; 
;; 
;; ## Install via Emacs Lisp Packages (on Marmalade)
;; 
;; For this way you either need packages.el from
;; [here](https://github.com/technomancy/package.el) and or Emacs 24, where the
;; packages library is already included. adoc-mode is on the
;; [Marmalade](http://marmalade-repo.org/) package archive.
;; 
;; * Type `M-x package-install RET adoc-mode RET`.
;; 
;; 
;; ## Possible steps after installation
;; 
;; Each of the following is optional
;; 
;; * According to AsciiDoc manual, .txt is the standard file extension of
;;   AsciiDoc files. Add the following to your initialization file to open all
;;   .txt files with adoc-mode as major mode automatically: `(add-to-list
;;   'auto-mode-alist (cons "\\.txt\\'" 'adoc-mode))`
;; 
;; * If your default face is a fixed pitch (monospace) face, but in AsciiDoc
;;   files you liked to have normal text with a variable pitch face,
;;   buffer-face-mode is for you: `(add-hook 'adoc-mode-hook (lambda()
;;   (buffer-face-mode t)))`
;; 
;; 
;; # Features
;; 
;; - sophisticated highlighting
;; 
;; - promote / demote title
;; 
;; - toggle title type between one line title and two line title
;; 
;; - adjust underline length of a two line title to match title text's length
;; 
;; - goto anchor defining a given id, default reading from xref at point
;; 
;; - support for outline (however only with the one-line title style)
;; 
;; 
;; ## Coming features
;; 
;; The next features I plan to implement
;; 
;; - Demote / promote for list items
;; - Outline support also for two line titles
;; - Correctly highlighting backslash escapes
;; 
;; 
;; # Screenshot
;; 
;; The highlighting emphasizes on how the output will look like. _All_
;; characters are visible, however meta characters are displayed in a faint way.
;; 
;; ![screenshot](http://dl.dropbox.com/u/75789984/adoc-mode.png)
;;
;;
;;; Todo:
;; - Fontlock
;;   - make font-lock regexps based upon AsciiDoc configuration file, or make
;;     them configurable in a way similar to that configuration file
;;   - respect font-lock-maximum-decoration
;;   - delimited blocks are supported, but not well at all
;;   - Most regexps for highlighting can spawn at most over two lines.
;;   - font-lock's multi line capabilities are not used well enough. At least 2
;;     line spawns should be covered - replace all .*? by .*?\\(?:\n.*?\\)??
;;   - backslash escapes are seldom highlighted correctly
;; - Other common Emacs functionality/features
;;   - demote/promote/create/delete titles/list-items. Also put emphasis on a
;;     convenient simple user interface.
;;   - hideshow
;;   - outline mode shall support two line titles
;;   - tags tables for anchors, indixes, bibliography items, titles, ...
;;   - spell check shall ignore meta characters
;;   - supply a regexp for magic-mode-alist
;;   - Is there something that would remove hard newlines within a paragraph,
;;     but just for display, so the paragraph uses the whole buffer length.
;;   - are there generic base packages to handle lists / tables?
;;   - a read only view mode where commands for navigation are on short key
;;     bindings like alphanum letters
;;   - study what other markup modes like rst offer
;; - AsciiDoc related features
;;   - Two (or gradually fading) display modes: one emphasises to see the
;;     AsciiDoc source text, the other emphasises to see how the output will
;;     look like. Or even hide meta characters all together

;;; Variables:

(require 'markup-faces) ; https://github.com/sensorflo/markup-faces
(require 'cl) ; I know, I should remove it, I will, eventually
;; tempo or tempo-snippet is required later below


(defconst adoc-mode-version "0.6.6"
  "adoc mode version number.

Based upon AsciiDoc version 8.5.2. I.e. regexeps and rules are
taken from that version's asciidoc.conf / manual.")


;;;; customization  
(defgroup adoc nil
  "Major-mode for editing AsciiDoc files in Emacs.

Most faces adoc-mode uses belong to the markup-faces
customization group, see link below, and have to be customized
there.  adoc-mode has only a few faces of its own, which can be
customized on this page."
  :group 'wp
  :link '(custom-group-link markup-faces))

(defcustom adoc-script-raise '(-0.3 0.3)
  "How much to lower and raise subscript and superscript content.

This is a list of two floats. The first is negative and specifies
how much subscript is lowered, the second is positive and
specifies how much superscript is raised. Heights are measured
relative to that of the normal text. The faces used are
markup-superscript-face and markup-subscript-face respectively.

You need to call `adoc-calc' after a change."
  :type '(list (float :tag "Subscript")
               (float :tag "Superscript"))
  :group 'adoc)

;; Interacts very badly with minor-modes using overlays because
;; adoc-unfontify-region-function removes ALL overlays, not only those which
;; where insered by adoc-mode.
(defcustom adoc-insert-replacement nil
  "When non-nil the character/string a replacment/entity stands for is displayed.

E.g. after '&amp;' an '&' is displayed, after '(C)' the copy right
sign is displayed. It's only about display, neither the file nor
the buffer content is affected.

You need to call `adoc-calc' after you change
`adoc-insert-replacement'. For named character entities (e.g.
'&amp;', in contrast to '&#20;' or '(C)' ) to be displayed you
need to set `adoc-unichar-name-resolver'.

Setting it to non-nil interacts very badly with minor-modes using
overlays."
  :type 'boolean
  :group 'adoc)

(defcustom adoc-unichar-name-resolver nil
  "Function taking a unicode char name and returing it's codepoint.

E.g. when given \"amp\" (as in the character entity reference
\"&amp;\"), it shall return 38 (#x26). Is used to insert the
character a character entity reference is refering to after the
entity. When adoc-unichar-name-resolver is nil, or when its
function returns nil, nothing is done with named character
entities. Note that if `adoc-insert-replacement' is nil,
adoc-unichar-name-resolver is not used.

You can set it to `adoc-unichar-by-name'; however it requires
unichars.el (http://nwalsh.com/emacs/xmlchars/unichars.el). When
you set adoc-unichar-name-resolver to adoc-unichar-by-name, you
need to call `adoc-calc' for the change to take effect."
  :type '(choice (const nil)
                 (const adoc-unichar-by-name)
                 function)
  :group 'adoc)

(defcustom adoc-two-line-title-del '("==" "--" "~~" "^^" "++")
  "Delimiter used for the underline of two line titles.
Each string must be exactly 2 characters long. Corresponds to the
underlines element in the titles section of the asciidoc
configuration file."
  :type '(list
          (string :tag "level 0") 
          (string :tag "level 1") 
          (string :tag "level 2") 
          (string :tag "level 3") 
          (string :tag "level 4") )
  :group 'adoc)

(defcustom adoc-delimited-block-del
  '("^/\\{4,\\}"	 ; 0 comment
    "^\\+\\{4,\\}"	 ; 1 pass
    "^-\\{4,\\}"	 ; 2 listing
    "^\\.\\{4,\\}"	 ; 3 literal
    "^_\\{4,\\}"	 ; 4 quote
    "^=\\{4,\\}"	 ; 5 example
    "^\\*\\{4,\\}"	 ; 6 sidebar
    "^--")        	 ; 7 open block
  "Regexp used for delimited blocks.

WARNING: They should not contain a $. It is implied that they
match up to end of the line;

They correspond to delimiter variable blockdef-xxx sections in
the AsciiDoc configuration file.

However contrary to the AsciiDoc configuration file a separate
regexp can be given for the start line and for the end line. You
may want to do that because adoc-mode often can't properly
distinguish between a) a two line tile b) start of a delimited
block and c) end of a delimited block. If you start a listing
delimited block with '>----' and end it with '<----', then all
three cases can easily be distinguished. The regexp in your
AsciiDoc config file would the probably be '^[<>]-{4,}$'"
  :type '(list
	  (choice :tag "comment"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	  (choice :tag "pass"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	  (choice :tag "listing"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	  (choice :tag "literal"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	  (choice :tag "quote"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	  (choice :tag "example"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	  (choice :tag "sidebar"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))
	   (choice :tag "open"
		  (regexp :tag "start/end regexp")
		  (list :tag "separate regexp"
			(regexp :tag "start regexp")
			(regexp :tag "end regexp")))))

;; todo: limit value range to 1 or 2
(defcustom adoc-default-title-type 1
  "Default title type, see `adoc-title-descriptor'."
  :group 'adoc)

;; todo: limit value range to 1 or 2
(defcustom adoc-default-title-sub-type 1
  "Default title sub type, see `adoc-title-descriptor'."
  :group 'adoc  )

(defcustom adoc-enable-two-line-title t
  "Wether or not two line titles shall be fontified.

nil means never fontify. t means always fontify. A number means
only fontify if the line below has NOT the lenght of the given
number. You could use a number for example when all your
delimited block lines have a certain length.

This is usefull because adoc-mode has troubles to properly
distinguish between two line titles and a line of text before a
delimited block. Note however that adoc-mode knows the AsciiDoc
rule that the length of a two line title underline can differ at
most 3 chars from the length of the title text."
  :type '(choice (const nil)
		 (const t)
		 number)
  :group 'adoc)

(defcustom adoc-title-style 'adoc-title-style-one-line
  "Title style used for title tempo templates.

See for example `tempo-template-adoc-title-1'."
  :type '(choice (const :tag "== one line" adoc-title-style-one-line)
		 (const :tag "== one line enclosed ==" adoc-title-style-one-line-enclosed)
                 (const :tag "two line\\n--------" adoc-title-style-two-line))
  :group 'adoc)

(defcustom adoc-tempo-frwk 'tempo-vanilla
  "Tempo framework to be used by adoc's templates. "
  :type '(choice (const :tag "tempo" tempo-vanilla)
		 (const :tag "tempo-snippets" tempo-snippets))
  :group 'adoc)


;;;; faces / font lock  
(define-obsolete-face-alias 'adoc-orig-default 'adoc-align "23.3")
(defface adoc-align
  '((t (:inherit (markup-meta-face))))
  "Face used so the text looks left aligned.

Is applied to whitespaces at the beginning of a line. You want to
set it to a fixed width face. This is useful if your default face
is a variable with face. Because for e.g. in a variable with
face, '- ' and ' ' (two spaces) don't have equal with, with
`adoc-align' in the following example the item's text looks
aligned.

- lorem ipsum
  dolor ..."
  :group 'adoc)

(define-obsolete-face-alias 'adoc-generic 'markup-gen-face "23.3")
(define-obsolete-face-alias 'adoc-monospace 'markup-typewriter-face "23.3")
(define-obsolete-face-alias 'adoc-strong 'markup-strong-face "23.3")
(define-obsolete-face-alias 'adoc-emphasis 'markup-emphasis-face "23.3")
(define-obsolete-face-alias 'adoc-superscript 'markup-superscript-face "23.3")
(define-obsolete-face-alias 'adoc-subscript 'markup-subscript-face "23.3")
(define-obsolete-face-alias 'adoc-secondary-text 'markup-secondary-text-face "23.3")
(define-obsolete-face-alias 'adoc-replacement 'markup-replacement-face "23.3")
(define-obsolete-face-alias 'adoc-complex-replacement 'markup-complex-replacement-face "23.3")
(define-obsolete-face-alias 'adoc-list-item 'markup-list-face "23.3")
(define-obsolete-face-alias 'adoc-table-del 'markup-table-face "23.3")
(define-obsolete-face-alias 'adoc-reference 'markup-reference-face "23.3")
(define-obsolete-face-alias 'adoc-delimiter 'markup-meta-face "23.3")
(define-obsolete-face-alias 'adoc-hide-delimiter 'markup-hide-delimiter-face "23.3")
(define-obsolete-face-alias 'adoc-anchor 'markup-anchor-face "23.3")
(define-obsolete-face-alias 'adoc-comment 'markup-comment-face "23.3")
(define-obsolete-face-alias 'adoc-warning 'markup-error-face "23.3")
(define-obsolete-face-alias 'adoc-preprocessor 'markup-preprocessor-face "23.3")

;; Despite the comment in font-lock.el near 'defvar font-lock-comment-face', it
;; seems I still need variables to refer to faces in adoc-font-lock-keywords.
;; Not having variables and only referring to face names in
;; adoc-font-lock-keywords does not work.
(defvar adoc-align 'adoc-align)
(defvar adoc-generic 'markup-gen-face)
(defvar adoc-monospace 'markup-typewriter-face)
(defvar adoc-replacement 'markup-replacement-face)
(defvar adoc-complex-replacement 'markup-complex-replacement-face)
(defvar adoc-table-del 'markup-table-face)
(defvar adoc-reference 'markup-reference-face)
(defvar adoc-secondary-text 'markup-secondary-text-face)
(defvar adoc-delimiter 'markup-meta-face)
(defvar adoc-hide-delimiter 'markup-meta-hide-face)
(defvar adoc-anchor 'markup-anchor-face)
(defvar adoc-comment 'markup-comment-face)
(defvar adoc-warning 'markup-error-face)
(defvar adoc-preprocessor 'markup-preprocessor-face)


;;;; misc 
(defconst adoc-title-max-level 4
  "Max title level, counting starts at 0.")

(defconst adoc-uolist-max-level 5
  "Max unordered (bulleted) list item nesting level, counting starts at 0.")

;; I think it's actually not worth the fuzz to try to sumarize regexps until
;; profiling profes otherwise. Nevertheless I can't stop doing it.
(defconst adoc-summarize-re-uolisti t
  "When non-nil, sumarize regexps for unordered list items into one regexp.
To become a customizable variable when regexps for list items become customizable.")

(defconst adoc-summarize-re-olisti t
  "As `adoc-summarize-re-uolisti', but for ordered list items.")

(defconst adoc-summarize-re-llisti t
  "As `adoc-summarize-re-uolisti', but for labeled list items.")

(defvar adoc-unichar-alist nil
  "An alist, key=unicode character name as string, value=codepoint.")

;; altough currently always the same face is used, I prefer an alist over a
;; list. It is faster to find out wheter any attribute id is in the alist or
;; not. And maybe markup-faces splits up markup-secondary-text-face into more
;; specific faces.
(defvar adoc-attribute-face-alist
  '(("id" . markup-anchor-face)
    ("caption" . markup-secondary-text-face)
    ("xreflabel" . markup-secondary-text-face)
    ("alt" . markup-secondary-text-face)
    ("title" . markup-secondary-text-face)
    ("attribution" . markup-secondary-text-face)
    ("citetitle" . markup-secondary-text-face)
    ("text" . markup-secondary-text-face))
  "An alist, key=attribute id, value=face.")

(defvar adoc-mode-abbrev-table nil
  "Abbrev table in use in adoc-mode buffers.")

(defvar adoc-font-lock-keywords nil
  "Font lock keywords in adoc-mode buffers.")

(defvar adoc-replacement-failed nil )

(define-abbrev-table 'adoc-mode-abbrev-table ())

(defvar adoc-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-d" 'adoc-demote)
    (define-key map "\C-c\C-p" 'adoc-promote)
    (define-key map "\C-c\C-t" 'adoc-toggle-title-type)
    (define-key map "\C-c\C-g" 'adoc-goto-ref-label)
    map)
  "Keymap used in adoc mode.")


;;;; help text copied from asciidoc manual
(defconst adoc-help-constrained-quotes
  "Constrained quotes must be bounded by white space or commonly
  adjoining punctuation characters. These are the most commonly
  used type of quote.")
(defconst adoc-help-emphasis
  "Usually rendered italic")
(defconst adoc-help-strong
  "Usually rendered bold")
(defconst adoc-help-monospace
  "Aka typewritter. This does _not_ mean verbatim / literal")
(defconst adoc-help-single-quote
  "Single quotation marks around enclosed text.")
(defconst adoc-help-double-quote
  "Quotation marks around enclosed text.")
(defconst adoc-help-attributed
  "A mechanism to allow inline attributes to be applied to
  otherwise unformatted text.")
(defconst adoc-help-unconstrained-quotes
  "Unconstrained quotes have no boundary constraints and can be
  placed anywhere within inline text.")
(defconst adoc-help-line-break
  "A plus character preceded by at least one space character at
  the end of a non-blank line forces a line break. It generates a
  line break (`br`) tag for HTML outputs and a custom XML
  `asciidoc-br` processing instruction for DocBook outputs")
(defconst adoc-help-page-break
  "A line of three or more less-than (`<<<`) characters will
  generate a hard page break in DocBook and printed HTML
  outputs.")
(defconst adoc-help-ruler-line
  "A line of three or more apostrophe characters will generate a
  ruler line. It generates a ruler (`hr`) tag for HTML outputs
  and a custom XML `asciidoc-hr` processing instruction for
  DocBook outputs.")
(defconst adoc-help-entity-reference
  "You can also include arbitrary character entity references in
  the AsciiDoc source. Example both `&amp;` and `&#38;` are
  replace by an & (ampersand).")
(defconst adoc-help-literal-paragraph
  "Verbatim in a monospaced font. Applyied to paragraphs where
  the first line is indented by one or more space or tab
  characters")
(defconst adoc-help-delimited-block
  "Delimited blocks are blocks of text enveloped by leading and
  trailing delimiter lines (normally a series of four or more
  repeated characters).")
(defconst adoc-help-delimited-block-comment
  "The contents of 'CommentBlocks' are not processed; they are
  useful for annotations and for excluding new or outdated
  content that you don't want displayed. CommentBlocks are never
  written to output files.")
(defconst adoc-help-delimited-block-passthrouh
  "By default the block contents is subject only to 'attributes'
  and 'macros' substitutions (use an explicit 'subs' attribute to
  apply different substitutions). PassthroughBlock content will
  often be backend specific. The following styles can be applied
  to passthrough blocks: pass:: No substitutions are performed.
  This is equivalent to `subs=\"none\"`. asciimath, latexmath::
  By default no substitutions are performed, the contents are
  rendered as mathematical formulas.")
(defconst adoc-help-delimited-block-listing
  "'ListingBlocks' are rendered verbatim in a monospaced font,
  they retain line and whitespace formatting and are often
  distinguished by a background or border. There is no text
  formatting or substitutions within Listing blocks apart from
  Special Characters and Callouts. Listing blocks are often used
  for computer output and file listings.")
(defconst adoc-help-delimited-block-literal
  "'LiteralBlocks' are rendered just like literal paragraphs.")
(defconst adoc-help-delimited-block-quote
  "'QuoteBlocks' are used for quoted passages of text. There are
  two styles: 'quote' and 'verse'. The style behavior is
  identical to quote and verse paragraphs except that blocks can
  contain multiple paragraphs and, in the case of the 'quote'
  style, other section elements. The first positional attribute
  sets the style, if no attributes are specified the 'quote'
  style is used. The optional 'attribution' and 'citetitle'
  attributes (positional attributes 2 and3) specify the quote's
  author and source.")
(defconst adoc-help-delimited-block-example
  "'ExampleBlocks' encapsulate the DocBook Example element and
  are used for, well, examples. Example blocks can be titled by
  preceding them with a 'BlockTitle'. DocBook toolchains will
  normally automatically number examples and generate a 'List of
  Examples' backmatter section.

  Example blocks are delimited by lines of equals characters and
  can contain any block elements apart from Titles, BlockTitles
  and Sidebars) inside an example block.")
(defconst adoc-help-delimited-block-sidebar
  "A sidebar is a short piece of text presented outside the
  narrative flow of the main text. The sidebar is normally
  presented inside a bordered box to set it apart from the main
  text.The sidebar body is treated like a normal section body.")
(defconst adoc-help-delimited-block-open-block
  "An 'OpenBlock' groups a set of block elements.")
(defconst adoc-help-list
  "Indentation is optional and does _not_ determine nesting.")
(defconst adoc-help-bulleted-list
  "Aka itimized or unordered.")
(defconst adoc-help-list-item-continuation
  "Another list or a literal paragraph immediately following a
  list item is implicitly appended to the list item; to append
  other block elements to a list item you need to explicitly join
  them to the list item with a 'list continuation' (a separator
  line containing a single plus character). Multiple block
  elements can be appended to a list item using list
  continuations (provided they are legal list item children in
  the backend markup).")
(defconst adoc-help-table
  "The AsciiDoc table syntax looks and behaves like other
  delimited block types and supports standard block configuration
  entries.")
(defconst adoc-help-macros
  "Inline Macros occur in an inline element context. A Block
  macro reference must be contained in a single line separated
  either side by a blank line or a block delimiter. Block macros
  behave just like Inline macros, with the following differences:
  1) They occur in a block context. 2) The default syntax is
  <name>::<target>[<attrlist>] (two colons, not one). 3) Markup
  template section names end in -blockmacro instead of
  -inlinemacro.")
(defconst adoc-help-url
  "If you don’t need a custom link caption you can enter the
  http, https, ftp, file URLs and email addresses without any
  special macro syntax.")
(defconst adoc-help-anchor
  "Used to specify hypertext link targets. The `<id>` is a unique
  string that conforms to the output markup's anchor syntax. The
  optional `<xreflabel>` is the text to be displayed by
  captionless 'xref' macros that refer to this anchor.")
(defconst adoc-help-xref
  "Creates a hypertext link to a document anchor. The `<id>`
  refers to an anchor ID. The optional `<caption>` is the link's
  displayed text.")
(defconst adoc-help-local-doc-link
  "Hypertext links to files on the local file system are
  specified using the link inline macro.")
(defconst adoc-help-local-doc-link
  "Hypertext links to files on the local file system are
  specified using the link inline macro.")
(defconst adoc-help-comment
  "Single lines starting with two forward slashes hard up against
  the left margin are treated as comments. Comment lines do not
  appear in the output unless the showcomments attribute is
  defined. Comment lines have been implemented as both block and
  inline macros so a comment line can appear as a stand-alone
  block or within block elements that support inline macro
  expansion.")
(defconst adoc-help-passthrough-macros
  "Passthrough macros are analogous to passthrough blocks and are
  used to pass text directly to the output. The substitution
  performed on the text is determined by the macro definition but
  can be overridden by the <subslist>. Passthroughs, by
  definition, take precedence over all other text
  substitutions.")
(defconst adoc-help-pass
  "Inline and block. Passes text unmodified (apart from
  explicitly specified substitutions).")
(defconst adoc-help-asciimath
  "Inline and block. Passes text unmodified. A (backend
  dependent) mechanism for rendering mathematical formulas given
  using the ASCIIMath syntax.")
(defconst adoc-help-latexmath
  "Inline and block. Passes text unmodified. A (backend
  dependent) mechanism for rendering mathematical formulas given
  using the LaTeX math syntax.")
(defconst adoc-help-pass-+++
  "Inline and block. The triple-plus passthrough is functionally
  identical to the pass macro but you don’t have to escape ]
  characters and you can prefix with quoted attributes in the
  inline version.")
(defconst adoc-help-pass-$$
  "Inline and block. The double-dollar passthrough is
  functionally identical to the triple-plus passthrough with one
  exception: special characters are escaped.")
(defconst adoc-help-monospace-literal
  "Text quoted with single backtick characters constitutes an
  inline literal passthrough. The enclosed text is rendered in a
  monospaced font and is only subject to special character
  substitution. This makes sense since monospace text is usually
  intended to be rendered literally and often contains characters
  that would otherwise have to be escaped. If you need monospaced
  text containing inline substitutions use a plus character
  instead of a backtick.")


;;; Code:

;;;; regexps
;; from AsciiDoc manual: The attribute name/value syntax is a single line ...
;; from asciidoc.conf:
;; ^:(?P<attrname>\w[^.]*?)(\.(?P<attrname2>.*?))?:(\s+(?P<attrvalue>.*))?$
;; asciidoc src code: AttributeEntry.isnext shows that above regexp is matched
;; against single line.
(defun adoc-re-attribute-entry ()
  (concat "^\\(:[a-zA-Z0-9_][^.\n]*?\\(?:\\..*?\\)?:[ \t]*\\)\\(.*?\\)$"))

;; from asciidoc.conf: ^= +(?P<title>[\S].*?)( +=)?$
;; asciidoc src code: Title.isnext reads two lines, which are then parsed by
;; Title.parse. The second line is only for the underline of two line titles.
(defun adoc-re-one-line-title (level)
  "Returns a regex matching a one line title of the given LEVEL.
When LEVEL is nil, a one line title of any level is matched.

match-data has these sub groups:
1 leading delimiter inclusive whites between delimiter and title text
2 title's text exclusive leading/trailing whites
3 trailing delimiter with all whites 
4 trailing delimiter only inclusive whites between title text and delimiter
0 only chars that belong to the title block element

==  my title  ==  n
---12------23------
            4--4"
  (let* ((del (if level
                 (make-string (+ level 1) ?=)
               (concat "=\\{1," (+ adoc-title-max-level 1) "\\}"))))
    (concat
     "^\\(" del "[ \t]+\\)"		      ; 1
     "\\([^ \t\n].*?\\)"                          ; 2
     ;; using \n instad $ is important so group 3 is guaranteed to be at least 1
     ;; char long (except when at the end of the buffer()). That is important to
     ;; to have a place to put the text property adoc-reserved on.
     "\\(\\([ \t]+" del "\\)?[ \t]*\\(?:\n\\|\\'\\)\\)" ))) ; 3 & 4

(defun adoc-make-one-line-title (sub-type level text)
  "Returns a one line title of LEVEL and SUB-TYPE containing the given text."
  (let ((del (make-string (+ level 1) ?=)))
    (concat del " " text (when (eq sub-type 2) (concat " " del)))))   

;; AsciiDoc handles that by source code, there is no regexp in AsciiDoc.  See
;; also adoc-re-one-line-title.
(defun adoc-re-two-line-title-undlerline (&optional del)
  "Returns a regexp matching the underline of a two line title.

DEL is an element of `adoc-two-line-title-del' or nil. If nil,
any del is matched.

Note that even if this regexp matches it still doesn't mean it is
a two line title underline, see also `adoc-re-two-line-title'."
  (concat
   "\\("
   (mapconcat
    (lambda(x)
      (concat
       "\\(?:"
       "\\(?:" (regexp-quote x) "\\)+"	
       (regexp-quote (substring x 0 1)) "?"
       "\\)"))
    (if del (list del) adoc-two-line-title-del) "\\|")          
   ;; adoc-re-two-line-title shall have same behaviour als one line, thus
   ;; also here use \n instead $
   "\\)[ \t]*\\(?:\n\\|\\'\\)"))

;; asciidoc.conf: regexp for _first_ line
;; ^(?P<title>.*?)$  additionally, must contain (?u)\w, see Title.parse
(defun adoc-re-two-line-title (del)
  "Returns a regexps that matches a two line title.

Note that even if this regexp matches it still doesn't mean it is
a two line title. You additionaly have to test if the underline
has the correct length.

DEL is described in `adoc-re-two-line-title-undlerline'.

match-data has these sub groups:

1 dummy, so that group 2 is the title's text as in
  adoc-re-one-line-title
2 title's text
3 delimiter
0 only chars that belong to the title block element"
  (when (not (eq (length del) 2))
    (error "two line title delimiters must be 2 chars long"))
  (concat
   ;; 1st line: title text must contain at least one \w character, see
   ;; asciidoc src, Title.parse,
   "\\(\\)\\(^.*?[a-zA-Z0-9_].*?\\)[ \t]*\n"
   ;; 2nd line: underline
   (adoc-re-two-line-title-undlerline del)))

(defun adoc-make-two-line-title (level text)
  "Returns a two line title of given LEVEL containing given TEXT.
LEVEL starts at 1."
  (concat text "\n" (adoc-make-two-line-title-underline level (length text))))
  
(defun adoc-make-two-line-title-underline (level &optional length)
  "Returns a two line title underline.
LEVEL is the level of the title, starting at 1. LENGTH is the
line of the title's text. When nil it defaults to 4."
  (unless length
    (setq length 4))
  (let* ((repetition-cnt (if (>= length 2) (/ length 2) 1))
	 (del (nth level adoc-two-line-title-del))
	 (result ""))
    (while (> repetition-cnt 0)
      (setq result (concat result del))
      (setq repetition-cnt (- repetition-cnt 1)))
    (when (eq (% length 2) 1)
      (setq result (concat result (substring del 0 1))))
    result))

(defun adoc-re-oulisti (type &optional level sub-type)
  "Returns a regexp matching an (un)ordered list item.

match-data his this sub groups:
1 leading whites
2 delimiter
3 trailing whites between delimiter and item's text
0 only chars belonging to delimiter/whites. I.e. none of text.

WARNING: See warning about list item nesting level in `adoc-list-descriptor'."
  (cond

   ;;   ^\s*- +(?P<text>.+)$                     normal 0           
   ;;   ^\s*\* +(?P<text>.+)$                    normal 1
   ;;   ...                                      ...
   ;;   ^\s*\*{5} +(?P<text>.+)$                 normal 5
   ;;   ^\+ +(?P<text>.+)$                       bibliograpy(DEPRECATED)     
   ((eq type 'adoc-unordered)
    (cond
     ((or (eq sub-type 'adoc-normal) (null sub-type))
      (let ((r (cond ((numberp level) (if (eq level 0) "-" (make-string level ?\*)))
                     ((or (null level) (eq level 'adoc-all-levels)) "-\\|\\*\\{1,5\\}")
                     (t (error "adoc-unordered/adoc-normal: invalid level")))))
        (concat "^\\([ \t]*\\)\\(" r "\\)\\([ \t]+\\)")))
     ((and (eq sub-type 'adoc-bibliography) (null level))
      "^\\(\\)\\(\\+\\)\\([ \t]+\\)")
     (t (error "adoc-unordered: invalid sub-type/level combination"))))

   ;;   ^\s*(?P<index>\d+\.) +(?P<text>.+)$      decimal = 0
   ;;   ^\s*(?P<index>[a-z]\.) +(?P<text>.+)$    lower alpha = 1
   ;;   ^\s*(?P<index>[A-Z]\.) +(?P<text>.+)$    upper alpha = 2
   ;;   ^\s*(?P<index>[ivx]+\)) +(?P<text>.+)$   lower roman = 3
   ;;   ^\s*(?P<index>[IVX]+\)) +(?P<text>.+)$   upper roman = 4
   ((eq type 'adoc-explicitly-numbered)
    (when level (error "adoc-explicitly-numbered: invalid level"))
    (let* ((l '("[0-9]+\\." "[a-z]\\." "[A-Z]\\." "[ivx]+)" "[IVX]+)"))
           (r (cond ((numberp sub-type) (nth sub-type l))
                    ((or (null sub-type) (eq sub-type 'adoc-all-subtypes)) (mapconcat 'identity l "\\|"))
                    (t (error "adoc-explicitly-numbered: invalid subtype")))))
      (concat "^\\([ \t]*\\)\\(" r "\\)\\([ \t]+\\)")))

   ;;   ^\s*\. +(?P<text>.+)$                    normal 0
   ;;   ^\s*\.{2} +(?P<text>.+)$                 normal 1
   ;;   ... etc until 5                          ...
   ((eq type 'adoc-implicitly-numbered) 
    (let ((r (cond ((numberp level) (number-to-string (+ level 1)))
                   ((or (null level) (eq level 'adoc-all-levels)) "1,5")
                   (t (error "adoc-implicitly-numbered: invalid level")))))
      (concat "^\\([ \t]*\\)\\(\\.\\{" r "\\}\\)\\([ \t]+\\)")))

   ;;   ^<?(?P<index>\d*>) +(?P<text>.+)$        callout
   ((eq type 'adoc-callout)
    (when (or level sub-type) (error "adoc-callout invalid level/sub-type"))
    "^\\(\\)\\(<?[0-9]*>\\)\\([ \t]+\\)")

   ;; invalid
   (t (error "invalid (un)ordered list type"))))
     
(defun adoc-make-uolisti (level is-1st-line)
  "Returns a regexp matching a unordered list item."
  (let* ((del (if (eq level 0) "-" (make-string level ?\*)))
         (white-1st (if indent-tabs-mode
                        (make-string (/ (* level standard-indent) tab-width) ?\t)
                      (make-string (* level standard-indent) ?\ )))
         (white-rest (make-string (+ (length del) 1) ?\ )))
    (if is-1st-line
        (concat white-1st del " ")
      white-rest)))

(defun adoc-re-llisti (type level)
  "Returns a regexp matching a labeled list item.
Subgroups:
1 leading blanks
2 label text, incl whites before delimiter
3 delimiter incl trailing whites
4 delimiter only

  foo :: bar
-12--23-3
      44"
  (cond
   ;; ^\s*(?P<label>.*[^:])::(\s+(?P<text>.+))?$    normal 0
   ;; ^\s*(?P<label>.*[^;]);;(\s+(?P<text>.+))?$    normal 1
   ;; ^\s*(?P<label>.*[^:]):{3}(\s+(?P<text>.+))?$  normal 2
   ;; ^\s*(?P<label>.*[^:]):{4}(\s+(?P<text>.+))?$  normal 3
   ((eq type 'adoc-labeled-normal)
    (let* ((deluq (nth level '("::" ";;" ":::" "::::"))) ; unqutoed
           (del (regexp-quote deluq))
           (del1st (substring deluq 0 1)))
      (concat
       "^\\([ \t]*\\)"			; 1
       "\\(.*[^" del1st "\n]\\)"	; 2
       "\\(\\(" del "\\)\\(?:[ \t]+\\|$\\)\\)"))) ; 3 & 4

   ;; glossary (DEPRECATED)
   ;; ^(?P<label>.*\S):-$                        
   ((eq type 'adoc-labeled-qanda)
    (concat
     "^\\([ \t]*\\)"			; 1
     "\\(.*[^ \t\n]\\)"			; 2
     "\\(\\(\\?\\?\\)\\)$"))		; 3 & 4

   ;; qanda (DEPRECATED)
   ;; ^\s*(?P<label>.*\S)\?\?$                      
   ((eq type 'adoc-labeled-glossary)
    (concat
     "^\\(\\)"				; 1
     "\\(.*[^ \t\n]\\)"			; 2
     "\\(\\(:-\\)\\)$"))		; 3 & 4
   (t (error "Unknown type/level"))))

(defun adoc-re-delimited-block-line ()
  (concat
   "\\(?:"
   (mapconcat
    (lambda (x)
      (concat "\\(?:" x "\\)[ \t]*$"))
    adoc-delimited-block-del "\\|")
   "\\)"))

;; KLUDGE: Contrary to what the AsciiDoc manual specifies, adoc-mode does not
;; allow that either the first or the last line within a delmited block is
;; blank. That shall help to prevent the case that adoc-mode wrongly
;; interprets the end of a delimited block as the beginning, and the beginning
;; of a following delimited block as the ending, thus wrongly interpreting the
;; text between two adjacent delimited blocks as delimited block.  It is
;; expected that it is unlikely that one wants to begin or end a delimited
;; block with a blank line, and it is expected that it is likely that
;; delimited blocks are surrounded by blank lines.
(defun adoc-re-delimited-block (del)
  (let* ((tmp (nth del adoc-delimited-block-del))
	 (start (if (consp tmp) (car tmp) tmp))
	 (end (if (consp tmp) (cdr tmp) tmp)))
    (concat
     "\\(" start "\\)[ \t]*\n"
     "\\("
       ;; a single leading non-blank line 
       "[ \t]*[^ \t\n].*\n"
       ;; optionally followed by
       "\\(?:"
         ;; any number of arbitrary lines followed by
         "\\(?:.*\n\\)*?"
         ;; a trailing non blank line
         "[ \t]*[^ \t\n].*\n"
       "\\)??" 
     "\\)??"
     "\\(" end "\\)[ \t]*$")))

;; TODO: since its multiline, it doesn't yet work properly.
(defun adoc-re-verbatim-paragraph-sequence ()
  (concat 
   "\\("
   ;; 1. paragraph in sequence delimited by blank line or list continuation
   "^\\+?[ \t]*\n" 

   ;; sequence of verbatim paragraphs
   "\\(?:"
     ;; 1st line starts with blanks, but has also non blanks, i.e. is not empty
     "[ \t]+[^ \t\n].*" 
     ;; 2nd+ line is neither a blank line nor a list continuation line
     "\\(?:\n\\(?:[^+ \t\n]\\|[ \t]+[^ \t\n]\\|\\+[ \t]*[^ \t\n]\\).*?\\)*?" 
     ;; paragraph delimited by blank line or list continuation or end of buffer
     ;; NOTE: now list continuation belongs the the verbatim paragraph sequence,
     ;; but actually we want to highlight it differently. Thus the font lock
     ;; keywoard handling list continuation must come after verbatim paraphraph
     ;; sequence.
     "\\(?:\n[ \t]*\\(?:\n\\|\\'\\)\\|\n\\+[ \t]*\n\\|\\'\\)" 
   "\\)+" 

   "\\)" ))

;; ^\.(?P<title>([^.\s].*)|(\.[^.\s].*))$
;; Isn't that asciidoc.conf regexp the same as: ^\.(?P<title>(.?[^.\s].*))$
;; insertion: so that this whole regex doesn't mistake a line starting with a
;; cell specifier like .2+| as a block title
(defun adoc-re-block-title ()
  "Returns a regexp matching an block title

Subgroups:
1 delimiter
2 title's text incl trailing whites
3 newline or end-of-buffer anchor

.foo n
12--23"
  (concat
   "^\\(\\.\\)"
   "\\(\\.?\\(?:"	
   "[0-9]+[^+*]" ; inserted part, see above
   "\\|[^. \t\n]\\).*\\)"
   "\\(\n\\|\\'\\)"))

;; (?u)^(?P<name>image|unfloat|toc)::(?P<target>\S*?)(\[(?P<attrlist>.*?)\])$
;; note that altough it hasn't got the s Python regular expression flag, it
;; still can spawn multiple lines. Probably asciidoc removes newlines before
;; it applies the regexp above
(defun adoc-re-block-macro (&optional cmd-name)
  "Returns a regexp matching an attribute list elment.
Subgroups:
1 cmd name
2 target
3 attribute list, exclusive brackets []"
  (concat
   "^\\(" (or cmd-name "[a-zA-Z0-9_]+") "\\)::"
   "\\([^ \t\n]*?\\)"
   "\\["
   "\\(" (adoc-re-content) "\\)"
   "\\][ \t]*$"))

;; ?P<id>[\w\-_]+
(defun adoc-re-id ()
  "Returns a regexp matching an id used by anchors/xrefs"
  "\\(?:[-a-zA-Z0-9_]+\\)")

(defun adoc-re-anchor (&optional type id)
  "Returns a regexp matching an anchor.

If TYPE is non-nil, only that type is matched. If TYPE is nil,
all types are matched.

If ID is non-nil, the regexp matches an anchor defining exactly
this id. If ID is nil, the regexp matches any anchor."
  (cond
   ((eq type 'block-id)
    ;; ^\[\[(?P<id>[\w\-_]+)(,(?P<reftext>.*?))?\]\]$
    (concat "^\\[\\["
	    "\\(" (if id (regexp-quote id) (adoc-re-id)) "\\)"
	    "\\(?:,\\(.*?\\)\\)?"
	    "\\]\\][ \t]*$"))

   ((eq type 'inline-special)
    ;; [\\]?\[\[(?P<attrlist>[\w"_:].*?)\]\]
    (concat "\\(\\[\\[\\)"
	    "\\(" (if id (concat (regexp-quote id) "[ \t]*?") "[a-zA-Z0-9\"_:].*?") "\\)"
	    "\\(\\]\\]\\)"))

   ((eq type 'biblio)
    ;; [\\]?\[\[\[(?P<attrlist>[\w_:][\w_:.-]*?)\]\]\]
    (concat "\\(\\[\\[\\)"
	    "\\(\\[" (if id (regexp-quote id) "[a-zA-Z0-9_:][a-zA-Z0-9_:.-]*?") "\\]\\)"
	    "\\(\\]\\]\\)"))

   ((eq type 'inline-general)
    (adoc-re-inline-macro "anchor" id))

   ((null type)
    (mapconcat
     (lambda (x) (adoc-re-anchor x id))
     '(block-id inline-special biblio inline-general)
     "\\|"))

   (t
    (error "Unknown type"))))

(defun adoc-re-xref (&optional type for-kw)
  "Returns a regexp matching a reference.

If TYPE is nil, any type is matched. If FOR-KW is true, the
regexp is intendet for a font lock keyword, which has to make
further tests to find a proper xref."
  (cond
   ((eq type 'inline-special-with-caption)
    ;; (?su)[\\]?&lt;&lt;(?P<attrlist>[\w"].*?)&gt;&gt;=xref2
    (if for-kw
	"\\(<<\\)\\([a-zA-Z0-9\"].*?\\)\\(,\\)\\(.*?\\(?:\n.*?\\)??\\)\\(>>\\)"
      (concat "\\(<<\\)\\(" (adoc-re-id) "[ \t\n]*\\)\\(,\\)\\([^>\n]*?\\(?:\n[^>\n]*?\\)??\\)\\(>>\\)")))

   ((eq type 'inline-special-no-caption)
    ;; asciidoc.conf uses the same regexp as for without caption
    (if for-kw
	"\\(<<\\)\\([a-zA-Z0-9\"].*?\\(?:\n.*?\\)??\\)\\(>>\\)"
      (concat "\\(<<\\)\\(" (adoc-re-id) "[ \t\n]*\\)\\(>>\\)")))

   ((eq type 'inline-general-macro)
    (adoc-re-inline-macro "xref"))

   ((null type)
    (mapconcat
     (lambda (x) (adoc-re-xref x for-kw))
     '(inline-special-with-caption inline-special-no-caption inline-general-macro)
     "\\|"))

   (t (error "unknown type"))))

(defun adoc-re-attribute-list-elt ()
  "Returns a regexp matching an attribute list elment.
Subgroups:
1 attribute name
2 attribute value if given as string 
3 attribute value if not given as string"
  (concat
   ",?[ \t\n]*"
   "\\(?:\\([a-zA-Z_]+\\)[ \t\n]*=[ \t\n]*\\)?"         ; 1
   "\\(?:"
     ;; regexp for string: See 'Mastering Regular Expressions', chapter 'The
     ;; Real "Unrolling-the-Loop" Pattern'.
     "\"\\([^\"\\]*\\(?:\\\\.[^\"\\]*\\)*\\)\"[ \t\n]*" "\\|"	; 2 
     "\\([^,]+\\)"					; 3 
   "\\)"))

(defun adoc-re-precond (&optional unwanted-chars backslash-allowed disallowed-at-bol)
  (concat
          (when disallowed-at-bol ".")
          "\\(?:"
          (unless disallowed-at-bol "^\\|")
          "[^"
          (if unwanted-chars unwanted-chars "")
          (if backslash-allowed "" "\\")
          "\n"
          "]"
          "\\)"))

(defun adoc-re-quote-precondition (not-allowed-chars)
  "Regexp that matches before a (un)constrained quote delimiter.

NOT-ALLOWED-CHARS are chars not allowed before the quote."
  (concat
     "\\(?:"   
       "^"     
     "\\|"
       "\\="
     "\\|"
       ; or *not* after
       ; - an backslash
       ; - user defined chars
       "[^" not-allowed-chars "\\\n]" 
     "\\)"))

;; AsciiDoc src:
;; # Unconstrained quotes can appear anywhere.
;; reo = re.compile(r'(?msu)(^|.)(\[(?P<attrlist>[^[\]]+?)\])?' \
;;         + r'(?:' + re.escape(lq) + r')' \
;;         + r'(?P<content>.+?)(?:'+re.escape(rq)+r')')
;;
;; BUG: Escaping ala \\**...** does not yet work. Probably adoc-mode should do
;; it like this, which is more similar to how asciidoc does it: 'Allow'
;; backslash as the first char. If the first char is ineed a backslash, it is
;; 'removed' (-> adoc-hide-delimiter face), and the rest of the match is left
;; unaffected.
(defun adoc-re-unconstrained-quote (ldel &optional rdel)
  (unless rdel (setq rdel ldel))
  (let* ((qldel (regexp-quote ldel))
         (qrdel (regexp-quote rdel)))
    (concat
     (adoc-re-quote-precondition "")
     "\\(\\[[^][]+?\\]\\)?"
     "\\(" qldel "\\)"
     "\\(" (adoc-re-content "+") "\\)"
     "\\(" qrdel "\\)")))

;; AsciiDoc src for constrained quotes
;; # The text within constrained quotes must be bounded by white space.
;; # Non-word (\W) characters are allowed at boundaries to accommodate
;; # enveloping quotes.
;;
;; reo = re.compile(r'(?msu)(^|[^\w;:}])(\[(?P<attrlist>[^[\]]+?)\])?' \
;;     + r'(?:' + re.escape(lq) + r')' \
;;     + r'(?P<content>\S|\S.*?\S)(?:'+re.escape(rq)+r')(?=\W|$)')
(defun adoc-re-constrained-quote (ldel &optional rdel)
  "
subgroups:
1 attribute list [optional]
2 starting del
3 enclosed text
4 closing del"
  (unless rdel (setq rdel ldel))
  (let ((qldel (regexp-quote ldel))
        (qrdel (regexp-quote rdel)))
    (concat
     ;; added &<> because those are special chars which are substituted by a
     ;; entity, which ends in ;, which is prohibited in the ascidoc.conf regexp
     (adoc-re-quote-precondition "A-Za-z0-9;:}&<>")  
     "\\(\\[[^][]+?\\]\\)?"
     "\\(" qldel "\\)"
     "\\([^ \t\n]\\|[^ \t\n]" (adoc-re-content) "[^ \t\n]\\)"
     "\\(" qrdel "\\)"
     ;; BUG: now that Emacs doesn't has look-ahead, the match is too long, and
     ;; adjancted quotes of the same type wouldn't be recognized.
     "\\(?:[^A-Za-z0-9\n]\\|[ \t]*$\\)")))

(defun adoc-re-quote (type ldel &optional rdel)
  (cond
   ((eq type 'adoc-constrained)
    (adoc-re-constrained-quote ldel rdel))
   ((eq type 'adoc-unconstrained)
    (adoc-re-unconstrained-quote ldel rdel))
   (t
    (error "Invalid type"))))

;; Macros using default syntax. From asciidoc.conf:
;; (?su)(?<!\w)[\\]?(?P<name>http|https|ftp|file|irc|mailto|callto|image|link|anchor|xref|indexterm):(?P<target>\S*?)\[(?P<attrlist>.*?)\]
;;
;; asciidoc.conf itself says: Default (catchall) inline macro is not
;; implemented. It _would_ be
;; (?su)[\\]?(?P<name>\w(\w|-)*?):(?P<target>\S*?)\[(?P<passtext>.*?)(?<!\\)\]=
(defun adoc-re-inline-macro (&optional cmd-name target unconstrained attribute-list-constraints)
  "Returns regex matching an inline macro.

Id CMD-NAME is nil, any command is matched. It maybe a regexp
itself in order to match multiple commands. If TARGET is nil, any
target is matched. When UNCONSTRAINED is nil, the returned regexp
begins with '\<', i.e. it will _not_ match when CMD-NAME is part
of a previous word. When ATTRIBUTE-LIST-CONSTRAINTS is 'empty,
only an empty attribut list is matched, if it's
'single-attribute, only an attribute list with exactly one
attribute is matched.

Subgroups of returned regexp:
1 cmd name
2 :
3 target
4 [
5 attribute list, exclusive brackets [], also when
  attribute-list-constraints is non-nil
6 ]"
  ;; !!! \< is not exactly what AsciiDoc does, see regex above
  (concat
   (unless unconstrained "\\<")
   "\\(" (if cmd-name (concat "\\(?:" cmd-name "\\)") "\\w+") "\\)"
   "\\(:\\)"
   "\\(" (if target (regexp-quote target) "[^ \t\n]*?") "\\)"
   "\\(\\[\\)\\("
   (cond
    ((eq attribute-list-constraints 'empty) "")
    ((eq attribute-list-constraints 'single-attribute) "[^\n,]*?\\(?:\n[^\n,]*?\\)??")
    (t (adoc-re-content)))
   "\\)\\(\\]\\)" ))

;; todo: use same regexps as for font lock
(defun adoc-re-paragraph-separate ()
  (concat

        ;; empty line
        "[ \t]*$"
        
        ;; delimited blocks / two line titles
        "\\|"
        "\\("
          "^+" "\\|"
          "\\++" "\\|"
          "/+" "\\|"
          "-+" "\\|"
          "\\.+" "\\|"
          "\\*+" "\\|"
          "_*+" "\\|"
          "=*+" "\\|"
          "~*+" "\\|"
          "^*+" "\\|"
          "--"
        "\\)"
        "[ \t]*$"
        ))

;; todo: use same regexps as for font lock
(defun adoc-re-paragraph-start ()
  (concat
        paragraph-separate
        
        ;; list items
        "\\|"
        "[ \t]*"
        "\\("
            "-"                  "\\|"
            "\\*\\{1,5\\}"       "\\|"
            "\\.\\{1,5\\}"       "\\|"
            "[0-9]\\{,3\\}\\."   "\\|"
            "[a-z]\\{,3\\}\\."   "\\|"
            "[A-Z]\\{,3\\}\\."   "\\|"
            "[ivxmcIVXMC]+)"     "\\|"
            ".*?:\\{2,4\\}"
        "\\)"
        "\\( \\|$\\)"
        
        ;; table rows
        "\\|"
        "|"

        ;; one line titles
        "\\|"
        "[=.].*$"
        
        ))

(defun adoc-re-aor(e1 e2)
  "all or: Returns a regex matching \(e1\|e2\|e1e2\)? "
  (concat "\\(?:" e1 "\\)?\\(?:" e2 "\\)?"))

(defun adoc-re-ror(e1 e2)
  "real or: Returns a regex matching \(e1\|e2\|e1e2\)"
  (concat "\\(?:\\(?:" e1 "\\)\\|\\(?:" e2 "\\)\\|\\(?:" e1 "\\)\\(?:" e2 "\\)\\)"))

;; ((?<!\S)((?P<span>[\d.]+)(?P<op>[*+]))?(?P<align>[<\^>.]{,3})?(?P<style>[a-z])?)?\|'
(defun adoc-re-cell-specifier () 
  (let* ((fullspan (concat (adoc-re-ror "[0-9]+" "\\.[0-9]+") "[*+]"))
         (align (adoc-re-ror "[<^>]" "\\.[<^>]"))
         (style "[demshalv]"))
    (concat "\\(?:" fullspan "\\)?\\(?:" align "\\)?\\(?:" style "\\)?")))

;; bug: if qualifier is "+", and the thing to match starts at the end of a
;;      line (i.e. the first char is newline), then wrongly this regexp does
;;      never match.
;; Note: asciidoc uses Python's \s to determine blank lines, while _not_
;;       setting either the LOCALE or UNICODE flag, see
;;       Reader.skip_blank_lines. Python uses [ \t\n\r\f\v] for it's \s . So
;;       the horizontal spaces are [ \t].
(defun adoc-re-content (&optional qualifier) 
  "Matches content, possibly spawning multiple non-blank lines"
  (concat
   "\\(?:"
   ;; content on initial line
   "." (or qualifier "*") "?" 
   ;; if content spawns multiple lines
   "\\(?:\n"
     ;; complete non blank lines
     "\\(?:[ \t]*\\S-.*\n\\)*?"
     ;; leading content on last line
     ".*?"
   "\\)??"
   "\\)"))


;;;; font lock keywords 
(defun adoc-kwf-std (end regexp &optional must-free-groups no-block-del-groups)
  "Standart function for keywords

Intendent to be called from font lock keyword functions. END is
the limit of the search. REXEXP the regexp to be searched.
MUST-FREE-GROUPS a list of regexp group numbers which may not
match text that has an adoc-reserved text-property with a non-nil
value. Likewise, groups in NO-BLOCK-DEL-GROUPS may not contain
text having adoc-reserved set to 'block-del."
  (let ((found t) (prevented t) saved-point)
    (while (and found prevented (<= (point) end) (not (eobp)))
      (setq saved-point (point))
      (setq found (re-search-forward regexp end t))
      (setq prevented 
	    (and found
		 (or
		  (some (lambda(x)
			  (and (match-beginning x)
			       (text-property-not-all (match-beginning x)
						      (match-end x)
						      'adoc-reserved nil)))
			must-free-groups)
		  (some (lambda(x)
			  (and (match-beginning x))
			  (text-property-any (match-beginning x)
			         	     (match-end x)
					     'adoc-reserved 'block-del))
			no-block-del-groups))))
      (when (and found prevented (<= (point) end))
	(goto-char (1+ saved-point))))
    (and found (not prevented))))

(defun adoc-kwf-attribute-list (end)
  ;; for each attribute list before END
  (while (< (point) end)
    (goto-char (or (text-property-not-all (point) end 'adoc-attribute-list nil)
                   end))
    (when (< (point) end)
      (let* ((attribute-list-end
              (or (text-property-any (point) end 'adoc-attribute-list nil)
                  end))
             (prop-of-attribute-list
              (get-text-property (point) 'adoc-attribute-list))
             ;; position (number) or name (string) of current
             ;; attribute. Attribute list start with positional attributes, as
             ;; opposed to named attributes, thus init with 0.
             (pos-or-name-of-attribute 0))

        (if (facep prop-of-attribute-list)
            ;; The attribute list is not really an attribute list. As a whole
            ;; it counts as text.
            (put-text-property
             (point) attribute-list-end
             'face prop-of-attribute-list)

          ;; for each attribute in current attribute list
          (while (re-search-forward (adoc-re-attribute-list-elt) attribute-list-end t)
            (when (match-beginning 1); i.e. when it'a named attribute
              ;; get attribute's name
              (setq pos-or-name-of-attribute
                    (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
              ;; fontify the attribute's name with markup-attribute-face
              (put-text-property
               (match-beginning 1) (match-end 1) 'face markup-attribute-face))

            ;; fontify the attribute's value
            (let ((match-group-of-attribute-value (if (match-beginning 2) 2 3))
                  (attribute-value-face
                   (adoc-face-for-attribute pos-or-name-of-attribute prop-of-attribute-list)))
              (put-text-property
               (match-beginning match-group-of-attribute-value)
               (match-end match-group-of-attribute-value)
               'face attribute-value-face))

            (when (numberp pos-or-name-of-attribute)
              (setq pos-or-name-of-attribute (1+ pos-or-name-of-attribute)))))

        (goto-char attribute-list-end))))
  nil)

(defun adoc-facespec-subscript ()
  (list 'quote
	(append '(face markup-subscript-face)
		(when (not (= 0 (car adoc-script-raise)))
		  `(display (raise ,(car adoc-script-raise)))))))

(defun adoc-facespec-superscript ()
  (list 'quote
	(append '(face markup-superscript-face)
		(when (not (= 0 (car adoc-script-raise)))
		  `(display (raise ,(cadr adoc-script-raise)))))))

;; todo: use & learn some more macro magic so adoc-kw-unconstrained-quote and
;; adoc-kw-constrained-quote are less redundant and have common parts in one
;; macro. E.g. at least such 'lists'
;; (not (text-property-not-all (match-beginning 1) (match-end 1) 'adoc-reserved nil))
;; (not (text-property-not-all (match-beginning 3) (match-end 3) 'adoc-reserved nil))
;; ...
;; could surely be replaced by a single (adoc-not-reserved-bla-bla 1 3)

;; BUG: Remember that if a matcher function returns nil, font-lock does not
;; further call it and abandons that keyword. Thus in adoc-mode in general,
;; there should be a loop around (and (re-search-forward ...) (not
;; (text-property-not-all...)) ...). Currently if say a constrained quote cant
;; match because of adoc-reserved, following quotes of the same type which
;; should be highlighed are not, because font-lock abandons that keyword.

(defun adoc-kw-one-line-title (level text-face)
  "Creates a keyword for font-lock which highlights one line titles"
  (list
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-one-line-title level) '(0)))
    '(1 '(face markup-meta-hide-face adoc-reserved block-del) t)
    `(2 ,text-face t) 
    '(3  '(face nil adoc-reserved block-del) t)
    '(4 '(face markup-meta-hide-face) t t)))

;; todo: highlight bogous 'two line titles' with warning face
;; todo: completly remove keyword when adoc-enable-two-line-title is nil
(defun adoc-kw-two-line-title (del text-face)
  "Creates a keyword for font-lock which highlights two line titles"
  (list
   ;; matcher function
   `(lambda (end)
      (and adoc-enable-two-line-title
           (re-search-forward ,(adoc-re-two-line-title del) end t)
           (< (abs (- (length (match-string 2)) (length (match-string 3)))) 3)
	   (or (not (numberp adoc-enable-two-line-title))
	       (not (equal adoc-enable-two-line-title (length (match-string 2)))))
           (not (text-property-not-all (match-beginning 0) (match-end 0) 'adoc-reserved nil))))
   ;; highlighers
   `(2 ,text-face t)
   `(3 '(face markup-meta-hide-face adoc-reserved block-del) t)))

;; (defun adoc-?????-attributes (endpos enddelchar)
;;   (list
;;    (concat 
;;     ",?[ \t\n]*"
;;     "\\(?:\\([a-zA-Z_]+\\)[ \t\n]*=[ \t\n]*\\)?" ; attribute name
;;     "\\([^" enddelchar ",]*\\|" (adoc-re-string) "\\)"))					      ; attribute value
;;    '(1 markup-attribute-face t)
;;    '(2 markup-value-face t)))

(defun adoc-kw-oulisti (type &optional level sub-type)
  "Creates a keyword for font-lock which highlights both (un)ordered list item.
Concerning TYPE, LEVEL and SUB-TYPE see `adoc-re-oulisti'"
  (list
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-oulisti type level sub-type) '(0)))
   '(0 '(face nil adoc-reserved block-del) t)
   '(2 markup-list-face t) 
   '(3 adoc-align t)))

(defun adoc-kw-llisti (sub-type &optional level)
  "Creates a keyword for font-lock which highlights labeled list item.
Concerning TYPE, LEVEL and SUB-TYPE see `adoc-re-llisti'."
  (list
   `(lambda (end)
      (when (adoc-kwf-std end ,(adoc-re-llisti sub-type level) '(0))
	(let ((pos (match-beginning 0)))
	  (when (> pos (point-min))
	    (put-text-property (1- pos) pos 'adoc-reserved 'block-del)))
	t))
   '(1 '(face nil adoc-reserved block-del) t)
   '(2 markup-gen-face t)
   '(3 '(face adoc-align adoc-reserved block-del) t)
   '(4 markup-list-face t)))

(defun adoc-kw-list-continuation ()
  (list 
   ;; see also regexp of forced line break, which is similar. it is not directly
   ;; obvious from asciidoc sourcecode what the exact rules are.
   '(lambda (end) (adoc-kwf-std end "^\\(\\+\\)[ \t]*$" '(1)))
   '(1 '(face markup-meta-face adoc-reserved block-del) t))) 

(defun adoc-kw-delimited-block (del &optional text-face inhibit-text-reserved)
  "Creates a keyword for font-lock which highlights a delimited block."
  (list
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-delimited-block del) '(1 3)))
   '(0 '(face nil font-lock-multiline t) t)
   '(1 '(face markup-meta-hide-face adoc-reserved block-del) t)
   (if (not inhibit-text-reserved)
       `(2 '(face ,text-face face markup-verbatim-face adoc-reserved t) t t)
     `(2 ,text-face t t))
   '(3 '(face markup-meta-hide-face adoc-reserved block-del) t)))

;; if adoc-kw-delimited-block, adoc-kw-two-line-title don't find the whole
;; delimited block / two line title, at least 'use up' the delimiter line so it
;; is later not misinterpreted as a funny serries of unconstrained quotes
(defun adoc-kw-delimiter-line-fallback ()
  (list
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-delimited-block-line) '(0)))
   '(0 '(face markup-meta-face adoc-reserved block-del) t)))

;; admonition paragraph. Note that there is also the style with the leading attribute list.
;; (?s)^\s*(?P<style>NOTE|TIP|IMPORTANT|WARNING|CAUTION):\s+(?P<text>.+)
(defmacro adoc-kw-admonition-paragraph ()
  "Creates a keyword which highlights admonition paragraphs"
  `(list
    ;; matcher function
    (lambda (end)
      (and (re-search-forward "^[ \t]*\\(\\(?:CAUTION\\|WARNING\\|IMPORTANT\\|TIP\\|NOTE\\):\\)\\([ \t]+\\)" end t)
           (not (text-property-not-all (match-beginning 0) (match-end 0) 'adoc-reserved nil))))
    ;; highlighers
    '(1 '(face adoc-complex-replacement adoc-reserved t))
    '(2 '(face adoc-align adoc-reserved t))))

(defun adoc-kw-verbatim-paragraph-sequence ()
  "Creates a keyword which highlights a sequence of verbatim paragraphs."
  (list
    ;; matcher function
    `(lambda (end)
      (and (re-search-forward ,(adoc-re-verbatim-paragraph-sequence) end t)
           (not (text-property-not-all (match-beginning 0) (match-end 0) adoc-reserved nil))))
    ;; highlighers
    '(1 '(face adoc-monospace adoc-reserved t font-lock-multiline t))))

(defun adoc-kw-block-title ()
  (list
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-block-title) '(1)))
   '(1 '(face markup-meta-face adoc-reserved block-del))
   '(2 markup-gen-face)
   '(3 '(face nil adoc-reserved block-del))))

(defun adoc-kw-quote (type ldel text-face-spec &optional del-face rdel literal-p)
  "Return a keyword which highlights (un)constrained quotes.
When LITERAL-P is non-nil, the contained text is literal text."
  (list
   ;; matcher function
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-quote type ldel rdel) '(1 2 4) '(3)))
   ;; highlighers
   '(1 '(face markup-meta-face adoc-reserved t) t t)                    ; attribute list
   `(2 '(face ,(or del-face markup-meta-hide-face) adoc-reserved t) t)  ; open del
   `(3 ,text-face-spec append)                                               ; text 
   (if literal-p
	`(3 '(face ,markup-verbatim-face adoc-reserved t) append)
      '(3 nil)) ; grumbl, I dont know how to get rid of it
   `(4 '(face ,(or del-face markup-meta-hide-face) adoc-reserved t) t))); close del

(defun adoc-kw-inline-macro (&optional cmd-name unconstrained attribute-list-constraints cmd-face target-faces target-meta-p attribute-list)
  "Returns a kewyword which highlights an inline macro.

For CMD-NAME and UNCONSTRAINED see
`adoc-re-inline-macro'. CMD-FACE determines face for the command
text. If nil, `markup-command-face' is used.  TARGET-FACES
determines face for the target text. If nil `markup-meta-face' is
used. If a list, the first is used if the attribute list is the
empty string, the second is used if its not the empty string. If
TARGET-META-P is non-nil, the target text is considered to be
meta characters."
  (list
   `(lambda (end) (adoc-kwf-std end ,(adoc-re-inline-macro cmd-name nil unconstrained attribute-list-constraints) '(1 2 4 5) '(0)))
   `(1 '(face ,(or cmd-face markup-command-face) adoc-reserved t) t) ; cmd-name
   '(2 '(face markup-meta-face adoc-reserved t) t)		     ; :
   `(3 ,(cond ((not target-faces) markup-meta-face)		     ; target
	      ((listp target-faces) `(if (string= (match-string 5) "") ; 5=attribute-list
					 ,(car target-faces)
				       ,(cadr target-faces)))
	      (t target-faces))
       ,(if target-meta-p t 'append))
   '(4 '(face markup-meta-face adoc-reserved t) t) ; [
   `(5 '(face markup-meta-face adoc-attribute-list ,(or attribute-list t)) t)
   '(6 '(face markup-meta-face adoc-reserved t) t))) ; ]

;; largely copied from adoc-kw-inline-macro
;; todo: output text should be affected by quotes & co, e.g. bold, emph, ...
(defun adoc-kw-inline-macro-urls-attribute-list ()
  (let ((cmd-name (regexp-opt '("http" "https" "ftp" "file" "irc" "mailto" "callto" "link"))))
    (list
     `(lambda (end) (adoc-kwf-std end ,(adoc-re-inline-macro cmd-name) '(0) '(0)))
     `(1 '(face markup-internal-reference-face adoc-reserved t) t) ; cmd-name
     `(2 '(face markup-internal-reference-face adoc-reserved t) t) ; :
     `(3 '(face markup-internal-reference-face adoc-reserved t) t) ; target
     '(4 '(face markup-meta-face adoc-reserved t) t)		   ; [
     `(5 '(face markup-reference-face adoc-attribute-list markup-reference-face) append)
     '(6 '(face markup-meta-face adoc-reserved t) t))))            ; ]

(defun adoc-kw-inline-macro-urls-no-attribute-list ()
  (let ((cmd-name (regexp-opt '("http" "https" "ftp" "file" "irc" "mailto" "callto" "link"))))
    (list
     `(lambda (end) (adoc-kwf-std end ,(adoc-re-inline-macro cmd-name nil nil 'empty) '(0) '(0)))
     '(1 '(face markup-reference-face adoc-reserved t) append) ; cmd-name
     '(2 '(face markup-reference-face adoc-reserved t) append)		     ; :
     '(3 '(face markup-reference-face adoc-reserved t) append)		     ; target
     '(4 '(face markup-meta-face adoc-reserved t) t) ; [
					             ; 5 = attriblist is empty
     '(6 '(face markup-meta-face adoc-reserved t) t)))) ; ]

;; standalone url
;; From asciidoc.conf:
;; # These URL types don't require any special attribute list formatting.
;; (?su)(?<!\S)[\\]?(?P<name>http|https|ftp|file|irc):(?P<target>//[^\s<>]*[\w/])=
;; # Allow a leading parenthesis and square bracket.
;; (?su)(?<\=[([])[\\]?(?P<name>http|https|ftp|file|irc):(?P<target>//[^\s<>]*[\w/])=
;; # Allow <> brackets.
;; (?su)[\\]?&lt;(?P<name>http|https|ftp|file|irc):(?P<target>//[^\s<>]*[\w/])&gt;=
;; 
;; asciidoc.conf bug? why is it so restrictive for urls without attribute
;; list, that version can only have a limited set of characters before. Why
;; not just have the rule that it must start with \b.
;;
;; standalone email
;; From asciidoc.conf:
;; (?su)(?<![">:\w._/-])[\\]?(?P<target>\w[\w._-]*@[\w._-]*\w)(?!["<\w_-])=mailto
;;
;; todo: properly handle leading backslash escapes
;;
;; non-bugs: __flo@gmail.com__ is also in AsciiDoc *not* an emphasised email, it's
;;   just an emphasised text. Thats because the quote transforms happen before
;;   the url transform, thus the middle stage is something like
;;   ...>flo@gmail.com<... According to asciidoc.conf regexps a leading > or a
;;   trailing < are not allowed. In adoc-mode, the fontification is as in
;;   AsciiDoc, but that's coincidence. The reason in adoc-mode is that the
;;   regexps quantifier are greedy instead lazy, thus the trailing __ behind the
;;   email are taken part as the email adress, and then adoc-kwf-std cant match
;;   because part of the match (the __) contains text properties with
;;   adoc-reserved non-nil, also because quote highlighting already happened.
(defun adoc-kw-standalone-urls ()
  (let* ((url "\\b\\(?:https?\\|ftp\\|file\\|irc\\)://[^ \t\n<>]*[a-zA-Z0-9_/]")
	 (url<> (concat "<\\(?:" url "\\)>")) 
	 (email "[a-zA-Z0-9_][-a-zA-Z0-9_._]*@[-a-zA-Z0-9_._]*[a-zA-Z0-9_]")
	 (both (concat "\\(?:" url "\\)\\|\\(?:" url<> "\\)\\|\\(?:" email "\\)")))
    (list
     `(lambda (end) (adoc-kwf-std end ,both '(0) '(0)))
     '(0 '(face markup-reference-face adoc-reserved t) append t))))

;; bug: escapes are not handled yet
;; todo: give the inserted character a specific face. But I fear that is not
;; possible. The string inserted with the ovlerlay property after-string gets
;; the face of the text 'around' it, which is in this case the text following
;; the replacement.
(defmacro adoc-kw-replacement (regexp &optional replacement)
  "Creates a keyword for font-lock which highlights replacements."
  `(list
    ;; matcher function
    (lambda (end)
      (let ((found t) (prevented t) saved-point)
        (while (and found prevented)
          (setq saved-point (point))
          (setq found
                (re-search-forward ,regexp end t))
          (setq prevented ; prevented is only meaningfull wenn found is non-nil
                (or
                 (not found) ; the following is only needed when found
                 (text-property-not-all (match-beginning 1) (match-end 1) 'adoc-reserved nil)))
          (when (and found prevented)
            (goto-char (+ saved-point 1))))
        (when (and found (not prevented) adoc-insert-replacement ,replacement)
          (let* ((s (cond
                     ((stringp ,replacement)
                      ,replacement)
                     ((functionp ,replacement)
                      (funcall ,replacement (match-string-no-properties 1)))
                     (t (error "Invalid replacement type"))))
                 (o (when (stringp s)
                      (make-overlay (match-end 1) (match-end 1)))))
            (setq adoc-replacement-failed (not o))
            (unless adoc-replacement-failed
              (overlay-put o 'after-string s))))
        (and found (not prevented))))

    ;; highlighers
    ;; todo: replacement instead warining face if resolver is not given
    (if (and adoc-insert-replacement ,replacement)
        ;; '((1 (if adoc-replacement-failed adoc-warning adoc-hide-delimiter) t)
        ;;   (1 '(face nil adoc-reserved t) t))
        '(1 '(face adoc-hide-delimiter adoc-reserved t) t)
      '(1 '(face adoc-replacement adoc-reserved t) t))))

;; - To ensure that indented lines are nicely aligned. They only look aligned if
;;   the whites at line beginning have a fixed with font.
;; - Some faces have properties which are also visbile on whites
;;   (underlines/backgroundcolor/...), for example links typically gave
;;   underlines. If now a link in an indented paragraph (e.g. because its a list
;;   item), spawns multiple lines, then without countermeasures the blanks at
;;   line beginning would also be underlined, which looks akward.
(defun adoc-flf-first-whites-fixed-width(end)
  ;; it makes no sense to do something with a blank line, so require at least one non blank char. 
  (and (re-search-forward "\\(^[ \t]+\\)[^ \t\n]" end t)
       ;; dont replace a face with with adoc-align which already is a fixed with
       ;; font (most probably), because then it also won't look aligned
       (text-property-not-all (match-beginning 1) (match-end 1) 'face 'markup-typewriter-face)
       (text-property-not-all (match-beginning 1) (match-end 1) 'face 'markup-code-face)
       (text-property-not-all (match-beginning 1) (match-end 1) 'face 'markup-passthrough-face)
       (text-property-not-all (match-beginning 1) (match-end 1) 'face 'markup-comment-face)))

;; See adoc-flf-first-whites-fixed-width
(defun adoc-kw-first-whites-fixed-width ()
  (list
   'adoc-flf-first-whites-fixed-width
   '(1 adoc-align t)))

;; ensures that faces from the markup-text group don't overwrite faces from the
;; markup-meta group
(defun adoc-flf-meta-face-cleanup (end)
  (while (< (point) end)
    (let* ((next-pos (next-single-property-change (point) 'face nil end))
	   (faces-raw (get-text-property (point) 'face))
	   (faces (if (listp faces-raw) faces-raw (list faces-raw)))
	   newfaces
	   meta-p)
      (while faces
	(if (member (car faces) '(markup-meta-hide-face markup-command-face markup-attribute-face markup-value-face markup-complex-replacement-face markup-list-face markup-table-face markup-table-row-face markup-table-cell-face markup-anchor-face markup-internal-reference-face markup-comment-face markup-preprocessor-face))
	    (progn
	      (setq meta-p t)
	      (setq newfaces (cons (car faces) newfaces)))
	  (if (not (string-match "markup-" (symbol-name (car faces))))
	      (setq newfaces (cons (car faces) newfaces))))
	(setq faces (cdr faces)))
      (if meta-p
	  (put-text-property (point) next-pos 'face
			     (if (= 1 (length newfaces)) (car newfaces) newfaces)))
      (goto-char next-pos)))
  nil)


;;;; font lock 
(defun adoc-unfontify-region-function (beg end) 
  ;; 
  (font-lock-default-unfontify-region beg end)
  
  ;; remove overlays. Currently only used by AsciiDoc replacements
  ;; todo: this is an extremly brute force solution and interacts very badly
  ;; with many (minor) modes using overlays such as flyspell or ediff
  (when adoc-insert-replacement
    (remove-overlays beg end))

  ;; text properties. Currently only display raise used for sub/superscripts.
  ;; code snipped copied from tex-mode
  (when (not (and (= 0 (car adoc-script-raise)) (= 0 (cadr adoc-script-raise))))
    (while (< beg end)
      (let ((next (next-single-property-change beg 'display nil end))
	    (prop (get-text-property beg 'display)))
	(if (and (eq (car-safe prop) 'raise)
		 (member (car-safe (cdr prop)) adoc-script-raise)
		 (null (cddr prop)))
	    (put-text-property beg next 'display nil))
	(setq beg next)))))

(defun adoc-font-lock-mark-block-function ()
  (mark-paragraph 2)
  (forward-paragraph -1))

(defun adoc-get-font-lock-keywords ()
  (list
   
   ;; Asciidoc BUG: Lex.next has a different order than the following extract
   ;; from the documentation states.
   
   ;; When a block element is encountered asciidoc(1) determines the type of
   ;; block by checking in the following order (first to last): (section)
   ;; Titles, BlockMacros, Lists, DelimitedBlocks, Tables, AttributeEntrys,
   ;; AttributeLists, BlockTitles, Paragraphs.

   ;; sections / document structure
   ;; ------------------------------
   (adoc-kw-one-line-title 0 markup-title-0-face)
   (adoc-kw-one-line-title 1 markup-title-1-face)
   (adoc-kw-one-line-title 2 markup-title-2-face)
   (adoc-kw-one-line-title 3 markup-title-3-face)
   (adoc-kw-one-line-title 4 markup-title-4-face)
   (adoc-kw-two-line-title (nth 0 adoc-two-line-title-del) markup-title-0-face)
   (adoc-kw-two-line-title (nth 1 adoc-two-line-title-del) markup-title-1-face)
   (adoc-kw-two-line-title (nth 2 adoc-two-line-title-del) markup-title-2-face)
   (adoc-kw-two-line-title (nth 3 adoc-two-line-title-del) markup-title-3-face)
   (adoc-kw-two-line-title (nth 4 adoc-two-line-title-del) markup-title-4-face)


   ;; block macros 
   ;; ------------------------------
   ;; todo: respect asciidoc.conf order

   ;; -- system block macros
   ;;     # Default system macro syntax.
   ;; SYS_RE = r'(?u)^(?P<name>[\\]?\w(\w|-)*?)::(?P<target>\S*?)' + \
   ;;          r'(\[(?P<attrlist>.*?)\])$'
   ;; conditional inclusion
   (list "^\\(\\(?:ifn?def\\|endif\\)::\\)\\([^ \t\n]*?\\)\\(\\[\\).+?\\(\\]\\)[ \t]*$"
         '(1 '(face adoc-preprocessor adoc-reserved block-del))    ; macro name
         '(2 '(face adoc-delimiter adoc-reserved block-del))       ; condition
         '(3 '(face adoc-hide-delimiter adoc-reserved block-del))  ; [
         ; ... attribute list content = the conditionaly included text
         '(4 '(face adoc-hide-delimiter adoc-reserved block-del))) ; ]
   ;; include
   (list "^\\(\\(include1?::\\)\\([^ \t\n]*?\\)\\(\\[\\)\\(.*?\\)\\(\\]\\)\\)[ \t]*$"
         '(1 '(face nil adoc-reserved block-del)) ; the whole match
         '(2 adoc-preprocessor)           ; macro name
         '(3 adoc-delimiter)              ; file name
         '(4 adoc-hide-delimiter)         ; [
         '(5 adoc-delimiter)              ;   attribute list content
         '(6 adoc-hide-delimiter))        ; ]


   ;; -- special block macros
   ;; ruler line.
   ;; Is a block marcro in asciidoc.conf, altough manual has it in the "text formatting" section 
   ;; ^'{3,}$=#ruler
   (list "^\\('\\{3,\\}+\\)[ \t]*$"
         '(1 '(face adoc-complex-replacement adoc-reserved block-del))) 
   ;; forced pagebreak
   ;; Is a block marcro in asciidoc.conf, altough manual has it in the "text formatting" section 
   ;; ^<{3,}$=#pagebreak
   (list "^\\(<\\{3,\\}+\\)[ \t]*$"
         '(1 '(face adoc-delimiter adoc-reserved block-del))) 
   ;; comment
   ;; (?mu)^[\\]?//(?P<passtext>[^/].*|)$
   ;; I don't know what the [\\]? should mean
   (list "^\\(//\\(?:[^/].*\\|\\)\\(?:\n\\|\\'\\)\\)"
         '(1 '(face markup-comment-face adoc-reserved block-del)))    
   ;; image. The first positional attribute is per definition 'alt', see
   ;; asciidoc manual, sub chapter 'Image macro attributes'.
   (list `(lambda (end) (adoc-kwf-std end ,(adoc-re-block-macro "image") '(0)))
         '(0 '(face markup-meta-face adoc-reserved block-del) t) ; whole match
         '(1 markup-complex-replacement-face t)	; 'image'  
         '(2 markup-internal-reference-face t)  ; file name
         '(3 '(face markup-meta-face adoc-reserved nil adoc-attribute-list ("alt")) t)) ; attribute list
			  
   ;; passthrough: (?u)^(?P<name>pass)::(?P<subslist>\S*?)(\[(?P<passtext>.*?)\])$
   ;; todo

   ;; -- general block macro
   (list `(lambda (end) (adoc-kwf-std end ,(adoc-re-block-macro) '(0)))
         '(0 '(face markup-meta-face adoc-reserved block-del)) ; whole match
         '(1 markup-command-face t)			       ; command name
         '(3 '(face markup-meta-face adoc-reserved nil adoc-attribute-list t) t)) ; attribute list

   ;; lists
   ;; ------------------------------
   ;; todo: respect and insert adoc-reserved
   ;; 
   ;; bug: for items begining with a label (i.e. user text): if might be that
   ;; the label contains a bogous end delimiter such that you get a
   ;; highlighting that starts in the line before the label item and ends
   ;; within the label. Example:
   ;;
   ;; bla bli 2 ** 8 is 256                   quote starts at this **
   ;; that is **important**:: bla bla         ends at the first **
   ;; 
   ;; similary:
   ;;
   ;; bla 2 ** 3:: bla bla 2 ** 3 gives       results in an untwanted unconstrained quote
   ;; 
   ;; - dsfadsf sdf ** asfdfsad
   ;; - asfdds fsda ** fsfas
   ;;
   ;; maybe the solution is invent a new value for adoc-reserved, or a new
   ;; property alltogether. That would also be used for the trailing \n in other
   ;; block elements. Text is not allowed to contain them. All font lock
   ;; keywords standing for asciidoc inline substituions would have to be
   ;; adapted.
   ;;
   ;;
   ;; bug: the text of labelleled items gets inline macros such as anchor not
   ;; highlighted. See for example [[X80]] in asciidoc manual source.
   (adoc-kw-oulisti 'adoc-unordered 'adoc-all-levels) 
   (adoc-kw-oulisti 'adoc-unordered nil 'adoc-bibliography) 
   (adoc-kw-oulisti 'adoc-explicitly-numbered ) 
   (adoc-kw-oulisti 'adoc-implicitly-numbered 'adoc-all-levels) 
   (adoc-kw-oulisti 'adoc-callout) 
   (adoc-kw-llisti 'adoc-labeled-normal 0) 
   (adoc-kw-llisti 'adoc-labeled-normal 1) 
   (adoc-kw-llisti 'adoc-labeled-normal 2) 
   (adoc-kw-llisti 'adoc-labeled-normal 3) 
   (adoc-kw-llisti 'adoc-labeled-qanda) 
   (adoc-kw-llisti 'adoc-labeled-glossary) 
   (adoc-kw-list-continuation) 

   ;; Delimited blocks
   ;; ------------------------------
   (adoc-kw-delimited-block 0 markup-comment-face)   ; comment
   (adoc-kw-delimited-block 1 markup-passthrough-face) ; passthrough
   (adoc-kw-delimited-block 2 markup-code-face) ; listing
   (adoc-kw-delimited-block 3 markup-verbatim-face) ; literal
   (adoc-kw-delimited-block 4 nil t) ; quote    
   (adoc-kw-delimited-block 5 nil t) ; example  
   (adoc-kw-delimited-block 6 adoc-secondary-text t) ; sidebar
   (adoc-kw-delimited-block 7 nil t) ; open block
   (adoc-kw-delimiter-line-fallback)  


   ;; tables
   ;; ------------------------------
   ;; must come BEFORE block title, else rows starting like .2+| ... | ... are taken as 
   (cons "^|=\\{3,\\}[ \t]*$" 'adoc-table-del ) ; ^\|={3,}$
   (list (concat "^"                  "\\(" (adoc-re-cell-specifier) "\\)" "\\(|\\)"
                 "\\(?:[^|\n]*?[ \t]" "\\(" (adoc-re-cell-specifier) "\\)" "\\(|\\)"
                 "\\(?:[^|\n]*?[ \t]" "\\(" (adoc-re-cell-specifier) "\\)" "\\(|\\)"
                 "\\(?:[^|\n]*?[ \t]" "\\(" (adoc-re-cell-specifier) "\\)" "\\(|\\)" "\\)?\\)?\\)?")
         '(1 '(face adoc-delimiter adoc-reserved block-del) nil t) '(2 '(face adoc-table-del adoc-reserved block-del) nil t)
         '(3 '(face adoc-delimiter adoc-reserved block-del) nil t) '(4 '(face adoc-table-del adoc-reserved block-del) nil t)
         '(5 '(face adoc-delimiter adoc-reserved block-del) nil t) '(6 '(face adoc-table-del adoc-reserved block-del) nil t)
         '(7 '(face adoc-delimiter adoc-reserved block-del) nil t) '(8 '(face adoc-table-del adoc-reserved block-del) nil t))
   

   ;; attribute entry
   ;; ------------------------------
   (list (adoc-re-attribute-entry) '(1 adoc-delimiter) '(2 adoc-secondary-text nil t))


   ;; attribute list
   ;; ----------------------------------

   ;; --- special attribute lists
   ;; quote/verse
   (list (concat
          "^\\("
            "\\(\\[\\)"
            "\\(quote\\|verse\\)"
            "\\(?:\\(,\\)\\(.*?\\)\\(?:\\(,\\)\\(.*?\\)\\)?\\)?"
            "\\(\\]\\)"
          "\\)[ \t]*$")
         '(1 '(face nil adoc-reserved block-del)) ; whole match
         '(2 adoc-hide-delimiter)         ; [
         '(3 adoc-delimiter)              ;   quote|verse
         '(4 adoc-hide-delimiter nil t)   ;   ,
         '(5 adoc-secondary-text nil t)   ;   attribution(author)
         '(6 adoc-delimiter nil t)        ;   ,
         '(7 adoc-secondary-text nil t)   ;   cite title
         '(8 adoc-hide-delimiter))        ; ]
   ;; admonition block
   (list "^\\(\\[\\(?:CAUTION\\|WARNING\\|IMPORTANT\\|TIP\\|NOTE\\)\\]\\)[ \t]*$"
         '(1 '(face adoc-complex-replacement adoc-reserved block-del)))
   ;; block id
   (list `(lambda (end) (adoc-kwf-std end ,(adoc-re-anchor 'block-id) '(0)))
   	 '(0 '(face markup-meta-face adoc-reserved block-del))
   	 '(1 markup-anchor-face t)
   	 '(2 markup-secondary-text-face t t))

   ;; --- general attribute list block element
   ;; ^\[(?P<attrlist>.*)\]$
   (list '(lambda (end) (adoc-kwf-std end "^\\(\\[\\(.*\\)\\]\\)[ \t]*$" '(0)))
         '(1 '(face markup-meta-face adoc-reserved block-del))
   	 '(2 '(face markup-meta-face adoc-attribute-list t)))


   ;; block title
   ;; -----------------------------------
   (adoc-kw-block-title)


   ;; paragraphs
   ;; --------------------------
   (adoc-kw-verbatim-paragraph-sequence)
   (adoc-kw-admonition-paragraph)
   (list "^[ \t]+$" '(0 '(face nil adoc-reserved block-del) t))

   ;; Inline substitutions
   ;; ==========================================
   ;; Inline substitutions within block elements are performed in the
   ;; following default order:
   ;; -. Passtrough stuff removal (seen in asciidoc source)
   ;; 1. Special characters
   ;; 2. Quotes
   ;; 3. Special words
   ;; 4. Replacements
   ;; 5. Attributes
   ;; 6. Inline Macros
   ;; 7. Replacements2


   ;; (passthrough stuff removal)
   ;; ------------------------
   ;; todo. look in asciidoc source how exactly asciidoc does it
   ;; 1) BUG: actually only ifdef::no-inline-literal[]
   ;; 2) TODO: in asciidod.conf (but not yet here) also in inline macro section

   ;; AsciiDoc Manual: constitutes an inline literal passthrough. The enclosed
   ;; text is rendered in a monospaced font and is only subject to special
   ;; character substitution.
   (adoc-kw-quote 'adoc-constrained "`" markup-typewriter-face nil nil t)     ;1)
   ;; AsciiDoc Manual: The triple-plus passthrough is functionally identical to
   ;; the pass macro but you don’t have to escape ] characters and you can
   ;; prefix with quoted attributes in the inline version
   (adoc-kw-quote 'adoc-unconstrained "+++" markup-typewriter-face nil nil t) ;2)
   ;;The double-dollar passthrough is functionally identical to the triple-plus
   ;;passthrough with one exception: special characters are escaped.
   (adoc-kw-quote 'adoc-unconstrained "$$" markup-typewriter-face nil nil t)  ;2)
   ;; todo: add pass:[...], latexmath:[...], asciimath[...]

   ;; special characters
   ;; ------------------
   ;; no highlighting for them, since they are a property of the backend markup,
   ;; not of AsciiDoc syntax


   ;; quotes: unconstrained and constrained
   ;; order given by asciidoc.conf
   ;; ------------------------------
   (adoc-kw-quote 'adoc-unconstrained "**" markup-strong-face)
   (adoc-kw-quote 'adoc-constrained "*" markup-strong-face)
   (adoc-kw-quote 'adoc-constrained "``" nil adoc-replacement "''") ; double quoted text
   (adoc-kw-quote 'adoc-constrained "'" markup-emphasis-face)	   ; single quoted text
   (adoc-kw-quote 'adoc-constrained "`" nil adoc-replacement "'")
   ;; `...` , +++...+++, $$...$$ are within passthrough stuff above
   (adoc-kw-quote 'adoc-unconstrained "++" markup-typewriter-face) ; AsciiDoc manual: really onl '..are rendered in a monospaced font.'
   (adoc-kw-quote 'adoc-constrained "+" markup-typewriter-face) 
   (adoc-kw-quote 'adoc-unconstrained  "__" markup-emphasis-face)
   (adoc-kw-quote 'adoc-constrained "_" markup-emphasis-face)
   (adoc-kw-quote 'adoc-unconstrained "##" markup-gen-face) ; unquoted text
   (adoc-kw-quote 'adoc-constrained "#" markup-gen-face)    ; unquoted text
   (adoc-kw-quote 'adoc-unconstrained "~" (adoc-facespec-subscript)) ; subscript
   (adoc-kw-quote 'adoc-unconstrained "^" (adoc-facespec-superscript)) ; superscript
    

   ;; special words
   ;; --------------------
   ;; there are no default special words to highlight


   ;; replacements
   ;; --------------------------------
   ;; Asciidoc.conf surounds em dash with thin spaces. I think that does not
   ;; make sense here, all that spaces you would see in the buffer would at best
   ;; be confusing.
   (adoc-kw-replacement "\\((C)\\)" "\u00A9")
   (adoc-kw-replacement "\\((R)\\)" "\u00AE")
   (adoc-kw-replacement "\\((TM)\\)" "\u2122")
   ;; (^-- )=&#8212;&#8201;
   ;; (\n-- )|( -- )|( --\n)=&#8201;&#8212;&#8201;
   ;; (\w)--(\w)=\1&#8212;\2
   (adoc-kw-replacement "^\\(--\\)[ \t]" "\u2014") ; em dash. See also above
   (adoc-kw-replacement "[ \t]\\(--\\)\\(?:[ \t]\\|$\\)" "\u2014") ; dito
   (adoc-kw-replacement "[a-zA-Z0-9_]\\(--\\)[a-zA-Z0-9_]" "\u2014") ; dito
   (adoc-kw-replacement "[a-zA-Z0-9_]\\('\\)[a-zA-Z0-9_]" "\u2019") ; punctuation apostrophe
   (adoc-kw-replacement "\\(\\.\\.\\.\\)" "\u2026") ; ellipsis
   (adoc-kw-replacement "\\(->\\)" "\u2192")
   (adoc-kw-replacement "\\(=>\\)" "\u21D2")
   (adoc-kw-replacement "\\(<-\\)" "\u2190")
   (adoc-kw-replacement "\\(<=\\)" "\u21D0") 
   ;; general character entity reference
   ;; (?<!\\)&amp;([:_#a-zA-Z][:_.\-\w]*?;)=&\1
   (adoc-kw-replacement "\\(&[:_#a-zA-Z]\\(?:[-:_.]\\|[a-zA-Z0-9_]\\)*?;\\)" 'adoc-entity-to-string)

   ;; attributes
   ;; ---------------------------------
   ;; attribute refrence
   (cons "{\\(\\w+\\(?:\\w*\\|-\\)*\\)\\([=?!#%@$][^}\n]*\\)?}" 'adoc-replacement) 


   ;; inline macros (that includes anchors, links, footnotes,....)
   ;; ------------------------------
   ;; todo: make adoc-kw-... macros to have less redundancy
   ;; Note: Some regexp/kewyords are within the macro section 
   ;; TODO:
   ;; - allow multiline
   ;; - currently escpapes are not looked at
   ;; - adapt to the adoc-reserved scheme
   ;; - same order as in asciidoc.conf (is that in 'reverse'? cause 'default syntax' comes first)

   ;; Macros using default syntax, but having special highlighting in adoc-mode
   (adoc-kw-inline-macro-urls-no-attribute-list)
   (adoc-kw-inline-macro-urls-attribute-list)
   (adoc-kw-inline-macro "anchor" nil nil nil markup-anchor-face t '("xreflabel"))
   (adoc-kw-inline-macro "image" nil nil markup-complex-replacement-face markup-internal-reference-face t
     '("alt"))
   (adoc-kw-inline-macro "xref" nil nil nil '(markup-reference-face markup-internal-reference-face) t
     '(("caption") (("caption" . markup-reference-face))))
   (adoc-kw-inline-macro "footnote" t nil nil nil nil markup-secondary-text-face)
   (adoc-kw-inline-macro "footnoteref" t 'single-attribute nil nil nil
    '(("id") (("id" . markup-internal-reference-face))))
   (adoc-kw-inline-macro "footnoteref" t nil nil nil nil '("id" "text"))
   (adoc-kw-standalone-urls)

   ;; Macros using default syntax and having default highlighting in adoc-mod
   (adoc-kw-inline-macro)

   ;; bibliographic anchor ala [[[id]]]
   ;; actually in AsciiDoc the part between the innermost brackets is an
   ;; attribute list, for simplicity adoc-mode doesn't really treat it as such.
   ;; The attrib list can only contain one element anyway.
   (list `(lambda (end) (adoc-kwf-std end ,(adoc-re-anchor 'biblio) '(1 3) '(0)))
   	 '(1 '(face markup-meta-face adoc-reserved t) t)  ; [[
   	 '(2 markup-gen-face)				  ; [id]
	 '(3 '(face markup-meta-face adoc-reserved t) t)) ; ]]
   ;; anchor ala [[id]] or [[id,xreflabel]]
   (list `(lambda (end) (adoc-kwf-std end ,(adoc-re-anchor 'inline-special) '(1 3) '(0)))
   	 '(1 '(face markup-meta-face adoc-reserved t) t)
   	 '(2 '(face markup-meta-face adoc-attribute-list ("id" "xreflabel")) t)
	 '(3 '(face markup-meta-face adoc-reserved t) t))

   ;; see also xref: within inline macros
   ;; reference with own/explicit caption
   (list (adoc-re-xref 'inline-special-with-caption t)
         '(1 adoc-hide-delimiter)       ; <<
         '(2 adoc-delimiter)            ; anchor-id
         '(3 adoc-hide-delimiter)       ; ,
         '(4 adoc-reference)            ; link text
         '(5 adoc-hide-delimiter))      ; >>
   ;; reference without caption
   (list (adoc-re-xref 'inline-special-no-caption t)
         '(1 adoc-hide-delimiter)       ; <<
         '(2 adoc-reference)            ; link text = anchor id
         '(3 adoc-hide-delimiter))      ; >>

   ;; index terms
   ;; todo:
   ;; - copy asciidocs regexps below
   ;; - add the indexterm2?:...[...] syntax     
   ;; ifdef::asciidoc7compatible[]
   ;;   (?su)(?<!\S)[\\]?\+\+(?P<attrlist>[^+].*?)\+\+(?!\+)=indexterm
   ;;   (?<!\S)[\\]?\+(?P<attrlist>[^\s\+][^+].*?)\+(?!\+)=indexterm2
   ;; ifndef::asciidoc7compatible[]
   ;;   (?su)(?<!\()[\\]?\(\(\((?P<attrlist>[^(].*?)\)\)\)(?!\))=indexterm
   ;;   (?<!\()[\\]?\(\((?P<attrlist>[^\s\(][^(].*?)\)\)(?!\))=indexterm2
   ;; 
   (cons "(((?\\([^\\\n]\\|\\\\.\\)*?)))?" 'adoc-delimiter) 

   ;; passthrough. Note that quote section has some of them also
   ;; todo: passthrough stuff
   ;; (?su)[\\]?(?P<name>pass):(?P<subslist>\S*?)\[(?P<passtext>.*?)(?<!\\)\]=[]
   ;; (?su)[\\]?\+\+\+(?P<passtext>.*?)\+\+\+=pass[]
   ;; (?su)[\\]?\$\$(?P<passtext>.*?)\$\$=pass[specialcharacters]
   ;; # Inline literal (within ifndef::no-inline-literal[])
   ;; (?su)(?<!\w)([\\]?`(?P<passtext>\S|\S.*?\S)`)(?!\w)=literal[specialcharacters]



   ;; -- forced linebreak 
   ;; manual: A plus character preceded by at least one space character at the
   ;; end of a non-blank line forces a line break.
   ;; Asciidoc bug: If has that affect also on a non blank line.
   ;; todo: what kind of element is that? Really text formatting? Its not in asciidoc.conf
   (list "^.*[^ \t\n].*[ \t]\\(\\+\\)[ \t]*$" '(1 adoc-delimiter)) ; bug: only if not adoc-reserved

   ;; -- callout anchors (references are within list)
   ;; commented out because they are only witin (literal?) blocks
   ;; asciidoc.conf: [\\]?&lt;(?P<index>\d+)&gt;=callout
   ;; (list "^\\(<\\)\\([0-9+]\\)\\(>\\)" '(1 adoc-delimiter) '(3 adoc-delimiter))


   ;; Replacements2
   ;; -----------------------------
   ;; there default replacements2 section is empty


   ;; misc 
   ;; ------------------------------

   ;; -- misc 
   (adoc-kw-first-whites-fixed-width)

   ;; -- warnings 
   ;; todo: add tooltip explaining what is the warning all about
   ;; bogous 'list continuation'
   (list "^\\([ \t]+\\+[ \t]*\\)$" '(1 adoc-warning t)) 
   ;; list continuation witch appends a literal paragraph. The user probably
   ;; wanted to add a normal paragraph. List paragraphs are appended
   ;; implicitely.
   (list "^\\(\\+[ \t]*\\)\n\\([ \t]+\\)[^ \t\n]" '(1 adoc-warning t) '(2 adoc-warning t)) 

   ;; content of attribute lists
   (list 'adoc-kwf-attribute-list)

   ;; cleanup
   (list 'adoc-flf-meta-face-cleanup)
   ))


;;;; interactively-callable commands
(defun adoc-show-version ()
  "Show the version number in the minibuffer."
  (interactive)
  (message "adoc-mode, version %s" adoc-mode-version))

(defun adoc-goto-ref-label (id)
  "Goto the anchor defining the id ID."
  ;; KLUDGE: Getting the default, i.e. trying to parse the xref 'at' point, is
  ;; not done nicely. backward-char 5 because the longest 'starting' of an xref
  ;; construct is 'xref:' (others are '<<'). All this fails if point is within
  ;; the id, opposed to the start the id. Or if the xref spawns over the current
  ;; line.
  (interactive (let* ((default (adoc-xref-id-at-point))
		      (default-str (if default (concat "(default " default ")") "")))
		 (list
		  (read-string
		   (concat "Goto anchor of reference/label " default-str ": ")
		   nil nil default))))
  (let ((pos (save-excursion
	       (goto-char 0)
	       (re-search-forward (adoc-re-anchor nil id) nil t))))
    (if (null pos) (error (concat "Can't find an anchor defining '" id "'")))
    (push-mark)
    (goto-char pos)))

(defun adoc-promote (&optional arg)
  "Promotes the structure at point ARG levels.

When ARG is nil (i.e. when no prefix arg is given), it defaults
to 1. When ARG is negative, level is demoted that many levels.

The intention is that the structure can be a title or a list
element or anything else which has a 'level'. However currently
it works only for titles."
  (interactive "p")
  (adoc-promote-title arg))

(defun adoc-demote (&optional arg)
  "Demotes the structure at point ARG levels.

Analogous to `adoc-promote', see there."
  (interactive "p")
  (adoc-demote-title arg))

(defun adoc-promote-title (&optional arg)
  "Promotes the title at point ARG levels.

When ARG is nil (i.e. when no prefix arg is given), it defaults
to 1. When ARG is negative, level is demoted that many levels. If
ARG is 0, see `adoc-adjust-title-del'."
  (interactive "p")
  (adoc-modify-title arg))

(defun adoc-demote-title (&optional arg)
  "Completely analgous to `adoc-promote-title'."
  (interactive "p")
  (adoc-promote-title (- arg)))

;; todo:
;; - adjust while user is typing title
;; - tempo template which uses alreay typed text to insert a 'new' title
;; - auto convert one line title to two line title. is easy&fast to type, but
;;   gives two line titles for those liking them
(defun adoc-adjust-title-del ()
  "Adjusts underline length to match the length of the title's text.

E.g. after editing a two line title, call `adoc-adjust-title-del' so
the underline has the correct length."
  (interactive)
  (adoc-modify-title))

(defun adoc-toggle-title-type (&optional type-type)
  "Toggles title's type.

If TYPE-TYPE is nil, title's type is toggled. If TYPE-TYPE is
non-nil, the sub type is toggled."
  (interactive "P") 
  (when type-type
    (setq type-type t))
  (adoc-modify-title nil nil (not type-type) type-type))

(defun adoc-calc ()
  "(Re-)calculates variables used in adoc-mode.
Needs to be called after changes to certain (customization)
variables. Mostly in order font lock highlighting works as the
new customization demands."
  (interactive)

  (when (and (null adoc-insert-replacement)
             adoc-unichar-name-resolver)
    (message "Warning: adoc-unichar-name-resolver is non-nil, but is adoc-insert-replacement is nil"))
  (when (and (eq adoc-unichar-name-resolver 'adoc-unichar-by-name)
             (null adoc-unichar-alist))
    (adoc-make-unichar-alist))

  (setq adoc-font-lock-keywords (adoc-get-font-lock-keywords))
  (when (and font-lock-mode (eq major-mode 'adoc-mode))
    (font-lock-fontify-buffer))

  (adoc-easy-menu-define))

(defun adoc-easy-menu-define()
  (easy-menu-define
    adoc-mode-menu adoc-mode-map "Menu for adoc mode"
    `("AsciiDoc"
      ["Promote" adoc-promote]
      ["Demote" adoc-demote]
      ["Toggle title type" adoc-toggle-title-type]
      ["Adjust title underline" adoc-adjust-title-del]
      ["Goto anchor" adoc-goto-ref-label]
      "---"
      ;; names|wording / rough order/ help texts are from asciidoc manual
      ("Templates / cheat sheet" 
       ("Text formatting - constrained quotes"
	:help ,adoc-help-constrained-quotes
	["_Emphasis_" tempo-template-adoc-emphasis
	 :help ,adoc-help-emphasis ]
	["*Strong*" tempo-template-adoc-strong
	 :help ,adoc-help-strong ]
	["+Monospaced+" tempo-template-adoc-monospace
	 :help ,adoc-help-monospace]
	["`Monospaced literal`" tempo-template-adoc-monospace-literal ; redundant to the one in the passthrough section
	 :help ,adoc-help-monospace-literal]
	["`Single quote'" tempo-template-adoc-single-quote
	 :help ,adoc-help-single-quote] 
	["``Double quote''" tempo-template-adoc-double-quote
	 :help ,adoc-help-double-quote]
	;; todo: insert underline, overline, strikethrough, big, small
	["[attributes]##text##" tempo-template-adoc-attributed
	 :help ,adoc-help-attributed]) 
       ("Text formatting - unconstrained quotes"
	:help ,adoc-help-unconstrained-quotes
	["^Superscript^" tempo-template-adoc-superscript]
	["~Subscript~" tempo-template-adoc-subscript]
	["__Emphasis__" tempo-template-adoc-emphasis-uc
	 :help ,adoc-help-emphasis ]
	["**Strong**" tempo-template-adoc-strong-uc
	 :help ,adoc-help-strong ]
	["++Monospaced++" tempo-template-adoc-monospace-uc
	 :help ,adoc-help-monospace]
	["[attributes]##text##" tempo-template-adoc-attributed-uc
	 :help ,adoc-help-attributed])
       ("Text formatting - misc"
	["Line break: <SPC>+<NEWLINE>" tempo-template-adoc-line-break
	 :help ,adoc-help-line-break]
	["Page break: <<<" tempo-template-adoc-page-break
	 :help ,adoc-help-page-break]
	["Ruler line: ---" tempo-template-adoc-ruler-line
	 :help ,adoc-help-ruler-line])
       ("Text formatting - replacements"
	["Copyright: (C) \u2192 \u00A9" tempo-template-adoc-copyright]
	["Trademark: (TM) \u2192 \u2122" tempo-template-adoc-trademark]
	["Registered trademark: (R) \u2192 \u00AE" tempo-template-adoc-registered-trademark]
	["Dash: -- \u2192 \u2014" tempo-template-adoc-dash]
	["Ellipsis: ... \u2192 \u2026" tempo-template-adoc-ellipsis]
	["Right arrow: -> \u2192 \u2192" tempo-template-adoc-right-arrow]
	["Left arrow: <- \u2192 \u2190" tempo-template-adoc-left-arrow]
	["Right double arrow: => \u2192 \u21D2" tempo-template-adoc-right-double-arrow]
	["Left double arrow: <= \u2192 \u21D0" tempo-template-adoc-left-double-arrow]
	"---"
	["Character entity reference: &...;" tempo-template-adoc-entity-reference
	 :help ,adoc-help-entity-reference])
       ("Titles"
	[,(concat "Document title (level 0): " (adoc-template-str-title 0))
	 tempo-template-adoc-title-1]
	[,(concat "Section title (level 1): " (adoc-template-str-title 1))
	 tempo-template-adoc-title-2]
	[,(concat "Section title (level 2): " (adoc-template-str-title 2))
	 tempo-template-adoc-title-3]
	[,(concat "Section title (level 3): " (adoc-template-str-title 3))
	 tempo-template-adoc-title-4]
	[,(concat "Section title (level 4): " (adoc-template-str-title 4))
	 tempo-template-adoc-title-5]
	["Block title: .foo" tempo-template-adoc-block-title]
	["BlockId: [[id]]" tempo-template-adoc-anchor]) ; redundant to anchor below
       ("Paragraphs"
	["Literal paragraph" tempo-template-adoc-literal-paragraph
	 :help ,adoc-help-literal-paragraph]
	"---"
	["TIP: " tempo-template-adoc-paragraph-tip]
	["NOTE: " tempo-template-adoc-paragraph-note]
	["IMPORTANT: " tempo-template-adoc-paragraph-important]
	["WARNING: " tempo-template-adoc-paragraph-warning]
	["CAUTION: " tempo-template-adoc-paragraph-caution])
       ("Delimited blocks"
	:help ,adoc-help-delimited-block
	;; BUG: example does not reflect the content of adoc-delimited-block-del
	["Comment: ////" tempo-template-adoc-delimited-block-comment
	 :help ,adoc-help-delimited-block-comment]
	["Passthrough: ++++" tempo-template-adoc-delimited-block-passthrough
	 :help ,adoc-help-delimited-block-passthrouh]
	["Listing: ----" tempo-template-adoc-delimited-block-listing
	 :help ,adoc-help-delimited-block-listing]
	["Literal: ...." tempo-template-adoc-delimited-block-literal
	 :help ,adoc-help-delimited-block-literal]
	["Quote: ____" tempo-template-adoc-delimited-block-quote
	 :help ,adoc-help-delimited-block-quote]
	["Example: ====" tempo-template-adoc-delimited-block-example
	 :help ,adoc-help-delimited-block-example]
	["Sidebar: ****" tempo-template-adoc-delimited-block-sidebar
	 :help ,adoc-help-delimited-block-sidebar]
	["Open: --" tempo-template-adoc-delimited-block-open-block
	 :help ,adoc-help-delimited-block-open-block])
       ("Lists"
	:help ,adoc-help-list
	("Bulleted"
	 :help ,adoc-help-bulleted-list
	 ["Item: -" tempo-template-adoc-bulleted-list-item-1]
	 ["Item: **" tempo-template-adoc-bulleted-list-item-2]
	 ["Item: ***" tempo-template-adoc-bulleted-list-item-3]
	 ["Item: ****" tempo-template-adoc-bulleted-list-item-4]
	 ["Item: *****" tempo-template-adoc-bulleted-list-item-5])
	("Numbered - explicit"
	 ["Arabic (decimal) numbered item: 1." tempo-template-adoc-numbered-list-item]
	 ["Lower case alpha (letter) numbered item: a." tempo-template-adoc-numbered-list-item]
	 ["Upper case alpha (letter) numbered item: A." tempo-template-adoc-numbered-list-item]
	 ["Lower case roman numbered list item: i)" tempo-template-adoc-numbered-list-item-roman]
	 ["Upper case roman numbered list item: I)" tempo-template-adoc-numbered-list-item-roman])
	("Numbered - implicit"
	 ["Arabic (decimal) numbered item: ." tempo-template-adoc-implicit-numbered-list-item-1]
	 ["Lower case alpha (letter) numbered item: .." tempo-template-adoc-implicit-numbered-list-item-2]
	 ["Upper case alpha (letter)numbered item: ..." tempo-template-adoc-implicit-numbered-list-item-3]
	 ["Lower case roman numbered list item: ...." tempo-template-adoc-implicit-numbered-list-item-4]
	 ["Upper case roman numbered list item: ....." tempo-template-adoc-implicit-numbered-list-item-5])
	["Labeled item: label:: text" tempo-template-adoc-labeled-list-item]
	["List item continuation: <NEWLINE>+<NEWLINE>" tempo-template-adoc-list-item-continuation
	 :help ,adoc-help-list-item-continuation])
       ("Tables"
	:help ,adoc-help-table
        ["Example table" tempo-template-adoc-example-table])
       ("Macros (inline & block)"
	:help ,adoc-help-macros
	["URL: http://foo.com" tempo-template-adoc-url
	 :help ,adoc-help-url]
	["URL with caption: http://foo.com[caption]" tempo-template-adoc-url-caption
	 :help ,adoc-help-url]
	["EMail: bob@foo.com" tempo-template-adoc-email
	 :help ,adoc-help-url]
	["EMail with caption: mailto:address[caption]" tempo-template-adoc-email-caption
	 :help ,adoc-help-url]
	["Anchor aka BlockId (syntax 1): [[id,xreflabel]]" tempo-template-adoc-anchor
	 :help ,adoc-help-anchor]
	["Anchor (syntax 2): anchor:id[xreflabel]" tempo-template-adoc-anchor-default-syntax
	 :help ,adoc-help-anchor]
	["Xref (syntax 1): <<id,caption>>" adoc-xref
	 :help ,adoc-help-xref]
	["Xref (syntax 2): xref:id[caption]" adoc-xref-default-syntax
	 :help ,adoc-help-xref]
	["Image: image:target-path[caption]" adoc-image]
	["Comment: //" tempo-template-adoc-comment
	 :help ,adoc-help-comment]
	("Passthrough macros"
	 :help adoc-help-passthrough-macros
	 ["pass:[text]" tempo-template-adoc-pass
	  :help ,adoc-help-pass]
	 ["ASCIIMath: asciimath:[text]" tempo-template-adoc-asciimath
	  :help ,adoc-help-asciimath]
	 ["LaTeX math: latexmath[text]" tempo-template-adoc-latexmath
	  :help ,adoc-help-latexmath]
	 ["+++text+++" tempo-template-adoc-pass-+++
	  :help ,adoc-help-pass-+++]
	 ["$$text$$" tempo-template-pass-$$
	  :help ,adoc-help-pass-$$]
	 ["`text`" tempo-template-monospace-literal ; redundant to the one in the quotes section
	  :help ,adoc-help-monospace-literal]))))))


;;;; tempos
;; todo: tell user to make use of tempo-interactive
;; todo: tell user to how to use tempo-snippets?? that there are clear methods
;; todo: tell user to how to use tempo-snippets?? suggested customizations working best with adoc
;; todo: after changing adoc-tempo-frwk, all adoc-tempo-define need to be
;;       evaluated again. This doesn't feel right
;; todo: titles,block titles,blockid,... should start on a new line
;; PROBLEM: snippets dont allow empty 'field', e.g. empty caption
;;       Workaround: mark whole 'edit-field' and delete it
(if (eq adoc-tempo-frwk 'tempo-snippets)
    (require 'tempo-snippets)
  (require 'tempo))

(defun adoc-tempo-define (&rest args)
  (if (eq adoc-tempo-frwk 'tempo-snippets)
      (apply 'tempo-define-snippet args)
    (apply 'tempo-define-template args)))

(defun adoc-template-str-title (&optional level title-text)
  "Returns the string tempo-template-adoc-title-x would insert"
  (with-temp-buffer
    (insert (or title-text "foo"))
    (set-mark (point-min))
    (funcall (intern-soft (concat "tempo-template-adoc-title-" (number-to-string (1+ (or level 0))))))
    (replace-regexp-in-string "\n" "\\\\n" 
			      (buffer-substring-no-properties (point-min) (point-max)))))

;; Text formatting - constrained quotes
(adoc-tempo-define "adoc-emphasis" '("_" (r "text" text) "_") nil adoc-help-emphasis)
(adoc-tempo-define "adoc-strong" '("*" (r "text" text) "*") nil adoc-help-strong)
(adoc-tempo-define "adoc-monospace" '("+" (r "text" text) "+") nil adoc-help-monospace)
(adoc-tempo-define "adoc-monospace-literal" '("`" (r "text" text) "`"))
(adoc-tempo-define "adoc-single-quote" '("`" (r "text" text) "'") nil adoc-help-single-quote)
(adoc-tempo-define "adoc-double-quote" '("``" (r "text" text) "''") nil adoc-help-double-quote)
(adoc-tempo-define "adoc-attributed" '("[" p "]#" (r "text" text) "#") nil adoc-help-double-quote)

;; Text formatting - unconstrained quotes
(adoc-tempo-define "adoc-emphasis-uc" '("__" (r "text" text) "__") nil adoc-help-emphasis)
(adoc-tempo-define "adoc-strong-uc" '("**" (r "text" text) "**") nil adoc-help-strong)
(adoc-tempo-define "adoc-monospace-uc" '("++" (r "text" text) "++") nil adoc-help-monospace)
(adoc-tempo-define "adoc-attributed-uc" '("[" p "]##" (r "text" text) "##") nil adoc-help-attributed)
(adoc-tempo-define "adoc-superscript" '("^" (r "text" text) "^"))
(adoc-tempo-define "adoc-subscript" '("~" (r "text" text) "~"))

;; Text formatting - misc
(adoc-tempo-define "adoc-line-break" '((if (looking-back " ") "" " ") "+" %) nil adoc-help-line-break)
(adoc-tempo-define "adoc-page-break" '(bol "<<<" %) nil adoc-help-page-break)
(adoc-tempo-define "adoc-ruler-line" '(bol "---" %) nil adoc-help-ruler-line)

;; Text formatting - replacements
(adoc-tempo-define "adoc-copyright" '("(C)"))
(adoc-tempo-define "adoc-trademark" '("(T)"))
(adoc-tempo-define "adoc-registered-trademark" '("(R)"))
(adoc-tempo-define "adoc-dash" '("---"))
(adoc-tempo-define "adoc-ellipsis" '("..."))
(adoc-tempo-define "adoc-right-arrow" '("->"))
(adoc-tempo-define "adoc-left-arrow" '("<-"))
(adoc-tempo-define "adoc-right-double-arrow" '("=>"))
(adoc-tempo-define "adoc-left-double-arrow" '("<="))
(adoc-tempo-define "adoc-entity-reference" '("&" r ";") nil adoc-help-entity-reference)

;; Titles
;; todo
;; - merge with adoc-make-title
;; - dwim:
;;   - when point is on a text line, convert that line to a title
;;   - when it is already a title .... correct underlines?
;;   - ensure n blank lines before and m blank lines after title, or unchanged if n/m nil
(dotimes (level 5) ; level starting at 0
  (let ((one-line-del (make-string (1+ level) ?\=)))

    (adoc-tempo-define
     (concat "adoc-title-" (number-to-string (1+ level)))
     ;; see adoc-tempo-handler for what the (tr ...) does.
     (list
      `(cond
	((eq adoc-title-style 'adoc-title-style-one-line)
	 '(tr bol ,one-line-del " " (r "text" text)))
	((eq adoc-title-style 'adoc-title-style-one-line-enclosed)
	 '(tr bol ,one-line-del " " (r "text" text) " " ,one-line-del))
	;; BUG in tempo: when first thing is a tempo element which introduces a marker, that
	;; marker is skipped
	((eq adoc-title-style 'adoc-title-style-two-line)
	 '(tr bol (r "text" text) "\n"
	      (adoc-make-two-line-title-underline ,level (if on-region (- tempo-region-stop tempo-region-start)))))
	(t
	 (error "Unknown title style"))))
     nil
     (concat
      "Inserts a level " (number-to-string (1+ level)) " (starting at 1) title.
Is influenced by customization variables such as `adoc-title-style'."))))

(adoc-tempo-define "adoc-block-title" '(bol "." (r "text" text) %))

;; Paragraphs
(adoc-tempo-define "adoc-literal-paragraph" '(bol "  " (r "text" text) %) nil adoc-help-literal-paragraph)
(adoc-tempo-define "adoc-paragraph-tip" '(bol "TIP: " (r "text" text) %))
(adoc-tempo-define "adoc-paragraph-note" '(bol "NOTE: " (r "text" text) %))
(adoc-tempo-define "adoc-paragraph-important" '(bol "IMPORTANT: " (r "text" text) %))
(adoc-tempo-define "adoc-paragraph-warning" '(bol "WARNING: " (r "text" text) %))
(adoc-tempo-define "adoc-paragraph-caution" '(bol "CAUTION: " (r "text" text) %))

;; delimited blocks
(adoc-tempo-define "adoc-delimited-block-comment" 
  '(bol (make-string 50 ?/) n (r-or-n "text" text) bol (make-string 50 ?/) %)
  nil adoc-help-delimited-block-comment)
(adoc-tempo-define "adoc-delimited-block-passthrough"
 '(bol (make-string 50 ?+) n (r-or-n "text" text) bol (make-string 50 ?+) %)
 nil adoc-help-delimited-block-passthrouh)
(adoc-tempo-define "adoc-delimited-block-listing"
  '(bol (make-string 50 ?-) n (r-or-n "text" text) bol (make-string 50 ?-) %)
  nil adoc-help-delimited-block-listing)
(adoc-tempo-define "adoc-delimited-block-literal"
  '(bol (make-string 50 ?.) n (r-or-n "text" text) bol (make-string 50 ?.) %)
  nil adoc-help-delimited-block-literal)
(adoc-tempo-define "adoc-delimited-block-quote"
  '(bol (make-string 50 ?_) n (r-or-n "text" text) bol (make-string 50 ?_) %)
  nil adoc-help-delimited-block-quote)
(adoc-tempo-define "adoc-delimited-block-example"
  '(bol (make-string 50 ?=) n (r-or-n "text" text) bol (make-string 50 ?=) %)
  nil adoc-help-delimited-block-example)
(adoc-tempo-define "adoc-delimited-block-sidebar"
  '(bol (make-string 50 ?*) n (r-or-n "text" text) bol (make-string 50 ?*) %)
  nil adoc-help-delimited-block-sidebar)
(adoc-tempo-define "adoc-delimited-block-open-block"
  '(bol "--" n (r-or-n "text" text) bol "--" %)
  nil adoc-help-delimited-block-open-block)

;; Lists
;; todo: customize indentation
(adoc-tempo-define "adoc-bulleted-list-item-1" '(bol (adoc-insert-indented "- " 1) (r "text" text)))
(adoc-tempo-define "adoc-bulleted-list-item-2" '(bol (adoc-insert-indented "** " 2) (r "text" text)))
(adoc-tempo-define "adoc-bulleted-list-item-3" '(bol (adoc-insert-indented "*** " 3) (r "text" text)))
(adoc-tempo-define "adoc-bulleted-list-item-4" '(bol (adoc-insert-indented "**** " 4) (r "text" text)))
(adoc-tempo-define "adoc-bulleted-list-item-5" '(bol (adoc-insert-indented "***** " 5) (r "text" text)))
(adoc-tempo-define "adoc-numbered-list-item" '(bol (p "number" number) ". " (r "text" text)))
(adoc-tempo-define "adoc-numbered-list-item-roman" '(bol (p "number" number) ") " (r "text" text)))
(adoc-tempo-define "adoc-implicit-numbered-list-item-1" '(bol (adoc-insert-indented ". " 1) (r "text" text)))
(adoc-tempo-define "adoc-implicit-numbered-list-item-2" '(bol (adoc-insert-indented ".. " 2) (r "text" text)))
(adoc-tempo-define "adoc-implicit-numbered-list-item-3" '(bol (adoc-insert-indented "... " 3) (r "text" text)))
(adoc-tempo-define "adoc-implicit-numbered-list-item-4" '(bol (adoc-insert-indented ".... " 4) (r "text" text)))
(adoc-tempo-define "adoc-implicit-numbered-list-item-5" '(bol (adoc-insert-indented "..... " 5) (r "text" text)))
(adoc-tempo-define "adoc-labeled-list-item" '(bol (p "label" label) ":: " (r "text" text)))
(adoc-tempo-define "adoc-list-item-continuation" '(bol "+" %) nil adoc-help-list-item-continuation)

;; tables
(adoc-tempo-define "adoc-example-table"
  '(bol "|====================\n" 
    "| cell 11 | cell 12\n"
    "| cell 21 | cell 22\n"
    "|====================\n" % ))

;; Macros (inline & block)
(adoc-tempo-define "adoc-url" '("http://foo.com") nil adoc-help-url)
(adoc-tempo-define "adoc-url-caption" '("http://foo.com[" (r "caption" caption) "]") nil adoc-help-url)
(adoc-tempo-define "adoc-email" '("bob@foo.com") nil adoc-help-url)
(adoc-tempo-define "adoc-email-caption" '("mailto:" (p "address" address) "[" (r "caption" caption) "]") nil adoc-help-url)
(adoc-tempo-define "adoc-anchor" '("[[" (r "id" id) "]]") nil adoc-help-anchor)
(adoc-tempo-define "adoc-anchor-default-syntax" '("anchor:" (r "id" id) "[" (p "xreflabel" xreflabel) "]") nil adoc-help-anchor)
(adoc-tempo-define "adoc-xref" '("<<" (p "id" id) "," (r "caption" caption) ">>") nil adoc-help-xref)
(adoc-tempo-define "adoc-xref-default-syntax" '("xref:" (p "id" id) "[" (r "caption" caption) "]") nil adoc-help-xref)
(adoc-tempo-define "adoc-image" '("image:" (r "target-path" target-path) "[" (p "caption" caption) "]"))

;; Passthrough
(adoc-tempo-define "adoc-pass" '("pass:[" (r "text" text) "]") nil adoc-help-pass)
(adoc-tempo-define "adoc-asciimath" '("asciimath:[" (r "text" text) "]") nil adoc-help-asciimath)
(adoc-tempo-define "adoc-latexmath" '("latexmath:[" (r "text" text) "]") nil adoc-help-latexmath)
(adoc-tempo-define "adoc-pass-+++" '("+++" (r "text" text) "+++") nil adoc-help-pass-+++)
(adoc-tempo-define "adoc-pass-$$" '("$$" (r "text" text) "$$") nil adoc-help-pass-$$)
; backticks handled in tempo-template-adoc-monospace-literal


;;;; misc
(defun adoc-insert-indented (str indent-level)
  "Indents and inserts STR such that point is at INDENT-LEVEL."
  (indent-to (- (* tab-width indent-level) (length str)))
  (insert str))

(defun adoc-repeat-string (str n)
  "Returns str n times concatenated"
  (let ((retval ""))
    (dotimes (i n)
      (setq retval (concat retval str)))
    retval))

(defun adoc-tempo-handler (element)
  "Tempo user element handler, see `tempo-user-elements'."
  (let ((on-region (adoc-tempo-on-region)))
    (cond

     ;; tr / tempo-recurse : tempo-insert the remaining args of the list
     ((and (listp element)
	   (memq (car element) '(tr tempo-recurse)))
      (mapc (lambda (elt) (tempo-insert elt on-region)) (cdr element))
      "")

     ;; bol: ensure point is at the beginning of a line by inserting a newline if needed
     ((eq element 'bol)
      (if (bolp) "" "\n"))
     
     ;; r-or-n
     ((eq element 'r-or-n)
      (if on-region 'r '(tr p n)))
     ;; (r-or-n ...)
     ((and (consp element)
	   (eq (car element) 'r-or-n)) 
      (if on-region (cons 'r (cdr element)) '(tr p n))))))

(add-to-list 'tempo-user-elements 'adoc-tempo-handler)

(defun adoc-tempo-on-region ()
  "Guesses the on-region argument `tempo-insert' is given.

Is a workaround the problem that tempo's user handlers don't get
passed the on-region argument."
  (let* (
	 ;; try to determine the arg with which the tempo-template-xxx was
	 ;; called that eventually brought us here. If we came here not by an
	 ;; interactive call to tempo-template-xxx we can't have a clue - assume
	 ;; nil.
	 (arg (if (string-match "^tempo-template-" (symbol-name this-command))
		  current-prefix-arg
		nil)) 
	 ;; copy from tempo-define-template
	 (on-region (if tempo-insert-region
			(not arg)
		      arg)))
    ;; copy from tempo-insert-template
    (if (or (and (boundp 'transient-mark-mode) ; For Emacs
		 transient-mark-mode
		 mark-active)
	    (if (featurep 'xemacs)
		(and zmacs-regions (mark))))
	(setq on-region t))
    on-region))

(defun adoc-forward-xref (&optional bound)
  "Move forward to next xref and return it's id.

Match data is the one of the found xref. Returns nil if there was
no xref found."
  (cond
   ((or (re-search-forward (adoc-re-xref 'inline-special-with-caption) bound t)
	(re-search-forward (adoc-re-xref 'inline-special-no-caption) bound t))
    (match-string-no-properties 2))
   ((re-search-forward (adoc-re-xref 'inline-general-macro) bound t)
    (match-string-no-properties 3))
   (t nil)))

(defun adoc-xref-id-at-point ()
  "Returns id referenced by the xref point is at.

Returns nil if there was no xref found."
  (save-excursion
    ;; search the xref within +-1 one line. I.e. if the xref spawns more than
    ;; two lines, it wouldn't be found.
    (let ((id)
	  (saved-point (point))
	  (end (save-excursion (forward-line 1) (line-end-position))))
      (forward-line -1)
      (while (and (setq id (adoc-forward-xref end))
		  (or (< saved-point (match-beginning 0))
		      (> saved-point (match-end 0)))))
      id)))

(defun adoc-title-descriptor()
  "Returns title descriptor of title point is in.

Title descriptor looks like this: (TYPE SUB-TYPE LEVEL TEXT START END)

0 TYPE: 1 fore one line title, 2 for two line title.

1 SUB-TYPE: Only applicable for one line title: 1 for only
starting delimiter ('== my title'), 2 for both starting and
trailing delimiter ('== my title ==').

2 LEVEL: Level of title. A value between 0 and
`adoc-title-max-level' inclusive.

3 TEXT: Title's text

4 START / 5 END: Start/End pos of match"
  (save-excursion 
    (let ((level 0)
          found
          type sub-type text)
      (beginning-of-line)
      (while (and (not found) (<= level adoc-title-max-level))
        (cond
         ((looking-at (adoc-re-one-line-title level))
          (setq type 1)
          (setq text (match-string 2))
          (setq sub-type (if (< 0 (length (match-string 3))) 2 1))
          (setq found t))
         ;; WARNING: if you decide to replace adoc-re-two-line-title with a
         ;; method ensuring the correct length of the underline, be aware that
         ;; due to adoc-adjust-title-del we sometimes want to find a title which has
         ;; the wrong underline length.
         ((or (looking-at (adoc-re-two-line-title (nth level adoc-two-line-title-del)))
	      (save-excursion
		(forward-line -1)
		(beginning-of-line)
		(looking-at (adoc-re-two-line-title (nth level adoc-two-line-title-del)))))
          (setq type 2)
          (setq text (match-string 2))
          (setq found t))
         (t
          (setq level (+ level 1)))))        
      (when found
        (list type sub-type level text (match-beginning 0) (match-end 0))))))

(defun adoc-make-title (descriptor)
  (let ((type (nth 0 descriptor))
        (sub-type (nth 1 descriptor))
        (level (nth 2 descriptor))
        (text (nth 3 descriptor)))
    (if (eq type 1)
        (adoc-make-one-line-title sub-type level text)
      (adoc-make-two-line-title level text))))

(defun adoc-modify-title (&optional new-level-rel new-level-abs new-type new-sub-type create)
  "Modify properties of title point is on.

NEW-LEVEL-REL defines the new title level relative to the current
one. Negative values are allowed. 0 or nil means don't change.
NEW-LEVEL-ABS defines the new level absolutely. When both
NEW-LEVEL-REL and NEW-LEVEL-ABS are non-nil, NEW-LEVEL-REL takes
precedence. When both are nil, level is not affected.

When ARG is nil, it defaults to 1. When ARG is negative, level is
demoted that many levels. If ARG is 0, see `adoc-adjust-title-del'.

When NEW-TYPE is nil, the title type is unaffected. If NEW-TYPE
is t, the type is toggled. If it's 1 or 2, the new type is one
line title or two line title respectively.

NEW-SUB-TYPE is analogous to NEW-TYPE. However when the actual
title has no sub type, only the absolute values of NEW-SUB-TYPE
apply, otherise the new sub type becomes
`adoc-default-title-sub-type'.

If CREATE is nil, an error is signaled if point is not on a
title. If CREATE is non-nil a new title is created if point is
currently not on a title.

BUG: In one line title case: number of spaces between delimiters
and title's text are not preserved, afterwards its always one space."
  (let ((descriptor (adoc-title-descriptor)))
    (if (or create (not descriptor))
        (error "Point is not on a title"))

    ;; todo: set descriptor to default
    ;; (if (not descriptor)
    ;;     (setq descriptor (list 1 1 2 ?? adoc-default-title-type adoc-default-title-sub-type)))
    (let* ((type (nth 0 descriptor))
           (new-type-val (cond
			  ((eq new-type 1) 2)
			  ((eq new-type 2) 1)
			  ((not (or (eq type 1) (eq type 2)))
			   (error "Invalid title type"))
			  ((eq new-type nil) type)
			  ((eq new-type t) (if (eq type 1) 2 1))
			  (t (error "NEW-TYPE has invalid value"))))
           (sub-type (nth 1 descriptor))
           (new-sub-type-val (cond
			      ((eq new-sub-type 1) 2)
			      ((eq new-sub-type 2) 1)
			      ((null sub-type) adoc-default-title-sub-type) ; there wasn't a sub-type before
			      ((not (or (eq sub-type 1) (eq sub-type 2)))
			       (error "Invalid title sub-type"))
			      ((eq new-sub-type nil) sub-type)
			      ((eq new-sub-type t) (if (eq sub-type 1) 2 1))
			      (t (error "NEW-SUB-TYPE has invalid value"))))           
           (level (nth 2 descriptor))
           (new-level (cond
		       ((or (null new-level-rel) (eq new-level-rel 0))
			level)
		       ((not (null new-level-rel))
			(let ((x (% (+ level arg) (+ adoc-title-max-level 1))))
			  (if (< x 0)
			      (+ x adoc-title-max-level 1)
			    x)))
		       ((not (null new-level-abs))
			new-level-abs)
		       (t
			level)))
           (start (nth 4 descriptor))
           (end (nth 5 descriptor))
           (saved-col (current-column)))
      
      ;; set new title descriptor
      (setcar (nthcdr 0 descriptor) new-type-val)
      (setcar (nthcdr 1 descriptor) new-sub-type-val)
      (setcar (nthcdr 2 descriptor) new-level)

      ;; replace old title by new
      (let ((end-char (char-before end)))
	(beginning-of-line)
	(when (and (eq type 2) (looking-at (adoc-re-two-line-title-undlerline)))
	  (forward-line -1)
	  (beginning-of-line))
	(delete-region start end)
	(insert (adoc-make-title descriptor))
	(when (equal end-char ?\n)
	  (insert  "\n")
	  (forward-line -1)))

      ;; reposition point
      (when (and (eq new-type-val 2) (eq type 1))
        (forward-line -1))
      (move-to-column saved-col))))

(defun adoc-make-unichar-alist()
  "Creates `adoc-unichar-alist' from `unicode-character-list'"
  (unless (boundp 'unicode-character-list)
    (load-library "unichars.el"))
  (let ((i unicode-character-list))
    (setq adoc-unichar-alist nil)
    (while i
      (let ((name (nth 2 (car i)))
            (codepoint (nth 0 (car i))))
        (when name
          (push (cons name codepoint) adoc-unichar-alist))
        (setq i (cdr i))))))

(defun adoc-unichar-by-name (name)
  "Returns unicode codepoint of char with the given NAME"
  (cdr (assoc name adoc-unichar-alist)))

(defun adoc-entity-to-string (entity)
  "Returns a string containing the character referenced by ENTITY.

ENTITY is a string containing a character entity reference like
e.g. '&#38;' or '&amp;'. nil is returned if its an invalid
entity, or when customizations prevent `adoc-entity-to-string' from
knowing it. E.g. when `adoc-unichar-name-resolver' is nil."
  (save-match-data
    (let (ch)
      (setq ch
        (cond
         ;; hex
         ((string-match "&#x\\([0-9a-fA-F]+?\\);" entity)
          (string-to-number (match-string 1 entity) 16))
         ;; dec
         ((string-match "&#\\([0-9]+?\\);" entity)
          (string-to-number (match-string 1 entity)))
         ;; name
         ((and adoc-unichar-name-resolver
               (string-match "&\\(.+?\\);" entity))
          (funcall adoc-unichar-name-resolver
                   (match-string 1 entity)))))
      (when (characterp ch) (make-string 1 ch)))))

(defun adoc-face-for-attribute (pos-or-name &optional attribute-list-prop-val)
  "Returns the face to be used for the given attribute.

The face to be used is looked up in `adoc-attribute-face-alist',
unless that alist is overwritten by the content of
ATTRIBUTE-LIST-PROP-VAL.

POS-OR-NAME identifies the attribute for which the face is
returned. When POS-OR-NAME satifies numberp, it is the number of
the positional attribute, where as the first positinal attribute
has position 0. Otherwise POS-OR-NAME is the name of the named
attribute.

The value of ATTRIBUTE-LIST-PROP-VAL is one of the following:
- nil
- FACE
- POS-TO-NAME
- (POS-TO-NAME LOCAL-ATTRIBUTE-FACE-ALIST)

POS-TO-NAME is a list of strings mapping positions to attribute
names. E.g. (\"foo\" \"bar\") means that the first positional
attribute corresponds to the named attribute foo, and the 2nd
positional attribute corresponds to the named attribute bar.

FACE is something that satisfies facep; in that case the whole
attribute list is fontified with that face. However that case is
handled outside this function.

An attribute name is first looked up in
LOCAL-ATTRIBUTE-FACE-ALIST before it is looked up in
`adoc-attribute-face-alist'."
  (let* ((has-pos-to-name (listp attribute-list-prop-val))
	 (has-local-alist (and has-pos-to-name (listp (car-safe attribute-list-prop-val))))
	 (pos-to-name (cond ((not has-pos-to-name) nil)
			  (has-local-alist (car attribute-list-prop-val))
			  (t attribute-list-prop-val)))
	 (local-attribute-face-alist (when has-local-alist (cadr attribute-list-prop-val)))
	 (name (cond ((stringp pos-or-name) pos-or-name)
		   ((numberp pos-or-name) (nth pos-or-name pos-to-name)))))
    (or (when name (or (cdr (assoc name local-attribute-face-alist))
		     (cdr (assoc name adoc-attribute-face-alist))))
	markup-value-face)))

(defun adoc-imenu-create-index ()
  (let* ((index-alist)
         (re-all-titles-core
          (mapconcat
           (lambda (level)
             (concat
              (adoc-re-one-line-title level)
              "\\|"
              (adoc-re-two-line-title (nth level adoc-two-line-title-del))))
           '(0 1 2 3 4)
           "\\)\\|\\(?:"))
         (re-all-titles
          (concat "\\(?:" re-all-titles-core "\\)")))
    (save-restriction
      (widen)
      (goto-char 0)
      (while (re-search-forward re-all-titles nil t)
        (backward-char) ; skip backwards the trailing \n of a title
        (let* ((descriptor (adoc-title-descriptor))
               (title-text (nth 3 descriptor))
               (title-pos (nth 4 descriptor)))
          (setq
           index-alist
           (cons (cons title-text title-pos) index-alist)))))
    (nreverse index-alist)))


;;;###autoload
(define-derived-mode adoc-mode text-mode "adoc"
  "Major mode for editing AsciiDoc text files.
Turning on Adoc mode runs the normal hook `adoc-mode-hook'."
  
  ;; syntax table
  ;; todo: do it as other modes do it, eg rst-mode?
  (modify-syntax-entry ?$ ".")
  (modify-syntax-entry ?% ".")
  (modify-syntax-entry ?& ".")
  (modify-syntax-entry ?' ".")
  (modify-syntax-entry ?` ".")
  (modify-syntax-entry ?\" ".")
  (modify-syntax-entry ?* ".")
  (modify-syntax-entry ?+ ".")
  (modify-syntax-entry ?. ".")
  (modify-syntax-entry ?/ ".")
  (modify-syntax-entry ?< ".")
  (modify-syntax-entry ?= ".")
  (modify-syntax-entry ?> ".")
  (modify-syntax-entry ?\\ ".")
  (modify-syntax-entry ?| ".")
  (modify-syntax-entry ?_ ".")

  ;; comments
  (set (make-local-variable 'comment-column) 0)
  (set (make-local-variable 'comment-start) "// ")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-start-skip) "^//[ \t]*")
  (set (make-local-variable 'comment-end-skip) "[ \t]*\\(?:\n\\|\\'\\)")
  
  ;; paragraphs
  (set (make-local-variable 'paragraph-separate) (adoc-re-paragraph-separate))
  (set (make-local-variable 'paragraph-start) (adoc-re-paragraph-start))
  (set (make-local-variable 'paragraph-ignore-fill-prefix) t)
  
  ;; font lock
  (set (make-local-variable 'font-lock-defaults)
       '(adoc-font-lock-keywords
	 nil nil nil nil
	 (font-lock-multiline . t)
	 (font-lock-mark-block-function . adoc-font-lock-mark-block-function)))
  (make-local-variable 'font-lock-extra-managed-props)
  (setq font-lock-extra-managed-props '(adoc-reserved adoc-attribute-list))
  (make-local-variable 'font-lock-unfontify-region-function)
  (setq font-lock-unfontify-region-function 'adoc-unfontify-region-function)
  
  ;; outline mode
  ;; BUG: if there are many spaces\tabs after =, level becomes wrong
  ;; Ideas make it work for two line titles: Investigate into
  ;; outline-heading-end-regexp. It seams like outline-regexp could also contain
  ;; newlines.
  (set (make-local-variable 'outline-regexp) "=\\{1,5\\}[ \t]+[^ \t\n]")
  
  ;; misc
  (set (make-local-variable 'page-delimiter) "^<<<+$")
  (set (make-local-variable 'require-final-newline) t)
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  
  ;; it's the user's decision whether he wants to set imenu-sort-function to
  ;; nil, or even something else. See also similar comment in sgml-mode.
  (set (make-local-variable 'imenu-create-index-function)
       'adoc-imenu-create-index)

  ;; compilation
  (when (boundp 'compilation-error-regexp-alist-alist)
    (add-to-list 'compilation-error-regexp-alist-alist
        '(asciidoc
          "^asciidoc: +\\(?:ERROR\\|\\(WARNING\\|DEPRECATED\\)\\): +\\([^:\n]*\\): line +\\([0-9]+\\)"
          2 3 nil (1 . nil))))
  (when (boundp 'compilation-error-regexp-alist)
    (make-local-variable 'compilation-error-regexp-alist)
    (add-to-list 'compilation-error-regexp-alist 'asciidoc))

  (easy-menu-add adoc-mode-menu))


;;;; non-definitions evaluated during load  
(adoc-calc)


(provide 'adoc-mode)

;;; adoc-mode.el ends here

