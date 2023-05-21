;;; scopeline.el --- Show scope info of blocks in buffer at end of scope -*- lexical-binding: t; -*-

;; URL: https://github.com/meain/scopeline.el
;; Package-Version: 20230521.614
;; Package-Commit: 6733f0f7ca33aa5c8ad83099dcb7b7ff8bc46a68
;; Keywords: scope, context, tree-sitter, convenience
;; SPDX-License-Identifier: Apache-2.0
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.1

;;; Commentary:
;; This package lets you show the scope info of blocks like function
;; definitions, loops, conditions etc.  It does this by adding the
;; first line of these blocks at the end of the last char of that
;; block.  It makes use of `tree-sitter' to figure out block start and
;; end.
;;
;; The package exposes a single minor mode `scopeline-mode' which you
;; can use to enable or disable the functionality.
;;
;; Here is a sample `use-package' configuration
;;
;; (use-package scopeline
;;   :config (add-hook 'prog-mode-hook #'scopeline-mode))
;;
;; You can find more info in the README for the project at
;; https://github.com/meain/scopeline.el

;;; Code:
(require 'subr-x)
(defvar scopeline--can-use-elisp-treesitter
  (require 'tree-sitter nil t)
  "If non-nil, we are can make use of elisp-tree-sitter instead of builtin.")
(defvar scopeline--can-use-builtin-treesit
  (require 'treesit nil t)
  "If non-nil, we are can make use of builtin treesit instead of elisp-tree-sitter.")

(defgroup scopeline nil
  "Show info about the block at the end of the block."
  :group 'tools)

;; Ignore warnings from optionally requiring tree-sitter and treesit
(defvar tree-sitter-language)
(defvar tree-sitter-tree)
(declare-function tsc-node-byte-range "tsc" t t)
(declare-function tsc--buffer-substring-no-properties "tsc")
(declare-function tsc-query-matches "tsc")
(declare-function tsc-root-node "tsc" t t)
(declare-function tsc-make-query "tsc")
(declare-function treesit-node-end "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-query-capture "treesit.c")
(declare-function treesit-buffer-root-node "treesit")

(defvar-local scopeline--overlays '() "List to keep overlays applies in buffer.")
(defcustom scopeline-overlay-prefix "  ¤ "
  "Prefix to use for overlay."
  :type 'string
  :group 'scopeline)
(defcustom scopeline-min-lines 5
  "Minimum number of lines for block before we show scope info."
  :type 'integer
  :group 'scopeline)
(defface scopeline-face
  '((default :inherit font-lock-comment-face))
  "Face for showing scope info."
  :group 'scopeline)
(defcustom scopeline-targets ;; TODO: Add more language modes
  '(
    ;; TODO: Should this be more complex queries (for example gets
    ;; name of func for func) as it might look weird if only the
    ;; return type is on the first line in case of c-mode entries
    (c-mode . ("function_definition" "for_statement" "if_statement" "while_statement"))
    (css-mode . ("rule_set"))
    (go-mode . ("function_declaration" "func_literal" "method_declaration" "if_statement" "for_statement" "type_declaration"))
    (html-mode . ("element"))
    (javascript-mode . ("function" "function_declaration" "if_statement" "for_statement" "while_statement"))
    (js-mode . ("function" "function_declaration" "if_statement" "for_statement" "while_statement"))
    (js2-mode . ("function" "function_declaration" "if_statement" "for_statement" "while_statement"))
    (js3-mode . ("function" "function_declaration" "if_statement" "for_statement" "while_statement"))
    (typescript-mode . ("function" "function_declaration" "if_statement" "for_statement" "while_statement"))
    (json-mode . ("pair"))
    (toml-mode . ("pair"))
    (mhtml-mode . ("element"))
    (nix-mode . ("bind"))
    (python-mode . ("function_definition" "if_statement" "for_statement"))
    (ruby-mode . ("block" "case" "do_block" "if" "method" "singleton_method" "unless" "class"))
    (rust-mode . ("function_item" "for_expression" "if_expression"))
    (sh-mode . ("function_definition" "if_statement" "while_statement" "for_statement" "case_statement"))
    (yaml-mode . ("block_mapping_pair")))
  "Tree-sitter entities for scopeline target."
  :type '(repeat (cons symbol (repeat string)))
  :group 'scopeline)

(defun scopeline--use-builtin-treesitter ()
  "Return non-nil if we should use builtin treesitter."
  (and scopeline--can-use-builtin-treesit
       (string-suffix-p "-ts-mode" (symbol-name major-mode))))

(defun scopeline--add-overlay (pos text)
  "Add overlay at `POS' with the specified `TEXT'."
  (dolist (ov (overlays-in pos pos))
    (when (overlay-get ov 'scopeline)
      (setq scopeline--overlays (delete ov scopeline--overlays))
      (delete-overlay ov)))
  (let ((ov (make-overlay pos pos)))
    (overlay-put ov 'after-string
                 (propertize (format "%s%s" scopeline-overlay-prefix text)
                             'face 'scopeline-face
                             'cursor t))
    ;; Mark this overlay as belonging to scopeline
    (overlay-put ov 'scopeline t)
    (add-to-list 'scopeline--overlays ov)))

(defun scopeline--delete-all-overlays ()
  "Delete all scopeline related overlays."
  (dolist (ov scopeline--overlays)
    (delete-overlay ov))
  (setq scopeline--overlays '()))

(defun scopeline-delete-all-overlays ()
  "Delete all overlays created by scopeline.
You should not ideally have to use it.  This is only in case something
bad happens and scopeline leaves around unnecessary overlays."
  (interactive)
  (let ((overlays (overlays-in (point-min) (point-max))))
    (dolist (ov overlays)
      (when (overlay-get ov 'scopeline)
        (delete-overlay ov)))))

(defun scopeline--get-query-matches (query)
  "Return list of matches for `QUERY' based on the treesitter lib available."
  (if (scopeline--use-builtin-treesitter)
      (let* ((root (treesit-buffer-root-node))
             (matches (treesit-query-capture root query)))
        (seq-map (lambda (x)
                   (cons (treesit-node-start (cdr x))
                         (treesit-node-end (cdr x))))
                 matches))
    (if scopeline--can-use-elisp-treesitter
        (let* ((query-p (tsc-make-query tree-sitter-language query))
               (root-node (tsc-root-node tree-sitter-tree))
               (matches (tsc-query-matches query-p root-node #'tsc--buffer-substring-no-properties)))
          (seq-map (lambda (x)
                     (let* ((entity (seq-elt (cdr x) 0))
                            (pos (tsc-node-byte-range (cdr entity))))
                       (cons (byte-to-position (car pos)) (byte-to-position (cdr pos)))))
                   matches))
      (message "Unable to use builtin treesit or elisp-treesitter"))))

(defun scopeline--get-targets-for-mode (mode)
  "Return scopeline targets for `MODE'."
  (cdr (assq
        (if (scopeline--use-builtin-treesitter)
            (intern (replace-regexp-in-string "-ts-mode$" "-mode" (symbol-name mode)))
          mode)
        scopeline-targets)))

(defun scopeline--show ()
  "Show all the scopeline items in buffer."
  (when-let* ((scopeline-targets-for-mode (scopeline--get-targets-for-mode major-mode))
              (query (progn
                       (string-join
                        (seq-map (lambda (ct)
                                   (format "(%s) @entity" ct))
                                 scopeline-targets-for-mode)
                        "\n")))
              (matches (scopeline--get-query-matches query)))
    (seq-map (lambda (x) ; TODO: seq-map might not be the best option here
               (let* ((start-pos (car x))
                      (end-pos (cdr x))
                      (start-line (line-number-at-pos start-pos))
                      (end-line (line-number-at-pos end-pos))
                      (line-difference (- end-line start-line)))
                 (if (> line-difference scopeline-min-lines)
                     (scopeline--add-overlay
                      (save-excursion
                        (goto-char end-pos)
                        (end-of-line)
                        (point))
                      (save-excursion
                        (goto-char start-pos)
                        (string-trim (thing-at-point 'line)))))))
             ;; Reversing the matches here so that it shows up in
             ;; correct order for indent based languages like python
             (reverse matches))))

;;;###autoload
(define-minor-mode scopeline-mode
  "Show scopeline of first line on last line."
  :lighter " scopeline"
  (if scopeline-mode
      (if (scopeline--use-builtin-treesitter)
          (add-hook 'after-change-functions #'scopeline--redisplay nil t)
        (if scopeline--can-use-elisp-treesitter
            (progn
              (add-hook 'tree-sitter-after-first-parse-hook #'scopeline--redisplay nil t)
              (add-hook 'tree-sitter-after-change-functions #'scopeline--redisplay nil t))
          (message "Unable to enable scopeline mode, tree-sitter not available.")))
    (progn
      (if (scopeline--use-builtin-treesitter)
          (remove-hook 'after-change-functions #'scopeline--redisplay t)
        (remove-hook 'tree-sitter-after-change-functions #'scopeline--redisplay t))
      (scopeline--delete-all-overlays))))

(defun scopeline--redisplay (&rest _)
  "Re-display all the scopeline entries."
  (scopeline--delete-all-overlays)
  (scopeline--show))

(provide 'scopeline)
;;; scopeline.el ends here
