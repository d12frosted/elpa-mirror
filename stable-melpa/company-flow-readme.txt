This package adds support for flow to company. It requires
flow to be in your path.

To use it, add to your company-backends:

  (eval-after-load 'company
    '(add-to-list 'company-backends 'company-flow))
