This library extracts information from installed packages.

;; Functions:

`pkg-info-library-version' extracts the version from the header of a library.

`pkg-info-defining-library-version' extracts the version from the header of a
 library defining a function.

`pkg-info-package-version' gets the version of an installed package.

`pkg-info-format-version' formats a version list as human readable string.

`pkg-info-version-info' returns complete version information for a specific
package.

`pkg-info-get-melpa-recipe' gets the MELPA recipe for a package.

`pkg-info-get-melpa-fetcher' gets the fetcher used to build a package on
MELPA.

`pkg-info-wiki-package-p' determines whether a package was build from
EmacsWiki on MELPA.
