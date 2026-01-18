           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  CONSULT.EL - SEARCH AND NAVIGATE VIA
                            COMPLETING-READ
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Consult provides search and navigation commands based on the Emacs
completion function [completing-read] documented in the [Elisp
manual]. Completion allows you to quickly select an item from a list of
candidates. Consult offers asynchronous and interactive `consult-grep'
and `consult-ripgrep' commands, and the line-based search command
`consult-line'. Furthermore Consult provides an advanced buffer
switching command `consult-buffer' to switch between buffers, recently
opened files, bookmarks and buffer-like candidates from other
sources. Some of the Consult commands are enhanced versions of built-in
Emacs commands. For example the command `consult-imenu' presents a flat
list of the Imenu with [live preview], [grouping and narrowing]. Please
take a look at the [full list of commands].

Consult is fully compatible with completion systems centered around the
standard Emacs `completing-read' API, [Vertico], [Mct], and the built-in
default completion system and Icomplete.

This package keeps the completion system specifics to a minimum. The
ability of the Consult commands to work well with arbitrary completion
systems is one of the main advantages of the package. Consult fits well
into existing setups and it helps you to create a full completion
environment out of small and independent components.

You can combine the complementary packages [Marginalia], [Embark] and
[Orderless] with Consult. Marginalia enriches the completion display
with annotations, e.g., documentation strings or file information. The
versatile Embark package provides local actions, comparable to a context
menu. These actions operate on the selected candidate in the minibuffer
or at point in normal buffers. For example, when selecting from a list
of files, Embark offers an action to delete the file.  Additionally
Embark offers a facility to collect completion candidates in a collect
buffer. The section [Embark integration] documents in detail how Consult
and Embark work together.

Table of Contents
─────────────────

1. Available commands
.. 1. Virtual Buffers
.. 2. Editing
.. 3. Register
.. 4. Navigation
.. 5. Search
.. 6. Grep and Find
.. 7. Compilation
.. 8. Histories
.. 9. Modes
.. 10. Org Mode
.. 11. Help
.. 12. Miscellaneous
2. Special features
.. 1. Live previews
.. 2. Narrowing and grouping
.. 3. Asynchronous search
.. 4. Multiple sources
.. 5. Embark integration
3. Configuration
.. 1. Use-package example
.. 2. Custom variables
.. 3. Project support
.. 4. Fine-tuning
.. 5. Default completion UI with auto update
4. Recommended packages
5. Bug reports
6. Hacking
.. 1. Creating simple commands
.. 2. Creating asynchronous completion commands
.. 3. Live preview
7. Contributions
8. Acknowledgments
9. Indices
.. 1. Function index
.. 2. Concept index


[completing-read]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Minibuffer-Completion.html>

[Elisp manual] <info:elisp#Minibuffer Completion>

[live preview] See section 2.1

[grouping and narrowing] See section 2.2

[full list of commands] See section 1

[Vertico] <https://github.com/minad/vertico>

[Mct] <https://github.com/protesilaos/mct>

[Marginalia] <https://github.com/minad/marginalia>

[Embark] <https://github.com/oantolin/embark>

[Orderless] <https://github.com/oantolin/orderless>

[Embark integration] See section 2.5


1 Available commands
════════════════════

  Most Consult commands follow the meaningful naming scheme
  `consult-<thing>'.  Many commands implement a little known but
  convenient Emacs feature called "future history", which guesses what
  input the user wants. At a command prompt type `M-n' and typically
  Consult will insert the symbol or thing at point into the input.

  *TIP:* If you have [Marginalia] annotators activated, type `M-x
  ^consult' to see all Consult commands with their abbreviated
  description. Alternatively, type `C-h a ^consult' to get an overview
  of all Consult variables and functions with their descriptions.


[Marginalia] <https://github.com/minad/marginalia>

