;;; ox-750words.el --- Org mode exporter for 750words.com -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Diego Zamboni

;; Author: Diego Zamboni <https://github.com/zzamboni>
;; Maintainer: Diego Zamboni <diego@zzamboni.org>
;; Created: June 10, 2021
;; Modified: June 10, 2021
;; Version: 0.0.1
;; Package-Version: 20210701.1950
;; Package-Commit: 0fed7621c04debad64ea6455455494d4e6eb03fa
;; Keywords: files, org, writing
;; Homepage: https://github.com/zzamboni/750words-client
;; Package-Requires: ((emacs "24.4") (750words "0.0.1"))

;; This file is not part of GNU Emacs.

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at

;;     https://www.apache.org/licenses/LICENSE-2.0

;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; An Org exporter which converts Org to Markdown and posts it to 750words.com.

;; See https://github.com/zzamboni/750words-client for full usage instructions.

;;; Code:

(require '750words)
(require 'ox-md)

(org-export-define-derived-backend '750words 'md
  :menu-entry
  '(?m 1
       ((?7 "Post to 750words.com"
            (lambda (_a s v _b) (org-750words-export-to-750words s v))))))

(defun org-750words-export-to-750words (subtreep visible-only)
  "Post Org text to 750words.com.

The Org buffer is first converted to Markdown using ox-md, and
the result posted to 750words.com.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements."
  (let* ((outfile (make-temp-file "ox-750words"))
         (org-export-with-smart-quotes nil))
    (org-export-to-file 'md outfile nil subtreep visible-only)
    (750words-file outfile)))

(provide 'ox-750words)
;;; ox-750words.el ends here
