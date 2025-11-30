[![GNU ELPA badge][gnu-elpa-badge]][gnu-elpa-link]
[![MELPA badge][melpa-badge]][melpa-link]

[gnu-elpa-link]: https://elpa.gnu.org/packages/termint.html
[gnu-elpa-badge]: https://elpa.gnu.org/packages/termint.svg
[melpa-link]: https://melpa.org/#/termint
[melpa-badge]: https://melpa.org/packages/termint-badge.svg

**Run REPLs in a terminal emulator backend**

`termint.el` provides a flexible way to define and manage interactions with
Read-Eval-Print Loops (REPLs) running inside a terminal emulator backend within
Emacs. It allows you to easily configure how Emacs communicates with different
REPLs, leveraging the capabilities of fully-featured terminal emulators like
`term`, `vterm`, or `eat`.

Instead of relying on Emacs's built-in "dumb" terminal (`comint-mode`),
`termint` runs REPLs in a full terminal emulator, enabling features like
bracketed paste mode, proper rendering, and potentially advanced interaction for
complex terminal applications.

The core of the package is the `termint-define` macro, which generates a set of
functions and keybindings tailored to a specific REPL, making it easy to start
sessions, send code snippets, source files, and manage the REPL window.

# Features

- Flexible REPL Definition: Define interactions for various REPLs using the
  `termint-define` macro.
- Multiple Backends: Supports `term`, `vterm`, and `eat` as terminal emulator
  backends. Configure your preferred backend using `termint-backend`.
- Customizable Interaction: Control aspects like bracketed paste mode, start/end
  patterns for sending code (with different behaviour for single vs. multi-line
  input), and code preprocessing.
- Code Sourcing: Provides a mechanism (`:source-syntax`) to source code, often
  by writing to a temporary file and sending a command to source it (helpers
  included for common languages).
- Generated Commands: Automatically creates functions for:
  - Starting/switching to REPL sessions
  - Sending regions/strings
  - Sourcing regions
  - Hiding the REPL window
- Evil Integration: Automatically defines Evil operators if Evil mode is
  detected.
- Dedicated Keymap: Creates a prefix keymap for easy access to the generated
  commands.

# Installation

`termint` is available on the ELPA and MELPA package repository. You can install
it using your preferred package manager.

```emacs-lisp
(package-install 'termint)

;; Alternatively, using straight.el
(straight-use-package 'termint)
```

# Configuration

Choose your preferred terminal backend by customizing the `termint-backend`
variable:

```emacs-lisp
;; Choose one: 'term, 'vterm, or 'eat
(setq termint-backend 'eat)
```

Make sure the corresponding backend package (`vterm` or `eat`) is installed if
you choose it. `term` is built-in.

We recommend using `eat` or `vterm` due to their superior performance compared
to the built-in `term`.

## Usage

The primary way to use `termint` is by defining REPL configurations in your
Emacs init file using the `termint-define` macro.

This approach takes inspiration from the `reformatter` package, which similarly
provides a macro to define distinct formatters. Each formatter is accompanied by
its own command, allowing you to apply different configurations across various
languages.

This macro defines a schema for interacting with a specific REPL.

```emacs-lisp
(termint-define REPL-NAME REPL-CMD &rest ARGS)
```

## Generated Components

For a `(termint-define "myrepl" ...)` definition, the macro generates several
components prefixed with `termint-myrepl-`:

**Functions:** A set of interactive functions are created for common REPL
interactions:

- `termint-myrepl-start`: Start or switch to the REPL session.
- `termint-myrepl-send-string`: Send a string (prompted) to the REPL.
- `termint-myrepl-hide-window`: Hide the REPL window.

_Region Operations:_

- `termint-myrepl-send-region`: Send the selected region to the REPL.
- `termint-myrepl-source-region`: Source the selected region in the REPL.

_Paragraph Operations:_

- `termint-myrepl-send-paragraph`: Send the current paragraph to the REPL.
- `termint-myrepl-source-paragraph`: Source the current paragraph in the REPL.

_Buffer Operations:_

- `termint-myrepl-send-buffer`: Send the current buffer to the REPL.
- `termint-myrepl-source-buffer`: Source the current buffer in the REPL.

_Defun Operations:_

- `termint-myrepl-send-defun`: Send the current defun to the REPL.
- `termint-myrepl-source-defun`: Source the current defun in the REPL.

**Evil Operators:** If Evil mode is loaded, the following operators are defined,
mirroring the region operations:

