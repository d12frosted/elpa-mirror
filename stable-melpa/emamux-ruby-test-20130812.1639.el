;;; emamux-ruby-test.el --- Ruby test with emamux

;; Copyright (C) 2013 by Syohei YOSHIDA, Malyshev Artem

;; Authors: Syohei YOSHIDA <syohex@gmail.com>
;;          Malyshev Artem <proofit404@gmail.com>
;; URL: https://github.com/syohex/emamux-ruby-test
;; Package-Version: 20130812.1639
;; Package-Commit: 785bfd44d097a46bb2ebe1e62ac7595fd4dc9ab5
;; Package-Requires: ((emamux "0.01") (projectile "0.9.1"))

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

;; emamux-ruby-test makes you test ruby file with emamux.
;; This package is inspired by vimux-ruby-test.
;;
;; To use emamux-ruby-test, add the following code into your init.el or .emacs:
;;
;;    (require 'emamux-ruby-test)
;;    (global-emamux-ruby-test-mode)
;;
;; To use emamux-ruby-test with specific mode only, add folowing:
;;
;;    (require 'emamux-ruby-test)
;;    (add-hook 'ruby-mode-hook 'emamux-ruby-test-mode)
;;
;; emamux-ruby-test provides following commands:
;;
;; Run all tests/specs in the current project
;;   C-c r T --- emamux-ruby-test:run-all
;;
;; Run all tests/specs in the current file
;;   C-c r t --- emamux-ruby-test:run-current-test
;;
;; Load ruby console dependent of current project type
;;   C-c r c --- emamux-ruby-test:run-console
;;
;; Run focused test/spec in test framework specific tool
;;   C-c r . --- emamux-ruby-test:run-focused-test
;;
;; Run focused class/context in test framework specific tool
;;   C-c r , --- emamux-ruby-test:run-focused-goal
;;
;; Close test pane
;;   C-c r k --- emamux:close-runner-pane
;;
;; Visit test pane in copy mode
;;   C-c r j --- emamux:inspect-runner

;;; Code:

(require 'emamux)
(require 'projectile)

(defgroup emamux-ruby-test nil
  "Ruby test with emamux"
  :group 'tools)

(defcustom emamux-ruby-test-keymap-prefix (kbd "C-c r")
  "Keymap prefix for emamux-ruby-test mode."
  :group 'emamux-ruby-test
  :type 'string)

(defcustom emamux-ruby-test-mode-lighter " Test"
  "Lighter used in emamux-ruby-test-mode."
  :group 'emamux-ruby-test
  :type 'string)

(defcustom emamux-ruby-test:tconsole-orientation 'horizonal
  "Orientation of splitting tconsole pane"
  :type '(choice (const :tag "Split pane vertial" vertical)
                 (const :tag "Split pane horizonal" horizonal))
  :group 'emamux)

(defcustom emamux-ruby-test:tconsole-height 50
  "Height of splitting tconsole pane"
  :type  'integer
  :group 'emamux)

(unless (fboundp 'cl-flet)
  (require 'cl)
  (defalias 'cl-flet 'flet))


;;; Utility functions.

(defun emamux-rt:project-root ()
  "Absolute path to ruby project."
  (let ((projectile-require-project-root t))
    (ignore-errors
      (projectile-project-root))))

(defun emamux-rt:project-type ()
  "Ruby project type specification."
  (let ((projectile-require-project-root t))
    (ignore-errors
      (projectile-project-type))))

(defun emamux-rt:source-file-p (file)
  "Return t if FILE is a ruby source."
  (and file
       (file-regular-p file)
       (s-ends-with? ".rb" file)))

(defun emamux-rt:project-p ()
  "Return t if PROJ is a ruby language project."
  (or (emamux-rt:rails-project-p)
      (emamux-rt:ruby-project-p)))

(defun emamux-rt:rails-project-p ()
  "Return t if PROJ is a rails framework project."
  (s-starts-with? "rails" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:ruby-project-p ()
  "Return t if PROJ is a rails framework project."
  (s-starts-with? "ruby" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:test-unit-p ()
  "Return t if PROJ is a rails framework project."
  (s-ends-with? "test" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:rspec-p ()
  "Return t if PROJ is a rails framework project."
  (s-ends-with? "rspec" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:relative-file-name (file)
  "Return relative path name for FILE."
  (substring file (length (emamux-rt:project-root))))

(defun emamux-rt:relative-test-name (file)
  "Return relative test name for FILE."
  (if (projectile-test-file-p file)
      (emamux-rt:relative-file-name file)
    (or (projectile-find-matching-test file)
        (error "No corresponding test/spec found"))))


;;; Projects functions.

(defun emamux-rt:test-command ()
  "Return command to test whole project"
  (projectile-test-command (emamux-rt:project-root)))

(defun emamux-rt:console-command ()
  "Return command appropriate to start project console."
  (cond
   ((emamux-rt:rails-project-p)
    "bundle exec rails console")
   ((emamux-rt:ruby-project-p)
    "bundle console")
   (t
    (error "No console type found"))))

(defun emamux-rt:current-test-pattern ()
  "Return string appropriate for formatting current test command."
  (cond
   ((emamux-rt:rspec-p)
    "bundle exec rspec %s")
   ((emamux-rt:test-unit-p)
    "bundle exec rake test TEST=%s")
   (t
    (error "No test engine found"))))


;;; Content functions.

(defun emamux-rt:focused-test ()
  "Return (LINE . DEFINITION) pair for current def/test/should above.
Definition here is a form processed to be appropriate for sending it
into external tools."
  (save-excursion
    (cl-flet
        ((def-p () (looking-at-p "[ ]*def [a-zA-Z0-9_-]+"))
         (test-p () (looking-at-p "[ ]*test ['\"][a-zA-Z0-9 _-]+['\"]")))
      (beginning-of-line)
      (while (not (or (def-p) (test-p)))
        (if (eq (point) (point-min))
            (error "Can't find focused test/spec")
          (previous-line)))
      (let ((str
             (buffer-substring-no-properties
              (line-beginning-position)
              (line-end-position))))
        (cons
         (line-number-at-pos)
         (cond
          ((def-p) (cadr (s-split "[ ()]+" str t)))
          ((test-p) (s-join "_" (butlast (s-split "[ _'\"]+" str t))))))))))

(defun emamux-rt:focused-goal ()
  "Return (LINE . DEFINITION) pair for current class/context.
Definition here is a form processed to be appropriate for sending it
into external tools."
  (save-excursion
    (cl-flet
        ((class-p () (looking-at-p "[ ]*class [a-zA-z0-9:]+")))
      (beginning-of-line)
      (while (not (class-p))
        (if (eq (point) (point-min))
            (error "Can't find focused class/context")
          (previous-line)))
      (let ((str
             (buffer-substring-no-properties
              (line-beginning-position)
              (line-end-position))))
        (cons (line-number-at-pos)
              (cond
               ((class-p) (cadr (s-split "[ <]+" str t)))))))))


;;; Services.

(defvar emamux-rt:runned-services nil
  "List variable stores ran test services in '(PATH SERVICE PANE-ID) form.")

(defun emamux-rt:add-service (path service pane-id)
  "Register running service."
  (add-to-list 'emamux-rt:runned-services (list path service pane-id)))

(defun emamux-rt:remove-service (path service)
  "Unregister running service."
  (setq emamux-rt:runned-services
        (--remove
         (and (eq service (cadr it))
              (equal (car it) (emamux-rt:project-root)))
         emamux-rt:runned-services)))

(defun emamux-rt:service-alive-p (service)
  "Check if SERVICE run in current project."
  (not
   (null
    (--filter
     (and (eq service (cadr it))
          (equal (car it) (emamux-rt:project-root)))
     emamux-rt:runned-services))))

(defun emamux-rt:service-pane-id (service)
  "Return pane id for SERVICE run in current project."
  (unless (emamux-rt:service-alive-p service)
    (error (format "No %s service running for this project." (symbol-name service))))
  (let ((service
         (car (--filter
               (and (eq service (cadr it))
                    (equal (car it) (emamux-rt:project-root)))
               emamux-rt:runned-services))))
    ;; Get pane id.
    (elt service 2)))

(defun emamux-rt:service-pane-alive-p (service)
  "Check if registered SERVICE has runner pane."
  (and (emamux-rt:service-alive-p service)
       (emamux:pane-alive-p (emamux-rt:service-pane-id service))))


;;; Tconsole.

(defun emamux-rt:run-tconsole ()
  "Load tconsole tool for ruby test unit framework."
  (if (emamux-rt:service-alive-p 'tconsole)
      ;; Normally this mean that tconsole was started early
      ;; but someone kill its pane or break it into another
      ;; window. So we lost information about it and must
      ;; unregister this service.
      (emamux-rt:remove-service (emamux-rt:project-root) 'tconsole))
  (if (not (emamux-rt:test-unit-p))
      (error "tconsole appropriate for ruby test unit only")
    (let ((emamux:default-orientation emamux-ruby-test:tconsole-orientation)
          (emamux:runner-pane-height emamux-ruby-test:tconsole-height))
      (emamux:run-command
       "bundle exec tconsole"
       (emamux-rt:project-root)))
    (emamux-rt:add-service (emamux-rt:project-root) 'tconsole emamux:runner-pane-id)
    (setq emamux:runner-pane-id nil)))

(defun emamux-rt:tconsole-send-focus (focus)
  "Send FOCUS in tconsole."
  (let ((current-pane (emamux:active-pane-id)))
    (unless (emamux-rt:service-pane-alive-p 'tconsole)
      (emamux-rt:run-tconsole))
    (emamux:send-keys focus (emamux-rt:service-pane-id 'tconsole))
    (emamux:select-pane current-pane)))

(defun emamux-rt:tconsole-focused-test ()
  "Return focused test appropriate for sending it in tconsole."
  (let ((test (emamux-rt:focused-test))
        (goal (emamux-rt:focused-goal)))
    (when (< (car goal) (car test))
      (format "%s#%s" (cdr goal) (cdr test)))))

(defun emamux-rt:tconsole-focused-goal ()
  "Return focused goal appropriate for sending it in tconsole."
  (cdr (emamux-rt:focused-goal)))

(defun emamux-rt:run-tconsole-focused-test ()
  "Send focused test in tconsole."
  (emamux-rt:tconsole-send-focus (emamux-rt:tconsole-focused-test)))

(defun emamux-rt:run-tconsole-focused-goal ()
  "Send focused goal in tconsole."
  (emamux-rt:tconsole-send-focus (emamux-rt:tconsole-focused-goal)))


;;; Runner functions.

(defun emamux-ruby-test:run-all ()
  "Run all tests/specs in the current project."
  (interactive)
  (emamux:run-command
   (emamux-rt:test-command)
   (emamux-rt:project-root)))

(defun emamux-ruby-test:run-console ()
  "Load ruby console dependent of current project type."
  (interactive)
  (emamux:run-command
   (emamux-rt:console-command)
   (emamux-rt:project-root)))

(defun emamux-ruby-test:run-current-test ()
  "Run all tests/specs in the current file."
  (interactive)
  (let ((file (buffer-file-name)))
    (if (not (emamux-rt:source-file-p file))
        (error "Can't find current test")
      (emamux:run-command
       (format
        (emamux-rt:current-test-pattern)
        (emamux-rt:relative-test-name file))
       (emamux-rt:project-root)))))

(defun emamux-ruby-test:run-focused-test ()
  "Run focused test/spec in test framework specific tool."
  (interactive)
  (let ((file (buffer-file-name)))
    (cond
     ((not (emamux-rt:source-file-p file))
      (error "Can't find focused test/spec"))
     ((emamux-rt:test-unit-p)
      (emamux-rt:run-tconsole-focused-test))
     (t
      (error "No test engine found")))))

(defun emamux-ruby-test:run-focused-goal ()
  "Run focused class/context in test framework specific tool."
  (interactive)
  (let ((file (buffer-file-name)))
    (cond
     ((not (emamux-rt:source-file-p file))
      (error "Can't find focused class/context"))
     ((emamux-rt:test-unit-p)
      (emamux-rt:run-tconsole-focused-goal))
     (t
      (error "No test engine found")))))


;;; Minor mode definition.

(defvar emamux-ruby-test-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "T") 'emamux-ruby-test:run-all)
      (define-key prefix-map (kbd "t") 'emamux-ruby-test:run-current-test)
      (define-key prefix-map (kbd ".") 'emamux-ruby-test:run-focused-test)
      (define-key prefix-map (kbd ",") 'emamux-ruby-test:run-focused-goal)
      (define-key prefix-map (kbd "c") 'emamux-ruby-test:run-console)
      (define-key prefix-map (kbd "k") 'emamux:close-runner-pane)
      (define-key prefix-map (kbd "j") 'emamux:inspect-runner)

      (define-key map emamux-ruby-test-keymap-prefix prefix-map))
    map)
  "Keymap for emamux-ruby-test mode.")

;;;###autoload

(define-minor-mode emamux-ruby-test-mode
  "Minor mode to Ruby test with emamux.

\\{emamux-ruby-test-mode-map}"
  :lighter emamux-ruby-test-mode-lighter
  :keymap emamux-ruby-test-mode-map
  :group 'emamux-ruby-test)

(define-globalized-minor-mode global-emamux-ruby-test-mode
  emamux-ruby-test-mode
  emamux-ruby-test-on)

(defun emamux-ruby-test-on ()
  "Enable emamux-ruby-test minor mode only if current buffer is a part of ruby project."
  (when (emamux-rt:project-p)
    (emamux-ruby-test-mode 1)))

(defun emamux-ruby-test-off ()
  "Disable emamux-ruby-test minor mode."
  (emamux-ruby-test-mode -1))

(provide 'emamux-ruby-test)

;;; emamux-ruby-test.el ends here
