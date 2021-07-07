;;; hyai.el --- Haskell Yet Another Indentation -*- lexical-binding: t -*-

;; Copyright (C) 2014-2017 by Iku Iwasa

;; Author:    Iku Iwasa <iku.iwasa@gmail.com>
;; URL:       https://github.com/iquiw/hyai
;; Package-Version: 20170301.1447
;; Package-Commit: 9efad2ac6a57059b3be624588f649e276a96fdd4
;; Version:   1.4.0
;; Package-Requires: ((cl-lib "0.5") (emacs "24"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; HYAI is an indentation minor mode for Haskell.
;;
;; To enable HYAI in `haskell-mode', add `hyai-mode' to `haskell-mode-hook'.
;;
;;     (add-hook 'haskell-mode-hook #'hyai-mode)
;;

;;; Code:

(require 'cl-lib)

(defgroup hyai nil
  "Haskell Yet Another Indentation"
  :group 'haskell)

(defcustom hyai-basic-offset 4
  "Basic offset used in most places."
  :type 'integer)
(defcustom hyai-where-offset 2
  "Offset used around \"where\"."
  :type 'integer)

(defun hyai-indent-line (&optional inverse)
  "Indent the current line according to the current context.
If there are multiple indent candidates, they are rotated by pressing tab key.
If INVERSE is non-nil, rotation is performed in the reverse order."
  (pcase-let* ((cc (current-column))
               (`(,offset . ,head) (hyai--current-offset-head))
               (indent (hyai--indent offset head inverse)))
    (when indent
      (indent-line-to indent)
      (when (> cc offset)
        (forward-char (- cc offset))))))

(defun hyai-indent-backward ()
  "Indent the current line as `hyai-indent-line', but inversely."
  (interactive)
  (hyai-indent-line t))

(defun hyai--indent (offset head &optional inverse)
  "Return next indent of the current line according to the current context.
OFFSET is indent offset of the current line.
HEAD is the first token in the current line or some special symbol,
one of 'comment or 'string.
If INVERSE is non-nil, previous indent is returned."
  (let ((ppss (syntax-ppss))
        (command (if inverse
                     #'hyai-indent-backward
                   #'indent-for-tab-command))
        indents nexts)
    (cond
     ((member head '(comment string))
      (hyai--indent-comment))

     ((string= head "-}")
      (forward-line 0)
      (save-excursion
        (hyai--goto-comment-start)
        (current-column)))

     ((string= "{-" head)
      (unless (hyai--in-comment-p ppss)
        offset))

     ((string= "--" head)
      (pcase-let ((`(,poffset . ,phead) (hyai--current-offset-head -1)))
        (cond
         ((and (stringp phead)
               (string= phead "--"))
          poffset)
         ((not (hyai--in-comment-p ppss))
          offset))))

     (t
      (setq indents (hyai-indent-candidates head))
      (if (null indents)
          offset
        (cond
         (inverse (setq indents (nreverse indents)))
         ((hyai--previous-line-empty-p)
          (setq indents (hyai--cycle-zero-first indents))))

        (setq nexts (when (eq this-command command)
                      (cdr (member offset indents))))
        (car (or nexts indents)))))))

(defun hyai--indent-comment ()
  "Return indent of the current line in nestable comment or multiline string."
  (pcase-let ((`(,offset . ,head) (hyai--current-offset-head -1)))
    (if (equal head "{-")
        (+ offset 3)
      offset)))

(defun hyai-indent-candidates (head)
  "Return list of indent candidates in the current line.
HEAD is the first token in the current line."
  (if (member head '("{-" "--"))
      '()
    (save-excursion
      (forward-line 0)
      (hyai--skip-space-backward)
      (if (bobp)
          '(0)
        (or (save-excursion (hyai--indent-candidates-from-current head))
            (save-excursion (hyai--indent-candidates-from-previous))
            (save-excursion (hyai--indent-candidates-from-backward head)))))))

(defun hyai--indent-candidates-from-current (head)
  "Return list of indent candidates according to HEAD."
  (pcase head
    ((or `"class" `"data" `"import" `"instance" `"module" `"newtype" `"type")
     '(0))
    (`"where" (if (hyai--search-token-backward nil '("where"))
                  (or
                   (hyai--offsetnize (hyai--botp) hyai-basic-offset)
                   (list (+ (hyai--next-offset) hyai-where-offset)))
                (list (+ (current-indentation) hyai-where-offset))))

    (`"then" (hyai--offsetnize (hyai--search-token-backward nil '("if"))
                               hyai-basic-offset))
    (`"else" (let ((offset (hyai--search-token-backward nil '("then"))))
               (hyai--offsetnize
                (if (equal offset (current-indentation))
                    offset
                  (hyai--search-token-backward nil '("if"))))))

    (`"in" (hyai--offsetnize (hyai--search-token-backward nil '("let"))))

    (`"("
     (let (offset)
       (save-excursion
         (cond
          ((member (hyai--grab-token) '("," "(")) nil) ; fall through
          ((member (hyai--search-context) '("import" "module"))
           (setq offset (current-column))
           (list (+ offset hyai-basic-offset)))))))

    ((or `"{" `"=")
     (list (+ (hyai--previous-offset) hyai-basic-offset)))

    (`")"
     (hyai--offsetnize (hyai--search-comma-bracket ?\))))

    (`"]"
     (hyai--offsetnize (hyai--search-comma-bracket ?\])))

    (`"}"
     (hyai--offsetnize (hyai--search-comma-bracket ?\})))

    (`","
     (hyai--offsetnize (hyai--search-comma-bracket ?,)))

    ((or `"->" `"=>")
     (let (limit)
       (or (hyai--offsetnize
            (save-excursion
              (prog1 (hyai--search-token-backward '("::") nil)
                (setq limit (point)))))
           (hyai--offsetnize (hyai--search-vertical limit t))
           (list hyai-basic-offset))))

    (`"|" (let (limit ctx offset)
            (save-excursion
              (setq ctx (hyai--search-context))
              (setq limit (point))
              (setq offset (current-indentation)))
            (if (equal ctx "data")
                (hyai--search-vertical-equal limit)
              (or (save-excursion (hyai--search-vertical limit))
                  (cond
                   ((equal ctx "where")
                    (list (+ offset hyai-where-offset hyai-basic-offset)))
                   ((equal ctx "case")
                    (list (+ (hyai--previous-offset) hyai-basic-offset)))
                   (t (list (+ (current-indentation) hyai-basic-offset))))))))))

(defun hyai--indent-candidates-from-previous ()
  "Return list of indent candidates according to the last token in previous line."
  (pcase (hyai--grab-token)
    (`"do"
     (list (+ (hyai--find-base-offset) hyai-basic-offset)))
    (`"where"
     (if (hyai--botp)
         (list (+ (current-column) hyai-where-offset))
       (or (hyai--offsetnize
            (hyai--search-token-backward nil '("where"))
            hyai-basic-offset)
           (if (looking-at-p "module")
               (list (current-indentation))
             (list (+ (current-indentation) hyai-basic-offset))))))
    (`"of"
     (let ((offset (hyai--search-token-backward nil '("case"))))
       (when offset
         (hyai--offsetnize
          (if (or (= offset (current-indentation))
                  (progn
                    (hyai--skip-space-backward)
                    (not (equal (hyai--grab-syntax-backward ".") "="))))
              offset
            (list (hyai--find-base-offset) offset))
          hyai-basic-offset))))
    ((or `"then" `"else")
     (if (hyai--botp)
         (list (+ (current-column) hyai-basic-offset))
       (hyai--offsetnize
        (hyai--search-token-backward nil '("if"))
        hyai-basic-offset)))

    (`"="
     (list (+ (hyai--find-base-offset) hyai-basic-offset)))
    (`"->"
     (let ((off1 (hyai--find-equal))
           (off2 (current-indentation)))
       (if off1
           (list (+ off2 hyai-basic-offset) off1)
         (list off2 (+ off2 hyai-basic-offset)))))
    (`","
     (list (or (and (hyai--search-comma-bracket ?,)
                    (progn
                      (forward-char)
                      (skip-syntax-forward " ")
                      (if (eolp)
                          (hyai--next-offset)
                        (current-column))))
               (hyai--previous-offset))))

    (`"(" (list (+ (current-column) 1)))
    ((or `"{" `"[")
     (let ((cc (current-column))
           (offset (hyai--previous-offset)))
       (if (= offset (- cc 1))
           (list (+ offset 2))
         (list (+ offset hyai-basic-offset)))))

    (`")" (when (equal (hyai--search-context) "import")
            '(0)))))

(defun hyai--indent-candidates-from-backward (head)
  "Return list of indent candidates according to HEAD and backward tokens."
  (pcase-let* ((`(,offs1 ,token ,col) (hyai--possible-offsets))
               (offs2)
               (offset (current-indentation))
               (min-offset (or (car offs1) offset)))
    (cond
     ((equal token "let")
      offs1)
     ((member token '("(" "[" "{" "," "then"))
      (or (cdr offs1)
          (list min-offset (+ min-offset hyai-basic-offset))))

     (t
      (cond
       ((equal token "else")
        (setq offs1 (append offs1 (list (+ min-offset hyai-basic-offset))))
        (hyai--search-token-backward nil '("if"))
        (setq offset (current-column)))

       ((equal token "->")
        (unless (= offset col)
          (push offset offs1))))

      (when (> offset 0)
        (setq offs2 (hyai--indent-candidates-rest offset)))

      (when (and (= offset hyai-basic-offset)
                 (< offset min-offset))
        (push offset offs2))

      (when (and offs1 (string= head "["))
        (setq offs1
              (cons
               (+ offset hyai-basic-offset)
               (if (equal offset min-offset)
                   (cdr offs1)
                 offs1))))

      (unless offs1
        (push (+ offset hyai-basic-offset) offs1)
        (push offset offs1))

      (when (and (< 0 min-offset) (not (string= head "[")))
        (push 0 offs2))

      (let ((result (append offs1 offs2)))
        (if (hyai--type-signature-p)
            (hyai--cycle-zero-first result)
          result))))))

(defun hyai--indent-candidates-rest (base-offset)
  "Return list of indent candidates from rest of backward lines.
Candidates larger than BASE-OFFSET is ignored."
  (let* (result (coffset base-offset))
    (while (>= coffset hyai-basic-offset)
      (forward-line 0)
      (skip-syntax-backward "> ")
      (pcase-let* ((`(,offs . _) (hyai--possible-offsets))
                   (`(,offset . ,head) (hyai--current-offset-head)))
        (setq coffset offset)
        (if offs
            (setq result (append
                          (cl-remove-if (lambda (x) (>= x base-offset)) offs)
                          result))
          (when (and (> coffset 0) (< coffset base-offset)
                     (>= coffset hyai-basic-offset)
                     (not (member head '("|" "->" "where"))))
            (push coffset result)))
        (when (< offset base-offset)
          (setq base-offset offset))))
    result))

(defun hyai--current-offset-head (&optional n)
  "Return cons of the indent offset and the head in the current line.

Head is either symbol or string.
If it is a symbol, the value is 'comment or 'string which means
beginning of the current line is in nestable comment or multiline string.
Otherwise, the value is the first token of the current line.

If N is supplied, go to N lines relative to the current line."
  (save-excursion
    (forward-line (or n 0))
    (skip-syntax-forward " ")
    (cons
     (current-column)
     (let ((ppss (syntax-ppss))
           (c (char-after)))
       (cond
        ((hyai--in-comment-p ppss)
         (if (looking-at-p "-}")
             "-}"
           'comment))

        ((hyai--in-multiline-string-p ppss)
         'string)

        ((eobp) "")

        (t
         (cl-case (char-syntax c)
           (?w (hyai--grab-syntax-forward "w"))
           (?_ (hyai--grab-syntax-forward "_"))
           (?\( (if (looking-at-p "{-") "{-" (string c)))
           (?\) (string c))
           (?. (if (looking-at-p "--")
                   "--"
                 (hyai--grab-syntax-forward ".")))
           (t ""))))))))

(defun hyai--search-token-backward (symbols words)
  "Search token specified in SYMBOLS or WORDS backward."
  (skip-syntax-backward " >")
  (let (result)
    (hyai--process-syntax-backward
     (lambda (syn _c)
       (cl-case syn
         (?w (cond
              ((null words)
               (skip-syntax-backward "w")
               nil)
              ((member (hyai--grab-syntax-backward "w") words)
               (setq result (current-column))
               'stop)
              (t 'next)))
         (?. (cond
              ((null symbols)
               (skip-syntax-backward ".")
               nil)
              ((member (hyai--grab-syntax-backward ".") symbols)
               (setq result (current-column))
               'stop)
              (t 'next)))
         (?> (if (/= (char-syntax (char-after)) ?\s)
                 'stop
               (backward-char)
               'next)))))
    result))

(defun hyai--possible-offsets ()
  "Return list of possible indent offsets, last token and its column."
  (let (offs prev curr last-token last-col)
    (hyai--process-syntax-backward
     (lambda (syn c)
       (cl-case syn
         (?\s (setq prev (current-column))
              (skip-syntax-backward " ")
              'next)
         (?w (setq curr (current-column))
             (setq last-token (hyai--grab-syntax-backward "w"))
             (setq last-col (current-column))
             (cond
              ((member last-token '("let" "then" "else"))
               (push (or prev curr) offs)
               (when (and (equal last-token "let")
                          (hyai--botp))
                 (push (current-indentation) offs))
               'stop)
              (t 'next)))
         (?. (setq curr (current-column))
             (setq last-token (hyai--grab-syntax-backward "."))
             (setq last-col (current-column))
             (cond
              ((member last-token '("=" "->" "<-" "::"))
               (push (or prev curr) offs)
               'next)
              ((equal last-token ",")
               (push (or prev curr) offs)
               'stop)
              (t 'next)))
         (?\( (setq curr (current-column))
              (setq last-token (string c))
              (setq last-col (current-column))
              (push (if (= (char-syntax (char-after)) ?\s) prev curr) offs)
              'stop)
         (?> (when (and prev offs
                        (looking-at "^[[:space:]]")
                        (not (member last-token '("->"))))
               (push prev offs))
             'stop))))
    (list offs last-token last-col)))

(defun hyai--search-vertical (limit &optional after-blank)
  "Search vertical bar backward until LIMIT.
If AFTER-BLANK is non-nil, include the last space position in the result."
  (let (result prev)
    (hyai--process-syntax-backward
     (lambda (syn _c)
       (cl-case syn
         (?\s (when after-blank
                (setq prev (current-column))
                (skip-syntax-backward " ")
                'next))
         (?. (let ((s (hyai--grab-syntax-backward ".")))
               (when (string= s "|")
                 (push (or prev (current-column)) result))
               'next))))
     limit)
    (cl-remove-duplicates result)))

(defun hyai--search-vertical-equal (limit)
  "Search vertical bar or equal backward until LIMIT.
Return the first non-space position after it."
  (let (result)
    (hyai--process-syntax-backward
     (lambda (syn _c)
       (when (= syn ?.)
         (let ((s (hyai--grab-syntax-backward ".")) offset)
           (setq offset (current-column))
           (cond
            ((or (string= s "|")
                 (= offset (current-indentation)))
             (push offset result))
            ((string= s "=") (push offset result)))
           'next)))
     limit)
    (cl-remove-duplicates result)))

(defun hyai--find-equal ()
  "Find the first non-space position after equal in the current line."
  (let (result)
    (hyai--process-syntax-backward
     (lambda (syn _c)
       (cl-case syn
         (?\s (setq result (current-column))
              (skip-syntax-backward " ")
              'next)
         (?. (if (string= (hyai--grab-syntax-backward ".") "=")
                 'stop
               'next))
         (?> (setq result nil)
             'stop))))
    result))

(defun hyai--search-comma-bracket (origin)
  "Search comma or bracket backward and return the position.
ORIGIN is a charcter at the original position."
  (let (result)
    (hyai--process-syntax-backward
     (lambda (syn c)
       (cl-case syn
         (?\s (when (hyai--botp)
                (setq result (current-column)))
              nil)
         (?\( (backward-char)
              (cond
               ((null result) (setq result (current-column)))
               ((= origin ?,) (setq result (current-column)))
               ((= c ?\{) (setq result (current-indentation))))
              'stop)
         (?. (pcase (hyai--grab-syntax-backward ".")
               (`"|" (if (= origin ?,)
                         (progn (setq result (current-column)) 'stop)
                       'next))
               (`","
                (if (hyai--botp)
                    (progn (setq result (current-column)) 'stop)
                  (setq result nil) 'next))
               (_ 'next)))
         (?> (backward-char)
             (skip-syntax-backward " ")
             'next))))
    result))

(defun hyai--find-base-offset ()
  "Find position in the current line where the indent is based on."
  (let (result cc)
    (hyai--process-syntax-backward
     (lambda (syn _c)
       (cl-case syn
         (?\s (setq result (current-column))
              nil)
         ((?w ?.)
          (setq cc (current-column))
          (pcase (hyai--grab-syntax-backward (string syn))
            ((or `"let" `"," `"|")
             (unless result
               (setq result cc))
             'stop)
            (_ (setq result nil)
               'next)))
         (?\(
          (setq result (or result (current-column)))
          'stop)
         (?> 'stop))))
    (or result 0)))

(defun hyai--skip-space-backward ()
  "Skip whitespaces backward across lines."
  (hyai--process-syntax-backward
   (lambda (syn _c)
     (cl-case syn
       (?\s (skip-syntax-backward " ")
            'next)
       (?> (backward-char)
           (skip-syntax-backward " ")
           'next)
       (t 'stop)))))

(defun hyai--process-syntax-backward (callback &optional limit)
  "Perform syntax-aware string processing backward.
CALLBACK is called with syntax and character and should return 'stop, 'next
or nil.

 'stop: stop the processing.
 'next: skip to the previous char.
   nil: skip to the previous different syntax.

Process is stopped at the optional LIMIT position."
  (setq limit (or limit 0))
  (let (res)
    (while (and (null (eq res 'stop))
                (> (point) limit)
                (null (bobp)))
      (let* ((c (char-before))
             (syn (char-syntax c))
             (ppss (syntax-ppss))
             (comm-type (nth 4 ppss)))
        (cond
         (comm-type (hyai--goto-comment-start ppss))
         ((and (= c ?\}) (looking-back "-}" limit))
          (backward-char)
          (hyai--goto-comment-start ppss))
         (t
          (setq res (funcall callback syn c))
          (unless res
            (condition-case nil
                (cl-case syn
                  (?> (backward-char))
                  (?\) (backward-sexp))
                  (?\" (backward-sexp))
                  (t (if (= c ?')
                         (backward-sexp)
                       (skip-syntax-backward (string syn)))))
              (error (setq res 'stop))))))))))

(defun hyai--search-context ()
  "Search the current context backward.
Context is \"case\", \"where\" or the token that starts from the BOL."
  (let (result)
    (hyai--process-syntax-backward
     (lambda (syn _c)
       (cl-case syn
         (?> (when (looking-at "^\\([^#[:space:]]+\\)")
               (setq result (match-string-no-properties 1))
               'stop))
         (?w (let ((token (hyai--grab-syntax-backward "w")))
               (when (or (bobp) (member token '("case" "where")))
                 (setq result token)
                 'stop))))))
    result))

(defun hyai--previous-offset ()
  "Return the previous offset with empty lines ignored."
  (skip-syntax-backward " >")
  (current-indentation))

(defun hyai--next-offset ()
  "Return the next offset with empty lines ignored."
  (forward-line 1)
  (skip-syntax-forward " >")
  (current-indentation))

(defun hyai--botp ()
  "Return the current column if it is same as the current indentation."
  (let ((cc (current-column)))
    (and (= (current-column) (current-indentation))
         cc)))

(defun hyai--in-multiline-string-p (ppss)
  "Return non-nil if the current point is in a multiline string using PPSS."
  (and (nth 3 ppss)
       (< (nth 8 ppss)
          (save-excursion (forward-line 0) (point)))))

(defun hyai--in-comment-p (ppss)
  "Return non-nil if the current point is in a comment using PPSS."
  (nth 4 ppss))

(defun hyai--goto-comment-start (&optional ppss)
  "Goto the point where the comment is started usinng PPSS.
If PPSS is not supplied, `syntax-ppss' is called internally."
  (let ((p (nth 8 (or ppss (syntax-ppss)))))
    (when p (goto-char p))))

(defun hyai--grab-token ()
  "Grab one token before the current point."
  (let* ((c (char-before))
         (syn (and c (char-syntax c))))
    (cond
     ((not syn) nil)
     ((member syn '(?\( ?\))) (string c))
     (t (hyai--grab-syntax-backward (string syn))))))

(defun hyai--grab-syntax-forward (syntax)
  "Skip SYNTAX forward and return substring from the current point to it."
  (buffer-substring-no-properties
   (point)
   (progn (skip-syntax-forward syntax) (point))))

(defun hyai--grab-syntax-backward (syntax)
  "Skip SYNTAX backward and return substring from the current point to it."
  (buffer-substring-no-properties
   (point)
   (progn (skip-syntax-backward syntax) (point))))

(defun hyai--offsetnize (obj &optional plus)
  "Make list of offsets from OBJ.
If OBJ is a list, return new list with PLUS added for each element.
If OBJ is a number, return (OBJ + PLUS).
Otherwise, return nil."
  (setq plus (or plus 0))
  (cond
   ((listp obj) (mapcar (lambda (x) (+ x plus)) obj))
   ((numberp obj) (list (+ obj plus)))
   (t nil)))

(defun hyai--cycle-zero-first (offsets)
  "Return new list with modifying OFFSETS so that 0 is the first element.
If OFFSETS does not contain 0, return OFFSETS as is."
  (or
   (catch 'result
     (let (lst i (rest offsets))
       (while (setq i (car rest))
         (if (= i 0)
             (throw 'result (nconc rest (nreverse lst)))
           (push i lst))
         (setq rest (cdr rest)))))
   offsets))

(defun hyai--previous-line-empty-p ()
  "Return non-nil if the previous line is empty.
Comment only lines are ignored."
  (save-excursion
    (catch 'result
      (while (>= (forward-line -1) 0)
        (cond
         ((looking-at-p "^[[:space:]]*$")
          (throw 'result t))
         ((not (looking-at-p "^[[:space:]]*--"))
          (throw 'result nil)))))))

(defun hyai--type-signature-p ()
  "Return non-nil if type signature follows after the current point."
  (looking-at-p "^[[:word:][:punct:]]*[[:space:]]*::"))

(defvar hyai-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<backtab>") #'hyai-indent-backward)
    map))

;;;###autoload
(define-minor-mode hyai-mode
  "Haskell Yet Another Indentation minor mode."
  :lighter " HYAI"
  :keymap hyai-mode-map
  (kill-local-variable 'indent-line-function)
  (when hyai-mode
    (when (and (bound-and-true-p haskell-indentation-mode)
               (fboundp 'haskell-indentation-mode))
      (haskell-indentation-mode 0))
    (set (make-local-variable 'indent-line-function) 'hyai-indent-line)))

(provide 'hyai)
;;; hyai.el ends here
