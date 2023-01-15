;;; coffee-fof.el --- A coffee-mode configuration for `ff-find-other-file'.
;; Copyright (C) 2013 Yasuyki Oka

;; Author: Yasuyki Oka <yasuyk@gmail.com>
;; Keywords: coffee-mode
;; Package-Version: 20131012.1230
;; Package-Commit: 211529594bc074721c6cbc4edb73a63cc05f89ac
;; Version: DEV
;; Package-Requires: ((coffee-mode "0.4.1"))
;; URL: http://github.com/yasuyk/coffee-fof

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;
;; Introduction:
;;
;; A coffee-mode configuration for `ff-find-other-file'.
;;
;; * You can find the CoffeeScript or JavaScript file corresponding to
;;   this file.
;; * You can find the CoffeeScrpt/JavaScript or test/spec file
;;   corresponding to this file.
;;
;;
;; Requirements:
;;
;; * `coffee-mode'
;; * `js-mode', `js2-mode' or `js3-mode'
;;
;;
;; Usage:
;;
;; * coffee-find-other-file: `C-c f'
;;
;;   Find the CoffeeScript or JavaScript file corresponding to this
;;   file.  This command is enabled in `coffee-mode', `js-mode',
;;   `js2-mode', `js3-mode'.
;;
;; * coffee-find-test-file: `C-c s'
;;
;;   Find the CoffeeScript/JavaScript or test/spec file corresponding
;;   to this file.  This command is enabled in `coffee-mode`,
;;   `js-mode`, `js2-mode`, `js3-mode`.
;;
;;
;; Configuration:
;;
;; Add the following to your Emacs init file:
;;
;;     (require 'coffee-fof) ;; Not necessary if using ELPA package
;;     (coffee-fof-setup)
;;
;; If the .coffee files and .js files are in the same directory, a
;; configuration is not necessary as default value of
;; coffee-fof-search-directories is '(".").
;;
;; If the .coffee and .js files are in different directories, for
;; example, .js files are in `js` directory and .coffee files are in
;; `coffee` directory as below, customize
;; `coffee-fof-search-directories`.
;;
;;     .
;;     ├── coffee
;;     │   └── example.coffee
;;     └── js
;;         └── example.js
;;
;;
;;     (custom-set-variables
;;      '(coffee-fof-search-directories
;;       '("." "../*")))
;;
;; If you want to set another key binding, configure as follow.
;;
;;     (coffee-fof-setup :other-key "C-c C-f" :test-key "C-c t")
;;
;;

;;; Code:

(defgroup coffee-fof nil
  "Find a coffee/js file corresponding to this one given a pattern."
  :prefix "coffee-fof-"
  :link '(emacs-commentary-link "find-file")
  :group 'find-file)

(defcustom coffee-fof-other-file-alist
  '(("\\.coffee$" (".js")) ("\\.js$" (".coffee")))
  "See the description of the `ff-other-file-alist' variable."
  :type '(repeat (list regexp (choice (repeat string) function)))
  :group 'coffee-fof)

