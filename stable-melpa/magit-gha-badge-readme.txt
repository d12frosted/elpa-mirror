A GitHub Actions status badge at the top of the magit status buffer,
and a buffer of the workflow runs with their jobs, steps and logs.

Setup:

  (magit-add-section-hook 'magit-status-sections-hook
                          #'magit-gha-badge-insert
                          'magit-insert-status-headers
                          'append)

Auth: requests go through `ghub-request' with `magit-gha-badge-auth'
(default `ghub'), i.e. the generic ghub token: an authinfo entry like

  machine api.github.com login USER^ghub password TOKEN

plus `github.user' set in git config.
