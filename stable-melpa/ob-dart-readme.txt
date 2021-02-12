   - Currently only supports execution of Dart code that can be wrapped
     in Dart main() method body.
 Todo:
   - Support any valid Dart code, including class definitions and
     the main() method
   - Session support

; Requirements:
- Dart language installed - An implementation can be downloaded from
                            https://www.dartlang.org/downloads/
- The dart executable is on the PATH
- (Optional) Dart major mode -  Can be installed from MELPA

Notes:
  - Code follows / inspired by these previously supported org-languages,
    roughly in this order:
    - ob-io.el
    - ob-scala.el
    - ob-groovy.el
    - ob-R.el
    - ob-python.el
