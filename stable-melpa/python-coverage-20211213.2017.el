;;; python-coverage.el --- Show Python coverage via overlays or Flycheck -*- lexical-binding: t; -*-

;; Author: wouter bolsterlee <wouter@bolsterl.ee>
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1") (dash "2.18.0") (s "1.12.0") (xml+ "1"))
;; Keywords: languages, processes, tools
;; URL: https://github.com/wbolster/emacs-python-coverage

;;; License:

;; BSD-3-clause License

;;; Commentary:

;; Show Python coverage results in source files,
;; using overlays or with a Flycheck checker.

;;; Code:

(require 'dash)
(require 'filenotify)
(require 'python)
(require 's)
(require 'xml)
(require 'xml+)

(defgroup python-coverage nil
  "Python coverage"
  :group 'python
  :prefix "python-coverage")

(defcustom python-coverage-default-file-name "coverage.xml"
  "Default file name to use when looking for coverage results."
  :group 'python-coverage
  :type 'string)

(defcustom python-coverage-overlay-width nil
  "Maximum width of the overlays.

If nil, highlight the whole statement. If a number, highlight up
to that number of characters, or until the end of line, whichever
comes first. Practically, a small number such as 2 will result in
non-obtrusive colored blocks adjacent to the left margin."
  :group 'python-coverage
  :type '(choice integer (const :tag "Complete line" nil)))

(defface python-coverage-overlay-missing
  '((t :inherit magit-diff-removed))
  "Overlay face for missing coverage."
  :group 'python-coverage)

(defface python-coverage-overlay-partial
  '((t :inherit magit-diff-base))
  "Overlay face for partial (branch) coverage."
  :group 'python-coverage)

(defface python-coverage-overlay-missing-outdated
  '((t :inherit magit-diff-context-highlight))
  "Overlay face for potentially outdated missing coverage."
  :group 'python-coverage)

(defface python-coverage-overlay-partial-outdated
  '((t :inherit magit-diff-context-highlight))
  "Overlay face for potentially outdated partial (branch) coverage."
  :group 'python-coverage)

(defvar-local python-coverage--coverage-file-name nil
  "Coverage file to use for the current buffer.")

(defvar-local python-coverage--overlay-watch nil
  "File watch for automatic overlay refreshing.")

;; Public interface

;;;###autoload
(defun python-coverage-select-coverage-file (&optional coverage-file-name)
  "Explicitly set the COVERAGE-FILE-NAME to use for the current buffer.

This is only needed if autodetection does not work."
  (interactive "f")
  (setq python-coverage--coverage-file-name coverage-file-name))

;;;###autoload
(define-minor-mode python-coverage-overlay-mode
  "Minor mode to show Python coverage results as overlays."
  :lighter " PyCov"
  (if python-coverage-overlay-mode
      (progn
        (python-coverage-overlay-refresh)
        (add-hook 'kill-buffer-hook #'python-coverage--overlay-remove-watch nil t)
        (add-hook 'after-save-hook #'python-coverage--mark-as-outdated nil t)
        (python-coverage--overlay-add-watch))
    (python-coverage--overlay-remove-watch)
    (remove-hook 'after-save-hook #'python-coverage--mark-as-outdated t)
    (python-coverage-overlay-remove-all)))

;;;###autoload
(defun python-coverage-overlay-refresh ()
  "Refresh the overlays."
  (interactive)
  (let ((coverage-info (python-coverage-current-buffer)))
    (when (python-coverage--coverage-file-outdated?)
      (message "Note: coverage file is potentially outdated."))
    (save-restriction
      (widen)
      (overlay-recenter (point-max))
      (python-coverage-overlay-remove-all)
      (python-coverage--overlay-make-all coverage-info))))

;;;###autoload
(defun python-coverage-overlay-remove-all ()
  "Remove all overlays."
  (interactive)
  (save-restriction
    (widen)
    (remove-overlays nil nil 'category 'python-coverage)))

;;;###autoload
(defun python-coverage-overlay-jump-next ()
  "Jump to the next overlay."
  (interactive)
  (-if-let* ((overlay (-first-item (python-coverage--overlays-in (1+ (point)) nil))))
      (goto-char (overlay-start overlay))
    (user-error "No more coverage overlays in this direction")))

;;;###autoload
(defun python-coverage-overlay-jump-previous ()
  "Jump to the previous overlay."
  (interactive)
  (-if-let* ((overlay (-last-item (python-coverage--overlays-in nil (point)))))
      (goto-char (overlay-start overlay))
    (user-error "No more coverage overlays in this direction")))

;;;###autoload
(defun python-coverage-overlay-jump-first ()
  "Jump to the first overlay."
  (interactive)
  (-if-let* ((overlay (-first-item (python-coverage--overlays-in))))
      (goto-char (overlay-start overlay))
    (user-error "No coverage overlays in buffer")))

(defun python-coverage-current-buffer ()
  "Obtain coverage info for the current buffer."
  (-when-let*
      ((coverage-file (python-coverage--find-coverage-file-current-buffer))
       (non-empty? (> (python-coverage--file-size coverage-file) 0))
       (tree (python-coverage--parse-coverage-xml-file coverage-file))
       (coverage-info (python-coverage--get-missing-file-coverage tree (buffer-file-name))))
    coverage-info))

;; Internal helpers for handling files

(defun python-coverage--find-coverage-file-current-buffer ()
  "Find a coverage file for the current buffer."
  (-let [source-file-name
         (or (buffer-file-name)
             (error "Cannot detect source file name; buffer is not visiting a file"))]
    (python-coverage--find-coverage-file source-file-name)))

(defun python-coverage--find-coverage-file (source-file-name)
  "Find a coverage file for SOURCE-FILE-NAME."
  (or
   python-coverage--coverage-file-name
   (-some->
    (python-coverage--locate-dominating-file source-file-name python-coverage-default-file-name)
    (file-name-as-directory)
    (s-concat python-coverage-default-file-name))
   (error "Could not find coverage file. (Hint: use ‘M-x python-coverage-select-coverage-file’ to choose manually.)")))

(declare-function projectile-locate-dominating-file "projectile" (file name))

(defun python-coverage--locate-dominating-file (file name)
  "Like ‘locate-dominating-file’, using Projectile if available.

FILE and NAME are handled like ‘locate-dominating-file’ does."
  (if (featurep 'projectile)
      (projectile-locate-dominating-file file name)
    (locate-dominating-file file name)))

(defun python-coverage--coverage-file-outdated? (&optional file-name)
  "Return t when the coverage file for FILE-NAME is outdated."
  (unless file-name (setq file-name (buffer-file-name)))
  (let* ((coverage-file (python-coverage--find-coverage-file-current-buffer))
         (coverage-mtime (python-coverage--file-mtime coverage-file))
         (file-mtime (python-coverage--file-mtime file-name)))
    (< coverage-mtime file-mtime)))

(defun python-coverage--file-mtime (file-name)
  "Get the mtime of FILE-NAME as a float."
  (->> (file-attributes file-name)
       (nth 5)
       (float-time)))

(defun python-coverage--file-size (file-name)
  "Get the size of FILE-NAME."
  (->> (file-attributes file-name)
       (nth 7)))

;; Internal helpers for handling the coverage XML format

(defun python-coverage--parse-xml-file (name)
  "Parse an XML file NAME."
  ;; Try to use libxml, and fall back to the slower built-in function.
  (or
   (if (fboundp 'libxml-parse-xml-region)
       (with-temp-buffer
         (insert-file-contents name)
         (libxml-parse-xml-region (point-min) (point-max)))
     (-first-item (xml-parse-file name)))
   (error "Could not parse coverage file ‘%s’" name)))

(defun python-coverage--parse-coverage-xml-file (name)
  "Parse the XML file NAME."
  (-when-let* ((tree (python-coverage--parse-xml-file name)))
    (unless (eq (car tree) 'coverage)
      (error "Unknown XML file format; root element should be <coverage>"))
    tree))

(defun python-coverage--get-missing-file-coverage (tree file-name)
  "Get the missing coverage for FILE-NAME from TREE."
  (-when-let (class-node (python-coverage--find-class-node tree file-name))
    (python-coverage--extract-lines class-node)))

(defun python-coverage--find-class-node (tree file-name)
  "Find the <class> XML node in TREE for the specified FILE-NAME."
  ;; Unfortunately, the XML does not contain full file paths. Find all
  ;; <class name=...> elements for the base file name, then check if
  ;; any of them matches when combined with any of the source paths.
  (-if-let*
      ((file-name-without-directory (file-name-nondirectory file-name))
       (query `((coverage) > (packages) > (package) > (classes) >
                (class :name ,file-name-without-directory)))
       (class-node-candidates (xml+-query-all tree query))
       (source-paths (python-coverage--get-source-paths tree))
       (class-node
        (--first
         (python-coverage--class-node-matches-file-name? it file-name source-paths)
         class-node-candidates)))
      class-node
    (error "Coverage file contains no information for file ‘%s’" file-name)))

(defun python-coverage--get-source-paths (tree)
  "Get the source paths from the TREE."
  (->> (xml+-query-all tree '((coverage) > (sources) > (source)))
       (-map 'xml+-node-text)))

(defun python-coverage--class-node-matches-file-name? (class-node file-name source-paths)
  "Check whether CLASS-NODE is about FILE-NAME.

This tries all SOURCE-PATHS and compares that to FILE-NAME."
  ;; The ‘filename=...’ attribute contains a relative file name
  ;; starting at any of the source directories.
  (-let [relative-file-name
         (or (xml-get-attribute-or-nil class-node 'filename)
             (error "<class> node does not have a ‘filename’ attribute"))]
    (->> source-paths
         (-map 'file-name-as-directory)
         (--map (s-concat it relative-file-name))
         (member file-name))))

(defun python-coverage--extract-lines (class-node)
  "Extract info about lines that are not fully covered from CLASS-NODE."
  (->> (xml+-query-all class-node '((class) > (lines) > (line)))
       (nreverse)
       (-map 'python-coverage--transform-line-node)
       (--remove (eq (plist-get it :status) 'covered))
       (-sort (-on '< (-rpartial 'plist-get :line-beg)))
       (python-coverage--merge-adjacent)))

(defun python-coverage--transform-line-node (line-node)
  "Transform a LINE-NODE (‘<line ...>’) into a simple structure."
  (let* ((line
          (-> line-node
              (xml-get-attribute 'number)
              (string-to-number)))
         (missing?
          (-> line-node
              (xml-get-attribute 'hits)
              (s-equals? "0")))
         (missing-branches
          (-> line-node
              (xml-get-attribute-or-nil 'missing-branches)))
         (status
          (cond (missing? 'missing)
                (missing-branches 'partial)
                (t 'covered)))
         (result
          (append
           (list :line-beg line :line-end line :status status)
           (-some->> missing-branches (list :missing-branches)))))
    result))

(defun python-coverage--merge-adjacent (coverage-info)
  "Merge adjacent lines in COVERAGE-INFO into larger blocks."
  (nreverse
   (--reduce-from
    (-if-let* ((previous (car acc))
               (current it)
               (previous-line (plist-get previous :line-end))
               (current-line (plist-get it :line-beg))
               (same-status? (eq (plist-get previous :status)
                                 (plist-get current :status)))
               (adjacent? (eql (- current-line previous-line) 1))
               (replacement-head (plist-put previous :line-end current-line)))
        (cons replacement-head (cdr acc))
      (cons it acc))
    nil
    coverage-info)))

;; useful for debugging:
;; (setq tmp-input
;;       '((:line-beg 3 :line-end 3 :status missing)
;;         (:line-beg 4 :line-end 4 :status missing)
;;         (:line-beg 5 :line-end 5 :status missing)
;;         (:line-beg 8 :line-end 8 :status missing)
;;         (:line-beg 10 :line-end 10 :status missing)
;;         (:line-beg 11 :line-end 11 :status missing)
;;         (:line-beg 12 :line-end 12 :status missing)
;;         (:line-beg 13 :line-end 13 :status missing)
;;         (:line-beg 15 :line-end 15 :status missing)
;;         (:line-beg 16 :line-end 16 :status missing)))
;; (python-coverage--merge-adjacent tmp-input)


;; Internal helpers for overlays

(defun python-coverage--overlay-make-all (coverage-info)
  "Create all overlays for COVERAGE-INFO."
  (let ((outdated? (python-coverage--coverage-file-outdated?)))
    (--each coverage-info
      (python-coverage--overlay-make it outdated?))))

(defun python-coverage--overlay-make (info outdated)
  "Make an overlay for coverage INFO.

If OUTDATED is non-nil, use a different style."
  (save-restriction
    (widen)
    (-let* (((&plist :line-beg :line-end :status) info)
            (beg
             (save-excursion
               (goto-char (point-min))
               (forward-line (1- line-beg))
               (point)))
            (end
             (save-excursion
               (goto-char beg)
               (forward-line (- line-end line-beg))
               (if python-coverage-overlay-width
                   (min
                    (line-end-position)
                    (progn
                      (forward-char python-coverage-overlay-width)
                      (point)))
                 (python-nav-end-of-statement)
                 (1+ (point)))))
            (end
             ;; At least one character. This should only happen for
             ;; outdated overlays on empty lines.
             (max end (1+ beg)))
            (face
             (pcase status
               ('missing
                (if outdated
                    'python-coverage-overlay-missing-outdated
                  'python-coverage-overlay-missing))
               ('partial
                (if outdated
                    'python-coverage-overlay-partial-outdated
                  'python-coverage-overlay-partial))))
            (overlay
             (-doto (make-overlay beg end)
               (overlay-put 'evaporate t)
               (overlay-put 'category 'python-coverage)
               (overlay-put 'face face))))
      overlay)))

(defun python-coverage--overlays-in (&optional beg end)
  "Return all overlays between BEG and END."
  (unless beg (setq beg (point-min)))
  (unless end (setq end (point-max)))
  (save-restriction
    (widen)
    (->> (overlays-in (point-min) (point-max))
         (--filter (eq (overlay-get it 'category) 'python-coverage))
         (--filter (>= (overlay-start it) beg))
         (--filter (<= (overlay-end it) end))
         (-sort (-on '< 'overlay-start)))))

(defun python-coverage--overlay-add-watch ()
  "Watch the coverage file to automatically refresh overlays."
  (let* ((coverage-file (python-coverage--find-coverage-file-current-buffer))
         (watch
          (file-notify-add-watch
           coverage-file
           '(change attribute-change)
           (-partial
            'python-coverage--overlay-watch-on-change
            (current-buffer)))))
    (setq python-coverage--overlay-watch watch)))

(defun python-coverage--mark-as-outdated ()
  "Mark all overlays as outdated."
  (--each (python-coverage--overlays-in)
    (let* ((face (overlay-get it 'face))
           (new-face
            (pcase face
              ('python-coverage-overlay-missing 'python-coverage-overlay-missing-outdated)
              ('python-coverage-overlay-partial 'python-coverage-overlay-partial-outdated))))
      (overlay-put it 'face new-face))))

(defun python-coverage--overlay-remove-watch ()
  "Remove the file watch on the coverage file."
  (when (and python-coverage--overlay-watch
             (file-notify-valid-p python-coverage--overlay-watch))
    (file-notify-rm-watch python-coverage--overlay-watch))
  (setq python-coverage--overlay-watch nil))

(defun python-coverage--overlay-watch-on-change (buffer _event)
  "Change event handler for file watching.

The EVENT causes the overlays in BUFFER to get refreshed."
  (with-current-buffer buffer
    (python-coverage-overlay-refresh)))

;; Internal helpers for flycheck

(declare-function flycheck-define-generic-checker "flycheck")
(declare-function flycheck-error-new-at "flycheck")
(declare-function flycheck-verification-result-new "flycheck")
(defvar flycheck-checkers)

(defun python-coverage--flycheck-predicate ()
  "Check whether the flycheck checker can be used."
  (condition-case nil
      (python-coverage--find-coverage-file-current-buffer)
    (error nil)))

(defun python-coverage--flycheck-verify (_checker)
  "Check whether the flycheck checker can be used."
  (list
   (condition-case err
       (let ((coverage-file (python-coverage--find-coverage-file-current-buffer)))
         (flycheck-verification-result-new
          :label "report"
          :message (format "Found at %s" coverage-file)
          :face 'success))
     (error
      (flycheck-verification-result-new
       :label "report"
       :message (format "%s" (error-message-string err))
       :face 'error)))))

(defun python-coverage--flycheck-error (info checker)
  "Create a flycheck error for CHECKER containing INFO ."
  (-let* (((&plist :line-beg :status :missing-branches) info)
          (column 1)
          (level
           (pcase status
             ('missing 'error)
             ('partial 'warning)))
          (message
           (pcase status
             ('missing "Not covered")
             ('partial
              (s-concat "Partially covered" (-some->> missing-branches (format " (missing branches: %s)")))))))
    (flycheck-error-new-at line-beg column level message :checker checker)))

(defun python-coverage--flycheck-start (checker callback)
  "Flycheck start function for CHECKER, invoking CALLBACK."
  (condition-case err
      (let* ((context)
             (coverage-info (python-coverage-current-buffer))
             (errors
              (--map
               (python-coverage--flycheck-error it checker)
               coverage-info)))
        (funcall callback 'finished errors)
        context)
    (error
     (funcall callback 'errored (error-message-string err))
     (signal (car err) (cdr err)))))

(with-eval-after-load 'flycheck
  (flycheck-define-generic-checker 'python-coverage
    "A Python checker to show coverage results using a XML report."
    :modes '(python-mode)
    :start #'python-coverage--flycheck-start
    :predicate #'python-coverage--flycheck-predicate
    :verify #'python-coverage--flycheck-verify)

  (add-to-list 'flycheck-checkers 'python-coverage t))

(provide 'python-coverage)
;;; python-coverage.el ends here
