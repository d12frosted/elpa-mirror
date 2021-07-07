;;; ox-latex-subfigure.el --- Subfigure for latex export

;; Copyright (C) 2014-2019 Quang Linh LE

;; Author: Quang Linh LE <linktohack@gmail.com>
;; URL: http://github.com/linktohack/ox-latexty-subfigure
;; Package-Version: 20190718.1255
;; Package-Commit: b7445849ae1f16b4b28f7a080301a0a61edf1c83
;; Version: 0.0.2
;; Keywords: ox latex subfigure org org-mode
;; Package-Requires: ()

;; This file is not part of GNU Emacs.

;;; License:

;; This file is part of ox-latex-subfigure
;;
;; ox-latex-subfigure is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; ox-latex-subfigure is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied warranty
;; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; ox-latex-subfigure.el permits to export subfigure to latex

;;; Code:

(require 'ox-latex)
(require 'org-loaddefs)

(defun link/org-export-table-to-subfigure (text backend info)
  "Convert table to subfigure in LaTeX export."
  (when (org-export-derived-backend-p backend 'latex)
    (if (not (next-property-change 0 text))
        text
      (let ((pt 0)
            cell table attr env limit)
        (while (or (not table)
                   (not pt))
          (setq pt (next-property-change pt text)
                cell (plist-get (text-properties-at pt text) :parent)
                table (org-export-get-parent-table cell)))
        (setq attr (org-export-read-attribute :attr_latex table)
              env (plist-get attr :environment)
              limit (string-to-number (or (plist-get attr :limit) "0")))
        (if (not (string= "subfigure" env))
            text
          (with-temp-buffer
            (insert text)
            (goto-char 1)
            (link/latex-table-to-subfigure limit)
            (buffer-string)))))))

(defun link/latex-table-to-subfigure (limit)
  "Convert well-formed table to subfigure."
  (interactive "p")
  (let ((width ".9\\textwidth")
        (align "")
        (option "")
        (centering "")
        (caption "")
        fig cap options-test)
    (beginning-of-line)
    (while (not (looking-at "^\\\\end{table}"))
      (let ((row (thing-at-point 'line t)))
        (kill-whole-line)
        (cond
         ;; \begin{table}[option], \end{table}
         ((string-match "^\\\\begin{table}\\(\\[.*\\]\\)?" row)
          (setq option (or (match-string 1 row) "")))
         ;; \centering
         ((string-match "^\\\\centering" row)
          (setq centering "\\centering\n"))
         ;; \begin{subfigure}{width}{align}, \begin{subfigure}{align}
         ;; \end{subfigure}
         ((string-match "^\\\\begin{subfigure}\\({\\(.*?\\)}\\)?\\({\\(.*?\\)}\\)?" row)
          (let
              (maybe-width maybe-align start-of-table row-start row-end rules)
            (setq maybe-width (match-string 2 row))
            (setq maybe-align (match-string 4 row))
            (unless maybe-align
              (setq maybe-align maybe-width)
              (setq maybe-width nil))
            (setq width (or maybe-width width))
            (setq align (or maybe-align align))

            (setq start-of-table (point))

            ;; Remove all possible rules or hlines
            (setq rules
                  (mapconcat 'identity
                             '("hline" "vline" "toprule" "midrule" "bottomrule")
                             "\\|"))
            (while (re-search-forward (concat "\\\\\\(" rules  "\\)\n?") nil t)
              (replace-match ""))

            (goto-char start-of-table)

            ;; Transform all multi line rows to single line rows by replacing
            ;; newlines with spaces
            (while (not (looking-at "\\\\end{subfigure}"))
              (setq row-start (point))

              ;; Search for a new row delimiter
              (when (re-search-forward "\\\\\\\\\n?" nil t)
                (goto-char row-start)

                (setq row-end (match-beginning 0))

		;; Replace all newlines in the row with spaces
                (save-match-data
                  (while (re-search-forward "\n" row-end t)
                    (replace-match " ")))

                (setq row-start (match-end 0))
                (goto-char row-start)))

            ;; Go back the start of the table and continue with normal
            ;; row formatting
            (goto-char start-of-table)))
         ;; \caption{\label{tab:orgtable1}
         ;; xxx}
         ((string-match "^\\\\caption[\\\\[{]" row)
          (setq caption (concat row (thing-at-point 'line t)))
          (kill-whole-line))
         ;; table row
         ((string-match ".*\\\\\\\\$" row)
          (let ((striped-row (replace-regexp-in-string "\\\\\\\\\n$" "" row)))
            (setq fig (append fig (split-string striped-row " & ")))
            (setq row (thing-at-point 'line t))
            (kill-whole-line)
            (setq striped-row (replace-regexp-in-string "\\\\\\\\\n$" "" row))
            (setq cap (append cap (split-string striped-row " & ")))
            ;;
            (setq row (thing-at-point 'line t))
            (kill-whole-line)
            (setq striped-row (replace-regexp-in-string "\\\\\\\\\n$" "" row))
            (setq options-test (append options-test (split-string striped-row " & "))))))))
    (kill-whole-line)
    (insert (format "\\begin{figure}%s\n%s%s" option
                    (if (member 'subfigure org-latex-caption-above) caption "")
                    centering))
    (dotimes (i (length fig))
      (let ((f (nth i fig))
            (c (nth i cap))
            (o (nth i options-test))
            (std "includegraphics")
            (svg "includesvg"))
        (when (or (string-match std c)
                  (string-match svg c))
          (setq f (prog1 c (setq c f))))
        (when (or
               (string-match (concat
                              "\\(\\\\"
                              std
                              "\\(:?\\[.*?\\]\\)?{.*?}\\)")
                             f)
               (string-match (concat
                              "\\(\\\\"
                              svg
                              "\\(:?\\[.*?\\]\\)?{.*?}\\)")
                             f)
               )
          (setq
           f (replace-regexp-in-string
              "\\[.*?\\]"
              (concat "[" o "]")
              (match-string 1 f)
              t t))
          (insert (format "\\begin{subfigure}[%s]{%s}\\centering
%s
\\caption{%s}
\\end{subfigure}\n" align width f c))
          (when (and (> limit 0)
                     (< i (1- (length fig)))
                     (= (mod (1+ i) limit) 0))
            (insert (format "\\end{figure}\n
\\begin{figure}%s
%s\\ContinuedFloat\n" option centering))))))
    (insert (format "%s\\end{figure}\n"
                    (if (member 'subfigure org-latex-caption-above) "" caption)))))

(add-hook 'org-export-filter-table-functions
          'link/org-export-table-to-subfigure)

(provide 'ox-latex-subfigure)

;;; ox-latex-subfigure.el ends here
