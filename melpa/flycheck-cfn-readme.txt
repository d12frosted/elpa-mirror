This package adds support for AWS Cloudformation in Flycheck.

To use, first install the requisite tools:

~gem install cfn_nag~
~pip install cfn-lint~

For information about these checkers, and how to handle configuration and
exceptions, see the following links:

- cfn_nag :: `https://github.com/stelligent/cfn_nag'
- cfn-lint :: `https://github.com/aws-cloudformation/cfn-python-lint'

To use, do:
(add-hook 'cfn-mode-hook
  (setq flycheck-checkers (append flycheck-checkers '(cfn-lint cfn-nag))))
