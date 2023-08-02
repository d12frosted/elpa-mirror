	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		CONSULT.EL - CONSULTING COMPLETING-READ
	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Consult provides search and navigation commands based on the Emacs
completion function [completing-read]. Completion allows you to quickly
select an item from a list of candidates. Consult offers asynchronous
and interactive `consult-grep' and `consult-ripgrep' commands, and the
line-based search command `consult-line'.  Furthermore Consult provides
an advanced buffer switching command `consult-buffer' to switch between
buffers, recently opened files, bookmarks and buffer-like candidates
from other sources. Some of the Consult commands are enhanced versions
of built-in Emacs commands. For example the command `consult-imenu'
presents a flat list of the Imenu with [live preview], [grouping and
narrowing].  Please take a look at the [full list of commands].

Consult is fully compatible with completion systems centered around the
standard Emacs `completing-read' API, notably the default completion
system, [Vertico], [Mct], and [Icomplete].

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
buffer. The section [Embark integration] documents in greater detail how
Consult and Embark work together.

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
.. 3. Fine-tuning
4. Recommended packages
5. Auxiliary packages
6. Bug reports
7. Contributions
8. Acknowledgments
9. Indices
.. 1. Function index
.. 2. Concept index


[completing-read]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Minibuffer-Completion.html>

[live preview] See section 2.1

[grouping and narrowing] See section 2.2

[full list of commands] See section 1

[Vertico] <https://github.com/minad/vertico>

[Mct] <https://github.com/protesilaos/mct>

[Icomplete]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Icomplete.html>

[Marginalia] <https://github.com/minad/marginalia/>

[Embark] <https://github.com/oantolin/embark/>

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

  • `consult-buffer' (`-other-window', `-other-frame'): Enhanced version
    of `switch-to-buffer' with support for virtual buffers. Supports
    live preview of buffers and narrowing to the virtual buffer
    types. You can type `f SPC' in order to narrow to recent
    files. Press `SPC' to show ephemeral buffers.  Supported narrowing
    keys:
    • b Buffers
    • SPC Hidden buffers
    • * Modified buffers
    • f Files (Requires `recentf-mode')
    • r File registers
    • m Bookmarks
    • p Project
    • Custom [other sources] configured in `consult-buffer-sources'.
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
    function for an enhanced register formatting. See the [example
    configuration].
  • `consult-register-window': Replace `register-preview' with this
    function for a better register window. See the [example
    configuration].
  • `consult-register-load': Utility command to quickly load a register.
    The command either jumps to the register value or inserts it.
  • `consult-register-store': Improved UI to store registers depending
    on the current context with an action menu. With an active region,
    store/append/prepend the contents, optionally deleting the region
    when a prefix argument is given.  With a numeric prefix argument,
    store/add the number. Otherwise store point, frameset, window or
    kmacro. Usage examples:
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
    completion style like orderless. `consult-grep' supports preview. If
    the `consult-project-function' returns non-nil, `consult-grep'
    searches the current project directory.  Otherwise the
    `default-directory' is searched. If `consult-grep' is invoked with
    prefix argument `C-u M-s g', you can specify one or more
    comma-separated files and directories manually.
  • `consult-find', `consult-locate': Find file by matching the path
    against a regexp.  Like for `consult-grep', either the project root
    or the current directory is the root directory for the search. The
    input string is treated similarly to `consult-grep', where the first
    part is passed to find, and the second part is used for Emacs
    filtering.  Prefix arguments to `consult-find' work just like those
    for the consult grep commands.


1.7 Compilation
───────────────

  • `consult-compile-error': Jump to a compilation error. Supports live
    preview narrowing and recursive editing.
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

  • `consult-org-heading': Similar to `consult-outline', for Org
    buffers. Supports narrowing by heading level, priority and TODO
    state, as well as live preview and recursive editing.
  • `consult-org-agenda': Jump to an agenda heading. Supports narrowing
    by heading level, priority and TODO state, as well as live preview
    and recursive editing.


1.11 Help
─────────

  • `consult-man': Find Unix man page, via Unix `apropos' or `man
    -k'. `consult-man' opens the selected man page using the Emacs `man'
    command.
  • `consult-info': Full text search through info pages. If the command
    is invoked from within an `*info*' buffer, it will search through
    the current manual. You may want to create your own commands which
    search through a predefined set of info pages, for example:
  ┌────
  │ (defun consult-info-emacs ()
  │   "Search through Emacs info pages."
  │   (interactive)
  │   (consult-info "emacs" "efaq" "elisp" "cl" "compat"))
  │ 
  │ (defun consult-info-org ()
  │   "Search through the Org info page."
  │   (interactive)
  │   (consult-info "org"))
  │ 
  │ (defun consult-info-completion ()
  │   "Search through completion info pages."
  │   (interactive)
  │   (consult-info "vertico" "consult" "marginalia" "orderless" "embark"
  │ 		"corfu" "cape" "tempel"))
  └────


