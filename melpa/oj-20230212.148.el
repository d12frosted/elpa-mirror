;;; oj.el --- Competitive programming tools client for AtCoder, Codeforces  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.7
;; Package-Version: 20230212.148
;; Package-Commit: 6d586cb108c642bc166c64df113e03193f4d1495
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (quickrun "2.2"))
;; URL: https://github.com/conao3/oj.el

;; This program is free software: you can redistribute it and/or modify
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

;; Competitive programming tools client for AtCoder, Codeforces.


;;; Code:

(require 'quickrun)
(require 'format-spec)
(require 'subr-x)
(require 'seq)

(defgroup oj nil
  "Competitive programming tools client."
  :prefix "oj-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/oj.el"))

(defcustom oj-shell-program shell-file-name
  "Shell program to use `oj'."
  :group 'oj
  :type 'string)

(defcustom oj-home-dir (locate-user-emacs-file "oj")
  "Directory path for `oj'."
  :group 'oj
  :type 'directory)

(defcustom oj-compiler-c "gcc"
  "Compiler name to submit for C/C++."
  :group 'oj
  :type '(choice
          (const :tag "gcc/g++" "gcc")
          (const :tag "clang/clang++" "clang")))

(defcustom oj-compiler-python "cpython"
  "Compiler name to submit for Python."
  :group 'oj
  :type '(choice
          (const :tag "cpython" "cpython")
          (const :tag "pypy" "pypy")))

(defcustom oj-login-args nil
  "Args for `oj-login'.

usage: oj login [-h] [-u USERNAME] [-p PASSWORD]
[--check] [--use-browser {always,auto,never}] url

positional arguments:
  url

optional arguments:
  -h, --help            show this help message and exit
  -u USERNAME, --username USERNAME
  -p PASSWORD, --password PASSWORD
  --check               check whether you are logged in or not
  --use-browser {always,auto,never}
                        specify whether it uses a GUI web browser
                        to login or not  (default: auto)"
  :group 'oj
  :type '(repeat string))

(defcustom oj-prepare-args nil
  "Args for `oj-prepare'.

usage: oj-prepare [-h] [-v] [-c COOKIE] [--config-file CONFIG_FILE] url

positional arguments:
  url

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose
  -c COOKIE, --cookie COOKIE
  --config-file CONFIG_FILE
             default: ~/.config/online-judge-tools/prepare.config.toml"
  :group 'oj
  :type '(repeat string))

(defcustom oj-test-args '()
  "Args for `oj-test'.

Note that the runtime command (`-c') is detected automatically.

usage: oj test [-h] [-c COMMAND] [-f FORMAT] [-d DIRECTORY] [-m
               {simple,side-by-side}] [-S] [--no-rstrip]
               [--rstrip] [-s] [-e ERROR] [-t TLE] [--mle MLE]
               [-i] [-j N] [--print-memory] [--gnu-time GNU_TIME]
               [--no-ignore-backup] [--ignore-backup] [--json]
               [--judge-command JUDGE] [test [test ...]]

positional arguments:
  test                  paths of test cases. (if empty: globbed from --format)

optional arguments:
  -h, --help            show this help message and exit
  -c COMMAND, --command COMMAND
                        your solution to be tested.  (default: \"./a.out\")
  -f FORMAT, --format FORMAT
                        a format string to recognize the relationship of
                        test cases.  (default: \"%s.%e\")
  -d DIRECTORY, --directory DIRECTORY
                        a directory name for test cases (default: test/)
  -m {simple,side-by-side}, --display-mode {simple,side-by-side}
                        mode to display an output with the correct answer
                        (default: simple)
  -S, --side-by-side    display an output and the correct answer with
                        side byside mode
                        (equivalent to --display-mode side-by-side)
  --no-rstrip
  --rstrip              rstrip output before compare (default)
  -s, --silent          don't report output and correct answer even if not AC
                        (for --mode all)
  -e ERROR, --error ERROR
                        check as floating point number: correct if its absolute
                        or relative error doesn't exceed it
  -t TLE, --tle TLE     set the time limit (in second) (default: inf)
  --mle MLE             set the memory limit (in megabyte) (default: inf)
  -i, --print-input     print input cases if not AC
  -j N, --jobs N        specifies the number of jobs to run simultaneously
                        (default: no parallelization)
  --print-memory        print the amount of memory which your program used,
                        even if it is small enough
  --gnu-time GNU_TIME   used to measure memory consumption (default: \"time\")
  --no-ignore-backup
  --ignore-backup       ignore backup files and hidden files
                        (i.e. files like \"*~\", \"\\#*\\#\" and \".*\")
                        (default)
  --json
  --judge-command JUDGE
                        specify judge command instead of default diff judge.
                        See https://online-judge-tools.readthedocs.io/en/
                              master/introduction.en.html
                              #test-for-special-forms-of-problem for details

format string for --format:
  %s                    name
  %e                    extension: \"in\" or \"out\"
  (both %s and %e are required.)

tips:
  You can do similar things with shell: e.g.
 `for f in test/*.in ; do echo $f ; diff <(./a.out < $f) ${f/.in/.out} ; done`"
  :group 'oj
  :type '(repeat string))

(defcustom oj-submit-args '("-y")
  "Args for `oj-submit'.

Note: --guess-cxx-compiler and --guess-python-interpreter is guessed
from `oj-compiler-c' or `oj-compiler-python' or `quickrun' default.

usage: oj submit [-h] [-l LANGUAGE] [--no-guess] [-g]
                 [--no-guess-latest] [--guess-cxx-latest]
                 [--guess-cxx-compiler {gcc,clang,all}]
                 [--guess-python-version {2,3,auto,all}]
                 [--guess-python-interpreter {cpython,pypy,all}]
                 [--format-dos2unix] [--format-rstrip] [-G]
                 [--no-open] [--open] [-w SECOND] [-y] [url] file

positional arguments:
  url                   the URL of the problem to submit.
                        if not given, guessed from history of download command.
  file

optional arguments:
  -h, --help            show this help message and exit
  -l LANGUAGE, --language LANGUAGE
                        narrow down language choices if ambiguous
  --no-guess
  -g, --guess           guess the language for your file (default)
  --no-guess-latest
  --guess-cxx-latest    use the lasest version for C++ (default)
  --guess-cxx-compiler {gcc,clang,all}
                        use the specified C++ compiler if both of GCC and
                        Clang are available (default: gcc)
  --guess-python-version {2,3,auto,all}
                        default: auto
  --guess-python-interpreter {cpython,pypy,all}
                        use the specified Python interpreter if both of CPython
                        and PyPy are available (default: cpython)
  --format-dos2unix     replace CRLF with LF for given file
  --format-rstrip       remove trailing newlines from given file
  -G, --golf            now equivalent to --format-dos2unix --format-rstrip
  --no-open
  --open                open the result page after submission (default)
  -w SECOND, --wait SECOND
                        sleep before submitting
  -y, --yes             don't confirm"
  :group 'oj
  :type '(repeat string))

(defcustom oj-default-online-judge 'codeforces
  "Default online judge service."
  :group 'oj
  :type
  '(choice (const :tag "Aizu Online Judge"      'aoj)
           (const :tag "Anarchy Golf"           'anrchy-golf)
           (const :tag "AtCoder"                'atcoder)
           (const :tag "Codeforces"             'codeforces)
           (const :tag "CS Academy"             'cs-academy)
           (const :tag "Facebook Hacker Cup"    'facebook-hacker-cup)
           (const :tag "HackerRank"             'hackerrank)
           (const :tag "Kattis"                 'kattis)
           (const :tag "PKU JudgeOnline"        'pku)
           (const :tag "Topcoder"               'topcoder)
           (const :tag "Toph (Problem Archive)" 'toph)
           (const :tag "CodeChef"               'codechef)
           (const :tag "Sphere online judge"    'soj)
           (const :tag "yukicoder"              'yukicoder)
           (const :tag "Library Checker"        'library-checker)))

(defvar oj-online-judges
  '((aoj                . ((name . "Aizu Online Judge")        (url . "https://onlinejudge.u-aizu.ac.jp/")))
    (aoj2               . ((name . "Aizu Online Judge (Beta)") (url . "https://onlinejudge.u-aizu.ac.jp/courses/")))
    (anrchy-golf        . ((name . "Anarchy Golf")             (url . "http://golf.shinh.org/p.rb?")))
    (atcoder            . ((name . "AtCoder")                  (url . "https://atcoder.jp/contests/")))
    (codeforces         . ((name . "Codeforces")               (url . "https://codeforces.com/contest/")))
    (cs-academy         . ((name . "CS Academy")               (url . "https://csacademy.com/contest/")))
    (facebook           . ((name . "Facebook Hacker Cup")      (url . "https://www.facebook.com/hackercup/")))
    (hackerrank         . ((name . "HackerRank")               (url . "https://www.hackerrank.com/challenges/")))
    (hackerrank-contest . ((name . "HackerRank Contest")       (url . "https://www.hackerrank.com/contests/")))
    (kattis             . ((name . "Kattis")                   (url . "https://open.kattis.com/problems/")))
    (poj                . ((name . "PKU JudgeOnline")          (url . "http://poj.org/problem?id=")))
    (topcoder           . ((name . "Topcoder")                 (url . "https://www.topcoder.com/challenges/")))
    (toph               . ((name . "Toph (Problem Archive)")   (url . "https://toph.co/p/")))
    (codechef           . ((name . "CodeChef")                 (url . "https://www.codechef.com/problems/")))
    (soj                . ((name . "Sphere online judge")      (url . "https://www.spoj.com/problems/")))
    (yukicoder          . ((name . "yukicoder")                (url . "https://yukicoder.me/problems/no/")))
    (yukicoder-contest  . ((name . "yukicoder Contest")        (url . "https://yukicoder.me/contests/")))
    (library-checker    . ((name . "Library Checker")          (url . "https://judge.yosupo.jp/problem/"))))
  "Supported online judges.

- Download sample cases
  (aoj-arena aoj anrchy-golf atcoder codeforces
   cs-academy facebook hackerrank kattis poj toph
   codechef soj yukicoder library-checker)

- Download system cases
  (aoj yukicoder)

- Submit solution source code
  (atcoder codeforces topcoder hackerrank toph)

NOTE: online-judge symbol MUST NOT include slash (\"/\").")


;;; Functions

(defvar comint-process-echoes)
(declare-function comint-send-input "comint")
(declare-function comint-delete-input "comint")
(declare-function comint-send-string "comint")
(declare-function make-comint-in-buffer "comint")

(defvar oj-buffer nil)

(defun oj--exec-script (script)
  "Exec SCRIPT in `oj-buffer'."
  (oj-open-shell)
  (with-current-buffer oj-buffer
    (goto-char (point-max))
    (comint-delete-input)
    (comint-send-string oj-buffer script)
    (with-current-buffer oj-buffer
      (comint-send-input))))

(defun oj--join-scripts (&rest scripts)
  "Join all SCRIPTS with \" && \"."
   (string-join scripts " && "))

(defun oj--file-readable (file)
  "Return FILE if readable."
  (when (file-readable-p file) file))

(defun oj--online-judges ()
  "Return supported online-judge symbols."
  (mapcar #'car oj-online-judges))

(defun oj--first-value (fn lst)
  "Apply FN for LST and return first non-nil value."
  (when-let (val (cl-member-if fn lst))
    (funcall fn (car val))))

(defun oj--url-to-online-judge (url)
  "Detect online-judge service from URL."
  (oj--first-value
   (lambda (elm)
     (let ((sym (car elm))
           (alist (cdr elm)))
       (when (string-match (alist-get 'url alist) url)
         sym)))
   oj-online-judges))

(defun oj--url-to-dirs (url)
  "Detect suitable dirs from URL."
  (or
   ;; http://judge.u-aizu.ac.jp/onlinejudge/description.jsp?id=ITP1_8_C
   ;; http://judge.u-aizu.ac.jp/onlinejudge/description.jsp
   (and (string-match
         "http://judge.u-aizu.ac.jp/onlinejudge/description.jsp\\?id=\\([^/]+\\)" url)
        `("aizu" ,(match-string 1 url)))
   (and (string-match
         "http://judge.u-aizu.ac.jp/onlinejudge/description.jsp" url)
        `("aizu" "1000"))

   ;; https://onlinejudge.u-aizu.ac.jp/courses/lesson/2/ITP1/1/ITP1_1_A
   (and (string-match
         "https://onlinejudge.u-aizu.ac.jp/courses/[^/]*/[^/]*/[^/]*/[^/]*/\\([^/]+\\)/?" url)
        `("aizu" ,(match-string 1 url)))

   ;; http://golf.shinh.org/p.rb?hello+world
   (and (string-match
         "http://golf.shinh.org/p.rb\\?\\([^/]+\\)" url)
        `("anrchy-golf" ,(replace-regexp-in-string "\\+" "_" (match-string 1 url))))

   ;; https://atcoder.jp/contests/abc167/tasks/abc167_a
   ;; https://atcoder.jp/contests/abc167
   (and (string-match
         "https://atcoder.jp/contests/\\([^/]+\\)/tasks/\\([^/]+\\)/?" url)
        `("atcoder" ,(match-string 1 url) ,(match-string 2 url)))
   (and (string-match
         "https://atcoder.jp/contests/\\([^/]+\\)/?" url)
        `("atcoder" ,(match-string 1 url)))

   ;; https://codeforces.com/contest/1349/problem/A
   (and (string-match
         "https://codeforces.com/contest/\\([^/]+\\)/problem/\\([^/]+\\)/?" url)
        `("codeforces" ,(format "%s_%s" (match-string 1 url) (match-string 2 url))))
   (and (string-match
         "https://codeforces.com/contest/\\([^/]+\\)/?" url)
        `("codeforces" ,(match-string 1 url)))

   ;; https://csacademy.com/contest/interview-archive/task/3-divisible-pairs/
   ;; https://csacademy.com/contest/archive/task/gcd/
   (and (string-match
         "https://csacademy.com/contest/[^/]+/task/\\([^/]+\\)/?" url)
        `("cs-academy" ,(match-string 1 url)))

   ;; https://www.hackerrank.com/challenges/c-tutorial-basic-data-types
   ;; https://www.hackerrank.com/challenges/c-tutorial-basic-data-types/problem
   ;; https://www.hackerrank.com/contests/projecteuler/challenges/euler254/problem
   (and (string-match
         "https://www.hackerrank.com/challenges/\\([^/]+\\)/?\\(problem\\)?" url)
        `("hackerrank" ,(match-string 1 url)))
   (and (string-match
         "https://www.hackerrank.com/contests/\\([^/]+\\)/challenges/\\([^/]+\\)/?\\(problem\\)?" url)
        `("hackerrank" ,(format "%s_%s" (match-string 1 url) (match-string 2 url))))
   (and (string-match
         "https://www.hackerrank.com/contests/\\([^/]+\\)/?" url)
        `("hackerrank" ,(match-string 1 url)))

   ;; https://open.kattis.com/problems/hello
   (and (string-match
         "https://open.kattis.com/problems/\\([^/]+\\)/?" url)
        `("kattis" ,(match-string 1 url)))

   ;; http://poj.org/problem?id=1000
   (and (string-match
         "http://poj.org/problem\\?id=\\([^/]+\\)" url)
        `("poj" ,(match-string 1 url)))

   ;; https://www.topcoder.com/challenges/30125517
   (and (string-match
         "https://www.topcoder.com/challenges/\\([^/]+\\)/?" url)
        `("topcoder" ,(match-string 1 url)))

   ;; https://toph.co/p/count-the-chaos
   (and (string-match
         "https://toph.co/p/\\([^/]+\\)/?" url)
        `("toph" ,(match-string 1 url)))

   ;; https://www.codechef.com/problems/TREEMX
   (and (string-match
         "https://www.codechef.com/problems/\\([^/]+\\)/?" url)
        `("codechef" ,(match-string 1 url)))

   ;; https://www.spoj.com/problems/TEST/
   ;; https://www.spoj.com/problems/PRIME1/
   (and (string-match
         "https://www.spoj.com/problems/\\([^/]+\\)/?" url)
        `("soj" ,(match-string 1 url)))

   ;; https://yukicoder.me/contests/262
   ;; https://yukicoder.me/problems/no/1046
   (and (string-match
         "https://yukicoder.me/contests/\\([^/]+\\)/?" url)
        `("yukicoder" ,(match-string 1 url)))
   (and (string-match
         "https://yukicoder.me/problems/no/\\([^/]+\\)/?" url)
        `("yukicoder" ,(match-string 1 url)))

   ;; https://judge.yosupo.jp/problem/aplusb
   (and (string-match
         "https://judge.yosupo.jp/problem/\\([^/]+\\)/?" url)
        `("library-checker" ,(match-string 1 url)))

   `("test")))

(defun oj--shortname-to-url (shortname &optional judge)
  "Convert SHORTNAME to URL for JUDGE.

  (oj--shortname-to-url \"abc167\" 'atcoder)
  ;;=> https://atcoder.jp/contests/abc167

  (oj--shortname-to-url \"abc167/a\" 'atcoder)
  ;;=> https://atcoder.jp/contests/abc167/tasks/abc167_a"
  (let ((judge* (or judge oj-default-online-judge))
        (args (split-string shortname "/")))
    (cl-case (length args)
      (1
       (concat (alist-get 'url (alist-get judge* oj-online-judges)) shortname))
      (2
       (cl-case judge*
         (atcoder
          (format "https://atcoder.jp/contests/%s/tasks/%s"
                  (nth 0 args)
                  (format "%s_%s" (nth 0 args) (nth 1 args))))
         (codeforces
          (format "https://codeforces.com/contest/%s/problem/%s"
                  (nth 0 args) (nth 1 args)))
         (hackerrank
          (format "https://www.hackerrank.com/contests/%s/challenges/%s"
                  (nth 0 args) (nth 1 args)))
         (otherwise
          (error "Slash input (%s) for %s is not supported" shortname judge*)))))))

(defun oj--parent-dir (path)
  "Return the parent directory to PATH."
  (let ((dir (directory-file-name (expand-file-name path default-directory))))
    (directory-file-name
     (file-name-directory dir))))


;;; Main

;;;###autoload
(defun oj-install-packages ()
  "Install `oj', `oj-template', `selenium' pip package via `pip3'."
  (interactive)
  (unless (yes-or-no-p "Install `oj', `oj-template', `selenium' via pip3?")
    (error "Abort install"))
  (dolist (elm '(("oj" . "online-judge-tools")
                 ("oj-template" . "online-judge-template-generator")
                 ("selenium" . "selenium")))
    (unless (executable-find (car elm))
      (unless (executable-find "python3")
        (error "Missing `python3'.  Please ensure Emacs's PATH and the installing"))
      (unless (executable-find "pip3")
        (error "Missing `pip3'.  Please ensure Emacs's PATH and the installing"))
      (oj--exec-script (format "pip3 install %s" (cdr elm))))))

;;;###autoload
(defun oj-open-shell ()
  "Open shell to controll `oj'."
  (interactive)
  (setq oj-buffer (get-buffer-create (format "*oj - %s*" oj-shell-program)))
  (unless (process-live-p (get-buffer-process oj-buffer))
    (with-current-buffer oj-buffer
      (setq comint-process-echoes t))
    (make-comint-in-buffer "oj" oj-buffer shell-file-name))
  (display-buffer oj-buffer))

;;;###autoload
(defun oj-open-home-dir (&optional contest)
  "Open `oj-home-dir'/CONTEST."
  (interactive)
  (let ((dir (expand-file-name (or contest "") oj-home-dir)))
    (unless (file-directory-p dir)
      (make-directory dir))
    (dired dir)))

;;;###autoload
(defun oj-login (name)
  "Login online-judge system.

NAME is string of (mapcar #'car oj-online-judges).
NAME is also whole URL to login."
  (interactive (list (completing-read "Login for: " (mapcar #'car oj-online-judges))))
  (let ((url (if (string-match "/" name)
                 name
               (alist-get 'url (alist-get (intern name) oj-online-judges)))))
    (oj--exec-script
     (concat
      (format "oj login %s" url)
      (when oj-login-args
        (format " %s" (mapconcat #'identity oj-login-args " ")))))))

;;;###autoload
(defun oj-prepare (name)
  "Prepare new NAME working folder."
  (interactive
   (list (read-string
          (format "Contest name (shortcode like `1349' or `1349/A' for %s, or URL): " oj-default-online-judge))))
  (let* ((url (if (string-prefix-p "http" name) name (oj--shortname-to-url name)))
         (dirs (oj--url-to-dirs url))
         (contestdir (mapconcat #'identity dirs "/"))
         (path (expand-file-name contestdir oj-home-dir)))
    (oj--exec-script
     (format "mkdir -p %s && cd %s" path path))
    (oj--exec-script
     (concat
      (format "oj-prepare %s" url)
      (when oj-prepare-args
        (format " %s" (mapconcat #'identity oj-prepare-args " ")))))
    (oj-open-home-dir contestdir)))

;;;###autoload
(defun oj-test ()
  "Run test."
  (interactive)
  (oj--exec-script (format "cd %s" default-directory))
  (let* ((alist (quickrun--command-info
                 (quickrun--command-key (buffer-file-name))))
         (spec (mapcar (lambda (elm)
                         `(,(string-to-char (substring (car elm) 1)) . ,(cdr elm)))
                       (quickrun--template-argument alist (buffer-file-name))))
         (exec (or (alist-get :exec alist)
                   (alist-get :exec quickrun--default-tmpl-alist))))
    (oj--exec-script
     (apply
      #'oj--join-scripts
      (append
       (when (consp exec)
         (mapcar
          (lambda (arg)
            (format-spec arg spec))
          (nreverse (cdr (reverse exec)))))
       (list
        (concat
         "oj test"
         (when oj-test-args
           (format " %s" (mapconcat #'identity oj-test-args " ")))
         " -c '" (format-spec (if (consp exec) (car (last exec)) exec) spec) "'")))))))

;;;###autoload
(defun oj-submit ()
  "Submit code."
  (interactive)
  (let ((alist (quickrun--command-info
                (quickrun--command-key (buffer-file-name)))))
    (oj--exec-script (format "cd %s" default-directory))
    (oj--exec-script
     (concat
      (format "oj submit %s" (buffer-file-name))
      (when oj-submit-args
        (format " %s" (mapconcat #'identity oj-submit-args " ")))
      (when (or (string= "clang" oj-compiler-c)
                (string-match "clang" (alist-get :command alist)))
        " --guess-cxx-compiler clang")
      (when (or (string= "pypy" oj-compiler-python)
                (string-match "pypy" (alist-get :command alist)))
        " --guess-python-interpreter pypy")))))

;;;###autoload
(defun oj-next ()
  "Open source code for next task."
  (interactive)
  (let* ((currentfile (file-name-nondirectory (buffer-file-name)))
         (currenttask (file-name-nondirectory (oj--parent-dir (buffer-file-name))))
         (contestdir (oj--parent-dir (oj--parent-dir (buffer-file-name)))))
    (when-let (nextdir (let ((default-directory contestdir))
                         (thread-last (file-expand-wildcards "*")
                           (cl-remove-if-not #'file-directory-p)
                           (seq-sort #'string<)
                           (member currenttask)
                           (cadr))))
      (when-let (file (thread-last nextdir
                        (funcall (lambda (elm) (expand-file-name elm contestdir)))
                        (funcall (lambda (elm) (expand-file-name currentfile elm)))))
        (when (file-readable-p file)
          (find-file file))))))

;;;###autoload
(defun oj-prev ()
  "Open source code for prev task."
  (interactive)
  (let* ((currentfile (file-name-nondirectory (buffer-file-name)))
         (currenttask (file-name-nondirectory (oj--parent-dir (buffer-file-name))))
         (contestdir (oj--parent-dir (oj--parent-dir (buffer-file-name)))))
    (when-let (prevdir (let ((default-directory contestdir))
                         (thread-last (file-expand-wildcards "*")
                           (cl-remove-if-not #'file-directory-p)
                           (funcall (lambda (elm) (sort elm #'string<)))
                           (funcall (lambda (elm)
                                      (let ((pos (cl-position currenttask elm :test #'string=)))
                                        (when (<= 1 pos)
                                          (nth (- pos 1) elm))))))))
      (when-let (file (thread-last prevdir
                        (funcall (lambda (elm) (expand-file-name elm contestdir)))
                        (funcall (lambda (elm) (expand-file-name currentfile elm)))))
        (when (file-readable-p file)
          (find-file file))))))

(provide 'oj)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; oj.el ends here
