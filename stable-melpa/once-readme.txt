This library provides two main functions:

- `once-hook', substitute for `add-hook'
- `once-load', substitute for `eval-after-load'

They are like `add-hook' and `eval-after-load' respectively,
except that they only result in calling the provided function once: at the
next time the hook is run or the file is loaded, respectively.

The variants

- `once-hook*'
- `once-load*'

can be explained if you think of the main functions as being called
"pushnew-self-deleting-hook", and these just "push-self-deleting-hook".

The macros

- `once-hook!'
- `once-load!'

are meant to help with writing Emacs init-files.


;; Examples:

Unset some default keys in geiser-repl, when that file first loads:

    (once-load! geiser-repl
      (keymap-unset geiser-repl-mode-map "M-," t)
      (keymap-unset geiser-repl-mode-map "M-." t)
      (keymap-unset geiser-repl-mode-map "M-`" t))

Configure font after the daemon makes its first emacsclient frame:

    (once-hook! server-after-make-frame-hook
      (set-face-font 'default (font-spec :family "Iosevka Nerd Font" :size 29)))

By the way, setting hooks in init-files is a natural fit for the ## macro
from Llama.  No problems combining that with this library:

    (once-load 'org (##setopt org-todo-keywords '((sequence "IDEA" "DONE"))))

Setting up a `my-first-frame-hook':

    (if (daemonp)
        (once-hook 'server-after-make-frame-hook (##run-hooks 'my-first-frame-hook))
      (add-hook 'emacs-startup-hook (##run-hooks 'my-first-frame-hook)))

The advantage of `once-hook' plus Llama, compared to `once-hook!', is that
the former preserves the exact calling convention of `add-hook'.
That makes it trivial to rewrite from `add-hook' to `once-hook' and back.
Note the identical arguments:

    (add-hook  'enable-theme-functions (##message "Loaded theme %s" %) -50)
    (once-hook 'enable-theme-functions (##message "Loaded theme %s" %) -50)
