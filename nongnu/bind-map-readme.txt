Table of Contents
─────────────────

1. bind-map
.. 1. Binding keys in the maps
.. 2. Avoiding repetition


[file:https://travis-ci.org/justbur/emacs-bind-map.svg?branch=master]
[file:http://melpa.org/packages/bind-map-badge.svg]


[file:https://travis-ci.org/justbur/emacs-bind-map.svg?branch=master]
<https://travis-ci.org/justbur/emacs-bind-map>

[file:http://melpa.org/packages/bind-map-badge.svg]
<http://melpa.org/#/bind-map>


1 bind-map
══════════

  bind-map is an Emacs package providing the macro `bind-map' which can
  be used to make a keymap available across different "leader keys"
  including ones tied to evil states. It is essentially a generalization
  of the idea of a leader key as used in vim or the Emacs [evil-leader]
  package, and allows for an arbitrary number of "leader keys". This is
  probably best explained with an example.

  ┌────
  │ (bind-map my-base-leader-map
  │   :keys ("M-m")
  │   :evil-keys ("SPC")
  │   :evil-states (normal motion visual))
  │ (bind-map my-elisp-map
  │   :keys ("M-m m" "M-RET")
  │   :evil-keys ("SPC m" ",")
  │   :major-modes (emacs-lisp-mode
  │ 		lisp-interaction-mode))
  └────

  This will make `my-base-leader-map' (automatically creating the map if
  it's not defined yet) available under the prefixes (or leaders) `M-m'
  and `SPC', where the latter is only bound in evil's normal, motion or
  visual states. The second declaration makes `my-elisp-map' available
  under the specified keys when one of the specified major modes is
  active. In the second case, the evil states used are also normal
  motion and visual because this is the default as specified in
  `bind-map-default-evil-states'. It is possible to make the bindings
  conditional on minor modes being loaded, or a mix of major and minor
  modes. Since the symbols of the modes are used, it is not necessary to
  ensure that any of the mode's packages are loaded prior to this
  declaration. See the docstring of `bind-map' for more options.

  This package will only make use of evil if one of the evil related
  keywords is specified. This declaration, for example, makes no use of
  the evil package.

  ┌────
  │ (bind-map my-elisp-map
  │   :keys ("M-m m" "M-RET")
  │   :major-modes (emacs-lisp-mode
  │ 		lisp-interaction-mode))
  └────

  The idea behind this package is that you want to organize your
  personal bindings in a series of keymaps separate from built-in mode
  maps. You can simply add keys using the built-in `define-key' to
  `my-elisp-map' for example, and a declaration like the one above will
  take care of ensuring that these bindings are available in the correct
  places.


[evil-leader] <https://github.com/cofi/evil-leader>

1.1 Binding keys in the maps
────────────────────────────

  You may use the built-in `define-key' which will function as intended.
  `bind-key' (part of [use-package]) is another option. For those who
  want a different interface, you may either use the `:bindings' keyword
  in the `bind-map' macro or the two provided functions
  `bind-map-set-keys' and `bind-map-set-key-defaults', which both just
  use `define-key' internally, but allow for multiple bindings without
  much syntax.

  ┌────
  │ (bind-map my-base-leader-map
  │   :keys ("M-m")
  │   :evil-keys ("SPC")
  │   :evil-states (normal motion visual)
  │   :bindings ("c" 'compile
  │ 	     "C" 'check))
  │ 
  │ (bind-map-set-keys my-base-leader-map
  │   "c" 'compile
  │   "C" 'check
  │   ;; ...
  │   )
  │   ;; is the same as
  │   ;; (define-key my-base-leader-map (kbd "c") 'compile)
  │   ;; (define-key my-base-leader-map (kbd "C") 'check)
  │   ;; ...
  │ 
  │ (bind-map-set-key-defaults my-base-leader-map
  │   "c" 'compile
  │   ;; ...
  │   )
  │   ;; is the same as
  │   ;; (unless (lookup-key my-base-leader-map (kbd "c"))
  │   ;;   (define-key my-base-leader-map (kbd "c") 'compile))
  │   ;; ...
  └────

  The second function only adds the bindings if there is no existing
  binding for that key. It is probably only useful for shared
  configurations, where you want to provide a default binding but don't
  want that binding to overwrite one made by the user. Note the keys in
  both functions are strings that are passed to `kbd' before binding
  them.


[use-package] <https://github.com/jwiegley/use-package>


1.2 Avoiding repetition
───────────────────────

  If you use multiple `bind-map' declarations you might find yourself
  repeating properties like `:evil-keys' and `:evil-states'. You may use
  `bind-map-for-mode-inherit' to automatically pull these properties
  from a parent map as the following example illustrates. See the
  docstring for more information.

  ┌────
  │ (bind-map my-leader-map
  │   :keys ("M-m")
  │   :evil-keys ("SPC")
  │   :evil-states (normal motion visual))
  │ 
  │ (bind-map-for-mode-inherit my-markdown-map my-leader-map
  │   :major-modes (markdown-mode))
  └────
