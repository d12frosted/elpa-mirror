;;; nix-haskell-mode.el --- haskell-mode integrations for Nix -*- lexical-binding: t -*-

;; Copyright (C) 2019 Matthew Bauer

;; Author: Matthew Bauer <mjbauer95@gmail.com>
;; Homepage: https://github.com/matthewbauer/nix-haskell
;; Keywords: nix, haskell, languages, processes
;; Package-Version: 20190615.135
;; Package-Commit: 68efbcbf949a706ecca6409506968ed2ef928a20
;; Version: 0.0.3
;; Package-Requires: ((emacs "25") (haskell-mode "16.0") (nix-mode "1.3.0"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Setup for this is fairly straightforward. It aims to automatically
;; configure everything for you. It assumes that you are already using
;; haskell-mode and flycheck.

;; If you have use-package setup, this is enough to get nix-haskell
;; working,

;;   (use-package nix-haskell
;;     :hook (haskell-mode . nix-haskell-mode))

;; Opening a buffer will start a nix process to get your dependencies.
;; Flycheck and interactive-haskell-mode will start running once they
;; have been downloaded. This is cached so it will only be done once
;; for each buffer.

;; Flycheck will be started automatically. To start a haskell session,
;; press C-c C-l.

;; nix-haskell is designed to build package dbs in Nix and then pass
;; them to GHC. This should avoid some of the security issues in using
;; ‘nix-shell’ automatically in visited directories.

;;; History:

;; This originally lived in https://github.com/matthewbauer/bauer but
;; was moved so it could be included in MELPA.

;;; Code:

(require 'nix)
(require 'nix-instantiate)
(require 'nix-store)
(require 'haskell)

(defgroup nix-haskell nil
  "Nix integration with haskell-mode.el"
  :group 'nix)

(defcustom nix-haskell-verbose nil
  "Whether to print lots of messages when running nix-haskell.el."
  :type 'boolean
  :group 'nix-haskell)

(defcustom nix-haskell-ttl (* 60 10)
  "Time in seconds to keep the cache."
  :type 'integer
  :group 'nix-haskell)

(defcustom nix-haskell-flycheck nil
  "Whether to enable flycheck."
  :type 'boolean
  :group 'nix-haskell)

(defcustom nix-haskell-interactive t
  "Whether to enable variable ‘interactive-haskell-mode’."
  :type 'boolean
  :group 'nix-haskell)

(defcustom nix-haskell-interactive-auto t
  "Whether to start an variable ‘interactive-haskell-mode’ session automatically."
  :type 'boolean
  :group 'nix-haskell)

;; Prefix to use in the lighters
(defconst nix-haskell-lighter-prefix " NixH")

;; Expression used to build Haskell’s package db

;; We don’t want to just get ghc from the Nix file. This would leave
;; us vulnerable to malicious projects. Instead, we get the compiler
;; name and try to find it in nixpkgs.haskell.compiler. These aren’t
;; left in Nixpkgs for very long so we try to download some channels
;; to see if they are in there.
(defvar nix-haskell-pkg-db-expr "{ pkgs ? import <nixpkgs> {}
, haskellPackages ? pkgs.haskellPackages
, nixFile ? null, packageName, cabalFile
, compilers ? {
  ghc6104 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc6104;
  ghc6121 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc6121.ghc;
  ghc6122 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc6122.ghc;
  ghc6123 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc6123;
  ghc701 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc701.ghc;
  ghc702 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc702.ghc;
  ghc703 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc703.ghc;
  ghc704 = (import (builtins.fetchTarball \"channel:nixos-18.03\") {}).haskell.compiler.ghc704;
  ghc721 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc721.ghc;
  ghc722 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc722;
  ghc741 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc741.ghc;
  ghc742 = (import (builtins.fetchTarball \"channel:nixos-18.03\") {}).haskell.compiler.ghc742;
  ghc761 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc761.ghc;
  ghc762 = (import (builtins.fetchTarball \"channel:nixos-14.04\") {}).pkgs.haskell.packages_ghc762.ghc;
  ghc763 = (import (builtins.fetchTarball \"channel:nixos-18.03\") {}).haskell.compiler.ghc763;
  ghc783 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc783;
  ghc784 = (import (builtins.fetchTarball \"channel:nixos-18.03\") {}).haskell.compiler.ghc784;
  ghc7102 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc7102;
  ghc7103 = (import (builtins.fetchTarball \"channel:nixos-18.09\") {}).haskell.compiler.ghc7103;
  ghc801 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc801;
  ghc802 = (import (builtins.fetchTarball \"channel:nixos-18.09\") {}).haskell.compiler.ghc802;
  ghc821 = (import (builtins.fetchTarball \"channel:nixos-17.09\") {}).haskell.compiler.ghc821;
  ghc822 = (import (builtins.fetchTarball \"channel:nixos-19.03\") {}).haskell.compiler.ghc822;
  ghc841 = (import (builtins.fetchTarball \"channel:nixos-18.03\") {}).haskell.compiler.ghc841;
  ghc843 = (import (builtins.fetchTarball \"channel:nixos-18.09\") {}).haskell.compiler.ghc843;
  ghc844 = (import (builtins.fetchTarball \"channel:nixos-19.03\") {}).haskell.compiler.ghc844;
  ghc861 = (import (builtins.fetchTarball \"channel:nixos-18.09\") {}).haskell.compiler.ghc861;
  ghc862 = (import (builtins.fetchTarball \"channel:nixos-18.09\") {}).haskell.compiler.ghc862;
  ghc863 = (import (builtins.fetchTarball \"channel:nixos-18.09\") {}).haskell.compiler.ghc863;
  ghc864 = (import (builtins.fetchTarball \"channel:nixos-19.03\") {}).haskell.compiler.ghc864;
} }: let
  inherit (pkgs) lib;
  getGhc = name: let compilerName = lib.replaceStrings [\".\" \"-\"] [\"\" \"\"] name;
                 in pkgs.haskell.compiler.${compilerName} or compilers.${compilerName} or (throw \"Can’t find haskell compiler ${compilerName}\");
  buildPkgDb = pkg: let
    maybeGhc = if pkg.nativeBuildInputs != [] then builtins.head pkg.nativeBuildInputs else null;
    compiler = if pkg ? compiler then getGhc pkg.compiler.name
               else if maybeGhc != null && builtins.match \"^ghc.*\" maybeGhc.name != null
                    then getGhc (if maybeGhc ? version then \"ghc-${maybeGhc.version}\" else maybeGhc.name)
               else throw \"Can’t find compiler for ${pkg.name}.\";
    package-db = pkgs.buildEnv {
      name = \"${packageName}-package-db-${compiler.name}\";
      paths = [ compiler ] ++ lib.closePropagation
                (pkg.getBuildInputs.haskellBuildInputs or
                  (pkg.buildInputs ++ pkg.propagatedBuildInputs ++ pkg.nativeBuildInputs));
      pathsToLink = [ \"/lib/${compiler.name}/package.conf.d\" ];
      buildInputs = [ compiler ];
      postBuild = ''
        ghc-pkg --package-db=$out/lib/${compiler.name}/package.conf.d recache
      '';
      ignoreCollisions = true;
    };
    compilerBin = pkgs.buildEnv {
      name = \"${compiler.name}-bins\";
      paths = [ compiler ];
      pathsToLink = [ \"/bin\" ];
    };
  in pkgs.buildEnv {
    name = \"${packageName}-${compiler.name}-wrapped\";
    paths = [ package-db pkgs.cabal-install compilerBin ];
  };
  pkg = if nixFile == null
        then haskellPackages.callCabal2nix \"auto-callcabal2nix\" (builtins.toPath cabalFile) {}
        else (let nixExpr = import nixFile;
                  nixExpr' = if builtins.isFunction nixExpr
                             then (if (builtins.functionArgs nixExpr) ? mkDerivation
                                   then haskellPackages.callPackage nixFile {}
                                   else nixExpr {})
                             else nixExpr;
              in (if lib.isDerivation nixExpr'
                     then (if nixExpr' ? shells
                           then nixExpr'.shells.ghc
                           else nixExpr')
                  else if builtins.isAttrs nixExpr'
                  then let nixExpr'' = if nixExpr' ? proj then nixExpr'.proj
                                       else if nixExpr' ? shells then nixExpr'
                                       else if nixExpr' ? haskellPackages then nixExpr'.haskellPackages
                                       else if nixExpr' ? haskellPackageSets then nixExpr'.haskellPackageSets.ghc
                                       else if nixExpr' ? ghc then nixExpr'.ghc
                                       else nixExpr';
                       in (if nixExpr'' ? shells then nixExpr''.shells.ghc
                           else if nixExpr'' ? ${packageName} then nixExpr''.${packageName}
                           else if nixExpr'' ? callCabal2nix
                                then nixExpr''.callCabal2nix \"auto-callcabal2nix\" (builtins.toPath cabalFile) {}
                           else haskellPackages.callCabal2nix \"auto-callcabal2nix\" (builtins.toPath cabalFile) {})
                  else throw \"Can't import ${nixFile} correctly.\"));
in buildPkgDb pkg")

(defvar nix-haskell-running-processes nil
  "Store information on running Nix evaluations.")

(defvar nix-haskell-package-db-cache nil
  "Cache information on past Nix evaluations.")

(defvar-local nix-haskell-package-name nil
  "Stores the package name.")

(defvar-local nix-haskell-status (concat nix-haskell-lighter-prefix "?")
  "Get the status of nix-haskell buffer.")

(defun nix-haskell-clear-cache ()
  "Clean the nix-haskell cache."
  (interactive)
  (setq nix-haskell-package-db-cache nil))

(defun nix-haskell-message (str)
  "Messaging appropriate in nix-haskell async processes.
STR message to send to minibuffer"
  (unless (active-minibuffer-window)
    (message "%s" str)))

(defun nix-haskell-store-sentinel (err buf drv-file drv _ event)
  "Make a nix-haskell process.
ERR the error buffer.
BUF the main buffer.
DRV-FILE filename of derivation.
DRV parsed derivation file.
PROC the process that has been run.
EVENT the event that was fired."
  (pcase event
    ("finished\n"
     (kill-buffer err)
     (nix-haskell-interactive buf drv-file drv))
    (_
     ;; (display-buffer err)
     (nix-haskell-message "Running nix-haskell failed to realise the store path")
     (setq nix-haskell-status (concat nix-haskell-lighter-prefix "!")))))

(defun nix-haskell-instantiate-sentinel (prop err proc event)
  "Make a nix-haskell process.
PROP the prop name of ‘nix-haskell-running-processes’.
ERR the error buffer.
PROC the process that has been run.
EVENT the event that was fired."
  (pcase event
    ("finished\n"
     (with-current-buffer (process-buffer proc)
       (unless (eq (buffer-size) 0)
	 ;; Parse nix-instantiate output
	 (let* ((drv-file (substring (buffer-string) 0 (- (buffer-size) 1)))
		(drv (nix-instantiate--parsed drv-file))

		;; Hacky way to get output path without building it.
		(out (cdadr (cadar drv))))
	   (dolist
	       (callback (lax-plist-get nix-haskell-running-processes prop))
	     (funcall callback out drv-file))
	   (setq nix-haskell-package-db-cache
		 (lax-plist-put nix-haskell-package-db-cache
				prop (list (float-time) out drv-file))))))
     (setq nix-haskell-running-processes
	   (lax-plist-put nix-haskell-running-processes prop nil))
     (kill-buffer err))
    (_
     ;; (display-buffer err)
     (nix-haskell-message "Running nix-haskell failed to instantiate")
     (setq nix-haskell-status (concat nix-haskell-lighter-prefix "!"))))
  (unless (process-live-p proc)
    (kill-buffer (process-buffer proc))))

(defun nix-haskell-root ()
  "Get the nix-haskell root."
  (let (root)
    (or
     (setq root (locate-dominating-file default-directory "cabal.project"))
     (setq root (locate-dominating-file default-directory "default.nix"))
     (setq root (locate-dominating-file default-directory "shell.nix"))
     (setq root (file-name-directory (nix-haskell-cabal-file))))
    (when root
      (setq root (expand-file-name root)))
    root))

(defun nix-haskell-package-name ()
  "Get the package name of the project."
  (unless nix-haskell-package-name
    (setq nix-haskell-package-name
	  (replace-regexp-in-string
	   ".cabal$" ""
	   (file-name-nondirectory (nix-haskell-cabal-file)))))
  nix-haskell-package-name)

(defun nix-haskell-nix-file ()
  "Get the nix file based on the current directory."
  (let ((root (nix-haskell-root)) nix-file)
    ;; Look for shell.nix or default.nix
    (unless (and nix-file (file-exists-p nix-file))
      (setq nix-file (expand-file-name "shell.nix" root)))
    (unless (and nix-file (file-exists-p nix-file))
      (setq nix-file (expand-file-name "default.nix" root)))
    (when (and nix-file (file-exists-p nix-file)) nix-file)))

(defvar-local nix-haskell-instantiate-stderr nil
  "Store stderr buffer")
(defvar-local nix-haskell-store-stderr nil
  "Store stderr buferr")

(defun nix-haskell-get-pkg-db (callback)
  "Get a package-db async.
CALLBACK called once the package-db is determined."
  (let* ((cabal-file (nix-haskell-cabal-file))
	 (cache (lax-plist-get nix-haskell-package-db-cache cabal-file))
	 (root (nix-haskell-root))
	 (nix-file (nix-haskell-nix-file))
	 (package-name (nix-haskell-package-name)))
    (when cache (apply callback (cdr cache)))

    (when (or (not cache)
              (> (float-time) (+ (car cache) nix-haskell-ttl))
              (> (time-to-seconds
                  (nth 5 (file-attributes cabal-file)))
                 (car cache)))
      (setq nix-haskell-instantiate-stderr
	    (generate-new-buffer
	     (format "*nix-haskell-instantiate-stderr<%s>*"
		     package-name)))
      (let* ((data (lax-plist-get nix-haskell-running-processes cabal-file))
	     (stdout (generate-new-buffer
		      (format "*nix-haskell-instantiate-stdout<%s>*"
			      package-name)))
	     (command
	      (list nix-instantiate-executable
		    "-E" nix-haskell-pkg-db-expr
		    "--argstr" "cabalFile" cabal-file
		    "--argstr" "packageName" package-name)))

        (when nix-haskell-verbose
          (nix-haskell-message (format "Running nix-instantiate for %s..." cabal-file)))

        (when nix-file
          (when nix-haskell-verbose
	    (nix-haskell-message (format "Found Nix file at %s." nix-file)))
          (setq command
                (append command (list "--argstr" "nixFile" nix-file))))

	;; Pick up projects with custom package sets. This is
	;; required for some important projects like those based on
	;; Obelisk or reflex-platform.
        (cond
         ((file-exists-p (expand-file-name "reflex-platform.nix" root))

          (when nix-haskell-verbose
            (nix-haskell-message "Detected reflex-platform project."))

	  (setq command
		(append command
			(list "--arg" "haskellPackages"
			      (format "(import %s {}).ghc"
				      (expand-file-name "reflex-platform.nix"
							root))))))

         ((file-exists-p (expand-file-name ".obelisk/impl/default.nix" root))

          (when nix-haskell-verbose
            (nix-haskell-message "Detected obelisk project."))

	  (setq command
		(append command
			(list "--arg" "haskellPackages"
			      (format "(import %s {}).haskellPackageSets.ghc"
				      (expand-file-name
				       ".obelisk/impl/default.nix" root))))))

         ;; ((and (file-exists-p (expand-file-name "default.nix" root))
         ;;       (not (string= (expand-file-name "default.nix" root)
         ;;                     nix-file)))
         ;;  (when nix-haskell-verbose
         ;;    (nix-haskell-message "Detected default.nix."))
	 ;;  (setq command
	 ;;        (append command
	 ;;             (list "--arg" "haskellPackages"
	 ;;                   (format "(import %s {})"
	 ;;                           (expand-file-name "default.nix"
	 ;;                                             root))))))
         )

	(setq nix-haskell-running-processes
	      (lax-plist-put nix-haskell-running-processes
			     cabal-file (cons callback data)))

        ;; (when nix-haskell-verbose
        ;;   (nix-haskell-message (format "Running %s." command)))

	(setq nix-haskell-status (concat nix-haskell-lighter-prefix "*"))
	(make-process
	 :name (format "*nix-haskell*<%s>" package-name)
	 :buffer stdout
	 :command command
	 :noquery t
	 :sentinel (apply-partially 'nix-haskell-instantiate-sentinel
				    cabal-file nix-haskell-instantiate-stderr)
	 :stderr nix-haskell-instantiate-stderr)

	;; Don’t let hooks wait for make-process.
	t))))

(defvar flycheck-haskell-ghc-executable)
(defvar flycheck-haskell-runghc-command)
(defvar flycheck-ghc-package-databases)

(defun nix-haskell-interactive (buf out drv)
  "Setup interactive buffers for nix-haskell.

Handles flycheck and haskell-interactive modes currently.

BUF the buffer this was called from.
OUT filename of derivation.
DRV derivation file."
  (if (file-exists-p out)
      (let ((package-db out))

        (when nix-haskell-verbose
          (nix-haskell-message "nix-haskell succeeded in buffer."))

	(with-current-buffer buf
	  (setq nix-haskell-status (concat nix-haskell-lighter-prefix
					   "[" (nix-haskell-package-name) "]"))

	  ;; Find package db directory.
	  (setq package-db (expand-file-name "lib" package-db))
	  (setq package-db (expand-file-name
			    (car (directory-files package-db nil "^ghc"))
			    package-db))
	  (setq package-db (expand-file-name "package.conf.d" package-db))

	  (setq-local haskell-compile-cabal-build-command
		      (concat "cd %s && " (expand-file-name "bin/cabal" out) " new-build"))

	  ;; Setup haskell-mode args.
          (setq-local haskell-process-type 'cabal-new-repl)
	  (setq-local haskell-process-path-cabal
		      (expand-file-name "bin/cabal" out))
	  (make-local-variable 'haskell-process-args-cabal-new-repl)
	  (add-to-list 'haskell-process-args-cabal-new-repl
		       (format "--with-ghc-pkg=%s/bin/ghc-pkg" out) t)
	  (add-to-list 'haskell-process-args-cabal-new-repl
		       (format "--with-ghc=%s/bin/ghc" out) t)
	  (add-to-list 'haskell-process-args-cabal-new-repl
		       (format "--with-hsc2hs=%s/bin/hsc2hs" out) t)
	  (add-to-list 'haskell-process-args-cabal-new-repl
	               (format "--ghc-pkg-option=--global-package-db=%s"
			       package-db) t)
	  (add-to-list 'haskell-process-args-cabal-new-repl
		       (format "--ghc-option=-package-db=%s" package-db) t)

	  (when nix-haskell-interactive
	    (interactive-haskell-mode 1)
            (when nix-haskell-interactive-auto
              (let ((haskell-process-load-or-reload-prompt nil))
		(haskell-session-new-assume-from-cabal)
		(haskell-process-load-file))))

	  ;; Setup flycheck.
	  (setq-local flycheck-haskell-ghc-executable
		      (expand-file-name "bin/ghc" out))
	  (setq-local flycheck-haskell-runghc-command
		      (list (expand-file-name "bin/runghc" out) "--" "-i"
			    "-packageCabal" "-packagebase"
			    "-packagebytestring" "-packagecontainers"
			    "-packagedirectory" "-packagefilepath"
			    "-packageprocess"))
	  (make-local-variable 'flycheck-ghc-package-databases)
	  (add-to-list 'flycheck-ghc-package-databases package-db)

	  (when nix-haskell-flycheck
	    (require 'flycheck)
	    (require 'flycheck-haskell)
	    (flycheck-haskell-setup)
	    (flycheck-mode 1))))
    (let ((stderr (generate-new-buffer
		   (format "*nix-haskell-store<%s>*" (nix-haskell-package-name)))))
      (with-current-buffer buf
	(setq nix-haskell-status (concat nix-haskell-lighter-prefix "+"))
	(setq nix-haskell-store-stderr stderr))
      (make-process
       :name (format "*nix-haskell-store<%s>*" (nix-haskell-package-name))
       :buffer nil
       :command (list nix-store-executable "-r" drv)
       :noquery t
       :sentinel (apply-partially 'nix-haskell-store-sentinel
				  stderr buf out drv)
       :stderr stderr))))

(defun nix-haskell-status ()
  "Get the current status of a buffer."
  nix-haskell-status)

(defun nix-haskell-cabal-file ()
  "Get the current cabal file for the project."
  (let ((cabal-file (haskell-cabal-find-file default-directory)))
    (when cabal-file (setq cabal-file (expand-file-name cabal-file)))
    cabal-file))

(defun nix-haskell-restart ()
  "Restart variable ‘nix-haskell-mode’ process."
  (interactive)
  (setq nix-haskell-package-db-cache
	(lax-plist-put nix-haskell-package-db-cache
		       (nix-haskell-cabal-file) nil))
  (nix-haskell-get-pkg-db (apply-partially (lambda (buf &rest args)
					     (apply 'nix-haskell-interactive buf args)
					     (with-current-buffer buf
					       (haskell-process-restart)
					       (haskell-process-load-file))
					     ;; TODO: restart all haskell buffers!
					     )
					   (current-buffer))))

(defun nix-haskell-show-buffer ()
  "Show buffer used in nix-haskell."
  (interactive)
  (cond
   (nix-haskell-store-stderr
    (display-buffer nix-haskell-store-stderr))
   (nix-haskell-instantiate-stderr
    (display-buffer nix-haskell-instantiate-stderr))
   (t (error "No nix-haskell buffer is active"))))

(defvar nix-haskell-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for nix-haskell minor mode.")

(easy-menu-define nil nix-haskell-mode-map "nix-haskell-mode menu"
  '("NixHaskell"
    ["Clear cache" nix-haskell-clear-cache
     :help "Clear the nix-haskell-mode cache."]
    ["Restart" nix-haskell-restart
     :help "Restart the nix-haskell-mode process."]
    ["Configure..." (lambda () (interactive) (customize-group 'nix-haskell))
     :help "Customize nix-haskell-mode settings."]
    ["Show buffer" nix-haskell-show-buffer
     :help "Show the buffer used to download the Nix dependencies."]))

(define-minor-mode nix-haskell-mode
  "Minor mode for nix-haskell-mode."
  :lighter (:eval (nix-haskell-status))
  :group 'nix-haskell
  :keymap nix-haskell-mode-map
  (if nix-haskell-mode
      (progn
	(if (nix-haskell-cabal-file)
	    (progn
	      ;; Disable flycheck and interactive-haskell-mode.
	      ;; They will be reenabled later.
	      (when (and nix-haskell-flycheck (fboundp 'flycheck-mode))
		(flycheck-mode -1))
	      (when (and nix-haskell-interactive (fboundp 'interactive-haskell-mode))
		(interactive-haskell-mode -1))
	      ;; Need to keep the buffer for after the process has run.
	      (nix-haskell-get-pkg-db (apply-partially 'nix-haskell-interactive
						       (current-buffer))))
	  (setq nix-haskell-status "")))
    (progn
      ;; Undo changes made
      )))

(defun nix-haskell-mode-message-line (str)
  "Echo STR in mini-buffer.
Given string is shrinken to single line, multiple lines just
disturbs the programmer."
  (unless (active-minibuffer-window)
    (message "%s" (haskell-mode-one-line str (frame-width)))))

(provide 'nix-haskell-mode)
;;; nix-haskell-mode.el ends here
