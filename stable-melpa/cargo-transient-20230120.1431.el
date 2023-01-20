;;; cargo-transient.el --- A transient UI for Cargo, Rust's package manager -*- lexical-binding: t -*-

;; Copyright (C) 2022 Peter Stuart

;; Author: Peter Stuart <peter@peterstuart.org>
;; Maintainer: Peter Stuart <peter@peterstuart.org>
;; Created: 6 Jun 2022
;; URL: https://github.com/peterstuart/cargo-transient
;; Package-Version: 20230120.1431
;; Package-Commit: f0295aee41404ffb2e8532948becf78d405e4ee9
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides a transient for Rust's cargo.

;; Usage:
;; M-x cargo-transient

;; Supported cargo commands:
;; - build
;; - check
;; - clean
;; - clippy
;; - doc
;; - fmt
;; - run
;; - test

;; Not all commands and arguments are supported. If cargo-transient is
;; missing support for something you need, please open a pull request
;; or file an issue at
;; <https://github.com/peterstuart/cargo-transient/>.

;; By default, all commands will share the same compilation buffer,
;; but that can be changed by customizing
;; `cargo-transient-compilation-buffer-name-function'.

;; See the info node `(transient)Top' for information on using
;; transients.

;;; Code:

(require 'project)
(require 'transient)

;; Customize

(defgroup cargo-transient nil
  "A transient for cargo."
  :group 'tools
  :prefix "cargo-transient-")

(defcustom cargo-transient-compilation-buffer-name-function nil
  "Function to compute the name of a cargo compilation buffer.
It is equivalent to `project-compilation-buffer-name-function'."
  :group 'cargo-transient
  :type '(choice (const :tag "Default" nil)
                 (const :tag "Prefixed with root directory name"
                        cargo-transient-project-prefixed-buffer-name)
                 (function :tag "Custom function")))

(defun cargo-transient-project-prefixed-buffer-name (mode)
  (let* ((project           (project-current))
         (default-directory (if project (project-root project) default-directory)))
    (project-prefixed-buffer-name mode)))

;; Group Names

(eval-when-compile
  (defconst cargo-transient--group-target-selection
    "Target Selection")
  (defconst cargo-transient--group-feature-selection
    "Feature Selection")
  (defconst cargo-transient--group-compilation-options
    "Compilation Options")
  (defconst cargo-transient--group-manifest-options
    "Manifest Options")
  (defconst cargo-transient--group-arguments
    "Arguments")
  (defconst cargo-transient--group-actions
    "Actions"))

;; Transients

;;;###autoload (autoload 'cargo-transient "cargo-transient" nil t)
(transient-define-prefix cargo-transient ()
  "Interact with `cargo' in a transient."
  ["Commands"
   ("b" "Build" cargo-transient--prefix-build)
   ("c" "Check" cargo-transient--prefix-check)
   ("d" "Doc" cargo-transient--prefix-doc)
   ("f" "Format" cargo-transient-fmt)
   ("k" "Clean" cargo-transient--prefix-clean)
   ("l" "Clippy" cargo-transient--prefix-clippy)
   ("r" "Run" cargo-transient--prefix-run)
   ("t" "Test" cargo-transient--prefix-test)])

(transient-define-prefix cargo-transient--prefix-build ()
  "Run `cargo build'."
  :man-page "cargo-build"
  [cargo-transient--group-target-selection
   (cargo-transient--arg-bin)
   (cargo-transient--arg-bins)
   (cargo-transient--arg-example)
   (cargo-transient--arg-examples)
   (cargo-transient--arg-lib)
   (cargo-transient--arg-test)
   (cargo-transient--arg-tests)]
  [cargo-transient--group-feature-selection
   (cargo-transient--arg-features)
   (cargo-transient--arg-all-features)
   (cargo-transient--arg-no-default-features)]
  [cargo-transient--group-compilation-options
   (cargo-transient--arg-release)]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-actions
   ("b" "Build" cargo-transient-build)])

(defun cargo-transient-build (&rest args)
  "Run `cargo build' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "build" args))

(transient-define-prefix cargo-transient--prefix-check ()
  "Run `cargo check'."
  :man-page "cargo-check"
  [cargo-transient--group-target-selection
   (cargo-transient--arg-bin)
   (cargo-transient--arg-bins)
   (cargo-transient--arg-example)
   (cargo-transient--arg-examples)
   (cargo-transient--arg-lib)
   (cargo-transient--arg-test)
   (cargo-transient--arg-tests)]
  [cargo-transient--group-feature-selection
   (cargo-transient--arg-features)
   (cargo-transient--arg-all-features)
   (cargo-transient--arg-no-default-features)]
  [cargo-transient--group-compilation-options
   (cargo-transient--arg-release)]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-actions
   ("c" "Check" cargo-transient-check)])

(defun cargo-transient-check (&rest args)
  "Run `cargo check' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "check" args))

(transient-define-prefix cargo-transient--prefix-clean ()
  "Run `cargo clean'."
  :man-page "cargo-clean"
  ["Clean Options"
   (cargo-transient--arg-doc
    :description "Just the documentation directory"
    :key "-d")
   (cargo-transient--arg-release
    :description "Release artifacts"
    :key "-r")]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-actions
   ("k" "Clean" cargo-transient-clean)])

(defun cargo-transient-clean (&rest args)
  "Run `cargo clean' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "clean" args))

(transient-define-prefix cargo-transient--prefix-clippy ()
  "Run `cargo clippy'."
  ["Clippy Options"
   ("-n"
    "Run Clippy only on the given crate, without linting the dependencies"
    "--no-deps")]
  [cargo-transient--group-feature-selection
   (cargo-transient--arg-features)
   (cargo-transient--arg-all-features)
   (cargo-transient--arg-no-default-features)]
  [cargo-transient--group-target-selection
   (cargo-transient--arg-bin)
   (cargo-transient--arg-bins)
   (cargo-transient--arg-example)
   (cargo-transient--arg-examples)
   (cargo-transient--arg-lib)
   (cargo-transient--arg-test)
   (cargo-transient--arg-tests)]
  [cargo-transient--group-compilation-options
   (cargo-transient--arg-release)]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-actions
   ("l" "Clippy" cargo-transient-clippy)
   ("f" "Fix" cargo-transient-clippy-fix)
   ("F" "Fix all" cargo-transient-clippy-fix-all)])

(defun cargo-transient-clippy (&rest args)
  "Run `cargo clippy' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "clippy" args))

(defun cargo-transient-clippy-fix (&rest args)
  "Automatically apply lint suggestions."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "clippy --fix" args))

(defun cargo-transient-clippy-fix-all (&rest args)
  "Automatically apply lint suggestions, regardless of dirty or staged status."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "clippy --fix --allow-dirty --allow-staged" args))

