;;; simplezen.el --- A simple subset of zencoding-mode for Emacs.

;; Copyright (C) 2013 Magnar Sveen

;; Author: Magnar Sveen <magnars@gmail.com>
;; Package-Requires: ((s "1.4.0") (dash "1.1.0"))
;; Package-Version: 20130421.1000
;; Package-Commit: 119fdf2c6890a0c56045ae72cf4fce0071a81481
;; Version: 0.1.1

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

;; A simple subset of zencoding-mode for Emacs.

;; It completes these types:
;;
;;     div        --> <div></div>
;;     input      --> <input>
;;     .article   --> <div class="article"></div>
;;     #logo      --> <div id="logo"></div>
;;     ul.items   --> <ul class="items"></ul>
;;     h2#tagline --> <h2 id="tagline"></h2>
;;
;; So why not just use zencoding-mode for a much richer set of features?
;;
;; - this covers 98% of my usage of zencoding-mode
;; - this is simple enough to be predictable
;;
;; The original had a way of surprising me. Like when I just wanted to
;; add a quick <code></code> tag inside some prose, and it garbled the
;; entire sentence. That doesn't happen here, since this subset does not
;; look past whitespace.
;;
;; It also will not try to expand anything that is not a known html-tag,
;; reducing the number of errors when I just want to indent the line.
;; Yes, I have it on TAB.
;;
;; ## Setup
;;
;; You can bind `simplezen-expand` to any button of your choosing.
;;
;;     (require 'simplezen)
;;     (define-key html-mode-map (kbd "C-c C-z") 'simplezen-expand)
;;
;; If you want it bound to `tab` you can do this:
;;
;;     (define-key html-mode-map (kbd "TAB") 'simplezen-expand-or-indent-for-tab)
;;
;; Then it will still indent the line, except in cases where you're
;; looking back at a valid simplezen-expression (see above).
;;
;; To get it working with yasnippet aswell, I did this:
;;
;;     (defun --setup-simplezen ()
;;       (set (make-local-variable 'yas/fallback-behavior)
;;            '(apply simplezen-expand-or-indent-for-tab)))
;;
;;     (add-hook 'sgml-mode-hook '--setup-simplezen)
;;
;; Which will give yasnippet first priority, then simplezen gets it
;; chance, and if neither of those did anything it will indent the line.

;;; Code:

(require 'dash)
(require 's)

(defvar simplezen-html-tags
  '("a" "abbr" "acronym" "address" "area" "b" "base" "bdo" "big" "blockquote" "body" "br"
    "button" "caption" "cite" "code" "col" "colgroup" "dd" "del" "dfn" "div" "dl" "dt"
    "em" "fieldset" "form" "h1" "h2" "h3" "h4" "h5" "h6" "head" "html" "hr" "i" "img"
    "input" "ins" "kbd" "label" "legend" "li" "link" "map" "meta" "noscript" "object" "ol"
    "optgroup" "option" "p" "param" "pre" "q" "samp" "script" "select" "small" "span"
    "strong" "style" "sub" "sup" "table" "tbody" "td" "textarea" "tfoot" "th" "thead"
    "title" "tr" "tt" "ul" "var" "article" "aside" "bdi" "command" "details" "dialog"
    "summary" "figure" "figcaption" "footer" "header" "hgroup" "mark" "meter" "nav"
    "progress" "ruby" "rt" "rp" "section" "time" "wbr" "audio" "video" "source" "embed"
    "track" "canvas" "datalist" "keygen" "output"))

(defvar simplezen-empty-tags
  '("area" "base" "basefont" "br" "col" "frame" "hr" "img" "input" "isindex" "link"
    "meta" "param" "wbr"))

(defvar simplezen-fallback-behavior nil
  "Function to call if simplezen does not find a match.")

(defun simplezen--maybe-fall-back ()
  (when simplezen-fallback-behavior
    (call-interactively simplezen-fallback-behavior)))

(defun simplezen-expand ()
  (interactive)
  (if (looking-back "[[:lower:]1-6]")
      (let* ((end (point))
             (beg (save-excursion (search-backward-regexp " \\|^\\|>")
                                  (unless (bolp) (forward-char 1))
                                  (point)))
             (expressions (s-slice-at "[.#]" (buffer-substring beg end)))
             (first (car expressions))
             (tagname (if (or (s-starts-with? "." first)
                              (s-starts-with? "#" first))
                          "div"
                        first)))
        (if (member tagname simplezen-html-tags)
            (let ((id (--first (s-starts-with? "#" it) expressions))
                  (classes (->> expressions
                             (--filter (s-starts-with? "." it))
                             (--map (s-chop-prefix "." it))
                             (s-join " "))))
              (delete-char (- beg end))
              (insert "<" tagname
                      (if (s-blank? id) "" (s-concat " id=\"" (s-chop-prefix "#" id) "\""))
                      (if (s-blank? classes) "" (s-concat " class=\"" classes "\""))
                      ">")
              (unless (member tagname simplezen-empty-tags)
                (save-excursion (insert "</" tagname ">"))))
          (simplezen--maybe-fall-back)))
    (simplezen--maybe-fall-back)))

(defun simplezen-expand-or-indent-for-tab ()
  (interactive)
  (let ((simplezen-fallback-behavior 'indent-for-tab-command))
    (simplezen-expand)))

(provide 'simplezen)
;;; simplezen.el ends here
