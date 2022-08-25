;;; toggle-test.el --- Toggle between source and test files in various programming languages

;; Copyright (C) 2014 Raghunandan Rao

;; Author: Raghunandan Rao <r.raghunandan@gmail.com>
;; Keywords: tdd test toggle productivity
;; Package-Version: 20140723.537
;; Package-Commit: a0b64834101c2b8b24da365baea1d36e57b069b5
;; Version: 1.0.2
;; Url: https://github.com/rags/toggle-test

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
;; Toggle test provides test toggle functionality very similar to Jetbrains 
;; IDEs like IntelliJ/Rubymine/Pycharm. It presents
;; the user with choices in case there are multiple macthes (Ex: You have 
;; integration and unit test for the same source file). It creates the file 
;; (test or source), along with the entire directory hierarchy if the file does
;; not exist. 
;; It is language agnostic so you can use it on your rails, django, scala, node.js 
;; or any other projects.

;;; Change log:
;; - 1.0 - Initial release
;; - 1.0.1 - autoloads added
;; - 1.0.2 - swapped order of detecting src and test to handle cases where test is subdirectory of src

;;; Code:

(require 'cl)

(defgroup toggle-test nil
  "IntelliJ like facility to quickly toggle between source and its corresponding test files."
  :group 'convenience
  :prefix "tgt-"
  :link '(emacs-library-link :tag "Lisp File" "toggle-test.el"))

;; A list of projects. Each item in this list is a an alist that specifies,
;; 1. The project root directory
;; 2. Source folder(s) (relative to root directory)
;; 3. Test source folder(s) (relative to root directory)
;; 4. prefix/suffix attached to source file names to name the test files
;;    Ex: src/foo.py <-> test/test_foo.py - the prefix is 'test_'
;;        src/controllers/Foo.scala <-> specs/controllers/Foo$Spec.scala 
;;        The suffix here is '$Spec'.
;;    Note: you can specify both prefix and suffix if required.
;;
;; Usage:
;; (add-to-list 'tgt-projects '((:root-dir "~/python-project") 
;;                             (:src-dirs "src") (:test-dirs "tests") 
;;                             (:test-prefixes "test-")))          
;; (add-to-list 'tgt-projects '((:root-dir "~/scala-project") 
;;                             (:src-dirs "src") (:test-dirs "specs") 
;;                             (:test-suffixes "$Spec")))

;;;###autoload
(defcustom tgt-projects '() 
  "Project entries. 
One entry per project that provides naming convention and folder structure"
  :group 'toggle-test
  :type '(repeat (alist)))

;; Indicates if the toggle file should be opened in a new window 
;; or replace the buffer in current window. The default behavior is to open it in new window
;; Use (setq tgt-open-in-new-window 'nil) to override default behavior

;;;###autoload
(defcustom tgt-open-in-new-window t 
  "Indicates if the files are opened in new window or current window"
  :group 'toggle-test
  :type 'boolean)

(defun tgt-proj-prop (prop proj) (cdr (assoc prop proj)))
(defun tgt-root-dir (proj) (file-truename (car (tgt-proj-prop :root-dir proj))))

(defun tgt-relative-file-path (file proj dir-type) 
  (reduce 
   (lambda (cur_val dir) 
     (or cur_val 
	 (let ((src-dir (file-name-as-directory 
			 (expand-file-name dir (tgt-root-dir proj))))) 
	   (if (tgt-is-ancestor-p src-dir file)
	       (subseq file (length src-dir)))))) 
   (cdr (assoc dir-type proj))
   :initial-value 'nil))

;; Given a file return its project 
(defun tgt-proj-for (file)
  (tgt-best-project (remove-if-not
		(lambda (proj) (tgt-is-ancestor-p (tgt-root-dir proj) file)) tgt-projects)))

(defun tgt-best-project (projects)
  (if projects 
	  (reduce (lambda (res proj) 
				(if (> (tgt-root-depth proj) (tgt-root-depth res)) proj res)) projects)
	'nil))

(defun tgt-root-depth (proj)
  (length (split-string (file-name-as-directory (tgt-root-dir proj)) "/")))

(defun tgt-find-project-file-in-dirs (file proj)
  (assert (tgt-proj-prop :src-dirs proj) nil "Source directory not configured")
  (assert (tgt-proj-prop :test-dirs proj) nil "Test directory not configured")
  (let ((test-file-rel-path (tgt-relative-file-path file proj :test-dirs)))
    (if test-file-rel-path 
	(values 'nil test-file-rel-path)
      (values (tgt-relative-file-path file proj :src-dirs) 'nil))))


(defun tgt-find-match (file) 
  (let ((proj (tgt-proj-for file)))
      (cond (proj 
	   (multiple-value-bind 
	       (src-file-rel-path test-file-rel-path) 
	       (tgt-find-project-file-in-dirs file proj)
	     (cond
	      (test-file-rel-path (tgt-all-toggle-paths 
							   test-file-rel-path proj :src-dirs 
							   #'tgt-possible-src-file-names))
	      (src-file-rel-path (tgt-all-toggle-paths 
							  src-file-rel-path proj :test-dirs 
							  #'tgt-possible-test-file-names))
	      
	      (t (message "File '%s' in project '%s' is not part src-dirs or test-dirs"
			  file (tgt-root-dir proj)) 'nil))))
	  (t (message "File '%s' not part of any project. Have you defined a project?" file) 
		 'nil))))

(defun tgt-best-matches (all-matches)
  (let ((exact-matches (remove-if-not #'file-exists-p all-matches)))
	(if exact-matches (values t exact-matches) (values 'nil all-matches))))

(defun tgt-all-toggle-paths (rel-path proj dir-type file-names-generator)
  (tgt-make-full-paths 
   (tgt-possible-dirs proj dir-type (or (file-name-directory rel-path) "")) 
   (funcall file-names-generator 
			(file-name-nondirectory rel-path) 
			(tgt-proj-prop :test-prefixes proj) 
			(tgt-proj-prop :test-suffixes proj))))

(defun tgt-make-full-paths (dirs filenames)
  (tgt-cross-join dirs filenames (lambda (dir file) (expand-file-name file dir))))

;rel-dir-path is com/foo/bar for src in "proj-root/src/com/foo/bar/Blah.java
(defun tgt-possible-dirs (proj dir-type rel-dir-path)
  (let ((root (tgt-root-dir proj)))
	(mapcar (lambda (dir) (expand-file-name rel-dir-path (expand-file-name dir root))) 
			(tgt-proj-prop dir-type proj))))


(defun tgt-remove-file-prefix (prefix file) 
  (if (string-match (concat "^" prefix) file) (replace-match "" t t file) 'nil))

(defun tgt-remove-file-suffix (name suffix ext)
  (if (string-match (concat suffix "$") name) 
	  (concat (replace-match "" t t name) ext) 
	'nil))

(defun tgt-remove-file-preffix-suffix (prefix name suffix ext) 
  (tgt-remove-file-prefix prefix (or (tgt-remove-file-suffix name suffix ext) "")))

(defun tgt-possible-src-file-names (file prefixes suffixes)
  (tgt-possible-file-names file prefixes suffixes 
						   #'tgt-remove-file-prefix
						   #'tgt-remove-file-suffix
						   #'tgt-remove-file-preffix-suffix))

(defun tgt-possible-test-file-names (file prefixes suffixes)
  (tgt-possible-file-names file prefixes suffixes #'concat #'concat #'concat))

(defun tgt-santize-seq (seq)
  ;(append seq 'nil) converts vectors/sequences/list to list
  (delete-dups (remove 'nil (append seq 'nil))))

(defun tgt-possible-file-names (file prefixes suffixes 
									 pref-fn suff-fn
									 pref-suff-fn)
  (or (tgt-santize-seq 
	   (let ((name (file-name-sans-extension file))
			 (ext (file-name-extension file t))
			 (ret-val '()))
		 (setq ret-val (vconcat 
						(mapcar (lambda (prefix) (funcall pref-fn prefix file)) prefixes)
						(mapcar (lambda (suffix) (funcall suff-fn name suffix ext)) suffixes)))
	 
		 (if (and prefixes suffixes) 
			 (setq ret-val (vconcat (tgt-cross-join 
									 prefixes suffixes 
									 (lambda (prefix suffix) 
									   (funcall pref-suff-fn prefix name suffix ext))) 
									ret-val)))
	 
		 ret-val)) (list file)))

;join 2 lists - to make list of tuples by default. 
;fn argument can override how 2 elements join
(defun tgt-cross-join (list1 list2 &optional fn)
  (cond ((not list1) list2)
		((not list2) list1)
		(t (let ((ret-val '())) 
			 (dolist (i list1)
			  (dolist (j list2) 
				(add-to-list 'ret-val (if fn (funcall fn i j) (list i j)))))
			 ret-val))))

(defun tgt-open-file (file)
  (tgt-find-file file (if tgt-open-in-new-window #'find-file-other-window #'find-file)))

(defun tgt-find-file (file find-file-fn)
  (mkdir (file-name-directory file) t);Ensure parent directory exits
  (funcall find-file-fn file))


(defun tgt-show-matches (matches exact-match-p)
  (with-output-to-temp-buffer "*Toggle Test*"  
	(funcall (if tgt-open-in-new-window 
				 #'switch-to-buffer-other-window #'switch-to-buffer) "*Toggle Test*")
	(princ (if exact-match-p 
			   "Mutiple matching files were found. Choose one to open:\n"
			 "No matching file found. These are the potentials. Pick one to create:\n"))
	(dolist (file matches)
	  (princ "* ")
	  (insert-button file 'action (lambda (btn) 
									(tgt-find-file 
									 (button-label btn) #'find-alternate-file)))
	  (princ "\n"))))


(defun tgt-open (files)
  (if files
	  (multiple-value-bind (exact-match-p matches) (tgt-best-matches files)
		(cond
		 ((= 1 (length matches)) (tgt-open-file (car matches)))
		 (t (tgt-show-matches matches exact-match-p))))))

;;;###autoload
(defun tgt-toggle ()
  (interactive)
  (if buffer-file-truename  
; expand ~/ with 
	  (tgt-open (tgt-find-match (file-truename buffer-file-truename)))))

(defun tgt-is-ancestor-p (dir file)
  (if (and dir file (> (length file) 0) (> (length dir) 0))
   (let ((dir-name (file-name-as-directory (expand-file-name dir))) 
	 (file-name (expand-file-name file)))
	 (and (>= (length file-name) (length dir-name)) 
	      (string= (substring file-name 0 (length dir-name)) dir-name))) 'nil))

(provide 'toggle-test)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions)
;; End:

;;; toggle-test.el ends here
