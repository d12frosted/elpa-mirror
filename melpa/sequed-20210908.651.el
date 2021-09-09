;;; sequed.el --- Major mode for FASTA format DNA alignments

;; Copyright (C) 2020-2021 Bruce Rannala

;; Author: Bruce Rannala <brannala@ucdavis.edu
;; URL: https://github.com/brannala/sequed
;; Package-Version: 20210908.651
;; Package-Commit: c78ef34da948576290978d876b776c21f8832136
;; Version: 1.00
;; Package-Requires: ((emacs "25.2"))
;; License: GNU General Public License Version 3

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

;; Major mode for editing DNA sequence data in FASTA format and viewing multiple sequence alignments.

;; Usage:
;;
;; M-x sequed-mode to invoke.  Automatically invoked as major mode for .fa and .aln files.
;; Sequed-mode major mode:
;; M-x sequed-reverse-complement [C-c C-r c] -> generate reverse complement of selected DNA region
;; M-x sequed-translate [C-c C-r t] -> generate amino acid sequence by translation of selected DNA region
;; M-x sequed-export [C-c C-e] -> export to new buffer in BPP/Phylip format
;; M-x sequed-mkaln [C-c C-a] -> create an alignment view in read-only buffer in sequed-aln-mode
;; sequed-aln-mode major mode:
;; M-x sequed-aln-gotobase [C-c C-b] -> prompt for base number to move cursor to that column in alignment
;; M-x sequed-aln-seqfeatures [C-c C-f] -> print number of sequences and number of sites
;; M-x sequed-aln-kill-alignment [C-c C-k] -> quit alignment view buffer

;;; Code:

