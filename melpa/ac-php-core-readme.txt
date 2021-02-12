The core library of the `ac-php' package.  Acts like a backend for the
following components:

- `ac-php'
- `company-php'
- `helm-ac-php-apropros'

Can be used as an API to build your own components.  This engine currently
provides:

- Support of PHP code completion
- Support of jumping to definition/declaration/inclusion-file

When creating this package, the ideas of the following packages were used:

- auto-java-complete

  - `ac-php-remove-unnecessary-items-4-complete-method'
  - `ac-php-split-string-with-separator'

- auto-complete-clang

- rtags

  - `ac-php-location-stack-index'

Many options available under Help:Customize
Options specific to ac-php-core are in
  Convenience/Completion/Auto Complete

Known to work with Linux and macOS.  Windows support is in beta stage.
For more info and examples see URL `https://github.com/xcwen/ac-php' .

Bugs: Bug tracking is currently handled using the GitHub issue tracker
(see URL `https://github.com/xcwen/ac-php/issues')
