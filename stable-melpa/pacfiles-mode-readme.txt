
`pacfiles-mode' is an Emacs major mode to manage `.pacnew` and `.pacsave`
files left by Arch's pacman. To merge files, *pacfiles-mode* automatically
creates an Ediff merge session that a user can interact with. After finishing
the Ediff merge session, *pacfiles-mode* cleans up the mess that Ediff leaves
behind. *pacfiles-mode* also takes care of keeping the correct permissions of
merged files, and requests passwords (with TRAMP) to act as root when needed.

Start the major mode using the command `pacfiles' or `pacfiles/start'.
