;;; jst.el --- JS test mode

;; Copyright (C) 2015 Cheung Hoi Yu

;; Author: Cheung Hoi Yu <yeannylam@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20150604.1138
;; Package-Commit: 865ff97449a4cbbcb40d38b4908cf4d7b22a5108
;; Keywords: js, javascript, jasmine, coffee, coffeescript
;; Package-Requires: ((s "1.9") (f "0.17") (dash "2.10") (pcache "0.3") (emacs "24.4"))
;; URL: https://github.com/cheunghy/jst-mode

;; This file is not part of GNU Emacs.

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

;; This mode deals with multiple javaScript testing frameworks and supports
;; multiple programming languages derived from javaScript.

;;; Code:

(require 'pcache)
(require 'dash)
(require 's)
(require 'f)
(require 'cl-lib)

(defgroup jst nil
  "jst mode"
  :prefix "jst-"
  :group 'applications)

(defcustom jst-keymap-prefix (kbd "C-c t")
  "The prefix for all javaScript testing related key commands."
  :type 'string
  :group 'jst)

;; This is currently unused actually
;; Unless pcache support custom persistent location for repository
(defcustom jst-cache-info-file (convert-standard-filename "~/.emacs.d/.jstcache")
  "Default target for storing jst project informatin and type information."
  :group 'jst
  :type '(choice
          (const :tag "Default value is ~/.emacs.d/.jst" nil)
          file))

(defcustom jst-project-config-file ".jst"
  "The file to dominate a jst project."
  :type 'string
  :group 'jst)

(defvar jst-known-langs-and-exts (make-hash-table :test 'equal)
  "An hash table records known languages and extensions,
keys are language names such as 'LiveScript',
values are list of extensions such as ('ls').")
(setq jst-known-langs-and-exts (make-hash-table :test 'equal))

(defvar jst-known-imenu-settings (make-hash-table :test 'equal)
  "A hash table records known imenu settings. Keys are languange names
remembered by `jst-known-langs-and-exts', values are hashes.
See `jst-remember-imenu-setting' for more information.")

(defvar jst-known-spec-file-patterns '()
  "An list records the global spec file patterns.")

(defvar jst-known-spec-dir-patterns '()
  "An list records the global spec dir patterns.")

(defvar jst-known-project-types (make-hash-table :test 'equal)
  "An hash table records known project types, keys are type
such as \"rails\", values are an complicated object.")

(defvar jst-known-testing-frameworks (make-hash-table :test 'equal)
  "An hash table records known testing frameworks. Keys are framework
names such as \"jasmine\", \"mocha\".")

(defvar jst-known-dominating-files '()
  "An list of files that implies project root directory.")

(defvar jst-known-projects (make-hash-table :test 'equal)
  "A hash table records all the projects.")

(defvar jst-pcache-repo (pcache-repository "jst")
  "The pcache-repository object used by jst.")

(defvar-local jst-last-imenu-generic-expression nil
  "The backup variable for `imenu-generic-expression'.")

(defvar-local jst-last-imenu-create-index nil
  "The backup variable for `imenu-create-index-function'.")

(defconst jst-project-type-and-project-common-keys
  (list :testing-framework :spec-dir :source-dir :config-file :command-ci
        :command-browser :spec-to-target :target-to-spec :browser-url)
  "Common keys of `jst-project-type-keys' and `jst-project-keys'.")

(defconst jst-project-type-keys
  (append jst-project-type-and-project-common-keys
          (list :dominating-files :characteristic))
  "JST project keys.")

(defconst jst-imenu-setting-keys (list :gen-expr :create-index)
  "Default JST imenu setting keys.")

(defconst jst-project-keys
  (append jst-project-type-and-project-common-keys (list :type))
  "Default JST project keys.")

(defconst jst-project-path-keys (list :spec-dir :source-dir :config-file)
  "JST project path keys.")

(defconst jst-testing-frameworks-keys
  (list :command-ci :command-browser :browser-url :config-file
        :keywords :current- :current-))

(defconst jst-default-imenu-generic-expression
  '((nil "^\\( *\\(x?f?describe\\|x?f?it\\|beforeEach\\|beforeAll\\|\
afterEach\\|afterAll\\).*\\)$" 1))
  "The default imenu generic expression.")

(defmacro jst-remember-keyed (arg1 target-table keys-list exist args)
  "This macro helps with jst-remember functions."
  `(if (gethash ,arg1 ,target-table)
       ,exist
     (let ((table (make-hash-table :test 'equal))
           (keys ,keys-list))
       (cl-loop for (label value) on ,args by #'cddr
                do (if (-contains? ,keys-list label)
                       (puthash label value table)))
       (puthash ,arg1 table ,target-table))))

(defun jst-remember-language (&rest args)
  "Let JST remember another language."
  (let (label value lang ext)
    (while (not (= 0 (length args)))
      (setq label (pop args))
      (setq value (pop args))
      (and (equal :extension label) (setq ext value))
      (and (equal :name label) (setq lang value)))
    (if (gethash lang jst-known-langs-and-exts)
        (push ext (gethash lang jst-known-langs-and-exts))
      (puthash lang (list ext) jst-known-langs-and-exts))))

(defun jst-remember-imenu-setting (lang &rest args)
  "Let JST remember another imenu setting."
  (jst-remember-keyed lang jst-known-imenu-settings
                      jst-imenu-setting-keys
                      (error "Redefine JST imenu setting.")
                      args))

(defun jst-query-imenu-setting (lang &optional key)
  "Query JST for imenu setting.
return a hash, if KEY is specified, return a value."
  (catch 'found-it
    (let ((table (gethash lang jst-known-imenu-settings)))
      (unless key (throw 'found-it table))
      (and table (gethash key table)))))

(defun jst-remember-spec-file-pattern (pattern)
  "Let JST know another spec file pattern."
  (push pattern jst-known-spec-file-patterns))

(defun jst-remember-spec-dir-pattern (pattern)
  "Let JST know another spec dir pattern."
  (push pattern jst-known-spec-dir-patterns))

(defun jst-remember-project-type (type &rest args)
  "Let JST remember another project type."
  (jst-remember-keyed type jst-known-project-types
                      jst-project-type-keys
                      (error "Redefined JST project type.")
                      args))

(defun jst-remember-testing-framework (name &rest args)
  "Let JST remember another testing framework."
  (jst-remember-keyed name jst-known-testing-frameworks
                      jst-testing-frameworks-keys
                      (error "Redefined JST testing framework.")
                      args))

(defun jst-query-project-type (type &optional key)
  "Query JST for project type. If KEY is not specified,
return a hash, if KEY is specified, return a value."
  (catch 'found-it
    (let ((table (gethash type jst-known-project-types)))
      (unless key (throw 'found-it table))
      (and table (gethash key table)))))

(defun jst-query-project-type-all (key)
  "Return a list of values specified by KEY."
  (let ((ret-val '()))
    (maphash (lambda (proj-type proj-hash)
               (push (gethash key proj-hash) ret-val)
               ) jst-known-project-types)
    (-uniq (-remove-item nil ret-val))))

(defun jst-remember-dominating-file (name)
  "Let JST know another spec dir pattern."
  (push name jst-known-dominating-files))

(defun jst-serialize-projects ()
  "Serialize loaded projects."
  (pcache-put jst-pcache-repo 'projects jst-known-projects)
  (pcache-save jst-pcache-repo))

(defun jst-unserialize-projects ()
  "Unserialize projects and set `jst-known-projects'."
  (setq jst-known-projects (or (pcache-get jst-pcache-repo 'projects)
                               jst-known-projects)))

(defun jst-remember-project (root &rest args)
  "Let JST remember another project."
  (jst-remember-keyed root jst-known-projects
                      jst-project-keys
                      (error "Redefined JST project.")
                      args))

(defun jst-declare-project (&rest args)
  "This function is aim to be used in project root directory.
Sorry for my poor English. Help me improve the words and grammar."
  (apply 'jst-remember-project (file-name-directory load-file-name) args))

(defun jst-query-project (root &optional key)
  "Query project with a ROOT directory path."
  (catch 'found-it
    (let ((table (if (hash-table-p root) root
                   (gethash root jst-known-projects))))
      (unless key (throw 'found-it (jst-complete-project-info table)))
      (and table (jst-query-project-key table key)))))

(defun jst-query-testing-framework (name &optional key)
  "Query testing framework with a NAME and optional KEY."
  (catch 'found-it
    (let ((table (if (hash-table-p name) name
                   (gethash name jst-known-testing-frameworks))))
      (unless name (throw 'found-it (jst-complete-testing-framework-info table)))
      (and table (gethash key table)))))

(defun jst-complete-testing-framework-info (table)
  ""
  table) ;; TODO

(defun jst-query-project-for-file (file-name &optional key)
  "Query project with a file name."
  (jst-query-project (jst-query-project-root-for-file file-name) key))

(defun jst-project-root-for-project (proj)
  "Return proj root dir of PROJ hash."
  (jst-hashkey proj jst-known-projects))

(defun jst-hashkey (value hash)
  "Return key of VALUE in HASH. nil if not found."
  (catch 'found-it
    (dolist (key (hash-table-keys hash))
      (if (equal (gethash key hash) value)
          (throw 'found-it key)))))

(defun jst-complete-project-info (proj)
  "Given a project table, complete it with default project type settings and
absolute directories."
  (catch 'return
    (unless proj (throw 'return proj))
    (unless (gethash "type" proj) (throw 'return proj))
    (let* ((typen (gethash "type" proj))
           (typed (gethash typen jst-known-project-types))
           (root (jst-hashkey proj jst-known-projects))
           (proj (copy-hash-table proj)))
      (maphash (lambda (key value)
                 (unless (gethash key proj)
                   (puthash key value proj))
                 ) typed)
      (jst-apply-full-path-for-proj proj root))) proj)

(defun jst-apply-full-path-for-proj (proj root)
  "Make all relative paths full path."
  (dolist (key jst-project-path-keys)
    (if (gethash key proj)
        (puthash key (f-expand (gethash key proj) root) proj))))

(defun jst-query-project-key (proj key)
  "Return key's value of project, type is being considerated."
  (catch 'return
    (unless proj (throw 'return nil))
    (if (gethash key proj) (throw 'return (gethash key proj)))
    (unless (gethash "type" proj) (throw 'return nil))
    (gethash key (gethash "type" proj))))

(defun jst-query-project-root-for-file (file-name)
  "Return project root for given FILE-NAME.
FILE-NAME should be complete."
  (catch 'found-it
    (dolist (proj-root (hash-table-keys jst-known-projects))
      (and (s-contains? proj-root file-name)
           (throw 'found-it proj-root)))))

(defun jst-all-reasonable-exts ()
  "Return a list of all reasonable exts."
  (-uniq (-flatten (hash-table-values jst-known-langs-and-exts))))

(defun jst-file-is-js (file-name)
  "Return t if file is js."
  (-contains? (jst-all-reasonable-exts) (f-ext file-name)))

(defun jst-file-is-spec (file-name)
  "Return t if file is js and spec."
  (and (jst-file-is-js file-name)
       (jst-file-matches-spec file-name)))

(defun jst-file-matches-spec (file-name)
  (let ((base-name (file-name-nondirectory file-name)))
    (catch 'found-it
      (dolist (rex jst-known-spec-file-patterns)
        (if (numberp (string-match rex base-name))
            (throw 'found-it t))))))

(defun jst-buffer-is-js (&optional buffer)
  "Return t if buffer is js."
  (setq buffer (or buffer (current-buffer)))
  (jst-file-is-js (buffer-file-name buffer)))

(defun jst-buffer-is-spec (&optional buffer)
  "Return t if buffer is spec."
  (setq buffer (or buffer (current-buffer)))
  (jst-file-is-spec (buffer-file-name buffer)))

(defun jst-enforce-project-of-file (file-name)
  "Figure out project of file and return the project."
  (or (jst-query-project-for-file file-name)
      (jst-load-project (jst-root-project-dir-for-file file-name))
      (jst-register-project (jst-root-project-dir-for-file file-name))))

(defalias 'jst-project-of-file 'jst-enforce-project-of-file)

(defun jst-load-project (root-dir)
  "Load a user defined project in ROOT-DIR.
Return the project if it is defined. Return nil if not defined."
  (if (f-exists? (f-expand jst-project-config-file root-dir))
      (load (f-expand jst-project-config-file root-dir)))
  (jst-query-project root-dir))

(defun jst-register-project (root-dir)
  "Register project."
  (catch 'return
    (unless root-dir (throw 'return nil))
    (let (type spec-dir)
      (setq type (jst-type-of-project root-dir))
      (or (jst-query-project-type type :spec-dir)
          (setq spec-dir (jst-spec-dir-of-root-dir root-dir)))
      (jst-remember-project root-dir :type type :spec-dir spec-dir)
      (jst-query-project root-dir))))

(defun jst-spec-dir-of-root-dir (root-dir)
  "Figure out spec dir given root dir of a project. And it's type is known."
  (let (matched-dirs)
    (setq
     matched-dirs
     (f-directories root-dir (lambda (dir-name)
                               (-find (lambda (pattern)
                                        (string-match pattern dir-name))
                                      jst-known-spec-dir-patterns)) t))
    (-min-by (lambda (a b) (> (jst-path-depth a) (jst-path-depth b))) matched-dirs)))

(defun jst-file-base-name (file-name)
  "Return file base name without all exts."
  (setq file-name (replace-regexp-in-string ".*/" "" file-name))
  (replace-regexp-in-string "\\..*" "" file-name))

(defun jst-file-pure-base-name (file-name)
  "Return file base name even without spec or test part."
  (setq file-name (file-name-nondirectory file-name))
  (dolist (pattern jst-known-spec-file-patterns)
    (let ((match (nth 1 (s-match pattern file-name))))
      (if match (setq file-name (s-replace match "" file-name)))))
  (jst-file-base-name file-name))

(defun jst-locate-dominating-file (path file-name-or-list &optional with-file)
  "This is similar to `locate-dominating-file' but accepts a list
of arguments and can return with the file."
  (setq file-name-or-list (-flatten file-name-or-list))
  (let (d-f-p)
    (catch 'found-it
      (dolist (file-name file-name-or-list)
        (if (setq d-f-p
                  (locate-dominating-file path file-name))
            (if with-file
                (throw 'found-it (f-full (f-expand file-name d-f-p)))
              (throw 'found-it (f-full d-f-p))))))))

(defun jst-file-belongs-to-project (file-name)
  "Return t if FILE-NAME is belong to a known project."
  (stringp (jst-query-project-root-for-file file-name)))

(defun jst-valid-dominating-files ()
  "Return a list of known dominating files."
  (-concat (-flatten (jst-query-project-type-all :dominating-files))
           jst-known-dominating-files))

(defun jst-root-project-dir-for-file (file-name)
  "Return project root dir for the file named FILE-NAME."
  (jst-locate-dominating-file file-name (jst-valid-dominating-files)))

(defun jst-type-of-project (root-dir)
  "Return known type hash of ROOT-DIR, may return nil."
  (let ((types jst-known-project-types)
        (similarity-alist nil) (ret-type nil) (max-simi 0.0))
    (maphash (lambda (type desc)
               (let ((similarity 0.0) (count 0.0) (have 0.0))
                 (dolist (maybe (gethash :characteristic desc))
                   (setq count (1+ count))
                   (if (jst-dir-has-file root-dir maybe)
                       (setq have (1+ have))))
                 (setq similarity (/ have count))
                 (push (cons type similarity) similarity-alist))) types)
    (dolist (cell similarity-alist)
      (if (> (cdr cell) max-simi)
          (progn
            (setq max-simi (cdr cell))
            (setq ret-type (car cell))))) ret-type))

(defun jst-dir-has-file (dir file)
  "Return true if the file is in the path."
  (f-exists? (f-expand file dir)))

(defun jst-spec-file-for-file (file-name)
  "Return spec file for target file FILE-NAME."
  (let* ((project (jst-query-project-for-file file-name))
         (tar-to-spec (jst-query-project project :target-to-spec)))
    (if tar-to-spec
        (funcall tar-to-spec file-name)
      (jst-spec-file-for-file-voilently file-name))))

(defun jst-target-file-for-spec (spec-file)
  "Return target file for spec file SPEC-FILE."
  (let* ((project (jst-query-project-for-file spec-file))
         (spec-to-tar (jst-query-project project :spec-to-target)))
    (if spec-to-tar
        (funcall spec-to-tar spec-file)
      (jst-target-file-for-spec-voilently spec-file))))

(defmacro jst-voilently-binding (file-name &rest body)
  "Used in `jst-spec-file-for-file-voilently' and
`jst-target-file-for-spec-voilently'."
  (declare (indent 1) (debug t))
  `(let* ((project (jst-query-project-for-file ,file-name))
          (spec-dir (or (jst-query-project project :spec-dir)
                        (jst-query-project-root-for-file ,file-name)))
          (source-dir (or (jst-query-project project :source-dir)
                          (jst-query-project-root-for-file ,file-name)))
          (common-parent (f-common-parent (list spec-dir source-dir)))
          (relative-path (f-relative ,file-name common-parent))
          (pure-name (jst-file-pure-base-name ,file-name)))
     ,@body))

(defun jst-spec-file-for-file-voilently (file-name)
  "Find spec file for FILE-NAME, voilently."
  (jst-voilently-binding file-name
    (let ((spec-files (jst-spec-files-for-project project)))
      (setq spec-files
            (-select (lambda (n) (s-contains? pure-name (f-filename n))) spec-files))
      (jst-best-match file-name spec-files))))

(defun jst-target-file-for-spec-voilently (spec-file)
  "Find target file for SPEC-FILE, voilently."
  (jst-voilently-binding spec-file
    (let ((src-files (jst-target-files-for-project project)))
      (setq src-files
            (-select (lambda (n) (s-contains? pure-name (f-filename n))) src-files))
      (jst-best-match spec-file src-files))))

(defun jst-best-match (file-name file-list)
  "Return the best match from FILE-LIST."
  (catch 'done
    (if (equal 0 (length file-list))
        (throw 'done nil))
    (if (equal 1 (length file-list))
        (throw 'done (nth 0 file-list)))
    (let ((similarity-alist nil) (fname-best-matches) (highest 0.0)
          (pure-name (jst-file-pure-base-name file-name))
          (path-best-matches nil))
      ;; Use file name similarity match
      (dolist (testfile file-list)
        (push (cons testfile (/ (* 1.0 (length pure-name))
                                (length (jst-file-pure-base-name testfile))))
              similarity-alist))
      (setq highest (-max (jst-cdrs similarity-alist)))
      (dolist (cell similarity-alist)
        (if (= (cdr cell) highest)
            (push (car cell) fname-best-matches)))
      (if (equal 1 (length fname-best-matches))
          (throw 'done (nth 0 fname-best-matches)))
      ;; Use path similarity
      (setq similarity-alist nil)
      (setq highest 0.0)
      (dolist (testfile fname-best-matches)
        (push (cons testfile (jst-common-path-length testfile file-name))
              similarity-alist))
      (setq highest (-max (jst-cdrs similarity-alist)))
      (dolist (cell similarity-alist)
        (if (= (cdr cell) highest)
            (push (car cell)  path-best-matches)))
      (if (equal 1 (length path-best-matches))
          (throw 'done (nth 0 path-best-matches))
        ;; Let's test file extension
        (throw 'done (-find (lambda (f) (not (f-ext? f "js"))) path-best-matches))
        ;; Unused
        ;; Return randomly maybe suit user's need
        (throw 'done
               (nth (random (length path-best-matches)) path-best-matches))))))

(defun jst-cdrs (alist)
  "Return a list of all cdrs from ALIST."
  (-map 'cdr alist))

(defun jst-spec-files-for-project (proj)
  "Return a list of spec files for PROJ."
  (let (spec-dir)
    (setq spec-dir (or (jst-query-project proj :spec-dir)
                       (jst-project-root-for-project proj)))
    (f-files spec-dir (lambda (file)
                        (jst-file-is-spec file)) t)))

(defun jst-target-files-for-project (proj)
  "Return a list of target files for PROJ."
  (let (src-dir files)
    (setq src-dir (or (jst-query-project proj :source-dir)
                      (jst-project-root-for-project proj)))
    (setq files (f-files src-dir (lambda (file)
                                   (jst-file-is-js file)) t))
    (-remove (lambda (f) (jst-file-is-spec f)) files)))

(defun jst-path-depth (path)
  "Return path depth of PATH. PATH is expanded first."
  (length (s-split (f-path-separator) (f-expand path) t)))

(defun jst-common-path (file1 file2)
  "Return common path of full file name FILE1 and FILE2.
FILE1 and FILE2 will be truncated to very pure form."
  (setq file1 (s-concat (file-name-directory file1)
                        (jst-file-pure-base-name file1)))
  (setq file2 (s-concat (file-name-directory file2)
                        (jst-file-pure-base-name file2)))
  (s-shared-end file1 file2))

(defun jst-common-path-length (file1 file2)
  "Return common path length of full file name FILE1 and FILE2.
FILE1 and FILE2 will be truncated to very pure form."
  (jst-path-depth (jst-common-path file1 file2)))

(defun jst-recover-imenu-settings ()
  "Recover the default imenu generic expression."
  (setq imenu-generic-expression jst-last-imenu-generic-expression)
  (setq imenu-create-index-function jst-last-imenu-create-index))

(defun jst-enhance-imenu-settings ()
  "Set some imenu extras."
  (let* ((lang (jst-programming-language-of-buffer))
         (gen-expr (or (jst-query-imenu-setting lang :gen-expr)
                       jst-default-imenu-generic-expression))
         (create-index (or (jst-query-imenu-setting lang :create-index)
                           'imenu-default-create-index-function)))
    (setq jst-last-imenu-generic-expression imenu-generic-expression)
    (setq jst-last-imenu-create-index imenu-create-index-function)
    (make-local-variable 'imenu-generic-expression)
    (make-local-variable 'imenu-create-index-function)
    (setq imenu-generic-expression gen-expr)
    (setq imenu-create-index-function create-index)
    ))

(defun jst-programming-language-for-file (file-name)
  "Return the programming language for FILE-NAME."
  (catch 'found-it
    (maphash (lambda (k l)
               (if (-contains? l (f-ext file-name))
                   (throw 'found-it k))) jst-known-langs-and-exts)))

(defun jst-programming-language-of-buffer (&optional buffer)
  (jst-programming-language-for-file
   (buffer-file-name (or buffer (current-buffer)))))

(defun jst-run-spec-buffer-name (project)
  "Return the spec buffer name for project. PROJECT can be a project hash or a
root dir."
  (if (hash-table-p project)
      (setq project (jst-hashkey project jst-known-projects)))
  (concat "*jst-spec-run " (file-name-nondirectory project) " *"))

(defun jst-current-project ()
  "Return the current project."
  (jst-query-project (jst-query-project-root-for-file
                      (buffer-file-name (current-buffer)))))

(defun jst-current-project-root ()
  "Return the current project root."
  (jst-hashkey (jst-current-project) jst-known-projects))

(defmacro jst-with-proj-root (body-form)
  `(let ((default-directory (jst-current-project-root)))
     ,body-form))

(defun jst-apply-ansi-color ()
  (ansi-color-apply-on-region compilation-filter-start (point)))

(defun jst-run-spec-terminate ()
  (let ((process (get-buffer-process (current-buffer))))
    (when process (signal-process process 15))))

(defun jst-run-spec (browser-or-ci)
  "Run specs."
  (let ((jst-buffer-name (jst-run-spec-buffer-name (jst-current-project))))
    (if (member jst-buffer-name (mapcar 'buffer-name (buffer-list)))
        (kill-buffer jst-buffer-name))
    (jst-with-proj-root
     (compile (or (jst-query-project (jst-current-project) browser-or-ci)
                  (read-string "Type a command: "))
              'jst-run-spec-mode))))

(defun jst-current-testing-framework ()
  "Return the used testing framework of current project."
  (jst-query-testing-framework
   (jst-query-project (jst-current-project) :testing-framework)))

;; Interactive commands

(defun jst-toggle-current-spec ()
  "Toggle current spec according to current testing framework."
  (interactive)

  ) ;; TODO

(defun jst-toggle-current-block ()
  "Toggle current block according to current testing framework."
  (interactive)
  ) ;; TODO

(defun jst-verify-current-block ()
  "Verify current block."
  (interactive)
  ) ;; TODO

(defun jst-verify-current-spec ()
  "Verify current spec."
  (interactive)
  ) ;; TODO

(defun jst-move-next-spec ()
  "Move to next spec."
  (interactive)
  ) ;; TODO

(defun jst-move-previous-spec ()
  "move to previous spec."
  (interactive)
  ) ;; TODO

(defun jst-move-next-block ()
  "move to previous block."
  (interactive)
  ) ;; TODO

(defun jst-move-previous-block ()
  "move to previous block."
  (interactive)
  ) ;; TODO

(defun jst-refresh-current-project-setting ()
  "Refresh current project setting."
  (interactive)
  (jst-refresh-project-setting
   (jst-query-project-root-for-file (buffer-file-name (current-buffer)))))

(defun jst-refresh-project-setting (root-dir)
  "Refresh project setting."
  (interactive "D")
  (if (gethash root-dir jst-known-projects)
      (remhash root-dir jst-known-projects))
  (jst-enforce-project-of-file root-dir))

(defun jst-refresh-all-project-setting ()
  "Refresh all project settings. It will remove project if a project is not
exist anymore."
  (interactive)
  (dolist (proj (hash-table-keys jst-known-projects))
    (if (f-directory? proj)
        (jst-refresh-project-setting proj)
      (remhash proj jst-known-projects))))

(defun jst-find-spec-file-other-window ()
  "Find the spec file in other window."
  (interactive)
  (find-file-other-window (jst-spec-file-for-file (buffer-file-name))))

(defun jst-find-target-file-other-window ()
  "Find the target file in other window."
  (interactive)
  (find-file-other-window (jst-target-file-for-spec (buffer-file-name))))

(defun jst-run-spec-ci ()
  "Run specs with CI."
  (interactive)
  (jst-run-spec :command-ci))

(defun jst-run-spec-browser ()
  "Run specs in browser."
  (interactive)
  (jst-run-spec :command-browser)
  (let ((browser-url (jst-query-project (jst-current-project) :browser-url)))
    (if browser-url (browse-url browser-url))))

(defun jst-enable-appropriate-mode ()
  "Enable appropriate mode for the opened buffer."
  (if (jst-buffer-is-spec) (jst-mode)
    (if (jst-buffer-is-js) (jst-verifiable-mode))))

;; Load some basic data

(jst-remember-language :extension "js" :name "JavaScript")
(jst-remember-language :extension "es6" :name "ECMA6")
(jst-remember-language :extension "ts" :name "TypeScript")
(jst-remember-language :extension "coffee" :name "CoffeeScript")
(jst-remember-language :extension "ls" :name "LiveScript")

(jst-remember-imenu-setting
 "CoffeeScript"
 :gen-expr nil
 :create-index nil)

(jst-remember-spec-file-pattern "^.+?\\([_-]?\\([sS]pec\\|[tT]est\\)\\)\\.")
(jst-remember-spec-dir-pattern "\\([sS]pec\\|[tT]est\\)")

(jst-remember-dominating-file ".git")
(jst-remember-dominating-file jst-project-config-file)

(jst-remember-project-type
 "rails" :spec-to-target nil :target-to-spec nil
 :testing-framework "jasmine"
 :spec-dir "spec/javascripts"
 :config-file "spec/javascripts/support/jasmine.yml"
 :source-dir "app/assets/javascripts"
 :command-ci "bundle exec rake spec:javascript"
 :command-browser "bundle exec rails s"
 :characteristic '("config.ru" "app/controllers" "app/assets" "public")
 :dominating-files '("config.ru" "Gemfile" "Rakefile"))

;; Key map

(define-prefix-command 'jst-verifiable-command-map)
(define-prefix-command 'jst-command-map)

(define-key 'jst-verifiable-command-map (kbd "b")
  'jst-find-spec-file-other-window)
(define-key 'jst-command-map (kbd "b") 'jst-find-target-file-other-window)

(define-key 'jst-verifiable-command-map (kbd "c")
  'jst-run-spec-ci)
(define-key 'jst-command-map (kbd "c")
  'jst-run-spec-ci)

(define-key 'jst-verifiable-command-map (kbd "a")
  'jst-run-spec-browser)
(define-key 'jst-command-map (kbd "a")
  'jst-run-spec-browser)


(defvar jst-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map jst-keymap-prefix 'jst-command-map)
    map)
  "Keymap for `jst-mode'.")

(defvar jst-verifiable-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map jst-keymap-prefix 'jst-verifiable-command-map)
    map)
  "Keymap for `jst-verifiable-mode'.")

;; Mode definition

(define-minor-mode jst-mode
  "Minor mode for testing javaScrip code.

\\{jst-mode-map}"
  :lighter " JST" :keymap jst-mode-map
  (unless (jst-enforce-project-of-file (buffer-file-name))
    (setq jst-mode nil))
  (if jst-mode
      (jst-enhance-imenu-settings)
    (jst-recover-imenu-settings)))

(define-minor-mode jst-verifiable-mode
  "Minor mode for javaScript files that have specs.

\\{jst-verifiable-mode-map}"
  :lighter "" :keymap jst-verifiable-mode-map
  (unless (jst-enforce-project-of-file (buffer-file-name))
    (setq jst-verifiable-mode nil)))

(define-derived-mode jst-run-spec-mode compilation-mode "JST Run Spec"
  "Compilation mode for running jst specs used by `jst-mode'."
  (add-hook 'compilation-filter-hook 'jst-apply-ansi-color nil t)
  (add-hook 'kill-buffer-hook 'jst-run-spec-terminate t t)
  (add-hook 'kill-emacs-hook 'jst-run-spec-terminate t t)
  (setq-local compilation-scroll-output t))

;; Setup hooks

(eval-after-load 'jst-mode
  (jst-unserialize-projects))

(add-hook 'kill-emacs-hook 'jst-serialize-projects)

(provide 'jst)
;;; jst.el ends here
