This package provides Romanian national holidays and other commemoration dates.

Installation:

    M-x package-install RET romanian-holidays RET

You'll likely need to add to your config files:

    (require 'romanian-holidays)

Or, with 'use-package', add to your config file:

    (use-package romanian-holidays)

Configuration:

You can use 'romanian-holidays' in several ways. Here are two examples.

To replace the built-in list of holidays with all the romanian ones:

    (setq calendar-holidays romanian-holidays-all-holidays)

To add the romanian legal days off as the user-defined holidays:

    (setq holiday-other-holidays romanian-holidays-legal)

You may want to disable all (or some of) the pre-defined holidays:

    (setq holiday-general-holidays nil
          holiday-bahai-holidays nil
          holiday-hebrew-holidays nil
          holiday-christian-holidays nil
          holiday-islamic-holidays nil
          holiday-oriental-holidays nil)

See also: 'calendar-holidays'.
