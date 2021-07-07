;;; cider-hydra.el --- Hydras for CIDER.     -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2018 Tianxiang Xiong

;; Author: Tianxiang Xiong <tianxiang.xiong@gmail.com>
;; Keywords: convenience, tools
;; Package-Version: 20190816.1121
;; Package-Commit: c3b8a15d72dddfbc390ab6a454bd7e4c765a2c95
;; Package-Requires: ((cider "0.22.0") (hydra "0.13.0"))
;; URL: https://github.com/clojure-emacs/cider-hydra
;; Version: 0.2.0-snapshot

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

;; This package defines some hydras (pop-up menus of commands with common
;; prefixes) for CIDER.

;; For more information about CIDER, see
;; https://github.com/clojure-emacs/cider

;; For more information about hydras, see https://github.com/abo-abo/hydra

;; Hydras serve several important purposes: discovery, memorization, and
;; organization.

;; - Discovery

;;   - Grouping related commands together under a common prefix and
;;     displaying them in a single menu facilitates discovery.

;;   - For example, if a user wants to know about CIDER's documentation
;;     commands, they could bring up a hydra that includes commands like
;;     `cider-doc', `cider-javadoc', etc, some of which may be new to them.

;; - Memorization

;;   - Hydras serve as a memory aid for the user.  By grouping related
;;     commands together, the user has less need to memorize every command;
;;     knowing one, she can find the others.

;; - Organization

;;   - The process of creating hydras can aid in organizing code.  This
;;     gives both developers and users a better overview of what the
;;     project can or cannot do.
;;
;;   - Thus, each hydra is like a section of a quick-reference card.  In
;;     fact, many of the hydras here are inspired by the CIDER refcard:
;;     https://github.com/clojure-emacs/cider/blob/master/doc/cider-refcard.pdf

;;; Code:

(require 'cider-apropos)
(require 'cider-client)
(require 'cider-doc)
(require 'cider-clojuredocs)
(require 'cider-eval)
(require 'cider-macroexpansion)
(require 'cider-mode)
(require 'cider-repl)
(require 'cider-test)
(require 'cider-inspector)
(require 'hydra)


;;;; Customize

(defgroup cider-hydra nil
  "Hydras for CIDER."
  :prefix "cider-hydra-"
  :group 'cider)


;;;; Documentation

(defhydra cider-hydra-doc (:color blue)
  "
CIDER Documentation
---------------------------------------------------------------------------
_d_: CiderDoc                           _j_: JavaDoc in browser
_a_: Search symbols                     _s_: Search symbols & select
_A_: Search documentation               _e_: Search documentation & select
_r_: ClojureDocs                        _h_: ClojureDocs in browser
"
  ;; CiderDoc
  ("d" cider-doc nil)
  ;; JavaDoc
  ("j" cider-javadoc nil)
  ;; Apropos
  ("a" cider-apropos nil)
  ("s" cider-apropos-select nil)
  ("A" cider-apropos-documentation nil)
  ("e" cider-apropos-documentation-select nil)
  ;; ClojureDocs
  ("r" cider-clojuredocs nil)
  ("h" cider-clojuredocs-web nil))


;;;; Loading and evaluation

(defhydra cider-hydra-eval (:color blue)
  "
CIDER Evaluation
---------------------------------------------------------------------------
_k_: Load (eval) buffer                 _l_: Load (eval) file
_p_: Load all project namespaces
_r_: Eval region                        _n_: Eval ns form
_e_: Eval last sexp                     _p_: Eval last sexp and pprint
_w_: Eval last sexp and replace         _E_: Eval last sexp to REPL
_d_: Eval defun at point                _f_: Eval defun at point and pprint
_:_: Read and eval                      _i_: Inspect
_m_: Macroexpand-1                      _M_: Macroexpand all
"
  ;; Load
  ("k" cider-load-buffer nil)
  ("l" cider-load-file nil)
  ("p" cider-load-all-project-ns nil)
  ;; Eval
  ("r" cider-eval-region nil)
  ("n" cider-eval-ns-form nil)
  ("e" cider-eval-last-sexp nil)
  ("p" cider-pprint-eval-last-sexp nil)
  ("w" cider-eval-last-sexp-and-replace nil)
  ("E" cider-eval-last-sexp-to-repl nil)
  ("d" cider-eval-defun-at-point nil)
  ("f" cider-pprint-eval-defun-at-point nil)
  (":" cider-read-and-eval nil)
  ;; Inspect
  ("i" cider-inspect nil)
  ;; Macroexpand
  ("m" cider-macroexpand-1 nil)
  ("M" cider-macroexpand-all nil))


;;;; Testing and debugging

(defhydra cider-hydra-test (:color blue)
  "
CIDER Debug and Test
---------------------------------------------------------------------------
_x_: Eval defun at point
_v_: Toggle var tracing                 _n_: Toggle ns tracing
_t_: Run test                           _l_: Run loaded tests
_p_: Run project tests                  _r_: Rerun tests
_s_: Show test report
"
  ;; Debugging
  ("x" (lambda () (interactive) (cider-eval-defun-at-point t)) nil)
  ("v" cider-toggle-trace-var nil)
  ("n" cider-toggle-trace-ns nil)
  ;; Testing
  ("t" cider-test-run-test nil)
  ("l" cider-test-run-loaded-tests nil)
  ("r" cider-test-rerun-failed-tests nil)
  ("p" cider-test-run-project-tests nil)
  ("s" cider-test-show-report nil))


;;;; REPL

(defhydra cider-hydra-repl (:color blue)
  "
CIDER REPL
---------------------------------------------------------------------------
_d_: Display connection info            _r_: Rotate default connection
_z_: Switch to REPL                     _n_: Set REPL ns
_p_: Insert last sexp in REPL           _x_: Reload namespaces
_o_: Clear REPL output                  _O_: Clear entire REPL
_b_: Interrupt pending evaluations      _Q_: Quit CIDER
"
  ;; Connection
  ("d" cider-display-connection-info nil)
  ("r" cider-rotate-default-connection nil)
  ;; Input
  ("z" cider-switch-to-repl-buffer nil)
  ("n" cider-repl-set-ns nil)
  ("p" cider-insert-last-sexp-in-repl nil)
  ("x" cider-refresh nil)
  ;; Output
  ("o" cider-find-and-clear-repl-output nil)
  ("O" (lambda () (interactive) (cider-find-and-clear-repl-output t)) nil)
  ;; Interrupt/quit
  ("b" cider-interrupt nil)
  ("Q" cider-quit nil))


;;;; Key bindings and minor mode

(defvar cider-hydra-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map cider-mode-map)
    (define-key map (kbd "C-c C-d") #'cider-hydra-doc/body)
    (define-key map (kbd "C-c C-t") #'cider-hydra-test/body)
    (define-key map (kbd "C-c M-t") #'cider-hydra-test/body)
    (define-key map (kbd "C-c M-r") #'cider-hydra-repl/body)
    map)
  "Keymap for CIDER hydras.")

;;;###autoload
(define-minor-mode cider-hydra-mode
  "Hydras for CIDER."
  :keymap cider-hydra-map
  :require 'cider)


(provide 'cider-hydra)
;;; cider-hydra.el ends here
