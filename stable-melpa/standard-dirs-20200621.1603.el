;;; standard-dirs.el --- Platform-specific paths for config, cache, and other data  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Joseph M LaFreniere

;; Author: Joseph M LaFreniere <joseph@lafreniere.xyz>
;; Maintainer: Joseph M LaFreniere <joseph@lafreniere.xyz>
;; License: GPL3+
;; URL: https://github.com/lafrenierejm/standard-dirs.el
;; Package-Version: 20200621.1603
;; Package-Commit: e37b7e1c714c7798cd8e3a6569e4d71b96718a60
;; Version: 1.0.0
;; Keywords: files
;; Package-Requires: ((emacs "26.1") (f "0.20.0") (s "1.7.0"))

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; The purpose of this package is to provide platform-specific paths for reading
;; and writing configuration, cache, and other data.

;; On Linux (`gnu/linux'), the directory paths conform to the XDG base directory
;; and XDG user directory specifications as published by the freedesktop.org
;; project.

;; On macOS (`darwin'), the directory paths conform to Apple's documentation at
;; https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFileSystem/Articles/WhereToPutFiles.html.

;;; Code:
(require 'env)
(require 'f)
(require 'files)
(require 's)
(require 'subr-x)
(require 'xdg)

(defgroup standard-dirs nil
  "Directory paths that conform to platform-specific standards."
  :prefix "standard-dirs"
  :group 'files)

;;; User Directories
;; Retrieve paths of the standard user directories defined by the platform's
;; standards.

;;;###autoload
(defun standard-dirs-user ()
  "Get the current user's home directory."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (getenv "HOME"))
     ('darwin
      (getenv "HOME")))))

;;;###autoload
(defun standard-dirs-user-cache ()
  "Get the base directory for user-specific cache files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-cache-home))
     ('darwin
      (f-join (standard-dirs-user) "Library" "Caches")))))

;;;###autoload
(defun standard-dirs-user-config ()
  "Get the base directory for user-specific configuration files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-config-home))
     ('darwin
      (f-join (standard-dirs-user) "Library" "Preferences")))))

;;;###autoload
(defun standard-dirs-user-data ()
  "Get the base directory for user-specific data files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-data-home))
     ('darwin
      (f-join (standard-dirs-user) "Library")))))

;;;###autoload
(defun standard-dirs-user-data-local ()
  "Get the base directory for user-specific data files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-data-home))
     ('darwin
      (f-join (standard-dirs-user) "Library")))))

;;;###autoload
(defun standard-dirs-user-audio ()
  "Get the base directory for the current user's audio files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "MUSIC"))
     ('darwin
      (f-join (standard-dirs-user) "Music")))))

;;;###autoload
(defun standard-dirs-user-desktop ()
  "Get the base directory for the current user's desktop files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "DESKTOP"))
     ('darwin
      (f-join (standard-dirs-user) "DESKTOP")))))

;;;###autoload
(defun standard-dirs-user-document ()
  "Get the base directory for the current user's document files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "DOCUMENTS"))
     ('darwin
      (f-join (standard-dirs-user) "Documents")))))

;;;###autoload
(defun standard-dirs-user-downloads ()
  "Get the base directory for the current user's downloaded files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "DOWNLOAD"))
     ('darwin
      (f-join (standard-dirs-user) "Downloads")))))

;;;###autoload
(defun standard-dirs-user-font ()
  "Get the base directory for the current user's fonts."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (f-join (standard-dirs-user-data) "fonts"))
     ('darwin
      (f-join (standard-dirs-user) "Library" "Fonts")))))

;;;###autoload
(defun standard-dirs-user-picture ()
  "Get the base directory for the current user's picture files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "PICTURES"))
     ('darwin
      (f-join (standard-dirs-user) "Pictures")))))

;;;###autoload
(defun standard-dirs-user-public ()
  "Get the base directory for the current user's public files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "PUBLICSHARE"))
     ('darwin
      (f-join (standard-dirs-user) "Public")))))

;;;###autoload
(defun standard-dirs-user-runtime ()
  "Get the base directory for the current user's template files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-runtime-dir)))))

;;;###autoload
(defun standard-dirs-user-template ()
  "Get the base directory for the current user's template files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "TEMPLATES")))))

;;;###autoload
(defun standard-dirs-user-video ()
  "Get the base directory for the current user's video files."
  (file-name-as-directory
   (pcase system-type
     ('gnu/linux
      (xdg-user-dir "VIDEOS"))
     ('darwin
      (f-join (standard-dirs-user) "Movies")))))

;;; Project Directories
;; Create project-specific directories for the current user.

(defun standard-dirs--assemble-project-name (tld org app)
  "Assemble platform-dependent name from a TLD, ORG, and APP.

For example, an application \"Foo Bar-App\" published by an organization \"Baz
Corp\" whose website top-level domain (TLD) is .org would be passed as the
following arguments
- TLD: \"org\"
- ORG: \"Baz Corp\"
- APP: \"Foo Bar-App\"
and would result in the following values
- darwin: \"org.Baz-Corp.Foo-Bar-App\"
- gnu/linux: \"foobar-app\""
  (pcase system-type
    ('darwin
     (s-join "." (list tld
                       (s-replace " " "-" org)
                       (s-replace " " "-" app))))
    ('gnu/linux
     (s-downcase (s-replace " " "" app)))))

(defun standard-dirs--make-directory (dir)
  "Create and return the directory DIR."
  (make-directory dir t)
  (file-name-as-directory dir))

(defmacro standard-dirs--defun-project (dir-type)
  "Define a standard-dirs-project function for directory type DIR-TYPE."
  (let ((name (intern (concat "standard-dirs-project-" dir-type)))
        (user-func (intern (concat "standard-dirs-user-" dir-type))))
    `(defun ,name (tld org app)
       ,(format "Make and return the %s path for a project identified by TLD, ORG, and APP.

For example, the application \"Emacs\" published by the organization \"Free
Software Foundation\" whose website (gnu.org)'s top-level domain (TLD) is
\"org\" would be passed as the following arguments
- TLD: \"org\"
- ORG: \"Free Software Foundation\"
- APP: \"Emacs\""
                dir-type)
       (when-let ((project-name (standard-dirs--assemble-project-name
                                 tld org app))
                  (user-dir (,user-func)))
         (standard-dirs--make-directory
          (pcase system-type
            ('darwin
             (f-join user-dir project-name))
            ('gnu/linux
             (f-join user-dir project-name))))))))

;;;###autoload (autoload 'standard-dirs-project-cache "standard-dirs.el")
(standard-dirs--defun-project "cache")

;;;###autoload (autoload 'standard-dirs-project-config "standard-dirs.el")
(standard-dirs--defun-project "config")

;;;###autoload (autoload 'standard-dirs-project-data "standard-dirs.el")
(standard-dirs--defun-project "data")

;;;###autoload (autoload 'standard-dirs-project-data-local "standard-dirs.el")
(standard-dirs--defun-project "data-local")

;;;###autoload (autoload 'standard-dirs-project-runtime "standard-dirs.el")
(standard-dirs--defun-project "runtime")

(provide 'standard-dirs)
;;; standard-dirs.el ends here
