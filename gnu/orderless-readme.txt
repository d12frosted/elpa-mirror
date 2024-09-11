                              ━━━━━━━━━━━
                               ORDERLESS
                              ━━━━━━━━━━━





1 Overview
══════════

  This package provides an `orderless' /completion style/ that divides
  the pattern into space-separated components, and matches candidates
  that match all of the components in any order. Each component can
  match in any one of several ways: literally, as a regexp, as an
  initialism, in the flex style, or as multiple word prefixes. By
  default, regexp and literal matches are enabled.

  A completion style is a back-end for completion and is used from a
  front-end that provides a completion UI. Any completion style can be
  used with the default Emacs completion UI (sometimes called minibuffer
  tab completion), with the built-in Icomplete package (which is similar
  to the more well-known Ido Mode), the icomplete-vertical variant from
  Emacs 28 (see the external [icomplete-vertical] package to get that
  functionality on earlier versions of Emacs), or with some third party
  minibuffer completion frameworks such as [Mct] or [Vertico].

  All the completion UIs just mentioned are for minibuffer completion,
  used when Emacs commands prompt the user in the minibuffer for some
  input, but there is also completion at point in normal buffers,
  typically used for identifiers in programming languages. Completion
  styles can also be used for that purpose by completion at point UIs
  such as [Corfu], [Company] or the function
  `consult-completion-in-region' from [Consult].

  To use a completion style with any of the above mentioned completion
  UIs simply add it as an entry in the variables `completion-styles' and
  `completion-category-overrides' and `completion-category-defaults'
  (see their documentation).

  The `completion-category-defaults' variable serves as a default value
  for `completion-category-overrides'. If you want to use `orderless'
  exclusively, set both variables to `nil', but be aware that
  `completion-category-defaults' is modified by packages at load time.

  With a bit of effort, it might still be possible to use `orderless'
  with other completion UIs, even if those UIs don't support the
  standard Emacs completion styles. Currently there is support for [Ivy]
  (see below). Also, while Company does support completion styles
  directly, pressing `SPC' takes you out of completion, so comfortably
  using `orderless' with it takes a bit of configuration (see below).

  If you use ELPA or MELPA, the easiest way to install `orderless' is
  via `package-install'. If you use `use-package', you can use:

  ┌────
  │ (use-package orderless
  │   :ensure t
  │   :custom
  │   (completion-styles '(orderless basic))
  │   (completion-category-overrides '((file (styles basic partial-completion)))))
  └────

  Alternatively, put `orderless.el' somewhere on your `load-path', and
  use the following configuration:

  ┌────
  │ (require 'orderless)
  │ (setq completion-styles '(orderless basic)
  │       completion-category-overrides '((file (styles basic partial-completion))))
  └────

  The `basic' completion style is specified as fallback in addition to
  `orderless' in order to ensure that completion commands which rely on
  dynamic completion tables, e.g., `completion-table-dynamic' or
  `completion-table-in-turn', work correctly. Furthermore the `basic'
  completion style needs to be tried /first/ (not as a fallback) for
  TRAMP hostname completion to work. In order to achieve that, we add an
  entry for the `file' completion category in the
  `completion-category-overrides' variable. In addition, the
  `partial-completion' style allows you to use wildcards for file
  completion and partial paths, e.g., `/u/s/l' for `/usr/share/local'.

  Bug reports are highly welcome and appreciated!


[icomplete-vertical] <https://github.com/oantolin/icomplete-vertical>

[Mct] <https://gitlab.com/protesilaos/mct>

[Vertico] <https://github.com/minad/vertico>

[Corfu] <https://github.com/minad/corfu>

[Company] <https://company-mode.github.io/>

[Consult] <https://github.com/minad/consult>

[Ivy] <https://github.com/abo-abo/swiper>


2 Customization
═══════════════

2.1 Component matching styles
─────────────────────────────

  Each component of a pattern can match in any of several matching
  styles. A matching style is a function from strings to regexps or
  predicates, so it is easy to define new matching styles. The value
  returned by a matching style can be either a regexp as a string, an
  s-expression in `rx' syntax or a predicate function. The predefined
  matching styles are:

  orderless-regexp
        the component is treated as a regexp that must match somewhere
        in the candidate.

        If the component is not a valid regexp, it is ignored.

  orderless-literal
        the component is treated as a literal string that must occur in
        the candidate.

  orderless-literal-prefix
        the component is treated as a literal string that must occur as
        a prefix of a candidate.

  orderless-prefixes
        the component is split at word endings and each piece must match
        at a word boundary in the candidate, occurring in that order.

        This is similar to the built-in `partial-completion'
        completion-style.  For example, `re-re' matches
        `query-replace-regexp', `recode-region' and
        `magit-remote-list-refs'; `f-d.t' matches `final-draft.txt'.

  orderless-initialism
        each character of the component should appear as the beginning
        of a word in the candidate, in order.

        This maps `abc' to `\<a.*\<b.*\c'.

  orderless-flex
        the characters of the component should appear in that order in
        the candidate, but not necessarily consecutively.

        This maps `abc' to `a.*b.*c'.

  *orderless-without-literal*
        the component is a treated as a literal string that must *not*
        occur in the candidate.

        Nothing is highlighted by this style. This style should not be
        used directly in `orderless-matching-styles' but with a style
        dispatcher instead. See also the more general style modifier
        `orderless-not'.

  The variable `orderless-matching-styles' can be set to a list of the
  desired matching styles to use. By default it enables the literal and
  regexp styles.


2.1.1 Style modifiers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Style modifiers are functions which take a predicate function and a
  regular expression as a string and return a new predicate function.
  Style modifiers should not be used directly in
  `orderless-matching-styles' but with a style dispatcher instead.

  orderless-annotation
        this style modifier matches the pattern against the annotation
        string of the candidate, instead of against the candidate
        string.

  orderless-not
        this style modifier inverts the pattern, such that candidates
        pass which do not match the pattern.


2.1.2 Style dispatchers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  For more fine-grained control on which matching styles to use for each
  component of the input string, you can customize the variable
  `orderless-style-dispatchers'. You can use this feature to define your
  own "query syntax". For example, the default value of
  `orderless-style-dispatchers' lists a single dispatcher called
  `orderless-affix-dispatch' which enables a simple syntax based on
  special characters used as either a prefix or suffix:

  • ! modifies the component with `orderless-not'. Both `!bad' and
    `bad!' will match strings that do /not/ contain the pattern `bad'.
  • & modifies the component with `orderless-annotation'. The pattern
    will match against the candidate's annotation (cheesy mnemonic:
    andnotation!).
  • , uses `orderless-initialism'.
  • = uses `orderless-literal'.
  • ^ uses `orderless-literal-prefix'.
  • ~ uses `orderless-flex'.
  • % makes the string match ignoring diacritics and similar inflections
    on characters (it uses the function `char-fold-to-regexp' to do
    this).

  You can add, remove or change this mapping between affix characters
  and matching styles by customizing the user option
  `orderless-affix-dispatch-alist'. Most users will probably find this
  type of customization sufficient for their query syntax needs, but for
  those desiring further control the rest of this section explains how
  to implement your own style dispatchers.

  Style dispatchers are functions which take a component, its index in
  the list of components (starting from 0), and the total number of
  components, and are used to determine the matching styles used for
  that specific component, overriding the default matching styles.

  A style dispatcher can either decline to handle the input string or
  component, or it can return which matching styles to use. It can also,
  if desired, additionally return a new string to use in place of the
  given one. Consult the documentation of `orderless--dispatch' for full
  details.

  As an example of writing your own dispatchers, say you wanted the
  following setup:

  • you normally want components to match as regexps,
  • except for the first component, which should always match as an
    initialism —this is pretty useful for, say,
    `execute-extended-command' (`M-x') or `describe-function' (`C-h f'),
  • later components ending in `~' should match (the characters other
    than the final `~') in the flex style, and
  • later components starting with `!' should indicate the rest of the
    component is a literal string not contained in the candidate (this
    is part of the functionality of the default configuration).

  You can achieve this with the following configuration:

  ┌────
  │ (defun flex-if-twiddle (pattern _index _total)
  │   (when (string-suffix-p "~" pattern)
  │     `(orderless-flex . ,(substring pattern 0 -1))))
  │ 
  │ (defun first-initialism (pattern index _total)
  │   (if (= index 0) 'orderless-initialism))
  │ 
  │ (defun not-if-bang (pattern _index _total)
  │   (cond
  │    ((equal "!" pattern)
  │     #'ignore)
  │    ((string-prefix-p "!" pattern)
  │     `(orderless-not . ,(substring pattern 1)))))
  │ 
  │ (setq orderless-matching-styles '(orderless-regexp)
  │       orderless-style-dispatchers '(first-initialism
  │ 				    flex-if-twiddle
  │ 				    not-if-bang))
  └────


2.2 Component separator regexp
──────────────────────────────

  The pattern components are space-separated by default: this is
  controlled by the variable `orderless-component-separator', which
  should be set either to a regexp that matches the desired component
  separator, or to a function that takes a string and returns the list
  of components. The default value is a regexp matches a non-empty
  sequence of spaces. It may be useful to add hyphens or slashes (or
  both), to match symbols or file paths, respectively.

   Even if you want to split on spaces you might want to be able to
  escape those spaces or to enclose space in double quotes (as in shell
  argument parsing). For backslash-escaped spaces set
  `orderless-component-separator' to the function
  `orderless-escapable-split-on-space'; for shell-like double-quotable
  space, set it to the standard Emacs function
  `split-string-and-unquote'.

  If you are implementing a command for which you know you want a
  different separator for the components, bind
  `orderless-component-separator' in a `let' form.


2.3 Defining custom orderless styles
────────────────────────────────────

  Orderless allows the definition of custom completion styles using the
  `orderless-define-completion-style' macro. Any Orderless configuration
  variable can be adjusted locally for the new style, e.g.,
  `orderless-matching-styles'.

  By default Orderless only enables the regexp and literal matching
  styles. In the following example an `orderless+initialism' style is
  defined, which additionally enables initialism matching. This
  completion style can then used when matching candidates of the symbol
  or command completion category.

  ┌────
  │ (orderless-define-completion-style orderless+initialism
  │   (orderless-matching-styles '(orderless-initialism
  │ 			       orderless-literal
  │ 			       orderless-regexp)))
  │ (setq completion-category-overrides
  │       '((command (styles orderless+initialism))
  │ 	(symbol (styles orderless+initialism))
  │ 	(variable (styles orderless+initialism))))
  └────

  Note that in order for the `orderless+initialism' style to kick-in
  with the above configuration, you'd need to use commands whose
  metadata indicates that the completion candidates are commands or
  symbols. In Emacs 28, `execute-extended-command' has metadata
  indicating you are selecting a command, but earlier versions of Emacs
  lack this metadata.  Activating `marginalia-mode' from the
  [Marginalia] package provides this metadata automatically for many
  built-in commands and is recommended if you use the above example
  configuration, or other similarly fine-grained control of completion
  styles according to completion category.


[Marginalia] <https://github.com/minad/marginalia>


2.4 Faces for component matches
───────────────────────────────

  The portions of a candidate matching each component get highlighted in
  one of four faces, `orderless-match-face-?' where `?' is a number from
  0 to 3. If the pattern has more than four components, the faces get
  reused cyclically.

  If your `completion-styles' (or `completion-category-overrides' for
  some particular category) has more than one entry, remember than Emacs
  tries each completion style in turn and uses the first one returning
  matches. You will only see these particular faces when the `orderless'
  completion is the one that ends up being used, of course.


2.5 Pattern compiler
────────────────────

  The default mechanism for turning an input string into a predicate and
  a list of regexps to match against, configured using
  `orderless-matching-styles', is probably flexible enough for the vast
  majority of users. The patterns are compiled by
  `orderless-compile'. Under special circumstances it may be useful to
  implement a custom pattern compiler by advising `orderless-compile'.


2.6 Interactively changing the configuration
────────────────────────────────────────────

  You might want to change the separator or the matching style
  configuration on the fly while matching. There many possible user
  interfaces for this: you could toggle between two chosen
  configurations, cycle among several, have a keymap where each key sets
  a different configurations, have a set of named configurations and be
  prompted (with completion) for one of them, popup a [hydra] to choose
  a configuration, etc. Since there are so many possible UIs and which
  to use is mostly a matter of taste, `orderless' does not provide any
  such commands. But it's easy to write your own!

  For example, say you want to use the keybinding `C-l' to make all
  components match literally. You could use the following code:

  ┌────
  │ (defun my/match-components-literally ()
  │   "Components match literally for the rest of the session."
  │   (interactive)
  │   (setq-local orderless-matching-styles '(orderless-literal)
  │ 	      orderless-style-dispatchers nil))
  │ 
  │ (define-key minibuffer-local-completion-map (kbd "C-l")
  │   #'my/match-components-literally)
  └────

  Using `setq-local' to assign to the configuration variables ensures
  the values are only used for that minibuffer completion session.


[hydra] <https://github.com/abo-abo/hydra>


3 Integration with other completion UIs
═══════════════════════════════════════

  Several excellent completion UIs exist for Emacs in third party
  packages. They do have a tendency to forsake standard Emacs APIs, so
  integration with them must be done on a case by case basis.

  If you manage to use `orderless' with a completion UI not listed here,
  please file an issue or make a pull request so others can benefit from
  your effort. The functions `orderless-filter',
  `orderless-highlight-matches', `orderless--highlight' and
  `orderless--component-regexps' are likely to help with the
  integration.


3.1 Ivy
───────

  To use `orderless' from Ivy add this to your Ivy configuration:

  ┌────
  │ (setq ivy-re-builders-alist '((t . orderless-ivy-re-builder)))
  │ (add-to-list 'ivy-highlight-functions-alist '(orderless-ivy-re-builder . orderless-ivy-highlight))
  └────


3.2 Helm
────────

  To use `orderless' from Helm, simply configure `orderless' as you
  would for completion UIs that use Emacs completion styles and add this
  to your Helm configuration:

  ┌────
  │ (setq helm-completion-style 'emacs)
  └────


3.3 Company
───────────

  Company comes with a `company-capf' backend that uses the
  completion-at-point functions, which in turn use completion styles.
  This means that the `company-capf' backend will automatically use
  `orderless', no configuration necessary!

  But there are a couple of points of discomfort:

  1. Pressing SPC takes you out of completion, so with the default
     separator you are limited to one component, which is no fun. To fix
     this add a separator that is allowed to occur in identifiers, for
     example, for Emacs Lisp code you could use an ampersand:

     ┌────
     │ (setq orderless-component-separator "[ &]")
     └────

  2. The matching portions of candidates aren't highlighted. That's
     because `company-capf' is hard-coded to look for the
     `completions-common-part' face, and it only use one face,
     `company-echo-common' to highlight candidates.

     So, while you can't get different faces for different components,
     you can at least get the matches highlighted in the sole available
     face with this configuration:

     ┌────
     │ (defun just-one-face (fn &rest args)
     │   (let ((orderless-match-faces [completions-common-part]))
     │     (apply fn args)))
     │ 
     │ (advice-add 'company-capf--candidates :around #'just-one-face)
     └────

     (Aren't dynamically scoped variables and the advice system nifty?)

  If you would like to use different `completion-styles' with
  `company-capf' instead, you can add this to your configuration:

  ┌────
  │ ;; We follow a suggestion by company maintainer u/hvis:
  │ ;; https://www.reddit.com/r/emacs/comments/nichkl/comment/gz1jr3s/
  │ (defun company-completion-styles (capf-fn &rest args)
  │   (let ((completion-styles '(basic partial-completion)))
  │     (apply capf-fn args))
  │ 
  │ (advice-add 'company-capf :around #'company-completion-styles)
  └────


4 Related packages
══════════════════

4.1 Ivy and Helm
────────────────

  The well-known and hugely powerful completion frameworks [Ivy] and
  [Helm] also provide for matching space-separated component regexps in
  any order. In Ivy, this is done with the `ivy--regex-ignore-order'
  matcher.  In Helm, it is the default, called "multi pattern matching".

  This package is significantly smaller than either of those because it
  solely defines a completion style, meant to be used with any
  completion UI supporting completion styles while both of those provide
  their own completion UI (and many other cool features!).

  It is worth pointing out that Helm does provide its multi pattern
  matching as a completion style which could be used with default tab
  completion, Icomplete or other UIs supporting completion styles! (Ivy
  does not provide a completion style to my knowledge.) So, for example,
  Icomplete users could, instead of using this package, install Helm and
  configure Icomplete to use it as follows:

  ┌────
  │ (require 'helm)
  │ (setq completion-styles '(helm basic))
  │ (icomplete-mode)
  └────

  (Of course, if you install Helm, you might as well use the Helm UI in
  `helm-mode' rather than Icomplete.)


[Ivy] <https://github.com/abo-abo/swiper>

[Helm] <https://github.com/emacs-helm/helm>


4.2 Prescient
─────────────

  The [prescient.el] library also provides matching of space-separated
  components in any order. It offers a completion-style that can be used
  with Emacs' default completion UI, Mct, Vertico or with Icomplete.
  Furthermore Ivy is supported. The components can be matched literally,
  as regexps, as initialisms or in the flex style (called "fuzzy" in
  prescient). Prescient does not offer the same flexibility as Orderless
  with its style dispatchers. However in addition to matching, Prescient
  supports sorting of candidates, while Orderless leaves that up to the
  candidate source and the completion UI.


[prescient.el] <https://github.com/radian-software/prescient.el>


4.3 Restricting to current matches in Icicles, Ido and Ivy
──────────────────────────────────────────────────────────

  An effect equivalent to matching multiple components in any order can
  be achieved in completion frameworks that provide a way to restrict
  further matching to the current list of candidates. If you use the
  keybinding for restriction instead of `SPC' to separate your
  components, you get out of order matching!

  • [Icicles] calls this /progressive completion/ and uses the
    `icicle-apropos-complete-and-narrow' command, bound to `S-SPC', to
    do it.

  • Ido has `ido-restrict-to-matches' and binds it to `C-SPC'.

  • Ivy has `ivy-restrict-to-matches', bound to `S-SPC', so you can get
    the effect of out of order matching without using
    `ivy--regex-ignore-order'.


[Icicles] <https://www.emacswiki.org/emacs/Icicles>
