Get the Personal API Access Token from:
https://yourteam.esa.io/user/tokens

Put following to your .emacs:

(require 'esa)
(setq esa-token "******************************")
(setq esa-team-name "yourteam")

TODO:
- Add esa-tokens-and-team-names defcustom
- Encrypt risky configs
