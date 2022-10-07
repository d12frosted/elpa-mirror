;;; clj-deps-new.el --- Create clojure projects from templates  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  jpe90

;; Author: jpe90 <eskinjp@gmail.com>
;; URL: https://github.com/jpe90/emacs-deps-new
;; Package-Version: 20221007.1014
;; Package-Commit: e1cf65eb040f5a2e9a3eca970044ba71cc53fb27
;; Version: 1.1
;; Package-Requires: ((emacs "25.1" ) (transient "0.3.7"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a small wrapper around the deps-new and clj-new tools for creating
;; Clojure projects from templates.
;;
;; It provides access to built-in and some additional commmunity deps-new and
;; clj-new templates via `clj-deps-new'.  The command displays a series of
;; on-screen prompts allowing the user to interactively select arguments,
;; preview their output, and create projects.
;;
;; You can also create transient prefixes and suffixes to access your own custom
;; templates.  (see https://github.com/jpe90/emacs-deps-new#extending)
;; 
;; It requires external utilities 'tools.build', 'deps-new', and 'clj-new' to be
;; installed.  See https://github.com/seancorfield/deps-new for installation
;; instructions.
;;
;; This code assumes you installed 'clj-new' and 'deps-new' as tools using
;; the names 'clj-new' and 'new', respectively, as recommended in the
;; documentation for those tools.  If you used different names or are
;; specifying aliases in your deps.edn, be sure to customize the variables
;; `clj-deps-new-clj-new-alias' and `clj-deps-new-deps-new-alias' to
;; match your setup.
;; 
;; Requires transient.el to be loaded.

;;; Code:

(require 'transient)

;;; =====================================================================
;;;                    Customization variables

(defgroup clj-deps-new nil
  "Wrapper for clj-new and deps-new."
  :group 'clj-deps-new)

(defcustom clj-deps-new-clj-new-alias
  "clj-new"
  "The Clojure CLI tools alias referring to the clj-new tool.
You can find this by either running \"clojure -Ttools list\" if you installed
with \"clojure -Ttools install\", or finding the aliases your user deps.edn if
you manually added it there."
  :group 'clj-deps-new
  :type 'string
  :safe #'stringp)

(defcustom clj-deps-new-deps-new-alias
  "new"
  "The Clojure CLI tools alias referring to the clj-new tool.
You can find this by either running \"clojure -Ttools list\" if you installed
with \"clojure -Ttools install\", or finding the aliases your user deps.edn if
you manually added it there."
  :group 'clj-deps-new
  :type 'string
  :safe #'stringp)

;;; =====================================================================
;;;                    Transient Extensions


(defclass transient-quoted-option (transient-option) ()
  "Class used for escaping text entered by a user to opts for the command.")

(cl-defmethod transient-infix-value ((obj transient-quoted-option))
  "Shell-quote the VALUE in OBJ specified on TRANSIENT-QUOTED-OPTION."
  (let ((value (oref obj value))
        (arg (oref obj argument)))
    (concat arg (shell-quote-argument value))))

;;; =====================================================================
;;;                    Deps-new built-in templates


(defun clj-deps-new--assemble-command (command name opts)
  "Helper function for building the deps-new command string.
COMMAND: string name of the command
NAME: a string consisting of the keyword :name followed by the project name
OPTS: keyword - string pairs provided to the template by the user"
  (concat "clojure -T" clj-deps-new-deps-new-alias " " command " " name " " (mapconcat #'append opts " ")))

(defmacro clj-deps-new-def--transients (arglist)
  "Create the prefix and suffix transients for the built-in deps-new commands.
ARGLIST: a plist of values that are substituted into the macro."
  `(progn
     (transient-define-suffix
       ,(intern (format "execute-%s"  (plist-get arglist :name)))
       (&optional opts)
       ,(format "Create the %s" (plist-get arglist :name))
       :key "c"
       :description ,(plist-get arglist :description)
       (interactive (list (transient-args transient-current-command)))
       (let* ((name (read-string ,(plist-get arglist :prompt)))
              (display-name (concat ":name " (shell-quote-argument name)))
              (command (clj-deps-new--assemble-command
                        ,(plist-get arglist :name)
                        display-name
                        opts)))
         (message "Executing command `%s' in %s" command default-directory)
         (shell-command command)))
     (transient-define-prefix ,(intern (format "new-%s"  (plist-get arglist :name))) ()
       ,(format "Create a new %s" (plist-get arglist :name))
       ["Opts"
        ("-d" "Alternate project folder name (relative path, no trailing slash)"
         ":target-dir "
         :class transient-quoted-option)
        ("-o" "Don't overwrite existing projects" ":overwrite false" :class transient-switch)]
       ["Actions"
        (,(intern (format "execute-%s"  (plist-get arglist :name))))])))
(clj-deps-new-def--transients (:name "app"
                                     :description "Create an Application"
                                     :prompt "Application name: "))
(clj-deps-new-def--transients (:name "lib"
                                     :description "Create a Library"
                                     :prompt "Library name: "))
(clj-deps-new-def--transients (:name "template"
                                     :description "Create a Template"
                                     :prompt "Template name: "))
(clj-deps-new-def--transients (:name "scratch"
                                     :description "Create a Minimal \"scratch\" Project"
                                     :prompt "Scratch name: "))
(clj-deps-new-def--transients (:name "pom"
                                     :description "Create a pom.xml file"
                                     :prompt "Project name: "))

(transient-define-prefix clj-deps-new-deps-builtins ()
  "Generate a project using deps-new."
  ["Select a generation template"
   ("a" "Application" new-app)
   ("l" "Library" new-lib)
   ("t" "Template" new-template)
   ("s" "Scratch" new-scratch)
   ("p" "pom.xml" new-pom)])

;;; =====================================================================
;;;                    Community Templates

;; Kit Web Framework
;; https://kit-clj.github.io

(transient-define-suffix kit-template-suffix
    (&optional opts)
    "Create kit webapp." :key "c" :description "Create the Kit web application"
    (interactive
     (list
      (transient-args transient-current-command)))
    (let*
        ((name (shell-quote-argument (read-string "Project Name: ")))
         (command (concat
                       "clojure -T"
                       clj-deps-new-clj-new-alias
                       " create :template io.github.kit-clj :name "
                       name
                       " :args '[" (mapconcat #'append opts " ") "]'")))
      (message "Executing command `%s' in %s" command default-directory)
      (shell-command command)))

(transient-define-prefix kit-template-prefix nil "Create a kit web application."
  ["Arguments"
   [
    ("-x" "Adds the kit-xtdb lib" "+xtdb" :class transient-switch)
    ("-h" "Adds the kit-hato lib" "+hato" :class transient-switch)
    ("-m" "Adds the kit-metrics lib" "+metrics" :class transient-switch)
    ("-q" "Adds the kit-quartz lib" "+quartz" :class transient-switch)
    ("-d" "Adds the kit-redis lib" "+redis" :class transient-switch)
    ("-s" "Adds the kit-selmner lib" "+selmer" :class transient-switch)
    ("-p" "Adds the kit-postgres lib" "+postgres" :class transient-switch)]
   [("-n" "Adds the kit-nrepl lib" "+nrepl" :class transient-switch)
    ("-r" "Adds the kit-repl lib" "+socket-repl" :class transient-switch)
    ("-c" "Adds the kit-sql-conman lib" "+conman" :class transient-switch)
    ("-k" "Adds the kit-sql-hikari lib" "+hikari" :class transient-switch)
    ("-g" "Adds the kit-sql-migratus lib" "+migratus" :class transient-switch)
    ("-y" "Adds the kit-mysql lib" "+mysql" :class transient-switch)
    ]]
  [("-f" "Adds the libs kit-xtdb, kit-hato , kit-metrics, kit-quartz, kit-redis,
 kit-selmer , kit-repl, kit-sql-conman, kit-postgres, and kit-sql-migratus
" "+full" :class transient-switch)]
    ["Actions"
     (kit-template-suffix)])

;; Cryogen Static Site Generator
;; http://cryogenweb.org

(transient-define-suffix cryogen-template-suffix ()
  "Create kit webapp." :key "c" :description "Create the Cryogen static site"
    (interactive
     ())
    (let*
        ((name (shell-quote-argument (read-string "Project Name: ")))
         (command (concat
                   "clojure -Sdeps '{:deps {io.github.cryogen-project/cryogen
{:git/tag \"0.6.6\" :git/sha \"fcb2833\"}}}' -T"
                       clj-deps-new-deps-new-alias
                       " create :template org.cryogenweb/new :name "
                       name)))
      (message "Executing command `%s' in %s" command default-directory)
      (shell-command command)))

(transient-define-prefix cryogen-template-prefix nil "Create a static site with Cryogen."
  ["Actions"
     (cryogen-template-suffix)])

;;; =====================================================================
;;;                    Main Command

;; When adding your own custom commands, you probably want to append additional
;; transients to this prefix.
;;;###autoload (autoload 'clj-deps-new "clj-deps-new" nil t)
(transient-define-prefix clj-deps-new ()
  "Generate a project using deps-new."
  ["Create a new project"
   ("d" "Deps-new built-in templates" clj-deps-new-deps-builtins)
   ("k" "Kit web application" kit-template-prefix)
   ("c" "Cryogen static site generator" cryogen-template-prefix)])

(provide 'clj-deps-new)
;;; clj-deps-new.el ends here
