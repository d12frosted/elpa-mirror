
This small package provides a class and functions to set up python execution configurations.
It is possible to configure the python execution command, virtualenv to load and use for the run,
environment variables, parameters to pass and the directory where to execute the python file.

Usage:

You can use the `pyconf-add-config' function passing a `pyconf-config' object
You can then call `pyconf-start' to execute one of your configurations
Example:
(pyconf-add-config (pyconf-config :name "test1"
                                  :pyconf-exec-command "python3"
                                  :pyconf-file-to-exec "~/test/test.py"
                                  :pyconf-path-to-exec "~/test/"
                                  :pyconf-params "--verbose"
                                  :pyconf-venv "~/test/.venv/"
                                  :pyconf-env-vars '("TEST5=5")))

Add multiple configurations:
(pyconf-add-configurations `(,(pyconf-config :name "test3"
                                             :pyconf-exec-command "python3 -i"
                                             :pyconf-file-to-exec "~/test/test.py"
                                             :pyconf-path-to-exec "~/test/"
                                             :pyconf-params ""
                                             :pyconf-venv "~/test/.venv/"
                                             :pyconf-env-vars '("TEST5=5"))
                             ,(pyconf-config :name "test2"
                                             :pyconf-exec-command "python3 -i"
                                             :pyconf-file-to-exec "~/test/test.py"
                                             :pyconf-path-to-exec "~/test/"
                                             :pyconf-params ""
                                             :pyconf-venv "~/test/.venv/"
                                             :pyconf-env-vars '("TEST5=5"))))
