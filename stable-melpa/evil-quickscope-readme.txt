This package emulates quick_scope.vim by Brian Le
(https://github.com/unblevable/quick-scope). It highlights targets for
evil-mode's f,F,t,T keys, allowing for quick navigation within a line with no
additional mappings.

The functionality is wrapped into two different minor modes. Only one can be
activated at a time.

evil-quickscope-always-mode provides targets at all times and directly
emulates quick_scope.vim. It can be activated by adding the following to
~/.emacs:

    (require 'evil-quickscope)
    (global-evil-quickscope-always-mode 1)

Alternatively, you can enable evil-quickscope-always-mode in certain modes by
adding 'turn-on-evil-quickscope-always-mode' to the mode hook. For example:

    (add-hook 'prog-mode-hook 'turn-on-evil-quickscope-always-mode)

evil-quickscope-mode provides targets only after one of the f,F,t,T keys are
pressed. It can be activated by adding the following to ~/.emacs:

    (require 'evil-quickscope)
    (global-evil-quickscope-mode 1)

Or, you can use 'turn-on-evil-quickscope-mode' as a mode hook:

    (add-hook 'prog-mode-hook 'turn-on-evil-quickscope-mode)

This program requires EVIL (http://bitbucket.org/lyro/evil/wiki/Home)
