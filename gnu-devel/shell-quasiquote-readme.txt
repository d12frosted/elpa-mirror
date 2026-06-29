"Shell quasiquote" -- turn s-expressions into POSIX shell command strings.

Shells other than POSIX sh are not supported.

Quoting is automatic and safe against injection.

  (let ((file1 "file one")
        (file2 "file two"))
    (shqq (cp -r ,file1 ,file2 "My Files")))
      => "cp -r 'file one' 'file two' 'My Files'"

You can splice many arguments into place with ,@foo.

  (let ((files (list "file one" "file two")))
    (shqq (cp -r ,@files "My Files")))
      => "cp -r 'file one' 'file two' 'My Files'"

Note that the quoting disables a variety of shell expansions like ~/foo,
$ENV_VAR, and e.g. {x..y} in GNU Bash.

You can use ,,foo to escape the quoting.

  (let ((files "file1 file2"))
    (shqq (cp -r ,,files "My Files")))
      => "cp -r file1 file2 'My Files'"

And ,,@foo to splice and escape quoting.

  (let* ((arglist '("-x 'foo bar' -y baz"))
         (arglist (append arglist '("-z 'qux fux'"))))
    (shqq (command ,,@arglist)))
      => "command -x 'foo bar' -y baz -z 'qux fux'"

Neat, eh?