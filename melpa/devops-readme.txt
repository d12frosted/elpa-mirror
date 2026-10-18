
`devops.el' adds TARGET syntax to org-babel:

  #+TARGET: /ssh:web1.example.com: (web)
  #+TARGET: /ssh:db1.example.com: (db)

  * Check the web server                  :web:
  #+begin_src sh
  hostname
  #+end_src

  #+RESULTS:
  : web1

The package provides features that can be loaded separately:

(require 'devops)
  Run and tangle org-babel blocks on remote machines, chosen by
  heading tag.  Main entrypoint is `devops-mode'.

(require 'devops-drift)
  Detect drift between tangled blocks and the files on each
  target.  Main entrypoint is `devops-drift'.

(require 'devops-lob)
  Per-project Library of Babel from a project's tools.org.  Main
  entrypoint is `devops-lob-mode'.

Commands, on the heading at point:

- `devops-tangle'             tangle the heading's blocks to its target
- `devops-visit-file'         open tangled source block in the target
- `devops-open-terminal-dwim' open a terminal at the target
- `devops-drift'              (if loaded) report diff between blocks
                              and tangled files

If async is enabled (recommended)
- `devops-goto-session'       show the target's shell session
- `devops-restart-session'    kill the target's sessions

Options:

- `devops-enable-session-async'  run blocks in async session pool

Please report issues at
https://github.com/kpassapk/devops.el/issues
