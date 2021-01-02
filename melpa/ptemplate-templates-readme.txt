This package provides the official collection of `ptemplate' templates and a
convenient loader plugin for them. The templates here can be enabled by
simply turning on `ptemplate-templates-mode'. If the templates are no longer
wanted, `ptemplate-templates-mode' can also be turned off like any other
minor-mode.

The following configuration snippet will correctly configure
`ptemplate-templates:'
(eval-after-load 'ptemplate '(ptemplate-templates-mode 1))

Currently, only a few project templates are provided; other templates are
coming soon. New ones can be requested by opening an issue on github.
