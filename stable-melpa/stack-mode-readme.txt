
  'stack-mode' is a minor mode enabling various features based on
  the 'stack-ide' external process.

  Features:

      'M-.'      - Go to definition of thing at point.
      'C-c C-k'  - Clear the interaction buffer.
      'C-c C-t'  - Display type info of thing at point.
      'C-c C-i'  - Display the info of the thing at point.
      'C-c C-l'  - Load the current buffer's file.
      'C-c C-c'  - Load all files.

      'stack-mode' minor mode also integrates with Flycheck for
      on-the-fly GHC compiler error and HLint warning reporting.

  Conceptual Overview:

      'stack-mode' minor mode is a combination of two external
      processes, 'ide-backend' and 'stack', wrapped up into the
      'stack-ide' process. 'ide-backend' drives the GHC API to
      build, query, and run your code. 'stack' is a cross-platform
      program for developing Haskell projects.
