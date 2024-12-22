                 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  CAPE.EL - LET YOUR COMPLETIONS FLY!
                 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Cape provides Completion At Point Extensions which can be used in
combination with [Corfu], [Company] or the default completion UI. The
completion backends used by `completion-at-point' are so called
`completion-at-point-functions' (Capfs).

You can register the `cape-*' functions in the
`completion-at-point-functions' list.  This makes the backends available
for completion, which is usually invoked by pressing `TAB' or
`M-TAB'. The functions can also be invoked interactively to trigger the
respective completion at point. You can bind them directly to a key in
your user configuration. Notable commands/Capfs are `cape-line' for
completion of a line from the current buffer, `cape-history' for history
completion in shell or Comint modes and `cape-file' for completion of
file names. The commands `cape-elisp-symbol' and `cape-elisp-block' are
useful for documentation of Elisp packages or configurations, since they
complete Elisp anywhere.

Cape has the super power to transform Company backends into Capfs and
merge multiple Capfs into a Super-Capf! These transformers allow you to
still take advantage of Company backends even if you are not using
Company as frontend.

Table of Contents
─────────────────

1. Available Capfs
2. Configuration
3. CAPF adapters and transformers
.. 1. Company adapter
.. 2. Super-Capf - Merging multiple Capfs
.. 3. Capf-Buster - Cache busting
.. 4. Capf transformers
4. Contributions


[Corfu] <https://github.com/minad/corfu>

[Company] <https://github.com/company-mode/company-mode>


1 Available Capfs
═════════════════

  ⁃ `cape-abbrev': Complete abbreviation (`add-global-abbrev',
    `add-mode-abbrev').
  ⁃ `cape-dabbrev': Complete word from current buffers. See also
    `dabbrev-capf' on Emacs 29.
  ⁃ `cape-dict': Complete word from dictionary file.
  ⁃ `cape-elisp-block': Complete Elisp in Org or Markdown code block.
  ⁃ `cape-elisp-symbol': Complete Elisp symbol.
  ⁃ `cape-emoji': Complete Emoji. Available on Emacs 29 and newer.
  ⁃ `cape-file': Complete file name.
  ⁃ `cape-history': Complete from Eshell, Comint or minibuffer history.
  ⁃ `cape-keyword': Complete programming language keyword.
  ⁃ `cape-line': Complete entire line from current buffer.
  ⁃ `cape-rfc1345': Complete Unicode char using RFC 1345 mnemonics.
  ⁃ `cape-sgml': Complete Unicode char from SGML entity, e.g., `&alpha'.
  ⁃ `cape-tex': Complete Unicode char from TeX command, e.g. `\hbar'.


2 Configuration
═══════════════

  Cape is available on GNU ELPA and MELPA. You can install the package
  with `package-install'. In the following we present a sample
  configuration based on the popular `use-package' macro.

  I recommend to bind the `cape-*' completion commands to keys such that
  you can invoke them explicitly. This makes particular sense for
  special Capfs which you only want to trigger in rare
  circumstances. See the `:bind' specification below.

  Furthermore the `cape-*' functions are Capfs which you can add to the
  `completion-at-point-functions' list. Take care when adding Capfs to
  the list since each of the Capfs adds a small runtime cost. Note that
  the Capfs which occur earlier in the list take precedence, such that
  the first Capf returning a result will win and the later Capfs may not
  get a chance to run. In order to merge Capfs you can try the function
  `cape-capf-super'.

  One must distinguish the buffer-local and the global value of the
  `completion-at-point-functions' variable. The buffer-local value of
  the list takes precedence, but if the buffer-local list contains the
  symbol `t' at the end, it means that the functions specified in the
  global list should be executed afterwards. The special meaning of the
  value `t' is a feature of the `run-hooks' function, see the section
  ["Running Hooks" in the Elisp manual] for further information.

  ┌────
  │ ;; Enable Corfu completion UI
  │ ;; See the Corfu README for more configuration tips.
  │ (use-package corfu
  │   :init
  │   (global-corfu-mode))
  │ 
  │ ;; Add extensions
  │ (use-package cape
  │   ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  │   ;; Press C-c p ? to for help.
  │   :bind ("C-c p" . cape-prefix-map) ;; Alternative key: M-<tab>, M-p, M-+
  │   ;; Alternatively bind Cape commands individually.
  │   ;; :bind (("C-c p d" . cape-dabbrev)
  │   ;;        ("C-c p h" . cape-history)
  │   ;;        ("C-c p f" . cape-file)
  │   ;;        ...)
  │   :init
  │   ;; Add to the global default value of `completion-at-point-functions' which is
  │   ;; used by `completion-at-point'.  The order of the functions matters, the
  │   ;; first function returning a result wins.  Note that the list of buffer-local
  │   ;; completion functions takes precedence over the global list.
  │   (add-hook 'completion-at-point-functions #'cape-dabbrev)
  │   (add-hook 'completion-at-point-functions #'cape-file)
  │   (add-hook 'completion-at-point-functions #'cape-elisp-block)
  │   ;; (add-hook 'completion-at-point-functions #'cape-history)
  │   ;; ...
  │ )
  └────


