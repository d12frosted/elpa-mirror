;;; ruby-test-mode.el --- Minor mode for Behaviour and Test Driven
;;; Development in Ruby.

;; Copyright (C) 2009 Roman Scherer, Caspar Florian Ebeling

;; Author: Roman Scherer <roman.scherer@gmx.de>
;;         Caspar Florian Ebeling <florian.ebeling@gmail.com>
;; Maintainer: Roman Scherer <roman.scherer@gmx.de>
;; Created: 09.02.08
;; Version: 1.0
;; Package-Version: 20100220.1546
;; Package-Commit: 7d3c04b60721665af93ffb4abc2a7b3191926431
;; Keywords: ruby unit test rspec

;; This software can be redistributed. GPL v2 applies.

;; This mode provides commands for running ruby tests. The output is
;; shown in separate buffer '*Ruby-Test*' in ruby-test
;; mode. Backtraces from failures and errors are marked, and can be
;; clicked to bring up the relevent source file, where point is moved
;; to the named line.
;;
;; The tests can be both, either rspec behaviours, or unit
;; tests. (File names are assumed to end in _spec.rb or _test.rb to
;; tell the type.)  When the command for running a test is invoked, it
;; looks at several places for an actual test to run: first, it looks
;; if the current buffer is a test (or spec), secondly, if not, it
;; checks whether one of the visible buffers is, thirdly it looks if
;; there has been a test run before (during this session), in which
;; case that test is invoked again.
;;
;; Using the command `ruby-test-run-test-at-point', you can run test
;; cases separately from others in the same file.

;; Keybindings:
;;
;; C-c r - Runs the current buffer's file as an unit test or an rspec
;;         example.
;;
;; C-c p - Runs the unit test or rspec example at the current buffer's
;;         point.
;;
;; C-c t - Toggle between implementation and test/example files.

;; History:
;;
;; - 09.02.08, Clickable backtrace added.
;; - 02.03.08, Rails support, by Roman Scherer
;; - 06.06.08, Bugfixes
;; - 09.07.08, Fix backtrace rendering
;; - 17.07.08, Fix rails support and lookup of unqualified executables
;; - 31.07.08, Re-use buffer to show error location, if already visible
;; - 01.08.08, Red and green messages for success and failure
;; - 03.08.08, Run individual test case
;; - 03.08.08, Toggle between implementation and specification/unit
;;             files for rails projects, by Roman Scherer
;; - 06.08.08, Bug fix: unbreak goto-location if buffer is visible
;; - 21.08.08, Refactoring & Bug fix: Before running test files, emacs
;;             changes into the project's root directory, so relative
;;             paths are handled correctly. (Roman Scherer)

(defgroup ruby-test nil
  "Minor mode providing commands and helpers for Behavioural and
Test Driven Development in Ruby."
  :group 'ruby)

(defvar ruby-test-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-cr" 'ruby-test-run)
    (define-key map "\C-cp" 'ruby-test-run-at-point)
    (define-key map "\C-ct" 'ruby-test-toggle-implementation-and-specification)
    map)
  "The keymap used in `ruby-test-mode' buffers.")