- `termint-myrepl-send-region-operator`: Evil operator for sending text objects,
  motions, or regions.
- `termint-myrepl-source-region-operator`: Evil operator for sourcing text
  objects, motions, or regions.

**Keymap:**

- `termint-myrepl-map`: A keymap containing default bindings for the generated
  functions. You can bind this map to a prefix key for convenient access.

**Customizable Variables:** Several variables are generated to allow
customization of the REPL's behavior:

- `termint-myrepl-cmd`: The command used to start the REPL.
- `termint-myrepl-use-bracketed-paste-mode`: Whether to use bracketed paste
  mode.
- `termint-myrepl-start-pattern`: Pattern marking the start of code to send
  (optional).
- `termint-myrepl-end-pattern`: Pattern marking the end of code to send
  (optional).
- `termint-myrepl-str-process-func`: Function to preprocess strings before
  sending.
- `termint-myrepl-source-syntax`: Template for the command used to source code.
- `termint-myrepl-show-source-command-hint`: When enabled, display the first
  non-empty line of the code chunk as overlay. Alongside the source command sent
  to the REPL, providing a useful hint about the actual command being executed.
  the default value is nil.
- `termint-myrepl-send-delayed-final-ret`: When enabled, send the final return
  with a slight delay. Some REPLs may not properly recognize when a large chunk
  of text sent with bracketed paste mode has finished being input and needs to
  be evaluated. This option should generally remain false (the default), with
  Claude Code and OpenAI Codex being notable exceptions that require to set to
  true. PRs are welcome if other REPLs are found to need this option enabled.

**Global Customization Options:** Configure these before calling
`termint-define` to ensure all schemas inherit the same extensions to avoid
per-REPL repetition:

- `termint-region-dispatchers`: Register additional region selectors to
  automatically generate corresponding send/source commands across all schemas.
- `termint-schema-custom-commands`: Define universal custom commands that apply
  to every schema.
- `termint-mode-map-additional-keys`: Specify keybindings (key + command suffix)
  to include in all generated schema keymaps, keeping common shortcuts
  synchronized.

## Examples

As `termint-define` is a macro, it cannot automatically generate autoloads for
the derived commands. To address this, we recommend configuring `termint` using
`use-package`, which provides advanced lazy-loading functionality out of the
box.

We also recommend declare **separate** `use-package` forms for each REPL schema.
This structure allows you to activate specific REPL commands as long as their
corresponding programming language mode loads.

In the below example, we created two REPL schemas:

1. `ipython` - loads with Python mode
2. `claude-code` - lazy-loaded with global keybindings

