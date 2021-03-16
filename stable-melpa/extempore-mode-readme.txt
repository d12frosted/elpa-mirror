   A major mode for editing Extempore code. See the Extempore project page at
   http://github.com/digego/extempore for more details.

 Installation

   Available through MELPA:

   M-x `package-install' RET `extempore-mode' RET

   If you don't want to get it from MELPA, just download the file and use
   `package-install-file'

   (package-install-file "/path/to/extempore-mode.el")


 Configuration

   (optional) if you don't want to have to answer the "directory" prompt
   every time you call `extempore-run', you can set the `extempore-path'
   variable (either in your init file or through the customisation interface)

   (setq extempore-path "/path/to/extempore/")


 Usage

   The most important commands are:

     M-x `extempore-connect' (C-c C-j)

     M-x `switch-to-extempore' (C-c C-z)

     M-x `extempore-send-dwim' (C-M-x)

   For more usage instructions, see README.md
