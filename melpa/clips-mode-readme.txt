There are 5 steps necessary to utilize clips-mode:
1. Install the package clips-mode preferrably via ELPA or Cask.
2. Require it: (require 'clips-mode)
3. Decide whether you want to use a natively compiled CLIPS executable or
   the CLIPSJNI version that runs on a Java Virtual Machine (JVM).
4. If you are using a native version, then configure the program name
   like this: (setq inferior-clips-program "clips")
5. If you are using the JVM version, then configure which JVM to use like
   this: (setq inferior-clips-vm "java") and then configure a function
   which returns a list of strings that are passed as arguments to the
   previously specified JVM that result in the CLIPJNI shell being executed.
6. Read inf-clips.el to see the keybindings for executing CLIPS commands in
   the CLIPS shell.
