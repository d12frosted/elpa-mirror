This is a port of epg.el and epa-file.el, original copyright applies.

age.el is intended to provide transparent Age based file encryption
and decryption in Emacs.  As such age.el does not support all
Age CLI based use cases.  Rather age.el assumes you have configured
a default identity and a default recipient, e.g. based off your
ssh private key and ssh public key in ~/.ssh/id_rsa[.pub], which
is the default setting.

The main use case is for folks who like to e.g. encrypt their org
notes and things of that nature.  Since age.el provides is a direct
port from EPG/EPA it can support all roles that .gpg files can
support in Emacs, e.g. ~/.authinfo.age should work fine as well.

Usage:

Put age.el somewhere in your load-path and:

(require 'age)
(age-file-enable)
