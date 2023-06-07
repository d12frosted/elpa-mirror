;;; repl-driven-development.el --- Send arbitrary code to a REPL in the background  -*- lexical-binding: t; -*-

;; Copyright (c) 2023 Musa Al-hassy

;; Author: Musa Al-hassy <alhassy@gmail.com>
;; Version: 1.0
;; Package-Version: 20230508.40
;; Package-Commit: 581fa6ac02d77a7a4293965049d801411402098e
;; Package-Requires: ((s "1.12.0") (dash "2.16.0") (eros "0.1.0") (bind-key "2.4.1") (emacs "27.1") (org "9.1"))
;; Keywords: repl-driven-development, rdd, repl, lisp, java, python, ruby, programming, convenience
;; Repo: https://github.com/alhassy/repl-driven-development
;; Homepage: https://alhassy.github.io/repl-driven-development/

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

;; This library provides the Emacs built-in “C­x C­e” behaviour for
;; arbitrary languages, provided they have a REPL.
;;
;;
;; Minimal Working Example [Java]:
;;
;;   ;; Set “C­x C­j” to evaluate Java code in a background REPL.
;;   (repl-driven-development [C­x C­j]
;;                            "jshell --enable-preview"
;;                            :prompt "jshell>")
;;
;;   // Selece this Java snippet, then press “C­x C­j” to evaluate it
;;   import javax.swing.*;
;;   var frame = new JFrame(){{ setAlwaysOnTop(true); }};
;;   JOptionPane.showMessageDialog(frame, "Super nice!");
;;
;;   // REPL result values are shown as overlays:
;;   2 + 4 // ⇒ 6
;;
;;
;; Benefits:
;;
;; Whenever reading/refactoring some code, if you can make some of it
;; self-contained, then you can immediately try it out! No need to
;; load your entrie program; nor copy-paste into an external REPL.  The
;; benefits of Emacs' built-in “C­x C­e” for Lisp, and Lisp's Repl
;; Driven Development philosophy, are essentially made possible for
;; arbitrary languages (to some approximate degree, but not fully).
;;
;;
;; This file has been tangled from a literate, org-mode, file.

;;; Code:

;; String and list manipulation libraries
;; https://github.com/magnars/dash.el
;; https://github.com/magnars/s.el

