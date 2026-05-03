A pure Emacs Lisp MySQL client that implements the MySQL wire protocol
directly, without depending on the external `mysql' CLI.

Usage:

  (require 'mysql)

  (let ((conn (mysql-connect :host "127.0.0.1"
                             :port 3306
                             :user "root"
                             :password "secret"
                             :database "mydb")))
    (let ((result (mysql-query conn "SELECT * FROM users LIMIT 10")))
      (mysql-result-rows result))
    (mysql-disconnect conn))
