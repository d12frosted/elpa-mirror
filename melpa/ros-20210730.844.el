;;; ros.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Max Beutelspacher
;;
;; Author: Max Beutelspacher <https://github.com/mtb>
;; Maintainer: Max Beutelspacher <max@beutelspacher.eu>
;; Created: February 14, 2021
;; Modified: February 14, 2021
;; Version: 1.0.0
;; Package-Version: 20210730.844
;; Package-Commit: 63d46cefa8552b59556dcb4af0849253dc501ee9
;; Keywords: Symbol’s value as variable is void: finder-known-keywords
;; Homepage: https://github.com/DerBeutlin/ros.el
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 's)
(require 'with-shell-interpreter)
(require 'docker-tramp)
(require 'kv)
(require 'cl-lib)
(require 'transient)
(require 'hydra)
(require 'grep)
(require 'string-inflection)
(require 'avy)

(defvar ros-tramp-prefix "")

(defvar ros-current-workspace nil)

(defvar ros-version-name "")

(defvar ros-workspaces nil)

(defun ros-current-tramp-prefix ()
  (cdr (assoc "tramp-prefix" ros-current-workspace)))

(defun ros-current-workspace ()
  (cdr (assoc "workspace" ros-current-workspace)))

(defun ros-current-extensions ()
  (cdr (assoc "extends" ros-current-workspace)))

(defun ros-current-source-command ()
  (ros-source-command ros-current-workspace))

(defvar ros-cache nil)

(defun ros-cache-key ()
  (format "%s_%s_%s" (ros-current-tramp-prefix) (ros-current-workspace) (string-join (ros-current-extensions) "_")))

(defun ros-cache-store (key value)
  (let ((cache (cdr (assoc (ros-cache-key) ros-cache))))
    (setf (alist-get key cache) value)
    (setf (alist-get (ros-cache-key) ros-cache) cache)))

(defun ros-cache-load (key &optional generate)
  (let ((cached-value (cdr (assoc key (cdr (assoc (ros-cache-key) ros-cache))))))
    (if cached-value cached-value (when generate (progn (ros-cache-store key (funcall generate)) (ros-cache-load key))))))

(defun ros-cache-clean ()
  (interactive)
  (setq ros-cache nil))

(defun ros-source-command (workspace)
  (let ((extends (cdr (assoc "extends" workspace)))
        (ws-setup-bash (concat (file-name-as-directory (cdr (assoc "workspace" workspace))) "install/setup.bash")))
    (concat (string-join (mapcar (lambda (extension) (concat "source " (file-name-as-directory extension) "setup.bash")) extends) " && ") (format " && test -f %s && source %s || true" ws-setup-bash ws-setup-bash)))
  )

(cl-defun ros-dump-workspace (&key tramp-prefix workspace extends)
  (list (cons "tramp-prefix"  tramp-prefix)
        (cons "workspace" workspace)
        (cons "extends" extends)))

(defun ros-workspace-to-string (workspace)
  (let ((tramp-prefix (cdr (assoc "tramp-prefix" workspace))))
    (concat ( cdr (assoc "workspace" workspace)) " on " (if tramp-prefix tramp-prefix "localhost") " extending " (string-join (cdr (assoc "extends" workspace)) ", "))))

(defun ros-current-version ()
  (string-to-number (ros-shell-command-to-string "printenv ROS_VERSION")))

(defun ros-shell-command-to-string (cmd &optional use-default-directory)
  (let ((path (if use-default-directory default-directory (concat (ros-current-tramp-prefix) "~"))))
    (with-shell-interpreter :path path :form
      (s-trim(shell-command-to-string (format "/bin/bash  -c \"%s && %s\" | sed -r \"s/\x1B\\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g\"" (ros-current-source-command) cmd ))))))

(defun ros-shell-command-to-list (cmd)
  (split-string (ros-shell-command-to-string cmd) "\n" t  "[\s\f\t\n\r\v\\]+"))

(defun ros-list-packages ()
  (kvalist->keys (ros-list-package-locations)))

(defun ros-parse-colcon-list-line (line)
  (let ((components (split-string line)))
    (list (car components) (concat (file-name-as-directory  (ros-current-workspace)) (cl-second components)))))

(defun ros-list-package-locations ()
  (ros-cache-load "package-locations" (lambda nil (kvplist->alist (apply #'append (mapcar 'ros-parse-colcon-list-line (ros-shell-command-to-list (format "cd %s && colcon list" (ros-current-workspace)))))))))

(defun ros-package-files (package-name)
  (ros-cache-load (concat "package" "_" package-name)
                   (lambda nil
                     (let ((package-path (concat (ros-current-tramp-prefix)
                                                 (cdr (assoc package-name (ros-list-package-locations))) "/")))
                       (mapcar (lambda (str) (string-trim-left str package-path))
                               (directory-files-recursively package-path ".*"
                                                            nil
                                                            (lambda (subdir) (not (string-prefix-p "." (file-name-nondirectory subdir))))))) )))

(defun ros-set-workspace ()
  (interactive)
  (let ((descriptions (mapcar 'ros-workspace-to-string ros-workspaces)))
    (setq ros-current-workspace (nth (cl-position (completing-read "Workspace: " descriptions nil t nil nil (when ros-current-workspace (ros-workspace-to-string ros-current-workspace))) descriptions :test #'equal)  ros-workspaces))
    ))

(defun ros-completing-read-package ()
  (let ((packages (ros-list-packages))
        (current-package (ros-current-package)))
    (completing-read "Package: " packages nil t nil nil (when (member current-package packages) current-package))))

(defun ros-completing-read-package-path ()
  (let* ((locations (ros-list-package-locations))
         (package (completing-read "Package: " (kvalist->keys locations) nil t nil nil)))
    (cdr (assoc package locations))))

(defun ros-go-to-package (path)
  (interactive (list (ros-completing-read-package-path)))
  (find-file (concat (ros-current-tramp-prefix) path)))

(defun ros-find-file-in-current-package ()
  (interactive)
  (let ((current-package (ros-current-package)))
    (if current-package (ros-find-file-in-package current-package) (call-interactively 'ros-find-file-in-package))))

(defun ros-find-file-in-package (package)
  (interactive (list (ros-completing-read-package)))
  (let ((path (concat (ros-current-tramp-prefix) (cdr (assoc package (ros-list-package-locations))) "/"))
        (file (completing-read "File: " (ros-package-files package) nil t)))
    (find-file (concat path file))))

(defun ros-grep-in-package (package-path string)
  (interactive (list (ros-completing-read-package-path) (read-string "Regex: ")))
  (let ((grep-find-ignored-directories  (mapcar (lambda (name) (string-trim-right name "/")) (seq-filter (lambda (name) (and (directory-name-p name) (s-starts-with-p "." name))) (file-name-all-completions "" package-path)))))
    (unless grep-find-template (grep-compute-defaults))
    (rgrep string "*" package-path)))

(defun ros-grep-in-current-package (string)
  (interactive (list  (read-string "Regex: ")))
  (ros-grep-in-package (locate-dominating-file default-directory "package.xml") string))

(defun ros-list-messages ()
  (ros-cache-load "messages" (lambda nil (if (eq (ros-current-version) 1) (ros-list-messages-ros1) (ros-list-messages-ros2)))))

(defun ros-list-messages-ros1 ()
  (ros-shell-command-to-list "rosmsg list"))

(defun ros-list-messages-ros2 ()
  (cdr (ros-shell-command-to-list "ros2 interface list -m")))

(defun ros-completing-read-message ()
  (completing-read "Message: " (ros-list-messages) nil t))

(defun ros-completing-read-srv ()
  (completing-read "Srv:" (ros-list-srvs) nil t))

(defun ros-completing-read-action ()
  (completing-read "Action:" (ros-list-actions) nil t))

(defun ros-select-import-line ()
  (let ((avy-all-windows nil))
    (save-excursion
      (goto-char (point-min))
      (avy--line nil (point-min) (point-max)))))

(defun ros-insert-message (msg)
  (interactive (list (ros-completing-read-message)))
  (ros-insert-interface "msg" msg))

(defun ros-insert-message-import (msg line)
  (interactive (list (ros-completing-read-message) (ros-select-import-line)))
  (save-excursion
    (goto-char line)
    (ros-insert-interface "msg" msg t)
    (insert "\n")))

(defun ros-insert-srv (srv)
  (interactive (list (ros-completing-read-srv)))
  (ros-insert-interface "srv" srv))

(defun ros-insert-srv-import (srv line)
  (interactive (list  (ros-completing-read-srv) (ros-select-import-line)))
  (save-excursion
    (goto-char line)
    (ros-insert-interface "srv" srv t)
    (insert "\n")))

(defun ros-insert-action (action)
  (interactive (list (ros-completing-read-action)))
  (ros-insert-interface "action" action))

(defun ros-insert-action-import (action line)
  (interactive (list (ros-completing-read-action)  (ros-select-import-line)))
  (save-excursion
    (goto-char line)
    (ros-insert-interface "action" action t)
    (insert "\n")))

(defun ros-insert-interface (type item &optional import)
  (let ((data (ros-parse-interface type item)))
    (cond ((string= major-mode "python-mode") (ros-insert-interface-python data import))
          ((string= major-mode "c++-mode") (ros-insert-interface-cpp data import))
          (t (message "Only C++-mode and Python mode are supported.")))))

(defun ros-insert-interface-python (data import)
  (let ((name (cdr (assoc "name" data)))
        (package (cdr (assoc "package" data)))
        (type (cdr (assoc "type" data))))
    (if import (insert (format "from %s.%s import %s" package type name)) (insert name))))

(defun ros-insert-interface-cpp (data import)
  (if (= (ros-current-version) 1) (ros-insert-interface-cpp-ros1 data import) (ros-insert-interface-cpp-ros2 data import)))

(defun ros-insert-interface-cpp-ros1 (data import)
  (let ((name (cdr (assoc "name" data)))
        (package (cdr (assoc "package" data))))
    (if import (insert (format "#include <%s/%s.h>" package name)) (insert (format "%s::%s" package name)))))

(defun ros-insert-interface-cpp-ros2 (data import)
  (let ((name (cdr (assoc "name" data)))
        (package (cdr (assoc "package" data)))
        (type (cdr (assoc "type" data))))
    (if import (insert (format "#include <%s/%s/%s.hpp>" package type (downcase (string-inflection-underscore-function name)))) (insert (format "%s::%s::%s" package type name)))))

(defun ros-parse-interface (type item)
  (if (= (ros-current-version) 1) (ros-parse-interface-ros1 type item) (ros-parse-interface-ros2 item)))

(defun ros-parse-interface-ros1 (type item)
  (let* ((splits (split-string item "/"))
         (package (cl-first splits))
         (name (cl-second splits)))
    (list (cons "package" package)
          (cons "name" name)
          (cons "type" type))))

(defun ros-parse-interface-ros2 (item)
  (message item)
  (let* ((splits (split-string item "/"))
         (package (cl-first splits))
         (type (cl-second splits))
         (name (cl-third splits)))
    (list (cons "package" package)
          (cons "name" name)
          (cons "type" type))))



(defun ros-list-srvs ()
  (ros-cache-load "srvs" (lambda nil  (if (eq (ros-current-version) 1) (ros-list-srvs-ros1) (ros-list-srvs-ros2)))))

(defun ros-list-srvs-ros1 ()
  (ros-shell-command-to-list "rossrv list"))

(defun ros-list-srvs-ros2 ()
  (cdr (ros-shell-command-to-list "ros2 interface list -s")))

(defun ros-list-actions ()
  (ros-cache-load "actions" (lambda nil  (if (eq (ros-current-version) 1) (ros-list-actions-ros1) (ros-list-actions-ros2)))))

(defun ros-list-actions-ros1 ()
  (error "Actions can only be queried in ROS1"))

(defun ros-list-actions-ros2 ()
  (cdr (ros-shell-command-to-list "ros2 interface list -a")))

(defun ros-show-message-info (msg)
  (interactive (list (ros-completing-read-message)))
  (ros-interface-show-info "msg" msg))

(defun ros-show-srv-info (srv)
  (interactive (list (ros-completing-read-srv)))
  (ros-interface-show-info "srv" srv))

(defun ros-show-action-info (action)
  (interactive (list (ros-completing-read-action)))
  (ros-interface-show-info "action" action))

(defun ros-interface-show-info (type name)
  (let ((buffer-name (format "* ros-%s: %s" type name)))
    (when (get-buffer buffer-name) (kill-buffer buffer-name))
    (pop-to-buffer buffer-name))
  (erase-buffer)
  (insert (ros-interface-info type name))
  (messages-buffer-mode))

(defun ros-interface-info (type name)
  (if (= (ros-current-version) 1) (ros-shell-command-to-string (format "ros%s show %s" type name))
    (ros-shell-command-to-string (format "ros2 interface show %s" name))))


(cl-defun ros-dump-colcon-action (&key workspace verb flags post-cmd)
  (list (cons "workspace" workspace)
        (cons "verb" verb)
        (cons "flags" flags)
        (cons "post-cmd" post-cmd)))

(defun ros-load-colcon-action (action)
  (let* ((ros-current-workspace (cdr (assoc "workspace" action)))
         (source-command (ros-source-command ros-current-workspace))
         (verb (cdr (assoc "verb" action)))
         (flags (cdr (assoc "flags" action)))
         (post-cmd (cdr (assoc "post-cmd" action)))
         )
    (concat source-command " && colcon " verb " " (when flags (string-join flags " ")) (when post-cmd (concat " && " post-cmd)))))

(defun ros-compile-action (action)
  (interactive (list (ros-completing-read-colcon-action-from-history)))
  (let* ((ros-current-workspace (cdr (assoc "workspace" action)))
         (compilation-buffer-name-function (lambda (m) (concat "*Compile " (ros-current-workspace) "*")))
         (default-directory (concat (ros-current-tramp-prefix) (ros-current-workspace))))
    (ros-push-colcon-action-to-history action)
    (compile (format "/bin/bash -c \"%s\"" (ros-load-colcon-action action)))
    (other-window -1)
    ))

(defun ros-push-colcon-action-to-history (action)
  (when (member action ros-colcon-action-history) (setq ros-colcon-action-history (remove action ros-colcon-action-history)))
  (push action ros-colcon-action-history))

(defun ros-display-colcon-action (action)
  "Display string which describes the ACTION."
  (let* ((workspace (cdr(assoc "workspace" action)))
         (workspace-path (cdr (assoc "workspace" workspace)))
         (tramp-prefix (cdr (assoc "tramp-prefix" workspace)))
         (verb (cdr(assoc "verb" action)))
         (flags (cdr(assoc "flags" action)))
         (post-cmd (cdr(assoc "post-cmd" action))))
    (format "%s | %s |  colcon %s %s %s" (if tramp-prefix tramp-prefix "localhost") workspace-path verb (string-join flags " ") (if post-cmd (concat "&& " post-cmd) ""))))

(defvar ros-colcon-action-history '())

(defun ros-completing-read-colcon-action-from-history ()
  (let* ((history-strings (cl-mapcar 'ros-display-colcon-action ros-colcon-action-history))
         (action-string (completing-read "Action: " history-strings nil t))
         (index (seq-position history-strings action-string)))
    (nth index ros-colcon-action-history))
  )

(defun ros-current-package ()
  (let ((default-directory (locate-dominating-file default-directory "package.xml")))
    (when default-directory
      (let ((current-package (ros-shell-command-to-string "colcon list -n" t)))
        (when (not (string= current-package "")) current-package)))))

(defun ros-colcon-build-and-test-current-package (&optional flags)
  (interactive (list (ros-merge-cmake-args-commands (transient-args 'ros-colcon-build-transient))))
  (ros-colcon-build-current-package flags t))

(defun ros-colcon-build-current-package (&optional flags test)
  (interactive (list (ros-merge-cmake-args-commands (transient-args 'ros-colcon-build-transient))))
  (let ((current-package (ros-current-package)))
    (ros-colcon-build-package (if current-package current-package (ros-completing-read-package)) flags test)))

(defun ros-colcon-build-and-test-package (package &optional flags)
  (interactive (list (ros-completing-read-package) (ros-merge-cmake-args-commands (transient-args 'ros-colcon-build-transient))))
  (ros-colcon-build-package package flags t))

(defun ros-colcon-build-package (package &optional flags test)
  "Run a build action to build PACKAGE with FLAGS."
  (interactive (list (ros-completing-read-package) (ros-merge-cmake-args-commands (transient-args 'ros-colcon-build-transient))))
  (ros-compile-action (ros-dump-colcon-action :workspace ros-current-workspace :verb "build" :flags (append (list (concat "--packages-up-to " package)) flags)  :post-cmd (when test (concat "colcon test --packages-select " package " && colcon test-result --verbose")))))

(defun ros-colcon-build-workspace (&optional flags test)
  (interactive (list (ros-merge-cmake-args-commands (transient-args 'ros-colcon-build-transient))))
  (ros-compile-action (ros-dump-colcon-action :workspace ros-current-workspace :verb "build" :flags flags :post-cmd (when test (concat "colcon test --packages-select " package " && colcon test-result --verbose")))))

(defvar ros-additional-cmake-args nil)

(defun ros-merge-cmake-args-commands (flags)
  (let* ((is-cmake-args (lambda (f) (s-starts-with-p "--cmake-args" f)))
         (flags-without-cmake-args (cl-remove-if is-cmake-args flags))
         (cmake-args-flags (seq-filter is-cmake-args flags)))
    (append flags-without-cmake-args '("--cmake-args") (mapcar (lambda (f) (string-trim-left f "--cmake-args")) cmake-args-flags) ros-additional-cmake-args)))

(define-infix-argument ros-colcon-build-transient:--DCMAKE_BUILD_TYPE()
  :description "-DCMAKE_BUILD_TYPE"
  :class 'transient-switches
  :key "-bt"
  :argument-format "--cmake-args -DCMAKE_BUILD_TYPE=%s"
  :argument-regexp "\\(--cmake-args -DCMAKE_BUILD_TYPE=\\(Release\\|Debug\\|RelWithDebInfo\\|MinSizeRel\\)\\)"
  :choices '("Release" "Debug" "RelWithDebInfo" "MinSizeRel"))

(define-infix-argument ros-colcon-build-transient:--DCMAKE_EXPORT_COMPILE_COMMANDS()
  :description "-DCMAKE_EXPORT_COMPILE_COMMANDS"
  :class 'transient-switches
  :key "-ec"
  :argument-format "--cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=%s"
  :argument-regexp "\\(--cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=\\(ON\\|OFF\\)\\)"
  :choices '("ON" "OFF"))

(define-infix-argument ros-colcon-build-transient:--parallel-workers()
  :description "The maximum number of packages to process in parallel"
  :class 'transient-option
  :shortarg "-pw"
  :argument "--parallel-workers "
  :reader 'transient-read-number-N+)

(define-transient-command ros-colcon-build-transient ()
  "Transient command for catkin build."
  ["Arguments"
   ("-c" "continue on failure" "--continue-on-error")
   ("-C" "clean first" "--cmake-clean-first")
   ("-fc" "force CMake configure step" "--cmake-force-configure")
   ("-s" "Use symlinks instead of copying files where possible" "--symlink-install")
   (ros-colcon-build-transient:--DCMAKE_BUILD_TYPE)
   (ros-colcon-build-transient:--DCMAKE_EXPORT_COMPILE_COMMANDS)
   (ros-colcon-build-transient:--parallel-workers)
   ]
  ["Actions"
   ("p" "Build current package" ros-colcon-build-current-package)
   ("P" "Build a package" ros-colcon-build-package)
   ("w" "Build current workspace" ros-colcon-build-workspace)
   ("t" "Build and test current package" ros-colcon-build-and-test-current-package)
   ("T" "Build and test a package" ros-colcon-build-and-test-package)
   ])

(defun ros-colcon-test-current-package (&optional flags)
  (interactive (list (transient-args 'ros-colcon-test-transient)))
  (let ((current-package (ros-current-package)))
    (ros-colcon-test-package (if current-package current-package (ros-completing-read-package)) flags)))

(defun ros-colcon-test-package (package &optional flags)
  (interactive (list (ros-completing-read-package) (transient-args 'ros-colcon-test-transient)))
  (ros-compile-action (ros-dump-colcon-action :workspace ros-current-workspace :verb "test" :flags (append (list (concat "--packages-select " package)) flags) :post-cmd "colcon test-result --verbose")))

(defun ros-colcon-test-workspace (&optional flags)
  (interactive (list (transient-args 'ros-colcon-test-transient)))
  (ros-compile-action (ros-dump-colcon-action :workspace ros-current-workspace :verb "test" :flags flags :post-cmd  "colcon test-result --verbose")))

(define-infix-argument ros-colcon-test-transient:--retest-until-fail()
  :description "Rerun tests up to N times if they pass"
  :class 'transient-option
  :shortarg "-rp"
  :argument "--retest-until-fail "
  :reader 'transient-read-number-N+)

(define-infix-argument ros-colcon-test-transient:--retest-until-pass()
  :description "Rerun failing tests up to N times"
  :class 'transient-option
  :shortarg "-rf"
  :argument "--retest-until-pass "
  :reader 'transient-read-number-N+)

(define-transient-command ros-colcon-test-transient ()
  "Transient command for catkin build."
  ["Arguments"
   ("-a" "abort on error" "--abort-on-error")
   (ros-colcon-build-transient:--parallel-workers)
   (ros-colcon-test-transient:--retest-until-fail)
   (ros-colcon-test-transient:--retest-until-pass)
   ]
  ["Actions"
   ("p" "Test current package" ros-colcon-test-current-package)
   ("P" "Test a package" ros-colcon-test-package)
   ("w" "Test current workspace" ros-colcon-test-workspace)
   ])


(defhydra hydra-ros-main (:color blue :hint nil :foreign-keys warn)
  "
_c_: Compile   _t_: Test   _w_: Set Workspace  _p_: packages
_m_: Messages  _s_: Srvs   _a_: Actions        _x_: Clean Cache
"
  ("c" ros-colcon-build-transient)
  ("t" ros-colcon-test-transient)
  ("w" ros-set-workspace)
  ("p" hydra-ros-packages/body)
  ("m" hydra-ros-messages/body)
  ("s" hydra-ros-srvs/body)
  ("a" hydra-ros-actions/body)
  ("x" ros-cache-clean)
  ("q" nil "quit" :color blue))

(defhydra hydra-ros-packages (:color blue :hint nil :foreign-keys warn)
  "
_g_: Go to package _f_:  Find file current package  _F_: Find file in a package
_s_:  Search in current package  _S_: Search in a package
"
  ("g" ros-go-to-package)
  ("F" ros-find-file-in-package)
  ("f" ros-find-file-in-current-package)
  ("s" ros-grep-in-current-package)
  ("S" ros-grep-in-package)
  ("q" nil "quit hydra")
  ("^" hydra-ros-main/body "Go back"))

(defhydra hydra-ros-messages (:color blue :hint nil :foreign-keys warn)
  "
_i_: Insert message type at point               _s_: Show message
_I_: Insert import statement for message type
"
  ("i" ros-insert-message)
  ("I" ros-insert-message-import)
  ("s" ros-show-message-info)
  ("q" nil "quit hydra")
  ("^" hydra-ros-main/body "Go back"))

(defhydra hydra-ros-srvs (:color blue :hint nil :foreign-keys warn)
  "
_i_: Insert srv type at point               _s_: Show srv
_I_: Insert import statement for srv type
"
  ("i" ros-insert-srv)
  ("I" ros-insert-srv-import)
  ("s" ros-show-srv-info)
  ("q" nil "quit hydra")
  ("^" hydra-ros-main/body "Go back"))

(defhydra hydra-ros-actions (:color blue :hint nil :foreign-keys warn)
  "
_i_: Insert action type at point               _s_: Show action
_I_: Insert import statement for action type
"
  ("i" ros-insert-action)
  ("I" ros-insert-action-import)
  ("s" ros-show-action-info)
  ("q" nil "quit hydra")
  ("^" hydra-ros-main/body "Go back"))



(provide 'ros)
;;; ros.el ends here