(require 's)               ;; “The long lost Emacs string manipulation library”
(require 'dash)            ;; “A modern list library for Emacs”
(require 'cl-lib)          ;; New Common Lisp library; ‘cl-???’ forms.
(require 'eros)            ;; Simple Emacs Overlays
(require 'org)
(require 'bind-key)

(defconst repl-driven-development-version (package-get-version))
(defun repl-driven-development-version ()
  "Print the current repl-driven-development version in the minibuffer."
  (interactive)
  (message repl-driven-development-version))

;;;###autoload
(cl-defun repl-driven-development (keys cli &key (prompt ">"))
  "Make Emacs itself a REPL for your given language of choice.

Suppose you're exploring a Python/Ruby/Java/JS/TS/Haskell/Lisps/etc
API, or experimenting with an idea and want immediate feedback.
You could open a terminal and try things out there; with no editor
support, and occasionally copy-pasting things back into your editor
for future use.  Better yet, why not use your editor itself as a REPL.

Implementation & behavioural notes can be found in the JavaScript
Example below.

######################################################################
### JavaScript Example ---Basic usage, and a minimal server ##########
######################################################################

   ;; C­x C­j now evaluates arbitrary JavaScript code
   (repl-driven-development [C­x C­j] \"node -i\")

That's it! Press “C­x C­e” on the above line so that “C­x C­j”
will now evaluate a selection, or the entire line, as if it were
Java code.  ⟦Why C­x C­j? C­x C­“e” for Emacs Lisp code, and C­x
C­“j” for JavaScript code!⟧ For instance, copy-paste the
following examples into a JS file ---or just press “C­x C­j” to
evaluate them!

    1 + 2                                     // ⮕ 3
    1 + '2'                                   // ⮕ '12'
    let me = {name: 'Jasim'}; Object.keys(me) // ⮕ ['name']
    me.doesNotExist('whoops')                 // ⮕ Uncaught TypeError

All of these results are echoed inline in an overlay, by default.
Moreover, there is a *REPL* buffer created for your REPL so you
can see everything you've sent to it, and the output it sent
back.  This is particularly useful for lengthy error messages,
such as those of Java, which cannot be rendered nicely within an
overlay.

How this works is that Emacs spawns a new “node -i” process, then
C­x C­j sends text to that process.  Whenever the process emits
any output ---on stdout or stderr--- then we emit that to the
user via an overlay starting with “⮕”.

Finally, “C­h k  C­x C­j” will show you the name of the function
that is invoked when you press C­x C­j, along with minimal docs.

A useful example would be a minimal server, and requests for it.

   // First get stuff with C­x C­e:
   // (async-shell-command \"npm install -g express axios\")

   let app = require('express')()
   let clicked = 1
   app.get('/hi', (req, res) => res.send(`Hello World × ${clicked++}`))

   let server = app.listen(3000)
   // Now visit   http://localhost:3000/hi   a bunch of times!

  // Better yet, see the output programmatically...
  let axios = require('axios')
  // Press C­x C­j a bunch of times on the following expression ♥‿♥
  console.log((await axios.get('http://localhost:3000/hi')).data)

  // Consider closing the server when you're done with it.
  server.close()

Just as “Emacs is a Lisp Machine”, one can use “VSCodeJS” to use
“VSCode as a JS Machine”.
See http://alhassy.com/vscode-is-itself-a-javascript-repl.

######################################################################
### Description of Arguments #########################################
######################################################################

- KEYS: A vector such as [C­x C­p] that declares the keybindings for
  the new REPL evaluator.

- CLI: A string denoting the terminal command to start your repl;
  you may need an “-i” flag to force it to be interactive even though
  we use it from a child process rather than a top-level shell.

- PROMPT: What is the prompt that your REPL shows, e.g., “>”.
  We try to ignore showing it in an overlay that would otherwise hide
  useful output.

### Misc Remarks #####################################################
VSCode has a similar utility for making in-editor REPLs, by the
same author: http://alhassy.com/making-vscode-itself-a-java-repl"
  (-let* (((cmd . args) (s-split " " cli))
          ;; Identifier "repl-driven-development" is made unique
          ;; by start-process.
          (repl (apply #'start-process "repl-driven-development"
                       (format "*REPL/%s*" cli) cmd args))
          (repl-fun-name (intern (concat "repl/" cli))))

    ;; https://stackoverflow.com/q/4120054
    (set-process-coding-system repl 'utf-8-dos)

    (eval `(defun ,repl-fun-name (beg end)
             ,(concat "Executes the selected region, if any or "
                     "otherwise the entire current line,\n"
                     "and evaluates it with the repl: "
                     cli
                     "\n\n"
                     "Output is shown as an overlay at the current "
                     "cursor position. It is shown for 3 seconds.\n\n"
                     "See `repl-driven-development' for more "
                     "useful docs.")
                  (interactive "r")
                      (unless (use-region-p)
                        (beginning-of-line)
                        (set-mark-command nil)
                        (end-of-line)
                        (setq beg (region-beginning)
                              end (region-end))
                        (pop-mark))
                      (process-send-region ,repl beg end)
                      (process-send-string ,repl "\n")))

    (bind-key* (s-join " " (mapcar #'pp-to-string keys))
              repl-fun-name)

    (require 'eros)

    (set-process-filter repl
      `(lambda (process output)
         ;; If the output is just the prompt, write "\n", else write
         ;; the actual output to the REPL buffer and emit overlay.
         (if (or (s-starts-with? " " output)
                 (s-starts-with? ,prompt
                     (s-trim (s-collapse-whitespace output))))
             (repl-driven-development-ordinary-insertion-filter
                process "\n")
           (repl-driven-development-ordinary-insertion-filter
                process output)
           (thread-last output
                        (s-replace "\r" "")
                        (s-replace " " "")
                        (s-replace (concat "\n" ,prompt) "")
                        (s-trim)
                        (setq output))

           ;; I'd like “C­h e” to show things as well.
           (let ((inhibit-message t))
             (message "REPL⇒ %s" (s-collapse-whitespace output)))

           ;; Show output as an overlay at the current cursor position
           (eros--make-result-overlay (s-collapse-whitespace output)
             :format  "⮕ %s"
             :duration 3 ;; output shown for 3 seconds
             ))))

    ;; Return the REPL to the user.
    repl))

(defun repl-driven-development-ordinary-insertion-filter (proc string)
  "Insert STRING into the buffer for process PROC.

Copied from
www.gnu.org/software/emacs/manual/html_node/elisp/Filter-Functions"
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let ((moving (= (point) (process-mark proc))))
        (save-excursion
          (goto-char (process-mark proc))
          (insert string)
          (set-marker (process-mark proc) (point)))
        (if moving (goto-char (process-mark proc)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'repl-driven-development)

;;; repl-driven-development.el ends here