["Running Hooks" in the Elisp manual] <info:elisp#Running Hooks>


3 CAPF adapters and transformers
════════════════════════════════

3.1 Company adapter
───────────────────

  /Wrap your Company backend in a Cape and turn it into a Capf!/

  Cape provides the adapter `cape-company-to-capf' for Company
  backends. The adapter transforms Company backends to Capfs which are
  understood by the built-in Emacs completion mechanism. The function is
  approximately the inverse of the `company-capf' backend from
  Company. The adapter can be used as follows:

  ┌────
  │ ;; Use Company backends as Capfs.
  │ (setq-local completion-at-point-functions
  │   (mapcar #'cape-company-to-capf
  │     (list #'company-files #'company-keywords #'company-dabbrev)))
  └────

  Note that the adapter does not require Company to be installed or
  enabled.  Backends implementing the Company specification do not
  necessarily have to depend on Company, however in practice most
  backends do. The following shows a small example completion backend,
  which can be used with both `completion-at-point' (Corfu, default
  completion) and Company.

  ┌────
  │ (defvar demo-alist
  │   '((":-D" . "😀")
  │     (";-)" . "😉")
  │     (":-/" . "😕")
  │     (":-(" . "🙁")
  │     (":-*" . "😙")))
  │ 
  │ (defun demo-backend (action &optional arg &rest _)
  │   (pcase action
  │     ('prefix (and (memq (char-before) '(?: ?\;))
  │ 		  (cons (string (char-before)) t)))
  │     ('candidates (all-completions arg demo-alist))
  │     ('annotation (concat " " (cdr (assoc arg demo-alist))))
  │     ('post-completion
  │      (let ((str (buffer-substring (- (point) 3) (point))))
  │        (delete-region (- (point) 3) (point))
  │      (insert (cdr (assoc str demo-alist)))))))
  │ 
  │ ;; Register demo backend with `completion-at-point'
  │ (setq completion-at-point-functions
  │       (list (cape-company-to-capf #'demo-backend)))
  │ 
  │ ;; Register demo backend with Company.
  │ (setq company-backends '(demo-backend))
  └────

  It is possible to merge multiple Company backends and use them as a
  single Capf using the `company--multi-backend-adapter' function from
  Company. The adapter transforms multiple Company backends into a
  single Company backend, which can then be used as a Capf via
  `cape-company-to-capf'. Capfs can be merged directly with
  `cape-capf-super'.

  ┌────
  │ (require 'company)
  │ ;; Use the company-dabbrev and company-elisp backends together.
  │ (setq completion-at-point-functions
  │       (list
  │        (cape-company-to-capf
  │ 	(apply-partially #'company--multi-backend-adapter
  │ 			 '(company-dabbrev company-elisp)))))
  └────


3.2 Super-Capf - Merging multiple Capfs
───────────────────────────────────────

  /Throw multiple Capfs under the Cape and get a Super-Capf!/

  Cape supports merging multiple Capfs using the function
  `cape-capf-super'. Due to some technical details, not all Capfs can be
  merged successfully. Merge Capfs one by one and make sure that you get
  the desired outcome.

  Note that `cape-capf-super' is not needed if multiple Capfs should
  betried one after the other, for example you can use `cape-file'
  together with programming mode Capfs by adding `cape-file' to the
  `completion-at-point-functions' list. File completion will then be
  available in comments and string literals, but not in normal
  code. `cape-capf-super' is only necessary if you want to combine
  multiple Capfs, such that the candidates from multiple sources appear
  /together/ in the completion list at the same time.

  Capf merging requires completion functions which are sufficiently
  well-behaved and completion functions which do not define completion
  boundaries.  `cape-capf-super' has the same restrictions as
  `completion-table-merge' and `completion-table-in-turn'. As a simple
  rule of thumb, `cape-capf-super' works for static completion functions
  like `cape-dabbrev', `cape-keyword', `cape-dict', etc., but not for
  multi-step completions like `cape-file'.

  ┌────
  │ ;; Merge the dabbrev, dict and keyword capfs, display candidates together.
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-capf-super #'cape-dabbrev #'cape-dict #'cape-keyword)))
  │ 
  │ ;; Alternative: Define named Capf instead of using the anonymous Capf directly
  │ (defun cape-dabbrev-dict-keyword ()
  │   (cape-wrap-super #'cape-dabbrev #'cape-dict #'cape-keyword))
  │ (setq-local completion-at-point-functions (list #'cape-dabbrev-dict-keyword))
  └────

  See also the aforementioned `company--multi-backend-adapter' from
  Company, which allows you to merge multiple Company backends.


3.3 Capf-Buster - Cache busting
───────────────────────────────

  /The Capf-Buster ensures that you always get a fresh set of
  candidates!/

  If a Capf caches the candidates for too long we can use a cache
  busting Capf-transformer. For example the Capf merging function
  `cape-capf-super' creates a Capf, which caches the candidates for the
  whole lifetime of the Capf.  Therefore you may want to combine a
  merged Capf with a cache buster under some circumstances. It is
  noteworthy that the `company-capf' backend from Company refreshes the
  completion table frequently. With the `cape-capf-buster' we can
  achieve a similarly refreshing strategy.

  ┌────
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-capf-buster #'some-caching-capf)))
  └────


3.4 Capf transformers
─────────────────────

  Cape provides a set of additional Capf transformation functions, which
  are mostly meant to used by experts to fine tune the Capf behavior and
  Capf interaction. These can either be used as advices (`cape-wrap-*)'
  or to create a new Capf from an existing Capf (`cape-capf-*'). You can
  bind the Capfs created by the Capf transformers with `defalias' to a
  function symbol.

  • `cape-capf-accept-all', `cape-wrap-accept-all': Create a Capf which
    accepts every input as valid.
  • `cape-capf-case-fold', `cape-wrap-case-fold': Create a Capf which is
    case insensitive.
  • `cape-capf-debug', `cape-wrap-debug': Create a Capf which prints
    debugging messages.
  • `cape-capf-inside-code', `cape-wrap-inside-code': Ensure that Capf
    triggers only inside code.
  • `cape-capf-inside-comment', `cape-wrap-inside-comment': Ensure that
    Capf triggers only inside comments.
  • `cape-capf-inside-faces', `cape-wrap-inside-faces': Ensure that Capf
    triggers only inside text with certain faces.
  • `cape-capf-inside-string', `cape-wrap-inside-string': Ensure that
    Capf triggers only inside a string literal.
  • `cape-capf-interactive', `cape-interactive': Create a Capf which can
    be called interactively.
  • `cape-capf-nonexclusive', `cape-wrap-nonexclusive': Mark Capf as
    non-exclusive.
  • `cape-capf-noninterruptible', `cape-wrap-noninterruptible': Protect
    a Capf which does not like to be interrupted.
  • `cape-capf-passthrough', `cape-wrap-passthrough': Defeat entire
    completion style filtering.
  • `cape-capf-predicate', `cape-wrap-predicate': Add candidate
    predicate to a Capf.
  • `cape-capf-prefix-length', `cape-wrap-prefix-length': Enforce a
    minimal prefix length.
  • `cape-capf-properties', `cape-wrap-properties': Add completion
    properties to a Capf.
  • `cape-capf-purify', `cape-wrap-purify': Purify a broken Capf and
    ensure that it does not modify the buffer.
  • `cape-capf-silent', `cape-wrap-silent': Silence Capf messages and
    errors.
  • `cape-capf-sort', `cape-wrap-sort': Add sort function to a Capf.
  • `cape-capf-super', `cape-wrap-super': Merge multiple Capfs into a
    Super-Capf.

  In the following we show a few example configurations, which have come
  up on the [Cape] or [Corfu issue tracker] or the [Corfu wiki.] I use
  some of these tweaks in my personal configuration.

  ┌────
  │ ;; Example 1: Sanitize the `pcomplete-completions-at-point' Capf.  The Capf has
  │ ;; undesired side effects on Emacs 28.  These advices are not needed on Emacs 29
  │ ;; and newer.
  │ (when (< emacs-major-version 29)
  │   (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  │   (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))
  │ 
  │ ;; Example 2: Configure a Capf with a specific auto completion prefix length
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-capf-prefix-length #'cape-dabbrev 2)))
  │ 
  │ ;; Example 3: Create a Capf with debugging messages
  │ (setq-local completion-at-point-functions (list (cape-capf-debug #'cape-dict)))
  │ 
  │ ;; Example 4: Named Capf
  │ (defalias 'cape-dabbrev-min-2 (cape-capf-prefix-length #'cape-dabbrev 2))
  │ (setq-local completion-at-point-functions (list #'cape-dabbrev-min-2))
  │ 
  │ ;; Example 5: Define a defensive Dabbrev Capf, which accepts all inputs.  If you
  │ ;; use Corfu and `corfu-auto=t', the first candidate won't be auto selected if
  │ ;; `corfu-preselect=valid', such that it cannot be accidentally committed when
  │ ;; pressing RET.
  │ (defun my-cape-dabbrev-accept-all ()
  │   (cape-wrap-accept-all #'cape-dabbrev))
  │ (add-hook 'completion-at-point-functions #'my-cape-dabbrev-accept-all)
  │ 
  │ ;; Example 6: Define interactive Capf which can be bound to a key.  Here we wrap
  │ ;; the `elisp-completion-at-point' such that we can complete Elisp code
  │ ;; explicitly in arbitrary buffers.
  │ (keymap-global-set "C-c p e" (cape-capf-interactive #'elisp-completion-at-point))
  │ 
  │ ;; Example 7: Ignore :keywords in Elisp completion.
  │ (defun ignore-elisp-keywords (sym)
  │   (not (keywordp sym)))
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-capf-predicate #'elisp-completion-at-point
  │ 				       #'ignore-elisp-keywords)))
  └────


[Cape] <https://github.com/minad/cape/issues>

[Corfu issue tracker] <https://github.com/minad/corfu/issues>

[Corfu wiki.] <https://github.com/minad/corfu/wiki>


4 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/cape.html>
