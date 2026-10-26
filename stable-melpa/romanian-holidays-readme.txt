This package provides Romanian national holidays and other commemoration dates.

Installation:

    M-x package-install RET romanian-holidays RET

Or, with `use-package', add to your config file:

    (use-package romanian-holidays)

(Add ':ensure t' or `use-package-always-ensure' to actually install it, and see
configuration example below.)

Configuration:

The package defines several holidays lists:
- `romanian-holidays-general-holidays'
- `romanian-holidays-christian-holidays'
- `romanian-holidays-legal-holidays'  (combines the first two lists above)
- `romanian-holidays-other-holidays'  (various other holidays)
- `romanian-holidays-all-holidays'  (all of the above)

You can use these in several ways.  A few examples follow.

To replace the built-in list of holidays with all the Romanian ones:

    (setq calendar-holidays romanian-holidays-all-holidays)

To add the Romanian legal days off as the user-defined holidays you can use `setopt'
(Emacs 29+), or use `customize-set-variable'.

Note that `calendar-holidays' is set from `holiday-*-holidays' variables when package
`holidays.el' is loaded.  As `romanian-holidays.el' requires it, it is loaded along
with this package when something like `require' or `use-package' loads it, so setting
it with `setq' afterwards has no effect.

    (setopt holiday-other-holidays romanian-holidays-legal-holidays)

You may want to disable all (or some of) the pre-defined holidays:

    (setopt holiday-general-holidays nil
            holiday-bahai-holidays nil
            holiday-hebrew-holidays nil
            holiday-christian-holidays nil
            holiday-islamic-holidays nil
            holiday-oriental-holidays nil)

With `use-package':

    (use-package romanian-holidays
      :ensure t
      :custom
      (holiday-other-holidays romanian-holidays-all-holidays)
      (holiday-christian-holidays nil))

See also: `calendar-holidays'.
