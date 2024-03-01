Java extension for the eglot LSP client.

Some of the key features include the following:
- Automatic installation of the Eclipse JDT LSP server (latest milestone release).
- Ability to pass JVM arguments to the Eclipse JDT LSP server (eglot-java-eclipse-jdt-args)
- Wizards for Spring, Micronaut, Quarkus, Vert.x, Maven and Gradle project creation
- Generic build command support for Maven and Gradle projects
- JUnit tests support, this hasn't been tested for a while...

eglot-java dynamically modifies  the "eglot-server-programs" variable,
you can change that behavior with the variable "eglot-java-eglot-server-programs-manual-updates"
- you may prefer using directly default jdtls Python script, eglot-java doesn't use that (eglot defaults to jdtls)
- eglot-java calls the relevant Java command directly, both for historical reasons and for potentially avoiding any Python dependency (Windows, Mac OS)

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
(with-eval-after-load 'eglot-java
  (define-key eglot-java-mode-map (kbd "C-c l n") #'eglot-java-file-new)
  (define-key eglot-java-mode-map (kbd "C-c l x") #'eglot-java-run-main)
  (define-key eglot-java-mode-map (kbd "C-c l t") #'eglot-java-run-test)
  (define-key eglot-java-mode-map (kbd "C-c l N") #'eglot-java-project-new)
  (define-key eglot-java-mode-map (kbd "C-c l T") #'eglot-java-project-build-task)
  (define-key eglot-java-mode-map (kbd "C-c l R") #'eglot-java-project-build-refresh))

Sometimes you may want to add/modify LSP server initialization settings.
JDT LS settings documentation: https://github.com/eclipse-jdtls/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
- For basic flexibility, you can control the ":settings" node of the LSP server configuration via the variable "eglot-workspace-configuration".
- For greater flexibility, you can leverage the "eglot-java-user-init-opts-fn" variable.
  - You'll need to bind the value of the "eglot-java-user-init-opts-fn" with your own callback function.
  - You'll need to return a property list of valid JDT LS settings (merged with defaults)

(setq eglot-java-user-init-opts-fn 'custom-eglot-java-init-opts)
(defun custom-eglot-java-init-opts (server eglot-java-eclipse-jdt)
  "Custom options that will be merged with default settings."
  '(:bundles ["/home/me/.emacs.d/lsp-bundles/com.microsoft.java.debug.plugin-0.50.0.jar"]
    :settings
    (:java
     (:format
      (:settings
       (:url "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml")
       :enabled t)))))

The behavior of the "eglot-java-run-test" function depends on the cursor location:
- If there's an enclosing method at the current cursor location, that specific test method will run
- Otherwise, all the tests in the current file will be executed

You can upgrade an existing LSP server installation with the "eglot-java-upgrade-lsp-server" function.
You can upgrade an existing JUnit jar installation with the "eglot-java-upgrade-junit-jar" function.