```emacs-lisp
(use-package termint
  :demand t
  :after python
  :bind
  (:map python-ts-mode-map
   ("C-c s" . termint-ipython-start))

  :config

  (termint-define "ipython" "ipython" :bracketed-paste-p t
                  :source-syntax termint-ipython-source-syntax-template)

  ;; C-c m s: `termint-ipython-start'
  ;; C-c m e: `termint-ipython-send-string'
  ;; C-c m r: `termint-ipython-send-region' (or `termint-ipython-send-region-operator' if evil is installed.)
  ;; C-c m p: `termint-ipython-send-paragraph'
  ;; C-c m b: `termint-ipython-send-buffer'
  ;; C-c m f: `termint-ipython-send-defun'
  ;; C-c m R: `termint-ipython-source-region' (or `termint-ipython-source-region-operator' if evil is installed.)
  ;; C-c m P: `termint-ipython-source-paragraph'
  ;; C-c m B: `termint-ipython-source-buffer'
  ;; C-c m F: `termint-ipython-source-defun'
  ;; C-c m h: `termint-ipython-hide-window'
  (define-key python-ts-mode-map (kbd "C-c m") termint-ipython-map)

  ;; for evil user
  (evil-define-key '(normal visual)
    python-ts-mode-map (kbd "SPC r") #'termint-ipython-send-region-operator)
  (evil-define-key '(normal visual)
    python-ts-mode-map (kbd "SPC R") #'termint-ipython-source-region-operator))

(use-package termint
  :bind (("C-c C" . termint-claude-code-start))
  :bind-keymap ("C-c c" . termint-claude-code-map)

  :config
  (setq termint-backend 'eat)
  (termint-define "claude-code" "claude" :bracketed-paste-p t
                  ;; In most cases, there is no need to configure
                  ;; :send-delayed-final-ret; the default value suffices.
                  ;; However, for claude-code, it should be explicitly set to t.
                  :send-delayed-final-ret t
                  :source-syntax "@{{file}}"))

;; Codex is also required to enable :send-delayed-final-ret
(termint-define "codex" "codex" :bracketed-paste-p t
                :source-syntax "Read the instruction from {{file}}"
                :end-pattern ""
                :send-delayed-final-ret t)

```

When using `use-package` to lazy-load `termint`, keep in mind the following:

1.  To bind a `termint-repl-map` to a prefix key globally, utilize the
    `:bind-keymap` block within `use-package`.
2.  To bind a `termint-repl-map` to a prefix key within a major mode (e.g.,
    Python mode), use `define-key` manually inside the `:config` block within
    `use-package`.

## Window Management

The display behavior of REPL buffers created by `termint` can be customized by
defining window popup rules in `display-buffer-alist`.

For example, to configure the window layout for `ipython` buffers, use the
following configuration:

```emacs-lisp

(add-to-list 'display-buffer-alist
             '("\\*ipython\\*"
               (display-buffer-in-side-window display-buffer-reuse-window)
               (window-width . 0.5)
               (window-height 0.5)
               (side . bottom)
               (slot . -1)))
```

# FAQ

## Difference between "sourcing" and "sending"

`termint` differentiates between "sourcing" and simply "sending" code to the
REPL.

- **Sending** typically involves passing code directly to the REPL's standard
  input, mimicking manual typing (or a copy-pasted input via bracketed-paste).
  This is suitable for interactive commands or a few lines code snippets

- **Sourcing** utilizes the `:source-syntax` to manage the code execution. The
  conventional pattern involves:
  1.  Writing the code to a temporary file.
  2.  Sending a command to the REPL, instructing it to execute the contents of
      that file.

The primary advantage of `source` lies in handling large code content. Instead
of sending huge code chunks directly to the REPL, it prevents cluttering your
interaction history, maintaining a cleaner session. Additionally, on Windows,
sourcing from a file mitigates potential issues with stdin processing when the
REPL must read substantial input, as the file-based approach significantly
reduces the data read from the stdin.

However, one notable drawback involves the security implications of temporary
file creation. Since the REPL executes code from this file, any vulnerability in
temporary file handling—such as exposure to malicious attack—could pose security
risks. Thus, while beneficial in certain scenarios, this method requires careful
consideration of its potential drawbacks.

you may consider enabling `:show-source-command-hint` as `t`, which provides
useful hint about the underlying command being executed.

## Bracketed-Paste Mode

Bracketed-paste mode wraps pasted text in escape sequences, letting terminals
distinguish it from typed input. In `termint`, control it via
`:bracketed-paste-p` in `termint-define`. This prevents REPLs from
misinterpreting pasted newlines or special characters. Most modern REPLs support
it, making `:bracketed-paste-p t` a generally recommended setting, but some may
not work perfectly. Test with your setup to confirm compatibility.

## Comparison with Other Approaches

### Emacs Built-in `comint`

`comint-mode` is Emacs's standard way of interacting with inferior processes,
including shells and REPLs.

`comint` runs the process in a "dumb" process. This means it doesn't fully
support complex terminal escape sequences for things like advanced color
rendering, or features like bracketed paste mode (though some workarounds
exist). This can lead to display glitches or less robust interaction with modern
REPLs that expect a capable terminal.

`termint` runs the REPL inside a _real_ terminal emulator backend (`term`,
`vterm`, `eat`). This enables the REPL to function as it would in a standalone
terminal, taking advantage of features such as accurate rendering, bracketed
paste support, and complex interaction capabilities, leading to a potentially
smoother and more reliable experience.

### Language/Backend-Specific Packages (`py-vterm-interaction`, `vterm-julia`, etc.)

Packages like `py-vterm-interaction` (for Python in `vterm`) or `vterm-julia`
(for Julia in `vterm`) provide tight integration between a specific language and
a specific terminal backend.

termint offers a general and flexible definition mechanism that is
backend-agnostic (works with`term`, `vterm`, `eat`) and language-agnostic. You
can use the same framework to define interactions for Python, R, Julia, shell
scripting, or any other tool with a command-line REPL, simply by providing the
appropriate command and interaction parameters. This provides a consistent
approach across different tools and backends. The trade-off might be less deep
language-specific integration compared to a dedicated package, but it offers
much broader applicability and user choice regarding the terminal backend.

# Contributing

Contributions, bug reports, and feature requests are welcome. Please open an
issue or pull request on the project repository.
