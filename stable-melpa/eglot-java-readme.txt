Java extension for eglot.

Some of the key features include the following:
- Automatic installation of the Eclipse JDT LSP server.
- Ability to pass JVM arguments to the Eclipse JDT LSP server (eglot-java-eclipse-jdt-args)
- Wizards for Spring starter, Maven and Gradle project creation
- Generic build command support for Maven and Gradle projects
- JUnit tests support, this hasn't been tested for a while...

If you're having issues with Gradle projects (auto-completion), ensure that you're using the gradle wrapper in your projects:
- The root cause is likely JVM incompatibilities with the bundled Eclipse Gradle version
- Check your default JDK version
- If using a recent Eclipse JDT LS snapshot, check its bundled gradle version:  https://github.com/eclipse/buildship/blob/master/org.gradle.toolingapi/META-INF/MANIFEST.MF
- Check the gradle compatibility matrix: https://docs.gradle.org/current/userguide/compatibility.html
- Use the gradle wrapper to ensure that you always have a compatible matching JVM version
  - Edit directly your gradle/wrapper/gradle-wrapper.properties
  - or download the matching Gradle version for your JVM and run: gradle wrapper

Below is a sample configuration for your emacs init file

(add-hook 'java-mode-hook 'eglot-java-mode)
(add-hook 'eglot-java-mode-hook (lambda ()
  (define-key eglot-java-mode-map (kbd "C-c l n") #'eglot-java-file-new)
  (define-key eglot-java-mode-map (kbd "C-c l x") #'eglot-java-run-main)
  (define-key eglot-java-mode-map (kbd "C-c l t") #'eglot-java-run-test)
  (define-key eglot-java-mode-map (kbd "C-c l N") #'eglot-java-project-new)
  (define-key eglot-java-mode-map (kbd "C-c l T") #'eglot-java-project-build-task)
  (define-key eglot-java-mode-map (kbd "C-c l R") #'eglot-java-project-build-refresh)))
