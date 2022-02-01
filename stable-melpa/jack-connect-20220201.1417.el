;;; jack-connect.el --- Manage jack connections within Emacs -*- lexical-binding: t -*-

;; Copyright (C) 2014-2019 Stefano Barbi
;; Author: Stefano Barbi <stefanobarbi@gmail.com>
;; Version: 0.2
;; Package-Version: 20220201.1417
;; Package-Commit: 1acaebfe8f37f0194e95c3e812c9515a6f688eee

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

;; `jack-connect' and `jack-disconnect' allow to manage connections of
;; jackd audio server from Emacs minibuffer.
;; `jack-snapshot-to-register' stores a snapshot of current
;; connections in a register that can be later restored using
;; `jump-to-register'.
;;; Code:
(require 'cl-lib)
(require 'dash)
(require 'seq)
(require 'radix-tree)

(defgroup jack-connect
  nil
  "Jack connect"
  :group 'minibuffer)

(defcustom jack-connect-group-ports
  t
  "When the variable is not nil, jack-connect and jack-disconnect
will try to group ports within the same client and with the same
features (i.e. midi or audio, input or output) and append a
wildcard character (*) to their common prefix."
  :type 'boolean)

(cl-defstruct jack-port
  "Jack port structure"
  ;; client name type connections properties

  (client nil)
  (name nil)
  (type nil)
  (connections (list))
  (properties  (list)))

(defun jack-port-input-p (port)
  "Return t if PORT is an input port."
  (and (memq 'input (jack-port-properties port)) t))

(defun jack-port-output-p (port)
  "Return t if PORT is an output port."
  (and (memq 'output (jack-port-properties port)) t))

(defun jack-port-audio-p (port)
  "Return t if PORT is an audio port."
  (and (string-match-p "audio" (jack-port-type port)) t))

(defun jack-port-midi-p (port)
  "Return t if PORT is a midi port."
  (and (string-match-p "midi" (jack-port-type port)) t))

(defun jack-port-connected-p (port)
  "Return t if PORT is connected."
  (and (jack-port-connections port) t))

(defun jack-port-full-name (port)
  (concat (jack-port-client port) ":" (jack-port-name port)))

(defun jack-running-p ()
  "Return t if jackd is started."
  (pcase (process-lines "jack_wait" "-c" "-s" "default")
    (`("running") t)
    (`("not running") nil)))

(defun jack-lsp ()
  "List jack ports parsing the output of jack_lsp."
  (if (not (jack-running-p))
      (error "Jack default server is not active")
    (let ((current-port nil)
          (ports nil))
      (dolist (line (process-lines "jack_lsp" "-ctp"))
        (cond
         ;; port properties
         ((string-match "^[ \t]+properties: \\(.*\\)" line)
          (setf (jack-port-properties current-port)
                (mapcar #'intern
                        (split-string (replace-match "\\1" nil nil line) "," t))))

         ;; port connection
         ((string-match "^ \\{3\\}\\(.*\\)" line)
          (push (replace-match "\\1" nil nil line)
                (jack-port-connections current-port)))

         ;; port type
         ((string-match "^[ \t]+\\(.*\\)" line)
          (setf (jack-port-type current-port)
                (replace-match "\\1" nil nil line)))

         ;; port name (sets current-port)
         (t
          (cl-destructuring-bind (client &rest port)
              (split-string line ":")
            (let* ((port-name (string-join port)))
              (setq current-port (make-jack-port :client client :name port-name))
              ;; (jack-port-name-set current-port port-name)
              ;; (jack-port-client-set current-port client)
              (push current-port ports))))))
      ;; transform into an alist
      (mapcar (lambda (port) (cons (jack-port-full-name port) port))
              ports))))

(defun jack--ports-can-be-grouped-p (ports)
  (pcase ports
    (`(,frst . ,siblings)
     (let ((frst-direction (jack-port-input-p frst))
           (frst-type      (jack-port-type    frst))
           (frst-client    (jack-port-client  frst)))
       (-all-p (lambda (sibling)
                 (and
                  (eq frst-direction   (jack-port-input-p sibling))
                  (string= frst-client (jack-port-client sibling))
                  (string= frst-type   (jack-port-type sibling))))
               siblings)))))


(defun jack--port-tree-flatten (tree)
  "Flatten a radix tree representation of jack ports into an alist
where the keys represent port specifications and the values list
of ports.

When the group of port descending from a prefix is eligible to
become a port specification, the (prefix + `*` . ports) pair is
included to the final alist."
  (let ((stack (list)))
    (letrec ((itr
              (lambda (tree &optional prefix)
                (pcase tree
                  (`(,suffix . ,(and (pred atom) port))
                   (push (cons (concat prefix suffix) (list port)) stack)
                   (list port))

                  (`(,suffix . ,ptree)
                   ;; collect descendant ports
                   (let ((children (-mapcat
                                    (lambda (tree) (funcall itr tree (concat prefix suffix)))
                                    ptree)))
                     (when (and (> (length children) 1)
                              (jack--ports-can-be-grouped-p children))
                       (push (cons (concat prefix suffix "*")
                                   (sort children
                                         (lambda (a b) (string< (jack-port-name a)
                                                           (jack-port-name b)))))
                             stack)
                       children)))))))
      (mapc itr tree))
    stack))

(defun jack--port-alist-prepare-with-pred (lsp &rest preds)
  "Construct an alist of ports matching PREDS"
  (--> (or lsp (jack-lsp))
       (if preds           
           (let* ((combined-pred (apply #'-andfn preds)))
             (-filter (lambda (p) (funcall combined-pred (cdr p))) it))
         it)
       (if jack-connect-group-ports
           (-> it
              (radix-tree-from-map)
              (jack--port-tree-flatten))
         (mapcar (lambda (x) (cons (car x) (list (cdr x)) )) it))))

(defun jack--port-alist-prepare (lsp)
  (jack--port-alist-prepare-with-pred lsp))

(defun jack--port-annotation-function (s collection)
  (let ((ports (cdr (assoc s collection))))
    (concat
     (string-join
      (list  (propertize " " 'display '(space :align-to (+ center -5)))

             (if (jack-port-input-p (car ports)) "input" "output")
             (if (jack-port-audio-p (car ports)) "audio" "midi")
             (when (> (length ports) 1)
               (propertize
                (concat "("(string-join (mapcar #'jack-port-name ports) ", ") ")")
                'face 'shadow
                ;; 'display '(space :align-to (+ center -5))
                )))
      "\t"))))

(defun jack--connect-complete (prompt collection)
  (let* ((completion-extra-properties
          `(:annotation-function
            ,(lambda (s) (jack--port-annotation-function s collection))

            :metadatum ((category . jack-port)))))
    (--> (completing-read prompt collection)
         (assoc it collection))))


;;;###autoload
(defun jack-connect (from to)
  "Connect jack output port(s) specified in FROM with port
selection specified in TO.

Port specifications may end with a wildcard character `*`,
representing a group of port of the same type belonging to the
same client. In such case, ports are sequentially connected with
the target ports. With the argument prefix (C-u), connect input
ports to output ports."
  (interactive
   (let* ((from (if current-prefix-arg 'input 'output))
          ;; ports-from
          (lsp          (jack-lsp))

          (p-from-table (or (jack--port-alist-prepare-with-pred
                            lsp
                            (cl-case from
                              (output #'jack-port-output-p)
                              (input  #'jack-port-input-p)))
                           (error (format "There are no %s ports registered" from))))
          ;; select ports from which connect
          (sel1          (jack--connect-complete "connect: " p-from-table))

          (from-type     (jack-port-type (car (cdr sel1))))

          ;; compute a table of eligible port to connect to

          (p-to-table    (or (jack--port-alist-prepare-with-pred
                             lsp
                             (cl-case from
                               (input  #'jack-port-output-p)
                               (output #'jack-port-input-p))
                             (lambda (port)
                               (string= from-type
                                        (jack-port-type port))))
                            (error "Cannot find any port to connect to %s." (car sel1))))
          (sel2           (jack--connect-complete
                           (format "connect %s to: " (car sel1))
                           p-to-table)))
     (list  (cdr sel1) (cdr sel2))))
  (when from
    (cl-mapc (lambda (p1 p2)
               (call-process "jack_connect" nil nil nil
                             (jack-port-full-name p1)
                             (jack-port-full-name p2)))
             from
             to)))

(defun jack--merge-connections (ports)
  "Return the union of the connections of PORTS."
  (cl-reduce #'cl-union
             (mapcar #'jack-port-connections ports)))

;;;###autoload
(defun jack-disconnect (from to)
  "Disconnect all the connections between jack ports specified in
FROM and ports specified in TO.

Port specification may include a wildcard character, representing
a group of ports belonging to the same client and of the same
type."
  (interactive
   (let* ((lsp (jack-lsp))
          (p-from-table  (or (jack--port-alist-prepare-with-pred
                             lsp
                              #'jack-port-connected-p)
                            (error (format "There are no jack connections"))))

          (sel1           (jack--connect-complete
                           "disconnect jack port(s): "
                           p-from-table))

          (p-to-table      (let* ((connections (jack--merge-connections (cdr sel1)))
                                  (pred-fun (lambda (port)
                                              (member (jack-port-full-name port)
                                                      connections))))

                             (jack--port-alist-prepare-with-pred lsp pred-fun)))

          (sel2            (jack--connect-complete
                            (format "disconnect %s from: " (car sel1))
                            p-to-table)))
     (list (cdr sel1) (cdr sel2))))
  (when from
    (dolist (p1 from)
      (dolist (p2 to)
        (when (member (jack-port-full-name p1) (jack-port-connections p2))
          (call-process "jack_disconnect" nil nil nil
                        (jack-port-full-name p1)
                        (jack-port-full-name p2)))))))



(defun jack--snapshot-restore (snapshot)
  "Restore all the connections in SNAPSHOT."
  (let ((ports (mapcar #'jack-port-full-name (jack-lsp))))
    (cl-loop
     for cell in snapshot
     for (k . v) = cell
     when (and (member k ports )
             (member v ports))
     do
     (call-process "jack_connect" nil nil nil k v))))

(defun jack--snapshot-princ (snapshot)
  "Display SNAPSHOT."
  (princ (format "jack-snapshot:\n%s" snapshot)))

(defun jack--snapshot ()
  "Return an alist with all the current connections in jack."
  (cl-loop
   for cell in (jack-lsp)
   for (k . p) = cell
   when (jack-port-output-p p)
   append
   (cl-loop
    for c in (jack-port-connections p)
    collect   (cons (jack-port-full-name p) c))))

;;;###autoload
(defun jack-snapshot-to-register (snapshot reg)
  "Store a SNAPSHOT of jack connections into register REG.
Restore connections using `jump-to-register'."
  (interactive
   (let ((snapshot (jack--snapshot)))
     (if snapshot
         (list snapshot
               (register-read-with-preview "Jack snapshot to register: "))
       (error "There are no connections"))))
  (set-register reg
                (registerv-make
                 snapshot
                 :print-func #'jack--snapshot-princ
                 :jump-func #'jack--snapshot-restore)))

(provide 'jack-connect)
;;; jack-connect.el ends here
