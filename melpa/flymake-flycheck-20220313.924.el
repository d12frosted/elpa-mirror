;;; flymake-flycheck.el --- Use flycheck checkers as flymake backends  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Keywords: convenience, languages, tools
;; Package-Version: 20220313.924
;; Package-Commit: 850a3f2f6908db5d4a3739e385b2c9fb3ad488f9
;; Homepage: https://github.com/purcell/flymake-flycheck
;; Version: 0.1-pre
;; Package-Requires: ((flycheck "31") (emacs "26.1"))

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

;;; Commentary:

;; WARNING: EARLY PREVIEW CODE, SUBJECT TO CHANGE

;; This package provides support for running any flycheck checker as a
;; flymake diagnostic backend.  The effect is that flymake will
;; control when the checker runs, and flymake will receive its errors.

;; For example, to enable a couple of flycheck checkers in a bash
;; buffer, the following code is sufficient:

;;     (setq-local flymake-diagnostic-functions
;;                 (list (flymake-flycheck-diagnostic-function-for 'sh-shellcheck)
;;                       (flymake-flycheck-diagnostic-function-for 'sh-posix-bash)))

;; In order to add diagnostic functions for all checkers that are
;; available in the current buffer, you can use:

;;     (setq-local flymake-diagnostic-functions (flymake-flycheck-all-chained-diagnostic-functions))

;; but note that this will disable any existing flymake diagnostic
;; backends.

;; Some caveats:

;; * Flycheck UI packages will have no idea of what the checkers are
;;   doing, because they are run without flycheck's coordination.
;; * Flycheck's notion of "chained checkers" is not handled
;;   automatically, so although multiple chained checkers can be used,
;;   they will all be executed simultaneously even if earlier checkers
;;   fail.  This could either be considered a feature, or lead to
;;   redundant confusing messages.

;;; Code:

(require 'flycheck)
(require 'flymake)

(defvar flymake-flycheck-debug nil
  "When non-nil, output some debug messages.")

(defun flymake-flycheck--debug (msg &rest args)
  "Outputs debug messages if `flymake-flycheck-debug' is non-nil.
MSG and ARGS are passed to `message'."
  (when flymake-flycheck-debug
    (apply 'message (concat "[flymake-flycheck] (%s) " msg) (buffer-name) args)))

;;;###autoload
(defun flymake-flycheck-all-available-diagnostic-functions ()
  "Return a list of diagnostic functions for all usable checkers.
These might end up providing duplicate functionality, e.g. both
dash and bash might be used to check a `sh-mode' buffer if both are
found to be installed.

Usually you will want to use `flymake-flycheck-all-chained-diagnostic-functions' instead."
  (mapcar #'flymake-flycheck-diagnostic-function-for
          (seq-filter #'flycheck-may-use-checker flycheck-checkers)))

;;;###autoload
(defun flymake-flycheck-all-chained-diagnostic-functions ()
  "Return a list of diagnostic functions for the current checker chain."
  (when-let ((start (or flycheck-checker (seq-find #'flycheck-may-use-checker flycheck-checkers))))
    (let (checkers
          (nexts (list start)))
      (while nexts
        (setq checkers (append checkers nexts))
        (setq nexts (seq-filter #'flycheck-may-use-checker
                                (seq-mapcat #'flycheck-get-next-checkers nexts))))
      (mapcar #'flymake-flycheck-diagnostic-function-for (seq-uniq checkers)))))

;;;###autoload
(defun flymake-flycheck-diagnostic-function-for (checker)
  "Wrap CHECKER to make a `flymake-diagnostics-functions' backend."
  (let (current-check)
    (lambda (report-fn &rest _)
      (when current-check
        (flymake-flycheck--debug "interrupting defunct syntax check for %s" checker)
        (flycheck-syntax-check-interrupt current-check)
        (setq current-check nil))
      (flymake-flycheck--debug "start syntax check for %s" checker)
      (setq current-check (flycheck-syntax-check-new
                           :buffer (current-buffer)
                           :checker checker
                           :context nil
                           :working-directory (flycheck-compute-working-directory checker)))
      (flycheck-syntax-check-start
       current-check
       (lambda (status &optional data)
         (flymake-flycheck--debug "received status %S from %s" status checker)
         (pcase status
           ('errored (funcall report-fn
                              :panic
                              :explanation (format "Flycheck checker %s reported error %S" checker data)))
           ('finished (funcall report-fn
                               (mapcar (apply-partially #'flymake-flycheck--translate-error checker) data)
                               :region (cons (point-min) (point-max))))
           ('interrupted (flymake-flycheck--debug "checker %s reported being interrupted %S" checker data))
           ('suspicious (flymake-flycheck--debug "checker %s reported suspicious result %S" checker data))
           (_ (flymake-flycheck--debug "unexpected status from checker %s: %S" checker status))))))))

(defun flymake-flycheck--translate-error (checker err)
  "Translate flycheck CHECKER error ERR into a flymake diagnostic."
  (flycheck-error-with-buffer err
    ;; TODO: handle id, group, filename
    (flymake-make-diagnostic
     (flycheck-error-buffer err)
     (flycheck-error-pos err)
     (pcase (flycheck--exact-region err)
       (`(,beg . ,end) end)
       (_ (1+ (flycheck-error-pos err))))
     (pcase (flycheck-error-level err)
       ('error 'flymake-error)
       ('warning 'flymake-warning)
       ('info 'flymake-note)
       (_
        (flymake-flycheck--debug "Translating unknown error level %s to note" (flycheck-error-level err))
        'flymake-note))
     (format "%s [%s]" (flycheck-error-message err) checker))))


(provide 'flymake-flycheck)
;;; flymake-flycheck.el ends here
