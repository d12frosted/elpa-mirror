;;; project-rootfile.el --- Project backend by root file  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Taiki Sugawara

;; Author: Taiki Sugawara <buzz.taiki@gmail.com>
;; URL: https://github.com/buzztaiki/project-rootfile.el
;; Package-Version: 20220505.1256
;; Package-Commit: a4c4f004fbf8ca44e74be845a1c3696d6db5b0d6
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1"))

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

;; A project backend that uses a root file (e.g. Gemfile) for detection.

;; Usage:
;; If you prefer VCS root over root file for project detection, add the following to your init file:
;;
;;      (add-to-list 'project-find-functions #'project-rootfile-try-detect t)
;;
;; Otherwise, if you prefer a root file, add the following:
;;
;;      (add-to-list 'project-find-functions #'project-rootfile-try-detect)

;;; Code:

(require 'project)
(require 'cl-lib)

(defgroup project-rootfile nil
  "Project backend by root file."
  :group 'project)

(defcustom project-rootfile-list
  '("TAGS" "GTAGS"                                          ; tags
    "configure.ac" "configure.in"                           ; autoconf
    "cscope.out"                                            ; cscope
    "SConstruct"                                            ; scons
    "meson.build"                                           ; meson
    "default.nix" "flake.nix"                               ; nix
    "WORKSPACE"                                             ; bazel
    "debian/control"                                        ; debian
    "Makefile" "GNUMakefile" "CMakeLists.txt"               ; Make & CMake
    "composer.json"                                         ; PHP
    "rebar.config" "mix.exs"                                ; Erlang & Elixir
    "Gruntfile.js" "gulpfile.js" "package.json" "angular.json"
                                                            ; JavaScript
    "manage.py" "requirements.txt" "setup.py" "tox.ini" "Pipfile" "poetry.lock"
                                                            ; Python
    "pom.xml" "build.gradle" "gradlew" "application.yml"    ; Java & friends
    "build.sbt" "build.sc"                                  ; Scala
    "project.clj" "build.boot" "deps.edn" ".bloop"          ; Clojure
    "Gemfile"                                               ; Ruby
    "shard.yml"                                             ; Crystal
    "Cask" "Eldev" "Keg" "Eask"                             ; Emacs
    "DESCRIPTION"                                           ; R
    "stack.yaml"                                            ; Haskell
    "Cargo.toml"                                            ; Rust
    "info.rkt"                                              ; Racket
    "pubspec.yaml"                                          ; Dart
    "dune-project"                                          ; OCaml
    "go.mod"                                                ; Go
    )
  "A list of files considered to mark the root of a project."
  :group 'project-rootfile
  :type '(repeat :type string))

(cl-defstruct project-rootfile
  "Project backend by root file."
  root base)

;;;###autoload
(defun project-rootfile-try-detect (dir)
  "Entry point of `project-find-functions' for `project-rootfile'.
Return an instance of `project-rootfile' if DIR is it's target."
  (when-let (root (locate-dominating-file dir #'project-rootfile--root-p))
    (make-project-rootfile :root root :base (project-try-vc dir))))

(defun project-rootfile--root-p (dir)
  "Return non-nil if DIR is a project root."
  (seq-some (lambda (f) (file-exists-p (expand-file-name f dir)))
            project-rootfile-list))

(cl-defmethod project-root ((project project-rootfile))
  "Return root directory of the current PROJECT."
  (project-rootfile-root project))

(when (< emacs-major-version 28)
  (cl-defmethod project-roots ((project project-rootfile))
    "Return the list containing the current PROJECT root."
    (list (project-rootfile-root project))))

(cl-defmethod project-external-roots ((_project project-rootfile))
  "Return the list of external roots for PROJECT."
  (cl-call-next-method))

(cl-defmethod project-ignores ((project project-rootfile) dir)
  "Return the list of glob patterns to ignore inside DIR for PROJECT."
  (let ((base (project-rootfile-base project)))
    (if (null base)
        (cl-call-next-method)
      (project-ignores base dir))))

(cl-defmethod project-files ((project project-rootfile) &optional dirs)
  "Return a list of files in directories DIRS in PROJECT."
  (let ((base (project-rootfile-base project)))
    (if (null base)
        (cl-call-next-method)
      (project-files base (or dirs (list (project-rootfile-root project)))))))

(provide 'project-rootfile)
;;; project-rootfile.el ends here

;; Local Variables:
;; comment-column: 60
;; fill-column: 80
;; End:
