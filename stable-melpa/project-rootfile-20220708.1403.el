;;; project-rootfile.el --- Extension of project.el to detect project with root file  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Taiki Sugawara

;; Author: Taiki Sugawara <buzz.taiki@gmail.com>
;; URL: https://github.com/buzztaiki/project-rootfile.el
;; Package-Version: 20220708.1403
;; Package-Commit: 9259708307c9da6b06f04f5b34ccd28f1fba5eaa
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

;; Extension of `project' to detect project root with root file (e.g. Gemfile).
;;
;; It is useful when editing files outside of VCS.  And it may also be useful if
;; you are using monorepo.  It is very smiller to Projectile's
;; 'projectile-root-top-down', but it relies on the Emacs standard `project'.

;; Usage:
;;
;; As is the default for Projectile, you prefer a VCS root over a root file
;; for project detection, add the following to your init file:
;;
;;      (add-to-list 'project-find-functions #'project-rootfile-try-detect t)
;;
;; Otherwise, if you prefer a root file, add the following:
;;
;;      (add-to-list 'project-find-functions #'project-rootfile-try-detect)
;;
;; For more information, please see <https://github.com/buzztaiki/project-rootfile.el>.

;;; Credit:

;; `project-rootfile-list' is heavily taken from Projectile's `projectile-project-root-files'. Thanks!


;;; Code:

(require 'project)
(require 'cl-lib)

(defgroup project-rootfile nil
  "Extension of `project' to detect project root with root file (e.g. Gemfile)."
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
    "bower.json" "psc-package.json" "spago.dhall"           ; PureScript
    "stack.yaml"                                            ; Haskell
    "Cargo.toml"                                            ; Rust
    "info.rkt"                                              ; Racket
    "pubspec.yaml"                                          ; Dart
    "dune-project"                                          ; OCaml
    "go.mod"                                                ; Go
    )
  "A list of files considered to mark the root of a project."
  :type '(repeat :type string))

(cl-defstruct (project-rootfile-plain (:conc-name project-rootfile-plain--))
  "Project backend for plain (outside VCS) project."
  (root nil :documentation "Root directory of this project."))

(defcustom project-rootfile-plain-ignores nil
  "List of patterns to add to `project-ignores' for `project-rootfile-plain'."
  :type '(repeat string))

;;;###autoload
(defun project-rootfile-try-detect (dir)
  "Entry point of `project-find-functions' for `project-rootfile'.
Search a root file upwards from DIR and return project instance if found."
  (let* ((vc-project (project-try-vc dir))
         (stop-dir (and vc-project (project-rootfile--project-root vc-project))))
    (when-let (root (locate-dominating-file dir (lambda (d) (project-rootfile--root-p d stop-dir))))
      (pcase vc-project
        ((pred null) (make-project-rootfile-plain :root root))
        (`(vc ,backend ,_vc-root) (list 'vc backend root))
        (`(vc . ,_vc-root) (cons 'vc root))
        (_ (error "Unknown VC project pattern %s" vc-project))))))

(defun project-rootfile--root-p (dir &optional stop-dir)
  "Return non-nil if DIR is a project root.
If STOP-DIR is specified, return nil if DIR is not a subdirectory of it."
  (and (or (null stop-dir)
           (file-in-directory-p dir stop-dir))
       (seq-some (lambda (f) (file-exists-p (expand-file-name f dir)))
                 project-rootfile-list)))

(defun project-rootfile--project-root (project)
  "Return root directory of the PROJECT."
  (with-suppressed-warnings ((obsolete project-roots))
    (car (project-roots project))))

(when (cl-generic-p 'project-root)
  (cl-defmethod project-root ((project project-rootfile-plain))
    "Return root directory of the current PROJECT."
    (project-rootfile-plain--root project)))

(with-suppressed-warnings ((obsolete project-roots))
  (cl-defmethod project-roots ((project project-rootfile-plain))
    "Return the list containing the current PROJECT root."
    (list (project-rootfile-plain--root project))))

(cl-defmethod project-ignores ((_project project-rootfile-plain) _dir)
  "Return the list of glob patterns to ignore."
  (append
   (cl-call-next-method)
   project-rootfile-plain-ignores))

(provide 'project-rootfile)
;;; project-rootfile.el ends here

;; Local Variables:
;; comment-column: 60
;; fill-column: 80
;; End:
