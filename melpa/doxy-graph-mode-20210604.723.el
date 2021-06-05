;;; doxy-graph-mode.el --- Links source code editing with doxygen call graphs -*- lexical-binding: t -*-


;; Copiright (C) 2020 Gustavo Puche

;; Author: Gustavo Puche <gustavo.puche@gmail.com>
;; URL: https://github.com/gustavopuche/doxy-graph-mode
;; Package-Version: 20210604.723
;; Package-Commit: 88af6ef4bc9c8918b66c7774f0a115b2addc310e
;; Created: 18 June 2020
;; Version: 0.7
;; Keywords: languages all
;; Package-Requires: ((emacs "26.3"))

;;; Commentary:

;; doxy-graph-mode links source code to doxygen call graphs.

;; It allows to interactively see the call graph or the inverted call
;; graph of a given function or method from source code.

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

;;; Code:

;; Latex path to concat to graph filename.
(defvar doxy-graph--latex-path nil
	"Directory name of doxygen latex documentation.")

;; Constans
(defvar doxy-graph--graph-suffix "_cgraph"
	"Added at the end of call graph filename.")

(defvar doxy-graph--inverted-graph-suffix "_icgraph"
	"Added at the end of inverted call graph filename.")

;; Sets doxygen latex path
(defun doxy-graph-set-latex-path ()
	"Opens a directory chooser and setup `doxy-graph--latex-path'."
	(interactive)
	(setq doxy-graph--latex-path (read-directory-name "Please choose doxygen latex folder:")))

;; Gets doxygen latex path
(defun doxy-graph-get-latex-path ()
	"Gets current doxygen latex path.

   If `doxy-graph--latex-path' is set returns it If not calls
   `doxy-graph-set-latex-path' to allow user choose project doxygen
   latex documentation folder."
	(if (not (null doxy-graph--latex-path))
			doxy-graph--latex-path
		(doxy-graph-set-latex-path)))

;; Gets word at cursor point
(defun doxy-graph-get-word-at-point ()
	"Gets word at cursor position."
	(interactive)
	(thing-at-point 'word 'no-properties))

;; Gets file name without folder nor extension.
(defun doxy-graph-file-name-base ()
	"Gets source code filename without extension."
	(interactive)
	(file-name-base buffer-file-name))

;; Gets file name extension.
(defun doxy-graph-file-name-extension ()
	"Gets source code file extension."
	(interactive)
	(file-name-extension buffer-file-name))

;; Gets latex file.
(defun doxy-graph-latex-file ()
	"Builds doxygen latex filename string.

Concats [source-code-filename-base] \"_8\"
[source-code-extension] \".tex\"."
	(interactive)
	(concat (doxy-graph-file-name-base) "_8" (doxy-graph-file-name-extension) ".tex"))

;; Opens new buffer with pdf call graph.
(defun doxy-graph-open-call-graph ()
	"Opens pdf call graph.

Shows call graph of the function or method at cursor."

	(interactive)
	(find-file-other-window
	 (concat (doxy-graph-get-latex-path)
					 (doxy-graph-filename (doxy-graph-get-word-at-point) "_cgraph")
					 ".pdf")))

;; Opens new buffer with pdf call graph.
;; Cpp class version.
(defun doxy-graph-open-cpp-class-call-graph ()
	"Opens pdf call graph in cpp class.

Shows call graph of the function or method at cursor."

	(interactive)
	(find-file-other-window
	 (concat (doxy-graph-get-latex-path)
					 (doxy-graph-cpp-class-filename (doxy-graph-get-word-at-point) (doxy-graph-get-cpp-class) "_cgraph")
					 ".pdf")))

;; Opens new buffer with pdf inverted call graph.
;; Cpp class version.
(defun doxy-graph-open-cpp-class-inverted-call-graph ()
	"Opens pdf call graph in cpp class.

Shows iverted call graph of the function or method at cursor."

	(interactive)
	(find-file-other-window
	 (concat (doxy-graph-get-latex-path)
					 (doxy-graph-cpp-class-filename (doxy-graph-get-word-at-point) (doxy-graph-get-cpp-class) "_icgraph")
					 ".pdf")))