(defcustom ruby-test-ruby-executables
  '("/opt/local/bin/ruby" "/usr/bin/ruby" "ruby" "ruby1.9")
  "*A list of ruby executables to use. Non-absolute paths get
  expanded using `PATH'. The first existing will get picked. Set
  this variable to use the implementation you intend to test
  with."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-rspec-executables
  '("/opt/local/bin/spec" "spec" "/usr/bin/spec" "/usr/local/bin/spec")
  "*A list of spec executables. If the spec does not belong to a
  rails project, then non-absolute paths get expanded using
  `PATH'; The first existing will get picked. In a rails project
  the `script/spec' script will be invoked."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-file-name-extensions
  '("builder" "erb" "haml" "rb" "rjs")
  "*A list of filename extensions that trigger the loading of the
minor mode."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-implementation-filename-mapping
  '(
    ("\\(.*\\)\\(spec/controllers/\\)\\(.*\\)\\([^/]*\\)\\(_routing_spec\\)\\(\\.rb\\)$" "\\1config/routes.rb")
    ("\\(.*\\)\\(spec/\\)\\(controllers\\|helpers\\|models\\)\\(.*\\)\\([^/]*\\)\\(_spec\\)\\(\\.rb\\)$" "\\1app/\\3\\4\\5\\7")
    ("\\(.*\\)\\(spec/\\)\\(views\\)\\(.*\\)\\([^/]*\\)\\(_spec\\)\\(\\.rb\\)$" "\\1app/\\3\\4\\5")
    ("\\(.*\\)\\(spec/\\)\\(lib/\\)\\(.*\\)\\([^/]*\\)\\(_spec\\)\\(\\.rb\\)$" "\\1\\3\\4\\5\\7")
    ("\\(.*\\)\\(test/\\)\\(unit/\\)\\(.*\\)\\([^/]*\\)\\(_test\\)\\(\\.rb\\)$" "\\1app/models/\\4\\5\\7")
    ("\\(.*\\)\\(test/\\)\\(functional/\\)\\(.*\\)\\([^/]*\\)\\(_test\\)\\(\\.rb\\)$" "\\1app/controllers/\\4\\5\\7")
    ("\\(.*\\)\\(_spec\\)\\(\\.rb\\)$" "\\1\\3")
    ("\\(.*\\)\\(_test\\)\\(\\.rb\\)$" "\\1\\3"))
  "Regular expressions to map Ruby implementation to unit
filenames). The first element in each list is the match, the
second the replace expression."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-specification-filename-mapping
  '(
    ("\\(.*\\)\\(app/\\)\\(controllers\\|helpers\\|models\\)\\(.*\\)\\([^/]*\\)\\(\\.rb\\)$" "\\1spec/\\3\\4_spec\\5\\6")
    ("\\(.*\\)\\(app/views\\)\\(.*\\)$" "\\1spec/views\\3\\4_spec\\5\\6.rb")
    ("\\(.*\\)\\(lib\\)\\(.*\\)\\([^/]*\\)\\(\\.rb\\)$" "\\1spec/\\2\\3_spec\\4\\5")
    ("\\(.*\\)\\(\\.rb\\)$" "\\1_spec\\2"))
  "Regular expressions to map Ruby specification to
implementation filenames). The first element in each list is the
match, the second the replace expression."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-unit-filename-mapping
  '(
    ("\\(.*\\)\\(app/\\)\\(controllers\\)\\(.*\\)\\([^/]*\\)\\(\\.rb\\)$" "\\1test/functional\\4_test\\5\\6")
    ("\\(.*\\)\\(app/\\)\\(models\\)\\(.*\\)\\([^/]*\\)\\(\\.rb\\)$" "\\1test/unit\\4_test\\5\\6")
    ("\\(.*\\)\\(lib/\\)\\(.*\\)\\([^/]*\\)\\(\\.rb\\)$" "\\1test/unit/\\3\\4_test\\5\\6")
    ("\\(.*\\)\\(\\.rb\\)$" "\\1_test\\2"))
  "Regular expressions to map Ruby unit to implementation
filenames. The first element in each list is the match, the
second the replace expression."
  :type '(list)
  :group 'ruby-test)

;;;###autoload
(define-minor-mode ruby-test-mode
  "Toggle Ruby-Test minor mode.
With no argument, this command toggles the mode. Non-null prefix
argument turns on the mode. Null prefix argument turns off the
mode."
  :init-value nil
  :lighter " Ruby-Test"
  :keymap 'ruby-test-mode-map
  :group 'ruby-test)

(defun select (fn ls)
  "Create a list from elements of list LS for which FN returns
non-nil."
  (let ((result nil))
    (dolist (item ls)
      (if (funcall fn item)
          (setq result (cons item result))))
    (reverse result)))

(defalias 'find-all 'select)

(defun ruby-test-spec-p (filename)
  (and (stringp filename) (string-match "spec\.rb$" filename)))

(defun ruby-test-p (filename)
  (and (stringp filename) (string-match "test\.rb$" filename)))

(defun ruby-test-any-p (filename)
  (or (ruby-test-spec-p filename)
      (ruby-test-p filename)))

(defun ruby-test-expand-executable-path (name)
  (if (file-name-absolute-p name)
      name
    (executable-find name)))

(defun ruby-test-file-name-extension-p (&optional filename)
  "Returns t if the minor mode should be enabled for the current
buffer's filename or the optional filename argument."
  (member
   (file-name-extension (or filename buffer-file-name))
   ruby-test-file-name-extensions))

(defun ruby-test-find-file ()
  "Find the test file to run in number of diffeerent ways:
current buffer (if that's a test; another open buffer which is a
test; or the last run test (if there was one)."
  (let ((files))
    (if (buffer-file-name)
        (setq files (cons (buffer-file-name) files)))
    (setq files (append
                 (mapcar
                  (lambda (win-name) (buffer-file-name (window-buffer win-name)))
                  (window-list))))
    (if (boundp 'ruby-test-last-run)
        (nconc files (list ruby-test-last-run)))
    (setq ruby-test-last-run (car (select 'ruby-test-any-p (select 'identity files))))))

(defun ruby-test-find-file-hook ()
  "Enable ruby-test-mode if the current buffer's filename
extension matches one of the minor mode's filename extensions."
  (when (ruby-test-file-name-extension-p) (ruby-test-mode 't)))

(defun ruby-test-find-target-filename (filename mapping)
  "Find the target filename by matching FILENAME with the first
element of each list in mapping, and replacing the match with the
second element."
  (let ((target-filename nil))
    (while (and (not target-filename) mapping)
      (let ((regexp-match (car (car mapping)))
            (regexp-replace (car (cdr (car mapping)))))
        (if (string-match regexp-match filename)
            (setq target-filename (replace-match regexp-replace nil nil filename nil)))
        (setq mapping (cdr mapping))))
      target-filename))

(defun ruby-test-find-testcase-at (file line)
  (save-excursion
    (set-buffer (get-file-buffer file))
    (goto-line line)
    (message "%s:%s" (current-buffer) (point))
    (if (re-search-backward ruby-test-search-testcase-re nil t)
        (match-string 1))))

(defun ruby-test-implementation-filename (&optional filename)
  "Returns the implementation filename for the current buffer's
filename or the optional FILENAME, else nil."
  (let ((filename (or filename (buffer-file-name))))
    (ruby-test-find-target-filename filename ruby-test-implementation-filename-mapping)))

(defun ruby-test-implementation-p (&optional filename)
  "Returns t if the current buffer's filename or the given
filename is a Ruby implementation file."
  (let ((filename (or filename buffer-file-name)))
    (and (file-readable-p filename)
         (string-match "\\(\\.builder\\)\\|\\(\\.erb\\)\\|\\(\\.haml\\)\\|\\(\\.rb\\)$" filename)
         (not (string-match "_spec\\.rb$" filename))
         (not (string-match "_test\\.rb$" filename)))))

(defvar ruby-test-not-found-message "No test among visible buffers or run earlier.")

(defun ruby-test-run ()
  "Run the current buffer's file as specification or unit test."
  (interactive)
  (let ((filename (ruby-test-find-file)))
    (if filename
        (progn
          (setq default-directory (or (ruby-test-rails-root filename) (ruby-test-ruby-root filename)))
          (compilation-start (ruby-test-command filename)))
      (message ruby-test-not-found-message))))

(defun ruby-test-run-at-point ()
  "Run test at point individually, using the same search strategy
as `ruby-test-run-file'"
  (interactive)
  (let ((filename (ruby-test-find-file)))
    (let ((test-file-buffer (get-file-buffer filename)))
      (if (and filename
               test-file-buffer)
          (save-excursion
            (set-buffer test-file-buffer)
            (let ((line (line-number-at-pos (point))))
              (setq default-directory (or (ruby-test-rails-root filename) (ruby-test-ruby-root filename)))
              (compilation-start (ruby-test-command filename line))))
        (message ruby-test-not-found-message)))))

