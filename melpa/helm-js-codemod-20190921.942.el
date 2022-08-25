;;; helm-js-codemod.el --- A helm interface for running js-codemods -*- lexical-binding: t -*-

;; Copyright (C) 2017 @torgeir

;; Author: Torgeir Thoresen <@torgeir>
;; Version: 1.1.0
;; Package-Version: 20190921.942
;; Package-Commit: 1df8583fafadf8c8c5ceb2aecaa815a2a4152686
;; Keywords: helm js codemod region
;; Package-Requires: ((emacs "24.4") (helm-core "1.9.8") (js-codemod "1.0.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A helm interface for js-codemod - running mods on current sentence or
;; selected region. Run `helm-js-codemod' to list mods in
;; `helm-js-codemod-mod-dir' to run on the current sentence or the selected
;; region.

;;; Code:

(require 'helm)
(require 'js-codemod)

(defvar helm-js-codemod-mod-dir nil "Folder to read mods from.")

(defvar helm-js-codemod--no-mods-msg
  "No mods found. Set `helm-js-codemod-mod-dir' to the directory of your codemods and try again."
  "Msg shown when no mods are found.")

(defun helm-js-codemod--candidates ()
  "Candidate mods to run for the selected region. List files in `helm-js-codemod-mod-dir', expect `.' and `..'."
  (if (null helm-js-codemod-mod-dir)
      (list helm-js-codemod--no-mods-msg)
    (delete "."
            (delete ".."
                    (directory-files helm-js-codemod-mod-dir)))))

(defun helm-js-codemod--run (mod)
  "Run js-codemod on region, with the full path of the selected `MOD'."
  (js-codemod-mod-region (region-beginning)
                         (region-end)
                         (concat helm-js-codemod-mod-dir mod)))

(defvar helm-js-codemod--source
  (helm-build-sync-source "Execute codemod"
    :candidates #'helm-js-codemod--candidates
    :action #'helm-js-codemod--run)
  "Source to list available mods.")

;;;###autoload
(defun helm-js-codemod ()
  "`helm-js-codemod' entry point to run codemod on current line or seleted region."
  (interactive)
  (helm :sources '(helm-js-codemod--source)))

(provide 'helm-js-codemod)

;;; helm-js-codemod.el ends here
