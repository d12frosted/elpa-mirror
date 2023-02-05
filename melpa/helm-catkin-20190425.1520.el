;;; helm-catkin.el --- Package for compile ROS workspaces with catkin-tools  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Thore Goll

;; Author:  Thore Goll <thoregoll@googlemail.com>
;; Keywords: catkin, helm, build, tools, ROS
;; Package-Requires: ((emacs "24.3") (helm "0") (xterm-color "0"))
;; Homepage: https://github.com/gollth/helm-catkin
;; Version: 1.1

;; This file is not part of GNU Emacs.

;;; Commentary:

;; helm-catkin is a package providing an interface to catkin-tools `https://catkin-tools.readthedocs.io/en/latest/'.
;; It integrates with `helm' such that the config is shown in a helm dialog and can be customized
;; with actions.

;; Besides adjusting the config, you can build the ROS packages in the workspace in a colored build buffer.

;; All `helm-catkin' functions require a workspace defined. This is saved in a global Lisp
;; variable called `helm-catkin-workspace'. Easiest way is to specify a workspace is by calling
;; the interactive function `helm-catkin-set-workspace' which asks you to enter a path to your
;; workspace. This command can also be used to change between different workspaces.

;; Alternatively you can leave this variable at nil and use all `helm-catkin' functions on a
;; "per-buffer" basis. This means, the workspace is guessed for the buffer you are callling
;; the function from (only works if `helm-catkin-workspace' is nil though).

;; Quick overview of provided functionality:
;; `helm-catkin-set-workspace'  :: Sets the path to the helm-catkin workspace for all further helm-catkin commands
;; `helm-catkin'                :: Main command for showing, configuring and building in a helm window
;; `helm-catkin-build'          :: Build one, multiple or all packages in the current workspace
;; `helm-catkin-init'           :: Initializes the workspace and create a src/ folder if it doesn't exist
;; `helm-catkin-clean'          :: Clean the workspace (remove build/, devel/ and install/ folders)
;; `helm-catkin-config-show'    :: Shows the current config in a new buffer
;; `helm-catkin-config-open'    :: Opens the .catkin_tools/profiles/default/config.yaml file in a buffer

;;; Code:

(require 'helm)
(require 'xterm-color)

(define-derived-mode helm-catkin-mode special-mode "Catkin")

(defvar helm-catkin-workspace nil)
(defvar helm-catkin-build-success-hook)
(defvar helm-catkin-build-error-hook)
(defvar helm-catkin-build-done-hook)

(defun helm-catkin--get-workspace ()
  "Find the path of/in a catkin workspace. This is either `helm-catkin-workspace' if
this is set, or the `default-directory' of the current buffer. In both cases any
trailing slashes are removed."
  (let* ((ws (or helm-catkin-workspace default-directory))
         (root (expand-file-name (locate-dominating-file ws ".catkin_tools"))))
    (unless root (error (format "Cannot find catkin workspace at/above \"%s\"\
 (.catkin_tools folder not found)" ws)))
    ;; catkin locate crashes on trailing slashes, make sure to remove it accordingly
    (substring (file-name-as-directory root) 0 -1)))

(defun helm-catkin--parse-config (key)
  (let* ((ws (helm-catkin--get-workspace))
         (path (format "%s/.catkin_tools/profiles/default/config.yaml" ws)))
    (unless (helm-catkin--is-workspace-initialized ws)
      (error "Catkin workspace '%s' seems uninitialized. Use `(helm-catkin-init)' to do that now" ws))

    (with-temp-buffer
      (insert-file-contents path)
      (goto-char (point-min))
      (when (re-search-forward (format "^%s: *\\(\\(\n- .*$\\)+\\|\\(.*$\\)\\)" key) nil t)
        (let ((match (match-string 1)))
          (with-temp-buffer
            (insert match)
            (cond ((string= (buffer-string) "[]") '())
                  ((= 1 (count-lines (point-min) (point-max))) (buffer-string))
                  (t (split-string (replace-regexp-in-string "^- \\|^\\W*$" "" (buffer-string)) "\n")))))))))

(defun helm-catkin--util-format-list (list sep)
  "Combines the elements of LIST into a string joined by SEP."
  (mapconcat 'identity list sep))

(defun helm-catkin--util-command-to-list (command &optional separator)
  "Return each part of the stdout of COMMAND as elements of a list.
If SEPARATOR is nil, the newline character is used to split stdout."
  (let ((sep (or separator "\n")))
    (with-temp-buffer
      (call-process-shell-command command nil t)
      (ignore-errors (split-string (substring (buffer-string) 0 -1) sep t)))))

(defun helm-catkin--util-absolute-path-of (pkg)
  "Return the absolute path of PKG by calling \"catkin locate ...\".
If the package cannot be found this command raises an error."
  (helm-catkin--util-error-protected-command
              (format "catkin locate --quiet --workspace %s %s"
                      (shell-quote-argument (helm-catkin--get-workspace)) pkg)))

(defun helm-catkin--util-error-protected-command (cmd)
  (with-temp-buffer
    (when (file-exists-p "/tmp/.catkin-error") (delete-file "/tmp/.catkin-error"))
    (call-process-shell-command cmd
                                nil
                                '(t "/tmp/.catkin-error"))
    (with-temp-buffer
      (insert-file-contents "/tmp/.catkin-error")
      (unless (string= (buffer-string) "") (error (buffer-string))))
    (substring (buffer-string) 0 -1)))

(defun helm-catkin--is-workspace-initialized (path)
  "Return nil if the workspace at PATH has not yet been initialized, t otherwise."
  (= 0 (call-process "catkin" nil nil nil "profile" "--workspace" path "list")))

;;;###autoload
(defun helm-catkin-no-workspace ()
  "Clear the `helm-catkin-workspace' variable.
This can be used to fallback to \"per-buffer\" workspaces."
  (interactive)
  (setq helm-catkin-workspace nil))

;;;###autoload
(defun helm-catkin-set-workspace ()
  "Prompt to set the current catkin workspace to `helm-catkin-workspace'."
  (interactive)
  (let ((ws (read-directory-name "Set catkin workspace: " helm-catkin-workspace)))
    (unless (helm-catkin--is-workspace-initialized ws)
      (when (y-or-n-p (format "Workspace %s seems uninitialized. Initialize now? " ws))
        (helm-catkin-init ws)))
    (setq helm-catkin-workspace ws)
    (message (format "Catkin workspace set to %s" ws))))

;;;###autoload
(defun helm-catkin-init (&optional path)
  "(Re-)Initialize a catkin workspace at PATH.
If PATH is nil tries to initialize `helm-catkin-workspace'. If this is
also nil, the folder containing the current buffer will be used as workspace.
Creates the folder if it does not exist and also a child 'src' folder."
  (interactive)
  (let ((ws (or path (helm-catkin--get-workspace))))
    ;; If current workspace does not yet exist, prompt the user to create it
    (unless (file-exists-p ws)
      (unless (y-or-n-p (format "Path %s does not exist. Create? " ws))
        (error "Cannot initialize workspace `%s' since it doesn't exist" ws))
      (make-directory (format "%s/src" ws) t))  ; also create parent directiories)
    ;; Now that everything should be setup, call catkin config --init
    ;; to create the .catkin_tools/profile/default/config.yaml file
    (call-process-shell-command (format "catkin config --init --workspace %s"
                                        (shell-quote-argument ws)))
    (message (format "Catkin workspace initialized successfully at '%s'" ws))))

;;;###autoload
(defun helm-catkin-clean ()
  "Clean the build/ devel/ and install/ folder for the catkin workspace."
  (interactive)
  (let ((ws (helm-catkin--get-workspace)))
    (when (y-or-n-p (format "Clean workspace at '%s'? " ws))
      (call-process-shell-command (format "catkin clean --workspace %s -y"
                                          (shell-quote-argument ws))))))

(defun helm-catkin--source (command)
  "Prepend a `source $WS/devel/setup.bash &&' before COMMAND if such a file exists.
Otherwise leave COMMAND untouched."
  (let* ((ws (helm-catkin--get-workspace))
         (setup-file (format "%s/devel/setup.bash" (shell-quote-argument ws))))
    (if (file-exists-p setup-file)
        (format "source %s && %s" setup-file command)
      command)))

;;;###autoload
(defun helm-catkin-config-show ()
  "Print the current configuration of the catkin workspace.
The config goes to a new buffer called *Catkin Config*. This can be dismissed by pressing `q'."
  (interactive)
  (switch-to-buffer-other-window "*Catkin Config*")
  (erase-buffer)
  ;; Pipe stderr to null to supress "could not determine width" warning
  (call-process-shell-command (format "catkin --force-color config --workspace %s 2> /dev/null"
                                      (shell-quote-argument (helm-catkin--get-workspace))) nil t)
  (xterm-color-colorize-buffer)
  (helm-catkin-mode))        ; set this buffer to be dissmissable with "Q"

;;;###autoload
(defun helm-catkin-config-open ()
  "Open the config file for the default profile of the catkin workspace."
  (find-file (format "%s/.catkin_tools/profiles/default/config.yaml" (helm-catkin--get-workspace))))

;;;###autoload
(defun helm-catkin-config-set-devel-layout (&optional type)
  "Set the devel layout to either 'link', 'merge' or 'isolate'.
Prompt the user if TYPE is nil."
  (interactive)
  (if type (helm-catkin--config-set-devel-layout type)
    (helm :buffer "*helm Catkin Layout*"
          :sources (helm-build-sync-source "Devel Layout"
                     :candidates '("merge" "link" "isolate")
                     :action '(("Set layout" . helm-catkin--config-set-devel-layout))))))

(defun helm-catkin--config-set-devel-layout (type)
  "Set the layout of devel to TYPE to either 'link', 'merge' or 'isolate'."
  (unless (member type '("merge" "link" "isolate"))
    (error "Cannot set devel layout to. Only 'merge', 'link' or 'isolate' are supported." type))
  (call-process-shell-command
   (format "catkin config --workspace %s --%s-devel"
           (helm-catkin--get-workspace) type)))

(defun helm-catkin--config-args (operation &optional args)
  "Call 'catkin config' for the workspace to execute some OPERATION.
The ARGS are string joined with spaces and applied after the OPERATION.
This function can be used to set args of a certain type like so:

\(helm-catkin--config-args \"--cmake-args\"
                     '(\"-DCMAKE_ARG1=foo\" \"-DCMAKE_ARG2=bar\"))
\(helm-catkin--config-args \"--no-make-args\")"
  (unless (helm-catkin--is-workspace-initialized (helm-catkin--get-workspace))
    (error (format "Catkin workspace at %s not yet initialized. Have you called `helm-catkin-set-workspace'?" (helm-catkin--get-workspace))))
  (let ((arg-string (helm-catkin--util-format-list args " ")))
    (ignore-errors
      (substring
       (call-process-shell-command
        (format "catkin config --workspace %s %s %s"
                (shell-quote-argument (helm-catkin--get-workspace))
                operation
                arg-string))
       0 -1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  CMAKE Args                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar helm-catkin--cmake-cache nil)
(defun helm-catkin-config-cmake-args ()
  "Return a list of all currenty set cmake args for the workspace."
  (if helm-catkin--cmake-cache helm-catkin--cmake-cache
    (setq helm-catkin--cmake-cache
          (helm-catkin--parse-config "cmake_args"))))

(defun helm-catkin-config-cmake-args-clear ()
  "Remove all cmake args for the current workspace."
  (setq helm-catkin--cmake-cache nil)  ; invalidate
  (helm-catkin--config-args "--no-cmake-args"))

(defun helm-catkin-config-cmake-args-set (args)
  "Set a list of cmake ARGS for the current workspace.
Passing an empty list to ARGS will clear all currently set cmake arguments."
  (setq helm-catkin--cmake-cache nil)  ; invalidate
  (helm-catkin--config-args "--cmake-args" args))

(defun helm-catkin-config-cmake-args-add (args)
  "Add a list of cmake ARGS to the existing set of cmake arguments for the current workspace."
  (setq helm-catkin--cmake-cache nil)  ; invalidate
  (helm-catkin--config-args "--append-args --cmake-args" args))

(defun helm-catkin-config-cmake-args-remove (args)
  "Remove a list of cmake ARGS from the existing set of cmake arguments for the current workspace.
ARGS which are currently not set and are requested to be removed don't provoce an error and are just ignored."
  (setq helm-catkin--cmake-cache nil)  ; invalidate
  (helm-catkin--config-args "--remove-args --cmake-args" args))

(defun helm-catkin-config-cmake-change (arg)
  "Prompt the user to enter a new value for a CMake arg.
The prompt in the minibuffer is autofilled with ARG and the new entered value will be returned."
  (interactive)
  (let ((new-arg (helm-read-string "Adjust value for CMake Arg: " arg)))
    (helm-catkin-config-cmake-args-remove (list arg))
    (helm-catkin-config-cmake-args-add (list new-arg))))

(defun helm-catkin-config-cmake-new (&optional _)
  "Prompts the user to enter a new CMake arg which will be returned."
  (interactive)
  (setq helm-catkin--cmake-cache nil)  ; invalidate
  (helm-catkin-config-cmake-args-add (list (helm-read-string "New CMake Arg: "))))

(defvar helm-catkin--helm-source-catkin-config-cmake
  (helm-build-sync-source "CMake"
    :init 'helm-catkin-config-cmake-args
    :allow-dups nil
    :candidates 'helm-catkin--cmake-cache
    :help-message 'helm-catkin--helm-source-catkin-config-cmake-helm-message
    :action '(("Change" . (lambda (x) (helm-catkin-config-cmake-change x) (helm-catkin)))
              ("Remove" . (lambda (_) (helm-catkin-config-cmake-args-remove (helm-marked-candidates)) (helm-catkin))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   MAKE Args                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar helm-catkin--make-cache nil)
(defun helm-catkin-config-make-args ()
  "Return a list of all currenty set make args for the current workspace."
  (if helm-catkin--make-cache helm-catkin--make-cache
    (setq helm-catkin--make-cache
          (append (helm-catkin--parse-config "make_args")
                  (helm-catkin--parse-config "jobs_args")))))

(defun helm-catkin-config-make-args-clear ()
  "Remove all make args for the current workspace."
  (setq helm-catkin--make-cache nil)  ; invalidate
  (helm-catkin--config-args "--no-make-args"))

(defun helm-catkin-config-make-args-set (args)
  "Set a list of make ARGS for the current workspace.
Passing an empty list to ARGS will clear all currently set args."
  (setq helm-catkin--make-cache nil)  ; invalidate
  (helm-catkin--config-args "--make-args" args))

(defun helm-catkin-config-make-args-add (args)
  "Add a list of make ARGS to the existing set of make args for the current workspace."
  (setq helm-catkin--make-cache nil)  ; invalidate
  (helm-catkin--config-args "--append-args --make-args" args))

(defun helm-catkin-config-make-args-remove (args)
  "Remove a list of make ARGS from the existing set of make arguments for the current workspace.
ARGS which are currently not set and are requested to be removed don't provoce an error and
are just ignored."
  (setq helm-catkin--make-cache nil)  ; invalidate
  (helm-catkin--config-args "--remove-args --make-args" args))

(defun helm-catkin-config-make-change (arg)
  "Prompt the user to enter a new value for a Make arg.
The prompt in the minibuffer is autofilled with ARG and the new entered value will be returned."
  (interactive)
  (setq helm-catkin--make-cache nil)  ; invalidate
  (let ((new-arg (helm-read-string "Adjust value for Make Arg: " arg)))
    (helm-catkin-config-make-args-remove (list arg))
    (helm-catkin-config-make-args-add (list new-arg))))

(defun helm-catkin-config-make-new (&optional _)
  "Prompt the user to enter a new Make arg which will be returned."
  (interactive)
  (setq helm-catkin--make-cache nil)  ; invalidate
  (helm-catkin-config-make-args-add (list (helm-read-string "New Make Arg: "))))

(defvar helm-catkin--helm-source-catkin-config-make
  (helm-build-sync-source "Make"
    :init 'helm-catkin-config-make-args
    :candidates 'helm-catkin--make-cache
    :help-message 'helm-catkin--helm-source-catkin-config-make-helm-message
    :action '(("Change" . (lambda (x) (helm-catkin-config-make-change x) (helm-catkin)))
              ("Remove" . (lambda (_) (helm-catkin-config-make-args-remove (helm-marked-candidates)) (helm-catkin))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   CATKIN-MAKE Args                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar helm-catkin--catkin-make-cache nil)
(defun helm-catkin-config-catkin-make-args ()
  "Return a list of all currenty set catkin-make args for the current workspace."
  (if helm-catkin--catkin-make-cache helm-catkin--catkin-make-cache
    (setq helm-catkin--catkin-make-cache
          (helm-catkin--parse-config "catkin_make_args"))))

(defun helm-catkin-config-catkin-make-args-clear ()
  "Remove all catkin-make ARGS for the current workspace."
  (setq helm-catkin--catkin-make-cache nil)  ; invalidate
  (helm-catkin--config-args "--no-catkin-make-args"))

(defun helm-catkin-config-catkin-make-args-set (args)
  "Set a list of catkin-make ARGS for the current workspace.
Passing an empty list to ARGS will clear all currently set arguments."
  (setq helm-catkin--catkin-make-cache nil)  ; invalidate
  (helm-catkin--config-args "--catkin-make-args" args))

(defun helm-catkin-config-catkin-make-args-add (args)
  "Add a list of catkin-make ARGS to the existing set of catkin-make ARGS for the current workspace."
  (setq helm-catkin--catkin-make-cache nil)  ; invalidate
  (helm-catkin--config-args "--append-args --catkin-make-args" args))

(defun helm-catkin-config-catkin-make-args-remove (args)
  "Remove a list of catkin-make ARGS from the existing set of catkin make arguments for the current workspace.
ARGS which are currently not set and are requested to be removed don't provoce an error and are just ignored."
  (setq helm-catkin--catkin-make-cache nil)  ; invalidate
  (helm-catkin--config-args "--remove-args --catkin-make-args" args))

(defun helm-catkin-config-catkin-make-change (arg)
  "Prompt the user to enter a new value for a catkin make argument.
The prompt in the minibuffer is autofilled with ARG and the new entered value will be returned."
  (interactive)
  (setq helm-catkin--catkin-make-cache nil)  ; invalidate
  (let ((new-arg (helm-read-string "Adjust value for Catkin-Make Arg: " arg)))
    (helm-catkin-config-catkin-make-args-remove (list arg))
    (helm-catkin-config-catkin-make-args-add (list new-arg))))

(defun helm-catkin-config-catkin-make-new (&optional _)
  "Prompt the user to enter a new Catkin-Make arg which will be returned."
  (interactive)
  (setq helm-catkin--catkin-make-cache nil)  ; invalidate
  (helm-catkin-config-catkin-make-args-add (list (helm-read-string "New Catkin-Make Arg: "))))

(defvar helm-catkin--helm-source-catkin-config-catkin-make
  (helm-build-sync-source "Catkin-Make"
    :init 'helm-catkin-config-catkin-make-args
    :candidates 'helm-catkin--catkin-make-cache
    :help-message 'helm-catkin--helm-source-catkin-config-catkin-make-helm-message
    :action '(("Change" . (lambda (x) (helm-catkin-config-catkin-make-change x) (helm-catkin)))
              ("Remove" . (lambda (_) (helm-catkin-config-catkin-make-args-remove (helm-marked-candidates)) (helm-catkin))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Whitelist/Blacklist                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar helm-catkin--whitelist-cache nil)
(defun helm-catkin-config-whitelist ()
  "Return a list of all currenty whitelisted packages for the current workspace."
  (if helm-catkin--whitelist-cache helm-catkin--whitelist-cache
    (setq helm-catkin--whitelist-cache
          (helm-catkin--parse-config "whitelist"))))

(defun helm-catkin-config-whitelist-add (packages)
  "Mark a list of PACKAGES to be whitelisted for the current workspace."
  (helm-catkin--config-args "--append-args --whitelist" packages))

(defun helm-catkin-config-whitelist-remove (packages)
  "Remove a list of whitelisted PACKAGES from the existing whitelist for the current workspace.
Packages which are currently not whitelisted and are requested to be removed don't provoce
an error and are just ignored."
  (helm-catkin--config-args "--remove-args --whitelist" packages))

(defvar helm-catkin--helm-source-catkin-config-whitelist
  (helm-build-sync-source "Whitelist"
    :init 'helm-catkin-config-whitelist
    :candidates 'helm-catkin--whitelist-cache
    :help-message 'helm-catkin--helm-source-catkin-config-whitelist-helm-message
    :action '(("Un-Whitelist" . (lambda (_) (helm-catkin-config-whitelist-remove (helm-marked-candidates)) (helm-catkin)))
              ("Build" . (lambda (_) (helm-catkin-build-package (helm-marked-candidates))))
              ("Open Folder" . helm-catkin-open-pkg-dired)
              ("Open CMakeLists.txt" . (lambda (c) (helm-catkin-open-pkg-cmakelist (helm-marked-candidates))))
              ("Open package.xml" . (lambda (c) (helm-catkin-open-pkg-package (helm-marked-candidates)))))))

(defvar helm-catkin--blacklist-cache nil)
(defun helm-catkin-config-blacklist ()
  "Return a list of all currenty blacklisted packages for the workspace."
  (if helm-catkin--blacklist-cache helm-catkin--blacklist-cache
    (setq helm-catkin--blacklist-cache
          (helm-catkin--parse-config "blacklist"))))

(defun helm-catkin-config-blacklist-add (packages)
  "Mark a list of PACKAGES to be blacklisted for the current workspace."
  (helm-catkin--config-args "--append-args --blacklist" packages))

(defun helm-catkin-config-blacklist-remove (packages)
  "Remove a list of blacklisted PACKAGES from the existing blacklist for the current workspace.
Packages which are currently not blacklisted and are requested to be removed don't provoce an
error and are just ignored."
  (helm-catkin--config-args "--remove-args --blacklist" packages))

(defvar helm-catkin--helm-source-catkin-config-blacklist
  (helm-build-sync-source "Blacklist"
    :candidates 'helm-catkin-config-blacklist
    :help-message 'helm-catkin--helm-source-catkin-config-blacklist-help-message
    :action '(("Un-Blacklist" . (lambda (_) (helm-catkin-config-blacklist-remove (helm-marked-candidates)) (helm-catkin)))
              ("Build" . (lambda (_) (helm-catkin-build-package (helm-marked-candidates))))
              ("Open Folder" . helm-catkin-open-pkg-dired)
              ("Open CMakeLists.txt" . (lambda (c) (helm-catkin-open-pkg-cmakelist (helm-marked-candidates))))
              ("Open package.xml" . (lambda (c) (helm-catkin-open-pkg-package (helm-marked-candidates)))))))

(defvar helm-catkin--helm-source-catkin-config-new
  (helm-build-sync-source "[New]"
    :candidates '("CMake Arg" "Make Arg" "Catkin Make Arg")
    :help-message 'helm-catkin--helm-source-catkin-config-new-helm-message
    :action '(("Create New Arg" . (lambda (name)
                                    (cond ((string= name "CMake Arg")       (helm-catkin-config-cmake-new ""))
                                          ((string= name "Make Arg")        (helm-catkin-config-make-new ""))
                                          ((string= name "Catkin Make Arg") (helm-catkin-config-catkin-make-new ""))
                                          )
                                    (helm-catkin))))))

(defvar helm-catkin--helm-source-catkin-config-packages
  (helm-build-sync-source "Packages"
    :candidates 'helm-catkin-list
    :help-message 'helm-catkin--helm-source-catkin-config-packages-helm-message
    :action '(("Build" . (lambda (c) (helm-catkin-build-package (helm-marked-candidates))))
              ("Open Folder" . helm-catkin-open-pkg-dired)
              ("Open CMakeLists.txt" . (lambda (c) (helm-catkin-open-pkg-cmakelist (helm-marked-candidates))))
              ("Open package.xml" . (lambda (c) (helm-catkin-open-pkg-package (helm-marked-candidates))))
              ("Blacklist" . (lambda (_) (helm-catkin-config-blacklist-add (helm-marked-candidates)) (helm-catkin)))
              ("Whitelist" . (lambda (_) (helm-catkin-config-whitelist-add (helm-marked-candidates)) (helm-catkin))))))

(defvar helm-catkin-helm-help-string
  "* Catkin

Opens a helm query which shows the current config for the catkin workspace.
It combines the different arguments into helm sections:

** Config Sections
When you fire up the `helm-catkin' command, you see a different sections listed below. If in one section
no argument is set, the section is omitted. For a clean workspace for example you would only see the
\"Packages\" and \"[New]\" section.

 - [New]           Add a new argument to the config
 - CMake:          The arguments passed to `cmake'
 - Make:           The arguments passed to `make'
 - Catkin Make:    The arguments passed to `catkin_make'
 - Whitelist:      Which packages are whitelisted, i.e. are build exclusively
 - Blacklisted:    Which packages are blacklisted, i.e. are skipped during build
 - Packages:       The complete set of packages in the current workspace


** Actions
Each section has a distinct set of actions for each item. Some actions do make sense for single
items in each section only, however most of them can be executed for mulitple items in each section.
The first action [F1] is always the default choice if you just press enter.

*** [New]    (any of these actions will re-show the helm-catkin dialog)
***** [F1] CMake Arg           :: add a new cmake argument to the config
***** [F2] Make Arg            :: add a new make argument to the config
***** [F3] Catkin Make Arg     :: add a new catkin_make argument to the config
*** CMake
***** [F1] Change              :: change the value of that cmake argument
***** [F3] Remove              :: remove that/those selected cmake argument(s)
*** Make
***** [F1] Change              :: change the value of that make argument
***** [F3] Remove              :: remove that/those selected make argument(s)
*** Catkin Make
***** [F1] Change              :: change the value of that catkin_make argument
***** [F3] Remove              :: remove that/those selected catkin_make argument(s)
*** Blacklist
***** [F1] Un-Blacklist        :: remove the selected package(s) from the blacklist
***** [F2] Build               :: build the selected package(s)
***** [F3] Open Folder         :: open the package's folder in a `dired' buffer (no multi selection)
***** [F4] Open CMakeLists.txt :: open CMakeLists files of the selected package(s)
***** [F5] Open package.xml    :: open package files of the selected package(s)
*** Whitelist
***** [F1] Un-Whitelist        :: remove the selected package(s) from the whitelist
***** [F2] Build               :: build the selected package(s)
***** [F3] Open Folder         :: open the package's folder in a `dired' buffer (no multi selection)
***** [F4] Open CMakeLists.txt :: open CMakeLists files of the selected package(s)
***** [F5] Open package.xml    :: open package files of the selected package(s)
*** Packages
***** [F1] Build               :: build the selected package(s)
***** [F2] Open Folder         :: open the package's folder in a `dired' buffer (no multi selection)
***** [F3] Open CMakeLists.txt :: open CMakeLists files of the selected package(s)
***** [F4] Open package.xml    :: open package files of the selected package(s)
***** [F5] Blacklist           :: put the selected package(s) on the blacklist
***** [F6] Whitelist           :: put the selected package(s) on the whitelist

** Tips
**** Most of the actions above accept multiple items from that section.
**** You can list all available actions with \\[helm-select-action]
**** You can mark multiple items in one section with \\[helm-toggle-visibility-mark]
**** You can mark all items in one section with \\[helm-toggle-all-marks]
**** You can build the entire workspace if you move down with \\[helm-next-source] to the \"Packages\" section,
     press \\[helm-toggle-all-marks] to select all and hit `RET'.

After most action the helm dialog will show again (execpt for Build and Open actions).
To quit it just press ESC.")

(defun helm-catkin--invalidate-caches ()
  "Remove all cached helm sources"
  (setq helm-catkin--packages-cache nil)
  (setq helm-catkin--whitelist-cache nil)
  (setq helm-catkin--blacklist-cache nil)
  (setq helm-catkin--cmake-cache nil)
  (setq helm-catkin--make-cache nil)
  (setq helm-catkin--catkin-make-cache nil))

;;;###autoload
(defun helm-catkin ()
  "Helm command for catkin.
For more information use `C-h v helm-catkin-helm-help-message' or
press `C-c ?' in the helm-catkin helm query.

See `helm-catkin-helm-help-string'"
  (interactive)
  (helm-catkin--invalidate-caches)
  (message "Parsing Catkin Config...")
  (helm :buffer "*helm Catkin*"
        :sources '(helm-catkin--helm-source-catkin-config-new
                   helm-catkin--helm-source-catkin-config-cmake
                   helm-catkin--helm-source-catkin-config-make
                   helm-catkin--helm-source-catkin-config-catkin-make
                   helm-catkin--helm-source-catkin-config-whitelist
                   helm-catkin--helm-source-catkin-config-blacklist
                   helm-catkin--helm-source-catkin-config-packages)))

(defun helm-catkin--build-finished (process signal)
  "This get called, once the catkin build command finishes.
It marks the buffer as read-only and closes the window on `q'.
PROCESS is the process which runs the build command and SIGNAL
the signal with which the PROCESS finishes."
  (when (memq (process-status process) '(exit signal))
    (setq window (get-buffer-window "*Catkin Build*"))
    (shell-command-sentinel process signal)
    (message "Catkin build done!")
    (select-window window)      ; select the the build window
    (read-only-mode)            ; mark it as not-editable
    (local-set-key (kbd "q") (lambda () (interactive) (quit-window window)))

    ;; Run hooks according to build result
    (run-hooks 'helm-catkin-build-done-hook)
    (if (string-prefix-p "finished" signal)
        (run-hooks 'helm-catkin-build-success-hook)
      (run-hooks 'helm-catkin-build-error-hook))))

(defun helm-catkin-build-package (&optional pkgs)
  "Build the catkin workspace after sourcing it's ws.
If PKGS is non-nil, only these packages are built, otherwise all packages in the ws are build."
  (let* ((packages (helm-catkin--util-format-list pkgs " "))
         (build-command (format "catkin build --workspace %s %s"
                                (shell-quote-argument (helm-catkin--get-workspace))
                                packages))
         (buffer (get-buffer-create "*Catkin Build*"))
         (process (progn
                    (with-current-buffer "*Catkin Build*" (helm-catkin-mode))
                    (async-shell-command build-command buffer)
                    (get-buffer-process buffer))))
    (if (process-live-p process)
        (set-process-sentinel process #'helm-catkin--build-finished)
      (error "Could not attach process sentinel to \"catkin build\" since no such process is running"))))


(defvar helm-catkin--packages-cache nil)
(defun helm-catkin-list ()
  "Return a list of all packages in the current workspace."
  (if helm-catkin--packages-cache helm-catkin--packages-cache
    (setq helm-catkin--packages-cache
          (helm-catkin--util-command-to-list
           (format "catkin list --workspace %s --unformatted --quiet"
                   (shell-quote-argument (helm-catkin--get-workspace)))))))

(defun helm-catkin-open-file-in (pkg file)
  "Open the file at `$(rospack find pkg)/file'.
PKG is the name of the ros package and FILE a relative path to it."
  (interactive)
  (find-file (format "%s/%s" (helm-catkin--util-absolute-path-of pkg) file)))

(defun helm-catkin-open-pkg-cmakelist (pkgs)
  "Open the `CMakeLists.txt' file for each of the package names within PKGS."
  (dolist (pkg pkgs) (helm-catkin-open-file-in pkg "CMakeLists.txt")))

(defun helm-catkin-open-pkg-package (pkgs)
  "Open the `package.xml' file for each of the package names within PKGS."
  (dolist (pkg pkgs) (helm-catkin-open-file-in pkg "package.xml")))

(defun helm-catkin-open-pkg-dired (pkg)
  "Open the absolute path of PKG in `dired'."
  (interactive)
  (dired (helm-catkin--util-absolute-path-of pkg)))

(defvar helm-catkin--helm-catkin-build-help-message
  "* Catkin build Help
Prompts the user via a helm dialog to select one or more
packages to build in the current workspace.

The first section specifies to build the default configuration
setup by the `helm-catkin' command. For example if you have black- or
whitelisted packages, building with \"[default]\" will take this
into account. Otherwise you can explicately select packages in
the second section, which should be build regardless of black-
and whitelist.

** Tips
**** To adjust the config from the build command use the [F2] on \"[default]\"
**** Most of the actions above accept multiple items from that section.
**** You can list all available actions with \\[helm-select-action]
**** You can mark multiple items in one section with \\[helm-toggle-visibility-mark]
**** You can mark all items in the \"Packages\" section with \\[helm-toggle-all-marks]

** Actions:
**** [F1] Build:                Build the selected package(s)
**** [F2] Open Folder:          Open the package's folder in `dired' (no multiselection possible)
**** [F3] Open CMakeLists.txt   Open the `CMakeList.txt' file(s) in new buffer(s) for the selected package(s)
**** [F4] Open package.xml      Open the `package.xml' file(s) in new buffer(s) for the selected package(s)")

(defvar helm-catkin--helm-source-catkin-build-default-source
   (helm-build-sync-source "Config"
     :candidates '("[default]")
     :help-message 'helm-catkin--helm-catkin-build-help-message
     :action '(("Build" . (lambda (_) (helm-catkin-build-package)))
               ("Open Config" . (lambda (_) (helm-catkin))))))

(defvar helm-catkin--helm-source-catkin-build-source
  (helm-build-sync-source "Packages"
    :candidates 'helm-catkin-list
    :help-message 'helm-catkin--helm-catkin-build-help-message
    :action '(("Build"               . (lambda (c) (helm-catkin-build-package (helm-marked-candidates))))
              ("Open Folder"         . helm-catkin-open-pkg-dired)
              ("Open CMakeLists.txt" . (lambda (c) (helm-catkin-open-pkg-cmakelist (helm-marked-candidates))))
              ("Open package.xml"    . (lambda (c) (helm-catkin-open-pkg-package (helm-marked-candidates)))))))

;;;###autoload
(defun helm-catkin-build ()
  "Prompt the user via a helm dialog to select one or more packages to build.

  See `helm-catkin-helm-help-string'"
  (interactive)
  (helm-catkin--invalidate-caches)
  (helm :buffer "*helm Catkin Build*"
        :sources '(helm-catkin--helm-source-catkin-build-default-source
                   helm-catkin--helm-source-catkin-build-source)))

(provide 'helm-catkin)

;;; helm-catkin.el ends here
