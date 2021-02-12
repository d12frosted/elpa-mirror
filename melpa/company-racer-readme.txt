> **NOTE**: [emacs-racer][] already offers completion support for through
> `completion-at-point-functions', so installing both packages could be
> unnecessary.

A company backend for [racer][].

Setup:

Install and configure [racer][].  And add to your `init.el':

    (require 'company-racer)

    (with-eval-after-load 'company
      (add-to-list 'company-backends 'company-racer))

Check https://github.com/company-mode/company-mode for details.

Troubleshooting:

+ [racer][] requires to set the environment variable with
  `RUST_SRC_PATH' and needs to be an absolute path:

      (unless (getenv "RUST_SRC_PATH")
        (setenv "RUST_SRC_PATH" (expand-file-name "~/path/to/rust/src")))

TODO:

+ [ ] Add support for find-definition (maybe not in this package.)

[racer]: https://github.com/phildawes/racer
[emacs-racer]: https://github.com/racer-rust/emacs-racer
[rust-lang]: http://www.rust-lang.org/
