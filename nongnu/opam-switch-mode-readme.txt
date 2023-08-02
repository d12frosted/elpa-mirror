# opam-switch-mode

[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/opam-switch-mode.svg)](https://elpa.nongnu.org/nongnu/opam-switch-mode.html)
[![MELPA Stable](https://stable.melpa.org/packages/opam-switch-mode-badge.svg)](https://stable.melpa.org/#/opam-switch-mode)
[![MELPA](https://melpa.org/packages/opam-switch-mode-badge.svg)](https://melpa.org/#/opam-switch-mode)

Provide a command `opam-switch-set-switch` to change the opam switch
of the running Emacs session, and a minor mode `opam-switch-mode` to
select the opam switch via a (menu-bar or mode-bar) menu.

The menu is generated each time the minor mode is enabled and contains the
switches that are known at that time. If you create a new switch, re-enable
the minor mode to get it added to the menu. The menu contains an additional
entry "reset" to reset the environment to the state when Emacs was started.

## Installing `opam-switch-mode`

We recommend to install this mode from either the 
[NonGNU ELPA](https://elpa.nongnu.org/) or the
[MELPA](https://melpa.org/) repository of Emacs packages.
In the sequel, we assume you have already set up those in your `.emacs`.

If you use the
[`use-package`](https://github.com/jwiegley/use-package) macro, the
recommended configuration is as follows:

    (use-package opam-switch-mode
      :ensure t
      :hook
      ((coq-mode tuareg-mode) . opam-switch-mode))

If you don't use `use-package`, do the following instead:

    (add-hook 'coq-mode-hook #'opam-switch-mode)
    (add-hook 'tuareg-mode-hook #'opam-switch-mode)

so that the minor mode is automatically enabled when `coq-mode` or `tuareg-mode` is on,
see also [`opam-switch-mode` aware modes](#opam-switch-mode-aware-modes).

## Command `opam-switch-set-switch`

Invoke with `M-x opam-switch-set-switch RET`.

Choose and set an opam switch.

Set opam switch SWITCH-NAME, which must be a valid opam switch name. When
called interactively, the switch name must be entered in the minibuffer,
which forces completion to a valid switch name or the empty string.

Setting the opam switch for the first time inside Emacs will save the
current environment. Using the empty string for SWITCH-NAME will reset the
environment to the saved values.

The switch is set such that all process invocations from Emacs respect the
newly set opam switch. In addition to setting environment variables such as
PATH and CAML_LD_LIBRARY_PATH, this also sets `exec-path`, which controls
Emacs' subprocesses (`call-process`, `make-process` and similar functions).

Just before the switch is changed, `opam-switch-before-change-opam-switch-hook` runs.
After the switch is changed, `opam-switch-change-opam-switch-hook` runs.
One of these can be used to inform other modes that run background processes
that depend on the currently active opam switch.

For obvious reasons, `opam-switch-set-switch` will only affect Emacs and not
any other shells outside Emacs.

## `opam-switch-mode` aware modes

- `coq-mode` from [`proof-general`](https://proofgeneral.github.io/)
  can kill the Coq background process when the opam switch changes,
  see option [`coq-kill-coq-on-opam-switch`](https://proofgeneral.github.io/doc/master/userman/Coq-Proof-General/#index-coq_002dkill_002dcoq_002don_002dopam_002dswitch).
- `tuareg-mode` from [`tuareg`](https://github.com/ocaml/tuareg)
  can kill the OCaml background process when the opam switch changes,
  see option `tuareg-kill-ocaml-on-opam-switch`.
- `merlin-mode` from [`merlin`](https://github.com/ocaml/merlin)
  can kill the underlying Merlin server when the opam switch changes,
  see option `merlin-stop-server-on-opam-switch`.
