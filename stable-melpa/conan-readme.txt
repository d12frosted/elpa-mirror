This can be used in org-source to get the compile flags for source
blocks.  see https://github.com/Carl2/conan-elisp

conan-install

Install Conan packages for `libs', with `flags' specifying the options.

Usage:
(conan-install CONAN-LIBS-LIST FLAGS &optional PRE POST)

CONAN-LIBS-LIST is a string containing the names and versions of the Conan
packages to be installed, separated by space.  For example: "fmt/8.1.1 zlib/1.2.13".

FLAGS is expected to be one of the symbols 'include, 'libs, 'both, or 'all.
These options specify which Conan package information to extract:

- 'include extracts the include paths for the Conan packages.
- 'libs extracts the library paths for the Conan packages.
- 'both extracts both the include and library paths for the Conan packages.
- 'all is equivalent to 'both.

The function first extracts the Conan package names and versions from CONAN-LIBS-LIST
and calls the `conan-conan-install` function to install the packages.
It then extracts the include and/or library paths for the installed packages
based on the FLAGS option, and sets the corresponding Emacs Lisp variables to
these paths.

PRE - These are compile flags that are added before the conan flags when compiling

POST - Flags that are added to the compile flags after the conan flags.

Example usage:
(conan-install "fmt/8.1.1 zlib/1.2.13" 'libs "-std=c++20 -Wall -Wextra" "-O3")

This installs the Conan packages for fmt and zlib with version numbers 8.1.1 and 1.2.13,
respectively, and extracts the library paths for these packages.
It will also add the PRE-flags "-std=c++20 -Wall -Wextra" before the conan flags

this would possibly look something like:
g++ -std=c++20 -Wall -Wextra -I/home/user/.conan2/p/b/fmt038de2f1e357a/p/include \
   -I/home/user/.conan2/p/sml056dfa7919d57/p/include \
   -L/home/user/.conan2/p/b/fmt038de2f1e357a/p/lib \
   -lfmt -lm -O3 main.cpp

Examples
(conan-install "fmt/10.1.1 sml/1.1.6 zlib/1.2.13" 'all)
With pre flags
(conan-install "fmt/10.1.1 sml/1.1.9" 'all "-std=c++20 -Wall -Wextra")
With post flags
(conan-install "fmt/10.1.1 sml/1.1.9" 'all nil "-std=c++20 -Wall -Wextra")
With both pre and post flags
(conan-install "fmt/10.1.1 sml/1.1.9" 'all "-std=c++20 -Wall -Wextra" "-o /tmp/myElf")

When compiling
Note: This function assumes that Conan 2.0 is installed on the system and that the
necessary Conan packages are available.

todo alot! Buts its a start..
