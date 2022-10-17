;;; archive-phar.el --- Phar file support for archive-mode     -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Friends of Emacs-PHP development

;; Maintainer: USAMI Kenta <tadsan@zonu.me>
;; URL: https://github.com/emacs-php/archive-phar.el
;; Package-Version: 20221009.2129
;; Package-Commit: 0bda3e338446d06dbe9d8c8837dee746de48632f
;; Keywords: files
;; Version: 1.24.1
;; Package-Requires: ((emacs "28.1") (php-runtime "0.2") (datetime-format "0.0.1"))
;; License: GPL-3.0-or-later

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

;; This package add support PHP's Phar archive to archive-mode.
;; It currently only supports browsing files and does not implement editing archives.
;;
;; See <https://www.php.net/manual/book.phar.php> about Phar archive.

;;; Code:
(require 'arc-mode)
(require 'datetime-format)
(require 'nadvice)
(require 'php-mode nil t)
(require 'php-runtime)
(require 'json)

(eval-when-compile
  (require 'cl-lib)
  (defvar php-executable))

(defgroup archive-phar nil
  "Phar-specific options to archive."
  :group 'archive)

(defcustom archive-phar-php-executable (or (bound-and-true-p php-executable)
                               (executable-find "php")
                               "/usr/bin/php")
  "The location of the PHP executable for extract Phar archive."
  :tag "Archive Phar PHP Executable"
  :type 'string)

(defconst archive-phar-file-name-pattern
  (eval-when-compile (rx ".phar" string-end)))

;;;###autoload
(defun archive-phar-find-type ()
  "Added logic to `archive-find-type' to detect Phar."
  (let (case-fold-search)
    (when (and buffer-file-name
               (string-match archive-phar-file-name-pattern buffer-file-name))
      'phar)))

(defconst archive-phar--code-summarize-file
  "declare(strict_types=1);

$phar_path = trim(stream_get_contents(STDIN));
$tr = [\"phar://{$phar_path}/\" => ''];
$files = [];
$p = new Phar($phar_path);
foreach (new RecursiveIteratorIterator($p) as $f) {
    $files[] = [
        'pathname' => strtr($f->getPathname(), $tr),
        'mtime' => $f->getMTime(),
        'size' => $f->getSize(),
        'perms' => $f->getPerms(),
        'type' => $f->getType(),
    ];
}

echo json_encode($files, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
")

(defun archive-phar-summarize ()
  "Summarize Phar archive file."
  (let* ((php-runtime-php-executable archive-phar-php-executable)
         (phar-filepath buffer-file-name)
         (json (with-temp-buffer
                 (insert phar-filepath)
                 (php-runtime-eval archive-phar--code-summarize-file (current-buffer))))
         (data (with-temp-buffer
                 (insert json)
                 (goto-char (point-min))
                 (json-parse-buffer :object-type 'plist :array-type 'list)))
         (files
          (cl-loop for entry in data
                   for pathname = (plist-get entry :pathname)
                   for size = (plist-get entry :size)
                   for mtime = (datetime-format--int-to-timestamp (plist-get entry :mtime))
                   for time = (concat (archive-unixdate (cadr mtime) (car mtime))
                                      " "
                                      (archive-unixtime (cadr mtime) (car mtime)))
                   collect (archive--file-desc pathname pathname nil size time))))
    (archive--summarize-descs files)))

(defconst archive-phar--code-extract-file
  "declare(strict_types=1);

$input = trim(stream_get_contents(STDIN));
list($phar_path, $filename) = explode(\"\t\", $input);
$p = new Phar($phar_path, 0);
$alias = $p->getAlias();
readfile(\"phar://{$alias}/{$filename}\");
")

(defun archive-phar-extract (archive name)
  "Extract NAME file from Phar ARCHIVE."
  (insert (with-temp-buffer
            (insert (format "%s\t%s" archive name))
            (php-runtime-eval archive-phar--code-extract-file (current-buffer))))
  (current-buffer))

;;;###autoload
(with-eval-after-load "arc-mode"
  (advice-add #'archive-find-type :before-until #'archive-phar-find-type))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.phar\\'" . archive-mode))

(provide 'archive-phar)
;;; archive-phar.el ends here
