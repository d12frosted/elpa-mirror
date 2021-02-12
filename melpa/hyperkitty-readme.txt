
This package provides an Emacs interface for reading Mailman 3 archives
hosted via Hyperkitty.

To use it, you need to set `hyperkitty-mlists' variable to a list of pairs
of Mailinglist and base url for the hyperkitty's hosted instance.  For
example:

    (setq
       hyperkitty-mlists
       ((cons "test@mailman3.org" "https://lists.mailman3.org/archives")))

Then, you can simply use `M-x hyperkitty' to start using.
