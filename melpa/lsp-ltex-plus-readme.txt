
`lsp-ltex-plus' is an `lsp-mode' client for LTeX+, a LanguageTool-based
grammar, spell, and style checker.  It brings professional-grade writing
feedback into Emacs for:

  * Markup and writing languages — LaTeX, Markdown, Org, RestructuredText,
    HTML, BibTeX, AsciiDoc, Typst, Quarto, Magit commit messages, plain
    text, and many others (checked by default).
  * Comments and string literals in 30+ programming languages — Python,
    C/C++, Rust, Java, JavaScript/TypeScript, Go, Ruby, … (opt-in via
    `lsp-ltex-plus-check-programming-languages').

Highlights:

  * Add-on integration — registers with `:add-on? t' and `:priority -1',
    so it runs concurrently with primary LSP servers (texlab, pyright,
    etc.) without competing for features such as Go-to-Definition or
    Completion.
  * Offline by default — the local `ltex-ls-plus' binary checks documents
    entirely on your machine, no network involved.  An optional remote
    LanguageTool server (with optional LanguageTool Premium credentials)
    is supported for users who want it.
  * Multilingual — every external setting is keyed by language code
    (`:en-US', `:de-DE', `:fr', …), so dictionaries, disabled rules,
    enabled rules, and hidden false-positives are tracked per language.
  * Persistent state — words you "add to dictionary", rules you disable,
    and false positives you hide are saved as plist files under
    `user-emacs-directory' and survive Emacs restarts.  User-level
    `:custom' entries seed the defaults and remain pristine (never
    mutated by the package at runtime).
  * Lazy loading — split into a tiny bootstrap file loaded at Emacs
    startup and a full client loaded only on first use, so installing
    the package costs essentially no startup time.
  * Simple setup — one call to `lsp-ltex-plus-enable-for-modes' from
    the `:init' block of `use-package' activates the client across
    every supported major mode.  Narrow the set with the `:restrict-to'
    or `:exclude' keywords, or add your own modes with `:extend-to',
    without editing `lsp-ltex-plus-major-modes'.  All settings are
    defcustoms under the `lsp-ltex-plus-' prefix, configurable via
    `:custom' or `M-x customize-group RET lsp-ltex-plus RET'.

Minimal setup with `use-package':

  (use-package lsp-ltex-plus
    :init (lsp-ltex-plus-enable-for-modes))

See the README at URL `https://github.com/ltex-plus/emacs-ltex-plus' for
full configuration, multi-language setup, performance tuning, and a
comparison with the older `lsp-ltex' package.

External dependencies:

  - `ltex-ls-plus' binary on `exec-path'.
  - Java runtime — platform-specific `ltex-ls-plus' releases include a
    bundled JRE; otherwise Java 21 or later must be installed.
  - Optional: LanguageTool.org account for premium rules.