(defcustom coffee-fof-search-directories
  '(".")
  "See the description of the `ff-search-directories' variable."
  :type '(repeat directory)
  :group 'coffee-fof)

(defvar coffee-find-other-file-key "C-c f"
  "A local binding Key as `coffee-find-other-file' commmand.")

(defcustom coffee-fof-test-coffee-file-name-list
  '("_spec.coffee" "_test.coffee" "_Spec.coffee" "_Test.coffee"
    "Spec.coffee" "Test.coffee" "spec.coffee" "test.coffee")
  "List of name suffix of CoffeeScript test file corresponding to CoffeeScript file."
  :type '(repeat string)
  :group 'coffee-fof)

(defcustom coffee-fof-test-js-file-name-list
  '("_spec.js" "_test.js"  "_Spec.js" "_Test.js" "Spec.js" "Test.js" "spec.js" "test.js")
  "List of name suffix of JavaScript test file corresponding to JavaScript file."
  :type '(repeat string)
  :group 'coffee-fof)

(defcustom coffee-fof-test-file-alist
  `(("_[sS]pec\\.coffee$" (".coffee"))
    ("_[tT]est\\.coffee$" (".coffee"))
    ("[sS]pec\\.coffee$" (".coffee"))
    ("[tT]est\\.coffee$" (".coffee"))
    ("\\.coffee$" ,coffee-fof-test-coffee-file-name-list)
    ("_[sS]pec\\.js$" (".js"))
    ("_[tT]est\\.js$" (".js"))
    ("[sS]pec\\.js$" (".js"))
    ("[tT]est\\.js$" (".js"))
    ("\\.js$" ,coffee-fof-test-js-file-name-list))
  "See the description of the `ff-other-file-alist' variable."
  :type '(repeat (list regexp (choice (repeat string) function)))
  :group 'coffee-fof)

(defcustom coffee-fof-test-search-directories
  '(".")
  "See the description of the `ff-search-directories' variable."
  :type '(repeat directory)
  :group 'coffee-fof)

(defvar coffee-find-test-file-key "C-c s"
  "A local binding Key as `coffee-find-test-file' commmand.")

;;;###autoload
(defun coffee-find-other-file (&optional in-other-window)
  "Find the CoffeeScript or JavaScript file corresponding to this file.

If optional IN-OTHER-WINDOW is non-nil, find the file in the other window.
For more Information, See `ff-find-other-file' function."
  (interactive "P")
  (let ((ff-other-file-alist coffee-fof-other-file-alist)
        (ff-search-directories coffee-fof-search-directories))
    (call-interactively 'ff-find-other-file)))

;;;###autoload
(defun coffee-find-test-file (&optional in-other-window)
  "Find the CoffeeScrpt/JavaScript or test file corresponding to this file.

If optional IN-OTHER-WINDOW is non-nil, find the file in the other window.
For more Information, See `ff-find-other-file' function."
  (interactive "P")
  (let ((ff-other-file-alist coffee-fof-test-file-alist)
        (ff-search-directories coffee-fof-test-search-directories))
    (call-interactively 'ff-find-other-file)))

(defun coffee-fof-set-keys ()
  "Bind keys.

Give `coffee-find-other-file-key' a local binding as
`coffee-find-other-file'.
Give `coffee-find-test-file-key' a local binding as
`coffee-find-test-file'."
  (local-set-key (read-kbd-macro coffee-find-other-file-key) 'coffee-find-other-file)
  (local-set-key (read-kbd-macro coffee-find-test-file-key) 'coffee-find-test-file))

(defconst coffee-fof-setup-argument-keys
  '(:other-key :test-key))

;;;###autoload
(defun coffee-fof-setup (&rest plist)
  "Setup coffee-fof.

Keywords supported:
:other-key :test-key

PLIST is a list like \(:key1 val1 :key2 val2 ...\).

Basic keywords are the following:

\:other-key

Give key a local binding as `coffee-find-other-file'
in `js-mode-map', `js2-mode-map', `js3-mode-map' and `coffee-mode-map'.

\:test-key

Give key a local binding as `coffee-find-test-file'
in `js-mode-map', `js2-mode-map', `js3-mode-map' and `coffee-mode-map'."
  (let ((okey (plist-get plist :other-key))
        (tkey (plist-get plist :test-key)))
    (when okey (setq coffee-find-other-file-key okey))
    (when tkey (setq coffee-find-test-file-key tkey))
    (add-hook 'js-mode-hook 'coffee-fof-set-keys)
    (add-hook 'js2-mode-hook 'coffee-fof-set-keys)
    (add-hook 'js3-mode-hook 'coffee-fof-set-keys)
    (add-hook 'coffee-mode-hook 'coffee-fof-set-keys)))

(provide 'coffee-fof)

;; Local Variables:
;; coding: utf-8
;; eval: (checkdoc-minor-mode 1)
;; End:

;;; coffee-fof.el ends here
