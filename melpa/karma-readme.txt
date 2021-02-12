 Karma Test Runner Emacs Integration

 Usage:

   You need to create an `.karma` file inside your project directory to inform
   Karma.el where to get the Karma config file and the Karma executable.

   Example .karma file:

     {
       "config-file": "karma.coffee",
       "karma-command": "node_modules/karma/bin/karma"
     }

   The `config-file` and the `karma-command` paths need to be relative or absoulte
   to the your project directory.