(defun ruby-test-command (filename &optional line-number)
  "Return the command to run a unit test or a specification
depending on the filename."
  (let (command options)
    (cond
     ((ruby-test-spec-p filename)
      (setq command (or (ruby-test-rspec-executable filename) spec))
      (setq category "spec")
      (if line-number
          (setq options (cons "--line" (cons (format "%d" line-number) options)))))
     ((ruby-test-p filename)
      (setq command (or (ruby-test-ruby-executable) "ruby"))
      (setq category "unit test")
      (if line-number
          (let ((test-case (ruby-test-find-testcase-at filename line-number)))
            (if test-case
                (setq options (cons filename (list (format "--name=%s" test-case))))
              (error "No test case at %s:%s" filename line-number)))))
     (t (message "File is not a known ruby test file")))
    (format "%s %s %s" command (mapconcat 'identity options " ") filename)))

(defun ruby-test-project-root (filename root-predicate)
  "Returns the project root directory for a FILENAME using the
given ROOT-PREDICATE, else nil. The function returns a directory
if any of the directories in FILENAME is tested to t by
evaluating the ROOT-PREDICATE."
  (if (funcall root-predicate filename)
      filename
    (and
     filename
     (not (string= "/" filename))
     (ruby-test-project-root
      (file-name-directory
       (directory-file-name (file-name-directory filename)))
      root-predicate))))

(defun ruby-test-project-root-p (directory candidates)
  "Returns t if one of the filenames in CANDIDATES is existing
relative to the given DIRECTORY, else nil."
  (let ((found nil))
    (while (and (not found) (car candidates))
      (setq found
            (file-exists-p
             (concat (file-name-as-directory directory) (car candidates))))
      (setq candidates (cdr candidates)))
    found))

(defun ruby-test-rails-root (filename)
  "Returns the Ruby on Rails project directory for the given
FILENAME, else nil."
  (ruby-test-project-root filename 'ruby-test-rails-root-p))

(defun ruby-test-rails-root-p (directory)
  "Returns t if the given DIRECTORY is the root of a Ruby on
Rails project, else nil."
  (and (ruby-test-ruby-root-p directory)
       (ruby-test-project-root-p directory
       '("config/environment.rb" "config/database.yml"))))

(defun ruby-test-rspec-executable (test-file)
  "Returns the spec executable to be used for the current buffer
test-file or the given one. If (buffer) test-file is inside of a
rails project, the project executable is returned, else the first
existing default executable. If the default executable is
relative, it is assumed to be somewhere in `PATH'."
  (interactive "b")
  (if (not (buffer-file-name (get-buffer test-file)))
      (error "%s" "Cannot find spec relative to non-file buffer"))
  (let ((executables (copy-sequence ruby-test-rspec-executables)))
    (if (ruby-test-rails-root test-file)
        (add-to-list 'executables (concat (ruby-test-rails-root test-file)
                                          "script/spec")))
    (setq executables (mapcar 'ruby-test-expand-executable-path
                              executables))
    (let ((spec (car (select 'file-readable-p executables))))
      spec)))

(defun ruby-test-ruby-executable ()
  "Returns the ruby binary to be used."
  (car (select 'file-readable-p
               (select 'identity
                       (mapcar 'ruby-test-expand-executable-path
                               ruby-test-ruby-executables)))))

(defun ruby-test-ruby-root (filename)
  "Returns the Ruby project directory for the given FILENAME,
else nil."
  (ruby-test-project-root filename 'ruby-test-ruby-root-p))

(defun ruby-test-ruby-root-p (directory)
  "Returns t if the given DIRECTORY is the root of a Ruby
project, else nil."
  (ruby-test-project-root-p directory '("Rakefile")))

(defun ruby-test-specification-filename (&optional filename)
  "Returns the specification filename for the current buffer's
filename or the optional FILENAME, else nil."
  (let ((filename (or filename (buffer-file-name))))
    (ruby-test-find-target-filename filename ruby-test-specification-filename-mapping)))

(defun ruby-test-toggle-implementation-and-specification (&optional filename)
  "Toggle between the implementation and specification/test file
for the current buffer or the optional FILENAME."
  (interactive)
  (let ((filename (or filename (buffer-file-name))))
    (cond ((ruby-test-implementation-p filename)
           (cond ((ruby-test-specification-filename filename)
                  (find-file (ruby-test-specification-filename filename)))
                 ((ruby-test-unit-filename filename)
                  (find-file (ruby-test-unit-filename filename)))
                 (t
                  (put-text-property 0 (length filename) 'face 'bold filename)
                  (message "Sorry, can't guess unit/specification filename from %s." filename))))
           ((or (ruby-test-spec-p filename) (ruby-test-p filename))
            (find-file (ruby-test-implementation-filename filename)))
           (t
            (put-text-property 0 (length filename) 'face 'bold filename)
            (message "Sorry, %s is neither a Ruby implementation nor a test file." filename)))))

(defun ruby-test-unit-filename (&optional filename)
  "Returns the unit filename for the current buffer's filename or
the optional FILENAME, else nil."
  (let ((filename (or filename (buffer-file-name))))
    (ruby-test-find-target-filename filename ruby-test-unit-filename-mapping)))

(add-hook 'find-file-hooks 'ruby-test-find-file-hook)
(provide 'ruby-test-mode)

;;; ruby-test-mode.el ends here
