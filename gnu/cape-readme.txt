		 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		  CAPE.EL - LET YOUR COMPLETIONS FLY!
		 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Available Capfs
2. Configuration
3. Experimental features
.. 1. Company adapter
.. 2. Super-Capf - Merging multiple Capfs
.. 3. Capf-Buster - Cache busting
.. 4. Other Capf transformers
4. Contributions


Cape provides Completion At Point Extensions which can be used in
combination with the [Corfu] completion UI or the default completion
UI. The completion backends used by `completion-at-point' are so called
`completion-at-point-functions' (Capfs). In principle, the Capfs
provided by Cape can also be used by [Company].

You can register the `cape-*' functions in the
`completion-at-point-functions' list.  This makes the backends available
for completion, which is usually invoked by pressing `TAB' or
`M-TAB'. The functions can also be invoked interactively to trigger the
respective completion at point. You can bind them directly to a key in
your user configuration. Notable commands/Capfs are `cape-line' for
completion of a line from the current buffer and `cape-file' for
completion of a file name.  The command `cape-symbol' is particularly
useful for documentation of Elisp packages or configurations, since it
completes Elisp symbols anywhere.

Cape has the super power to transform Company backends into Capfs and
merge multiple Capfs into a Super-Capf! These transformers allow you to
still take advantage of Company backends even if you are not using
Company as frontend.

Table of Contents
─────────────────

1. Available Capfs
2. Configuration
3. Experimental features
.. 1. Company adapter
.. 2. Super-Capf - Merging multiple Capfs
.. 3. Capf-Buster - Cache busting
.. 4. Other Capf transformers
4. Contributions


[Corfu] <https://github.com/minad/corfu>

[Company] <https://github.com/company-mode/company-mode>


1 Available Capfs
═════════════════

  ⁃ `cape-dabbrev': Complete word from current buffers
  ⁃ `cape-file': Complete file name
  ⁃ `cape-history': Complete from Eshell, Comint or minibuffer history
  ⁃ `cape-keyword': Complete programming language keyword
  ⁃ `cape-symbol': Complete Elisp symbol
  ⁃ `cape-abbrev': Complete abbreviation (`add-global-abbrev',
    `add-mode-abbrev')
  ⁃ `cape-ispell': Complete word from Ispell dictionary
  ⁃ `cape-dict': Complete word from dictionary file
  ⁃ `cape-line': Complete entire line from current buffer
  ⁃ `cape-tex': Complete unicode char from TeX command, e.g. `\hbar'.
  ⁃ `cape-sgml': Complete unicode char from Sgml entity, e.g., `&alpha'.
  ⁃ `cape-rfc1345': Complete unicode char using RFC 1345 mnemonics.


2 Configuration
═══════════════

  Cape is available on GNU ELPA and MELPA. You can install the package
  with `package-install'. In the long term some of the Capfs provided by
  this package could be upstreamed into Emacs itself.

  ┌────
  │ ;; Enable Corfu completion UI
  │ ;; See the Corfu README for more configuration tips.
  │ (use-package corfu
  │   :init
  │   (global-corfu-mode))
  │ 
  │ ;; Add extensions
  │ (use-package cape
  │   ;; Bind dedicated completion commands
  │   ;; Alternative prefix keys: C-c p, M-p, M-+, ...
  │   :bind (("C-c p p" . completion-at-point) ;; capf
  │ 	 ("C-c p t" . complete-tag)        ;; etags
  │ 	 ("C-c p d" . cape-dabbrev)        ;; or dabbrev-completion
  │ 	 ("C-c p h" . cape-history)
  │ 	 ("C-c p f" . cape-file)
  │ 	 ("C-c p k" . cape-keyword)
  │ 	 ("C-c p s" . cape-symbol)
  │ 	 ("C-c p a" . cape-abbrev)
  │ 	 ("C-c p i" . cape-ispell)
  │ 	 ("C-c p l" . cape-line)
  │ 	 ("C-c p w" . cape-dict)
  │ 	 ("C-c p \\" . cape-tex)
  │ 	 ("C-c p _" . cape-tex)
  │ 	 ("C-c p ^" . cape-tex)
  │ 	 ("C-c p &" . cape-sgml)
  │ 	 ("C-c p r" . cape-rfc1345))
  │   :init
  │   ;; Add `completion-at-point-functions', used by `completion-at-point'.
  │   (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  │   (add-to-list 'completion-at-point-functions #'cape-file)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-history)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-keyword)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-tex)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-sgml)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-rfc1345)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-abbrev)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-ispell)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-dict)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-symbol)
  │   ;;(add-to-list 'completion-at-point-functions #'cape-line)
  │ )
  └────


