Elbank is a personal finances reporting (and soon budgeting) application.
It uses Weboob (https://weboob.org) for scraping data.

Data is stored as JSON in `elbank-data-file' which defaults to
`$HOME/.emacs.d/elbank-data.json'.

Transactions are automatically categorized with `elbank-categories', an
association list of the form:

  '(("category1" . ("regexp1" "regexp2"))
    (("category2" . ("regexp")))
