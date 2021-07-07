;;; js2-closure.el --- Google Closure dependency manager

;; Copyright 2017 Google Inc. All rights reserved.

;; Author: Justine Tunney <jart@google.com>
;; Version: 2.0
;; Package-Version: 20170816.1918
;; Package-Commit: f59db386d7d0693935d0bf52babcd2c203c06d04
;; License: Apache 2.0
;; URL: http://github.com/jart/js2-closure
;; Package-Requires: ((js2-mode "20150909"))
;; Keywords: javascript closure

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;    http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:
;;
;; Do you use Emacs, `js2-mode', and Google's Closure Library?  Do you get
;; frustrated writing your `goog.require` statements by hand?  If that's the
;; case, then this extension is going to make you very happy.
;;
;; js2-closure is able to analyse the JavaScript code in your buffer to
;; determine which imports you need, and then update the `goog.require` list at
;; the top of your buffer.  It works like magic.  It also runs instantaneously,
;; even if you have a big project.
;;
;; This tool only works on files using traditional namespacing,
;; i.e. `goog.provide` and `goog.require`.  However js2-closure is smart enough
;; to turn itself off in files that use `goog.module` or ES6 imports.

;;; Installation:
;;
;; Install this package from MELPA using `M-x install-package` and type
;; `js2-closure`.  If you aren't already using MELPA, see:
;; http://melpa.milkbox.net/#/getting-started
;;
;; You then need to run a helper script that crawls all your JavaScript sources
;; for `goog.provide` statements, in addition to your Closure Templates (Soy)
;; for `{namespace}` declarations (assuming you're using the Soy to JS
;; compiler).  You must also download the source code to the Closure Library
;; and pass this script the path of the `closure/goog` folder.
;;
;; Here's an example command for regenerating the provides index that you can
;; add to your `~/.bashrc` file:
;;
;;     jsi() {
;;       local github="https://raw.githubusercontent.com"
;;       local script="js2-closure-provides.sh"
;;       bash <(wget -qO- ${github}/jart/js2-closure/master/${script}) \
;;         ~/code/closure-library/closure/goog \
;;         ~/code/my-project/js \
;;         ~/code/my-project/soy \
;;         >~/.emacs.d/js2-closure-provides.el
;;     }
;;
;; That will generate an index file in your `~/.emacs.d` directory.  If you
;; want to store it in a different place, then `js2-closure-provides-file' will
;; need to be customised.
;;
;; This index file will be loaded into Emacs automatically when the timestamp
;; on the file changes.  You need to re-run the script manually whenever new
;; `goog.provide` statements are added or removed.  Automating that part is up
;; to you.

;;; Usage:
;;
;; To use this, you simply run `M-x js2-closure-fix` inside your `js2-mode'
;; buffer.  This will regenerate the list of `goog.require` statements by
;; crawling your source code to see which identifiers are being used.
;;
;; If you want the magic to happen automatically each time you save the buffer,
;; then add the following to your `.emacs` file:
;;
;;     (eval-after-load 'js2-mode
;;       '(add-hook 'before-save-hook 'js2-closure-save-hook))
;;
;; Alternatively, you can use a key binding as follows:
;;
;;     (eval-after-load 'js2-mode
;;       '(define-key js2-mode-map (kbd "C-c C-c") 'js2-closure-fix))
;;
;; This tool was written under the assumption that you're following Google's
;; JavaScript style guide: http://goo.gl/Ny5WxZ
;;
;; You can customize the behavior of js2-closure with the following settings:
;;
;; o `js2-closure-remove-unused'
;; o `js2-closure-whitelist'
;;
;; See the source code for more information.

;;; Code:

(require 'js2-mode)

(defcustom js2-closure-remove-unused t
  "Determines if unused goog.require statements should be auto-removed.
You might want to consider using `js2-closure-whitelist' rather
than disabling this feature.  Or you can add a @suppress
{extraRequire} JSDoc before before the require."
  :type 'boolean
  :group 'js2-mode)

(defcustom js2-closure-whitelist
  '("goog.testing.asserts"
    "goog.testing.jsunit")
  "List of goog.require namespaces that should never be removed."
  :type '(repeat string)
  :group 'js2-mode)

