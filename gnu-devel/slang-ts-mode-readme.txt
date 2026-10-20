1 slang-ts-mode
═══════════════

  This package provides slang-ts-mode, a major mode for editing [Slang]
  code powered by tree-sitter.


[Slang] <https://shader-slang.org>

1.1 Screenshot
──────────────

  <./assets/light.png>


1.2 Installation
────────────────

  The package is not on any repository yet. If you use Emacs 30+ then
  you can use package.el.

  ┌────
  │ (use-package slang-ts-mode
  │   :vc (:url "https://codeberg.org/hikari/slang-ts-mode")
  │   :mode "\\.slang\\'")
  └────

  Else, if you use straight.el or Elpaca,

  ┌────
  │ ;; For straight.el
  │ (use-package slang-ts-mode
  │   :straight (:host codeberg :repo "hikari/slang-ts-mode" :branch "main")
  │   :mode "\\.slang\\'")
  │ 
  │ ;; For Elpaca replace straight with ensure
  └────


1.3 Customization
─────────────────

  You can set the `slang-ts-indent-offset` variable (default 4) to
  change the indentation.


1.4 Changelog
─────────────

1.4.1 0.1
╌╌╌╌╌╌╌╌╌

  Initial release.


1.5 License
───────────

  GPLv2
