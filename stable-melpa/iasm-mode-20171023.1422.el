;;; iasm-mode.el --- interactive assembly major mode.

;; Copyright (C) 2013 Rémi Attab

;; Author: Rémi Attab <remi.attab@gmail.com>
;; Created: 2013-09-29
;; Version: 0.1
;; Package-Version: 20171023.1422
;; Package-Commit: abbec7f308f9ce97beeb57e459fff35f559b4c18
;; Keywords:: tools
;; License: BSD-2-clause
;; Url: https://github.com/RAttab/iasm-mode

;; This file is not part of GNU Emacs.


;;; Commentary:

;; Inspired by Justine Tunney's disaster.el (http://github.com/jart/disaster‎).

;; iasm provides a simple interactive interface objdump and ldd which
;; facilitates assembly exploration. It also provides tools to speed up the
;; edit-compile-disasm loop.

;; This mode currently only supports Linux because it relies rather heavily on
;; objdump and ldd. It also hasn't been tested for other CPU architectures or
;; other unixes so expect some of the regexes to spaz out in colourful ways.

;; Note that this is my first foray into elisp so monstrosities abound. Go forth
;; at your own peril. If you wish to slay the beasts that lurk within or simply
;; add a few functionalities, contributions are more then welcome. See the todo
;; section for ideas.


;;; Installation:

;; Make sure to place `iasm-mode.el` somewhere in the load-path and add the
;; following lines to your `.emacs` to enable iasm:

