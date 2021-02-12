
PHP EDE project that supports class autoloading and composer.json detection.

Example project definition :
(ede-php-autoload-project "My project"
                      :file "/path/to/a/file/at/root"
                      :class-autoloads '(:psr-0 (("MyNs" . "src/MyNs")
                                                ("AnotherNs" . "src/AnotherNs"))
                                         :psr-4 (("MyModernNs" . "src/modern/MyNs"))))

This EDE project can then be used through a semanticdb
backend.  Enable it by activating `ede-php-autoload-mode'.
