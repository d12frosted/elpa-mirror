A Swift backend for Flycheck with support for Xcode projects.

Features:

- Apple Swift 5

- Xcode projects
  Flycheck-swiftx can parse Xcode projects and use the build settings for the project.
  This means that complex projects, which may include various dependencies, can be
  typechecked automatically with swiftc.

- For non-Xcode projects provide your own configuration via `flycheck-swiftx-build-options` and `flycheck-swiftx-sources`.

- `xcrun` command support (only on macOS)

Installation:

In your `init.el`

(with-eval-after-load 'flycheck
  (require 'flycheck-swiftx))

or with `use-package`:

(use-package flycheck-swiftx
 :after flycheck)