(transient-define-prefix cargo-transient--prefix-doc ()
  "Run `cargo doc'."
  :man-page "cargo-doc"
  ["Documentation Options"
   ("-o"
    "Open the docs in a browser after builder them"
    "--open")
   ("-n"
    "Do not build documentation for dependencies"
    "--no-deps")
   ("-p"
    "Include non-public items in the documentation"
    "--document-private-items")]
  [cargo-transient--group-target-selection
   (cargo-transient--arg-bin)
   (cargo-transient--arg-bins)
   (cargo-transient--arg-example)
   (cargo-transient--arg-examples)
   (cargo-transient--arg-lib)]
  [cargo-transient--group-feature-selection
   (cargo-transient--arg-features)
   (cargo-transient--arg-all-features)
   (cargo-transient--arg-no-default-features)]
  [cargo-transient--group-compilation-options
   (cargo-transient--arg-release)]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-actions
   ("d" "Doc" cargo-transient-doc)])

(defun cargo-transient-doc (&rest args)
  "Run `cargo doc' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "doc" args))

(defun cargo-transient-fmt ()
  "Run `cargo fmt'."
  (interactive)
  (cargo-transient--exec "fmt"))

(transient-define-prefix cargo-transient--prefix-run ()
  "Run `cargo run`."
  :man-page "cargo-run"
  [cargo-transient--group-target-selection
   (cargo-transient--arg-bin)
   (cargo-transient--arg-example)]
  [cargo-transient--group-feature-selection
   (cargo-transient--arg-features)
   (cargo-transient--arg-all-features)
   (cargo-transient--arg-no-default-features)]
  [cargo-transient--group-compilation-options
   (cargo-transient--arg-release)]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-arguments
   (cargo-transient--arg-arguments
    :description "Arguments to the binary")]
  [cargo-transient--group-actions
   ("r" "Run" cargo-transient-run)])