;; Gets class name in cpp file before :: at word-at-point
(defun doxy-graph-get-cpp-class ()
	"Gets class before :: word at cursor position."
	(interactive)
	(if (equal (doxy-graph-file-name-extension) "h")
			(progn
				(message "Source extension: h")
				(search-backward "class")
				(right-word)
				(right-word)
				(left-word))
		(progn
			(message "Source extension: cpp")
			(left-word)
			(left-word)))
	
	(thing-at-point 'word 'no-properties))

;; Opens new buffer with pdf inverted call graph.
(defun doxy-graph-open-inverted-call-graph ()
	"Opens pdf inverted call graph.

Shows inverted call graph of the function or method at cursor
position."
	(interactive)
	(find-file-other-window
	 (concat (doxy-graph-get-latex-path)
					 (doxy-graph-filename (doxy-graph-get-word-at-point) "_icgraph")
					 ".pdf")))

;; Calls doxy-graph-gets-pdf-filename (latex-file function-name)
(defun doxy-graph-cpp-class-filename (function-name class-name graph-type)
	"Gets pdf call graph filename.

Concatenates latex path with pdf call graph filename.

Argument FUNCTION-NAME is the function at cursor.

Argument GRAPH-TYPE can be \"_cgraph\" to regular call graph and
\"_icgraph\" for inverted call graph."
	(interactive)
	(message (car (file-expand-wildcards (concat (doxy-graph-get-latex-path) "*" class-name ".tex"))))
	(doxy-graph-get-pdf-filename (car (file-expand-wildcards (concat (doxy-graph-get-latex-path) "*" class-name ".tex"))) function-name graph-type))

;; Calls doxy-graph-gets-pdf-filename (latex-file function-name)
(defun doxy-graph-filename (function-name graph-type)
	"Gets pdf call graph filename.

Concatenates latex path with pdf call graph filename.

Argument FUNCTION-NAME is the function at cursor.

Argument GRAPH-TYPE can be \"_cgraph\" to regular call graph and
\"_icgraph\" for inverted call graph."
	(interactive)
	(doxy-graph-get-pdf-filename (concat (doxy-graph-get-latex-path) (doxy-graph-latex-file)) function-name graph-type))

;; Parses latex file to obtain pdf call graph.
(defun doxy-graph-get-pdf-filename (latex-file function-name graph-type)
	"Parse latex file and gets pdf filename to graph-type.

Argument LATEX-FILE is the latex file in which it parses pdf graph filename.

Argument FUNCTION-NAME is the function at cursor.

Argument GRAPH-TYPE can be \"_cgraph\" to regular call graph and
\"_icgraph\" for inverted call graph."
	(with-temp-buffer
		(insert-file-contents latex-file)
		(let ((first-pos (search-forward (concat "{" function-name "()}")))
					(end-pos (search-forward graph-type))
					(begin-pos (search-backward "{"))
					(subsubsection-pos (search-backward "subsubsection")))
			(if (< subsubsection-pos first-pos)
					(buffer-substring (+ begin-pos 1) end-pos)
			(progn
				(if (equal graph-type "_cgraph")
						(error "Call graph NOT Found!")
					(error "Inverted call graph NOT Found!")))))))

;;; Keymap
;;
;;
(defvar doxy-graph-mode-map (make-sparse-keymap)
	"Keybindings variable.")

;;;###autoload
(define-minor-mode doxy-graph-mode
  "doxy-graph-mode default keybindings."
  :lighter " doxy-graph"
  :keymap  doxy-graph-mode-map
	(define-key doxy-graph-mode-map (kbd "<C-f1>") 'doxy-graph-open-call-graph)
	(define-key doxy-graph-mode-map (kbd "<C-f2>") 'doxy-graph-open-inverted-call-graph)
	(define-key doxy-graph-mode-map (kbd "<C-f3>") 'doxy-graph-open-cpp-class-call-graph)
	(define-key doxy-graph-mode-map (kbd "<C-f4>") 'doxy-graph-open-cpp-class-inverted-call-graph))

(provide 'doxy-graph-mode)

;;; doxy-graph-mode.el ends here
