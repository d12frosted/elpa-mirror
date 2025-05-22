Description
===========

The `company-forge' is a [company-mode] completion backend for [forge].  It
uses current `forge' repository data to offer completions for assignees
(`@' mentions of users and teams) and topics (`#' references to issues,
discussions, and pull requests).


[company-mode] <https://github.com/company-mode/company-mode>

[forge] <https://github.com/magit/forge>


Features
========

- Offer completion after entering `@' and `#'
- Support for users, teams, issues, discussions, and pull requests.
- Suppoet for different matching types (see `company-forge-match-type').
- Display [octicons] for candidates (see `company-forge-icons-mode').
- Display issues, discussions, and pull-request text as a documentation
  with `quickhelp-string' and `doc-buffer' `company' commands.
- Provide `company-forge-completion-at-point-function' compatible with
  built in command `completion-at-point'.


[octicons] <https://github.com/primer/octicons>


Installation
============

Installing from MELPA
~~~~~~~~~~~~~~~~~~~~~

The easiest way to install and keep `company-forge' up-to-date is using
Emacs' built-in package manager.  `company-forge' is available in the MELPA
repository.  Refer to <https://melpa.org/#/getting-started> for how to
install a package from MELPA.

Please see [Configuration] section for example configuration.

You can use any of the package managers that supports installation from
MELPA.  It can be one of (but not limited to): one of the built-in
`package', `use-package', or any other package manger that handles
autoloads generation, for example (in alphabetical order) [Borg], [Elpaca],
[Quelpa], or [straight.el].


[Configuration] See section Configuration

[Borg] <https://github.com/emacscollective/borg>

[Elpaca] <https://github.com/progfolio/elpaca>

[Quelpa] <https://github.com/quelpa/quelpa>

[straight.el] <https://github.com/radian-software/straight.el>


Installing from GitHub
~~~~~~~~~~~~~~~~~~~~~~

The preferred method is to use built-in `use-package'.  Add the following
to your Emacs configuration file (usually `~/.emacs' or
`~/.emacs.d/init.el'):

(use-package company-forge
  :vc (:url "https://github.com/pkryger/company-forge.el.git"
       :rev :newest)))

Please refer to [Configuration] section for example configuration.


[Configuration] See section Configuration


Configuration
=============

This section assumes you have `company-forge''s autoloads set up at Emacs
startup.  If you have installed `company-forge' using built-in `package' or
`use-package' then you should be all set.

(use-package company-forge
  :config
  (company-forge-icons-mode) ;; Display icons
  (advice-add #'forge--pull ;; Reset cache after forge pull
              :filter-args #'company-forge-reset-cache-after-pull)
  (add-to-list 'company-backends 'company-forge)
  (add-hook 'completion-at-point-functions
            #'company-forge-completion-at-point-function))


Customization
=============

Below is a list of configuration options and optional functions with their
synopses that can be used to customize `company-forge' behavior.  Please
refer to documentation of respective symbol for more details.

- user option: `company-forge-match-type': define how to match candidates
- user option: `company-forge-predicate': a buffer predicate to control if
  the backend is enabled
- user option: `company-forge-use-cache': control whether cache is used for
  candidates retrieval
- user option: `company-forge-capf-doc-buffer-function': a function used do
  show documentation when `company' backend `company-capf' is used
- minor mode: `comany-forge-icons-mode': control whether to display icons
  for candidates
- function: `company-forge-reset-cache-after-pull': designed as a
  `:filter-args' advice for `forge--pull'


Contributing
============

Contributions are welcome! Feel free to submit issues and pull requests on
the [GitHub repository].


[GitHub repository] <https://github.com/pkryger/company-forge.el>

Testing
~~~~~~~

When creating a pull request make sure all tests in
<file:test/company-forge.t.el> are passing.  When adding a new
functionality, please strive to add tests for it as well.

To run tests:
- open the <file:test/company-forge.t.el>
- type `M-x eval-buffer <RET>'
- type `M-x ert <RET> t <RET>'


Documentation autoring
~~~~~~~~~~~~~~~~~~~~~~

This package uses [org-commentary.el] (different from the one available on
MELPA!) to generate and validate commentary section in `company-forge.el'.
Please see the package documentation for usage instructions.


[org-commentary.el] <https://github.com/pkryger/org-commentary.el>
