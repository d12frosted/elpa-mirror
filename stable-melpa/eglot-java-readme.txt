Java extension for eglot. Some of the key features include the following:
- Automatic installation of the Eclipse JDT LSP server.
- Ability to pass JVM arguments to the Eclipse JDT LSP server (eglot-java-eclipse-jdt-args)
- Wizards for Spring starter, Maven and Gradle project creation
- Generic build command support for Maven and Gradle projects
- JUnit tests support, this hasn't been tested for a while...

Add the following lines to your .emacs configuration;;

(eval-after-load 'eglot-java
 (progn
   (require 'eglot-java)
   ;; The prefix key will be associated to the keymap eglot-mode-map
   ;; This is a customizable variable in the eglot-java group
   (setq eglot-java-prefix-key "C-c l")
   (setq eglot-java-default-bindings-enabled t)
   '(eglot-java-init)))
