
Add support for composer/installers to ede-php-autoload.

Allows ede-php-autoload to find classes even if composer/installers
has relocated the package.

Customize `ede-php-autoload-composer-installers-project-paths' to
specify the default installation path for package types, when not
specified in the extra section of composer.json.
