;;; markup-faces.el --- collection of faces for markup language modes
;; 
;; Copyright 2010-2013 Florian Kaufmann <sensorflo@gmail.com>
;;
;; Author: Florian Kaufmann <sensorflo@gmail.com>
;; URL: https://github.com/sensorflo/markup-faces
;; Package-Version: 20141110.817
;; Package-Commit: 98a807ed82473eb41c6a201ed7ef816d6bcd67b0
;; Version: 1.0.0
;; Created: 2010
;; Keywords: wp faces
;; 
;; This file is not part of GNU Emacs.
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;; 
;;; Commentary:
;; 
;; As font-lock-faces, but tailored for markup languages instead programming
;; languages. The sub group markup-faces-text is also intended for 'text viewing
;; modes' such as info or (wo)man. This gives a common look and feel, or let's
;; say theme, across different markup language modes and 'text viewing modes'
;; respectively.

;;; Variables:

;; todo: describe the idea of the face structure.
;; - hierarchical structure: gen for text, meta for meta
;; - within text faces, choose properties wisely so they can overlap / add on
;; - buffer face mode: distinguish between meta / text / text-typewriter
(defgroup markup-faces nil
  "Collection of faces for markup language modes and text viewing modes.

More info in the commentary section of the markup-faces library.
You can access it by typing M-x finder-commentary RET
markup-faces RET."
  :group 'faces)

;;; group markup-faces-text 
(defgroup markup-faces-text nil
  "Faces for literal text in markup languages or for text modes"
  :group 'markup-faces)

(defface markup-gen-face
  '((((background light))
     (:foreground "medium blue"))
    (((background dark))
     (:foreground "skyblue")))
  "Generic/base face for text with special formatting.

Typically `markup-title-0-face', `markup-strong-face' etc.
inherit from it. Also used for generic text that hasn't got it's
own dedicated face, e.g. if a markup command imposes arbitrary
colors/sizes/fonts upon it."
  :group 'markup-faces-text)

(defface markup-title-0-face
  '((t (:inherit markup-gen-face :height 3.0)))
  "For document's title"
  :group 'markup-faces-text)

(defface markup-title-1-face
  '((t :inherit markup-gen-face :height 2.4))
  "For level 1 (i.e. top level) chapters/sections/headings"
  :group 'markup-faces-text)

(defface markup-title-2-face
  '((t :inherit markup-gen-face :height 1.8))
  "For level 2 chapters/sections/headings"
  :group 'markup-faces-text)

(defface markup-title-3-face
  '((t :inherit markup-gen-face :height 1.4 :weight bold))
  "For level 3 chapters/sections/headings"
  :group 'markup-faces-text)

(defface markup-title-4-face
  '((t :inherit markup-gen-face :height 1.2 :slant italic))
  "For level 4 chapters/sections/headings"
  :group 'markup-faces-text)

(defface markup-title-5-face
  '((t :inherit markup-gen-face :height 1.2 :underline t))
  "For level 5 chapters/sections/headings"
  :group 'markup-faces-text)

(defface markup-emphasis-face
  '((t :inherit markup-gen-face :slant italic))
  "For emphasized text.

For example 'foo' in the following examples:
HTML: <em>foo</em>
LaTeX: \\emph{foo}
AsciiDoc: 'foo'"
  :group 'markup-faces-text)

(defface markup-strong-face
  '((t :inherit markup-gen-face :weight bold))
  "For strongly emphasized text.

For example 'foo' in the following examples:
HTML: <strong>foo</strong>
AsciiDoc: *foo*"
  :group 'markup-faces-text)

(defface markup-code-face
  '((t :inherit (fixed-pitch markup-gen-face)))
  "For text representing code/filenames/identifiers/....

Note that doesn't necessairily mean that the charachters are also
verbatim. See also `markup-verbatim-face', and
`markup-typewriter-face'.

For example 'foo' in the following examples:
HTML: <code>foo</code>
HTML: <var>foo</var>"
  :group 'markup-faces-text)

(defface markup-verbatim-face
  '((((background light))
     (:background "cornsilk"))
    (((background dark))
     (:background "saddlebrown")))
  "For verbatim text.

Verbatim in a sense that all its characters are to be taken
literally. Note that doesn't necessarily mean that that it is in
a typewritter font.

For example 'foo' in the following examples. In parantheses is a
summary what the command is for according to the given markup
language.
HTML: <pre>foo</pre>             (verbatim and typewriter font)
LaTeX: verb|foo|                 (verbatim and typewriter font)
MediaWiki: <nowiki>foo</nowiki>  (only verbatim)
AsciiDoc: `foo`                  (verbatim and typewriter font)
AsciiDoc: +++foo+++              (only verbatim)"
  :group 'markup-faces-text)

(defface markup-superscript-face
  '((t :inherit markup-gen-face :height 0.8))
  "For superscript text.
For example 'foo' in the following examples:
HTML: <sup>foo</sup>
LaTeX: ^{foo}
AsciiDoc: ^foo^

Note that typically the major mode doing the font lock
additionaly raises the text; face customization doesn't provide
this feature."
  :group 'markup-faces-text)

(defface markup-subscript-face
  '((t :inherit markup-gen-face :height 0.8))
  "For subscript text.
For example 'foo' in the following examples:
HTML: <sub>foo</sub>
LaTeX: _{foo}
AsciiDoc: ~foo~

Note that typically the major mode doing the font lock
additionally lowers the text; face customization doesn't provide
this feature."
  :group 'markup-faces-text)

(defface markup-reference-face
  '((t :inherit markup-gen-face :underline t))
  "For text being a link/reference

For example 'foo' in the following examples:
HTML: <a href=\"...\">foo</a>
MediaWiki: [[...|foo]] or [... foo]
AsciiDoc: ~foo~

See also `markup-internal-reference-face'."
  :group 'markup-faces-text)

;; the real thing identifying markup-secondary-text-face is the :family. height
;; and color only help (as always). NO!!! This is not true, because of
;; markup-typewriter-face, markup-code-face etc, which must also be available
;; within secondary text. Maybe its really the height which identifies it. Or
;; ist it the color :-)? Or maybe its all of them a bit - if the secondary uses
;; <big>, the others help, if the secondary text uses <tt>, the others help etc.
(defface markup-secondary-text-face
  '((t :inherit markup-gen-face :foreground "firebrick" :height 0.8))
  "For text that is not part of the running text.
For example for captions of tables or images, or for footnotes, or for floating text."
  :group 'markup-faces-text)

(defface markup-italic-face
  '((t :inherit markup-gen-face :slant italic))
  "For text in italic font.

For example 'foo' in the following examples:
HTML: <i>foo</i>
LaTeX: \\textit{foo}
Mediawiki: ''foo''"
  :group 'markup-faces-text)

(defface markup-bold-face
  '((t :inherit markup-gen-face :weight bold))
  "For text with a bold font.

For example 'foo' in the following examples:
HTML: <b>foo</b>
LaTeX: \\textbf{foo}
Mediawiki: '''foo'''"
  :group 'markup-faces-text)

(defface markup-underline-face
  '((t :inherit markup-gen-face :underline t))
  "For explicitly underlined text.

For example 'foo' in the following examples:
HTML: <u>foo</u>."
  :group 'markup-faces-text)

(defface markup-typewriter-face
  '((t :inherit (fixed-pitch markup-gen-face)))
  "For text in typewriter/monospaced font.

For example 'foo' in the following examples:
HTML: <tt>foo</tt>   (only typewriter font)
LaTeX: \\texttt{foo} (only typewriter font)
LaTeX: verb|foo|     (verbatim and typewriter font)
AsciiDoc: +foo+      (only typewriter font)
AsciiDoc: `foo`      (verbatim and typewriter font)

See also `markup-verbatim-face', and `markup-typewriter-face'."
  :group 'markup-faces-text)

(defface markup-small-face
  '((t :inherit markup-gen-face :height 0.8))
  "For text in a smaller font.

For example 'foo' in the following examples:
HTML: <small>foo</small>
LaTeX: {\\small foo}"
  :group 'markup-faces-text)

(defface markup-big-face
  '((t :inherit markup-gen-face :height 1.3))
  "For text in bigger font.

For example 'foo' in the following examples:
HTML: <big>foo</big>
LaTeX: {\\large foo}"
  :group 'markup-faces-text)

;;; group markup-faces-meta
(defgroup markup-faces-meta nil
  "Faces for meta text in markup languages"
  :group 'markup-faces)

(defface markup-meta-face
  '((default ( :family "Monospace" ; emacs's faces.el also directly uses "Monospace", so I assume it is safe to do so
	       :height 90       
	       ;; dummy, see doc string
	       :stipple nil
	       :inverse-video nil
	       :box nil
	       :strike-through nil
	       :overline nil
	       :underline nil
	       :slant normal
	       :weight normal
	       :width normal
	       :foundry "unknown"))
    (((background light)) (:foreground "gray65"))
    (((background dark)) (:foreground "gray30")))
  "Face for general meta characters and base for special meta characters.

The default sets all face properties to a value because then it's
easier for major mode to write font lock regular expressions."
  ;; For example in '<b>...<foo>...</b>', if <foo> is fontified before <b>, <b>
  ;; might then make <foo> bold, which is not the intend.
  :group 'markup-faces-meta)

(define-obsolete-face-alias 'markup-delimiter-face 'markup-meta-face "23.1")
;; (defface markup-delimiter-face
;;   '((t :inherit markup-meta-face))
;;   "Similar to `markup-meta-face'.
;;
;; I currently think markup-meta-face is for general meta characters
;; no having their own dedicated face, markup-delimiter-face is for
;; the delimiters separating section of meta characters from normal
;; text. E.g. the '<' and '>' in HTML, which delimit the tag, which
;; is a string of mete characters.
;;
;; It's questionable whether such a distinction makes sense. The
;; right thing to do is probably to drop markup-delimiter-face
;; altogether and replace references to it with markup-meta-face.
;; Historically I often used `markup-delimiter-face' for things which
;; actually should use `markup-meta-face'."
;;   :group 'markup-faces-meta)

(define-obsolete-face-alias 'markup-hide-delimiter-face 'markup-meta-hide-face "23.1")
(defface markup-meta-hide-face
  '((default (:inherit markup-meta-face :height 0.8))
    (((background light)) :foreground "gray75")
    (((background dark)) :foreground "gray25"))
  "For meta characters which can be 'hidden'.

Hidden in the sense of *almost* not visible. They don't need to
be properly seen because one knows what these characters must be;
deduced from the highlighting of the near context. E.g in
AsciiDocs '_important_', the underlines would be highlighted with
markup-hide-delimiter-face, and the text 'important' would be
highlighted with markup-emphasis-face. Because 'important' is
highlighted, one knows that it must be surrounded with the meta
characters '_', and thus the meta characters don't need to be
properly seen.

For example:
AsciiDoc: *strong emphasis text* or _emphasis text_
          ^                    ^    ^             ^"
  :group 'markup-faces-meta)

(defface markup-command-face
  '((t :inherit markup-meta-face :weight bold))
  "For command names.

For example 'foo' the following examples:
HTML: <foo ...>...</foo>
LaTeX: \\{foo ...}
Mediawiki: {{foo ...}}

Note however that special commands might be fontified specially.
For example in HTML's <b>important</b>, the whole tag,
e.g. '<b>', might be fontified with markup-bold-face. "
  :group 'markup-faces-meta)

(defface markup-attribute-face
  '((t :inherit markup-meta-face :slant italic))
  "For attribute names"
  :group 'markup-faces-meta)

(defface markup-value-face
  '((t :inherit markup-meta-face))
  "For attribute values"
  :group 'markup-faces-meta)

(defface markup-complex-replacement-face
  '((default (:inherit markup-meta-face
              :box (:line-width 2 :style released-button)))
    (((background light)) (:background "plum1" :foreground "purple3" :box (:color "plum1")))
    (((background dark)) (:background "purple3" :foreground "plum1" :box (:color "purple3"))))
  "Markup that is replaced by something complex.
For example an image, or a table of contents. See also
`markup-replacement-face'.

Examples: 
MediaWiki: __TOC__
AsciiDoc: image:...[...]"
  :group 'markup-faces-meta)

(defface markup-list-face
  '((default (:inherit markup-meta-face))
    (((background light)) (:background "plum1" :foreground "purple3"))
    (((background dark)) (:background "purple3" :foreground "plum1")))
  "For the bullets or numberings of list items."
  :group 'markup-faces-meta)

(defface markup-table-face
  '((default (:inherit markup-meta-face))
    (((background light)) (:background "light blue" :foreground "royal blue"))
    (((background dark)) (:background "dark blue" :foreground "dodger blue")))
  "For the start / end delimiter of a table."
  :group 'markup-faces-meta)

(defface markup-table-row-face
  '((t :inherit markup-table-face))
  "For the row start delimiter."
  :group 'markup-faces-meta)

(defface markup-table-cell-face
  '((default (:inherit markup-table-face))
    (((background light)) (:background "lavender"))
    (((background dark)) (:background "royal blue")))
  "for the cell start delimiter."
  :group 'markup-faces-meta)

(defface markup-anchor-face
  '((t :inherit markup-meta-face :overline t))
  "For the name/id of an anchor.
For example 'foo' in the following examples:
HTML: <a name=foo>...</a>
LaTeX: \\label{foo}
AsciiDoc: [[foo]]

See also `markup-internal-reference-face'"
  :group 'markup-faces-meta)

(defface markup-internal-reference-face
  '((t :inherit markup-meta-face :underline t))
  "For an internal reference.
For example 'foo' in the following examples:
HTML: <a ref=foo>...</a>
MediaWiki: [[foo|...]] or [foo ...]

See also `markup-reference-face' and `markup-anchor-face'."
  :group 'markup-faces-meta)

(defface markup-comment-face
  '((t :inherit (font-lock-comment-face markup-meta-face)))
  "For comments"
  :group 'markup-faces-meta)

(defface markup-preprocessor-face
  '((t :inherit (font-lock-preprocessor-face markup-meta-face)))
  "For preprocessor constructs"
  :group 'markup-faces-meta)

;;; group markup-faces-hybrid
(defgroup markup-faces-hybrid nil
  "Faces for text that neither really fits in the literal nor the meta group"
  :group 'markup-faces)

(defface markup-replacement-face
  '((default (:family "Monospace"))
    (((background light)) (:foreground "purple3"))
    (((background dark)) (:foreground "plum1")))
  "Meta characters that are replaced by text in the output.
See also `markup-complex-replacement-face'.

For example
AsciiDoc: '->' is replaced by an Unicode arrow
MediaWiki: In '{{Main|...}}', the part 'Main' is replaced by 'Main article: '
HTML: character entities: '&amp;' is replaced by an ampersand ('&')

It's difficult to say whether markup-replacement-face is part of
the group markup-faces-meta or part of the group
markup-faces-text. Technically they are clearly meta characters.
However they are just another representation of normal text and I
want to fontify them as such. E.g. in HTML '<b>foo &amp; bar</b>',
the output 'foo & bar' is fontified bold, thus I also want 'foo
&amp; bar' in the Emacs buffer be fontified with
markup-bold-face. Thus markup-replacement-face needs to be
something that is orthogonal to the markup-bold-face etc faces."
  :group 'markup-faces-hybrid)

(defface markup-passthrough-face
  '((t :inherit (fixed-pitch markup-gen-face)))
  "For text that is passed through yet another parser/renderer.

Since this text is passed to an arbitrary renderer, it is unknown
wich of its chars are meta characters and which are literal characters."
  :group 'markup-faces-hybrid)

;; todo: Make sure to avoid the error case that at the end something highlighted
;; with markup-error-face is not visible as such because some other face
;; prepended itself before it. Mmmh, however that would be the responsibility of
;; the major mode doing the font locking.
(defface markup-error-face
  '((t :inherit (font-lock-warning-face)))
  "For things that should stand out"
  :group 'markup-faces-hybrid)

;;; ---
(defvar markup-gen-face 'markup-gen-face)
(defvar markup-title-0-face 'markup-title-0-face)
(defvar markup-title-1-face 'markup-title-1-face)
(defvar markup-title-2-face 'markup-title-2-face)
(defvar markup-title-3-face 'markup-title-3-face)
(defvar markup-title-4-face 'markup-title-4-face)
(defvar markup-title-5-face 'markup-title-5-face)
(defvar markup-emphasis-face 'markup-emphasis-face)
(defvar markup-strong-face 'markup-strong-face)
(defvar markup-verbatim-face 'markup-verbatim-face)
(defvar markup-code-face 'markup-code-face)
(defvar markup-superscript-face 'markup-superscript-face)
(defvar markup-subscript-face 'markup-subscript-face)
(defvar markup-reference-face 'markup-reference-face)
(defvar markup-secondary-text-face 'markup-secondary-text-face)
(defvar markup-italic-face 'markup-italic-face)
(defvar markup-bold-face 'markup-bold-face)
(defvar markup-underline-face 'markup-underline-face)
(defvar markup-typewriter-face 'markup-typewriter-face)
(defvar markup-small-face 'markup-small-face)
(defvar markup-big-face 'markup-big-face)

(defvar markup-meta-face 'markup-meta-face)
(defvaralias 'markup-delimiter-face 'markup-meta-face)
(defvar markup-meta-hide-face 'markup-meta-hide-face)
(defvaralias 'markup-hide-delimiter-face 'markup-meta-hide-face)
(defvar markup-command-face 'markup-command-face)
(defvar markup-attribute-face 'markup-attribute-face)
(defvar markup-value-face 'markup-value-face)
(defvar markup-complex-replacement-face 'markup-complex-replacement-face)
(defvar markup-list-face 'markup-list-face)
(defvar markup-table-face 'markup-table-face)
(defvar markup-table-row-face 'markup-table-row-face)
(defvar markup-table-cell-face 'markup-table-cell-face)
(defvar markup-anchor-face 'markup-anchor-face)
(defvar markup-internal-reference-face 'markup-internal-reference-face)
(defvar markup-comment-face 'markup-comment-face)
(defvar markup-preprocessor-face 'markup-preprocessor-face)

(defvar markup-replacement-face 'markup-replacement-face)
(defvar markup-passthrough-face 'markup-passthrough-face)
(defvar markup-error-face 'markup-error-face)

(provide 'markup-faces)

;;; markup-faces.el ends here