3 Experimental features
═══════════════════════

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
  │     (list #'company-files #'company-ispell #'company-dabbrev)))
  └────

  Note that the adapter does not require Company to be installed or
  enabled.  Backends implementing the Company specification do not
  necessarily have to depend on Company, however in practice most
  backends do. The following shows a small example completion backend,
  which can be used with both `completion-at-point' (Corfu, default
  completion) and Company.

  ┌────
  │ (defvar emojis
  │   '((":-D" . "😀")
  │     (";-)" . "😉")
  │     (":-/" . "😕")
  │     (":-(" . "🙁")
  │     (":-*" . "😙")))
  │ 
  │ (defun emoji-backend (action &optional arg &rest _)
  │   (pcase action
  │     ('prefix (and (memq (char-before) '(?: ?\;))
  │ 		  (cons (string (char-before)) t)))
  │     ('candidates (all-completions arg emojis))
  │     ('annotation (concat " " (cdr (assoc arg emojis))))
  │     ('post-completion
  │      (let ((str (buffer-substring (- (point) 3) (point))))
  │        (delete-region (- (point) 3) (point))
  │      (insert (cdr (assoc str emojis)))))))
  │ 
  │ ;; Register emoji backend with `completion-at-point'
  │ (setq completion-at-point-functions
  │       (list (cape-company-to-capf #'emoji-backend)))
  │ 
  │ ;; Register emoji backend with Company.
  │ (setq company-backends '(emoji-backend))
  └────

  It is possible to merge/group multiple Company backends and use them
  as a single Capf using the `company--multi-backend-adapter' function
  from Company. The adapter transforms multiple Company backends into a
  single Company backend, which can then be used as a Capf via
  `cape-company-to-capf'.

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
  `cape-super-capf'. This feature is experimental and should only be
  used in special scenarios.  *Don't use cape-super-capf if you are not
  100% sure that you need it!*

  Note that `cape-super-capf' is not needed if you want to use multiple
  Capfs which are tried one by one, e.g., it is perfectly possible to
  use `cape-file' together with the Lsp-mode Capf or other programming
  mode Capfs by adding `cape-file' to the
  `completion-at-point-functions' list. The file completion will be
  available in comments and string literals. `cape-super-capf' is only
  needed if you want to combine multiple Capfs, such that the candidates
  from multiple sources appear /together/ in the completion list at the
  same time.

  Completion table merging works only for tables which are sufficiently
  well-behaved and tables which do not define completion boundaries.
  `cape-super-capf' has the same restrictions as
  `completion-table-merge' and `completion-table-in-turn'. As a simple
  rule of thumb, `cape-super-capf' works only well for static completion
  functions like `cape-dabbrev', `cape-keyword', `cape-ispell', etc.,
  but not for complex multi-step completions like `cape-file'.

  ┌────
  │ ;; Merge the dabbrev, dict and keyword capfs, display candidates together.
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-super-capf #'cape-dabbrev #'cape-dict #'cape-keyword)))
  │ 
  │ ;; Alternative: Define named Capf instead of using the anonymous Capf directly
  │ (defalias 'cape-dabbrev+dict+keyword
  │   (cape-super-capf #'cape-dabbrev #'cape-dict #'cape-keyword))
  │ (setq-local completion-at-point-functions (list #'cape-dabbrev+dict+keyword))
  └────

  See also the aforementioned `company--multi-backend-adapter' from
  Company, which allows you to merge multiple Company backends.


3.3 Capf-Buster - Cache busting
───────────────────────────────

  /The Capf-Buster ensures that you always get a fresh set of
  candidates!/

  If a Capf caches the candidates for too long we can use a cache
  busting Capf-transformer. For example the Capf merging function
  `cape-super-capf' creates a Capf, which caches the candidates for the
  whole lifetime of the Capf.  Therefore you may want to combine a
  merged Capf with a cache buster under some circumstances. It is
  noteworthy that the `company-capf' backend from Company refreshes the
  completion table frequently. With the `cape-capf-buster' we can
  achieve a similarly refreshing strategy.

  ┌────
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-capf-buster #'some-caching-capf)))
  └────


3.4 Other Capf transformers
───────────────────────────

  Cape provides a set of additional Capf transformation functions, which
  are mostly meant to used by experts to fine tune the Capf behavior and
  Capf interaction. These can either be used as advices (`cape-wrap-*)'
  or to create a new Capf from an existing Capf (`cape-capf-*'). You can
  bind the Capfs created by the Capf transformers with `defalias' to a
  function symbol.

  • `cape-interactive-capf': Create a Capf which can be called
    interactively.
  • `cape-wrap-accept-all', `cape-capf-accept-all': Create a Capf which
    accepts every input as valid.
  • `cape-wrap-silent', `cape-capf-silent': Wrap a chatty Capf and
    silence it.
  • `cape-wrap-purify', `cape-capf-purify': Purify a broken Capf and
    ensure that it does not modify the buffer.
  • `cape-wrap-noninterruptible', `cape-capf-noninterruptible:' Protect
    a Capf which does not like to be interrupted.
  • `cape-wrap-case-fold', `cape-capf-case-fold': Create a Capf which is
    case insensitive.
  • `cape-wrap-properties', `cape-capf-properties': Add completion
    properties to a Capf.
  • `cape-wrap-predicate', `cape-capf-predicate': Add candidate
    predicate to a Capf.
  • `cape-wrap-prefix-length', `cape-capf-prefix-length': Enforce a
    minimal prefix length.

  In the following we show a few example configurations, which have come
  up on the [Cape] or [Corfu issue tracker] or the [Corfu wiki.] I use
  some of these tweaks in my personal configuration.

  ┌────
  │ ;; Example 1: Sanitize the `pcomplete-completions-at-point' Capf.
  │ ;; The Capf has undesired side effects on Emacs 28 and earlier.
  │ (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  │ (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify)
  │ 
  │ ;; Example 2: Configure a Capf with a specific auto completion prefix length
  │ (setq-local completion-at-point-functions
  │ 	    (list (cape-capf-prefix-length #'cape-dabbrev 2)))
  │ 
  │ ;; Example 3: Named Capf
  │ (defalias 'cape-dabbrev-min-2 (cape-capf-prefix-length #'cape-dabbrev 2))
  │ (setq-local completion-at-point-functions (list #'cape-dabbrev-min-2))
  │ 
  │ ;; Example 4: Define a defensive Dabbrev Capf, which accepts all inputs.
  │ ;; If you use Corfu and `corfu-auto=t', the first candidate won't be auto
  │ ;; selected even if `corfu-preselect-first=t'! You can use this instead of
  │ ;; `cape-dabbrev'.
  │ (defun my-cape-dabbrev-accept-all ()
  │   (cape-wrap-accept-all #'cape-dabbrev))
  │ (add-to-list 'completion-at-point-functions #'my-cape-dabbrev-accept-all)
  │ 
  │ ;; Example 5: Define interactive Capf which can be bound to a key.
  │ ;; Here we wrap the `elisp-completion-at-point' such that we can
  │ ;; complete Elisp code explicitly in arbitrary buffers.
  │ (global-set-key (kbd "C-c p e")
  │ 		(cape-interactive-capf #'elisp-completion-at-point))
  │ 
  │ ;; Example 6: Ignore :keywords in Elisp completion.
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


[GNU ELPA] <http://elpa.gnu.org/packages/cape.html>
