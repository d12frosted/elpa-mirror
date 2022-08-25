;;; mmm-jinja2.el --- MMM submode class for Jinja2 Templates

;; Copyright (C) 2015  Ben Hayden

;; Author: Ben Hayden <hayden767@gmail.com>
;; URL: https://github.com/glynnforrest/mmm-jinja2
;; Package-Version: 20170313.1420
;; Package-Commit: c8cb763174fa2fb61b9a0e5e0ff8cb0210f8492f
;; Version: 0.1
;; Package-Requires: ((mmm-mode "0.5.4"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file incorporates work covered by the following copyright and
;; permission notice:

;;   Licensed under the Apache License, Version 2.0 (the "License"); you may not
;;   use this file except in compliance with the License.  You may obtain a copy
;;   of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
;;   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
;;   License for the specific language governing permissions and limitations
;;   under the License.

;;; Commentary:

;; Parts of this code was borrowed from mmm-mako mode. (Thanks Philip Jenvey)

;;; Code:

(require 'mmm-auto)
(require 'mmm-compat)
(require 'mmm-vars)

;; Jinja2 Tags


;; Add Classes

(mmm-add-group
 'jinja2
 `((jinja2-variable
    :submode python-mode
    :face mmm-code-submode-face
    :front "{{"
    :back "}}"
    :insert ((?{ jinja2-{{-}} nil @ "{{" @ " " _ " " @ "}}" @)))
   (jinja2-comment
    :submode text-mode
    :face mmm-comment-submode-face
    :front "{#"
    :back "#}"
    :insert ((?# jinja2-comment nil @ "{#" @ " " _ " " @ "#}" @)))
   (jinja2-block
    :submode python-mode
    :face mmm-code-submode-face
    :front "{%"
    :back "%}"
    :insert ((?% jinja2-{%-%} nil @ "{%" @ " " _ " " @ "%}" @)))))

;; Set Mode Line

(defun mmm-jinja2-set-mode-line ()
  "Set the mode line to Jinja2."
  (setq mmm-buffer-mode-display-name "Jinja2"))
(add-hook 'mmm-jinja2-class-hook 'mmm-jinja2-set-mode-line)

;;}}}

(provide 'mmm-jinja2)

;;; mmm-jinja2.el ends here
