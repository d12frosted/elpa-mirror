;;; elpa-clone.el --- Clone ELPA archive

;; Copyright (C) 2016, 2019, 2021 ZHANG Weiyi

;; Author: ZHANG Weiyi <dochang@gmail.com>
;; Version: 0.1.1
;; Package-Version: 20210916.655
;; Package-Commit: 2549b14e8688e9ee866e0ec9f1b6d9cbc97f462c
;; Package-Requires: ((emacs "24.4"))
;; Keywords: comm, elpa, clone, mirror
;; URL: https://github.com/dochang/elpa-clone

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; <!-- markdown-link-check-disable -->
;; [![MELPA](http://melpa.org/packages/elpa-clone-badge.svg)](http://melpa.org/#/elpa-clone)
;; [![MELPA Stable](http://stable.melpa.org/packages/elpa-clone-badge.svg)](http://stable.melpa.org/#/elpa-clone)
;; [![CI](https://github.com/dochang/elpa-clone/actions/workflows/ci.yml/badge.svg)](https://github.com/dochang/elpa-clone/actions/workflows/ci.yml)
;; [![Build Status](https://cloud.drone.io/api/badges/dochang/elpa-clone/status.svg)](https://cloud.drone.io/dochang/elpa-clone)
;; [![Build Status](https://travis-ci.org/dochang/elpa-clone.svg?branch=master)](https://travis-ci.org/dochang/elpa-clone)
;; [![GitHub](https://img.shields.io/github/license/dochang/elpa-clone)](https://github.com/dochang/elpa-clone/blob/master/LICENSE)
;; [![Say Thanks!](https://img.shields.io/badge/say-thanks-green)](https://saythanks.io/to/dochang)
;; <!--
;; See the following issues for details.
;;
;; <https://github.com/BlitzKraft/saythanks.io/issues/60>
;; <https://github.com/BlitzKraft/saythanks.io/issues/103>
;; -->
;; <!-- markdown-link-check-enable -->
;;
;; Mirror an ELPA archive into a directory.

;; Prerequisites:
;;
;; - Emacs 24.4 or later
;; - cl-lib
;; - rsync (optional, but recommended)

;; Installation:
;;
;; `elpa-clone` is available on [MELPA] and [el-get].
;;
;; [MELPA]: https://melpa.org/
;; [el-get]: https://github.com/dimitri/el-get
;;
;; To install `elpa-clone' from git repository, clone the repo, then add the
;; repo dir into `load-path'.

;; Usage:
;;
;; To clone an ELPA archive `http://host/elpa' into `/path/to/elpa', invoke
;; `elpa-clone':
;;
;;     (elpa-clone "http://host/elpa" "/path/to/elpa")
;;
;; `elpa-clone' can also be invoked via `M-x'.
;;
;; You can customize download interval via `elpa-clone-download-interval'.  But
;; note that the *real* interval is `(max elpa-clone-download-interval 5)'.
;;
;; ### Prefer rsync
;;
;; Some ELPA archives can more efficiently be cloned using rsync:
;;
;;     (elpa-clone "elpa.gnu.org::elpa/" "/path/to/elpa")
;;     (elpa-clone "rsync://melpa.org/packages/" "/path/to/elpa")
;;     (elpa-clone "rsync://stable.melpa.org/packages/" "/path/to/elpa")
;;
;; Currently, only the following archives support rsync:
;;
;; - GNU ELPA
;; - MELPA
;; - MELPA Stable
;;
;; By default, `elpa-clone` selects the appropriate sync method based on the
;; upstream url, but you can also specify the method you want:
;;
;;     (elpa-clone "foo/" "bar/" :sync-method 'rsync)
;;     (elpa-clone "foo::bar/" "/path/to/elpa" :sync-method 'local)
;;     (elpa-clone "rsync://foo/bar/" "/path/to/elpa" :sync-method 'url)
;;
;; Available methods are:
;;
;; - `rsync`: use rsync (recommended)
;; - `url`: use the `url` library
;; - `local`: treat upstream as a local directory
;; - `nil`: choose a method based on upstream

;; Note:
;;
;; `elpa-clone' will **NOT** overwrite existing packages but will clean
;; outdated packages before downloading new packages.  If a package file is
;; broken, remove the file and call `elpa-clone' again.

;; License:
;;
;; GPLv3

;;; Code:

(require 'url)
(require 'url-http)
(require 'package)
(require 'cl-lib)


(defgroup elpa-clone ()
  "Clone ELPA archive."
  :prefix "elpa-clone-"
  :group 'package)

(defcustom elpa-clone-download-interval 5
  "Interval between downloads, in seconds.

The value may be an integer or floating point."
  :type 'number
  :group 'elpa-clone)

(defun elpa-clone--read-archive-contents (buffer)
  "Read archive contents in BUFFER."
  (let ((contents (read buffer)))
    (when (> (car contents) package-archive-version)
      (error "Package archive version %d is higher than %d"
             (car contents) package-archive-version))
    (cdr contents)))

(defun elpa-clone--package-filename (pkg)
  "Return the filename of package PKG."
  (let* ((pkg-desc
          (package-desc-create
           :name (car pkg)
           :version (aref (cdr pkg) 0)
           :kind (aref (cdr pkg) 3))))
    (concat (package-desc-full-name pkg-desc)
            (package-desc-suffix pkg-desc))))

(defun elpa-clone--split-filename (filename)
  "Split FILENAME."
  (let* ((basename (file-name-base filename))
         (len (length basename))
         (pos (- len 1))
         (res -1))
    (while (and (>= pos 0)
                (= res -1))
      (when (and (= (aref basename pos) ?-)
                 (ignore-errors
                   (version-to-list (substring basename (1+ pos) len))))
        (setq res pos))
      (setq pos (1- pos)))
    (if (>= res 0)
        (list (substring basename 0 res)
              (substring basename (1+ res)))
      (list basename))))

(defun elpa-clone--cleaner (downstream)
  "Return a function that deletes ELPA files in DOWNSTREAM."
  (lambda (filename)
    (let* ((pkgname (car (elpa-clone--split-filename filename)))
           (readme-filename (concat pkgname "-readme.txt"))
           (readme-pathname (expand-file-name readme-filename downstream)))
      (when (file-exists-p readme-pathname)
        (delete-file readme-pathname)))
    (let* ((sig-filename (concat filename ".sig"))
           (sig-pathname (expand-file-name sig-filename downstream)))
      (when (file-exists-p sig-pathname)
        (delete-file sig-pathname)))
    (delete-file (expand-file-name filename downstream))))

(defun elpa-clone--downloader (upstream
                               downstream
                               signaturep
                               readme
                               upstream-join upstream-copy-file
                               upstream-file-exists-p)
  "Return a function that downloads readme file from UPSTREAM to DOWNSTREAM.

If SIGNATUREP is true, also downloads signature file.

README is the readme file to be downloaded.

UPSTREAM-JOIN is a function joins UPSTREAM url and filename.

UPSTREAM-COPY-FILE is a function copies file from UPSTREAM to DOWNSTREAM.

UPSTREAM-FILE-EXISTS-P is a function checks that whether a file is in UPSTREAM
or not."
  (lambda (filename)
    (sleep-for (max elpa-clone-download-interval 5))
    (let ((source (funcall upstream-join upstream filename))
          (target (expand-file-name filename downstream)))
      (unless (file-exists-p target)
        (let* ((pkgname (car (elpa-clone--split-filename filename)))
               (readme-filename (concat pkgname "-readme.txt"))
               (source-readme (funcall upstream-join upstream readme-filename)))
          (when (and (not (eq readme 'never))
                     (or readme
                         (funcall upstream-file-exists-p source-readme)))
            (funcall upstream-copy-file
                     source-readme
                     (expand-file-name readme-filename downstream)
                     'ok-if-already-exists)))
        (when signaturep
          (let* ((sig-filename (concat filename ".sig"))
                 (source-sig (funcall upstream-join upstream sig-filename))
                 (target-sig (expand-file-name sig-filename downstream)))
            (funcall upstream-copy-file
                     source-sig target-sig 'ok-if-already-exists)))
        (funcall upstream-copy-file source target)))))

(defun elpa-clone--internal (upstream
                             downstream
                             signature
                             readme
                             upstream-join
                             upstream-copy-file
                             upstream-insert-file-contents
                             upstream-file-exists-p)
  "Downloads readme file and signature file from UPSTREAM to DOWNSTREAM.

SIGNATURE is the signature file to be downloaded.

README is the readme file to be downloaded.

UPSTREAM-JOIN is a function joins UPSTREAM url and filename.

UPSTREAM-COPY-FILE is a function copies a file from UPSTREAM to DOWNSTREAM.

UPSTREAM-INSERT-FILE-CONTENTS is a function that

UPSTREAM-FILE-EXISTS-P is a function checks that whether a file is in UPSTREAM
or not."
  (let* (pkgs signaturep)
    (with-temp-buffer
      (let* ((contents-file "archive-contents")
             (sig-file (concat contents-file ".sig"))
             (upstream-contents-sig (funcall upstream-join upstream sig-file)))
        (funcall upstream-insert-file-contents
                 (funcall upstream-join upstream contents-file))
        (goto-char (point-min))
        (setq pkgs (elpa-clone--read-archive-contents (current-buffer)))
        (when (and (not (eq signature 'never))
                   (or signature
                       (funcall upstream-file-exists-p upstream-contents-sig)))
          (funcall upstream-copy-file
                   upstream-contents-sig
                   (expand-file-name sig-file downstream)
                   'ok-if-already-exists)
          (setq signaturep t))
        (write-file (expand-file-name contents-file downstream))))
    (let* ((upstream-filenames (mapcar 'elpa-clone--package-filename pkgs))
           (downstream-filenames (directory-files downstream nil
                                                  "\\.\\(el\\|tar\\)\\'"))
           (outdate-filenames (cl-set-difference downstream-filenames
                                                 upstream-filenames
                                                 :test 'string=))
           (new-filenames (cl-set-difference upstream-filenames
                                             downstream-filenames
                                             :test 'string=))
           (downloader (elpa-clone--downloader upstream downstream signaturep readme
                                               upstream-join upstream-copy-file
                                               upstream-file-exists-p))
           (cleaner (elpa-clone--cleaner downstream)))
      (mapc cleaner outdate-filenames)
      (mapc downloader new-filenames))))

(defun elpa-clone--url-join (upstream filename)
  "Join UPSTREAM url and FILENAME."
  (let* ((url (url-generic-parse-url upstream))
         (path-and-query (url-path-and-query url))
         (path (car path-and-query))
         (query (cdr path-and-query)))
    (when (or (null path) (equal path ""))
      (setq path "/"))
    (setq path (expand-file-name filename path))
    (setf (url-filename url) (if query (concat path "?" query) path))
    (url-recreate-url url)))

(defun elpa-clone--remote (upstream downstream signature readme)
  "Downloads signature and readme from a remote UPSTREAM to a local DOWNSTREAM.

SIGNATURE is the signature file.

README is the readme file."
  (elpa-clone--internal
   upstream downstream signature readme
   'elpa-clone--url-join
   'url-copy-file
   'url-insert-file-contents
   'url-http-file-exists-p))

(defun elpa-clone--local (upstream downstream signature readme)
  "Downloads signature and readme from a local UPSTREAM to a local DOWNSTREAM.

SIGNATURE is the signature file.

README is the readme file."
  (elpa-clone--internal
   upstream downstream signature readme
   (lambda (upstream filename)
     (expand-file-name filename upstream))
   'copy-file
   'insert-file-contents
   'file-exists-p))

(defun elpa-clone--rsync (upstream downstream)
  "Call rsync for UPSTREAM and DOWNSTREAM."
  (call-process "rsync" nil nil nil
                "--archive" "--compress" "--delete"
                upstream downstream))

(defun elpa-clone--select-sync-method (upstream)
  "Choose sync method based on UPSTREAM."
  (pcase upstream
    ((pred (string-match-p "\\`rsync://")) 'rsync)
    ((pred (string-match-p "\\`[a-zA-Z][[:alnum:]+.-]*://")) 'url)
    ((pred (string-match-p "\\`[[:alnum:]@.-]+::?[^:]*")) 'rsync)
    (_ 'local)))

;;;###autoload
(cl-defun elpa-clone (upstream downstream &key sync-method signature readme)
  "Clone ELPA archive.

UPSTREAM is an ELPA URL or local ELPA directory.
DOWNSTREAM is the download directory.

By default, `elpa-clone' will choose the appropriate SYNC-METHOD for UPSTREAM.
You can also specify the method.  Available methods are:

  `rsync' -- use rsync
  `url'   -- use the \"url\" library.  See Info node `(url)'.
  `local' -- treat UPSTREAM as a local directory.
  nil     -- choose a method based on UPSTREAM.

Default SYNC-METHOD is nil.

When SIGNATURE is nil, download *.sig files only if exists.
When SIGNATURE is `never', never download *.sig files.
When SIGNATURE is any other value, always download *.sig files.

When README is nil, download readme files only if exists.
When README is `never', never download readme files.
When README is any other value, always download readme files."
  (interactive "sUpstream URL or DIR: \nGDownload directory: ")

  (when (url-p upstream)
    (setq upstream (url-recreate-url upstream)))

  (unless upstream
    (error "Upstream must NOT be nil!"))

  (unless downstream
    (error "Download directory must NOT be nil!"))

  (setq downstream (expand-file-name downstream))
  (make-directory downstream 'create-parents)
  (setq downstream (file-name-as-directory downstream))

  (let ((make-backup-files nil)
        (version-control 'never))
    (unless sync-method
      (setq sync-method (elpa-clone--select-sync-method upstream)))
    (pcase sync-method
      (`rsync (elpa-clone--rsync upstream downstream))
      (`url (elpa-clone--remote upstream downstream signature readme))
      (`local (elpa-clone--local upstream downstream signature readme))
      (_ (error "Unknown sync method %s" sync-method)))))

(provide 'elpa-clone)

;;; elpa-clone.el ends here
