;;; sailfish-scratchbox.el --- Sailfish OS scratchbox inside the emacs.

;; Copyright (C) 2017 Victor Polevoy

;; Author: V. V. Polevoy <fx@thefx.co>
;; Version: 1.2.2
;; Package-Version: 20171202.1332
;; Package-Commit: bb5ed0f0b0cd72f2eb1af065b7587ec81866b089
;; Keywords: sb2, mb2, building, scratchbox, sailfish
;; URL: https://github.com/vityafx/sailfish-scratchbox.el
;; License: MIT

;;; Commentary:

;; This package provides easier way to run sailfish os sdk scripts
;; and tools as 'mb2 build' for example.

;;; Code:
(require 'compile)


(defgroup sailfish-scratchbox nil
  "Sailfish scratchbox utils"
  :group 'tools)

(defcustom sailfish-scratchbox-interpreter "bash -ic"
  "The interpreter to run the scripts with."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-which-sdk "sdk"
  "The path of the sdk environment script."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-mb2-build "mb2 build"
  "The command of the mb2 build script."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-mb2-build-options ""
  "The mb2-build script options."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-build-buffer-name "*scratchbox build*"
  "The sailfish scratchbox build buffer name."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-deploy-buffer-name "*scratchbox deploy*"
  "The sailfish scratchbox build buffer name."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-deploy-rpms-command "scp RPMS/*.rpm nemo@192.168.2.15:/home/nemo"
  "The sailfish scratchbox deploy command.
User must have his identity installed onto the phone is the command invokes scp."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)

(defcustom sailfish-scratchbox-install-in-sdk "sb2 -R rpm -i RPMS/*.rpm --force --verbose"
  "The sailfish scratchbox command to install project packages into the sdk."
  :type 'string
  :group 'sailfish-scratchbox
  :safe #'stringp)


(defun scratchbox-project-root ()
  "Return project root."
  (or (locate-dominating-file buffer-file-name ".git/") (locate-dominating-file buffer-file-name "rpm/")))

(defun scratchbox-mb2-build-generate-command ()
  "Compile a full cmd line for invoking mb2 build script.

Something like 'sdk mb2 build'"
  (concat sailfish-scratchbox-interpreter " " (shell-quote-argument (concat sailfish-scratchbox-which-sdk " "
                                                                            sailfish-scratchbox-mb2-build))
          " " sailfish-scratchbox-mb2-build-options))

(defun scratchbox-install-rpms-generate-command ()
  "Compile a full cmd line for installing rpm packages into a target."
  (concat sailfish-scratchbox-interpreter " " (shell-quote-argument (concat sailfish-scratchbox-which-sdk " "
                                                                            sailfish-scratchbox-install-in-sdk))))

(define-compilation-mode sailfish-scratchbox-compilation-mode "sailfish scratchbox"
  "Sailfish scratchbox compilation mode")

(defun run-with-project-path (function-to-run)
  "Run the FUNCTION-TO-RUN if the current buffer is inside a project."
  (let ((root-dir (scratchbox-project-root)))
    (if root-dir
        (funcall function-to-run root-dir)
        (message "(%s) does not seem to be inside a valid sailfish os project." (buffer-name)))))

(defun scratchbox-mb2-build-run (project-root-path)
  "Run the mb2 build script on the project with PROJECT-ROOT-PATH."
  (save-some-buffers (not compilation-ask-about-save)
                     (when (boundp 'compilation-save-buffers-predicate)
                       compilation-save-buffers-predicate))
  (when (get-buffer sailfish-scratchbox-build-buffer-name)
    (kill-buffer sailfish-scratchbox-build-buffer-name))
  (let ((command-to-run (scratchbox-mb2-build-generate-command)))
      (with-current-buffer (get-buffer-create sailfish-scratchbox-build-buffer-name)
        (setq default-directory project-root-path)
        (compilation-start command-to-run 'sailfish-scratchbox-compilation-mode (lambda (m) (buffer-name))))))

(defun scratchbox-deploy-rpms-run (project-root-path)
  "Run the deploy command with PROJECT-ROOT-PATH."
  (when (get-buffer sailfish-scratchbox-deploy-buffer-name)
    (kill-buffer sailfish-scratchbox-deploy-buffer-name))
  (let ((command-to-run sailfish-scratchbox-deploy-rpms-command))
      (with-current-buffer (get-buffer-create sailfish-scratchbox-deploy-buffer-name)
        (setq default-directory project-root-path)
        (compilation-start command-to-run 'sailfish-scratchbox-compilation-mode (lambda (m) (buffer-name))))))

(defun scratchbox-install-rpms-run (project-root-path)
  "Run the install rpm packages command with PROJECT-ROOT-PATH."
  (when (get-buffer sailfish-scratchbox-deploy-buffer-name)
    (kill-buffer sailfish-scratchbox-deploy-buffer-name))
  (let ((command-to-run (scratchbox-install-rpms-generate-command)))
    (with-current-buffer (get-buffer-create sailfish-scratchbox-deploy-buffer-name)
      (setq default-directory project-root-path)
      (compilation-start command-to-run 'sailfish-scratchbox-compilation-mode (lambda (m) (buffer-name))))))

;;;###autoload
(defun sailfish-scratchbox-mb2-build ()
  "Build the project inside the sdk this file is in."
  (interactive)
  (run-with-project-path 'scratchbox-mb2-build-run))

;;;###autoload
(defun sailfish-scratchbox-deploy-rpms ()
  "Copy the the built project artifacts to the phone."
  (interactive)
  (run-with-project-path 'scratchbox-deploy-rpms-run))

;;;###autoload
(defun sailfish-scratchbox-install-rpms ()
  "Install project rpm packages into the sailfish os scratchbox."
  (interactive)
  (run-with-project-path 'scratchbox-install-rpms-run))

(provide 'sailfish-scratchbox)
;;; sailfish-scratchbox.el ends here
