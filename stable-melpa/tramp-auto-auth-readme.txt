This library provides ‘tramp-auto-auth-mode’: a global minor mode
whose purpose is to automatically feed TRAMP sub-processes with
passwords for paths matching regexps.  This is useful in situations
where interactive user input is not desirable or feasible.  For
instance, in sub-nets with large number of hosts or whose hosts
have dynamic IPs assigned to them.  In those cases it’s not
practical to query passwords using the ‘auth-source’ library
directly, since this would require each host to be listed
explicitly and immutably in a Netrc file.  Another scenario where
this mode is useful are non-interactive Emacs sessions (like those
used for batch processing or by evaluating ‘:async’ Org Babel
source blocks) in which it’s impossible for the user to answer a
password-asking prompt.

When a TRAMP prompt is encountered, ‘tramp-auto-auth-mode’ queries
the alist ‘tramp-auto-auth-alist’ for the auth-source spec value
whose regexp key matches the correspondent TRAMP path.  This spec
is then used to query the auth-source library for a presumably
phony entry exclusively dedicated to the whole class of TRAMP
paths matching that regexp.

To make use of the automatic authentication feature, on the Lisp
side the variable ‘tramp-auto-auth-alist’ must be customized to
hold the path regexps and their respective auth-source specs, and
then ‘tramp-auto-auth-mode’ must be enabled.  For example:

---- ~/.emacs.el -------------------------------------------------
(require 'tramp-auto-auth)

(add-to-list
 'tramp-auto-auth-alist
 '("root@10\\.0\\." .
   (:host "Funny-Machines" :user "root" :port "ssh")))

(tramp-auto-auth-mode)
------------------------------------------------------------------

After this, just put the respective sacred secret in an
authentication source supported by auth-source library.  For
instance:

---- ~/.authinfo.gpg ---------------------------------------------
machine Funny-Machines login root password "$r00tP#sWD!" port ssh
------------------------------------------------------------------

In case you are feeling lazy or the secret is not so secret (nor so
sacred) -- or for any reason you need to do it all from Lisp --
it’s enough to:

(auth-source-remember '(:host "Funny-Machines" :user "root" :port "ssh")
		         '((:secret "$r00tP#sWD!")))

And happy TRAMPing!
