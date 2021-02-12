This package provides integration of the Yocto Bitbake tool with
emacs. Its main features are:

- interacting with the bitbake script so that you can run bitbake
  seamlessly from emacs. If your editing a recipe, recompiling is
  just one M-x bitbake-recompile command away,
- deploying recipes output directly to your target device over ssh
  for direct testing (if your image supports read-write mode),
- generating wic images,
- a global minor mode providing menu and shortcuts,
- an mmm based mode to edit bitbake recipes.