(defun cargo-transient-run (&rest args)
  "Run `cargo run' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "run" args))

(transient-define-prefix cargo-transient--prefix-test ()
  "Run `cargo test'."
  :man-page "cargo-test"
  ["Test Options"
   (cargo-transient--arg-test-test-name)
   ("-x"
    "Don't capture stdout/stderr of each task"
    "--nocapture")
   ("-c"
    "Compile, but don't run tests"
    "--no-run")
   ("-a"
    "Run all tests regardless of failure."
    "--no-fail-fast")]
  [cargo-transient--group-target-selection
   (cargo-transient--arg-bin)
   (cargo-transient--arg-bins)
   (cargo-transient--arg-doc)
   (cargo-transient--arg-example)
   (cargo-transient--arg-examples)
   (cargo-transient--arg-lib)
   (cargo-transient--arg-test)
   (cargo-transient--arg-tests)]
  [cargo-transient--group-feature-selection
   (cargo-transient--arg-features)
   (cargo-transient--arg-all-features)
   (cargo-transient--arg-no-default-features)]
  [cargo-transient--group-compilation-options
   (cargo-transient--arg-release)]
  [cargo-transient--group-manifest-options
   (cargo-transient--arg-offline)]
  [cargo-transient--group-actions
   ("t" "Test" cargo-transient-test)])

(defun cargo-transient-test (&rest args)
  "Run `cargo test' with the provided ARGS."
  (interactive (cargo-transient--args))
  (cargo-transient--exec "test" args))

(transient-define-argument cargo-transient--arg-test-test-name ()
  :description "Only run tests containing this string in their names"
  :class 'transient-option
  :key "-n"
  :argument "")

;; Target Selection

(transient-define-argument cargo-transient--arg-bin ()
  :description "Only the specified binary"
  :class 'transient-option
  :key "-b"
  :argument "--bin=")

(transient-define-argument cargo-transient--arg-bins ()
  :description "All binary targets"
  :key "-B"
  :argument "--bins")

(transient-define-argument cargo-transient--arg-doc ()
  :description "Only this library's documentation"
  :key "-d"
  :argument "--doc")

(transient-define-argument cargo-transient--arg-example ()
  :description "Only the specified example"
  :class 'transient-option
  :multi-value 'repeat
  :key "-e"
  :argument "--example=")

(transient-define-argument cargo-transient--arg-examples ()
  :description "All examples"
  :key "-E"
  :argument "--examples")

(transient-define-argument cargo-transient--arg-lib ()
  :description "Only this package's library"
  :key "-l"
  :argument "--lib")

(transient-define-argument cargo-transient--arg-test ()
  :description "Only the specified test target"
  :class 'transient-option
  :multi-value 'repeat
  :key "-t"
  :argument "--test=")

(transient-define-argument cargo-transient--arg-tests ()
  :description "All tests"
  :key "-T"
  :argument "--tests")

;; Feature Selection

(transient-define-argument cargo-transient--arg-features ()
  :description "Features"
  :class 'transient-option
  :multi-value 'repeat
  :key "-f"
  :argument "--features=")

(transient-define-argument cargo-transient--arg-all-features ()
  :description "All available features"
  :key "-F"
  :argument "--all-features")

(transient-define-argument cargo-transient--arg-no-default-features ()
  :description "Do not activate the default features"
  :key "-g"
  :argument "--no-default-features")

;; Compilation Options

(transient-define-argument cargo-transient--arg-release ()
  :description "Release mode, with optimizations"
  :shortarg "-r"
  :argument "--release")

;; Manifest Options

(transient-define-argument cargo-transient--arg-offline ()
  :description "Without accessing the network"
  :key "-u"
  :argument "--offline")

;; Arguments

(transient-define-argument cargo-transient--arg-arguments ()
  :description "Arguments"
  :class 'transient-option
  :key "--"
  :argument "--"
  :prompt "Arguments: "
  :reader 'completing-read-multiple
  :multi-value 'rest)

;; Private Functions

(defconst cargo-transient--post-args
  '("--nocapture")
  "Arguments which must be placed after a trailing `--' in the
arguments passed to `cargo'.")

(defun cargo-transient--is-post-arg (arg)
  "Return whether an argument must be placed after a trailing `--'
 in the arguments passed to `cargo'."
  (member arg cargo-transient--post-args))

(defun cargo-transient--rearrange-args (args)
  "Return arguments, rearranged if necessary, to handle arguments
which must occur after a trailing `--' in the arguments passed to
`cargo'.

If rearranging is necessary, `--' will be added to the list of
arguments."
  (let* ((pre-args  (cl-remove-if #'cargo-transient--is-post-arg args))
         (post-args (cl-remove-if-not #'cargo-transient--is-post-arg args)))
    (if (= (length post-args) 0)
        pre-args
      (append pre-args '("--") post-args))))

(defun cargo-transient--args ()
  "Return a list of arguments from the current transient command."
  (let ((args (flatten-list (transient-args transient-current-command))))
    (cargo-transient--rearrange-args args)))

(defun cargo-transient--exec (command &optional args)
  "Run `cargo COMMAND ARGS'."
  (let* ((cargo-args        (if args (mapconcat #'identity args " ") ""))
         (command           (format "cargo %s %s" command cargo-args))
         (compilation-buffer-name-function (or cargo-transient-compilation-buffer-name-function
                                               compilation-buffer-name-function))
         (default-directory (or (locate-dominating-file default-directory "Cargo.toml")
                                default-directory)))
    (compile command)))

(provide 'cargo-transient)

;;; cargo-transient.el ends here