(defcustom js2-closure-provides-file
  (concat user-emacs-directory "js2-closure-provides.el")
  "Filename of generated elisp file listing all provided namespaces."
  :type 'file
  :group 'js2-mode)

(defconst js2-closure-help-url
  "https://github.com/jart/js2-closure"
  "URL of documentation to provide help to lost souls.")

(defvar js2-closure-provides nil
  "Hierarchy of all closure provided namespaces.")

(defvar js2-closure-provides-modified nil
  "Modified timestamp of `js2-closure-provides-file'.")

(defconst js2-closure-namespace-regexp
  (concat js2-mode-identifier-re "\\(?:\\." js2-mode-identifier-re "\\)*")
  "Matches a Closure namespace.")

(defconst js2-closure-jsdoc-simple-type-tag-regexp
  (concat "\\*\\s-*@"
          (regexp-opt '("extends" "implements"))
          "\\(?:\\s-+\\|\\s-*{\\)\\("
          js2-closure-namespace-regexp
          "\\)")
  "Matches JSDoc type declarations that can't have things like unions.")

(defconst js2-closure-jsdoc-compound-type-tag-regexp
  (concat "\\s-*@"
          (regexp-opt
           '("const"
             "define"
             "enum"
             "package"
             "param"
             "private"
             "protected"
             "public"
             "return"
             "throws"
             "type"
             "typedef"))
          "\\s-*{\\([^}]+\\)}")
  "Matches JSDoc type declarations that could potentially be complex.")

(defun js2--closure-nested-namespace-p (identifier)
  "Return non-nil if IDENTIFIER has labels after one is capitalized."
  (let (result)
    (while identifier
      (let ((first-char (string-to-char (symbol-name (pop identifier)))))
        (when (and (>= first-char ?A)
                   (<= first-char ?Z))
          (setq result identifier
                identifier nil))))
    result))

(defun js2--closure-prune-provides (list)
  "Remove identifiers from LIST that shouldn't be required.
Nested namespaces such as `goog.Foo.Bar` are provided in the
Closure Library source code on several occasions.  However if you
try to require these namespaces, then `gjslint` will complain,
because it only wants us to require `goog.Foo`."
  (nreverse
   (let (result)
     (dolist (item list result)
       (when (not (js2--closure-nested-namespace-p item))
         (push item result))))))

(defun js2--closure-make-tree (list)
  "Turn sorted LIST of identifiers into a tree."
  (let (result)
    (while list
      (let (sublist
            (name (caar list))
            (is-leaf (null (cdar list))))
        (while (eq name (caar list))
          (let ((item (pop list)))
            (when (cdr item)
              (push (cdr item) sublist))))
        (let ((subtree (js2--closure-make-tree (nreverse sublist))))
          (push (cons name (cons is-leaf subtree)) result))))
    (nreverse result)))

(defun js2--closure-member-tree (identifier tree)
  "Return t if IDENTIFIER is a member of TREE."
  (let ((branch (assq (car identifier) tree)))
    (if (and branch (cdr identifier))
        (js2--closure-member-tree (cdr identifier) (cddr branch))
      (cadr branch))))

(defun js2--closure-make-identifier (node &optional names)
  "Turn NODE (or string) into an ordered list of interned NAMES."
  (cond ((js2-prop-get-node-p node)
         (js2--closure-make-identifier
          (js2-prop-get-node-left node)
          (js2--closure-make-identifier
           (js2-prop-get-node-right node)
           names)))
        ((and (js2-node-p node)
              (js2-prop-node-name node))
         (cons (intern (js2-prop-node-name node)) names))
        ((stringp node)
         (mapcar 'intern (split-string node "\\.")))))

(defun js2--closure-identifier-to-string (identifier)
  "Convert IDENTIFIER into a dotted string."
  (mapconcat 'symbol-name identifier "."))

(defun js2--closure-crawl (ast on-call on-identifier on-identifier-jsdoc)
  "Crawl `js2-mode' AST and invoke callbacks on nodes.
ON-CALL will be invoked for all `js2-call-node' nodes, passing
the node itself as the first argument.

ON-IDENTIFIER is invoked for all identifiers, passing as an
argument the last `js2-prop-get-node' in the chain of labels
making up that identifier.

ON-IDENTIFIER-JSDOC is invoked for all identifiers that appear in
JSDoc comments."
  (let (last)
    (js2-visit-ast
     ast
     (lambda (node endp)
       (unless endp
         (when (js2-call-node-p node)
           (funcall on-call node))
         (cond ((and (js2-prop-get-node-p node)
                     (or (not last)
                         (eq last (js2-prop-get-node-left node))))
                (setq last node))
               ((and (not (js2-prop-get-node-p node))
                     last)
                (funcall on-identifier last)
                (setq last nil)))
         t)))
    (when last
      (funcall on-call last)))
  (let ((jsdocs (js2--closure-extract-jsdocs ast)))
    (dolist (jsdoc jsdocs)
      (let ((items (js2--closure-extract-namespaces jsdoc)))
        (dolist (item items)
          (funcall on-identifier-jsdoc item))))))

(defun js2--closure-extract-jsdocs (ast)
  "Return list of JSDoc strings in AST."
  (let (result (comments (js2-ast-root-comments ast)))
    (dolist (node comments result)
      (when (eq (js2-comment-node-format node) 'jsdoc)
        (let ((value (buffer-substring-no-properties
                      (js2-node-abs-pos node)
                      (+ (js2-node-abs-pos node)
                         (js2-node-len node)))))
          (setq result (cons value result)))))))

(defun js2--closure-extract-namespaces (jsdoc)
  "Extract namespaces from Closure type tags in JSDOC."
  (let (result)
    (let ((i 0))
      (while (string-match js2-closure-jsdoc-compound-type-tag-regexp jsdoc i)
        (setq i (match-end 0))
        (let ((j 0)
              (compound-type (match-string 1 jsdoc)))
          (while (string-match js2-closure-namespace-regexp compound-type j)
            (setq j (match-end 0)
                  result (cons (match-string 0 compound-type) result))))))
    (let ((i 0))
      (while (string-match js2-closure-jsdoc-simple-type-tag-regexp jsdoc i)
        (setq i (match-end 0)
              result (cons (match-string 1 jsdoc) result))))
    (delete-dups result)))

(defun js2--closure-determine-requires (ast)
  "Return closure namespaces in AST to be imported.
The result is a cons cell containing two sorted lists.  The first
is namespaces that should be required.  The second is namespaces
referenced only in JSDoc that should be forward-declared."
  (let (provides requires forwards references references-jsdoc)
    (let ((on-call
           (lambda (node)
             (let ((funk (js2--closure-make-identifier
                          (js2-call-node-target node)))
                   (arg1 (car (js2-call-node-args node))))
               (cond ((and (equal funk '(goog provide))
                           (js2-string-node-p arg1))
                      (add-to-list 'provides (js2--closure-make-identifier
                                              (js2-string-node-value arg1))))
                     ((and (equal funk '(goog require))
                           (js2-string-node-p arg1))
                      (add-to-list 'requires (js2--closure-make-identifier
                                              (js2-string-node-value arg1))))
                     ((and (equal funk '(goog module get))
                           (js2-string-node-p arg1))
                      (add-to-list 'references (js2--closure-make-identifier
                                                (js2-string-node-value arg1))))
                     ((and (equal funk '(goog forwardDeclare))
                           (js2-string-node-p arg1))
                      (add-to-list 'forwards (js2--closure-make-identifier
                                              (js2-string-node-value arg1))))))))
          (on-identifier
           (lambda (node)
             (let ((item (js2--closure-make-identifier node)))
               (while item
                 (cond ((member item provides)
                        (setq item nil))
                       ((member item requires)
                        (add-to-list 'references item)
                        (setq item nil))
                       ((js2--closure-member-tree item js2-closure-provides)
                        (add-to-list 'references item)
                        (setq item nil)))
                 (setq item (butlast item))))))
          (on-identifier-jsdoc
           (lambda (node)
             (let ((item (js2--closure-make-identifier node)))
               (while item
                 (cond ((or (member item provides))
                        (setq item nil))
                       ((js2--closure-member-tree item js2-closure-provides)
                        (add-to-list 'references-jsdoc item)
                        (setq item nil)))
                 (setq item (butlast item)))))))
      (js2--closure-crawl ast on-call on-identifier on-identifier-jsdoc))
    (let* ((to-require
            (let (result)
              (dolist (item requires)
                (let ((namespace (js2--closure-identifier-to-string item)))
                  (when (or (not js2-closure-remove-unused)
                            (member namespace js2-closure-whitelist)
                            (member item references))
                    (push namespace result))))
              (dolist (item references result)
                (let ((namespace (js2--closure-identifier-to-string item)))
                  (add-to-list 'result namespace)))))
           (to-forward
            (let (result)
              (dolist (item forwards)
                (let ((namespace (js2--closure-identifier-to-string item)))
                  (when (and (or (not js2-closure-remove-unused)
                                 (member item references-jsdoc))
                             (not (member namespace to-require)))
                    (push namespace result))))
              (dolist (item references-jsdoc result)
                (let ((namespace (js2--closure-identifier-to-string item)))
                  (when (not (member namespace to-require))
                    (add-to-list 'result namespace)))))))
      (cons (sort to-require 'string<)
            (sort to-forward 'string<)))))

(defun js2--closure-delete-requires ()
  "Delete all goog.require statements in buffer."
  (save-excursion
    (dolist (regexp '("^goog.require(" "^goog.forwardDeclare("))
      (goto-char 0)
      (when (search-forward-regexp regexp nil t)
        (forward-line -1)
        (when (looking-at "^$")
          (delete-region (point) (progn (forward-line 1) (point)))))
      (while (search-forward-regexp regexp nil t)
        (beginning-of-line)
        (delete-region (point) (progn (forward-line 1) (point)))))))

(defun js2--closure-replace (type namespaces after1 after2)
  "Replace section of goog.require or goog.forwardDeclare statements.
This replaces the current section of TYPE statements with
NAMESPACES, which should come after the AFTER1 or AFTER2
sections."
  (save-excursion
    (goto-char 0)
    (if (search-forward-regexp (format "^%s(" type) nil t)
        (beginning-of-line)
      (if (or (search-forward-regexp (format "^%s(" after1) nil t)
              (search-forward-regexp (format "^%s(" after2) nil t))
          (progn (search-forward-regexp "^$")
                 (insert "\n"))
        (progn
          (search-forward-regexp "@fileoverview" nil t)
          (if (search-forward-regexp "^$" nil t)
              (when (not (= 1 (point)))
                (insert "\n"))
            (progn (goto-char (point-max))
                   (insert "\n"))))))
    (while (search-forward-regexp
            (format "^%s('\\([^']+\\)');" type) nil t)
      (beginning-of-line)
      (if (looking-back "@suppress {extraRequire}[^*]*\\*/\n")
          (progn
            (setq namespaces (delete (match-string 1) namespaces))
            (forward-line))
        (progn
          (if namespaces
              (progn
                (when (not (string= (match-string 1) (car namespaces)))
                  (replace-match (car namespaces) t t nil 1))
                (forward-line))
            (progn
              (beginning-of-line)
              (delete-region (point) (progn (forward-line 1) (point)))))
          (setq namespaces (cdr namespaces)))))
    (while namespaces
      (insert (format "%s('%s');\n" type (pop namespaces))))))

(defun js2--closure-replace-requires (namespaces)
  "Replace the current list of requires with NAMESPACES."
  (js2--closure-replace "goog.require" namespaces "goog.provide" nil))

(defun js2--closure-replace-forwards (namespaces)
  "Replace the current list of forward declarations with NAMESPACES."
  (js2--closure-replace "goog.forwardDeclare" namespaces
                        "goog.require" "goog.provide"))

(defun js2--closure-file-modified (file)
  "Return modified timestamp of FILE."
  (nth 5 (file-attributes file)))

(defun js2--closure-load (file)
  "Load FILE with list of provided namespaces into memory."
  (interactive)
  (when (not (file-exists-p file))
    (error "Empty js2-closure provides (%s) See docs: %s"
           file js2-closure-help-url))
  (load file)
  (when (not js2-closure-provides)
    (error "Empty js2-closure-provides (%s) See docs: %s"
           file js2-closure-help-url))
  (setq js2-closure-provides (js2--closure-make-tree
                              (js2--closure-prune-provides
                               js2-closure-provides)))
  (setq js2-closure-provides-modified (js2--closure-file-modified file))
  (message (format "Loaded %s" file)))

(defun js2--closure-has-traditional-namespaces ()
  "Return t if buffer doesn't use module namespacing."
  (save-excursion
    (goto-char 0)
    (not (or (search-forward-regexp "^goog.module(" nil t)
             (search-forward-regexp "^import " nil t)))))

(defun js2--closure-run ()
  "Run js-closure."
  (interactive)
  (when (js2--closure-has-traditional-namespaces)
    (let ((namespaces (js2--closure-determine-requires js2-mode-ast)))
      (if (not (or (car namespaces) (cdr namespaces)))
          (js2--closure-delete-requires)
        (progn
          (when (car namespaces)
            (js2--closure-replace-requires (car namespaces)))
          (when (cdr namespaces)
            (js2--closure-replace-forwards (cdr namespaces))))))))

;;;###autoload
(defun js2-closure-fix ()
  "Fix the `goog.require` statements in the current buffer.
This function assumes that all the requires are in one place and
sorted, without indentation or blank lines.  If you don't have
any requires, they'll be added after your provide statements.  If
you don't have those, then this routine will fail.

Effort was also made to avoid needlessly modifying the buffer,
since syntax coloring might take some time to kick back in.

This will automatically load `js2-closure-provides-file' into
memory if it was modified or not yet loaded."
  (interactive)
  (when (or (not js2-closure-provides)
            (time-less-p js2-closure-provides-modified
                         (js2--closure-file-modified
                          js2-closure-provides-file)))
    (js2--closure-load js2-closure-provides-file))
  (js2--closure-run))

;;;###autoload
(defun js2-closure-save-hook ()
  "Global save hook to invoke `js2-closure-fix' if in `js2-mode'.
To use this feature, add it to `before-save-hook'."
  (interactive)
  (when (eq major-mode 'js2-mode)
    (js2-reparse)
    (condition-case exc
        (js2-closure-fix)
      ('error
       (message (format "js2-closure-fix failed: [%s]" exc))))))

(provide 'js2-closure)

;;; js2-closure.el ends here