1.12 Miscellaneous
──────────────────

  • `consult-theme': Select a theme and disable all currently enabled
    themes.  Supports live preview of the theme while scrolling through
    the candidates.
  • `consult-preview-at-point' and `consult-preview-at-point-mode':
    Command and minor mode which previews the candidate at point in the
    `*Completions*' buffer. This mode is relevant if you use [Mct] or
    the default `*Completions*' UI.
  • `consult-completion-in-region': In case you don't use [Corfu] as
    your in-buffer completion UI, this function can be set as
    `completion-in-region-function'. Then your minibuffer completion UI
    (e.g., Vertico or Icomplete) will be used for `completion-at-point'.
    ┌────
    │ ;; Use `consult-completion-in-region' if Vertico is enabled.
    │ ;; Otherwise use the default `completion--in-region' function.
    │ (setq completion-in-region-function
    │       (lambda (&rest args)
    │ 	(apply (if vertico-mode
    │ 		   #'consult-completion-in-region
    │ 		 #'completion--in-region)
    │ 	       args)))
    └────
    Instead of `consult-completion-in-region', you may prefer to see the
    completions directly in the buffer as a small popup. In that case, I
    recommend either the [Corfu] or the [Company] package. There is a
    technical limitation of `consult-completion-in-region' in
    combination with Lsp-mode or Eglot. The Lsp server relies on the
    input at point, in order to generate refined candidate
    strings. Since the completion is transferred from the original
    buffer to the minibuffer, the server does not receive the updated
    input. LSP completion works with Corfu or Company though, which
    perform the completion directly in the original buffer.


[Mct] <https://git.sr.ht/~protesilaos/mct>

[Corfu] <https://github.com/minad/corfu>

[Company] <https://github.com/company-mode/company-mode>


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
  │  consult-ripgrep consult-git-grep consult-grep
  │  consult-bookmark consult-recent-file consult-xref
  │  consult--source-bookmark consult--source-file-register
  │  consult--source-recent-file consult--source-project-recent-file
  │  ;; my/command-wrapping-consult    ;; disable auto previews inside my command
  │  :preview-key '(:debounce 0.4 any) ;; Option 1: Delay preview
  │  ;; :preview-key "M-.")            ;; Option 2: Manual preview
  └────

  In this case one may wonder what the difference is between using an
  Embark action on the current candidate in comparison to a manually
  triggered preview.  The main difference is that the files opened by
  manual preview are closed again after the completion session. During
  preview some functionality is disabled to improve the performance, see
  for example the customization variables `consult-preview-variables'
  and `consult-preview-allowed-hooks'. Only the hooks listed in
  `consult-preview-allowed-hooks' are executed when a file is opened
  (`find-file-hook'). In order to enable additional font locking during
  preview, add the corresponding hooks to the allow list. The following
  code demonstrates this for [org-modern] and [hl-todo].

  ┌────
  │ (add-to-list 'consult-preview-allowed-hooks 'global-org-modern-mode-check-buffers)
  │ (add-to-list 'consult-preview-allowed-hooks 'global-hl-todo-mode-check-buffers)
  └────

  Files larger than `consult-preview-raw-size' are previewed literally
  without syntax highlighting and without changing the major
  mode. Delaying the preview is also useful for `consult-theme', since
  the theme preview is slow. The delay results in a smoother UI
  experience.

  ┌────
  │ ;; Preview on any key press, but delay 0.5s
  │ (consult-customize consult-theme :preview-key '(:debounce 0.5 any))
  │ ;; Preview immediately on M-., on up/down after 0.5s, on any other key after 1s
  │ (consult-customize consult-theme
  │ 		   :preview-key
  │ 		   '("M-."
  │ 		     :debounce 0.5 "<up>" "<down>"
  │ 		     :debounce 1 any))
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
  • `#defun -- --invert-match#': Pass argument `--invert-match' to grep.

  Asynchronous processes like `find' and `grep' create an error log
  buffer `_*consult-async*' (note the leading space), which is useful
  for troubleshooting. The prompt has a small indicator showing the
  process status:

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

  Multiple synchronous candidate sources can be combined. This feature
  is used by the `consult-buffer' command to present buffer-like
  candidates in a single menu for quick access. By default
  `consult-buffer' includes buffers, bookmarks, recent files and
  project-specific buffers and files. It is possible to configure the
  list of sources via the `consult-buffer-sources' variable. Arbitrary
  custom sources can be defined.

  As an example, the bookmark source is defined as follows:

  ┌────
  │ (defvar consult--source-bookmark
  │   `(:name     "Bookmark"
  │     :narrow   ?m
  │     :category bookmark
  │     :face     consult-bookmark
  │     :history  bookmark-history
  │     :items    ,#'bookmark-all-names
  │     :action   ,#'consult--bookmark-action))
  └────

  Required source fields:
  • `:category' Completion category.
  • `:items' List of strings to select from or function returning list
    of strings.  A list of cons cells is not supported.

  Optional source fields:
  • `:name' Name of the source, used for narrowing, group titles and
    annotations.
  • `:narrow' Narrowing character or `(character . string)' pair.
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
  │  consult--source-bookmark consult--source-file-register
  │  consult--source-recent-file consult--source-project-recent-file
  │  :preview-key "M-.")
  └────

  Sources can be added directly to the `consult-buffer-source' list for
  convenience.  For example views/perspectives can be added to the list
  of virtual buffers from a library like [bookmark-view].

  ┌────
  │ ;; Configure new bookmark-view source
  │ (add-to-list 'consult-buffer-sources
  │ 	      (list :name     "View"
  │ 		    :narrow   ?v
  │ 		    :category 'bookmark
  │ 		    :face     'font-lock-keyword-face
  │ 		    :history  'bookmark-view-history
  │ 		    :action   #'consult--bookmark-action
  │ 		    :items    #'bookmark-view-names)
  │ 	      'append)
  │ 
  │ ;; Modify bookmark source, such that views are hidden
  │ (setq consult--source-bookmark
  │       (plist-put
  │        consult--source-bookmark :items
  │        (lambda ()
  │ 	 (bookmark-maybe-load-default-file)
  │ 	 (mapcar #'car
  │ 		 (seq-remove (lambda (x)
  │ 			       (eq #'bookmark-view-handler
  │ 				   (alist-get 'handler (cdr x))))
  │ 			     bookmark-alist)))))
  └────

  Another useful source lists all Org buffers and lets you create new
  ones. One can create similar sources for other major modes, e.g., for
  Eshell.

  ┌────
  │ (defvar org-source
  │   (list :name     "Org Buffer"
  │ 	:category 'buffer
  │ 	:narrow   ?o
  │ 	:face     'consult-buffer
  │ 	:history  'buffer-name-history
  │ 	:state    #'consult--buffer-state
  │ 	:new
  │ 	(lambda (name)
  │ 	  (with-current-buffer (get-buffer-create name)
  │ 	    (insert "#+title: " name "\n\n")
  │ 	    (org-mode)
  │ 	    (consult--buffer-action (current-buffer))))
  │ 	:items
  │ 	(lambda ()
  │ 	  (mapcar #'buffer-name
  │ 		  (seq-filter
  │ 		   (lambda (x)
  │ 		     (eq (buffer-local-value 'major-mode x) 'org-mode))
  │ 		   (buffer-list))))))
  │ 
  │ (add-to-list 'consult-buffer-sources 'org-source 'append)
  └────

  For more details, see the documentation of `consult-buffer' and of the
  internal `consult--multi' API. The `consult--multi' function can be
  used to create new multi-source commands, but is part of the internal
  API as of now, since some details may still change.


[bookmark-view] <https://github.com/minad/bookmark-view/>


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
  can be edited, if the [wgrep] package is installed. These three
  workflows are symmetric.

  ⁃ `consult-line' -> `embark-export' to `occur-mode' buffer ->
    `occur-edit-mode' for editing of matches in buffer.
  ⁃ `consult-grep' -> `embark-export' to `grep-mode' buffer -> `wgrep'
    for editing of all matches.
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

  *IMPORTANT:* It is strongly recommended that you enable [lexical
  binding] in your configuration. Consult relies on lambdas and lexical
  closures. For this reason many Consult-related snippets require
  lexical binding.


[ELPA] <https://elpa.gnu.org/packages/consult.html>

[MELPA] <https://melpa.org/#/consult>

[Consult wiki] <https://github.com/minad/consult/wiki>

[lexical binding]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Lexical-Binding.html>

3.1 Use-package example
───────────────────────

  The Consult package only provides commands and does not add any
  keybindings or modes. Therefore the package is non-intrusive but
  requires a little setup effort. In order to use the Consult commands,
  it is advised to add keybindings for commands which are accessed
  often. Rarely used commands can be invoked via `M-x'. Feel free to
  only bind the commands you consider useful to your workflow.  The
  configuration shown here relies on the `use-package' macro, which is a
  convenient tool to manage package configurations.

  *NOTE:* There is the [Consult wiki], where you can contribute
  additional configuration examples.

  ┌────
  │ ;; Example configuration for Consult
  │ (use-package consult
  │   ;; Replace bindings. Lazily loaded due by `use-package'.
  │   :bind (;; C-c bindings in `mode-specific-map'
  │ 	 ("C-c M-x" . consult-mode-command)
  │ 	 ("C-c h" . consult-history)
  │ 	 ("C-c k" . consult-kmacro)
  │ 	 ("C-c m" . consult-man)
  │ 	 ("C-c i" . consult-info)
  │ 	 ([remap Info-search] . consult-info)
  │ 	 ;; C-x bindings in `ctl-x-map'
  │ 	 ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
  │ 	 ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
  │ 	 ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
  │ 	 ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
  │ 	 ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
  │ 	 ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
  │ 	 ;; Custom M-# bindings for fast register access
  │ 	 ("M-#" . consult-register-load)
  │ 	 ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
  │ 	 ("C-M-#" . consult-register)
  │ 	 ;; Other custom bindings
  │ 	 ("M-y" . consult-yank-pop)                ;; orig. yank-pop
  │ 	 ;; M-g bindings in `goto-map'
  │ 	 ("M-g e" . consult-compile-error)
  │ 	 ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
  │ 	 ("M-g g" . consult-goto-line)             ;; orig. goto-line
  │ 	 ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
  │ 	 ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
  │ 	 ("M-g m" . consult-mark)
  │ 	 ("M-g k" . consult-global-mark)
  │ 	 ("M-g i" . consult-imenu)
  │ 	 ("M-g I" . consult-imenu-multi)
  │ 	 ;; M-s bindings in `search-map'
  │ 	 ("M-s d" . consult-find)
  │ 	 ("M-s D" . consult-locate)
  │ 	 ("M-s g" . consult-grep)
  │ 	 ("M-s G" . consult-git-grep)
  │ 	 ("M-s r" . consult-ripgrep)
  │ 	 ("M-s l" . consult-line)
  │ 	 ("M-s L" . consult-line-multi)
  │ 	 ("M-s k" . consult-keep-lines)
  │ 	 ("M-s u" . consult-focus-lines)
  │ 	 ;; Isearch integration
  │ 	 ("M-s e" . consult-isearch-history)
  │ 	 :map isearch-mode-map
  │ 	 ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
  │ 	 ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
  │ 	 ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
  │ 	 ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
  │ 	 ;; Minibuffer history
  │ 	 :map minibuffer-local-map
  │ 	 ("M-s" . consult-history)                 ;; orig. next-matching-history-element
  │ 	 ("M-r" . consult-history))                ;; orig. previous-matching-history-element
  │ 
  │   ;; Enable automatic preview at point in the *Completions* buffer. This is
  │   ;; relevant when you use the default completion UI.
  │   :hook (completion-list-mode . consult-preview-at-point-mode)
  │ 
  │   ;; The :init configuration is always executed (Not lazy)
  │   :init
  │ 
  │   ;; Optionally configure the register formatting. This improves the register
  │   ;; preview for `consult-register', `consult-register-load',
  │   ;; `consult-register-store' and the Emacs built-ins.
  │   (setq register-preview-delay 0.5
  │ 	register-preview-function #'consult-register-format)
  │ 
  │   ;; Optionally tweak the register preview window.
  │   ;; This adds thin lines, sorting and hides the mode line of the window.
  │   (advice-add #'register-preview :override #'consult-register-window)
  │ 
  │   ;; Use Consult to select xref locations with preview
  │   (setq xref-show-xrefs-function #'consult-xref
  │ 	xref-show-definitions-function #'consult-xref)
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
  │    consult-ripgrep consult-git-grep consult-grep
  │    consult-bookmark consult-recent-file consult-xref
  │    consult--source-bookmark consult--source-file-register
  │    consult--source-recent-file consult--source-project-recent-file
  │    ;; :preview-key "M-."
  │    :preview-key '(:debounce 0.4 any))
  │ 
  │   ;; Optionally configure the narrowing key.
  │   ;; Both < and C-+ work reasonably well.
  │   (setq consult-narrow-key "<") ;; "C-+"
  │ 
  │   ;; Optionally make narrowing help available in the minibuffer.
  │   ;; You may want to use `embark-prefix-help-command' or which-key instead.
  │   ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)
  │ 
  │   ;; By default `consult-project-function' uses `project-root' from project.el.
  │   ;; Optionally configure a different project root function.
  │   ;;;; 1. project.el (the default)
  │   ;; (setq consult-project-function #'consult--default-project--function)
  │   ;;;; 2. vc.el (vc-root-dir)
  │   ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
  │   ;;;; 3. locate-dominating-file
  │   ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
  │   ;;;; 4. projectile.el (projectile-project-root)
  │   ;; (autoload 'projectile-project-root "projectile")
  │   ;; (setq consult-project-function (lambda (_) (projectile-project-root)))
  │   ;;;; 5. No project support
  │   ;; (setq consult-project-function nil)
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

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Variable                          Description                                           
  ─────────────────────────────────────────────────────────────────────────────────────────
   consult-after-jump-hook           Functions to call after jumping to a location         
   consult-async-input-debounce      Input debounce for asynchronous commands              
   consult-async-input-throttle      Input throttle for asynchronous commands              
   consult-async-min-input           Minimum numbers of letters needed for async process   
   consult-async-refresh-delay       Refresh delay for asynchronous commands               
   consult-async-split-style         Splitting style used for async commands               
   consult-async-split-styles-alist  Available splitting styles used for async commands    
   consult-bookmark-narrow           Narrowing configuration for `consult-bookmark'        
   consult-buffer-filter             Filter for `consult-buffer'                           
   consult-buffer-sources            List of virtual buffer sources                        
   consult-find-args                 Command line arguments for find                       
   consult-fontify-max-size          Buffers larger than this limit are not fontified      
   consult-fontify-preserve          Preserve fontification for line-based commands.       
   consult-git-grep-args             Command line arguments for git-grep                   
   consult-goto-line-numbers         Show line numbers for `consult-goto-line'             
   consult-grep-max-columns          Maximal number of columns of the matching lines       
   consult-grep-args                 Command line arguments for grep                       
   consult-imenu-config              Mode-specific configuration for `consult-imenu'       
   consult-line-numbers-widen        Show absolute line numbers when narrowing is active.  
   consult-line-start-from-top       Start the `consult-line' search from the top          
   consult-locate-args               Command line arguments for locate                     
   consult-man-args                  Command line arguments for man                        
   consult-mode-command-filter       Filter for `consult-mode-command'                     
   consult-mode-histories            Mode-specific history variables                       
   consult-narrow-key                Narrowing prefix key during completion                
   consult-point-placement           Placement of the point when jumping to matches        
   consult-preview-key               Keys which triggers preview                           
   consult-preview-allowed-hooks     List of `find-file' hooks to enable during preview    
   consult-preview-excluded-files    Regexps matched against file names during preview     
   consult-preview-max-count         Maximum number of files to keep open during preview   
   consult-preview-max-size          Files larger than this size are not previewed         
   consult-preview-raw-size          Files larger than this size are previewed in raw form 
   consult-preview-variables         Alist of variables to bind during preview             
   consult-project-buffer-sources    List of virtual project buffer sources                
   consult-project-function          Function which returns current project root           
   consult-register-prefix           Prefix string for register keys during completion     
   consult-ripgrep-args              Command line arguments for ripgrep                    
   consult-themes                    List of themes to be presented for selection          
   consult-widen-key                 Widening key during completion                        
   consult-yank-rotate               Rotate kill ring                                      
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[Marginalia] <https://github.com/minad/marginalia>


3.3 Fine-tuning of individual commands
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

  There exist many other fine completion UIs beside Vertico, which are
  supported by Consult. Give them a try and find out which interaction
  model fits best for you.

  • The builtin completion UI, which pops up the `*Completions*' buffer.
  • The builtin `icomplete-vertical-mode' in Emacs 28.
  • [mct by Protesilaos Stavrou]: Minibuffer and Completions in Tandem,
    which builds on the default completion UI (development currently
    [discontinued]).

  Note that all packages are independent and can be exchanged with
  alternative components, since there exist no hard
  dependencies. Furthermore it is possible to get started with only
  default completion and Consult and add more components later to the
  mix. For example you can omit Marginalia if you don't need
  annotations. I highly recommend the Embark package, but in order to
  familiarize yourself with the other components, you can first start
  without it - or you could use with Embark right away and add the other
  components later on.


[vertico] <https://github.com/minad/vertico>

[marginalia] <https://github.com/minad/marginalia>

[embark and embark-consult] <https://github.com/oantolin/embark>

[orderless] <https://github.com/oantolin/orderless>

[mct by Protesilaos Stavrou] <https://git.sr.ht/~protesilaos/mct>

[discontinued]
<https://protesilaos.com/codelog/2022-04-14-emacs-discontinue-mct/>


5 Auxiliary packages
════════════════════

  You can integrate Consult with special programs or with other packages
  in the wider Emacs ecosystem. You may want to install some of theses
  packages depending on your preferences and requirements.

  • [consult-ag]: Support for the [Silver Searcher] in the style of
    `consult-grep'.
  • [consult-codesearch]: Integration with [Code Search].
  • [consult-company]: Completion at point using the [Company] backends.
  • [consult-compile-multi]: Integration with [compile-multi].
  • [consult-dir]: Directory jumper using Consult multi sources.
  • [consult-dash]: Consult interface to [Dash documentation]
  • [consult-eglot]: Integration with Eglot (LSP client).
  • [consult-flycheck]: Additional Flycheck integration.
  • [consult-flyspell]: Additional Flyspell integration.
  • [consult-git-log-grep]: Consult interface to git log.
  • [consult-hatena-bookmark]: Access Hatena bookmarks.
  • [consult-ls-git]: List files from git via Consult.
  • [consult-lsp]: Integration with Lsp-mode (LSP client).
  • [consult-notmuch]: Access the [Notmuch] email system using Consult.
  • [consult-notes]: Searching notes with Consult.
  • [consult-org-roam]: Integration with [Org-roam].
  • [consult-project-extra]: Additional project.el extras and buffer
    sources.
  • [consult-projectile]: Additional [Projectile] integration and buffer
    sources.
  • [consult-recoll]: Access the [Recoll] desktop full-text search using
    Consult.
  • [consult-spotify]: Access the Spotify API and control your local
    music player.
  • [consult-yasnippet]: Integration with Yasnippet.
  • [affe]: Asynchronous Fuzzy Finder for Emacs based on Consult.

  Not directly related to Consult, but maybe still of interest are the
  following packages. These packages should work well with Consult,
  follow a similar spirit or offer functionality based on
  `completing-read'.

  • [corfu]: Completion systems for `completion-at-point' using small
    popups (Alternative to [Company]).
  • [cape]: Completion At Point Extensions, which can be used with
    `consult-completion-in-region' and [Corfu].
  • [bookmark-view]: Store window configuration as bookmarks, possible
    integration with `consult-buffer'.
  • [citar]: Versatile package for citation insertion and bibliography
    management.
  • [devdocs]: Emacs viewer for [DevDocs] with a convenient completion
    interface.
  • [flyspell-correct]: Apply spelling corrections by selecting via
    `completing-read'.
  • [wgrep]: Editing of grep buffers, use together with `consult-grep'
    via `embark-export'.
  • [all-the-icons-completion], [nerd-icons-completion]: Icons for the
    completion UI.


[consult-ag] <https://github.com/yadex205/consult-ag>

[Silver Searcher] <https://github.com/ggreer/the_silver_searcher>

[consult-codesearch] <https://github.com/youngker/consult-codesearch.el>

[Code Search] <https://github.com/google/codesearch>

[consult-company] <https://github.com/mohkale/consult-company>

[Company] <https://github.com/company-mode/company-mode>

[consult-compile-multi]
<https://github.com/mohkale/consult-compile-multi>

[compile-multi] <https://github.com/mohkale/compile-multi>

[consult-dir] <https://github.com/karthink/consult-dir>

[consult-dash] <https://codeberg.org/ravi/consult-dash>

[Dash documentation] <https://github.com/dash-docs-el/dash-docs>

[consult-eglot] <https://github.com/mohkale/consult-eglot>

[consult-flycheck] <https://github.com/minad/consult-flycheck>

[consult-flyspell] <https://gitlab.com/OlMon/consult-flyspell>

[consult-git-log-grep]
<https://github.com/ghosty141/consult-git-log-grep>

[consult-hatena-bookmark]
<https://github.com/Nyoho/consult-hatena-bookmark>

[consult-ls-git] <https://github.com/rcj/consult-ls-git>

[consult-lsp] <https://github.com/gagbo/consult-lsp>

[consult-notmuch] <https://codeberg.org/jao/consult-notmuch>

[Notmuch] <https://notmuchmail.org/>

[consult-notes] <https://github.com/mclear-tools/consult-notes>

[consult-org-roam] <https://github.com/jgru/consult-org-roam>

[Org-roam] <https://github.com/org-roam/org-roam>

[consult-project-extra]
<https://github.com/Qkessler/consult-project-extra/>

[consult-projectile] <https://gitlab.com/OlMon/consult-projectile/>

[Projectile] <https://github.com/bbatsov/projectile>

[consult-recoll] <https://codeberg.org/jao/consult-recoll>

[Recoll] <https://www.lesbonscomptes.com/recoll/>

[consult-spotify] <https://codeberg.org/jao/espotify>

[consult-yasnippet] <https://github.com/mohkale/consult-yasnippet>

[affe] <https://github.com/minad/affe>

[corfu] <https://github.com/minad/corfu>

[cape] <https://github.com/minad/cape>

[Corfu] <https://github.com/minad/corfu>

[bookmark-view] <https://github.com/minad/bookmark-view>

[citar] <https://github.com/bdarcus/citar>

[devdocs] <https://github.com/astoff/devdocs.el>

[DevDocs] <https://devdocs.io/>

[flyspell-correct] <https://github.com/d12frosted/flyspell-correct>

[wgrep] <https://github.com/mhayashi1120/Emacs-wgrep>

[all-the-icons-completion]
<https://github.com/iyefrat/all-the-icons-completion>

[nerd-icons-completion]
<https://github.com/rainstormstudio/nerd-icons-completion>


6 Bug reports
═════════════

  If you find a bug or suspect that there is a problem with Consult,
  please carry out the following steps:

  1. *Search through the issue tracker* if your issue has been reported
     before (and has been resolved eventually) in the meantime.
  2. *Remove all packages involved in the suspected bug from your
      installation.*
  3. *Reinstall the newest version of all relevant packages*. Updating
     alone is not sufficient, since package.el is known to cause
     miscompilation. The list of packages includes Consult, Compat,
     Vertico or other completion UIs, Marginalia, Embark and Orderless.
  4. Either use the default completion UI or ensure that exactly one of
     `vertico-mode', `mct-mode', or `icomplete-mode' is enabled. The
     unsupported modes `selectrum-mode', `ivy-mode', `helm-mode',
     `ido-mode' and `ido-ubiquitous-mode' must be disabled.
  5. Ensure that the `completion-styles' variable is properly
     configured. Try to set `completion-styles' to a list including
     `substring' or `orderless'.
  6. Try to reproduce the issue by starting a bare bone Emacs instance
     with `emacs -Q' on the command line. Execute the following minimal
     code snippets in the scratch buffer. This way we can exclude side
     effects due to configuration settings. If other packages are
     relevant to reproduce the issue, include them in the minimal
     configuration snippet.

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
  • Your operating system, since Emacs behavior varies between Linux,
    Mac and Windows.
  • The package manager, e.g., straight.el or package.el, used to
    install the Emacs packages, in order to exclude update issues. Did
    you install Consult as part of the Doom or Spacemacs Emacs
    distributions?
  • Do you use Evil or other packages which apply deep changes?  Consult
    does not provide Evil integration out of the box, but there is some
    support in [evil-collection].

  When evaluating Consult-related code snippets you should enable
  [lexical binding].  Consult often relies on lambdas and lexical
  closures.


[evil-collection] <https://github.com/emacs-evil/evil-collection>

[lexical binding]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Lexical-Binding.html>


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

[Consult issue tracker] <https://github.com/consult/issues>

[Consult wishlist] <https://github.com/minad/consult/issues/6>

[Consult wiki] <https://github.com/minad/consult/wiki>


8 Acknowledgments
═════════════════

  This package took inspiration from [Counsel] by Oleh Krehel. Some of
  the Consult commands originated in the Counsel package or the wiki of
  the Selectrum package.  This package exists only thanks to the help of
  these great contributors and thanks to the feedback of many
  users. Thank you!

  Code contributions:
  • [Omar Antolín Camarena]
  • [Sergey Kostyaev]
  • [Earl Hyatt]
  • [Clemens Radermacher]
  • [Tom Fitzhenry]
  • [jakanakaevangeli]
  • [Iñigo Serna]
  • [Adam Spiers]
  • [Omar Polo]
  • [Augusto Stoffel]
  • [Fox Kiester]
  • [Tecosaur]
  • [Mohamed Abdelnour]
  • [Sylvain Rousseau]
  • [J.D. Smith]
  • [Mohsin Kaleem]
  • [Jean-Philippe Bernardy]
  • [Aymeric Agon-Rambosson]
  • [Geoffrey Lessel]
  • [Piotr Kwiecinski]
  • [Robert Weiner]

  Advice and useful discussions:
  • [Clemens Radermacher]
  • [Omar Antolín Camarena]
  • [Protesilaos Stavrou]
  • [Steve Purcell]
  • [Adam Porter]
  • [Manuel Uberti]
  • [Tom Fitzhenry]
  • [Howard Melman]
  • [Stefan Monnier]
  • [Dmitry Gutov]
  • [Itai Y. Efrat]
  • [Bruce d'Arcus]
  • [J.D. Smith]
  • [Enrique Kessler Martínez]
  • [Radon Rosborough]

  Authors of supplementary `consult-*' packages:

  • [Jose A Ortega Ruiz] ([consult-notmuch], [consult-recoll],
    [consult-spotify])
  • [Gerry Agbobada] ([consult-lsp])
  • [Karthik Chikmagalur] ([consult-dir])
  • [Mohsin Kaleem] ([consult-company], [consult-compile-multi],
    [consult-eglot], [consult-yasnippet])
  • [Marco Pawłowski] ([consult-flyspell], [consult-projectile])
  • [Enrique Kessler Martínez] ([consult-project-extra])
  • [Jan Gru] ([consult-org-roam])
  • [Kanon Kakuno] ([consult-ag])
  • [Robin Joy] ([consult-ls-git])
  • [Ravi R Kiran] [(consult-dash])
  • [Colin McLear] ([consult-notes])
  • [Yukinori Kitadai] ([consult-hatena-bookmark])
  • [ghosty141] ([consult-git-log-grep])
  • [YoungJoo Lee] ([consult-codesearch])


[Counsel] <https://github.com/abo-abo/swiper#counsel>

[Omar Antolín Camarena] <https://github.com/oantolin/>

[Sergey Kostyaev] <https://github.com/s-kostyaev/>

[Earl Hyatt] <https://github.com/okamsn/>

[Clemens Radermacher] <https://github.com/clemera/>

[Tom Fitzhenry] <https://github.com/tomfitzhenry/>

[jakanakaevangeli] <https://github.com/jakanakaevangeli>

[Iñigo Serna] <https://hg.serna.eu>

[Adam Spiers] <https://github.com/aspiers/>

[Omar Polo] <https://github.com/omar-polo>

[Augusto Stoffel] <https://github.com/astoff>

[Fox Kiester] <https://github.com/noctuid>

[Tecosaur] <https://github.com/tecosaur>

[Mohamed Abdelnour] <https://github.com/mohamed-abdelnour>

[Sylvain Rousseau] <https://github.com/thisirs>

[J.D. Smith] <https://github.com/jdtsmith>

[Mohsin Kaleem] <https://github.com/mohkale>

[Jean-Philippe Bernardy] <https://github.com/jyp>

[Aymeric Agon-Rambosson] <https://github.com/aagon>

[Geoffrey Lessel] <https://github.com/geolessel>

[Piotr Kwiecinski] <https://github.com/piotrkwiecinski>

[Robert Weiner] <https://github.com/rswgnu>

[Protesilaos Stavrou] <https://protesilaos.com>

[Steve Purcell] <https://github.com/purcell/>

[Adam Porter] <https://github.com/alphapapa/>

[Manuel Uberti] <https://github.com/manuel-uberti/>

[Howard Melman] <https://github.com/hmelman/>

[Stefan Monnier] <https://github.com/monnier/>

[Dmitry Gutov] <https://github.com/dgutov/>

[Itai Y. Efrat] <https://github.com/iyefrat>

[Bruce d'Arcus] <https://github.com/bdarcus>

[Enrique Kessler Martínez] <https://github.com/Qkessler>

[Radon Rosborough] <https://github.com/raxod502>

[Jose A Ortega Ruiz] <https://codeberg.org/jao/>

[consult-notmuch] <https://codeberg.org/jao/consult-notmuch>

[consult-recoll] <https://codeberg.org/jao/consult-recoll>

[consult-spotify] <https://codeberg.org/jao/espotify>

[Gerry Agbobada] <https://github.com/gagbo/>

[consult-lsp] <https://github.com/gagbo/consult-lsp>

[Karthik Chikmagalur] <https://github.com/karthink>

[consult-dir] <https://github.com/karthink/consult-dir>

[consult-company] <https://github.com/mohkale/consult-company>

[consult-compile-multi]
<https://github.com/mohkale/consult-compile-multi>

[consult-eglot] <https://github.com/mohkale/consult-eglot>

[consult-yasnippet] <https://github.com/mohkale/consult-yasnippet>

[Marco Pawłowski] <https://gitlab.com/OlMon>

[consult-flyspell] <https://gitlab.com/OlMon/consult-flyspell>

[consult-projectile] <https://gitlab.com/OlMon/consult-projectile>

[consult-project-extra]
<https://github.com/Qkessler/consult-project-extra>

[Jan Gru] <https://github.com/jgru>

[consult-org-roam] <https://github.com/jgru/consult-org-roam>

[Kanon Kakuno] <https://github.com/yadex205>

[consult-ag] <https://github.com/yadex205/consult-ag>

[Robin Joy] <https://github.com/rcj>

[consult-ls-git] <https://github.com/rcj/consult-ls-git>

[Ravi R Kiran] <https://codeberg.org/ravi>

[(consult-dash] <https://codeberg.org/ravi/consult-dash>

[Colin McLear] <https://github.com/mclearc>

[consult-notes] <https://github.com/mclear-tools/consult-notes>

[Yukinori Kitadai] <https://github.com/Nyoho>

[consult-hatena-bookmark]
<https://github.com/Nyoho/consult-hatena-bookmark>

[ghosty141] <https://github.com/ghosty141>

[consult-git-log-grep]
<https://github.com/ghosty141/consult-git-log-grep>

[YoungJoo Lee] <https://github.com/youngker>

[consult-codesearch] <https://github.com/youngker/consult-codesearch.el>


9 Indices
═════════

9.1 Function index
──────────────────


9.2 Concept index
─────────────────
