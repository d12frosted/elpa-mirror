A small authinfo/netrc parsing library to deal with more entries than just the default credentials (as in netrc library)

Here is an example of .authinfo
machine machine0 port http login nouser password nopass
machine machine1 login some-login password some-pwd port 993
machine machine2 login some-login port 587 password some-pwd
machine jabber   login some-login password some-pwd
machine description name "my name is" blog some-blog mail some-mail

Read the content of the file and return an alist:
(creds/read-lines "~/.authinfo")
> (("machine" "machine0" "port" "http" "login" "nouser" "password" "nopass")
   ("machine" "machine1" "login" "some-login" "password" "some-pwd" "port" "993")
   ("machine" "machine2" "login" "some-login" "port" "587" "password" "some-pwd")
   ("machine" "jabber" "login" "some-login" "password" "some-pwd")
   ("machine" "description" "name" "\"my name is\"" "blog" "some-blog" "mail" "some-mail"))

To retrieve the machine entry:
(creds/get data "machine1")
> ("machine" "machine1" "login" "some-login" "password" "some-pwd" "port" "993")

To retrieve the machine entry "machine2" with login "some-login"
(creds/get-with data '(("machine" . "machine2") ("login" . "some-login")))
> ("machine" "machine2" "login" "some-login" "port" "587" "password" "some-pwd")

To retrieve the value from the key in an entry line
(creds/get-entry '("machine" "machine2" "login" "some-login" "port" "587" "password" "some-pwd") "login")
> "some-login"
