;;; eglot-java.el --- Java extension for the eglot LSP client  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2023 Yves Zoundi

;; Version: 1.8
;; Package-Version: 20230122.2144
;; Package-Commit: 472bf005b1dfa92464257fcfdebefa1fe91a586f
;; Author: Yves Zoundi <yves_zoundi@hotmail.com>
;; Maintainer: Yves Zoundi <yves_zoundi@hotmail.com>
;; URL: https://github.com/yveszoundi/eglot-java
;; Keywords: convenience, languages
;; Package-Requires: ((emacs "26.1") (eglot "1.0") (jsonrpc "1.0.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Java extension for eglot.
;;
;; Some of the key features include the following:
;; - Automatic installation of the Eclipse JDT LSP server.
;; - Ability to pass JVM arguments to the Eclipse JDT LSP server (eglot-java-eclipse-jdt-args)
;; - Wizards for Spring starter, Maven and Gradle project creation
;; - Generic build command support for Maven and Gradle projects
;; - JUnit tests support, this hasn't been tested for a while...
;;
;; If you're having issues with Gradle projects (auto-completion), ensure that you're using the gradle wrapper in your projects:
;; - The root cause is likely JVM incompatibilities with the bundled Eclipse Gradle version
;; - Check your default JDK version
;; - If using a recent Eclipse JDT LS snapshot, check its bundled gradle version:  https://github.com/eclipse/buildship/blob/master/org.gradle.toolingapi/META-INF/MANIFEST.MF
;; - Check the gradle compatibility matrix: https://docs.gradle.org/current/userguide/compatibility.html
;; - Use the gradle wrapper to ensure that you always have a compatible matching JVM version
;;   - Edit directly your gradle/wrapper/gradle-wrapper.properties
;;   - or download the matching Gradle version for your JVM and run: gradle wrapper
;;
;; If for any reason, you want to prevent "eglot-java" from modifying the "eglot-server-programs" variable,
;; you can toggle the value of the variable "eglot-java-eglot-server-programs-manual-updates"
;; - upstream "eglot" could change the syntax of programs associations without notice and it will break this package
;; - you may want fine-grained control over how "eglot-java" behaves accordingly to your emacs customization
;;
;; Below is a sample configuration for your emacs init file
;;
;; (add-hook 'java-mode-hook 'eglot-java-mode)
;; (add-hook 'eglot-java-mode-hook (lambda ()
;;   (define-key eglot-java-mode-map (kbd "C-c l n") #'eglot-java-file-new)
;;   (define-key eglot-java-mode-map (kbd "C-c l x") #'eglot-java-run-main)
;;   (define-key eglot-java-mode-map (kbd "C-c l t") #'eglot-java-run-test)
;;   (define-key eglot-java-mode-map (kbd "C-c l N") #'eglot-java-project-new)
;;   (define-key eglot-java-mode-map (kbd "C-c l T") #'eglot-java-project-build-task)
;;   (define-key eglot-java-mode-map (kbd "C-c l R") #'eglot-java-project-build-refresh)))

;;; Code:

(require 'project)
(require 'eglot)

(defgroup eglot-java
  nil
  "Interaction with a Java language server via eglot."
  :prefix "eglot-java-"
  :group 'eglot)

(defcustom eglot-java-eglot-server-programs-manual-updates
  nil
  "Do not try to automatically update eglot-server-programs"
  :type 'boolean
  :group 'eglot-java)

(defcustom eglot-java-eclipse-jdt-args
  '()
  "Eclipse JDT JVM arguments."
  :type '(repeat string)
  :group 'eglot-java)

(defcustom eglot-java-eclipse-jdt-ls-download-url
  "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz"
  "URL to download the latest Eclipse JDT language server."
  :type 'string
  :group 'eglot-java)

(defcustom eglot-java-junit-platform-console-standalone-jar-url
  "http://repository.sonatype.org/service/local/artifact/maven/redirect?r=central-proxy&g=org.junit.platform&a=junit-platform-console-standalone&v=LATEST"
  "URL to download the latest JUnit platform standalone console jar."
  :type 'string
  :group 'eglot-java)

(defcustom eglot-java-server-install-dir
  (concat user-emacs-directory "share/eclipse.jdt.ls")
  "Location of the Eclipse Java language server installation."
  :type 'directory
  :group 'eglot-java
  :link '(url-link :tag "Github" "https://github.com/yveszoundi/eglot-java"))

(defcustom eglot-java-junit-platform-console-standalone-jar
  (concat user-emacs-directory "share/junit-platform-console-standalone/junit-platform-console-standalone.jar")
  "Location of the vscode test runner."
  :type 'file
  :group 'eglot-java)

(defcustom eglot-java-spring-io-excluded-input-params
  '("_links" "dependencies")
  "Excluded input parameters."
  :type '(repeat string)
  :group 'eglot-java)

(defcustom eglot-java-spring-starter-url-projectdef
  "https://start.spring.io"
  "Start url."
  :type 'string
  :group 'eglot-java)

(defcustom eglot-java-spring-starter-url-starterzip
  "https://start.spring.io/starter.zip"
  "API endpoint to create a spring boot project."
  :type 'string
  :group 'eglot-java)

(defcustom eglot-java-workspace-folder
  (expand-file-name "~")
  "Java projects default folder."
  :type 'string
  :group 'eglot-java)

(defconst eglot-java-build-filename-maven  "pom.xml"      "Maven build file name.")
(defconst eglot-java-build-filename-gradle "build.gradle" "Gradle build file name.")

(defvar eglot-java-spring-starter-jsontext nil "Spring IO JSON payload.")
(defvar eglot-java-project-new-directory nil "The newly created java project directory location.")
(make-variable-buffer-local 'eglot-java-project-new-directory)

(declare-function tar-untar-buffer "tar-mode" ())
(declare-function xml-get-children "xml" (node child-name))

(defclass eglot-eclipse-jdt (eglot-lsp-server) ()
  :documentation "Eclipse's Java Development Tools Language Server.")

(cl-defmethod eglot-initialization-options ((server eglot-eclipse-jdt))
  "Passes through required jdt initialization options."
  `(:workspaceFolders
    [,@(cl-delete-duplicates
        (mapcar #'eglot--path-to-uri
                (let* ((root (project-root (eglot--project server))))
                  (cons root
                        (mapcar
                         #'file-name-directory
                         (append
                          (file-expand-wildcards (concat root "*/pom.xml"))
                          (file-expand-wildcards (concat root "*/build.gradle"))
                          (file-expand-wildcards (concat root "*/.project")))))))
        :test #'string=)]
    ,@(if-let ((home (or (getenv "JAVA_HOME")
                         (ignore-errors
                           (expand-file-name
                            ".."
                            (file-name-directory
                             (file-chase-links (executable-find "javac"))))))))
          `(:settings (:java (:home ,home)
                             :import (:gradle (:enabled t)
                                              :wrapper (:enabled t))))
        (ignore (eglot--warn "JAVA_HOME env var not set")))))

(defun eglot--eclipse-jdt-contact (interactive)
  "Return a contact for connecting to eclipse.jdt.ls server, as a cons cell.
If INTERACTIVE, prompt user for details."
  (cl-labels
      ((is-the-jar
        (path)
        (and (string-match-p
              "org\\.eclipse\\.equinox\\.launcher_.*\\.jar$"
              (file-name-nondirectory path))
             (file-exists-p path))))
    (let* ((classpath (or (getenv "CLASSPATH") path-separator))
           (cp-jar (cl-find-if #'is-the-jar (split-string classpath path-separator)))
           (jar cp-jar)
           (dir
            (cond
             (jar (file-name-as-directory
                   (expand-file-name ".." (file-name-directory jar))))
             (interactive
              (expand-file-name
               (read-directory-name
                (concat "Path to eclipse.jdt.ls directory (could not"
                        " find it in CLASSPATH): ")
                nil nil t)))
             (t (error "Could not find eclipse.jdt.ls jar in CLASSPATH"))))
           (repodir
            (concat dir
                    "org.eclipse.jdt.ls.product/target/repository/"))
           (repodir (if (file-directory-p repodir) repodir dir))
           (config
            (concat
             repodir
             (cond
              ((string= system-type "darwin") "config_mac")
              ((string= system-type "windows-nt") "config_win")
              (t "config_linux"))))
           (workspace
            (expand-file-name (md5 (project-root (eglot--current-project)))
                              (locate-user-emacs-file
                               "eglot-eclipse-jdt-cache"))))
      (unless jar
        (setq jar
              (cl-find-if #'is-the-jar
                          (directory-files (concat repodir "plugins") t))))
      (unless (and jar (file-exists-p jar) (file-directory-p config))
        (error "Could not find required eclipse.jdt.ls files (build required?)"))
      (when (and interactive (not cp-jar)
                 (y-or-n-p (concat "Add path to the server program "
                                   "to CLASSPATH environment variable?")))
        (setenv "CLASSPATH" (concat (getenv "CLASSPATH") path-separator jar)))
      (unless (file-directory-p workspace)
        (make-directory workspace t))
      (cons 'eglot-eclipse-jdt
            (nconc
             (list
              (executable-find "java")
              "-Declipse.application=org.eclipse.jdt.ls.core.id1"
              "-Dosgi.bundles.defaultStartLevel=4"
              "-Declipse.product=org.eclipse.jdt.ls.core.product")
             eglot-java-eclipse-jdt-args
             (list
              "-jar" jar
              "-configuration" config
              "-data" workspace))))))

(cl-defmethod eglot-execute-command
  ((_server eglot-eclipse-jdt) (_cmd (eql java.apply.workspaceEdit)) arguments)
  "Eclipse JDT breaks spec and replies with edits as arguments."
  (mapc #'eglot--apply-workspace-edit arguments))

(defun eglot-java--download-file (source-url dest-location)
  "Download a file from a URL at SOURCE-URL and save it to file at DEST-LOCATION."
  (let* ((dest-dir     (file-name-directory dest-location))
         (dest-abspath (expand-file-name dest-location)))
    (unless (file-exists-p dest-dir)
      (make-directory dest-dir t))
    (message "Downloading %s\n to %s." source-url dest-abspath)
    (url-copy-file  source-url dest-abspath t)))

(defun eglot-java--project-try (dir)
  "Return project instance if DIR is part of a Java project.
Otherwise returns nil"
  (let ((root (or (locate-dominating-file dir eglot-java-build-filename-maven)
                  (locate-dominating-file dir ".project")
                  (locate-dominating-file dir eglot-java-build-filename-gradle))))
    (and root (cons 'java root))))

(cl-defmethod project-root ((project (head java)))
  "Get the root of a JAVA PROJECT."
  (cdr project))

(defun eglot-java--find-equinox-launcher ()
  "Find the equinox jar launcher in the LSP plugins directory."
  (let* ((lsp-java-server-plugins-dir (concat
                                       (file-name-as-directory
                                        (expand-file-name eglot-java-server-install-dir))
                                       "plugins"))
         (equinox-launcher-jar        (car (directory-files lsp-java-server-plugins-dir
                                                            nil
                                                            "^org.eclipse.equinox.launcher_.*.jar$"
                                                            t))))
    (if (not equinox-launcher-jar)
        (user-error "Could not find Eclipse OSGI jar launcher!"))

    (expand-file-name equinox-launcher-jar
                      lsp-java-server-plugins-dir)))

(defun eglot-java--eclipse-contact (_interactive)
  "Setup the classpath in an INTERACTIVE fashion."
  (let ((cp (getenv "CLASSPATH")))
    (setenv "CLASSPATH" (concat cp path-separator (eglot-java--find-equinox-launcher)))
    (unwind-protect
        (eglot--eclipse-jdt-contact nil)
      (setenv "CLASSPATH" cp))))

(defun eglot-java--project-name-maven (root)
  "Return the name of a Maven project in the folder ROOT.
This extracts the project name from the Maven POM (artifactId)."
  (let* ((pom    (expand-file-name eglot-java-build-filename-maven root))
         (xml    (xml-parse-file pom))
         (parent (car xml)))
    (caddar (xml-get-children parent 'artifactId))))

(defun eglot-java--project-gradle-p (root)
  "Check if a project stored in the folder ROOT is using Gradle as build tool."
  (file-exists-p (expand-file-name eglot-java-build-filename-gradle
                                   (file-name-as-directory root)) ))

(defun eglot-java--project-name-gradle (root)
  "Return the name of a Gradle project in the folder ROOT.
If a settings.gradle file exists, it'll be parsed to extract the project name.
Otherwise the basename of the folder ROOT will be returned."
  (let ((build-file (expand-file-name "settings.gradle" root)))
    (if (file-exists-p build-file)
        (let* ((build           (expand-file-name "settings.gradle" root))
               (gradle-settings (with-temp-buffer
                                  (insert-file-contents build)
                                  (goto-char (point-min))
                                  (search-forward "rootProject.name")
                                  (search-forward "=")
                                  (buffer-substring (point) (line-end-position)))))
          (string-trim (cl-reduce
                        (lambda (acc item)
                          (replace-regexp-in-string item "" acc))
                        '("'" "\"")
                        :initial-value gradle-settings)))
      (file-name-nondirectory (directory-file-name (file-name-directory build-file))))))

(defun eglot-java--project-name (root)
  "Return the Java project name stored in a given folder ROOT."
  (if (eglot-java--project-gradle-p root)
      (eglot-java--project-name-gradle root)
    (eglot-java--project-name-maven root)))

(defun eglot-java--file--test-p (file-path)
  "Tell if a file locate at FILE-PATH is a test class."
  (eglot-execute-command
   (eglot--current-server-or-lose)
   "java.project.isTestFile"
   (vector (eglot--path-to-uri file-path ))))

(defun eglot-java--project-classpath (filename scope)
  "Return the classpath for a given FILENAME and SCOPE."
  (plist-get (eglot-execute-command (eglot--current-server-or-lose)
                                    "java.project.getClasspaths"
                                    (vector (eglot--path-to-uri filename)
                                            (json-encode `(( "scope" . ,scope)))))
             :classpaths))

(defun eglot-java-file-new ()
  "Create a new class."
  (interactive)
  (let* ((class-by-type     #s(hash-table
                               size 5
                               test equal
                               data ("Class"      "public class %s {\n\n}"
                                     "Enum"       "public enum %s {\n\n}"
                                     "Interface"  "public interface %s {\n\n}"
                                     "Annotation" "public @interface %s {\n\n}"
                                     "Test"       "import org.junit.jupiter.api.Assertions;\n
import org.junit.jupiter.api.Test;\n\npublic class %s {\n\n}")))
         (source-list       (eglot-execute-command
                             (eglot--current-server-or-lose)
                             "java.project.listSourcePaths" (list)))
         (source-paths      (mapcar
                             #'identity
                             (car  (cl-remove-if-not #'vectorp source-list))))
         (display-paths     (mapcar (lambda (e)
                                      (plist-get e :displayPath))
                                    source-paths))
         (selected-path     (completing-read "Source path : " display-paths))
         (fqcn              (read-string "Class name: "))
         (class-type        (completing-read "Type: " (hash-table-keys class-by-type)))
         (selected-source   (car (cl-remove-if-not
                                  (lambda (e)
                                    (string= (plist-get e :displayPath) selected-path))
                                  source-paths )))
         (path-elements     (split-string fqcn "\\."))
         (new-paths         (butlast path-elements))
         (dest-folder       (file-name-as-directory
                             (expand-file-name
                              (mapconcat #'identity new-paths "/")
                              (plist-get selected-source :path))))
         (simple-class-name (car (last path-elements))))

    (unless (file-exists-p dest-folder)
      (make-directory dest-folder t))

    (find-file
     (concat (file-name-as-directory dest-folder)
             (format "%s.java" simple-class-name)))
    (save-buffer)

    (when new-paths
      (insert "package " (mapconcat #'identity new-paths ".") ";\n\n"))

    (insert (format (gethash class-type class-by-type)
                    simple-class-name))

    (save-buffer)))

(defun eglot-java-run-test ()
  "Run a test class."
  (interactive)
  (let* ((fqcn                 (eglot-java--class-fqcn))
         (cp                   (eglot-java--project-classpath (buffer-file-name) "test"))
         (current-file-is-test (not (equal ':json-false (eglot-java--file--test-p (buffer-file-name))))))

    (unless (file-exists-p eglot-java-junit-platform-console-standalone-jar)
      (eglot-java--download-file eglot-java-junit-platform-console-standalone-jar-url
                                 eglot-java-junit-platform-console-standalone-jar))

    (if current-file-is-test
        (compile
         (concat "java -jar "
                 eglot-java-junit-platform-console-standalone-jar
                 (if (string-match-p "#" fqcn)
                     " -m "
                   " -c ")
                 fqcn
                 " -class-path "
                 (mapconcat #'identity cp path-separator)
                 " ")
         t)
      (user-error "No test found in current file! Is the file saved?" ))))

(defun eglot-java-run-main ()
  "Run a main class."
  (interactive)
  (let* ((fqcn (eglot-java--class-fqcn))
         (cp   (eglot-java--project-classpath (buffer-file-name) "runtime")))
    (if fqcn
        (compile
         (concat "java -cp "
                 (mapconcat #'identity cp path-separator)
                 " "
                 fqcn)
         t)
      (user-error "No main method found in this file! Is the file saved?!"))))

(defun eglot-java--class-fqcn ()
  "Return the fully qualified name of a given class."
  (let* ((document-symbols (eglot-java--document-symbols))
         (package-name     (eglot-java--symbol-value document-symbols "Package"))
         (class-name       (eglot-java--symbol-value document-symbols "Class"))
         (package-suffix   (if (string= "" package-name)
                               package-name
                             ".")))
    (format "%s%s%s" package-name package-suffix class-name)))

(defun eglot-java--symbol-value (symbols symbol-type)
  "Extract the symbol value for a given SYMBOL-TYPE from a symbol table SYMBOLS."
  (let ((symbol-details (cl-find-if
                         (lambda (elem)
                           (let* ((elem-kind (plist-get elem :kind))
                                  (elem-type (cdr (assoc elem-kind eglot--symbol-kind-names))))
                             (string= elem-type symbol-type)))
                         symbols)))
    (if symbol-details
        (plist-get symbol-details :name)
      "")))

(defun eglot-java--document-symbols ()
  "Fetch the document symbols/tokens."
  (jsonrpc-request
   (eglot--current-server-or-lose)
   :textDocument/documentSymbol
   (list :textDocument (list :uri (eglot--path-to-uri (buffer-file-name))))))

(defun eglot-java--spring-initializr-fetch-json (url)
  "Retrieve the Spring initializr JSON model from a given URL."
  (require 'url)
  (let ((url-request-method        "GET")
        (url-request-extra-headers '(("Accept" . "application/vnd.initializr.v2.1+json")))
        (url-request-data          (mapconcat (lambda (arg)
                                                (concat (url-hexify-string (car arg))
                                                        "="
                                                        (url-hexify-string (cdr arg))))
                                              (list)
                                              "&")))
    (url-retrieve url 'eglot-java--spring-switch-to-url-buffer)))

(defun eglot-java--spring-switch-to-url-buffer (_status)
  "Switch to the buffer returned by `url-retrieve'.
The buffer contains the raw HTTP response sent by the server."
  (require 'json)
  (let* ((json-object-type 'hash-table)
         (json-array-type  'list)
         (json-key-type    'string))
    (setq eglot-java-spring-starter-jsontext (json-read-from-string
                                              (eglot-java--buffer-whole-string (current-buffer))))
    (kill-buffer)))

(defun eglot-java--buffer-whole-string (buffer)
  "Retrieve the text contents from an HTTP response BUFFER."
  (with-current-buffer buffer
    (save-restriction
      (widen)
      (re-search-forward "^$")
      (buffer-substring-no-properties (point) (point-max)))))

(defun eglot-java--spring-read-json ()
  "Fetch the JSON model for creating Spring projects via spring initializr."
  (eglot-java--spring-initializr-fetch-json eglot-java-spring-starter-url-projectdef))

(defun eglot-java-project-new ()
  "Create a new Java project."
  (interactive)
  (let ((project-type (completing-read "Project Type: " '("spring" "maven" "gradle") nil t "spring")))
    (funcall (intern (concat "eglot-java--project-new-" project-type)))))

(defun eglot-java--project-new-maven ()
  "Create a new Maven project."
  (let ((mvn-project-parent-dir    (read-directory-name "Enter parent directory: "))
        (mvn-group-id              (read-string         "Enter group id: "))
        (mvn-artifact-id           (read-string         "Enter artifact id: "))
        (mvn-archetype-artifact-id (read-string         "Enter archetype artifact id: " "maven-archetype-quickstart")))

    (let ((b
           (eglot-java--build-run
            mvn-project-parent-dir
            (eglot-java--build-executable "mvn" "mvnw" mvn-project-parent-dir)
            (concat " archetype:generate "
                    " -DgroupId=" mvn-group-id
                    " -DartifactId=" mvn-artifact-id
                    " -DarchetypeArtifactId=" mvn-archetype-artifact-id
                    " -DinteractiveMode=false"))))

      (let ((dest-dir (expand-file-name mvn-artifact-id mvn-project-parent-dir))
            (p        (get-buffer-process b)))
        (with-current-buffer b
          (setq eglot-java-project-new-directory dest-dir))

        (set-process-sentinel p #'eglot-java--project-new-process-sentinel)))))

(defun eglot-java--project-new-gradle ()
  "Create a new Gradle project."
  (let* ((gradle-project-parent-dir (read-directory-name "Enter parent directory:"))
         (gradle-project-name       (read-string         "Enter project name (no spaces): "))
         (init-dsls                 '("groovy" "kotlin"))
         (init-types                '("java-application" "java-library" "java-gradle-plugin" "basic"))
         (init-test-frameworks      '("junit-jupiter" "spock" "testng"))
         (selected-dsl              (completing-read "Select init DSL: "
                                                     init-dsls
                                                     nil
                                                     t
                                                     (car init-dsls)))
         (selected-project-type     (completing-read "Select init type: "
                                                     init-types
                                                     nil
                                                     t
                                                     (car init-types)))
         (selected-test-framework   (completing-read "Select test framework: "
                                                     init-test-frameworks
                                                     nil
                                                     t
                                                     (car init-test-frameworks)))
         (selected-project-dir      (expand-file-name gradle-project-name gradle-project-parent-dir)))

    (unless (file-exists-p selected-project-dir)
      (make-directory selected-project-dir t))

    (let ((b
           (eglot-java--build-run
            selected-project-dir
            (eglot-java--build-executable "gradle" "gradlew" selected-project-dir)
            (mapconcat #'identity
                       (list "init"
                             "--type"
                             selected-project-type
                             "--test-framework"
                             selected-test-framework
                             "--dsl"
                             selected-dsl)
                       " "))))
      (with-current-buffer b
        (setq eglot-java-project-new-directory selected-project-dir))

      (set-process-sentinel (get-buffer-process b) #'eglot-java--project-new-process-sentinel))))

(defun eglot-java--project-new-spring ()
  "Create a new Spring java project using spring initializr. User input parameters are extracted from the JSON structure."
  (unless eglot-java-spring-starter-jsontext
    (eglot-java--spring-read-json)
    (while (not eglot-java-spring-starter-jsontext)
      (sleep-for 1)
      (message "Downloading spring initializr JSON data...")))

  (let* ((elems         (cl-remove-if
                         (lambda (node-name)
                           (member node-name eglot-java-spring-io-excluded-input-params))
                         (hash-table-keys eglot-java-spring-starter-jsontext)))
         (simple-params (mapcar
                         (lambda (p)
                           (let ((elem-type (gethash "type" (gethash p eglot-java-spring-starter-jsontext))))
                             (cond ((or (string= "single-select" elem-type)
                                        (string= "action" elem-type))
                                    (list
                                     p
                                     (completing-read
                                      (format "Select %s: " p)
                                      (mapcar
                                       (lambda (f)
                                         (gethash "id" f))
                                       (gethash "values" (gethash p
                                                                  eglot-java-spring-starter-jsontext)))
                                      nil t (gethash "default" (gethash p
                                                                        eglot-java-spring-starter-jsontext)))))
                                   ((string= "text" elem-type)
                                    (list p
                                          (read-string (format "Select %s: " p)
                                                       (gethash "default" (gethash p
                                                                                   eglot-java-spring-starter-jsontext))))))))
                         elems))
         (simple-deps   (completing-read-multiple "Select dependencies (comma separated, TAB to add more): "
                                                  (apply #'nconc
                                                         (mapcar
                                                          (lambda (s)
                                                            (mapcar
                                                             (lambda (f)
                                                               (gethash "id" f))
                                                             s))
                                                          (mapcar
                                                           (lambda (x)
                                                             (gethash "values" x))
                                                           (gethash "values"  (gethash "dependencies" eglot-java-spring-starter-jsontext )))))))
         (dest-dir     (read-directory-name "Project directory: "
                                            (expand-file-name (cadr (assoc "artifactId" simple-params)) eglot-java-workspace-folder))))

    (unless (file-exists-p dest-dir)
      (make-directory dest-dir t))

    (let ((large-file-warning-threshold nil)
          (dest-file-name (expand-file-name (concat (format-time-string "%Y-%m-%d_%N") ".zip")
                                            dest-dir))
          (source-url     (format "%s?%s"
                                  eglot-java-spring-starter-url-starterzip
                                  (url-build-query-string (append simple-params
                                                                  (list
                                                                   (list "dependencies"
                                                                         (mapconcat
                                                                          #'identity
                                                                          (nconc simple-deps)
                                                                          "," ))))))))
      (url-copy-file source-url dest-file-name t)
      (dired (file-name-directory dest-file-name))
      (revert-buffer))))

(defun eglot-java--project-new-process-sentinel (process event)
  "Switch to the project directory when the PROCESS finishes with a success EVENT."
  (when (string-prefix-p "finished" event)
    (switch-to-buffer (process-buffer process))
    (dired eglot-java-project-new-directory)
    (revert-buffer)))

(defun eglot-java--build-run (initial-dir cmd args)
  "Start a compilation from a direction INITIAL-DIR with a given command string CMD and its arguments string ARGS."
  (let ((mvn-cmd           (concat cmd " " args))
        (default-directory initial-dir))
    (compile mvn-cmd t)))

(defun eglot-java--build-executable(cmd cmd-wrapper-name cmd-wrapper-dir)
  "Return the command to run, either the initial command itself CMD or its wrapper equivalent (CMD-WRAPPER-NAME) if found in CMD-WRAPPER-DIR."
  (let ((cmd-wrapper-abspath (executable-find (expand-file-name
                                               cmd-wrapper-name
                                               cmd-wrapper-dir))))
    (if (and cmd-wrapper-abspath
             (file-exists-p cmd-wrapper-abspath))
        cmd-wrapper-abspath
      cmd)))

(defun eglot-java-project-build-refresh ()
  "Build the project when Maven or Gradle build files are found."
  (interactive)
  (let* ((root       (cdr (project-current)))
         (build-file (if (eglot-java--project-gradle-p root)
                         (expand-file-name eglot-java-build-filename-gradle (file-name-as-directory root))
                       (expand-file-name eglot-java-build-filename-maven (file-name-as-directory root)))))
    (when (file-exists-p build-file)
      (progn
        (jsonrpc-notify
         (eglot--current-server-or-lose)
         :java/projectConfigurationUpdate
         (list :uri (eglot--path-to-uri build-file)))
        (jsonrpc-notify
         (eglot--current-server-or-lose)
         :java/buildWorkspace
         '((:json-false)))))))

(defun eglot-java-project-build-task ()
  "Run a new build task."
  (interactive)
  (let* ((project-dir               (cdr (project-current)))
         (goal                      (read-string "Task & Parameters: " "test"))
         (project-is-gradle-project (eglot-java--project-gradle-p project-dir))
         (build-filename            (if project-is-gradle-project
                                        eglot-java-build-filename-gradle
                                      eglot-java-build-filename-maven))
         (build-filename-flag       (if project-is-gradle-project
                                        "-b"
                                      "-f"))
         (build-cmd                 (if project-is-gradle-project
                                        (eglot-java--build-executable "gradle" "gradlew" project-dir)
                                      (eglot-java--build-executable "mvn" "mvnw" project-dir))))
    (async-shell-command (format
                          "%s %s %s %s"
                          build-cmd
                          build-filename-flag
                          (shell-quote-argument
                           (expand-file-name build-filename project-dir))
                          goal))))

(defun eglot-java--install-lsp-server ()
  "Install the Eclipse JDT LSP server."
  (let* ((dest-dir                     (expand-file-name eglot-java-server-install-dir))
         (download-url                 eglot-java-eclipse-jdt-ls-download-url)
         (dest-filename                (file-name-nondirectory download-url))
         (dest-abspath                 (expand-file-name dest-filename dest-dir))
         (large-file-warning-threshold nil))
    (message "Installing Eclipse JDT LSP server, please wait...")
    (eglot-java--download-file download-url dest-abspath)
    (message "Extracting Eclipse JDT LSP archive, please wait...")
    (with-temp-buffer
      (let ((temporary-buffer (find-file dest-abspath)))
        (goto-char (point-min))
        (tar-untar-buffer)
        (kill-buffer temporary-buffer)))
    (delete-file dest-abspath)
    (message "Eclipse JDT LSP server installed in folder \n\"%s\"." dest-dir)))

(defun eglot-java--ensure ()
  "Install the LSP server as needed and then turn-on eglot."
  (unless (file-exists-p (expand-file-name eglot-java-server-install-dir))
    (eglot-java--install-lsp-server))
  (eglot-ensure))

(defun eglot-java--init ()
  "Initialize the library for use with the Eclipse JDT language server."
  (progn
    (unless eglot-java-eglot-server-programs-manual-updates
      (let ((existing-java-related-assocs (mapcan (lambda (item)
                                                    (if (listp (car item))
                                                        (when (member 'java-mode (car item))
                                                          (car item))
                                                      (when (eq 'java-mode (car item))
                                                        (cons (car item) nil))))
                                                  eglot-server-programs)))
        (if existing-java-related-assocs
            (progn
              (let ((eff-existing-java-related-assocs (if (= 1 (length existing-java-related-assocs))
                                                          (if (assq existing-java-related-assocs eglot-server-programs)
                                                              existing-java-related-assocs
                                                            (car existing-java-related-assocs))
                                                        existing-java-related-assocs)))
                (unless (eq 'eglot-java--eclipse-contact (assq eff-existing-java-related-assocs eglot-server-programs))
                  (setcdr (assoc eff-existing-java-related-assocs eglot-server-programs) 'eglot-java--eclipse-contact))))
          (add-to-list eglot-server-programs 'java-mode 'eglot-java--eclipse-contact))))
    (unless (member 'eglot-java--project-try project-find-functions)
      (add-hook 'project-find-functions  #'eglot-java--project-try))))

(defvar eglot-java-mode-map (make-sparse-keymap))

;;;###autoload
(define-minor-mode eglot-java-mode
  "Toggle eglot-java-mode."
  ;; The initial value.
  :init-value nil
  ;; The indicator for the mode line.
  :lighter nil
  (progn
    (eglot-java--init)
    (when eglot-java-mode
      (eglot-java--ensure))))

(provide 'eglot-java)
;;; eglot-java.el ends here
