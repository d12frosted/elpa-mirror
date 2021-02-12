Provides Brazilian holidays as well as for each State.
To enable holidays for the desired State, just set a non-nil value for the
State variable.

E.g.:
(require 'brazilian-holidays)
(setq brazilian-holidays-rj-holidays t)

Or with `use-package`:

(use-package brazilian-holidays
 :custom
 (brazilian-holidays-rj-holidays t)
 (brazilian-holidays-sp-holidays t))
