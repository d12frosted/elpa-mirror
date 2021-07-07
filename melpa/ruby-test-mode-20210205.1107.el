;;; ruby-test-mode.el --- Minor mode for Behaviour and Test Driven
;;; Development in Ruby.

;; Copyright (C) 2009 Roman Scherer, Caspar Florian Ebeling

;; Author: Roman Scherer <roman.scherer@gmx.de>
;;         Caspar Florian Ebeling <florian.ebeling@gmail.com>
;; URL: https://github.com/ruby-test-mode/ruby-test-mode
;; Package-Version: 20210205.1107
;; Package-Commit: d66db4aca6e6a246f65f7195ecfbc7581d35fb7a
;; Maintainer: Roman Scherer <roman.scherer@burningswell.com>
;; Created: 09.02.08
;; Version: 1.7
;; Keywords: ruby unit test rspec tools
;; Package-Requires: ((ruby-mode "1.0") (pcre2el "1.8"))

;; This file is not part of GNU Emacs.

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

;; This mode provides commands for running ruby tests.  The output is
;; shown in separate buffer '*Ruby-Test*' in ruby-test
;; mode.  Backtraces from failures and errors are marked, and can be
;; clicked to bring up the relevent source file, where point is moved
;; to the named line.
;;
;; The tests can be both, either rspec behaviours, or unit
;; tests.  (File names are assumed to end in _spec.rb or _test.rb to
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
;; C-c C-t n    - Runs the current buffer's file as an unit test or an
;; C-c C-t C-n    rspec example.
;;
;; C-c C-t t    - Runs the unit test or rspec example at the current buffer's
;; C-c C-t C-t    buffer's point.
;;
;; C-c C-t r    - Reruns the last unit test or rspec example
;; C-c C-t C-r
;;
;; C-c C-s      - Toggle between implementation and test/example files.

(require 'ruby-mode)
(require 'pcre2el)

;;; Code:

(defgroup ruby-test nil
  "Minor mode providing commands and helpers for Behavioural and
Test Driven Development in Ruby."
  :group 'ruby)

(defcustom ruby-test-rspec-options
  '("-b")
  "Pass extra command line options to RSpec when running specs."
  :initialize 'custom-initialize-default
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-plain-test-options
  '()
  "Pass extra command line options to minitest when running specs."
  :initialize 'custom-initialize-default
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-rails-test-options
  '("-v")
  "Pass extra command line options to `rails test` when running tests."
  :initialize 'custom-initialize-default
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-execution-environment
  '("PAGER=cat")
  "Environment variables to be set when running tests."
  :initialize 'custom-initialize-default
  :type '(repeat (string :tag "ENVVARNAME=VALUE"))
  :group 'ruby-test)

(defvar ruby-test-default-library
  "test"
  "Define the default test library.")

(defvar ruby-test-last-run
  nil
  "The last ruby test run.")

(defvar ruby-test-last-test-command
  nil
  "The last ruby test command ran.")

(defvar ruby-test-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-t n")   'ruby-test-run)
    (define-key map (kbd "C-c C-t C-n") 'ruby-test-run)
    (define-key map (kbd "C-c C-t t")   'ruby-test-run-at-point)
    (define-key map (kbd "C-c C-t C-t") 'ruby-test-run-at-point)
    (define-key map (kbd "C-c C-t r")   'ruby-test-rerun)
    (define-key map (kbd "C-c C-t C-r") 'ruby-test-rerun)
    (define-key map (kbd "C-c C-s")     'ruby-test-toggle-implementation-and-specification)
    map)
  "The keymap used in command `ruby-test-mode' buffers.")

(defcustom ruby-test-file-name-extensions
  '("builder" "erb" "haml" "rb" "rjs" "rake" "slim")
  "List of filename extensions that trigger the loading of the minor mode."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-implementation-filename-mapping
  `(
    (,(pcre-to-elisp "(.*)/spec/routing/routes_spec\\.rb$") "\\1/config/routes.rb")
    (,(pcre-to-elisp "(.*)/test/routing/routes_test\\.rb$") "\\1/config/routes.rb")
    (,(pcre-to-elisp "(.*)/spec/(controllers|models|jobs|helpers|mailers|uploaders|api|services)/(.*)_spec\\.rb$")
     "\\1/app/\\2/\\3.rb")
    (,(pcre-to-elisp "(.*)/test/(controllers|models|jobs|helpers|mailers|uploaders|api|services)/(.*)_test\\.rb$")
     "\\1/app/\\2/\\3.rb")

    (,(pcre-to-elisp "(.*)/spec/(views/.*)_spec\\.rb$") "\\1/app/\\2")
    (,(pcre-to-elisp "(.*)/test/(views/.*)_test\\.rb$") "\\1/app/\\2")

    (,(pcre-to-elisp "(.*)/spec/(.*)_tasks_spec\\.rb$") "\\1/\\2.rake")
    (,(pcre-to-elisp "(.*)/test/(.*)_tasks_test\\.rb$") "\\1/\\2.rake")

    ;; Project/spec/lib/aaa/bbb_spec.rb => Project/lib/aaa/bbb.rb
    (,(pcre-to-elisp "(.*)/spec/lib/(.*)_spec\\.rb$") "\\1/lib/\\2.rb")
    (,(pcre-to-elisp "(.*)/test/lib/(.*)_test\\.rb$") "\\1/lib/\\2.rb")

    ;; Project/spec/aaa/bbb_spec.rb => Project/lib/aaa/bbb.rb
    (,(pcre-to-elisp "(.*)/spec/(.*)_spec\\.rb$") "\\1/lib/\\2.rb")

    (,(pcre-to-elisp "(.*)/test/unit/(.*)_test\\.rb$")
     "\\1/app/models/\\2.rb"
     "\\1/lib/\\2.rb")
    (,(pcre-to-elisp "(.*)/test/functional/(.*)_test\\.rb$") "\\1/app/controllers/\\2.rb")

    ;; Project/test/aaa/bbb_test.rb => Project/lib/aaa/bbb.rb
    (,(pcre-to-elisp "(.*)/test/(.*)_test\\.rb$") "\\1/lib/\\2.rb")

    ;; make ruby-test-mode support asserts spec.
    (,(pcre-to-elisp "(.*)/spec/javascripts/(.*)_spec\\.(js|coffee)$")
     "\\1/app/assets/javascripts/\\2.\\3")

    ;; in same folder,  gem/aaa_spec.rb => gem/aaa.rb
    (,(pcre-to-elisp "(.*)_(spec|test)\\.rb$") "\\1.rb")
    )
  "Regular expressions to map Ruby implementation to unit filenames).
The first element in each list is the match, the
second the replace expression."
  :type '(list)
  :group 'ruby-test)

(defcustom ruby-test-specification-filename-mapping
  `(
    (,(pcre-to-elisp "(.*)/config/routes\\.rb$")
     "\\1/spec/routing/routes_spec.rb"
     "\\1/test/routing/routes_test.rb")
    (,(pcre-to-elisp "(.*)/app/views/(.*)$")
     "\\1/spec/views/\\2_spec.rb"
     "\\1/test/views/\\2_test.rb")

    ;; everything in app, should exist same path in spec/test.
    (,(pcre-to-elisp "(.*?)/app/(.*)\\.rb$")
     "\\1/spec/\\2_spec.rb"
     "\\1/test/\\2_test.rb")

    (,(pcre-to-elisp "(.*)/lib/(tasks/.*)\\.rake$")
     "\\1/spec/\\2_tasks_spec.rb"
     "\\1/test/\\2_tasks_test.rb")

    ;; Project/lib/aaa/bbb.rb, search order:
    ;; => Project/spec/lib/aaa/bbb_spec.rb, Project/spec/aaa/bbb_spec.rb
    (,(pcre-to-elisp "(.*)/lib/(.*)\\.rb$")
     "\\1/spec/\\2_spec.rb"
     "\\1/spec/lib/\\2_spec.rb"
     "\\1/test/\\2_test.rb"
     "\\1/test/lib/\\2_test.rb")

    ;; make ruby-test-mode support asserts spec.
    (,(pcre-to-elisp "(.*)/app/assets/javascripts/(.*)\\.(js|coffee)$")
     "\\1/spec/javascripts/\\2_spec.\\3")

    ;; in same folder,  gem/aaa.rb => gem/aaa_spec.rb
    (,(pcre-to-elisp "(.*)\\.rb$") "\\1_spec.rb" "\\1_test.rb")
    )
  "Regular expressions to map Ruby specification to implementation filenames).
The first element in each list is the
match, the second the replace expression."
  :type '(list)
  :group 'ruby-test)

;; TODO: It seem like we does not need this mapping anymore.
;; We could add more candicaate to `ruby-test-specification-filename-mapping' to
;; instead this.
(defcustom ruby-test-unit-filename-mapping
  `(
    (,(pcre-to-elisp "(.*)/config/routes\\.rb$") "\\1/test/routing/routes_test.rb")
    (,(pcre-to-elisp "(.*)/app/views/(.*)$") "\\1/test/views/\\2_test.rb")
    (,(pcre-to-elisp "(.*)/app/controllers/(.*)\\.rb$")
     "\\1/test/controllers/\\2_test.rb"
     "\\1/test/functional/\\2_test.rb")
    (,(pcre-to-elisp "(.*)/app/models/(.*)\\.rb$")
     "\\1/test/models/\\2_test.rb"
     "\\1/test/unit/\\2_test.rb")
    (,(pcre-to-elisp "(.*)/app/(.*)\\.rb$")
     "\\1/test/\\2_test.rb")
    (,(pcre-to-elisp "(.*)/lib/(tasks/.*)\\.rake$") "\\1/test/\\2_tasks_test.rb")
    (,(pcre-to-elisp "(.*)/lib/(.*)\\.rb$")
     "\\1/test/\\2_test.rb"
     "\\1/test/unit/\\2_test.rb"
     "\\1/test/lib/\\2_test.rb")
    (,(pcre-to-elisp "(.*)\\.rb$") "\\1_test.rb")
    )
  "Regular expressions to map Ruby unit to implementation filenames.
The first element in each list is the match, the
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

(defmacro ruby-test-with-ruby-directory (filename form)
  "Set to ruby or rails root inferred from FILENAME and run the provided FORM with `default-directory` bound."
  `(let ((default-directory (or (ruby-test-rails-root ,filename)
                                (ruby-test-ruby-root ,filename)
                                default-directory)))
     ,form))

(defun ruby-test-select (fn ls)
  "Call FN and create a list from elements of list LS for which FN is non-nil."
  (let ((result nil))
    (dolist (item ls)
      (if (funcall fn item)
          (setq result (cons item result))))
    (reverse result)))

(defalias 'find-all 'ruby-test-select)

(defun ruby-test-rails-p (filename)
  "Return non-nil if FILENAME is part of a Ruby on Rails project."
  (and (stringp filename) (ruby-test-rails-root filename)))

(defun ruby-test-minitest-p (filename)
  "Return non-nil if FILENAME is a minitest."
  (and (stringp filename)
    (or (and (string-match "test\.rb$" filename) (file-exists-p "test/minitest_helper.rb"))
      (and (string-match "spec\.rb$" filename) (file-exists-p "spec/minitest_helper.rb")))))

(defun ruby-test-spec-p (filename)
  "Return non-nil if FILENAME is a spec."
  (and (stringp filename) (string-match "spec\.rb$" filename)))

(defun ruby-test-p (filename)
  "Return non-nil if FILENAME is a test."
  (and (stringp filename) (string-match "test\.rb$" filename)))

(defun ruby-test-any-p (filename)
  "Return non-nil if FILENAME is a test or spec."
  (or (ruby-test-spec-p filename)
      (ruby-test-p filename)))

(defun ruby-test-file-name-extension-p (&optional filename)
  "Return t if the minor mode should be enabled.
If FILENAME is nil, use the current buffer."
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
    (setq ruby-test-last-run (car (ruby-test-select 'ruby-test-any-p (ruby-test-select 'identity files))))))

(defun ruby-test-find-target-filename (filename mapping)
  "Find the target filename.
Match FILENAME with the first element of each list in MAPPING,
and replace the match with the second element."
  (let ((target-filename nil))
    (while (and (not target-filename) mapping)
      (let ((regexp-match (car (car mapping)))
            (regexp-replace-candidates (cdr (car mapping))))
        (if (string-match regexp-match filename)
            (let ((target-filename-candidates
                   (mapcar #'(lambda (regexp)
                               (replace-match regexp nil nil filename nil))
                           regexp-replace-candidates))
                  exist-filename)
              (setq target-filename
                    (or (dolist (filename target-filename-candidates exist-filename)
                          (unless exist-filename
                            (setq exist-filename (if (file-exists-p filename)
                                                     filename
                                                   nil))))
                        (car target-filename-candidates)))))
        (setq mapping (cdr mapping))))
    target-filename))

(defun ruby-test-find-testcase-at (file line)
  "Find testcase at FILE LINE."
  (with-current-buffer (get-file-buffer file)
    (save-excursion
      (goto-char (point-min))
      (forward-line (1- line))
      (end-of-line)
      (message "%s:%s" (current-buffer) (point))
      (if (re-search-backward (concat "^[ \t]*\\(def\\|test\\|it\\|should\\)[ \t]+"
                                      "\\(\\([\"'].*?[\"']\\)\\|" ruby-symbol-re "*\\)"
                                      "[ \t]*") nil t)
          (let ((name (or (match-string 3)
                          (match-string 2)))
                (method (match-string 1)))
            (ruby-test-testcase-name name method))))))

(defun ruby-test-testcase-name (name method)
  "Return the sanitized name of the test using NAME and METHOD."
  (cond
   ;; assume methods created with it are from minitest
   ;; so no need to sanitize them
   ((string= method "it")
    name)
   ((string= method "should") ;; shoulda
    name)
   ((string= name "setup")
    nil)
   ((string-match "^[\"']\\(.*\\)[\"']$" name)
    (replace-regexp-in-string
     "\\?" "\\\\\\\\?"
     (replace-regexp-in-string
      "'_?\\|(_?\\|)_?" ".*"
      (replace-regexp-in-string " +" "_" (match-string 1 name)))))
   ((string= method "def")
    name)))

(defun ruby-test-implementation-filename (&optional filename)
  "Return the implementation filename for the current buffer's filename or the optional FILENAME, else nil."
  (let ((filename (or filename (buffer-file-name))))
    (ruby-test-find-target-filename filename ruby-test-implementation-filename-mapping)))

(defun ruby-test-implementation-p (&optional filename)
  "Return t if the current buffer's filename or the given FILENAME is a Ruby implementation file."
  (let ((filename (or filename buffer-file-name)))
    (and (file-readable-p filename)
         (string-match (regexp-opt ruby-test-file-name-extensions)
                       (file-name-extension filename))
         (not (string-match "_spec\\.rb$" filename))
         (not (string-match "_test\\.rb$" filename)))))

(defvar ruby-test-not-found-message "No test among visible buffers or run earlier.")

;;;###autoload
(defun ruby-test-run ()
  "Run the current buffer's file as specification or unit test."
  (interactive)
  (let ((filename (ruby-test-find-file)))
    (if filename
        (ruby-test-with-ruby-directory filename
                                       (ruby-test-run-command (ruby-test-command filename)))
      (message ruby-test-not-found-message))))

;;;###autoload
(defun ruby-test-run-at-point ()
  "Run test at point individually, using the same search strategy as `ruby-test-run-file'."
  (interactive)
  (let* ((filename (ruby-test-find-file))
         (test-file-buffer (get-file-buffer filename)))
    (if (and filename
             test-file-buffer)
        (ruby-test-with-ruby-directory filename
                                       (with-current-buffer test-file-buffer
                                         (let ((line (line-number-at-pos (point))))
                                           (ruby-test-run-command (ruby-test-command filename line)))))
      (message ruby-test-not-found-message))))

;;;###autoload
(defun ruby-test-rerun ()
  "Rerun the last test that was run by ruby-test.

When no tests had been run before calling this function, do nothing."
  (interactive)
  (if ruby-test-last-test-command
      (ruby-test-with-ruby-directory ruby-test-last-run
                                     (ruby-test-run-command ruby-test-last-test-command))
    (message "No tests have been run yet")))

(defun ruby-test-run-command (command)
  "Run compilation COMMAND in rails or ruby root directory."
  (setq ruby-test-last-test-command command)
  (let ((compilation-environment
         (append ruby-test-execution-environment compilation-environment)))
    (compilation-start command t)))

(defun ruby-test-command (filename &optional line-number)
  "Return the command to run a unit test or a specification depending on the FILENAME and LINE-NUMBER."
  (cond ((ruby-test-minitest-p filename)
         (ruby-test-minitest-command filename line-number))
        ((ruby-test-spec-p filename)
         (ruby-test-spec-command filename line-number))
        ((ruby-test-rails-p filename)
         (ruby-test-rails-command filename line-number))
        ((ruby-test-p filename)
         (ruby-test-test-command filename line-number))
        (t (message "File is not a known ruby test file"))))

(defun ruby-test-rails-command (filename &optional line-number)
  "Return command to run test in FILENAME at LINE-NUMBER with Rails test runner."
  (let ((line-part (if line-number
                       (format ":%d" line-number)
                     ""))
        (extra-options (if (not (null ruby-test-rails-test-options))
                           (mapconcat 'identity ruby-test-rails-test-options " ")
                         "")))
    (format "bundle exec rails test %s %s%s" extra-options filename line-part)))

(defun ruby-test-minitest-command (filename &optional line-number)
  "Return command to run minitest in FILENAME at LINE-NUMBER."
  (let (command options name-options)
    (if (file-exists-p ".zeus.sock")
      (setq command "zeus test")
      (setq command "bundle exec ruby"))
    (if (ruby-test-gem-root filename)
      (setq options (cons "-rrubygems" options)))
    (setq options (cons "-I'lib:test:spec'" options))
    (if line-number
      (let ((test-case (ruby-test-find-testcase-at filename line-number)))
        (if test-case
          (setq name-options (format "-n \"/%s/\"" test-case))
          (error "No test case at %s:%s" filename line-number)))
      (setq name-options ""))
    (format "%s %s %s %s" command (mapconcat 'identity options " ") filename name-options)))

(defun ruby-test-spec-command (filename &optional line-number)
  "Return command to run spec in FILENAME at LINE-NUMBER."
  (let ((command
         (cond ((file-exists-p ".zeus.sock") "zeus rspec")
               ((file-exists-p "bin/rspec") "bin/rspec")
               (t "bundle exec rspec")))
        (options ruby-test-rspec-options)
        (filename (if line-number
                      (format "%s:%s" filename line-number)
                    filename)))
    (format "%s %s %s" command (mapconcat 'identity options " ") filename)))

(defun ruby-test-test-command (filename &optional line-number)
  "Return command to run test in FILENAME at LINE-NUMBER."
  (let (command options name-options extra-options)
    (if (file-exists-p ".zeus.sock")
        (setq command "zeus test")
      (setq command "bundle exec ruby"))
    (if (ruby-test-gem-root filename)
        (setq options (cons "-rrubygems" options)))
    (setq options (cons "-I'lib:test'" options))
    (if line-number
        (let ((test-case (ruby-test-find-testcase-at filename line-number)))
          (if test-case
              (setq name-options (format "--name \"/%s/\"" test-case))
            (error "No test case at %s:%s" filename line-number)))
      (setq name-options ""))
    (setq extra-options
          (if (not (null ruby-test-plain-test-options))
              (mapconcat 'identity ruby-test-plain-test-options " ")
            ""))
    (format "%s %s %s %s %s" command (mapconcat 'identity options " ") filename name-options extra-options)))

(defun ruby-test-project-root (filename root-predicate)
  "Return the project root directory.
Consider a FILENAME using the given ROOT-PREDICATE, else nil.  The
function returns a directory if any of the directories in
FILENAME is tested to t by evaluating the ROOT-PREDICATE."
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
  "Return t if the given DIRECTORY has one of the filenames in CANDIDATES."
  (let ((found nil))
    (while (and (not found) (car candidates))
      (setq found
            (file-exists-p
             (concat (file-name-as-directory directory) (car candidates))))
      (setq candidates (cdr candidates)))
    found))

(defun ruby-test-rails-root (filename)
  "Return the Ruby on Rails project directory for the given FILENAME."
  (ruby-test-project-root filename 'ruby-test-rails-root-p))

(defun ruby-test-rails-root-p (directory)
  "Return t if the given DIRECTORY is the root of a Ruby on Rails project, else nil."
  (and directory
       (ruby-test-ruby-root-p directory)
       (ruby-test-project-root-p directory
                                 '("config/environment.rb" "config/database.yml" "config/routes.rb"))))

(defun ruby-test-gem-root (filename)
  "Return the gem project directory for the given FILENAME, else nil."
  (ruby-test-project-root filename 'ruby-test-gem-root-p))

(defun ruby-test-gem-root-p (directory)
  "Return t if the given DIRECTORY is the root of a Ruby on gem, else nil."
  (and (ruby-test-ruby-root-p directory)
       (> (length (directory-files directory nil ".gemspec")) 0)))

(defun ruby-test-ruby-root (filename)
  "Return the Ruby project directory for the given FILENAME,else nil."
  (ruby-test-project-root filename 'ruby-test-ruby-root-p))

(defun ruby-test-ruby-root-p (directory)
  "Return t if the given DIRECTORY is the root of a Ruby project, else nil."
  (or (ruby-test-project-root-p directory '("Rakefile"))
      (ruby-test-project-root-p directory '("Rakefile.rb"))
      (ruby-test-project-root-p directory '("spec"))
      (ruby-test-project-root-p directory '("test"))))

(defun ruby-test-specification-filename (&optional filename)
  "Return the specification filename for the current buffer's filename or the optional FILENAME, else nil."
  (let ((filename (or filename (buffer-file-name))))
    (ruby-test-find-target-filename filename ruby-test-specification-filename-mapping)))

;;;###autoload
(defun ruby-test-toggle-implementation-and-specification (&optional filename)
  "Toggle between the implementation and specification/test file for the current buffer or the optional FILENAME."
  (interactive)
  (let ((filename (or filename (buffer-file-name))))
    (cond ((ruby-test-implementation-p filename)
           (cond ((file-exists-p (ruby-test-specification-filename filename))
                  (find-file (ruby-test-specification-filename filename)))
                 ((file-exists-p (ruby-test-unit-filename filename))
                  (find-file (ruby-test-unit-filename filename)))
                 ((ruby-test-default-test-filename filename)
                  (find-file (ruby-test-default-test-filename filename)))
                 (t
                  (put-text-property 0 (length filename) 'face 'bold filename)
                  (message "Sorry, can't guess unit/specification filename from %s." filename))))
          ((or (ruby-test-spec-p filename) (ruby-test-p filename))
           (find-file (ruby-test-implementation-filename filename)))
          (t
           (put-text-property 0 (length filename) 'face 'bold filename)
           (message "Sorry, %s is neither a Ruby implementation nor a test file." filename)))))

(defun ruby-test-unit-filename (&optional filename)
  "Return the unit filename for the current buffer's filename or the optional FILENAME, else nil."
  (let ((filename (or filename (buffer-file-name))))
    (ruby-test-find-target-filename filename ruby-test-unit-filename-mapping)))

(defun ruby-test-default-test-filename (filename)
  "Return the default test filename for FILENAME."
  (cond ((and (string-equal ruby-test-default-library "test")
              (ruby-test-unit-filename filename))
         (ruby-test-unit-filename filename))
        ((and (string-equal ruby-test-default-library "spec")
              (ruby-test-specification-filename filename))
         (ruby-test-specification-filename filename))
        (t nil)))

(defun ruby-test-enable ()
  "Enable the ruby test mode."
  (ruby-test-mode t))

(add-hook 'ruby-mode-hook 'ruby-test-enable)

(provide 'ruby-test-mode)

;;; ruby-test-mode.el ends here
