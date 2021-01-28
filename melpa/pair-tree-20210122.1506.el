;;; pair-tree.el ---  Visualize a list              -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Zainab Ali

;; Author: Zainab Ali <zainab@kebab-ca.se>
;; Keywords: lisp, tools
;; Package-Version: 20210122.1506
;; Package-Commit: 7def8504148603494253559ca137617afb63ebd7
;; URL: https://github.com/zainab-ali/pair-tree

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (dash "2.17.0"))

;;; Commentary:

;; This library creates an explorable box diagram for a given list.
;; This is helpful for learning about linked-list structures in Elisp.

;;; Code:

;; The svg library is required to draw elements
(require 'svg)
(require 'cl-lib)
(require 'subr-x)
(require 'dash)


;;; Core functionality
;; Data types

(cl-defstruct (pair-tree--el (:constructor pair-tree--el-make)
                             (:copier nil))
  (pos nil :documentation "The `pair-tree--pos'")
  (ext nil :documentation "A `pair-tree--pos' of the max col and line index")
  (val nil :documentation "The actual value of the element, if a leaf")
  (node nil :documentation
        "A cons cell of the `pair-tree--el' children, if not a leaf")
  (hanging nil :documentation "`t' if the element is in the car"))

(cl-defstruct (pair-tree--pos (:constructor pair-tree--pos-make)
                              (:copier nil))
  (col nil :documentation "The zero-indexed column of an element")
  (line nil :documentation "The zero-indexed line of an element"))

(defconst pair-tree--keys
  '((empty . ?o)
    (hanging-leaf . ?v)
    (lying-leaf . ?>)
    (lying-node . ?+)
    (hanging-node . ?h)
    (connection . ?-))
  "An assoc list of symbol - character pairs.
Each symbol corresponds to the category of a grid square.
Its character is written to the buffer to represent the category.")

(defun pair-tree--el-category (el)
  "Gets the category of the `pair-tree--el' EL.
It is either a hanging-leaf, a lying-leaf or a hanging-node or a lying-node."
  (if (pair-tree--el-node el)
    ;; It must be a node
      (if (pair-tree--el-hanging el) 'hanging-node 'lying-node)
    ;; It must be a leaf
    (if (pair-tree--el-hanging el) 'hanging-leaf 'lying-leaf)))

(defvar-local pair-tree--tree nil "The viewed `pair-tree--el'.")

;; Point conversion
(defun pair-tree--grid-to-buffer-pos (pos ext-col)
  "Convert a `pair-tree--pos' POS to a buffer position.
EXT-COL is the column extent of the buffer (one less than the width).
The buffer position is behind the grid cell."
  (+ (pair-tree--pos-col pos) 1 (* (pair-tree--pos-line pos) (+ 2 ext-col))))

(defun pair-tree--buffer-to-grid-pos (buf-pos ext-col)
  "Convert a buffer position BUF-POS such as (point) to a `pair-tree--pos'.
EXT-COL is the column extent of the buffer (one less than the width)."
  (let ((col (- (mod buf-pos (+ 2 ext-col)) 1))
        (line (/ buf-pos (+ 2 ext-col))))
    (pair-tree--pos-make :col col :line line)))

;; Construction

(defconst pair-tree--max-list-length
  100
  "The maximum length of a list that can be visualized.
Note that large lists are not displayed well, and lists greater than this number
will exceed the stack depth.")

(defun pair-tree--make (pair)
  "Recursively traverses the cons cells of PAIR to build a `pair-tree-el'."
  (letrec ((go (lambda (pair ;; The current pair
                   col ;; The zero-indexed column
                   line ;; The zero-indexed line
                   is-car ;; Whether the element is the `car' of a parent pair
                   )
                 (let ((pos (pair-tree--pos-make :col col :line line)))
                   (if (consp pair)
                       ;; This is a node
                       (let* ((node-car (funcall go (car pair)
                                                 col (+ 1 line)
                                                 t))
                              (node-car-ext (pair-tree--el-ext node-car))
                              (node-car-col (pair-tree--pos-col node-car-ext))
                              (node-cdr (funcall go
                                                 (cdr pair)
                                                 (+ 1 node-car-col)
                                                 line
                                                 nil))
                              (node-cdr-ext (pair-tree--el-ext node-cdr)))
                         (pair-tree--el-make :pos pos
                                   :ext (pair-tree--pos-make
                                         :col (max
                                               col
                                               node-car-col
                                               (pair-tree--pos-col node-cdr-ext))
                                         :line (max
                                                line
                                                (pair-tree--pos-line node-car-ext)
                                                (pair-tree--pos-line node-cdr-ext)))
                                   :node (cons node-car node-cdr)
                                   :hanging is-car))
                     ;; This is a leaf
                     (pair-tree--el-make :pos pos
                               :ext pos
                               :val pair
                               :hanging is-car))))))
    (funcall go
             pair
             0 0 ;; The col and line are zero-indexed
             nil ;; The first element has no parent, so can't be at the car
             )))

;; Decomposition data types
(cl-defstruct (pair-tree--decomp
               (:constructor pair-tree--decomp-make)
               (:copier nil))
  "The graph decomposition around a focused `pair-tree--el'.
A graph decomposition of a tree around an element refers to all its linked
 elements.
The `pair-tree-el' already has a reference to its children, if any, so there is
no 'children' field as part of this structure."
  (el nil :documentation "The focused `pair-tree--el'")
  (parent nil :documentation "The parent `pair-tree--el' of the focused element"))

;; Decomposition construction

(defun pair-tree--decomp-at-pos (tree pos)
  "Decomposes a TREE around an element at POS."
  ;; Traverse the tree from the top down to find the element at the position
  ;; Record the parent element while doing so
  (letrec ((go (lambda (parent el)
                 (if (equal pos (pair-tree--el-pos el))
                     (pair-tree--decomp-make :el el :parent parent)
                   (when (pair-tree--el-node el)
                     (or (funcall go el (car (pair-tree--el-node el)))
                         (funcall go el (cdr (pair-tree--el-node el)))))))))
    (funcall go nil tree)))

(defun pair-tree--parent-pos (tree pos)
  "Gets the position of the parent of the element at POS in TREE.
Returns nil if the element is the root node and has no parent."
  (-when-let* ((decomp (pair-tree--decomp-at-pos tree pos))
               (parent (pair-tree--decomp-parent decomp)))
    (pair-tree--el-pos parent)))

(defun pair-tree--node-car-pos (tree pos)
  "Gets the position of the car of the pair at POS in TREE.
Returns nil if the element at POS is not a pair."
  (-when-let* ((decomp (pair-tree--decomp-at-pos tree pos))
               (node (pair-tree--el-node (pair-tree--decomp-el decomp)))
               (node-car (car node)))
    (pair-tree--el-pos node-car)))

(defun pair-tree--node-cdr-pos (tree pos)
  "Gets the position of the cdr of the pair at POS in TREE.
Returns nil if the element at POS is not a pair."
  (-when-let* ((decomp (pair-tree--decomp-at-pos tree pos))
               (node (pair-tree--el-node (pair-tree--decomp-el decomp)))
               (node-cdr (cdr node)))
    (pair-tree--el-pos node-cdr)))


;;; Path

(defconst pair-tree--condensed-accessors
(letrec ((go (lambda (n)
            (if (= n 0)
                '("a" "d")
              (let ((xs (funcall go (- n 1))))
                (append
                 (--map (concat "a" it) xs)
                 (--map (concat "d" it) xs)
                 '("a" "d")))))))
  (--sort (> (length it) (length other)) (--map it (funcall go 3))))
"A list of the inner letters of all cons cell accessors.
E.g. ('adaa' 'aada' ...)")

(defun pair-tree--path (tree pos)
  "The path, in 'a and 'd symbols, of the element at POS from the root of TREE."
  (letrec ((go (lambda (el)
                 (if (equal pos (pair-tree--el-pos el))
                     '(t)
                   (when (pair-tree--el-node el)
                     (let ((car-path (funcall go (car (pair-tree--el-node el))))
                           (cdr-path (funcall go (cdr (pair-tree--el-node el)))))
                       (if car-path
                           (cons "a" car-path)
                         (when cdr-path (cons "d" cdr-path))))))))
           (path (cdr (reverse (funcall go tree)))))
    path))

(defun pair-tree--path-condensed (path)
  "Condense the PATH from a list of 'a and 'd symbols to composed accessors.
Return a list of string accessors.
For example, the path (\"a\" \"d\") is condensed to (\"ad\")."
  (letrec ((str-path (apply #'concat path))
           (go (lambda (str)
                 (let ((accessor
                        (--find (string-suffix-p it str)
                                pair-tree--condensed-accessors)))
                   (if accessor
                       (cons accessor
                             (funcall go (substring str 0 (- (length accessor)))))
                     ;; There is no accessor. Return a list of letters
                     (reverse (--map (char-to-string it) str)))))))
    (reverse (funcall go str-path))))

(defun pair-tree--path-str (path)
  "Return the expression corresponding to PATH.
PATH must be a list of condensed accessors."
  (letrec ((go (lambda (path)
              (if path
                  (format "(c%sr %s)" (car path) (funcall go (cdr path)))
                ;; If at the root, print "tree"
                "tree"))))
    (funcall go path)))

(defun pair-tree--path-print (tree pos)
  "Print the path of the the element at grid POS in TREE to the minibuffer."
  (-when-let (path (pair-tree--path-condensed (pair-tree--path tree pos)))
    (message (pair-tree--path-str path))))

;;; Sexp

;; Data types
(cl-defstruct (pair-tree--sexp-region
               (:constructor pair-tree--sexp-region-make)
               (:copier nil))
  (start nil :documentation "Marks the start of the cons cell in the sexp buffer.")
  (end nil :documentation "Marks the end of the cons cell in the sexp buffer."))

(defvar-local pair-tree--regions nil
  "An assoc list of `pair-tree--pos' to sexp regions.")

(defun pair-tree--write-sexp (tree)
  "Recursively write a TREE to the current buffer.
Returns an assoc list of `pair-tree--pos' to regions."
  (letrec ((go (lambda (el)
                 (if (pair-tree--el-node el)
                     (let ((start (point-marker)))
                       (insert "(cons ")
                       (let ((car-regions (funcall go (car (pair-tree--el-node el)))))
                         (insert "\n")
                         (let ((cdr-regions (funcall go (cdr (pair-tree--el-node el)))))
                           (insert ")")
                           (append car-regions
                                   cdr-regions
                                   (list
                                    (cons
                                     (pair-tree--el-pos el)
                                     (pair-tree--sexp-region-make
                                      :start start
                                      :end (point-marker))))))))
                   (let ((val (pair-tree--el-val el))
                         (start (point-marker)))
                     (insert (format "%S" val))
                  (list (cons (pair-tree--el-pos el)
                         (pair-tree--sexp-region-make :start start
                                                 :end (point-marker))))))))
           (inhibit-read-only t))
    (erase-buffer)
    (let ((regions (funcall go tree)))
      (setq-local pair-tree--regions regions))
    (indent-region (point-min) (point-max))))

;; Focus
(defun pair-tree--sexp-focus-remove ()
  "Remove any existing overlays."
  (--each (overlays-in (point-min) (point-max)) (delete-overlay it)))

(defun pair-tree--sexp-focus-set (pos)
  "Focus a sexp at grid position POS."
  (-when-let* ((region (cdr (assoc pos pair-tree--regions)))
         (start (marker-position (pair-tree--sexp-region-start region)))
         (end (marker-position (pair-tree--sexp-region-end region)))
         (inhibit-read-only t))
    (pair-tree--sexp-focus-remove)
    (pair-tree--sexp-overlay-make start end)))

(defun pair-tree--sexp-overlay-make (start end)
  "Create an overlay from START to END."
  (let ((overlay (make-overlay start end)))
    (overlay-put overlay 'face 'highlight)))



;; Sexp
(defun pair-tree--sexp-buf ()
  "Get or create the *sexp* buffer."
  (unless (get-buffer "*sexp*")
    (with-current-buffer (get-buffer-create "*sexp*")
      (lisp-interaction-mode)
      (read-only-mode t)))
  (get-buffer "*sexp*"))

;;; Pair-tree

;; Display measurements

(defconst pair-tree-word-length 8 "The maximum number of characters displayed on a leaf.")

(defconst pair-tree--stroke-width 5 "The width of branch lines and leaf outlines.")

(defun pair-tree--char-height ()
  "The height in pt of a character in an SVG.
This is taken from the default font height."
  (/ (face-attribute 'default ':height)
     ;; The default font height is specified in units of
     ;; 1/10pt
     10.0))

(defun pair-tree--char-width ()
  "The approximate width in pt of a character in an SVG.

This is taken from the default font height."
  ;; For a monospaced font, the width is usually 0.8 of the height
  (* 0.8 (pair-tree--char-height)))

(defun pair-tree--image-length ()
  "The length in pt of each SVG."
  ;; An SVG must fit a word and a space to pad it.
  (* (+ 1 pair-tree-word-length) (pair-tree--char-width)))

;; Display

(defun pair-tree--image (char val)
  "Return the SVG image to display in place of CHAR.
If the CHAR represents a leaf, the VAL is displayed in the SVG.
The VAL can be any object.  It is formatted as an sexp and trimmed to
`pair-tree-word-length'."
  (let* ((len (pair-tree--image-length))
         (mid (/ len 2.0))
         (svg (svg-create len len
                          :stroke-width pair-tree--stroke-width)))
    (pcase (pair-tree--category-of char)
      ('hanging-leaf (pair-tree--image-svg-circle svg mid val))
      ('lying-leaf (pair-tree--image-svg-circle svg mid val))
      (`connection (pair-tree--image-svg-branch svg `(0 . ,mid) `(,len . 0)))
      ('lying-node (pair-tree--image-svg-branch svg `(0 . ,mid) `(,len . 0))
                   (pair-tree--image-svg-branch svg `(,mid . ,mid) `(0 . ,mid)))
      ('hanging-node (pair-tree--image-svg-branch svg `(,mid . 0) `(0 . ,len))
                     (pair-tree--image-svg-branch svg `(,mid . ,mid) `(,mid . 0))))
    (svg-image svg :scale 1)))

(defun pair-tree--image-svg-branch (svg start leg)
  "Draws a straght line on an SVG.
START is a cons cell of x and y.
LEG is a cons cell of the x and y distance to move."
  (svg-path svg `((moveto (,start))
                  (lineto (,leg)))
            :stroke-color (face-attribute 'default ':foreground)
            :stroke-width pair-tree--stroke-width
            :relative t))

(defun pair-tree--image-svg-circle (svg mid val)
  "Draws a circle centred at MID on an SVG.
Prints the VAL within the circle."
  (svg-circle svg mid mid (- mid pair-tree--stroke-width)
              :stroke-color (face-attribute 'default ':foreground)
              :fill-color "transparent"
              :stroke-width 5)
  (let* ((text (seq-take (format "%S" val) pair-tree-word-length))
         ;; Centre the text.
         ;; Starting from the midpoint, walk backwards by half the text width.
         (x-offset (- mid (* (/ (length text) 2.0) (pair-tree--char-width))))
         ;; Starting from the midpoint, walk backwards by half the text height.
         (y-offset (+ mid (/ (pair-tree--char-height) 2.0))))
    (svg-text
     svg
     text
     :font-size (font-get (face-attribute 'default ':font) ':size)
     :font-weight (face-attribute 'default ':weight)
     :fill (face-attribute 'default ':foreground)
     :font-family (face-attribute 'default ':family)
     :x x-offset
     :y y-offset)))

(defun pair-tree--display-image (char &optional val)
  "Return a string of CHAR with a display property set to an SVG image.
VAL is displayed in the image, if present."
  (propertize (char-to-string char)
              'display (pair-tree--image char val)))

;; Writing

(defun pair-tree--char-of (category)
  "Get the character representing CATEGORY."
  (cdr (assoc category pair-tree--keys)))
(defun pair-tree--category-of (char)
  "Get the category representing CHAR."
  (car (--find (equal char (cdr it)) pair-tree--keys)))

(defun pair-tree--write-category (category pos &optional val)
  "Writes an element to the buffer.
The character written is determined by CATEGORY.  If the element is a leaf,
the leaf's VAL is included in the displayed SVG.
It assumes that the grid spans the POS (no new lines or columns are created)."
  (goto-char (pair-tree--grid-to-buffer-pos pos (pair-tree--pos-col (pair-tree--el-ext pair-tree--tree))))
  (delete-char 1)
  (insert (pair-tree--display-image (pair-tree--char-of category) val)))

(defun pair-tree--write-connections (parent-pos child-pos)
  "Write the connectors between a parent node and a child cdr.
PARENT-POS is the `pair-tree--pos' of the parent.
CHILD-POS is th e`pair-tree--pos' of the child.
Both elements are assumed to share the same line (the cdr is to the right)."
  (let ((cols (number-sequence
               (+ 1 (pair-tree--pos-col parent-pos))
               (- (pair-tree--pos-col child-pos) 1))))
    (--each cols
      (let ((pos (pair-tree--pos-make :col it :line (pair-tree--pos-line parent-pos))))
        (pair-tree--write-category 'connection pos)))))

(defun pair-tree--write-el (el)
  "Writes the character for EL to the buffer.
If EL has a child node, writes the connections to its cdr."
  (pair-tree--write-category (pair-tree--el-category el) (pair-tree--el-pos el) (pair-tree--el-val el))
  (when (pair-tree--el-node el)
    (pair-tree--write-connections (pair-tree--el-pos el) (pair-tree--el-pos (cdr (pair-tree--el-node el))))))

(defun pair-tree--grid (ext)
  "A string of spaces making up the grid.
The string has of (+ (-pos-line EXT) 1) lines and (+ (-pos-col EXT) 1) columns"
  (let ((line (make-string (+ 1 (pair-tree--pos-col ext)) (pair-tree--char-of 'empty))))
    (string-join (-map
                  (lambda (_it) line)
                  (number-sequence 0 (pair-tree--pos-line ext)))
                 "\n")))

(defun pair-tree--write-tree (tree)
  "Writes a `pair-tree--el' TREE recursively."
  (letrec ((grid (pair-tree--grid (pair-tree--el-ext tree)))
           (display-grid
            (string-join
             (--map (if (not (equal it ?\n))
                        (pair-tree--display-image it)
                      (char-to-string it))
                    grid)))
           (go (lambda (el)
                 (pair-tree--write-el el)
                 (when (pair-tree--el-node el)
                   (funcall go (car (pair-tree--el-node el)))
                   (funcall go (cdr (pair-tree--el-node el))))))
           (inhibit-read-only t))
    (setq-local pair-tree--tree tree)
    (erase-buffer)
    (goto-char (point-min))
    (insert display-grid)
    (funcall go tree)))

;; Motion
(defun pair-tree--goto-pos (pos)
  "Move the point to POS."
  (goto-char (pair-tree--grid-to-buffer-pos pos (pair-tree--pos-col (pair-tree--el-ext pair-tree--tree))))
  (pair-tree--focus-set pos)
  (pair-tree--path-print pair-tree--tree pos))

(defun pair-tree-nav-up ()
  "Move the point up to the parent cell."
  (interactive)
  (-when-let (pos (pair-tree--parent-pos
                   pair-tree--tree
                   (pair-tree--buffer-to-grid-pos (point)
                                         (pair-tree--pos-col (pair-tree--el-ext pair-tree--tree)))))
    (pair-tree--goto-pos pos)))

(defun pair-tree-nav-down ()
  "Move the point down to the car (the first child)."
  (interactive)
  (-when-let (pos (pair-tree--node-car-pos
                   pair-tree--tree
                   (pair-tree--buffer-to-grid-pos (point)
                                         (pair-tree--pos-col (pair-tree--el-ext pair-tree--tree)))))
    (pair-tree--goto-pos pos)))

(defun pair-tree-nav-right ()
  "Move the point right to the cdr (the second child)."
  (interactive)
  (-when-let (pos (pair-tree--node-cdr-pos pair-tree--tree
                                  (pair-tree--buffer-to-grid-pos
                                   (point)
                                   (pair-tree--pos-col (pair-tree--el-ext pair-tree--tree)))))
    (pair-tree--goto-pos pos)))

(defun pair-tree-nav-mouse ()
  "Focus on the point."
  (interactive)
  (let ((pos (pair-tree--buffer-to-grid-pos (point)
                                   (pair-tree--pos-col (pair-tree--el-ext pair-tree--tree)))))
    (if (pair-tree--decomp-at-pos pair-tree--tree pos)
        (pair-tree--goto-pos pos)
      (pair-tree--focus-remove))))

;; Focus
(defvar-local pair-tree--focus nil "The `pair-tree--pos' of the focused element, if any.")

(defun pair-tree--focus-set (pos)
  "Set the focus to the POS in the *pair-tree* buffer."
  (setq-local pair-tree--focus pos)
  ;; Update the focus in the *sexp* buffer
  (with-current-buffer (pair-tree--sexp-buf)
    (pair-tree--sexp-focus-set pos)))

(defun pair-tree--focus-remove () "Remove the focus." (setq-local pair-tree--focus nil)
       (with-current-buffer (pair-tree--sexp-buf)
         (pair-tree--sexp-focus-remove)))

;; Buffer
(defun pair-tree--buf ()
  "Get or create the *pair-tree* buffer."
  (unless (get-buffer "*pair-tree*")
    (with-current-buffer (get-buffer-create "*pair-tree*")
      (pair-tree-mode)))
  (get-buffer "*pair-tree*"))

;; Mode
(defvar pair-tree-mode-map
  (let ((map (make-sparse-keymap 'pair-tree-mode-map)))
    (define-key map [left]  'pair-tree-nav-up)
    (define-key map [up]  'pair-tree-nav-up)
    (define-key map [down]  'pair-tree-nav-down)
    (define-key map [right]  'pair-tree-nav-right)
    (define-key map [mouse-1]  'pair-tree-nav-mouse)
    map)
  "Keymap for `pair-tree-mode'.")


(define-derived-mode pair-tree-mode special-mode "Pair-Tree"
  "Visualizes cons cells in a pair tree.
\n\\{pair-tree-mode-map}")

;;;###autoload
(defun pair-tree (pair)
  "Draw a pair tree for PAIR."
  (interactive (list (let ((arg (read-string "Expression: " "nil")))
                       (condition-case nil
                           (eval (read arg))
                         (error (error "Emacs couldn't evaluate '%s'" arg))))))
  (if (< (length (-flatten pair)) pair-tree--max-list-length)
      (if (image-type-available-p 'svg)
        (let ((tree (pair-tree--make pair)))
          (with-current-buffer (pair-tree--buf)
            (pop-to-buffer (pair-tree--buf))
            (pair-tree--write-tree tree)
            (goto-char (point-min)))
          (with-current-buffer (pair-tree--sexp-buf)
            (pair-tree--write-sexp tree))
          (pop-to-buffer (pair-tree--buf))
          (switch-to-buffer-other-window (pair-tree--sexp-buf))
          (select-window (get-buffer-window (pair-tree--buf))))
        (error "This Emacs version does not support SVGs"))
    (error "List is too large to visualize")))

(provide 'pair-tree)

;;; pair-tree.el ends here
