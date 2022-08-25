;;; flycheck-swiftx.el --- Flycheck: Swift backend -*- lexical-binding: t; -*-

;; Copyright (c) 2019 John Buckley <john@olivetoast.com>

;; Author: John Buckley <john@olivetoast.com>
;; URL: https://github.com/nhojb/flycheck-swiftx
;; Package-Version: 20200814.845
;; Package-Commit: 4d0c8ca0540b06fb947a83f1a38a6003a5abe0d4
;; Version: 1.0.2
;; Keywords: convenience, languages, tools
;; Package-Requires: ((emacs "26.1") (flycheck "26") (xcode-project "1.0"))

;; This file is not part of GNU Emacs.

;; MIT License

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; A Swift backend for Flycheck with support for Xcode projects.
;;
;; Features:
;;
;; - Apple Swift 5
;;
;; - Xcode projects
;;   Flycheck-swiftx can parse Xcode projects and use the build settings for the project.
;;   This means that complex projects, which may include various dependencies, can be
;;   typechecked automatically with swiftc.
;;
;; - For non-Xcode projects provide your own configuration via `flycheck-swiftx-build-options` and `flycheck-swiftx-sources`.
;;
;; - `xcrun` command support (only on macOS)
;;
;; Installation:
;;
;; In your `init.el`
;;
;; (with-eval-after-load 'flycheck
;;   (require 'flycheck-swiftx))
;;
;; or with `use-package`:
;;
;; (use-package flycheck-swiftx
;;  :after flycheck)
;;

;;; Code:

(require 'flycheck)
(require 'xcode-project)

(flycheck-def-option-var flycheck-swiftx-project-type 'automatic swiftx
  "Specify the project type.

Determines how project settings (SDK, compilation flags, source files etc)
will be obtained.

When `automatic' flycheck-swiftx will search for a project as follows:
  1. An Xcode project in the current buffer's directory or parent directories.
  2. Otherwise fall back to using `flycheck-swiftx-build-options' and `flycheck-swiftx-sources'
     (which may be specified via .dir-local.el in the project's root directory).

In the first two cases the project's root directory is that containing
the Xcode project or .dir-locals.el."
  :type '(choice (const :tag "Automatic project detection" automatic)
                 (const :tag "Xcode project" xcode)
                 (const :tag "None" nil))
  :safe #'symbolp)

(flycheck-def-option-var flycheck-swiftx-xcode-build-config "Debug" swiftx
  "Build configuration to use when extracting build settings from the
Xcode project."
  :type 'string
  :safe #'stringp)

(flycheck-def-option-var flycheck-swiftx-xcrun-toolchain nil swiftx
  "Specify which toolchain to use to perform the lookup.

When non-nil, set the toolchain identifier or name to use to
perform the lookup, via `--toolchain'.
The option is available only on macOS."
  :type 'string
  :safe #'stringp)

(flycheck-def-option-var flycheck-swiftx-sdk nil swift
  "Specify which SDK to use when typechecking (macos, iphoneos etc).

Ignored if the sdk is obtained from an Xcode project.

When non-nil, set the SDK name to find the tools, via `xcrun --sdk'.
The option is available only on macOS.

Use `xcodebuild -showsdks' to list the available SDK names."
  :type 'string
  :safe #'stringp)

(flycheck-def-option-var flycheck-swiftx-build-options nil swiftx
  "An list of swiftc build options.

If an Xcode project is found, these build options
are additional to the Xcode project's options.

May be specified as a dir local variable in the project's root."
  :type '(repeat (string :tag "Build option"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swiftx-sources nil swiftx
  "Specify sources files/directory to parse.

Ignored if source files are obtained from an Xcode project.

- When `flycheck-swiftx-sources' is a single directory, flycheck-swiftx will
  recursively include all .swift files found in the directory.
- When `flycheck-swiftx-sources' is a list of file paths, include these as-is.

Paths may be absolute or specified relative to the project's root directory.
May be specified as a dir local variable in the project's root."
  :type '(repeat (string :tag "Source directory or file list"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swiftx-project-target nil swiftx
  "Specify the target to use when extracting build settings from a project.

Ignored if no project is found or the target is not valid.
May be specified as a dir local variable in the project's root."
  :type 'string
  :safe #'stringp)

(flycheck-def-option-var flycheck-swiftx-build-env
    '((LOCAL_DEVELOPER_DIR . "/Library/Developer")
      (LOCAL_LIBRARY_DIR . "/Library"))
    swiftx
  "An alist of environment variables to apply to build settings.

For example: LOCAL_DEVELOPER_DIR, LOCAL_LIBRARY_DIR, etc

A default set of standard env variables are provided.

May be specified as a dir local variable in the project's root."
  :type '(repeat (string :tag "Environment var"))
  :safe #'listp)

(defvar flycheck-swiftx--cache-directory nil
  "The cache directory for `flycheck-swiftx'.")

(defun flycheck-swiftx--cache-location ()
  "Get the cache location for `flycheck-swiftx'.

If no cache directory exists yet, create one and return it.
Otherwise return the previously used cache directory."
  (setq flycheck-swiftx--cache-directory
        (or flycheck-swiftx--cache-directory
            ;; Note: we can't use flycheck-temp-dir-system because the temp dir
            ;; will be destroyed after each run of the checker...
            (make-temp-file flycheck-temp-prefix 'directory))))

(defun flycheck-swiftx--cache-cleanup ()
  "Cleanup `flycheck-swiftx' cache directory."
  (when (and flycheck-swiftx--cache-directory
             (file-directory-p flycheck-swiftx--cache-directory))
    (flycheck-safe-delete flycheck-swiftx--cache-directory))
  (setq flycheck-swiftx--cache-directory nil))

;; Clean-up cache directories
(add-hook 'kill-emacs-hook #'flycheck-swiftx--cache-cleanup)

;; Xcode project support

(defun flycheck-swiftx--find-xcodeproj (file-name)
  "Search FILE-NAME directory and parent directories for a Xcode project file.

Prefers an Xcode project with the same name as FILE-NAME's parent directory."
  (let* (projects
         (directory (file-name-directory file-name))
         (base-name (format "%s.xcodeproj" (directory-file-name directory))))
    (when (file-directory-p directory)
      (while (and (not projects) (not (equal directory "/")))
        (setq projects (directory-files directory t ".*\\.xcodeproj$" t))
        (setq directory (file-name-directory (directory-file-name directory)))))
    ;; Prefer project matching "<base-name>.xcodeproj"
    (or (seq-find (lambda (path) (equal path base-name)) projects)
        (car projects))))

(defun flycheck-swiftx--xcodeproj-modtime (xcproj-path)
  "Return the modification time for XCPROJ-PATH."
  (setq xcproj-path (expand-file-name xcproj-path))
  (if (and xcproj-path (file-directory-p xcproj-path))
      (nth 5 (file-attributes (xcode-project-concat-path xcproj-path "project.pbxproj")))))

;; TODO: Would be better to cache the filelist and only rebuild when modtime changes ;-)
(defun flycheck-swiftx--xcodeproj-cache-path (xcproj-path)
  "Return the cache path for the specified XCPROJ-PATH."
  (when (and xcproj-path (file-directory-p xcproj-path))
    (format "%s%s.%s" (file-name-as-directory (flycheck-swiftx--cache-location))
            (file-name-nondirectory xcproj-path)
            (time-to-seconds (flycheck-swiftx--xcodeproj-modtime xcproj-path)))))

(defun flycheck-swiftx--read-xcode-project-cache (xcproj-path)
  "Return the project cache for XCPROJ-PATH.
Return nil if the cache is not found, or the modification time of the project
has changed."
  (when-let (cache-path (flycheck-swiftx--xcodeproj-cache-path xcproj-path))
    (when (file-exists-p cache-path)
      (xcode-project-deserialize cache-path))))

(defun flycheck-swiftx--write-xcode-project-cache (proj xcproj-path)
  "Cache the parsed project PROJ for XCPROJ-PATH."
  (when-let (cache-path (flycheck-swiftx--xcodeproj-cache-path xcproj-path))
    (ignore-errors (xcode-project-serialize proj cache-path))))

(defun flycheck-swiftx--load-xcode-project (xcproj-path)
  "Load and return the Xcode project found at XCPROJ-PATH.

If the parsed Xcode project is found in our cache, return that.
Otherwise read from disk, cache and return the project."
  (setq xcproj-path (expand-file-name xcproj-path))
  (when (and xcproj-path (file-directory-p xcproj-path))
    (or (flycheck-swiftx--read-xcode-project-cache xcproj-path)
        (when-let (proj (xcode-project-read xcproj-path))
          (flycheck-swiftx--write-xcode-project-cache proj xcproj-path)
          proj))))

(defconst flycheck-swiftx--test-re "[tT]ests?$"
  "Regular expression used to match test files or targets.")

(defun flycheck-swiftx--maybe-test (file-name)
  "Return t if FILE-NAME is probably a test file."
  (or (string-match-p flycheck-swiftx--test-re (file-name-base file-name))
        (string-match-p flycheck-swiftx--test-re (directory-file-name (file-name-directory file-name)))))

(defun flycheck-swiftx--target-name (file-name xcproj)
  "Return the most appropriate XCPROJ target for FILE-NAME."
  (let* ((targets (xcode-project-target-names-for-file xcproj file-name "PBXSourcesBuildPhase"))
         (prefer-tests (flycheck-swiftx--maybe-test file-name)))
    (if (member flycheck-swiftx-project-target targets)
        flycheck-swiftx-project-target
      (seq-find (lambda (target) (if prefer-tests
                                     (string-match-p flycheck-swiftx--test-re target)
                                   (not (string-match-p flycheck-swiftx--test-re target))))
                targets
                (car targets)))))

(defun flycheck-swiftx--xcode-build-settings (xcproj target-name)
  "Return the build settings for the specified XCPROJ and TARGET-NAME."
  (let ((config-name (or flycheck-swiftx-xcode-build-config "Debug")))
    (when xcproj
      (alist-get 'buildSettings (xcode-project-build-config xcproj
                                                            config-name
                                                            target-name)))))
(defun flycheck-swiftx--deployment-target (build-settings)
  "Return the platform target for BUILD-SETTINGS."
  (when build-settings
      (let ((macos-target (alist-get 'MACOSX_DEPLOYMENT_TARGET build-settings))
            (iphoneos-target (alist-get 'IPHONEOS_DEPLOYMENT_TARGET build-settings)))
        (cond (macos-target
               (format "x86_64-apple-macosx%s" macos-target))
              (iphoneos-target
               ;; We never want "arm*" for flycheck.
               (format "x86_64-apple-ios%s" iphoneos-target))))))

(defun flycheck-swiftx--swift-version (build-settings)
  "Return the swift version for BUILD-SETTINGS."
  (when-let (swift-version (alist-get 'SWIFT_VERSION build-settings))
    ;; -swift-version appears to require integers (4 not 4.0 etc).
    ;; Major versions, such as 4.2, are however valid.
    (if (equal (fround swift-version) swift-version)
        (number-to-string (truncate swift-version))
      (number-to-string swift-version))))

(defun flycheck-swiftx--target-build-dir (target-name xcproj-path)
  "Return the target build dir for TARGET-NAME and XCPROJ-PATH.
Uses heuristics to locate the build dir in ~/Library/Developer/Xcode/DerivedData/."
  (let* ((build-root (expand-file-name "~/Library/Developer/Xcode/DerivedData/"))
         (results (directory-files-and-attributes build-root t (concat target-name "\\-[a-z]+"))))
    (unless results
      ;; Check for a xcworkspace in current/parent directory:
      (when-let (xcworkspace (flycheck-swiftx--find-xcworkspace (file-name-directory xcproj-path)))
        (setq target-name (file-name-base xcworkspace))
        (setq results (directory-files-and-attributes build-root (concat target-name "\\-[a-z]+")))))
    (car (seq-reduce (lambda (result item)
                       (if (time-less-p (nth 6 result) (nth 6 item))
                           item
                         result))
                     results (car results)))))

(defun flycheck-swiftx--xcrun-sdk-path (path-type &optional xcrun-sdk)
  "Return a path from `xcrun --sdk ${XCRUN-SDK} ${PATH-TYPE}'."
  (when-let ((xcrun-path (executable-find "xcrun"))
             (xcrun-cmd (if (eq path-type 'platform)
                            "--show-sdk-platform-path"
                          "--show-sdk-path")))
      (string-trim (shell-command-to-string
                    (format "%s %s %s" xcrun-path xcrun-cmd
                            (if xcrun-sdk (format "--sdk %s" xcrun-sdk) ""))))))

(defun flycheck-swiftx--sdk-root (&optional build-settings)
"Return the sdk root for BUILD-SETTINGS.
Falling back to flycheck-swiftx-sdk if BUILD-SETTINGS is nil."
(let ((sdk-root (or (alist-get 'SDKROOT build-settings)
                    flycheck-swiftx-sdk)))
  (if (equal sdk-root "iphoneos")
      "iphonesimulator"
    sdk-root)))

(defun flycheck-swiftx--sdk-path (&optional build-settings)
  "Return the sdk path for BUILD-SETTINGS.
If no valid sdk is found, return the default sdk path."
  (flycheck-swiftx--xcrun-sdk-path 'sdk
                                   (flycheck-swiftx--sdk-root build-settings)))

(defun flycheck-swiftx--sdk-platform-path (&optional build-settings)
  "Return the sdk platform path for BUILD-SETTINGS.
If no valid sdk is found, return the default sdk platform path."
  (flycheck-swiftx--xcrun-sdk-path 'platform
                                   (flycheck-swiftx--sdk-root build-settings)))

(defun flycheck-swiftx--list-swift-files (directory)
  "Return list of full paths to swift files in the specified DIRECTORY."
  (seq-filter
   (lambda (elt) (eq 0 (string-match-p "[^\\.].*" (file-name-nondirectory elt))))
   (directory-files-recursively directory ".*\\.swift$")))

(defun flycheck-swiftx--project-root (file-name)
  "Return the project root directory for FILE-NAME.

Searches for a Xcode project or Package.swift in FILE-NAME's
directory or parent directories.
Otherwise return FILE-NAME's directory."
  (if-let ((xcproj-path (when (or (eq flycheck-swiftx-project-type 'automatic)
                                  (eq flycheck-swiftx-project-type 'xcode))
                          (xcode-project-find-xcodeproj file-name))))
      (file-name-directory (directory-file-name xcproj-path))
    (if-let ((package-dir (locate-dominating-file file-name "Package.swift")))
        (expand-file-name package-dir)
      (file-name-directory file-name))))

(defun flycheck-swiftx--find-xcworkspace (directory-or-file)
  "Search DIRECTORY-OR-FILE and parent directories for an Xcode workspace file.
Returns the path to the Xcode workspace, or nil if not found."
  (when directory-or-file
    (let (xcworkspace
          (directory (if (file-directory-p directory-or-file)
                         directory-or-file
                       (file-name-directory directory-or-file))))
      (setq directory (expand-file-name directory))
      (while (and (not xcworkspace) (not (equal directory "/")))
        (setq xcworkspace (directory-files directory t ".*\\.xcworkspace$" nil))
        (setq directory (file-name-directory (directory-file-name directory))))
      (car xcworkspace))))

(defun flycheck-swiftx--source-files (&optional xcproj target-name)
  "Return the swift source files associated with the current buffer.

If XCPROJ and TARGET-NAME are non-nil then returns the source files
for the specified Xcode target.

Otherwise returns all .swift file specified by `flycheck-swiftx-sources'."
  (cond (xcproj
         (xcode-project-build-file-paths xcproj
                                         target-name
                                         "PBXSourcesBuildPhase"
                                         (lambda (file)
                                           (xcode-project-file-ref-extension-p file "swift"))
                                         'absolute))
         ((and (stringp flycheck-swiftx-sources)
               (file-directory-p flycheck-swiftx-sources))
          (flycheck-swiftx--list-swift-files flycheck-swiftx-sources))
         (flycheck-swiftx-sources
          (let ((inputs flycheck-swiftx-sources)
                (directory-name (file-name-directory
                                 (or load-file-name buffer-file-name))))
            (unless (listp inputs)
              (setq inputs (list inputs)))
            (flycheck-swiftx--expand-inputs inputs directory-name)))))

(defun flycheck-swiftx--expand-inputs (inputs &optional directory)
  "Return the expanded inputs.

If input files `INPUTS' is not nil, return the list of expanded
input files using `DIRECTORY' as the default directory."
  (let (expanded-inputs)
    (dolist (input inputs expanded-inputs)
      (if (file-name-absolute-p input)
          (setq expanded-inputs
                (append expanded-inputs (file-expand-wildcards input t)))
        (setq expanded-inputs
              (append expanded-inputs
                      (file-expand-wildcards
                       (expand-file-name input directory) t)))))))

(defun flycheck-swiftx--objc-bridging-header (build-settings xcproj-path)
  "Return path to Objc bridging header if found in BUILD-SETTINGS.

Header path is interpreted relative to XCPROJ-PATH."
  (when-let (header (flycheck-swiftx--string-option 'SWIFT_OBJC_BRIDGING_HEADER build-settings))
    (expand-file-name header (file-name-directory xcproj-path))))

(defun flycheck-swiftx--objc-inference (build-settings)
  "Return objc inference compiler flags for BUILD-SETTINGS."
  (when-let (objc-inference (alist-get 'SWIFT_SWIFT3_OBJC_INFERENCE build-settings))
    (cond ((equal objc-inference "On")
           '("-enable-swift3-objc-inference"
             "-warn-swift3-objc-inference-minimal"))
          ((equal objc-inference "Off")
           '("-disable-swift3-objc-inference")))))

(defun flycheck-swiftx--gcc-compilation-flags (build-settings)
  "Return a list of GCC conditional compilation flags found in BUILD-SETTINGS."
  (when-let (preprocessor-defs (alist-get 'GCC_PREPROCESSOR_DEFINITIONS build-settings))
    (when (stringp preprocessor-defs)
      (setq preprocessor-defs (vector preprocessor-defs)))
    (seq-concatenate 'vector
                     preprocessor-defs
                     (alist-get 'GCC_PREPROCESSOR_DEFINITIONS_NOT_USED_IN_PRECOMPS build-settings))))

(defun flycheck-swiftx--options-testing (build-settings)
  "Return swiftc options suitable for a test target using BUILD-SETTINGS."
  (if-let ((platform-path (flycheck-swiftx--sdk-platform-path build-settings)))
      (list "-enable-testing" "-F" (concat (file-name-as-directory platform-path) "Developer/Library/Frameworks"))
    '("-enable-testing")))

(defun flycheck-swiftx--string-option (key build-settings)
  "Return the string value for KEY in BUILD-SETTINGS."
  (when-let* ((value (alist-get key build-settings))
              (stringp value))
    value))

(defun flycheck-swiftx--list-option (key build-settings)
  "Return a list of options for KEY in BUILD-SETTINGS."
  (when-let (values (alist-get key build-settings))
    (if (stringp values)
        (seq-into (split-string values) 'vector)
      values)))

(defun flycheck-swiftx--path-option (key build-settings build-env)
  "Return list of options for KEY in BUILD-SETTINGS expanding with BUILD-ENV."
  (when-let ((values (flycheck-swiftx--list-option key build-settings)))
    (seq-map (lambda (value)
               (seq-reduce (lambda (result env)
                             (replace-regexp-in-string (format "$(?%s)?" (car env)) (cdr env) result t t))
                           build-env
                           value))
             values)))

(defun flycheck-swiftx--append-options (prefix options)
  "Append OPTIONS to PREFIX.
If options is a list or vector, maps each option to prefix.
Return nil if options is nil."
  (cond ((stringp options)
         (list prefix options))
        ((listp options)
         (mapcan (lambda(opt) (list prefix opt)) options))
        ((vectorp options)
         (mapcan (lambda(opt) (list prefix opt)) (append options nil)))))

(defun flycheck-swiftx--swiftc-options ()
  "Return a list of swift command line options.

When `flycheck-swiftx-project-type' is `automatic' or `xcode' then use the
associated Xcode project's build settings to determine command line options.

Otherwise fall back to the flycheck-swiftx custom options."
  (let* ((file-name (or load-file-name buffer-file-name))
         (xcproj-path (when (or (eq flycheck-swiftx-project-type 'automatic)
                                (eq flycheck-swiftx-project-type 'xcode))
                        (flycheck-swiftx--find-xcodeproj file-name))))
    (if (and xcproj-path (file-directory-p xcproj-path))
        (flycheck-swiftx--xcode-options xcproj-path file-name)
      (unless (eq flycheck-swiftx-project-type 'xcode)
        (let ((build-options flycheck-swiftx-build-options))
          ;; ensure -sdk is present in build-options
          (unless (seq-contains build-options "-sdk")
            (setq build-options (append build-options `("-sdk" ,(flycheck-swiftx--sdk-path)))))
          `(,@build-options
            ;; Associated source files, ignoring the file currently being checked.
            ,@(when-let (source-files (flycheck-swiftx--source-files))
                (remove file-name source-files))))))))

(defun flycheck-swiftx--xcode-options (xcproj-path file-name)
  "Return a list of swiftc options obtained from the XCPROJ-PATH.

FILE-NAME should be part of the project and is used to determine
the current target.  Only the first target found is used."
  (when-let* ((xcproj (flycheck-swiftx--load-xcode-project xcproj-path))
              (target-name (flycheck-swiftx--target-name file-name xcproj)))
    ;; build-settings are optional (though should usually be present).
    (let ((build-env (cons '("PROJECT_DIR" . (directory-file-name (file-name-directory xcproj-path))) flycheck-swiftx-build-env))
          (build-settings (flycheck-swiftx--xcode-build-settings xcproj target-name))
          (build-products-dir (xcode-project-concat-path (flycheck-swiftx--target-build-dir target-name xcproj-path)
                                                         "Build/Products"
                                                         (or flycheck-swiftx-xcode-build-config "Debug")))
          (enable-testing (flycheck-swiftx--maybe-test file-name)))
      `(
        ,@(flycheck-swiftx--append-options "-module-name" target-name)
        ,@(flycheck-swiftx--append-options "-target"
                                           (flycheck-swiftx--deployment-target build-settings))
        ,@(flycheck-swiftx--append-options "-swift-version"
                                           (flycheck-swiftx--swift-version build-settings))
        ,@(flycheck-swiftx--append-options "-sdk"
                                           (flycheck-swiftx--sdk-path build-settings))
        ,@(flycheck-swiftx--append-options "-import-objc-header"
                                           (flycheck-swiftx--objc-bridging-header build-settings xcproj-path))
        ,@(flycheck-swiftx--objc-inference build-settings)
        ,@(flycheck-swiftx--append-options "-D"
                                           (flycheck-swiftx--gcc-compilation-flags build-settings))
        ;; Other compiler flags
        ,@(flycheck-swiftx--list-option 'OTHER_SWIFT_FLAGS build-settings)
        ;; Tests
        ,@(when enable-testing (flycheck-swiftx--options-testing build-settings))
        ;; Search paths
        ;; Note: SDK search path should come before other framework search paths.
        ,@(flycheck-swiftx--append-options "-F"
                                           (seq-map (lambda (path) (concat (file-name-as-directory path) "Library/Frameworks"))
                                                    (flycheck-swiftx--path-option 'ADDITIONAL_SDKS
                                                                                  build-settings
                                                                                  build-env)))
        ,@(flycheck-swiftx--append-options "-F"
                                           (flycheck-swiftx--path-option 'FRAMEWORK_SEARCH_PATHS
                                                                                build-settings
                                                                                build-env))
        ,@(flycheck-swiftx--append-options "-I"
                                           (flycheck-swiftx--path-option 'HEADER_SEARCH_PATHS
                                                                                build-settings
                                                                                build-env))
        ,@(flycheck-swiftx--append-options "-I"
                                           (flycheck-swiftx--path-option 'USER_HEADER_SEARCH_PATHS
                                                                                build-settings
                                                                                build-env))
        ,@(flycheck-swiftx--append-options "-I"
                                           (flycheck-swiftx--path-option 'SYSTEM_HEADER_SEARCH_PATHS
                                                                                build-settings
                                                                                build-env))
        ,@(flycheck-swiftx--append-options "-I"
                                           (flycheck-swiftx--path-option 'SWIFT_INCLUDE_PATHS
                                                                                build-settings
                                                                                build-env))
        ;; Add target build dir to ensure that any framework dependencies are found
        ,@(flycheck-swiftx--append-options "-F" build-products-dir)
        ,@(flycheck-swiftx--append-options "-I" build-products-dir)
        ;; Optional, additional build options
        ,@flycheck-swiftx-build-options
        ;; Associated source files, ignoring the file currently being checked.
        ,@(when-let (source-files (flycheck-swiftx--source-files xcproj target-name))
            (remove file-name source-files))))))

(defun flycheck-swiftx--command ()
  "Return the command to run for Swift syntax checking.

Note: `flycheck-swiftx--command' is evaluated only once
when flycheck-swiftx is initialized."
  (if-let ((xcrun-path (executable-find "xcrun")))
      `(,xcrun-path
        (option "--toolchain" flycheck-swiftx-xcrun-toolchain)
        "swiftc")
    '("swiftc")))

(defun flycheck-swiftx--error-filter (errors)
  "Return filtered ERRORS.
swiftc v5.1.2 now returns errors for all inputs, even though we
specify a -primary-file.  We don't want to see errors for other
files in the current buffer, so we discard them here."
  (let* ((file-name (or load-file-name buffer-file-name)))
    (seq-filter
     (lambda (err)
       (or (equal "<unknown>" (flycheck-error-filename err))
           (equal file-name (flycheck-error-filename err))))
     errors)))

(flycheck-define-command-checker 'swiftx
  "A Swift syntax checker using Swift compiler frontend.

See URL `https://swift.org/'."
  :command `(,@(flycheck-swiftx--command)
             "-frontend"
             "-typecheck"
             (eval (flycheck-swiftx--swiftc-options))
             "-primary-file" source)
  :error-patterns '((error line-start "<unknown>:" line
                           ": " "error: " (optional (message)) line-end)
                    (info line-start (or "<stdin>" (file-name)) ":" line ":" column
                          ": " "note: " (optional (message)) line-end)
                    (warning line-start (or "<stdin>" (file-name)) ":" line ":" column
                             ": " "warning: " (optional (message)) line-end)
                    (error line-start (or "<stdin>" (file-name)) ":" line ":" column
                           ": " "error: " (optional (message)) line-end))
  :error-filter 'flycheck-swiftx--error-filter
  ;; Ensure paths (e.g flycheck-swiftx-sources) are interpreted relative to project's root directory.
  :working-directory (lambda (_) (flycheck-swiftx--project-root (or load-file-name buffer-file-name)))
  :modes 'swift-mode)

;; Set up Flycheck for Swift.
;;
;; Debug:
;;
;; In flycheck.el:flycheck-start-command-checker, add:
;; (when (equal checker 'swiftx) (message "%s %s" checker command))

(add-to-list 'flycheck-checkers 'swiftx)

(add-hook 'swift-mode-hook (lambda () (flycheck-mode)))

(provide 'flycheck-swiftx)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; flycheck-swiftx.el ends here