(require 'subr-x)
(require 'seq)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(?:fa\\|aln\\)\\'" . sequed-mode))

(defface sequed-base-c '((t :background "green"))
  "Basic face for DNA base c."
  :group 'base-faces)

(defface sequed-base-t '((t :background "orange"))
  "Basic face for DNA base t."
  :group 'base-faces)

(defface sequed-base-a '((t :background "red"))
  "Basic face for DNA base a."
  :group 'base-faces)

(defface sequed-base-g '((t :background "blue"))
  "Basic face for DNA base g."
  :group 'base-faces)


(defvar sequed-aln-base-a 'sequed-base-a)
(defvar sequed-aln-base-c 'sequed-base-c)
(defvar sequed-aln-base-g 'sequed-base-g)
(defvar sequed-aln-base-t 'sequed-base-t)

(defvar sequed-aln-mode-font-lock nil "DNA bases colors for `font-lock-defaults'.")

(setq sequed-aln-mode-font-lock
      '(("^>[^\s]+" . font-lock-constant-face)
	("[cC]" . sequed-aln-base-c)
	("[tT]" . sequed-aln-base-t)
	("[aA]" . sequed-aln-base-a)
	("[gG]" . sequed-aln-base-g)))

(defconst sequed-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;;  ; is a comment starter
    (modify-syntax-entry ?\; "<" table)
    ;; \n is a comment ender
    (modify-syntax-entry ?\n ">" table)
    table))

(defconst sequed-colors
      '(("^[^>]\\([a-zA-Z- ]+\\)" . font-lock-string-face)
	("^>.+\n" . font-lock-constant-face)))

(defvar sequed-mode-map
  (let ((km (make-sparse-keymap)))
    ;; assign sequed-mode commands to keys
    (define-key km (kbd "C-c C-a") 'sequed-mkaln)
    (define-key km (kbd "C-c C-e") 'sequed-export)
    (define-key km (kbd "C-c C-r c") 'sequed-reverse-complement)
    (define-key km (kbd "C-c C-r t") 'sequed-translate)
    (define-key km [menu-bar sequed]
      (cons "SequEd" (make-sparse-keymap "SequEd")))
    ;; assign sequed-mode commands to menu
    (define-key km
      [menu-bar sequed sequed-mkaln]
      '("View Alignment" . sequed-mkaln))
    (define-key km
      [menu-bar sequed sequed-export]
      '("Export" . sequed-export))
    (define-key km
      [menu-bar sequed sequed-reverse-complement]
      '("Reverse Complement" . sequed-reverse-complement))
    (define-key km
      [menu-bar sequed sequed-translate]
      '("Translation" . sequed-translate))
    km)
  "Keymap used in Sequed mode.")
      

;;;###autoload
(define-derived-mode sequed-mode fundamental-mode "SequEd"
  "A bioinformatics major mode for viewing and editing sequence data."
  :syntax-table sequed-mode-syntax-table
  (setq font-lock-defaults '(sequed-colors))
  (if (eq (sequed-check-fasta) nil) (user-error "Not a fasta file"))
  (font-lock-ensure)
  (sequed-get-sequence-length)
  (setq-local comment-start "; ")
  (setq-local comment-end ""))

(defvar sequed-aln-mode-map
  (let ((km2 (make-sparse-keymap)))
    ;; assign sequed-aln-mode commands to keys
    (define-key km2 (kbd "C-c C-b") 'sequed-aln-gotobase)
    (define-key km2 (kbd "C-c C-f") 'sequed-aln-seqfeatures)
    (define-key km2 (kbd "C-c C-k") 'sequed-aln-kill-alignment)
    (define-key km2 [menu-bar sequedaln]
      (cons "SequEdAln" (make-sparse-keymap "SequEdAln")))
    ;; define sequed-aln-mode menu
    (define-key km2 [menu-bar sequedaln move]
      '("Move to base" . sequed-aln-gotobase))
    (define-key km2 [menu-bar sequedaln features]
      '("Sequence features" . sequed-aln-seqfeatures))
    (define-key km2 [menu-bar sequedaln quit]
      '("Quit Alignment" . sequed-aln-kill-alignment))
    km2)
  "Keymap used in SequedAln mode.")

(define-derived-mode sequed-aln-mode fundamental-mode "SequEdAln"
  "A bioinformatics major mode for viewing sequence alignments."
  :syntax-table sequed-mode-syntax-table
  (setq font-lock-defaults '(sequed-aln-mode-font-lock))
  (font-lock-ensure)
  (setq mode-line-format (list "%e" mode-line-front-space mode-line-mule-info
			       mode-line-client mode-line-modified
			       mode-line-remote mode-line-frame-identification
			       mode-line-buffer-identification
			       "  SeqID:" '(:eval (aref sequed-seqID (- (string-to-number (format-mode-line "%l")) 1)))
			       " BasePos:" '(:eval (if (>  (- (current-column) (- sequed-label-length 1)) 0)
						       (number-to-string (+ (- (string-to-number
										(format-mode-line "%c"))
									       (- sequed-label-length 1))
									    (- sequed-startpos 1)))))
			       "   "
			       mode-line-modes mode-line-misc-info mode-line-end-spaces)))

(defun sequed-check-fasta ()
  "Check if file is in fasta format."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^\\(>\\).+\n[a-z\-]+" nil t) t nil)))

(defun sequed-remove-fasta-comments ()
  "Remove comments from current buffer."
  (goto-char (point-min))
  (let (kill-ring)
    (comment-kill (count-lines (point-min) (point-max)))))

(defvar-local sequed-label-length nil)
(defvar-local sequed-seq-length nil)
(defvar-local sequed-noseqs nil)
(defvar-local sequed-seqID nil)
(defvar-local sequed-startpos nil)
(defvar-local sequed-endpos nil)


(defun sequed-get-sequence-length ()
  "Get length of first sequence."
  (let (f-buffer f-lines f-linenum f-concatlines (oldbuf (current-buffer)))
  (with-temp-buffer
    (insert-buffer-substring oldbuf)
    (setq-local comment-start "; ")
    (setq-local comment-end "")
    (sequed-remove-fasta-comments)
    (setq f-buffer (buffer-substring-no-properties (point-min) (point-max))))
    (setq f-lines (split-string
		   f-buffer ">\\([[:word:]\-/|_.]+\\)\\([\s]+.*\n\\)?" t))
    (setq f-linenum 0) ; Counts the original file's line number being evaluated
    (while (< f-linenum (length f-lines))
      (push (mapconcat #'concat (split-string
				 (nth f-linenum f-lines)
				 "\n" t) "") f-concatlines)
      (setq f-linenum (+ 1 f-linenum)))
    (setq sequed-seq-length (length (car f-concatlines)))))

;; Create a read-only buffer with pretty alignment displayed
(defun sequed-mkaln (startpos endpos)
  "Create read-only buffer for alignment viewing.
Argument STARTPOS First nucleotide position in alignment to display.
Argument ENDPOS Last nucleotide position in alignment to display."
  (interactive
   (let ((spos (read-number "Start Pos: " 1))
	 (epos (read-number "End Pos: " sequed-seq-length)))
     (list spos epos)))
  (if (eq (sequed-check-fasta) nil) (user-error "Not a fasta file"))
  (let (f-buffer f-lines f-seqcount f-linenum f-labels f-pos f-concatlines f-trimmed
		 elabels (buf (get-buffer-create "*Alignment Viewer*")) text
		 (inhibit-read-only t) (oldbuf (current-buffer)))
    (with-temp-buffer
      (insert-buffer-substring oldbuf)
      (setq-local comment-start "; ")
      (setq-local comment-end "")
      (sequed-remove-fasta-comments)
      (setq f-buffer (buffer-substring-no-properties (point-min) (point-max))))
    (goto-char (point-min))
    (setq f-pos 0)
    (while (string-match ">[[:word:]\-/|_.]+" f-buffer f-pos)
      (push (substring-no-properties f-buffer
				     (nth 0 (match-data))
				     (nth 1 (match-data)))
	                             f-labels)
      (setq f-pos (nth 1 (match-data))))
    (setq f-labels (reverse f-labels))
    (setq f-lines (split-string
		   f-buffer ">\\([[:word:]\-/|_.]+\\)\\([\s]+.*\n\\)?" t))
    (setq f-linenum 0) ; Counts the original file's line number being evaluated
    (while (< f-linenum (length f-lines))
      (push (mapconcat #'concat (split-string
				 (nth f-linenum f-lines)
				 "\n" t) "") f-concatlines)
      (setq f-linenum (+ 1 f-linenum)))
    (setq elabels (sequed-labels-equal-length f-labels))
    (setq f-linenum 0)
    (while (< f-linenum (length f-concatlines))
      (push (substring (nth f-linenum f-concatlines) (- startpos 1) endpos) f-trimmed)
      (setq f-linenum (+ 1 f-linenum)))
    (setq f-trimmed (reverse f-trimmed)) ; restore correct order of sequences
    (setq f-linenum 0) ; Counts the original file's line number being evaluated
    (while (< f-linenum (length f-lines))
      (push (concat
	     (nth f-linenum elabels)
	     (nth f-linenum f-trimmed))
	    text)
      (setq f-linenum (+ 1 f-linenum)))
    (with-current-buffer buf
      (erase-buffer)
      (sequed-aln-mode)
      (setq sequed-label-length (length (car elabels)))
      (setq sequed-seq-length (length (car f-concatlines)))
      (setq sequed-noseqs (length elabels))
      (setq sequed-seqID (sequed-short-labels f-labels))
      (setq sequed-startpos startpos)
      (setq sequed-endpos endpos)
      (setq truncate-lines t)
      (setq f-linenum 0) ; Counts the original file's line number being evaluated
    (while (< f-linenum (length f-lines))
      (insert (concat (nth f-linenum text) "\n"))
      (setq f-linenum (+ 1 f-linenum)))
    (sequed-color-labels)
    (read-only-mode))
    (display-buffer buf))
  (other-window 1)
  (goto-char(point-min))
  (sequed-aln-gotobase sequed-startpos))

(defun sequed-aln-gotobase (position)
  "Move to base at POSITION in sequence that cursor is positioned in."
  (interactive "nPosition of base: ")
  (if (or (< position sequed-startpos)
	  (> position sequed-endpos))
      (user-error "Attempt to move to base outside sequence"))
  (beginning-of-line)
  (move-to-column (- (+ position (- sequed-label-length 1)) (- sequed-startpos 1))))

(defun sequed-aln-seqfeatures ()
  "List number of sequences and length of region."
  (interactive)
  (message "Sequences:%d Sites:%d"
	   sequed-noseqs sequed-seq-length))

(defun sequed-aln-kill-alignment ()
  "Kill alignment buffer and window."
  (interactive)
  (kill-buffer-and-window))

(defun sequed-export ()
  "Export alignment in format for phylogenetic software."
  (interactive)
  (let ((oldbuf (current-buffer)) nseqs nsites f-lines templine f-buffer start end)
    (save-current-buffer
      (set-buffer (get-buffer-create "*export alignment*"))
      (erase-buffer)
      (insert-buffer-substring-no-properties oldbuf )
      (setq f-buffer (buffer-substring-no-properties (point-min) (point-max)))
      (goto-char (point-min))
      (setq f-lines (split-string f-buffer ">\\([[:word:]\-/|_.]+\\)\\([\s]+.*\n\\)?" t))
      (setq templine (mapconcat #'concat (split-string (nth 1 f-lines) "\n" t) ""))
      (setq-local nsites (length templine))
      (goto-char 0)
      (setq-local comment-start "; ")
      (setq-local comment-end "")
      (sequed-remove-fasta-comments)
      (goto-char 0)
      (setq nseqs (how-many ">[[:word:]\-/|_.]+"))
      (goto-char 0)
      (while (re-search-forward ">[[:word:]\-/|_.]+" nil t)
	(delete-region (point) (- (re-search-forward "\n") 1)))
      (goto-char 0)
      (insert (concat (number-to-string nseqs) "  "))
      (insert (concat (number-to-string nsites) "\n"))
      (while (re-search-forward ">" nil t)
	(delete-char 1))
      (fundamental-mode)
      (display-buffer( current-buffer)))))

(defvar sequed-genetic-code-universal)

(setq sequed-genetic-code-universal (make-hash-table :test 'equal))
(puthash "ttt" ?F sequed-genetic-code-universal)
(puthash "ttc" ?F sequed-genetic-code-universal)
(puthash "tta" ?L sequed-genetic-code-universal)
(puthash "ttg" ?L sequed-genetic-code-universal)
(puthash "tct" ?S sequed-genetic-code-universal)
(puthash "tcc" ?S sequed-genetic-code-universal)
(puthash "tca" ?S sequed-genetic-code-universal)
(puthash "tcg" ?S sequed-genetic-code-universal)
(puthash "taa" ?* sequed-genetic-code-universal)
(puthash "tag" ?* sequed-genetic-code-universal)
(puthash "tat" ?Y sequed-genetic-code-universal)
(puthash "tac" ?Y sequed-genetic-code-universal)
(puthash "tgt" ?C sequed-genetic-code-universal)
(puthash "tgc" ?C sequed-genetic-code-universal)
(puthash "tga" ?* sequed-genetic-code-universal)
(puthash "tgg" ?W sequed-genetic-code-universal)
(puthash "ctt" ?L sequed-genetic-code-universal)
(puthash "ctc" ?L sequed-genetic-code-universal)
(puthash "cta" ?L sequed-genetic-code-universal)
(puthash "ctg" ?L sequed-genetic-code-universal)
(puthash "cct" ?P sequed-genetic-code-universal)
(puthash "ccc" ?P sequed-genetic-code-universal)
(puthash "cca" ?P sequed-genetic-code-universal)
(puthash "ccg" ?P sequed-genetic-code-universal)
(puthash "cat" ?H sequed-genetic-code-universal)
(puthash "cac" ?H sequed-genetic-code-universal)
(puthash "caa" ?Q sequed-genetic-code-universal)
(puthash "cag" ?Q sequed-genetic-code-universal)
(puthash "cgt" ?R sequed-genetic-code-universal)
(puthash "cgc" ?R sequed-genetic-code-universal)
(puthash "cga" ?R sequed-genetic-code-universal)
(puthash "cgg" ?R sequed-genetic-code-universal)
(puthash "att" ?I sequed-genetic-code-universal)
(puthash "atc" ?I sequed-genetic-code-universal)
(puthash "ata" ?I sequed-genetic-code-universal)
(puthash "atg" ?M sequed-genetic-code-universal)
(puthash "act" ?T sequed-genetic-code-universal)
(puthash "acc" ?T sequed-genetic-code-universal)
(puthash "aca" ?T sequed-genetic-code-universal)
(puthash "acg" ?T sequed-genetic-code-universal)
(puthash "aat" ?N sequed-genetic-code-universal)
(puthash "aac" ?N sequed-genetic-code-universal)
(puthash "aaa" ?K sequed-genetic-code-universal)
(puthash "aag" ?K sequed-genetic-code-universal)
(puthash "agt" ?S sequed-genetic-code-universal)
(puthash "agc" ?S sequed-genetic-code-universal)
(puthash "aga" ?R sequed-genetic-code-universal)
(puthash "agg" ?R sequed-genetic-code-universal)
(puthash "gtt" ?V sequed-genetic-code-universal)
(puthash "gtc" ?V sequed-genetic-code-universal)
(puthash "gta" ?V sequed-genetic-code-universal)
(puthash "gtg" ?V sequed-genetic-code-universal)
(puthash "gct" ?A sequed-genetic-code-universal)
(puthash "gcc" ?A sequed-genetic-code-universal)
(puthash "gca" ?A sequed-genetic-code-universal)
(puthash "gcg" ?A sequed-genetic-code-universal)
(puthash "gat" ?D sequed-genetic-code-universal)
(puthash "gac" ?D sequed-genetic-code-universal)
(puthash "gaa" ?E sequed-genetic-code-universal)
(puthash "gag" ?E sequed-genetic-code-universal)
(puthash "ggt" ?G sequed-genetic-code-universal)
(puthash "ggc" ?G sequed-genetic-code-universal)
(puthash "gga" ?G sequed-genetic-code-universal)
(puthash "ggg" ?G sequed-genetic-code-universal)

(defvar sequed-translation)

(defun sequed-translate (seqbegin seqend)
  "Translation of marked DNA region SEQBEGIN SEQEND into Amino Acids."
  (interactive "r")
  (let (z y x (i 0) (j 0) codon)
    (setq x (replace-regexp-in-string "[\s]*\n" "" (buffer-substring-no-properties seqbegin seqend)))
    (setq y (make-vector (/ (length x) 3) ?.))
    (while (< i (- (length x) 2))
      (setq codon (substring x i (+ i 3)))
      (if (string-match "[agct][agct][agct]" codon)
	  (aset y j (gethash codon sequed-genetic-code-universal))
	(aset y j ?.))
      (setq i (+ i 3))
      (setq j (+ j 1)))
    (setq z (seq-into y 'string))
    (setq sequed-translation (generate-new-buffer "*translation*"))
    (print z sequed-translation)
    (switch-to-buffer sequed-translation)))

(defvar sequed-revb)

(defun sequed-basepair (base)
  "Find the complement of a DNA BASE."
  (let ((case-fold-search nil))
    (cond
     ((char-equal ?a base) ?t)
     ((char-equal ?t base) ?a)
     ((char-equal ?c base) ?g)
     ((char-equal ?g base) ?c)
     ((char-equal ?A base) ?T)
     ((char-equal ?T base) ?A)
     ((char-equal ?C base) ?G)
     ((char-equal ?G base) ?C)
     (t base))))

(defun sequed-reverse-complement (seqbegin seqend)
  "Get reverse-complement of marked region SEQBEGIN SEQEND in new buffer."
  (interactive "r")
  (let (revcmp x)
    (setq revcmp (reverse (concat (seq-map #'sequed-basepair (buffer-substring-no-properties seqbegin seqend)))))
    (setq x (replace-regexp-in-string "[\s]*\n" "" revcmp))
    (setq sequed-revb (generate-new-buffer "*reverse complement*"))
    (print x sequed-revb)
    (switch-to-buffer sequed-revb)))

;; Pad labels to equal length to allow viewing of alignments
(defun sequed-labels-equal-length (labels)
    "Make fasta LABELS equal length by padding all to length of longest name."
    (let* (currline labelsizes equallabels maxszlabel)
      (setq currline 0)
      (while (< currline (length labels))
	(push (length (string-trim (nth currline labels))) labelsizes)
	(setq currline (+ 1 currline)))
      (setq labelsizes (reverse labelsizes))
      (setq maxszlabel (sequed-max2 labelsizes))
      (setq currline 0)
      (while (< currline (length labels))
	(push (concat (string-trim (nth currline labels))
		      (make-string
		       (- (+ 1 maxszlabel)
			  (nth currline labelsizes))
		       ?\s ))
	      equallabels)
	(setq currline (+ 1 currline)))
      equallabels))

;; Get short labels for display on mode line
(defun sequed-short-labels (labels)
  "Create short LABELS for display in mode line."
  (let* ((currline 0) seqID)
    (setq seqID (make-vector(length labels) "Empty"))
    (while (< currline (length labels))
      (aset seqID currline (substring (nth currline labels) 1 11))
      (setq currline (+ 1 currline)))
    seqID))

;; Length of longest string in list1
(defun sequed-max2 (list1)
"Get length of longest string in variable LIST1."
  (let (mx clist curr)
    (setq clist (cl-copy-list list1))
    (setq mx (pop clist))
    (while clist (setq curr (pop clist))
	   (if (> curr mx) (setq mx curr) ))
    mx ))

;; Color fasta labels
(defun sequed-color-labels ()
  "Identify labels and color them."
  (save-excursion
    (goto-char 0)
    (while (re-search-forward ">[[:word:]\-/|_.]+" nil t)
      (put-text-property
       (nth 0 (match-data))
       (nth 1 (match-data))'face '(:foreground "yellow")))))

(provide 'sequed)

;;; sequed.el ends here