1.1 Virtual Buffers
───────────────────

  • `consult-buffer': Enhanced version of `switch-to-buffer' with
    support for virtual buffers. Supports live preview of buffers and
    narrowing to the virtual buffer types. You can type `f SPC' in order
    to narrow to recent files. Press `SPC' to show ephemeral
    buffers. Supported narrowing keys:
    • b Buffers
    • SPC Hidden buffers
    • * Modified buffers
    • o Buffers from other frames/tabs
    • f Files (Requires `recentf-mode')
    • r File and buffer registers
    • m Bookmarks
    • p Project
    • B Project buffers
    • F Project files
    • R Project roots
    • Custom [other sources] configured in `consult-buffer-sources'.
    By default, buffers from all frames are taken into account. The
    buffers which are taken into account, can be customized by the
    variable `consult-buffer-list-function'. Other buffers are available
    by pressing `o SPC'.
  • `consult-buffer-other-window', `consult-buffer-other-frame',
    `consult-buffer-other-tab': Variants of `consult-buffer'.
  • `consult-project-buffer': Variant of `consult-buffer' restricted to
    buffers and recent files of the current project. You can add custom
    sources to `consult-project-buffer-sources'. The command may prompt
    you for a project if you invoke it from outside a project.
  • `consult-bookmark': Select or create bookmark. To select bookmarks
    you might use the `consult-buffer' as an alternative, which can
    include a bookmark virtual buffer source. Note that
    `consult-bookmark' supports preview of bookmarks and narrowing.
  • `consult-recent-file': Select from recent files with preview.  You
    might prefer the powerful `consult-buffer' instead, which can
    include recent files as a virtual buffer source. The `recentf-mode'
    enables tracking of recent files.


[other sources] See section 2.4


1.2 Editing
───────────

  • `consult-yank-from-kill-ring': Enhanced version of `yank' to select
    an item from the `kill-ring'. The selected text previewed as overlay
    in the buffer.
  • `consult-yank-pop': Enhanced version of `yank-pop' with
    DWIM-behavior, which either replaces the last `yank' by cycling
    through the `kill-ring', or if there has not been a last `yank'
    consults the `kill-ring'. The selected text previewed as overlay in
    the buffer.
  • `consult-yank-replace': Like `consult-yank-pop', but always replaces
    the last `yank' with an item from the `kill-ring'.
  • `consult-kmacro': Select macro from the macro ring and execute it.


1.3 Register
────────────

  • `consult-register': Select from list of registers. The command
    supports narrowing to register types and preview of marker
    positions. This command is useful to search the register
    contents. For quick access use the commands `consult-register-load',
    `consult-register-store' or the built-in Emacs register commands.
  • `consult-register-format': Set `register-preview-function' to this
    function for an enhanced register formatting. Used automatically by
    `consult-register-window'.
  • `consult-register-window': Replace `register-preview' with this
    function for a better register window. See the [example
    configuration].
  • `consult-register-load': Utility command to quickly load a register.
    The command either jumps to the register value or inserts it.
  • `consult-register-store': Improved UI to store registers depending
    on the current context with an action menu. With an active region,
    store/append/prepend the contents, optionally deleting the region
    when a prefix argument is given.  With a numeric prefix argument,
    store/add the number. Otherwise store point, file, buffer, frameset,
    window or kmacro. Usage examples:
    ‣ `M-' x': If no region is active, store point in register `x'.  If
      a region is active, store the region in register `x'.
    ‣ `M-' M-w x': Store window configuration in register `x'.
    ‣ `C-u 100 M-' x': Store number in register `x'.


[example configuration] See section 3.1


1.4 Navigation
──────────────

  • `consult-goto-line': Jump to line number enhanced with live
    preview. This is a drop-in replacement for `goto-line'. Enter a line
    number to jump to the first column of the given line. Alternatively
    enter `line:column' in order to jump to a specific column.
  • `consult-mark': Jump to a marker in the `mark-ring'. Supports live
    preview and recursive editing.
  • `consult-global-mark': Jump to a marker in the `global-mark-ring'.
    Supports live preview and recursive editing.
  • `consult-outline': Jump to a heading of the outline. Supports
    narrowing to a heading level, live preview and recursive editing.
  • `consult-imenu': Jump to imenu item in the current buffer. Supports
    live preview, recursive editing and narrowing.
  • `consult-imenu-multi': Jump to imenu item in project buffers, with
    the same major mode as the current buffer. Supports live preview,
    recursive editing and narrowing. This feature has been inspired by
    [imenu-anywhere].


[imenu-anywhere] <https://github.com/vspinu/imenu-anywhere>


1.5 Search
──────────

  • `consult-line': Enter search string and select from matching lines.
    Supports live preview and recursive editing. The symbol at point and
    the recent Isearch string are added to the "future history" and can
    be accessed by pressing `M-n'. When `consult-line' is bound to the
    `isearch-mode-map' and is invoked during a running Isearch, it will
    use the current Isearch string.
  • `consult-line-multi': Search dynamically across multiple buffers. By
    default search across project buffers. If invoked with a prefix
    argument search across all buffers. The candidates are computed on
    demand based on the input. The command behaves like `consult-grep',
    but operates on buffers instead of files.
  • `consult-keep-lines': Replacement for `keep/flush-lines' which uses
    the current completion style for filtering the buffer. The function
    updates the buffer while typing. In particular `consult-keep-lines'
    can narrow down an exported Embark collect buffer further, relying
    on the same completion filtering as `completing-read'. If the input
    begins with the negation operator, i.e., `! SPC', the filter matches
    the complement. If a region is active, the region restricts the
    filtering.
  • `consult-focus-lines': Temporarily hide lines by filtering them
    using the current completion style. Call with `C-u' prefix argument
    in order to show the hidden lines again. If the input begins with
    the negation operator, i.e., `!  SPC', the filter matches the
    complement. In contrast to `consult-keep-lines' this function does
    not edit the buffer. If a region is active, the region restricts the
    filtering.


1.6 Grep and Find
─────────────────

  • `consult-grep-match': Jump to a Grep match in related Grep
    buffers. Supports live preview narrowing and recursive editing.
  • `consult-grep', `consult-ripgrep', `consult-git-grep': Search for
    regular expression in files. Consult invokes Grep asynchronously,
    while you enter the search term. After at least
    `consult-async-min-input' characters, the search gets
    started. Consult splits the input string into two parts, if the
    first character is a punctuation character, like `#'. For example
    `#regexps#filter-string', is split at the second `#'. The string
    `regexps' is passed to Grep. Note that Consult transforms Emacs
    regular expressions to expressions understand by the search
    program. Always use Emacs regular expressions at the prompt. If you
    enter multiple regular expressions separated by space only lines
    matching all regular expressions are shown. In order to match space
    literally, escape the space with a backslash. The `filter-string' is
    passed to the /fast/ Emacs filtering to further narrow down the list
    of matches. This is particularly useful if you are using an advanced
    completion style like orderless. `consult-grep' supports
    preview. `consult-grep' searches the current [project directory] if
    a project is found. Otherwise the `default-directory' is
    searched. If `consult-grep' is invoked with prefix argument `C-u M-s
    g', you can specify one or more comma-separated files and
    directories manually. If invoked with two prefix arguments `C-u C-u
    M-s g', you can first select a project if you are not yet inside a
    project.
  • `consult-find', `consult-fd', `consult-locate': Find file by
    matching the path against a regexp. Like for `consult-grep', either
    the project root or the current directory is the root directory for
    the search. The input string is treated similarly to `consult-grep',
    where the first part is passed to find, and the second part is used
    for Emacs filtering. Prefix arguments to `consult-find' work just
    like those for the consult grep commands.


[project directory] See section 3.3


1.7 Compilation
───────────────

  • `consult-compile-error': Jump to a compilation error in related
    compilation buffers. Supports live preview narrowing and recursive
    editing.
  • `consult-flymake': Jump to Flymake diagnostic. Supports live preview
    and recursive editing. The command supports narrowing. Press `e
    SPC', `w SPC', `n SPC' to only show errors, warnings and notes
    respectively.
  • `consult-xref': Integration with xref. This function can be set as
    `xref-show-xrefs-function' and `xref-show-definitions-function'.


1.8 Histories
─────────────

  • `consult-complex-command': Select a command from the
    `command-history'. This command is a `completing-read' version of
    `repeat-complex-command' and is also a replacement for the
    `command-history' command from chistory.el.
  • `consult-history': Insert a string from the current buffer history,
    for example the Eshell or Comint history. You can also invoke this
    command from the minibuffer. In that case `consult-history' uses the
    history stored in the `minibuffer-history-variable'. If you prefer
    `completion-at-point', take a look at `cape-history' from the [Cape]
    package.
  • `consult-isearch-history': During an Isearch session, this command
    picks a search string from history and continues the search with the
    newly selected string. Outside of Isearch, the command allows you to
    pick a string from the history and starts a new
    Isearch. `consult-isearch-history' acts as a drop-in replacement for
    `isearch-edit-string'.


[Cape] <https://github.com/minad/cape>


1.9 Modes
─────────

  • `consult-minor-mode-menu': Enable/disable minor mode. Supports
    narrowing to on/off/local/global modes by pressing `i/o/l/g SPC'
    respectively.
  • `consult-mode-command': Run a command from the currently active
    minor or major modes. Supports narrowing to
    local-minor/global-minor/major mode via the keys `l/g/m'.


1.10 Org Mode
─────────────

  • `consult-org-heading': Variant of `consult-imenu' or
    `consult-outline' for Org buffers. The headline and its ancestors
    headlines are separated by slashes.  Supports narrowing by heading
    level, priority and TODO keyword, as well as live preview and
    recursive editing.
  • `consult-org-agenda': Jump to an Org agenda heading. Supports
    narrowing by heading level, priority and TODO keyword, as well as
    live preview and recursive editing.


1.11 Help
─────────

  • `consult-man': Find Unix man page, via Unix `apropos' or `man
    -k'. `consult-man' opens the selected man page using the Emacs `man'
    command. Supports live preview of the theme while scrolling through
    the candidates.
  • `consult-info': Full text search through info pages. If the command
    is invoked from within an `*info*' buffer, it will search through
    the current manual. You may want to create your own `consult-info-*'
    commands which search through a predefined set of info pages. You
    can use the function `consult-info-define' to define commands
    `consult-info-emacs', `consult-info-completion', `consult-info-org',
    and so on:
  ┌────
  │ (consult-info-define "emacs" "efaq" "elisp" "cl" "compat" "eshell")
  │ (consult-info-define 'completion
  │                      "vertico" "consult" "marginalia" "orderless"
  │                      "embark" "corfu" "cape" "tempel")
  │ (consult-info-define "org")
  │ (consult-info-define "gnus")
  │ (consult-info-define "magit")
  └────


1.12 Miscellaneous
──────────────────

  • `consult-theme': Select a theme and disable all currently enabled
    themes.  Supports live preview of the theme while scrolling through
    the candidates.
  • `consult-completion-in-region': In case you don't use [Corfu] as
    your in-buffer completion UI, this function can be set as
    `completion-in-region-function'. Then your minibuffer completion UI
    (e.g., Vertico or Icomplete) will be used for `completion-at-point'.
    ┌────
    │ (setq completion-in-region-function #'consult-completion-in-region)
    └────
    Instead of `consult-completion-in-region', you may prefer to see the
    completions directly in the buffer as a small popup. In that case, I
    recommend the [Corfu] package. There is a technical limitation of
    `consult-completion-in-region' in combination with the Lsp
    modes. The Lsp server relies on the input at point, in order to
    generate refined candidate strings. Since the completion is
    transferred from the original buffer to the minibuffer, the server
    does not receive the updated input. In contrast, in-buffer Lsp
    completion for example via Corfu works properly since the completion
    takes place directly in the original buffer.


[Corfu] <https://github.com/minad/corfu>


2 Special features
══════════════════

  Consult enhances `completing-read' with live previews of candidates,
  additional narrowing capabilities to candidate groups and
  asynchronously generated candidate lists. The internal `consult--read'
  function, which is used by most Consult commands, is a thin wrapper
  around `completing-read' and provides the special functionality. In
  order to support multiple candidate sources there exists the
  high-level function `consult--multi'. The architecture of Consult
  allows it to work with different completion systems in the backend,
  while still offering advanced features.


2.1 Live previews
─────────────────

  Some Consult commands support live previews. For example when you
  scroll through the items of `consult-line', the buffer will scroll to
  the corresponding position.  It is possible to jump back and forth
  between the minibuffer and the buffer to perform recursive editing
  while the search is ongoing.

  Consult enables previews by default. You can disable them by adjusting
  the `consult-preview-key' variable. Furthermore it is possible to
  specify keybindings which trigger the preview manually as shown in the
  [example configuration]. The default setting of `consult-preview-key'
  is `any' which means that Consult triggers the preview /immediately/
  on any key press when the selected candidate changes.  You can
  configure each command individually with its own `:preview-key'. The
  following settings are possible:

  • Automatic and immediate `'any'
  • Automatic and delayed `(list :debounce 0.5 'any)'
  • Manual and immediate `"M-."'
  • Manual and delayed `(list :debounce 0.5 "M-.")'
  • Disabled `nil'

  A safe recommendation is to leave automatic immediate previews enabled
  in general and disable the automatic preview only for commands where
  the preview may be expensive due to file loading. Internally, Consult
  uses the value of `this-command' to determine the `:preview-key'
  customized. This means that if you wrap a `consult-*' command within
  your own function or command, you will also need to add the name of
  /your custom command/ to the `consult-customize' call in order for it
  to be considered.

  ┌────
  │ (consult-customize
  │  consult-ripgrep consult-git-grep consult-grep consult-man
  │  consult-bookmark consult-recent-file consult-xref
  │  consult-source-bookmark consult-source-file-register
  │  consult-source-recent-file consult-source-project-recent-file
  │  :preview-key '(:debounce 0.4 any)) ;; Option 1: Delay preview
  │  ;; :preview-key "M-."              ;; Option 2: Manual preview
  └────

  In this case one may wonder what the difference is between using an
  Embark action on the current candidate in comparison to a manually
  triggered preview.  The main difference is that the files opened by
  manual preview are closed again after the completion session. During
  preview some functionality is disabled to improve the performance, see
  for example the customization variables `consult-preview-variables'
  and `consult-preview-allowed-hooks'. Only hooks listed in
  `consult-preview-allowed-hooks' are executed. This variable applies to
  `find-file-hook', `change-major-mode-hook' and mode hooks, e.g.,
  `prog-mode-hook'. In order to enable additional font locking during
  preview, add the corresponding hooks to the allow list. The following
  code demonstrates this for [org-modern] and [hl-todo].

  ┌────
  │ ;; local modes added to prog-mode hooks
  │ (add-to-list 'consult-preview-allowed-hooks 'hl-todo-mode)
  │ (add-to-list 'consult-preview-allowed-hooks 'elide-head-mode)
  │ ;; enabled global modes
  │ (add-to-list 'consult-preview-allowed-hooks 'global-org-modern-mode)
  │ (add-to-list 'consult-preview-allowed-hooks 'global-hl-todo-mode)
  └────

  Files larger than `consult-preview-partial-size' are previewed
  partially. Delaying the preview is also useful for `consult-theme',
  since the theme preview is slow.  The delay results in a smoother UI
  experience.

  ┌────
  │ ;; Preview on any key press, but delay 0.5s
  │ (consult-customize consult-theme :preview-key '(:debounce 0.5 any))
  │ ;; Preview immediately on M-., on up/down after 0.5s, on any other key after 1s
  │ (consult-customize consult-theme
  │                    :preview-key
  │                    '("M-."
  │                      :debounce 0.5 "<up>" "<down>"
  │                      :debounce 1 any))
  └────


[example configuration] See section 3.1

[org-modern] <https://github.com/minad/org-modern>

[hl-todo] <https://github.com/tarsius/hl-todo>


2.2 Narrowing and grouping
──────────────────────────

  Consult has special support for candidate groups. If the completion UI
  supports the grouping functionality, the UI separates the groups with
  thin lines and shows group titles. Grouping is useful if the list of
  candidates consists of candidates of multiple types or candidates from
  [multiple sources], like the `consult-buffer' command, which shows
  both buffers and recently opened files. Note that you can disable the
  group titles by setting the `:group' property of the corresponding
  command to nil using the `consult-customize' macro.

  By entering a narrowing prefix or by pressing a narrowing key it is
  possible to restrict the completion candidates to a certain candidate
  group. When you use the `consult-buffer' command, you can enter the
  prefix `b SPC' to restrict list of candidates to buffers only. If you
  press `DEL' afterwards, the full candidate list will be shown
  again. Furthermore a narrowing prefix key and a widening key can be
  configured which can be pressed to achieve the same effect, see the
  configuration variables `consult-narrow-key' and `consult-widen-key'.

  After pressing `consult-narrow-key', the possible narrowing keys can
  be shown by pressing `C-h'. When pressing `C-h' after some prefix key,
  the `prefix-help-command' is invoked, which shows the keybinding help
  window by default. As a more compact alternative, there is the
  `consult-narrow-help' command which can be bound to a key, for example
  `?' or `C-h' in the `consult-narrow-map', as shown in the [example
  configuration]. If [which-key] is installed, the narrowing keys are
  automatically shown in the which-key window after pressing the
  `consult-narrow-key'.


[multiple sources] See section 2.4

[example configuration] See section 3.1

[which-key] <https://github.com/justbur/emacs-which-key>


2.3 Asynchronous search
───────────────────────

  Consult has support for asynchronous generation of candidate
  lists. This feature is used for search commands like `consult-grep',
  where the list of matches is generated dynamically while the user is
  typing a regular expression. The grep process is executed in the
  background. When modifying the regular expression, the background
  process is terminated and a new process is started with the modified
  regular expression.

  The matches, which have been found, can then be narrowed using the
  installed Emacs completion-style. This can be powerful if you are
  using for example the `orderless' completion style.

  This two-level filtering is possible by splitting the input
  string. Part of the input string is treated as input to grep and part
  of the input is used for filtering. There are multiple splitting
  styles available, configured in `consult-async-split-styles-alist':
  `nil', `comma', `semicolon' and `perl'. The default splitting style is
  configured with the variable `consult-async-split-style'.

  With the `comma' and `semicolon' splitting styles, the first word
  before the comma or semicolon is passed to grep, the remaining string
  is used for filtering. The `nil' splitting style does not perform any
  splitting, the whole input is passed to grep.

  The `perl' splitting style splits the input string at a punctuation
  character, using a similar syntax as Perl regular expressions.

  Examples:

  • `#defun': Search for "defun" using grep.
  • `#consult embark': Search for both "consult" and "embark" using grep
    in any order.
  • `#first.*second': Search for "first" followed by "second" using
    grep.
  • `#\(consult\|embark\)': Search for "consult" or "embark" using
    grep. Note the usage of Emacs-style regular expressions.
  • `#defun#consult': Search for "defun" using grep, filter with the
    word "consult".
  • `/defun/consult': It is also possible to use other punctuation
    characters.
  • `#to#': Force searching for "to" using grep, since the grep pattern
    must be longer than `consult-async-min-input' characters by default.

  You can pass options to the underlying command. The following examples
  apply to ripgrep:

  • `#foo bar --invert-match' or `#foo bar -v': Invert matching.
  • `#foo bar --context=2' or `#foo bar -C2': Include two lines of
    context.
  • `#foo bar --hidden' or `#foo bar -.': Search hidden files.
  • `#foo bar --glob=*.org' or `#foo bar -g *.org': Search files
    matching the glob pattern.
  • `#foo bar --type=elisp' or `#foo bar -t elisp': Search only Elisp
    files.
  • `#.* -F': Treat input as fixed string, and not as regular
    expression.
  • `#foo bar -s': Treat input as case sensitive (`-s'), sensitive
    (`-i'), or smart case (`-S').

  Input can come after the options and the dash can be escaped:

  • `#\-foo bar': Search for `-foo' and `bar' with escaped dash.
  • `#-v -- foo bar': Inverted search, words come after options.

  The asynchronous processes create an error log buffer
  `_*consult-async*' (note the leading space), which you can inspect for
  troubleshooting. The prompt has a small indicator showing the process
  status:

  • `:' the usual prompt colon, before input is provided.
  • `*' with warning face, the process is running.
  • `:' with success face, success, process exited with an error code of
    zero.
  • `!' with error face, failure, process exited with a nonzero error
    code.
  • `;' with error face, interrupted, for example if more input is
    provided.


2.4 Multiple sources
────────────────────

  Multiple static and asynchronous candidate sources can be
  combined. This feature is used by the `consult-buffer' command to
  present buffer-like candidates in a single menu for quick access. By
  default `consult-buffer' includes buffers, bookmarks, recent files and
  project-specific buffers and files. The `consult-buffer-sources'
  variable configures the list of sources. Arbitrary custom sources can
  be added to this list.

  As an example, the bookmark source is defined as follows:

  ┌────
  │ (defvar consult-source-bookmark
  │   `(:name     "Bookmark"
  │     :narrow   ?m
  │     :category bookmark
  │     :face     consult-bookmark
  │     :history  bookmark-history
  │     :items    ,#'bookmark-all-names
  │     :action   ,#'consult--bookmark-action))
  └────

  Either the `:items' or the `:async' source field is required:
  • `:items' List of strings to select from or function returning list
    of strings.  The strings can carry metadata in text properties,
    which is then available to the `:annotate', `:action' and `:state'
    functions. The list can also consist of pairs, with the string in
    the `car' used for display and the `cdr' the actual candidate.
  • `:async' Alternative to `:items' for asynchronous sources. See the
    docstring for details.

  Optional source fields:
  • `:name' Name of the source, used for narrowing, group titles and
    annotations.
  • `:narrow' Narrowing character, `(char . string)' pair or list of
    pairs.
  • `:category' Completion category.
  • `:preview-key' Preview key or keys which trigger preview.
  • `:enabled' Function which must return t if the source is enabled.
  • `:hidden' When t candidates of this source are hidden by default.
  • `:face' Face used for highlighting the candidates.
  • `:annotate' Annotation function called for each candidate, returns
    string.
  • `:history' Name of history variable to add selected candidate.
  • `:default' Must be t if the first item of the source is the default
    value.
  • `:action' Function called with the selected candidate.
  • `:new' Function called with new candidate name, only if
    `:require-match' is nil.
  • `:state' State constructor for the source, must return the state
    function.
  • Other source fields can be added specifically to the use case.

  The `:state' and `:action' fields of the sources deserve a longer
  explanation. The `:action' function takes a single argument and is
  only called after selection with the selected candidate, if the
  selection has not been aborted. This functionality is provided for
  convenience and easy definition of sources. The `:state' field is more
  general. The `:state' function is a constructor function without
  arguments, which can perform some setup necessary for the preview. It
  must return a closure which takes an ACTION and a CANDIDATE
  argument. See the docstring of `consult--with-preview' for more
  details about the ACTION argument.

  By default, `consult-buffer' previews buffers, bookmarks and
  files. Loading recent files or bookmarks can result in expensive
  operations. However it is possible to configure a manual preview as
  follows.

  ┌────
  │ (consult-customize
  │  consult-source-bookmark consult-source-file-register
  │  consult-source-recent-file consult-source-project-recent-file
  │  :preview-key "M-.")
  └────

  Sources can be added directly to the `consult-buffer-source' list for
  convenience.  For example, the following source lists all Org buffers
  and lets you create new ones.

  ┌────
  │ (defvar org-source
  │   (list :name     "Org Buffer"
  │         :category 'buffer
  │         :narrow   ?o
  │         :face     'consult-buffer
  │         :history  'buffer-name-history
  │         :state    #'consult--buffer-state
  │         :new
  │         (lambda (name)
  │           (with-current-buffer (get-buffer-create name)
  │             (insert "#+title: " name "\n\n")
  │             (org-mode)
  │             (consult--buffer-action (current-buffer))))
  │         :items
  │         (lambda ()
  │           (consult--buffer-query :mode 'org-mode :as #'consult--buffer-pair))))
  │ 
  │ (add-to-list 'consult-buffer-sources 'org-source 'append)
  └────

  One can create similar sources for other major modes. See the [Consult
  wiki] for many additional source examples. See also the documentation
  of `consult-buffer' and of the internal `consult--multi' API. The
  function `consult--multi' can be used to create new multi-source
  commands.


[Consult wiki] <https://github.com/minad/consult/wiki>


2.5 Embark integration
──────────────────────

  *NOTE*: Install the `embark-consult' package from MELPA, which
  provides Consult-specific Embark actions and the Occur buffer export.

  Embark is a versatile package which offers context dependent actions,
  comparable to a context menu. See the [Embark manual] for an extensive
  description of its capabilities.

  Actions are commands which can operate on the currently selected
  candidate (or target in Embark terminology). When completing files,
  for example the `delete-file' command is offered. With Embark you can
  execute arbitrary commands on the currently selected candidate via
  `M-x'.

  Furthermore Embark provides the `embark-collect' command, which
  collects candidates and presents them in an Embark collect buffer,
  where further actions can be applied to them. A related feature is the
  `embark-export' command, which exports candidate lists to a buffer of
  a special type. For example in the case of file completion, a Dired
  buffer is opened.

  In the context of Consult, particularly exciting is the possibility to
  export the matching lines from `consult-line', `consult-outline',
  `consult-mark' and `consult-global-mark'. The matching lines are
  exported to an Occur buffer where they can be edited via the
  `occur-edit-mode' (press key `e'). Similarly, Embark supports
  exporting the matches found by `consult-grep', `consult-ripgrep' and
  `consult-git-grep' to a Grep buffer, where the matches across files
  can be edited, via `grep-edit-mode' on Emacs 31 (or via the [wgrep]
  package). These three workflows are symmetric.

  ⁃ `consult-line' -> `embark-export' to `occur-mode' buffer ->
    `occur-edit-mode' for editing of matches.
  ⁃ `consult-grep' -> `embark-export' to `grep-mode' buffer ->
    `grep-edit-mode' for editing of matches.
  ⁃ `consult-find' -> `embark-export' to `dired-mode' buffer ->
    `wdired-change-to-wdired-mode' for editing.


[Embark manual] <https://github.com/oantolin/embark>

[wgrep] <https://github.com/mhayashi1120/Emacs-wgrep>


3 Configuration
═══════════════

  Consult can be installed from [ELPA] or [MELPA] via the Emacs built-in
  package manager. Alternatively it can be directly installed from the
  development repository via other non-standard package managers.

  There is the [Consult wiki], where additional configuration examples
  can be contributed.

  *IMPORTANT:* It is recommended that you enable lexical binding in your
  configuration. Many Consult-related code snippets require lexical
  binding, since they use lambdas and closures.


[ELPA] <https://elpa.gnu.org/packages/consult.html>

[MELPA] <https://melpa.org/#/consult>

[Consult wiki] <https://github.com/minad/consult/wiki>

3.1 Use-package example
───────────────────────

  The Consult package only provides commands and does not add any
  keybindings or modes. Therefore the package is non-intrusive but
  requires a little setup effort. While the configuration example is
  long, it consists essentially of key bindings only, such that the risk
  of interference with other Emacs functionality is minimized.

  In order to use the Consult commands, it is recommended to add
  keybindings for commands which are accessed often. Rarely used
  commands can be invoked via `M-x'.  Feel free to only bind the
  commands you consider useful to your workflow. The configuration shown
  here relies on the `use-package' macro, which is a convenient tool to
  manage package configurations.

  *NOTE:* There is the [Consult wiki], where you can contribute
  additional configuration examples.

  ┌────
  │ ;; Example configuration for Consult
  │ (use-package consult
  │   ;; Replace bindings. Lazily loaded by `use-package'.
  │   :bind (;; C-c bindings in `mode-specific-map'
  │          ("C-c M-x" . consult-mode-command)
  │          ("C-c h" . consult-history)
  │          ("C-c k" . consult-kmacro)
  │          ("C-c m" . consult-man)
  │          ("C-c i" . consult-info)
  │          ([remap Info-search] . consult-info)
  │          ;; C-x bindings in `ctl-x-map'
  │          ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
  │          ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
  │          ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
  │          ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
  │          ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
  │          ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
  │          ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
  │          ;; Custom M-# bindings for fast register access
  │          ("M-#" . consult-register-load)
  │          ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
  │          ("C-M-#" . consult-register)
  │          ;; Other custom bindings
  │          ("M-y" . consult-yank-pop)                ;; orig. yank-pop
  │          ;; M-g bindings in `goto-map'
  │          ("M-g e" . consult-compile-error)
  │          ("M-g r" . consult-grep-match)
  │          ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
  │          ("M-g g" . consult-goto-line)             ;; orig. goto-line
  │          ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
  │          ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
  │          ("M-g m" . consult-mark)
  │          ("M-g k" . consult-global-mark)
  │          ("M-g i" . consult-imenu)
  │          ("M-g I" . consult-imenu-multi)
  │          ;; M-s bindings in `search-map'
  │          ("M-s d" . consult-find)                  ;; Alternative: consult-fd
  │          ("M-s c" . consult-locate)
  │          ("M-s g" . consult-grep)
  │          ("M-s G" . consult-git-grep)
  │          ("M-s r" . consult-ripgrep)
  │          ("M-s l" . consult-line)
  │          ("M-s L" . consult-line-multi)
  │          ("M-s k" . consult-keep-lines)
  │          ("M-s u" . consult-focus-lines)
  │          ;; Isearch integration
  │          ("M-s e" . consult-isearch-history)
  │          :map isearch-mode-map
  │          ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
  │          ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
  │          ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
  │          ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
  │          ;; Minibuffer history
  │          :map minibuffer-local-map
  │          ("M-s" . consult-history)                 ;; orig. next-matching-history-element
  │          ("M-r" . consult-history))                ;; orig. previous-matching-history-element
  │ 
  │   ;; The :init configuration is always executed (Not lazy)
  │   :init
  │ 
  │   ;; Tweak the register preview for `consult-register-load',
  │   ;; `consult-register-store' and the built-in commands.  This improves the
  │   ;; register formatting, adds thin separator lines, register sorting and hides
  │   ;; the window mode line.
  │   (advice-add #'register-preview :override #'consult-register-window)
  │   (setq register-preview-delay 0.5)
  │ 
  │   ;; Use Consult to select xref locations with preview
  │   (setq xref-show-xrefs-function #'consult-xref
  │         xref-show-definitions-function #'consult-xref)
  │ 
  │   ;; Configure other variables and modes in the :config section,
  │   ;; after lazily loading the package.
  │   :config
  │ 
  │   ;; Optionally configure preview. The default value
  │   ;; is 'any, such that any key triggers the preview.
  │   ;; (setq consult-preview-key 'any)
  │   ;; (setq consult-preview-key "M-.")
  │   ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  │   ;; For some commands and buffer sources it is useful to configure the
  │   ;; :preview-key on a per-command basis using the `consult-customize' macro.
  │   (consult-customize
  │    consult-theme :preview-key '(:debounce 0.2 any)
  │    consult-ripgrep consult-git-grep consult-grep consult-man
  │    consult-bookmark consult-recent-file consult-xref
  │    consult-source-bookmark consult-source-file-register
  │    consult-source-recent-file consult-source-project-recent-file
  │    ;; :preview-key "M-."
  │    :preview-key '(:debounce 0.4 any))
  │ 
  │   ;; Optionally configure the narrowing key.
  │   ;; Both < and C-+ work reasonably well.
  │   (setq consult-narrow-key "<") ;; "C-+"
  │ 
  │   ;; Optionally make narrowing help available in the minibuffer.
  │   ;; You may want to use `embark-prefix-help-command' or which-key instead.
  │   ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  │ )
  └────


[Consult wiki] <https://github.com/minad/consult/wiki>


3.2 Custom variables
────────────────────

  *TIP:* If you have [Marginalia] installed, type `M-x
  customize-variable RET ^consult' to see all Consult-specific
  customizable variables with their current values and abbreviated
  description. Alternatively, type `C-h a ^consult' to get an overview
  of all Consult variables and functions with their descriptions.

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Variable                          Description                                         
  ───────────────────────────────────────────────────────────────────────────────────────
   consult-after-jump-hook           Functions to call after jumping to a location       
   consult-async-input-debounce      Input debounce for asynchronous commands            
   consult-async-input-throttle      Input throttle for asynchronous commands            
   consult-async-min-input           Minimum numbers of input characters                 
   consult-async-refresh-delay       Refresh delay for asynchronous commands             
   consult-async-split-style         Splitting style used for async commands             
   consult-async-split-styles-alist  Available splitting styles used for async commands  
   consult-async-indicator           Async indicator characters                          
   consult-bookmark-narrow           Narrowing configuration for `consult-bookmark'      
   consult-buffer-filter             Filter for `consult-buffer'                         
   consult-buffer-list-function      Function to retrieve list of buffers                
   consult-buffer-sources            List of virtual buffer sources                      
   consult-fd-args                   Command line arguments for fd                       
   consult-find-args                 Command line arguments for find                     
   consult-fontify-max-size          Buffers larger than this limit are not fontified    
   consult-fontify-preserve          Preserve fontification for line-based commands.     
   consult-git-grep-args             Command line arguments for git-grep                 
   consult-goto-line-numbers         Show line numbers for `consult-goto-line'           
   consult-grep-max-columns          Maximal number of columns of the matching lines     
   consult-grep-args                 Command line arguments for grep                     
   consult-imenu-config              Mode-specific configuration for `consult-imenu'     
   consult-line-numbers-widen        Show absolute line numbers when narrowing is active 
   consult-line-start-from-top       Start the `consult-line' search from the top        
   consult-locate-args               Command line arguments for locate                   
   consult-man-args                  Command line arguments for man                      
   consult-mode-command-filter       Filter for `consult-mode-command'                   
   consult-mode-histories            Mode-specific history variables                     
   consult-narrow-key                Narrowing prefix key during completion              
   consult-point-placement           Placement of the point when jumping to matches      
   consult-preview-key               Keys which triggers preview                         
   consult-preview-allowed-hooks     List of hooks to allow during preview               
   consult-preview-excluded-buffers  Predicate to exclude buffers from preview           
   consult-preview-excluded-files    Regexps matched against file names during preview   
   consult-preview-max-count         Maximum number of files to keep open during preview 
   consult-preview-partial-size      Files larger than this size are previewed partially 
   consult-preview-partial-chunk     Size of the file chunk which is previewed partially 
   consult-preview-variables         Alist of variables to bind during preview           
   consult-project-buffer-sources    List of virtual project buffer sources              
   consult-project-function          Function which returns current project root         
   consult-register-prefix           Prefix string for register keys during completion   
   consult-ripgrep-args              Command line arguments for ripgrep                  
   consult-themes                    List of themes to be presented for selection        
   consult-widen-key                 Widening key during completion                      
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[Marginalia] <https://github.com/minad/marginalia>


3.3 Project support
───────────────────

  Multiple Consult search commands like `consult-grep' try to discover
  the current project and search in the project top level directory by
  default, if a project is found. Otherwise they fall back to the
  `default-directory'. By default, Consult uses the Emacs built-in
  project discovery support (`project-current' and `project-root'). It
  is possible to configure alternative methods via the customization
  variable `consult-project-function'.

  ┌────
  │ ;; Optionally configure a different project root function.
  │ ;; 1. project.el (the default)
  │ (setq consult-project-function #'consult--default-project--function)
  │ ;; 2. vc.el (vc-root-dir)
  │ (setq consult-project-function (lambda (_) (vc-root-dir)))
  │ ;; 3. locate-dominating-file
  │ (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
  │ ;; 4. projectile.el (projectile-project-root)
  │ (autoload 'projectile-project-root "projectile")
  │ (setq consult-project-function (lambda (_) (projectile-project-root)))
  │ ;; 5. Disable project support
  │ (setq consult-project-function nil)
  └────


3.4 Fine-tuning of individual commands
──────────────────────────────────────

  *NOTE:* Consult supports fine-grained customization of individual
  commands. This configuration feature exists for experienced users with
  special requirements.  There is the [Consult wiki], where we collect
  further configuration examples.

  Commands and buffer sources allow flexible, individual customization
  by using the `consult-customize' macro. You can override any option
  passed to the internal `consult--read' API. Note that since
  `consult--read' is part of the internal API, options could be removed,
  replaced or renamed in future versions of the package.

  Useful options are:
  • `:prompt' set the prompt string
  • `:preview-key' set the preview key, default is `consult-preview-key'
  • `:initial' set the initial input
  • `:initial-narrow' set the initial narrow key
  • `:default' set the default value
  • `:history' set the history variable symbol
  • `:add-history' add items to the future history, for example symbol
    at point
  • `:sort' enable or disable sorting
  • `:group' set to nil to disable candidate grouping and titles.
  • `:inherit-input-method' set to non-nil to inherit the input method.

  ┌────
  │ (consult-customize
  │  ;; Disable preview for `consult-theme' completely.
  │  consult-theme :preview-key nil
  │  ;; Set preview for `consult-buffer' to key `M-.'
  │  consult-buffer :preview-key "M-."
  │  ;; For `consult-line' change the prompt and specify multiple preview
  │  ;; keybindings. Note that you should bind <S-up> and <S-down> in the
  │  ;; `minibuffer-local-completion-map' or `vertico-map' to the commands which
  │  ;; select the previous or next candidate.
  │  consult-line :prompt "Search: "
  │  :preview-key '("S-<down>" "S-<up>"))
  └────

  The configuration values are evaluated at runtime, just before the
  completion session is started. Therefore you can use for example
  `thing-at-point' to adjust the initial input or the future history.

  ┌────
  │ (consult-customize
  │  consult-line
  │  :add-history (seq-some #'thing-at-point '(region symbol)))
  │ 
  │ (defalias 'consult-line-thing-at-point 'consult-line)
  │ 
  │ (consult-customize
  │  consult-line-thing-at-point
  │  :initial (thing-at-point 'symbol))
  └────

  Generally it is possible to modify commands for your individual needs
  by the following techniques:

  1. Use `consult-customize' in order to change the command or source
     settings.
  2. Create your own wrapper function which passes modified arguments to
     the Consult functions.
  3. Create your own buffer [multi sources] for `consult-buffer'.
  4. Create advices to modify some internal behavior.
  5. Write or propose a patch.


[Consult wiki] <https://github.com/minad/consult/wiki>

[multi sources] See section 2.4


3.5 Default completion UI with auto update
──────────────────────────────────────────

  I recommend to use Vertico for best performance and an intuitive UI.
  Nevertheless the default completions buffer UI works decently and
  supports automatic update in newer Emacs versions. I suggest the
  following configuration on Emacs 31:

  ┌────
  │ (setq
  │  ;; One column view with annotations
  │  completions-format 'one-column
  │  completions-detailed t
  │  completions-group t
  │  ;; Sort candidates by history position
  │  completions-sort 'historical
  │  ;; Allow navigating from the minibuffer
  │  minibuffer-visible-completions 'up-down
  │  ;; Show completions eagerly and update automatically
  │  completion-eager-update t
  │  completion-eager-display t
  │  ;; Disable noise (inline help also blocks input)
  │  completion-show-help nil
  │  completion-show-inline-help nil)
  └────


4 Recommended packages
══════════════════════

  I use and recommend this combination of packages:

  • consult: This package
  • [vertico]: Fast and minimal vertical completion system
  • [marginalia]: Annotations for the completion candidates
  • [embark and embark-consult]: Action commands, which can act on the
    completion candidates
  • [orderless]: Completion style which offers flexible candidate
    filtering
  • [wgrep] (or `grep-edit-mode' on Emacs 31): Editing of grep
    buffers. Use with `consult-grep' via `embark-export'.

  There exist multiple fine completion UIs beside Vertico, which are
  supported by Consult. Give them a try and find out which interaction
  model fits best for you.

  • The builtin completion UI, which pops up the `*Completions*' buffer.
  • The builtin `icomplete-vertical-mode'.
  • [mct by Protesilaos Stavrou]: Minibuffer and Completions in Tandem,
    which builds on the default completion UI.

  Note that all packages are independent and can be exchanged with
  alternative components, since there exist no hard
  dependencies. Furthermore it is possible to get started with only
  default completion and Consult and add more components later to the
  mix. For example you can omit Marginalia if you don't need
  annotations. I highly recommend the Embark package, but in order to
  familiarize yourself with the other components, you can first start
  without it - or you could use with Embark right away and add the other
  components later on.

  We document a [list of auxiliary packages] in the Consult wiki. These
  packages integrate Consult with special programs or with other
  packages in the wider Emacs ecosystem.


[vertico] <https://github.com/minad/vertico>

[marginalia] <https://github.com/minad/marginalia>

[embark and embark-consult] <https://github.com/oantolin/embark>

[orderless] <https://github.com/oantolin/orderless>

[wgrep] <https://github.com/mhayashi1120/Emacs-wgrep>

[mct by Protesilaos Stavrou] <https://git.sr.ht/~protesilaos/mct>

[list of auxiliary packages]
<https://github.com/minad/consult/wiki/Auxiliary-packages>


5 Bug reports
═════════════

  If you find a bug or suspect that there is a problem with Consult,
  please carry out the following steps:

  1. *Search through the issue tracker* if your issue has been reported
     before (and has been resolved eventually) in the meantime.
  2. *Remove all packages involved in the suspected bug from your
      installation.*
  3. *Reinstall the newest version of all relevant packages*. Updating
     alone is not sufficient, since package.el sometimes causes
     miscompilation. The list of packages includes Consult, Compat,
     Vertico or other completion UIs, Marginalia, Embark and Orderless.
  4. Either use the default completion UI or ensure that exactly one of
     `vertico-mode', `mct-mode', or `icomplete-mode' is enabled. The
     unsupported modes `selectrum-mode', `ivy-mode', `helm-mode',
     `ido-mode' and `ido-ubiquitous-mode' must be disabled.
  5. Ensure that the `completion-styles' variable is properly
     configured. Try to set `completion-styles' to a list including
     `substring' or `orderless'.
  6. Try to reproduce the issue with the newest stable Emacs
     version. Start a bare bone Emacs instance with `emacs -Q' on the
     command line. Execute the following minimal code snippets in the
     scratch buffer. This way we can exclude side effects due to
     configuration settings. If other packages are relevant to reproduce
     the issue, include them in the minimal configuration snippet.

  Minimal setup with Vertico for `emacs -Q':
  ┌────
  │ (package-initialize)
  │ (require 'consult)
  │ (require 'vertico)
  │ (vertico-mode)
  │ (setq completion-styles '(substring basic))
  └────

  Minimal setup with the default completion system for `emacs -Q':
  ┌────
  │ (package-initialize)
  │ (require 'consult)
  │ (setq completion-styles '(substring basic))
  └────

  Please provide the necessary important information with your bug
  report:

  • The minimal configuration snippet used to reproduce the issue.
  • Your completion UI (Default completion, Vertico, Mct or Icomplete).
  • A stack trace in case the bug triggers an exception.
  • Your Emacs version, since bugs may be fixed or introduced in newer
    versions.
  • Your operating system, since Emacs behavior varies subtly between
    Linux, Mac and Windows.
  • The package manager, e.g., straight.el or package.el, used to
    install the Emacs packages, in order to exclude update issues. Did
    you install Consult as part of the Doom Emacs distribution?
  • Do you use Evil? Consult does not provide Evil integration out of
    the box, but there is some support in [evil-collection].

  When evaluating Consult-related code snippets you should enable
  lexical binding.  Consult relies on lambdas and lexical closures.


[evil-collection] <https://github.com/emacs-evil/evil-collection>


6 Hacking
═════════

6.1 Creating simple commands
────────────────────────────

  When creating simple commands you can either use `consult--read' or
  directly rely on the built-in `completing-read'
  function. `consult--read' provides a nicer and more featureful API on
  top of `completing-read'. You can specify the completion candidates
  directly.

  ┌────
  │ (consult--read
  │  '("String A"
  │    "String B"
  │    "String C")
  │  :sort nil
  │  :prompt "Select: ")
  └────

  If you pass it an alist of `(completion-string . value)', you can look
  up the value.

  ┌────
  │ (consult--read
  │  '(("String A" . value-a)
  │    ("String B" . value-b)
  │    ("String C" . value-c))
  │  :prompt "Select: "
  │  :sort nil
  │  :lookup #'consult--lookup-cdr)
  └────

  You can add the result as a text property.

  ┌────
  │ (consult--read
  │  (list
  │   (propertize "String A" 'consult--candidate 'value-a)
  │   (propertize "String B" 'consult--candidate 'value-b)
  │   (propertize "String C" 'consult--candidate 'value-c))
  │  :prompt "Select: "
  │  :sort nil
  │  :lookup #'consult--lookup-candidate)
  └────

  You can add other text properties.

  ┌────
  │ (consult--read
  │  (mapcar (lambda (value)
  │            (propertize
  │             (format "%s %s"
  │                     (propertize "Option" 'face 'font-lock-comment-face)
  │                     value)
  │             'consult--candidate value))
  │          '("A" "B" "C"))
  │  :prompt "Select: "
  │  :sort nil
  │  :lookup #'consult--lookup-candidate)
  └────


6.2 Creating asynchronous completion commands
─────────────────────────────────────────────

  If you have a completion source that's both dynamic and expensive to
  generate, `completing-read' may not be the best choice. Instead,
  `consult--read' serves as a thin wrapper around `completing-read' that
  provides this functionality. For example, consider the following slow
  script that splits its input on space:

  ┌────
  │ #!/usr/bin/env bash
  │ # simulate work
  │ sleep .1
  │ # generate completion candidates
  │ printf "%s\n" "$*" | tr " " "\n" | sort
  └────

  Let's assume this script is callable as `testibus hello world'. To
  have Consult use it for completion, use `consult--process-collection':

  ┌────
  │ (consult--read
  │  (consult--process-collection
  │   (lambda (input) (list "testibus" (string-trim input))))
  │  :prompt "run testibus: ")
  └────

  If the completion candidates are generated by Lisp instead, use
  `consult--dynamic-collection':

  ┌────
  │ (consult--read
  │  (consult--dynamic-collection
  │   (lambda (input)
  │     (sleep-for 0.1) ;; Simulate work
  │     (split-string input nil t)))
  │  :prompt "run testibus: ")
  └────

  `consult--dynamic-collection' can take a function with a callback such
  that the completion UI can update for long running computations.

  ┌────
  │ (consult--read
  │  (consult--dynamic-collection
  │   (lambda (input callback)
  │     (dotimes (i 3)
  │       (sleep-for 0.1) ;; Simulate work
  │       (funcall callback (mapcar (lambda (s) (format "%s%s" s i))
  │                                 (split-string input nil t))))))
  │  :prompt "run testibus: ")
  └────

  The asynchronous completion collections `consult--dynamic-collection'
  and `consult--process-collection' can be used for `consult--multi'
  sources. Specify them as `:async' field of the source plist.


6.3 Live preview
────────────────

  Implementing live preview requires the definition of a state or
  preview function as defined by `consult--with-preview'. The preview
  function receives the candidate and some action to perform (e.g.,
  `'preview'). In its simplest form supporting live preview, it looks
  something like this:

  ┌────
  │ (defun testibus--preview (action cand)
  │   (pcase action
  │     ('preview
  │      (with-current-buffer-window " *testibus*" 'action nil
  │        (erase-buffer)
  │        (insert (format "input: %s\n" cand))))))
  └────

  See the docstring of `consult--with-preview' for the lifecycle of the
  action argument. Once defined, we can use this preview function in
  `consult--read':

  ┌────
  │ (consult--read
  │  (consult--dynamic-collection
  │   (lambda (input callback)
  │     (dotimes (i 3)
  │       (sleep-for 0.1) ;; Simulate work
  │       (funcall callback (mapcar (lambda (s) (format "%s%s" s i))
  │                                 (split-string input nil t))))))
  │  :prompt "run testibus: "
  │  :state #'testibus--preview)
  └────


7 Contributions
═══════════════

  Consult is a community effort, please participate in the discussions.
  Contributions are welcome, but you may want to discuss potential
  contributions first. Since this package is part of [GNU ELPA]
  contributions require a copyright assignment to the FSF.

  If you have a proposal, take a look at the [Consult issue tracker] and
  the [Consult wishlist]. There have been many prior feature
  discussions. Please search through the issue tracker, maybe your issue
  or feature request has already been discussed. You can contribute to
  the [Consult wiki], in case you want to share small configuration or
  command snippets.


[GNU ELPA] <https://elpa.gnu.org/packages/consult.html>

[Consult issue tracker] <https://github.com/minad/consult/issues>

[Consult wishlist] <https://github.com/minad/consult/issues/6>

[Consult wiki] <https://github.com/minad/consult/wiki>


8 Acknowledgments
═════════════════

  This package took inspiration from [Counsel] by Oleh Krehel. Some of
  the Consult commands originated in the Counsel package or the wiki of
  the Selectrum package.  This package exists only thanks to the help of
  these great contributors and thanks to the feedback of many
  users. Thank you!

  Code contributions: [Aymeric Agon-Rambosson], [Amos Bird], [Ashton
  Wiersdorf], [Adam Spiers], [Augusto Stoffel], [Clemens Radermacher],
  [Zhengyi], [Geoffrey Lessel], [Illia Ostapyshyn], [jakanakaevangeli],
  [JD Smith], [Jean-Philippe Bernardy], [mattiasdrp], [Mohamed
  Abdelnour], [Mohsin Kaleem], [Fox Kiester], [Omar Antolín Camarena],
  [Earl Hyatt], [Omar Polo], [Piotr Kwiecinski], [Robert Weiner],
  [Sergey Kostyaev], [Alexandru Scvorțov], [Tecosaur], [Sylvain
  Rousseau], [Tom Fitzhenry], [Iñigo Serna] and [Alex Kreisher].

  Advice and useful discussions: [Enrique Kessler Martínez], [Adam
  Porter], [Bruce d'Arcus], [Clemens Radermacher], [Dmitry Gutov],
  [Howard Melman], [Itai Y. Efrat], [JD Smith], [Manuel Uberti], [Stefan
  Monnier], [Omar Antolín Camarena], [Steve Purcell], [Radon
  Rosborough], [Tom Fitzhenry] and [Protesilaos Stavrou].


[Counsel] <https://github.com/abo-abo/swiper#counsel>

[Aymeric Agon-Rambosson] <https://github.com/aagon>

[Amos Bird] <https://github.com/amosbird>

[Ashton Wiersdorf] <https://github.com/ashton314>

[Adam Spiers] <https://github.com/aspiers>

[Augusto Stoffel] <https://github.com/astoff>

[Clemens Radermacher] <https://github.com/clemera>

[Zhengyi] <https://github.com/fuzy112>

[Geoffrey Lessel] <https://github.com/geolessel>

[Illia Ostapyshyn] <https://github.com/iostapyshyn>

[jakanakaevangeli] <https://github.com/jakanakaevangeli>

[JD Smith] <https://github.com/jdtsmith>

[Jean-Philippe Bernardy] <https://github.com/jyp>

[mattiasdrp] <https://github.com/mattiasdrp>

[Mohamed Abdelnour] <https://github.com/mohamed-abdelnour>

[Mohsin Kaleem] <https://github.com/mohkale>

[Fox Kiester] <https://github.com/noctuid>

[Omar Antolín Camarena] <https://github.com/oantolin>

[Earl Hyatt] <https://github.com/okamsn>

[Omar Polo] <https://github.com/omar-polo>

[Piotr Kwiecinski] <https://github.com/piotrkwiecinski>

[Robert Weiner] <https://github.com/rswgnu>

[Sergey Kostyaev] <https://github.com/s-kostyaev>

[Alexandru Scvorțov] <https://github.com/scvalex>

[Tecosaur] <https://github.com/tecosaur>

[Sylvain Rousseau] <https://github.com/thisirs>

[Tom Fitzhenry] <https://github.com/tomfitzhenry>

[Iñigo Serna] <https://hg.serna.eu>

[Alex Kreisher] <https://github.com/akreisher>

[Enrique Kessler Martínez] <https://github.com/Qkessler>

[Adam Porter] <https://github.com/alphapapa>

[Bruce d'Arcus] <https://github.com/bdarcus>

[Dmitry Gutov] <https://github.com/dgutov>

[Howard Melman] <https://github.com/hmelman>

[Itai Y. Efrat] <https://github.com/iyefrat>

[Manuel Uberti] <https://github.com/manuel-uberti>

[Stefan Monnier] <https://github.com/monnier>

[Steve Purcell] <https://github.com/purcell>

[Radon Rosborough] <https://github.com/raxod502>

[Protesilaos Stavrou] <https://protesilaos.com>


9 Indices
═════════

9.1 Function index
──────────────────


9.2 Concept index
─────────────────
