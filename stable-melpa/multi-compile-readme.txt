"Multi-compile" is multi target interface to "compile" command.

Setup
----
M-x package-install multi-compile

Configure
----

Sample config for Rustlang:
 ;;; init.el --- user init file
    (require 'multi-compile)
    (setq multi-compile-alist '(
        (rust-mode . (("rust-debug" . "cargo run")
                      ("rust-release" . "cargo run --release")
                      ("rust-test" . "cargo test")))
        ))

In a compilation commands, you can use the templates:
- "%path" - "/tmp/prj/file.rs"
- "%dir" - "/tmp/prj/"
- "%file-name" - "file.rs"
- "%file-sans" - "file"
- "%file-ext" - "rs"
- "%make-dir" - (Look up the directory hierarchy from current file for a directory containing "Makefile") - "/tmp/"

for example, add a make compilation (with a template "make-dir"):
(setq multi-compile-alist '(
    (c++-mode . (("cpp-run" . "make --no-print-directory -C %make-dir")))
    (rust-mode . (("rust-debug" . "cargo run")
                  ("rust-release" . "cargo run --release")
                  ("rust-test" . "cargo test")))
    ))

You can use filename pattern:
(setq multi-compile-alist '(
    ("\\.txt\\'" . (("text-filename" . "echo %file-name")))))

Or add a pattern for all files:
(setq multi-compile-alist '(
    ("\\.*" . (("any-file-command" . "echo %file-name")))))

You can use different backends for the menu:
(setq multi-compile-completion-system 'ido)
or
(setq multi-compile-completion-system 'helm)
or
(setq multi-compile-completion-system 'ivy)
or
(setq multi-compile-completion-system 'default)

Usage
----
- Open *.rs file
- M-x multi-compile-run

For a detailed introduction see:
https://github.com/ReanGD/emacs-multi-compile/blob/master/README.md