;;     (require 'iasm-mode)

;;     (global-set-key (kbd "C-c C-d") 'iasm-disasm)
;;     (global-set-key (kbd "C-c C-l") 'iasm-ldd)

;;     (add-hook 'c-mode-common-hook
;;               (lambda ()
;;                (local-set-key (kbd "C-c d") 'iasm-goto-disasm-buffer)
;;                (local-set-key (kbd "C-c l") 'iasm-disasm-link-buffer)))


;;; Disasm:

;; iasm mode can be invoked using the `iasm-disasm' function which will prompt
;; for an object file to disassemble. While you can provide just about anything
;; that objdump supports, the mode currently only processes the .text section.
;; iasm-disasm will then open up a new buffer with the symbols for that object
;; file.

;; Additionally, when working on source files, `iasm-disasm-link-buffer` will
;; invoke `iasm-disasm` on the given object file and will link the current
;; buffer with the newly opened iasm buffer. This then allows you to invoke
;; `iasm-goto-disasm-buffer` to quickly jump back to the iasm buffer and refresh
;; it if the object file was modified. This is useful to quickly test the effect
;; of change.

;; By default, all symbols are hidden which is a good thing. This makes it
;; easier to search for a specific symbol and it allows iasm to lazily load the
;; symbols assembly which is important when dealing with large object files. To
;; toggle the visibility of a symbol simply move to the appriate like and hit
;; `TAB` which will prompt iasm to either retrieve the relevant assembly from
;; objdump or show/hide the symbol's assembly. `c` can be used to hide all the
;; sections and `M-n` `M-p` can be used to jump to the next/previous section.

;; When moving around instructions, `s` will open a the source file at the line
;; associated with that instruction. Alternatively, you can change line with `n`
;; and `p` which will automatically track the source file. `C-n` and `C-p` work
;; as usual. When on a jump instruction, `j` will jump to the target address if
;; available. Note that this may trigger a symbol to be loaded.

;; Finally, `g` can be used to refresh the buffer if the object file was
;; modified and `q` will close the buffer.


;;; LDD:

;; `iasm-ldd-mode' is simple front-end for ldd which dumps all the dynamic
;; libraries that a object file depends on. This can be used in conjunction with
;; `iasm-disasm' to quickly locate symbols that aren't in the current object
;; file.

;; To create a open ldd buffer, either invoke the `iasm-ldd` function or press
;; `l` in an iasm buffer. In the resulting buffer, you can then press `d` to
;; invoke `iasm-disasm' on a the given library. Hit `j` or `RET` to invoke
;; `iasm-ldd` on the target library.

;; Finally, `g` can be used to refresh the buffer if the object file was
;; modified and `q` will close the buffer.


;;; Todos:

;; - Shorten the edit-compile-disasm loop
;;   - Introduce compilation into the loop somehow.

;; - Static analyses
;;   - Highlight all uses of a register.
;;     - Could even go as far as trace the entire use graph.
;;   - basic-block detection (highlight and loop detection would be nice).
;;   - Show jump edges (basic-block highlighting should work).

;; - Improvements:
;;   - Write tests... Just kidding! Well not really, index could use some love.
;;   - Should probably scope all the disasm specific stuff to iasm-disasm. That
;;     change touches almost half the functions in this mode so it'll wait.


;;; Code:

(require 'cl)
(require 'avl-tree)


;; -----------------------------------------------------------------------------
;; customization
;; -----------------------------------------------------------------------------

(defgroup iasm nil
  "Interactive assembly mode"
  :prefix "iasm-"
  :group 'tools)

(defcustom iasm-disasm-cmd "objdump"
  "Executable used to retrieve the assembly of an object file"
  :group 'iasm
  :type 'string)

(defcustom iasm-disasm-syms-args "-tCwj .text"
  "Arguments fed to the executable to retrieve symbol information"
  :group 'iasm
  :type 'string)

(defcustom iasm-disasm-insts-args "-dlCw --no-show-raw-insn"
  "Arguments fed to the executable to retrieve assembly information"
  :group 'iasm
  :type 'string)


;; -----------------------------------------------------------------------------
;; process
;; -----------------------------------------------------------------------------
;; Generic utilities to launch a process and process its output line by line.

(defun iasm-process-parse-buffer (fn)
  "Splits `iasm-process-buffer` into lines and applies FN.

FN is only called for complete lines. A line is complete if it
terminates with an end of line character."
  (when iasm-process-buffer
    (save-match-data
      (let ((split (split-string iasm-process-buffer "\n")))
        (setq iasm-process-buffer (car (last split)))
        (dolist (line (butlast split))
          (funcall fn line))))))


(defun iasm-process-filter (proc string filter)
  "Pre-processes STRING from PROC and invokes FILTER.

Acts as a generic filter function for `start-process`. FILTER is
invoked once per complete line encountered ."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (setq iasm-process-buffer (concat iasm-process-buffer string))
      (save-excursion
        (let ((inhibit-read-only t))
          (iasm-process-parse-buffer filter))))))


(defun iasm-process-sentinel (proc state filter sentinel)
  "Pre-processes STATE for PROC and invokes FITLER and then SENTINEL.

Acts as a generic sentinel function for `start-process`. FILTER
is invoked for any remaining unprocessed data before calling
SENTINEL."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (save-excursion
        (let ((inhibit-read-only t))
          (when filter (funcall filter iasm-process-buffer ))
          (when sentinel (funcall sentinel))))))
  (setq iasm-loading nil)
  (iasm-buffer-do-queued-jump))


(defun iasm-process-run (exec args filter sentinel)
  "Runs EXEC with ARGS and invokes FILTER and SENTINEL.

Easy to use interface to `start-process`. FILTER is invoked once
for each line generated by the process and SENTINEL is invoked
when the process exits."
  (unless iasm-loading
    (setq iasm-loading t)
    (make-variable-buffer-local 'iasm-process-buffer)
    (setq iasm-process-buffer "")
    (let ((proc (apply 'start-process "iasm-process" (current-buffer) exec args)))
      (set-process-filter proc filter)
      (set-process-sentinel proc sentinel))))


;; -----------------------------------------------------------------------------
;; index
;; -----------------------------------------------------------------------------

(defun avl-tree-lower-bound (tree data)
  "Returns the greatest element that is smaller or equal to data.
Extension to the standard avl-tree library provided by iasm-mode."
  (let ((node (avl-tree--root tree))
        (compare-function (avl-tree--cmpfun tree))
        bound found)
    (while (and node (not found))
      (assert node)
      (let ((node-data (avl-tree--node-data node)))
        (assert node-data)
        (cond
         ((funcall compare-function data node-data)
          (setq node (avl-tree--node-left node)))
         ((funcall compare-function node-data data)
          (when (or (null bound) (funcall compare-function bound node-data))
            (setq bound node-data))
          (setq node (avl-tree--node-right node)))
         (t
          (setq found t)
          (setq bound node-data)))))
    bound))

(defun avl-tree-upper-bound (tree data)
  "Returns the greatest element that is smaller or equal to data.
Extension to the standard avl-tree library provided by iasm-mode."
  (let ((node (avl-tree--root tree))
        (compare-function (avl-tree--cmpfun tree))
        bound found)
    (while (and node (not found))
      (assert node)
      (let ((node-data (avl-tree--node-data node)))
        (assert node-data)
        (cond
         ((funcall compare-function data node-data)
          (when (or (null bound) (funcall compare-function node-data bound))
            (setq bound node-data))
          (setq node (avl-tree--node-left node)))
         ((funcall compare-function node-data data)
          (setq node (avl-tree--node-right node)))
         (t
          (setq found t)
          (setq bound node-data)))))
    bound))


(defstruct iasm-index syms ctxs)

(defun iasm-index-create ()
  "Creates a new index for the iasm-mode."
  (make-iasm-index
   :syms (avl-tree-create 'iasm-sym-less)
   :ctxs (avl-tree-create 'iasm-ctx-less)))

(defun iasm-index-shift (index min-pos delta)
  "Shifts the positions greater then MIN-POS in INDEX by DELTA.

Used when inserting new lines in the buffer to keep the positions
in the index up to date."
  (assert index)
  (avl-tree-map
   (lambda (sym)
     (assert sym)
     (when (< min-pos (iasm-sym-pos sym))
       (setf (iasm-sym-pos sym) (+ delta (iasm-sym-pos sym))))
     sym)
   (iasm-index-syms index)))

(defun iasm-index-empty (index)
  "Returns t if INDEX contains no simbols."
  (or (null index) (avl-tree-empty (iasm-index-syms index))))


;; -----------------------------------------------------------------------------
;; index - sym
;; -----------------------------------------------------------------------------
;; Indexes symbols by their address. All positions for the symbols are absolute
;; and must therefor be shifted when the inserting lines in the buffer.

(defstruct iasm-sym addr addr-size pos pos-size head-size insts name)
(defun iasm-sym-less (lhs rhs)
  (assert (iasm-sym-p lhs))
  (assert (iasm-sym-p rhs))
  (< (iasm-sym-addr lhs) (iasm-sym-addr rhs)))

(defun iasm-index-add-sym (index sym)
  "Add SYM of type `iasm-sym` to INDEX."
  (assert (and index (iasm-index-p index)))
  (setf (iasm-sym-insts sym) (avl-tree-create 'iasm-inst-less-addr))
  (avl-tree-enter (iasm-index-syms index) sym))

(defun iasm-index-find-sym (index addr)
  "Find the SYM in INDEX that contains ADDR."
  (assert (and index (iasm-index-p index)))
  (avl-tree-lower-bound (iasm-index-syms index) (make-iasm-sym :addr addr)))

(defun iasm-index-find-next-sym (index addr)
  "Find the SYM in INDEX that follows ADDR."
  (assert (and index (iasm-index-p index)))
  (avl-tree-upper-bound (iasm-index-syms index) (make-iasm-sym :addr addr)))

(defun iasm-index-test-sym (index addr)
  "Returns t if a symbol is located at ADDR in INDEX."
  (assert (and index (iasm-index-p index)))
  (avl-tree-member (iasm-index-syms index) (make-iasm-sym :addr addr)))

(defun iasm-index-sym-empty (index addr)
  "Returns t if the symbol at ADDR doesn't have instructions in INDEX."
  (assert (and index (iasm-index-p index)))
  (let ((sym (iasm-index-find-sym index addr)))
    (assert sym)
    (avl-tree-empty (iasm-sym-insts sym))))

(defun iasm-index-sym-map (index fn)
  "Invokes FN for every symbol in INDEX."
  (assert (and index (iasm-index-p index)))
  (avl-tree-map fn (iasm-index-syms index)))


;; -----------------------------------------------------------------------------
;; index - inst
;; -----------------------------------------------------------------------------
;; Indexes instruction for a symbol by addresse. All positions for instructions
;; are relative to the parents positions (only the symbol needs to be shifted).

(defstruct iasm-inst addr pos target file line fn)
(defun iasm-inst-less-addr (lhs rhs)
  (assert (iasm-inst-p lhs))
  (assert (iasm-inst-p rhs))
  (< (iasm-inst-addr lhs) (iasm-inst-addr rhs)))

(defun iasm-index-add-inst (index inst)
  "Add INST of type `iasm-inst` to INDEX."
  (assert (and index (iasm-index-p index)))
  (let ((sym (iasm-index-find-sym index (iasm-inst-addr inst))))
    (assert sym)
    ;; Relative positions means that we don't need to update it when we shift.
    (setf (iasm-inst-pos inst) (- (iasm-inst-pos inst) (iasm-sym-pos sym)))
    (avl-tree-enter (iasm-sym-insts sym) inst)))

(defun iasm-index-find-inst (index addr)
  "Find the instruction in INDEX at ADDR."
  (assert (and index (iasm-index-p index)))
  (let ((sym (iasm-index-find-sym index addr)))
    (assert sym)
    (let* ((inst-src (avl-tree-lower-bound (iasm-sym-insts sym)
                                           (make-iasm-inst :addr addr)))
           (inst (copy-iasm-inst inst-src)))
      ;; Convert relative positions into absolutes
      (setf (iasm-inst-pos inst) (+ (iasm-sym-pos sym)
                                    (iasm-inst-pos inst)))
      inst)))


;; -----------------------------------------------------------------------------
;; index - ctx
;; -----------------------------------------------------------------------------
;; Indexes to be used from source files to load up an associated instruction.
;; Unfortunately, this is pretty useless if we don't load up the entire buffer
;; first. It's currently being filled in but not used.

(defstruct iasm-ctx file-line addrs)
(defun iasm-ctx-less (lhs rhs)
  (let ((lhs-file (car (iasm-ctx-file-line lhs)))
        (lhs-line (cdr (iasm-ctx-file-line lhs)))
        (rhs-file (car (iasm-ctx-file-line lhs)))
        (rhs-line (cdr (iasm-ctx-file-line lhs))))
    (if (string< lhs-file rhs-file) t
      (if (not (string= lhs-file rhs-file)) nil
        (when (< lhs-line rhs-line) t)))))

(defun iasm-index-add-ctx (index file line addr)
  (assert (and index (iasm-index-p index)))
  (let* ((key (make-iasm-ctx :file-line `(,file . ,line)))
         (index-ctx (avl-tree-member (iasm-index-ctxs index) key)))
    (if index-ctx
        (avl-tree-enter (iasm-ctx-addrs index-ctx) addr)
      (progn
        (setf (iasm-ctx-addrs key) (avl-tree-create '<))
        (avl-tree-enter (iasm-ctx-addrs key) addr)
        (avl-tree-enter (iasm-index-ctxs index) key)))))


(defun iasm-find-ctx (index file line)
  (assert (and index (iasm-index-p index)))
  (avl-tree-lower-bound (iasm-index-ctxs index)
                        (make-iasm-ctx :file-line `(,file . ,line))))

(defun iasm-find-next-ctx (index file line)
  (assert (and index (iasm-index-p index)))
  (avl-tree-upper-bound (iasm-index-ctxs index)
                        (make-iasm-ctx :file-line `(,file . ,line))))


;; -----------------------------------------------------------------------------
;; syms
;; -----------------------------------------------------------------------------
;; Loads up the symbols from objdump and writes the buffer while filling in the
;; index. Note that we only write out the output in the sentinel so that we can
;; first sort the symbols. Sorting is pretty handy because it can group related
;; symbols.

(defun iasm-syms-init ()
  "Initializes the buffer for symbol insertion."
  (make-variable-buffer-local 'iasm-index)
  (setq iasm-index (iasm-index-create)))

(defconst iasm-syms-regex
  (concat
   "^\\([0-9a-f]+\\)" ;; address
   ".*\\.text\\s-+"   ;; .text anchors our regex
   "\\([0-9a-f]+\\)"  ;; size
   "\\s-+"
   "\\(.+\\)$"))      ;; name

(defun iasm-syms-filter (line)
  "Looks for symbols in LINE and adds it to the index."
  (end-of-buffer)
  (save-match-data
    (when (string-match iasm-syms-regex line)
      (let ((addr (string-to-number (match-string 1 line) 16))
            (size (string-to-number (match-string 2 line) 16))
            (name (match-string 3 line)))
        ;; objdump reports duplicate symbols which we have to dedup.
        (when (and (> size 0) (null (iasm-index-test-sym iasm-index addr)))
          (when (and iasm-queued-sym-jump (string= name iasm-queued-sym-jump))
            (setq iasm-queued-sym-jump nil)
            (setq iasm-queued-jump addr))
          (iasm-index-add-sym iasm-index (make-iasm-sym
                                          :name      name
                                          :addr      addr
                                          :addr-size size)))))))

(defun iasm-syms-insert (sym)
  "Inserts SYM and updates the positions and text-properties."
  (let ((pos-start (point)))
    (insert (format "%016x %08x <%s>: \n"
                    (iasm-sym-addr sym)
                    (iasm-sym-addr-size sym)
                    (iasm-sym-name sym)))
    (let* ((pos-stop (point))
           (size (- pos-stop pos-start)))
      (setf (iasm-sym-pos       sym) pos-start)
      (setf (iasm-sym-pos-size  sym) size)
      (setf (iasm-sym-head-size sym) size)
      (add-text-properties pos-start pos-stop '(iasm-sym t))
      (add-text-properties pos-start pos-stop
                           `(iasm-addr ,(iasm-sym-addr sym)))))
  sym)

(defun iasm-syms-sentinel ()
  "Inserts the indexed SYMs in the current buffer."
  (end-of-buffer)
  (if (iasm-index-empty iasm-index) (insert "No Symbols")
    (iasm-index-sym-map iasm-index 'iasm-syms-insert)))


(defun iasm-disasm-syms-args-cons (file)
  "Returns the arguments require to obtain the symbols of FILE."
  (append (split-string iasm-disasm-syms-args " ") `(,file)))

(defun iasm-syms-run (file)
  "Inserts FILE's symbols by executing objdump."
  (iasm-syms-init)
  (let ((args (iasm-disasm-syms-args-cons file)))
    (iasm-process-run
     iasm-disasm-cmd args
     (lambda (proc string)
       (iasm-process-filter proc string 'iasm-syms-filter))
     (lambda (proc state)
       (iasm-process-sentinel
        proc state 'iasm-syms-filter 'iasm-syms-sentinel)))))


;; -----------------------------------------------------------------------------
;; insts
;; -----------------------------------------------------------------------------
;; Loads up the instructions from objdump between two addresses and writes the
;; buffer while filling in the index. Note that we must also keep track of
;; contextual (source file and line) information associated with each
;; instructions.

(defun iasm-insts-init (addr-start addr-stop)
  "Initializes the buffer to insert the instructions between
ADDR-START and ADDR-STOP."
  (make-variable-buffer-local 'iasm-insts-sym)
  (setq iasm-insts-sym (iasm-index-find-sym iasm-index addr-start))

  (make-variable-buffer-local 'iasm-insts-ctx-file)
  (setq iasm-insts-ctx-file nil)

  (make-variable-buffer-local 'iasm-insts-ctx-line)
  (setq iasm-insts-ctx-line nil)

  (make-variable-buffer-local 'iasm-insts-ctx-fn)
  (setq iasm-insts-ctx-fn nil))


(defun iasm-insts-update-ctx (line)
  "Updates the currently active context source file and line from LINE.

Note that LINE must have previously been matched using `string-match`."
  (setq iasm-insts-ctx-file (match-string 1 line))
  (setq iasm-insts-ctx-line (string-to-number (match-string 2 line))))

(defun iasm-insts-update-ctx-fn (line)
  "Updates the currently active context function from LINE.

Note that LINE must have previously been matched using `string-match`."
  (setq iasm-current-ctx-fn (match-string 1 line)))

(defun iasm-insts-annotate-inst (start-pos stop-pos addr target)
  "Annotates START-POS and STOP-POS with ADDR and TARGET.

Updates the index and adds text properties to the instruction
line."
  (assert iasm-insts-sym)
  (iasm-index-add-inst iasm-index (make-iasm-inst
                                   :addr   addr
                                   :pos    start-pos
                                   :target target
                                   :file   iasm-insts-ctx-file
                                   :line   iasm-insts-ctx-line
                                   :fn     iasm-insts-ctx-fn))
  (when (and iasm-insts-ctx-file iasm-insts-ctx-line)
    (iasm-index-add-ctx iasm-index iasm-insts-ctx-file iasm-insts-ctx-line addr))
  (setf (iasm-sym-pos-size iasm-insts-sym)
        (+ (iasm-sym-pos-size iasm-insts-sym) (- stop-pos start-pos)))
  (add-text-properties start-pos stop-pos '(iasm-inst t))
  (add-text-properties start-pos stop-pos `(iasm-addr ,addr)))


(defconst iasm-insts-regex-inst   "^ *\\([0-9a-f]+\\):")
(defconst iasm-insts-regex-jump   "\\([0-9a-f]+\\) <.*>$")
(defconst iasm-insts-regex-ctx    "^\\(/.+\\):\\([0-9]+\\)")
(defconst iasm-insts-regex-ctx-fn "^\\(.+\\):$")


(defun iasm-insts-jump-target (line)
  "Detects a jump in LINE and returns the target address."
  (save-match-data
    (when (string-match iasm-insts-regex-jump line)
      (string-to-number (match-string 1 line) 16))))

(defun iasm-insts-insert-inst (line)
  "Inserts the instruction found in LINE into the buffer."
  (assert iasm-insts-sym)
  (let ((addr   (string-to-number (match-string 1 line) 16))
        (target (iasm-insts-jump-target line))
        (pos    (+ (iasm-sym-pos iasm-insts-sym)
                   (iasm-sym-pos-size iasm-insts-sym))))
    (goto-char pos)
    (insert line "\n")
    (iasm-insts-annotate-inst pos (point) addr target)))


(defun iasm-insts-filter (line)
  "Parses LINE and updates the buffer accordingly."
  (save-match-data
    (if (string-match iasm-insts-regex-inst line)
        (iasm-insts-insert-inst line)
      (if (string-match iasm-insts-regex-ctx line)
          (iasm-insts-update-ctx line)
        (if (string-match iasm-insts-regex-ctx-fn line)
            (iasm-insts-update-ctx-fn line))))))

(defun iasm-insts-sentinel ()
  "Shifts the symbols and cleans up buffer local variables."
  (assert iasm-insts-sym)
  (let ((pos (iasm-sym-pos iasm-insts-sym))
        (delta (- (iasm-sym-pos-size iasm-insts-sym)
                  (iasm-sym-head-size iasm-insts-sym))))
    (iasm-index-shift iasm-index (+ pos 1) delta))

  (makunbound 'iasm-insts-sym)
  (makunbound 'iasm-insts-ctx-file)
  (makunbound 'iasm-insts-ctx-line)
  (makunbound 'iasm-insts-ctx-fn))


(defun iasm-disasm-insts-args-cons (file start stop)
  "Returns the arguments require to obtain the instructs of FILE
between addresse START and STOP."
  (append
   (split-string iasm-disasm-insts-args " ")
   `(,(format "--start-address=0x%x" start))
   `(,(format "--stop-address=0x%x" stop))
   `(,file)))

(defun iasm-insts-run (file start stop)
  "Inserts FILE's instructions between address START and STOP by
executing objdump."
  (assert (< start stop))
  (iasm-insts-init start stop)
  (let ((args (iasm-disasm-insts-args-cons file start stop)))
    (iasm-process-run
     iasm-disasm-cmd args
     (lambda (proc string)
       (iasm-process-filter proc string 'iasm-insts-filter))
     (lambda (proc state)
       (iasm-process-sentinel
        proc state 'iasm-insts-filter 'iasm-insts-sentinel)))))


;; -----------------------------------------------------------------------------
;; buffer
;; -----------------------------------------------------------------------------
;; Handles all the buffer navigation, modification post-insertion and
;; information extraction. It's important that none of these functions (except
;; init) insert or remove characters into the buffer. Otherwise, it'll screw up
;; the index which contains positional information.

(defun iasm-buffer-name (file)
  "Returns the name of an iasm buffer for FILE."
  (concat "*iasm " (file-name-nondirectory file) "*"))


(defun iasm-buffer-init (file)
  "Initializes the iasm buffer for FILE.

Involves creating a bunch of buffer local variables and the
buffer headers."

  (setq default-directory (file-name-directory file))
  (make-variable-buffer-local 'iasm-file)
  (setq iasm-file file)

  (make-variable-buffer-local 'iasm-file-last-modified)
  (setq iasm-file-last-modified (nth 5 (file-attributes file)))

  (make-variable-buffer-local 'iasm-loading)
  (setq iasm-loading nil)

  (make-variable-buffer-local 'iasm-queued-jump)
  (setq iasm-queued-jump nil)

  (make-variable-buffer-local 'iasm-queued-sym-jump)
  (setq iasm-queued-sym-jump nil)

  (toggle-truncate-lines t)
  (setq buffer-read-only t)

  (erase-buffer)
  (insert (format "file:  %s\n" file))
  (insert (format
           "syms:  %s %s\n" iasm-disasm-cmd
           (mapconcat 'identity (iasm-disasm-syms-args-cons file) " ")))
  (insert (format
           "insts: %s %s\n" iasm-disasm-cmd
           (mapconcat 'identity (iasm-disasm-insts-args-cons file 0 0) " ")))
  (insert "\n"))


(defun iasm-buffer-inst-p (pos)
  "Returns t if POS is on an instruction line."
  (get-text-property pos 'iasm-inst))

(defun iasm-buffer-sym-p (pos)
  "Returns t if POS is on a symbol line."
  (get-text-property pos 'iasm-sym))

(defun iasm-buffer-addr (pos)
  "Returns the address associated with POS."
  (get-text-property pos 'iasm-addr))

(defun iasm-buffer-sym (pos)
  "Returns the symbol associated with POS."
  (when (iasm-buffer-addr pos)
    (iasm-index-find-sym iasm-index (iasm-buffer-addr pos))))

(defun iasm-buffer-inst (pos)
  "Returns the instruction associated with POS."
  (when (iasm-buffer-inst-p pos)
    (iasm-index-find-inst iasm-index (iasm-buffer-addr pos))))

(defun iasm-buffer-sym-loaded-p (pos)
  "Returns t if the symbol at POS is loaded."
  (not (iasm-index-sym-empty iasm-index (iasm-buffer-addr pos))))

(defun iasm-buffer-sym-pos (pos)
  "Returns the position of the previous symbol of POS.

Useful to go to the symbol associated with an instruction."
  (if (iasm-buffer-sym-p pos) pos
    (when (iasm-buffer-inst-p pos)
      (let ((sym (iasm-buffer-sym pos)))
        (iasm-sym-pos sym)))))

(defun iasm-buffer-inst-pos (pos)
  "Returns the position of the instruction of POS.

TODO:
Really convoluted way of doing `beginning-of-line`. Not sure why
this exists really."
  (if (iasm-buffer-inst-p pos) pos
    (when (and (iasm-buffer-sym-p pos) (iasm-buffer-sym-loaded-p pos))
      (let ((sym (iasm-buffer-sym pos)))
        (+ (iasm-sym-pos sym) (iasm-sym-head-size sym))))))

(defun iasm-buffer-invisibility-p (pos)
  "Returns t if POS is invisible.

TODO:
The current method seems a bit convoluted. Could just test on POS
instead of getting inst-pos."
  (let ((inst-pos (iasm-buffer-inst-pos pos)))
    (when inst-pos (get-text-property inst-pos 'invisible))))

(defun iasm-buffer-set-invisibility (pos value)
  "Sets the invisibility of the symbol at POS to VALUE.

Note that this will only affect the text property and will not
load the symbol."
  (let ((sym-pos (iasm-buffer-sym-pos pos)))
    (when sym-pos
      (let* ((sym (iasm-buffer-sym sym-pos))
             (start (+ (iasm-sym-pos sym) (iasm-sym-head-size sym)))
             (stop (+ (iasm-sym-pos sym) (iasm-sym-pos-size sym))))
        (set-text-properties start stop `(invisible ,value))))))

(defun iasm-buffer-collapse-sym (pos)
  "Hides the symbol at POS."
  (when (not (iasm-buffer-invisibility-p pos))
    (iasm-buffer-set-invisibility pos t)))

(defun iasm-buffer-sym-load (pos)
  "Loads the instructions of the symbol at POS.

If previously loaded, this will do nothing."
  (when (and (iasm-buffer-sym-p pos) (not (iasm-buffer-sym-loaded-p pos)))
    (let* ((sym (iasm-buffer-sym pos))
           (inst-pos (+ (iasm-sym-pos sym) (iasm-sym-head-size sym)))
           (addr-start (iasm-sym-addr sym))
           (addr-stop (+ addr-start (iasm-sym-addr-size sym))))
      (goto-char inst-pos)
      (iasm-insts-run iasm-file addr-start addr-stop))))

(defun iasm-buffer-jump-to-addr (addr)
  "Goes to the position associated with ADDR.

If necessary, the symbol will first be loaded and the jump will
de defered to after the load using the `iasm-queued-jump`
variable."
  (let ((sym (iasm-index-find-sym iasm-index addr)))
    (unless sym (error "Address is not part of a known symbol: %x" addr))
    (if (avl-tree-empty (iasm-sym-insts sym))
        (progn
          (setq iasm-queued-jump addr)
          (iasm-buffer-sym-load (iasm-sym-pos sym)))
      (let ((inst (iasm-index-find-inst iasm-index addr)))
        (goto-char (iasm-inst-pos inst))))))

(defun iasm-buffer-do-queued-jump ()
  "Executes the queued jump stored in `iasm-queued-jump`."
  (when (boundp 'iasm-queued-jump)
    (setq iasm-queued-sym-jump nil)
    (when iasm-queued-jump
      (iasm-buffer-jump-to-addr iasm-queued-jump)
      (setq iasm-queued-jump nil))))


(defun iasm-buffer-goto-sym (addr)
  "Jumps to the symbol at or before ADDR."
  (let ((sym (iasm-index-find-sym iasm-index addr)))
    (unless sym (error "Address doesn't belong to a known symbol: %x" addr))
    (goto-char (iasm-sym-pos sym))))

(defun iasm-buffer-goto-next-sym (addr)
  "Jumps to the the symbol after ADDR."
  (let ((sym (iasm-index-find-next-sym iasm-index addr)))
    (unless sym (error "Address doesn't belong to a known symbol: %x" addr))
    (goto-char (iasm-sym-pos sym))))


;; -----------------------------------------------------------------------------
;; iasm-mode
;; -----------------------------------------------------------------------------

(defvar iasm-disasm-sym-addr-face 'font-lock-function-name-face
  "Face for the address of symbols.")

(defvar iasm-disasm-sym-face 'font-lock-type-face
  "Face for symbols.")

(defvar iasm-disasm-inst-addr-face 'font-lock-builtin-face
  "Face for the address of instructions.")

(defvar iasm-disasm-inst-prefix-face 'font-lock-keyword-face
  "Face for instruction prefixes (eg. lock).")

(defvar iasm-disasm-inst-face 'font-lock-keyword-face
  "Face for instructions.")

(defvar iasm-disasm-reg-face 'font-lock-variable-name-face
  "Face for registers.")

(defvar iasm-disasm-annotations-face 'font-lock-comment-face
  "Face for annotations (hash mark comments).")

(defvar iasm-disasm-header-face 'font-lock-preprocessor-face
  "Face for iasm headers.")

(defvar iasm-disasm-error-face 'font-lock-warning-face
  "Face for objdump errors.")

(defconst iasm-disasm-regex-sym
  (concat
   "^\\([0-9a-f]\\{16\\}\\)" ;; address
   "\\s-+"
   "\\([0-9a-f]\\{8\\}\\)"  ;; size
   "\\s-+"
   "<\\(.*\\)>:"             ;; sym
   ))

(defconst iasm-disasm-regex-inst
  (concat
   "^\\s-*"
   "\\([0-9a-f]+\\):" ;; address
   "\\s-+"
   "\\(lock \\)?"     ;; inst prefix
   "\\([a-z0-9]+\\)"  ;; inst
   "\\>"
   ))

(defconst iasm-disasm-regex-jump
  (concat
   "<"
   "\\(.*\\)"      ;; sym
   ;; "\\(\\+\\(.*\\)\\)?" ;; offset
   ">$"
   ))

(defconst iasm-disasm-font-lock-keywords
  `((,iasm-disasm-regex-sym (1 iasm-disasm-sym-addr-face)
                            (2 iasm-disasm-sym-addr-face)
                            (3 iasm-disasm-sym-face))
    (,iasm-disasm-regex-inst (1 iasm-disasm-inst-addr-face)
                             (2 iasm-disasm-inst-prefix-face nil t)
                             (3 iasm-disasm-inst-face))
    (,iasm-disasm-regex-jump (1 iasm-disasm-sym-face))
    ("%\\sw+"      . iasm-disasm-reg-face)
    ("\\(# .*\\)$" . (1 iasm-disasm-annotations-face t))
    ("^[a-z]+:"    . iasm-disasm-header-face)
    ("^ERROR: .*$" . iasm-disasm-error-face)
    ("^No Symbols" . iasm-disasm-error-face)))


(define-derived-mode iasm-mode fundamental-mode
  "iasm"
  "Interactive disassembly mode.

Provides a simple interactive interface to objdump which
facilitates assembly exploration.

\\{iasm-mode-map}"
  :group 'iasm

  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(iasm-disasm-font-lock-keywords))

  (define-key iasm-mode-map (kbd "q")   'iasm-quit)
  (define-key iasm-mode-map (kbd "g")   'iasm-refresh)
  (define-key iasm-mode-map (kbd "TAB") 'iasm-toggle-sym-at-point)
  (define-key iasm-mode-map (kbd "s")   'iasm-show-ctx-at-point)
  (define-key iasm-mode-map (kbd "n")   'iasm-next-line)
  (define-key iasm-mode-map (kbd "p")   'iasm-previous-line)
  (define-key iasm-mode-map (kbd "M-n") 'iasm-next-sym)
  (define-key iasm-mode-map (kbd "M-p") 'iasm-previous-sym)
  (define-key iasm-mode-map (kbd "j")   'iasm-jump)
  (define-key iasm-mode-map (kbd "c")   'iasm-collapse-all-syms)
  (define-key iasm-mode-map (kbd "l")   'iasm-goto-ldd))


;; -----------------------------------------------------------------------------
;; interactive - in-buffer
;; -----------------------------------------------------------------------------
;; Navigation functions.

(defun iasm-toggle-sym-at-point ()
  "Hides or shows the instructions associated with a symbol at
point.

To keep the buffer responsive when dealing with large object
files, symbols are loaded on demand and only one symbol can be
loaded at a time. Also, a symbol only needs to be loaded once and
subsequent toggles will only affect text properties."
  (interactive)
  (unless (iasm-buffer-sym-p (point)) (error "No symbol to expand."))
  (when iasm-loading (error "Only one symbol can be loaded at once."))
  (save-excursion
    (let ((inhibit-read-only t))
      (if (not (iasm-buffer-sym-loaded-p (point)))
          (iasm-buffer-sym-load (point))
        (let ((value (not (iasm-buffer-invisibility-p (point)))))
          (iasm-buffer-set-invisibility (point) value))))))

(defun iasm-collapse-all-syms ()
  "Hides all visible the instructions."
  (interactive)
  (let ((inhibit-read-only t))
    (iasm-index-sym-map
     iasm-index
     (lambda (sym) (iasm-buffer-collapse-sym (iasm-sym-pos sym)) sym))))

(defun iasm-show-ctx-at-point ()
  "Opens a new buffer for the source file and associated with
point."
  (interactive)
  (unless (iasm-buffer-inst-p (point)) (error "No context information."))
  (let* ((iasm-buf (current-buffer))
         (inst (iasm-buffer-inst (point)))
         (file (iasm-inst-file inst))
         (line (iasm-inst-line inst)))
    (unless file (error "No context information."))
    (unless (file-exists-p file)
      (error "Context file doesn't exist: %s" file))
    (find-file-other-window file)
    (when line (goto-line line))
    (pop-to-buffer iasm-buf)
    (message "Showing: %s:%s" file line)))

(defun iasm-next-line ()
  "Moves down a line and calls `iasm-show-ctx-at-point`"
  (interactive)
  (next-line)
  (iasm-show-ctx-at-point))

(defun iasm-previous-line ()
  "Moves up a line and calls `iasm-show-ctx-at-point`"
  (interactive)
  (previous-line)
  (iasm-show-ctx-at-point))

(defun iasm-next-sym ()
  "Moves to the next symbol."
  (interactive)
  (let ((sym (iasm-buffer-sym (point))))
    (unless sym (error "No symbols to jump to."))
    (iasm-buffer-goto-next-sym (+ (iasm-sym-addr sym) 1))))

(defun iasm-previous-sym ()
  "Moves to the previous symbol."
  (interactive)
  (if (iasm-buffer-inst-p (point))
      (iasm-buffer-goto-sym (iasm-buffer-addr (point)))
    (let ((sym (iasm-buffer-sym (point))))
      (unless sym (error "No symbols to jump to."))
      (iasm-buffer-goto-sym (- (iasm-sym-addr sym) 1)))))

;; \todo Need error handling for no jump target.
(defun iasm-jump ()
  "Jumps to the target of the instruction at point."
  (interactive)
  (unless (iasm-buffer-inst-p (point)) (error "No target to jump to."))
  (let* ((inhibit-read-only t)
         (inst (iasm-buffer-inst (point)))
         (target (iasm-inst-target inst)))
    (unless target (error "No target to jump to."))
    (iasm-buffer-jump-to-addr target)))

(defun iasm-goto-ldd ()
  "Opens a new ldd buffer for the current object file."
  (interactive)
  (iasm-ldd iasm-file))

(defun iasm-quit ()
  "Kills the current buffer."
  (interactive)
  (kill-buffer (current-buffer)))

(defun iasm-refresh ()
  "Reloads the buffer with a fresh objdump output.

Will also expand the current buffer if it exists in the new dump."
  (interactive)
  (let ((inhibit-read-only t)
        (sym (iasm-buffer-sym (point))))
    (iasm-buffer-init iasm-file)
    (when sym (setq iasm-queued-sym-jump (iasm-sym-name sym)))
    (iasm-syms-run iasm-file)))

(defun iasm-refresh-if-stale ()
  "Calls `iasm-refresh` if the current object file was modified."
  (interactive)
  (assert iasm-file-last-modified)
  (when (< (time-to-seconds iasm-file-last-modified)
           (time-to-seconds (nth 5 (file-attributes iasm-file))))
    (iasm-refresh)))


;; -----------------------------------------------------------------------------
;; interactive - out-of-buffer
;; -----------------------------------------------------------------------------

;;;###autoload
(defun iasm-disasm (file)
  "Disassemble FILE into an iasm buffer."
  (interactive "fObject file: ")
  (let* ((abs-file (expand-file-name file))
         (name     (iasm-buffer-name (expand-file-name abs-file)))
         (buffer   (get-buffer name)))
    (unless (file-exists-p abs-file)
      (error "Object file doesn't exist: %s" abs-file))
    (if buffer (with-current-buffer buffer (iasm-refresh-if-stale))
      (setq buffer (get-buffer-create name))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (iasm-mode)
          (iasm-buffer-init abs-file)
          (iasm-syms-run abs-file))))
    (switch-to-buffer-other-window buffer)
    buffer))

;; \todo Error handling for buffer that doesn't exist.
(defun iasm-goto-disasm-buffer ()
  "Switch to the linked iasm buffer and refresh it if necessary.

A buffer can be linked to an iasm buffer using the
iasm-disasm-link-buffer function. The linked buffer is stored in
the buffer-local variable 'iasm-linked-buffer'."
  (interactive)
  (unless (and (boundp 'iasm-linked-buffer) (buffer-live-p iasm-linked-buffer))
    (error "No linked buffer."))
  (with-current-buffer iasm-linked-buffer (iasm-refresh-if-stale))
  (switch-to-buffer-other-window iasm-linked-buffer))

;;;###autoload
(defun iasm-disasm-link-buffer (file)
  "Disassemble FILE and links the current buffer to the iasm buffer."
  (interactive "fObject file: ")
  (let ((src-buffer (current-buffer))
        (iasm-buffer (iasm-disasm file)))
    (when iasm-buffer
      (with-current-buffer src-buffer
        (make-variable-buffer-local 'iasm-linked-buffer)
        (setq iasm-linked-buffer iasm-buffer)))))


;; -----------------------------------------------------------------------------
;; ldd
;; -----------------------------------------------------------------------------
;; ldd-mode related stuff starts here.

(defcustom iasm-ldd-cmd "ldd"
  "Executable used to retrieve linked library information."
  :group 'iasm
  :type 'string)

(defcustom iasm-ldd-args ""
  "Arguments passed to the ldd executable."
  :group 'iasm
  :type 'string)


;; -----------------------------------------------------------------------------
;; ldd - process
;; -----------------------------------------------------------------------------
;; Process the output of the ldd buffer and build the buffer accordingly.

(defun iasm-ldd-args-cons (file)
  "Returns the arguments require to obtain the dependencies of FILE."
  (append (split-string iasm-ldd-args " " t) `(,file)))

(defun iasm-ldd-proc-insert (lib path addr)
  "Inserts LIB, PATH and ADDR and annotates the buffer."
  (assert (or lib path))
  (assert (stringp addr))
  (when path (setq path (expand-file-name path)))
  (unless lib (setq lib (file-name-nondirectory path)))
  (assert lib)
  (let ((pos (point)))
    (insert (format "%s  %-32s %s \n" addr lib path))
    (set-text-properties pos (point) `(ldd-path ,path))))

(defconst iasm-ldd-proc-regex-full
  (concat
   "\\s-+\\(.*\\)"        ;; lib
   " => "                 ;; anchor
   "\\(.*\\)"             ;; path
   " (0x\\([0-9a-f]+\\))" ;; address
   ))

(defconst iasm-ldd-proc-regex-short
  (concat
   "\\s-+\\(.*\\)"        ;; path
   " (0x\\([0-9a-f]+\\))" ;; address
   ))

(defconst iasm-ldd-proc-regex-error
  (concat
   "^ldd: "    ;; anchor
   ".*: "      ;; file
   "\\(.*\\)$" ;; message
   ))

(defun iasm-ldd-proc-filter (line)
  "Parses LINE for dependencies and builds the buffer."
  (end-of-buffer)
  (save-match-data
    (if (string-match iasm-ldd-proc-regex-full line)
        (iasm-ldd-proc-insert
         (match-string 1 line)
         (match-string 2 line)
         (match-string 3 line))
      (if (string-match iasm-ldd-proc-regex-short line)
        (iasm-ldd-proc-insert
         nil
         (match-string 1 line)
         (match-string 2 line))
        (when (string-match iasm-ldd-proc-regex-error line)
          (insert "ERROR: " (match-string 1 line)))))))

(defun iasm-ldd-proc-run (file)
  "Runs ldd on FILE and builds the buffer with the output."
  (let ((args (iasm-ldd-args-cons file)))
    (iasm-process-run
     iasm-ldd-cmd args
     (lambda (proc string)
       (iasm-process-filter proc string 'iasm-ldd-proc-filter))
     (lambda (proc state)
       (iasm-process-sentinel proc state 'iasm-ldd-proc-filter nil)))))


;; -----------------------------------------------------------------------------
;; ldd - buffer
;; -----------------------------------------------------------------------------

(defun iasm-ldd-buffer-name (file)
  "Returns the name of the ldd buffer for FILE."
  (concat "*ldd " (file-name-nondirectory file) "*"))

(defun iasm-ldd-buffer-init (file)
  "Initializes the ldd buffer.

This mostly involves setting up some buffer local variables and
inserting the headers."

  (setq default-directory (file-name-directory file))
  (make-variable-buffer-local 'iasm-ldd-file)
  (setq iasm-ldd-file file)

  (make-variable-buffer-local 'iasm-ldd-file-last-modified)
  (setq iasm-ldd-file-last-modified (nth 5 (file-attributes file)))

  (make-variable-buffer-local 'iasm-loading)
  (setq iasm-loading nil)

  (toggle-truncate-lines t)
  (setq buffer-read-only t)

  (erase-buffer)
  (insert "file: " file "\n")

  (insert (format
           "cmd:  %s %s\n"
           iasm-ldd-cmd (mapconcat 'identity (iasm-ldd-args-cons file) " ")))
  (insert "\n"))

(defun iasm-ldd-buffer-path (pos)
  "Returns the library path associated with PATH."
  (get-text-property pos 'ldd-path))


;; -----------------------------------------------------------------------------
;; ldd - mode
;; -----------------------------------------------------------------------------

(defvar iasm-ldd-lib-addr-face 'font-lock-function-name-face
  "Face for library addresses.")

(defvar iasm-ldd-lib-face 'font-lock-variable-name-face
  "Face for library names.")

(defvar iasm-ldd-header-face 'font-lock-preprocessor-face
  "Face for ldd-mode headers.")

(defvar iasm-ldd-error-face 'font-lock-warning-face
  "Face for errors.")

(defconst iasm-ldd-regex-main
  (concat
   "^\\([0-9a-f]\\{16\\}\\)"           ;; address
   "\\s-+"
   "\\(\\(\\sw\\|\\s_\\|\\s.\\)+\\)")) ;; libname

;; There's nothing not highlighted with this enabled so it's probably better to
;; leave it as is. Too much of a good thing...
;;
;; (defconst iasm-ldd-regex-path
;; "\\(/\\(\\sw\\|\\s_\\|\\s.\\|/\\)+\\)")

(defconst iasm-ldd-font-lock-keywords
  `((,iasm-ldd-regex-main (1 iasm-ldd-lib-addr-face)
                          (2 iasm-ldd-lib-face))
    ("^\\([a-z]+:\\)"      1 iasm-ldd-header-face)
    ("^\\(ERROR: .*\\)$"   1 iasm-ldd-error-face)))

(define-derived-mode iasm-ldd-mode fundamental-mode
  "iasm-ldd"
  "Interactive ldd mode.

Provides an interactive frontend for ldd which can be used to
quickly navigate the dependencies of an object file.

\\{iasm-ldd-mode-map}"
  :group 'iasm

  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(iasm-ldd-font-lock-keywords))

  (define-key iasm-ldd-mode-map (kbd "q")   'iasm-ldd-quit)
  (define-key iasm-ldd-mode-map (kbd "g")   'iasm-ldd-refresh)
  (define-key iasm-ldd-mode-map (kbd "j")   'iasm-ldd-jump)
  (define-key iasm-ldd-mode-map (kbd "RET") 'iasm-ldd-jump)
  (define-key iasm-ldd-mode-map (kbd "d")   'iasm-ldd-disasm))


;; -----------------------------------------------------------------------------
;; ldd - interactive
;; -----------------------------------------------------------------------------
;; Buffer navigation functions.

(defun iasm-ldd-jump ()
  "Open a new buffer for the library at point."
  (interactive)
  (let ((path (iasm-ldd-buffer-path (point))))
    (unless path (error "No library to jump to."))
    (iasm-ldd path)))

(defun iasm-ldd-disasm ()
  "Invokes `iasm-disasm` on the library at point."
  (interactive)
  (let ((path (iasm-ldd-buffer-path (point))))
    (unless path (error "No library to jump to."))
    (iasm-disasm path)))

(defun iasm-ldd-quit ()
  "Kills the current buffer."
  (interactive)
  (kill-buffer (current-buffer)))

(defun iasm-ldd-refresh ()
  "Reloads the content of the ldd buffer."
  (interactive)
  (assert iasm-ldd-file)
  (let ((inhibit-read-only t))
    (iasm-ldd-buffer-init iasm-ldd-file)
    (iasm-ldd-proc-run iasm-ldd-file)))

(defun iasm-ldd-refresh-if-stale ()
  "Invokes iasm-ldd-refresh if the object file was modified."
  (interactive)
  (assert iasm-ldd-file-last-modified)
  (when (< (time-to-seconds iasm-ldd-file-last-modified)
           (time-to-seconds (nth 5 (file-attributes iasm-ldd-file))))
    (iasm-ldd-refresh)))

;;;###autoload
(defun iasm-ldd (file)
  "Creates a new interactive buffer containing the output of ldd
applied to FILE."
  (interactive "fObject file: ")
  (let* ((abs-file (expand-file-name file))
         (name     (iasm-ldd-buffer-name (expand-file-name abs-file)))
         (buffer   (get-buffer name)))
    (unless (file-exists-p abs-file)
      (error "Object file doesn't exist: %s" abs-file))
    (if buffer (with-current-buffer buffer (iasm-ldd-refresh-if-stale))
      (setq buffer (get-buffer-create name))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (iasm-ldd-mode)
          (iasm-ldd-buffer-init abs-file)
          (iasm-ldd-proc-run abs-file))))
    (switch-to-buffer-other-window buffer)))


;; -----------------------------------------------------------------------------
;; packaging
;; -----------------------------------------------------------------------------

(provide 'iasm-mode)

;;; iasm-mode.el ends here
