;;; pynt.el --- Generate and scroll EIN buffers from python code -*- lexical-binding: t -*-

;; Copyright (C) 2018 Free Software Foundation, Inc.

;; Author: Edward Banner <edward.banner@gmail.com>
;; Version: 1.0
;; Package-Version: 20180710.726
;; Package-Commit: 86cf9ce78d34f92bfd0764c9cbb75427ebd429e6
;; Package-Requires: ((emacs "24.4") (ein "0.13.1") (epc "0.1.1") (deferred "0.5.1"))
;; Keywords: convenience
;; URL: https://github.com/ebanner/pynt

;;; Commentary:

;; pynt is an Emacs minor mode for generating and interacting with EIN notebooks.
;;
;; Feature List
;; ------------
;; - On-the-fly notebook creation
;;   - Run the command `pynt-mode' on a python buffer and a new notebook will be created for you to interact with (provided you have set the variable `pynt-start-jupyter-server-on-startup' to t)
;; - Dump a region of python code into a EIN notebook
;;   - Selectable regions include functions, methods, and code at the module level (i.e. outside of any function or class)
;; - Scroll the resulting EIN notebook with the code buffer
;;   - Alignment between code and cells are preserved even when cells are added and deleted

;;; Code:

(require 'seq)
(require 'epc)
(require 'epcs)
(require 'ein-jupyter)

(defgroup pynt nil
  "Customization group for pynt."
  :group 'applications)

(defcustom pynt-epc-server-hostname "localhost"
  "The hostname of the EPC server.

Usually set to \"localhost\" but if the jupyter kernel is running
inside a docker container then this value should be
\"docker.for.mac.localhost\" when on a mac.

Using the value of a remote machine should be possible but is
currently untested."
  :options '("localhost" "docker.for.mac.localhost"))

(defcustom pynt-scroll t
  "Scroll the notebook buffer with the code buffer. "
  :options '(nil t))

(defcustom pynt-kernelspec "python3" "Kernelspec to create a notebook with.")

(defcustom pynt-epc-port 9999
  "The port that the EPC server listens on.

Every invocation of pynt mode increments this number so that pynt
mode can run in multiple buffers.")

(defcustom pynt-start-jupyter-server-on-startup t
  "Start a jupyter server on startup if t and do not otherwise.

The jupyter server listens on the port defined by the variable
`ein:url-or-port'.")

(defcustom pynt-verbose nil
  "Log pynt debug information if t and do not otherwise.")

(defvar pynt-init-code-template
  "

%%matplotlib inline

import time
import IPython
import epc.client

epc_client = epc.client.EPCClient(('%s', %s), log_traceback=True)
def __cell__(content, buffer_name, cell_type, line_number):
    epc_client.call_sync('make-cell', args=[content, buffer_name, cell_type, line_number])
    time.sleep(0.01)

%s # additional code
"
  "Python code template which is evaluated early on.

The value of `pynt-epc-server-hostname' and
`pynt-epc-port' are used to complete this template.

Having '__cell__()' and 'epc_client' defined in the associated
IPython kernel allow the running python code to send code
snippets to the EPC server.")

(defvar pynt-epc-server nil
  "Emacs server.

There only ever needs to be one EPC server, even across multiple
pynt mode instances.")

(defvar pynt-ast-server nil "Python AST server")

(defvar-local pynt-code-buffer-file-name nil "The name of the file being visited.")

(defvar-local pynt-namespace nil "The name current namespace.")

(defvar-local pynt-line-to-cell-map nil
  "Map of source code lines to EIN cell(s).

A source code line may be associated with more than one EIN
cell (e.g. a line in the body of a for loop.")

(defvar-local pynt-namespace-to-notebook-map nil
  "Map of namespaces to notebooks.

Each namespace has its own indepenedent notebook.")

(defvar-local pynt-notebook-files nil
  "List of EIN notebook files.

Keep track of this so we delete all the notebooks when
terminating pynt mode.")

(defvar-local pynt-namespace-to-kernel-pid-map nil
  "Map of namespaces to kernel PIDs.

Every time one sets up the state of a notebook by jacking in a
subprocess is started which starts the kernel. These add up after
a while and it is in our interest to kill those processes when
their associated kernels can no longer be interacted with.")

(defvar-local pynt-namespace-to-region-map nil
  "Map of namespace names to start and end lines.

This map is used to produce a visual indication of which
namespace corresponds to which code. It was originally part of a
feature that was purely intended for making video demos prettier
but does serve as a way to intuitively select a region of code.

This map is used after a user changes the active namespace via
the command `pynt-choose-namespace'.")

(defun pynt-log (&rest args)
  "Log the message when the variable `pynt-verbose' is t.

Optional argument ARGS the arguments you would normally pass to the function `message'."
  (when pynt-verbose
    (apply 'message args)))

(defun pynt-toggle-debug ()
  "Toggle pynt development mode.

In pynt development mode we set the print-* variables to values
so that when we try and print EIN deeply nested and recursive
data structures they print and do not lock up emacs."
  (interactive)
  (setq pynt-verbose (not pynt-verbose)
        print-level (if print-level nil 1)
        print-length (if print-length nil 1)
        print-circle (not print-circle))
  (if ein:debug
      (ein:dev-stop-debug)
    (ein:dev-start-debug)))

(defun pynt-toggle-scroll ()
  "Toggle notebook scrolling.

Flips the value of the variable `pynt-scroll'."
  (interactive)
  (setq pynt-scroll (not pynt-scroll)))

(defun pynt-notebook (&optional namespace)
  "Get the current notebook."
  (gethash (or namespace pynt-namespace) pynt-namespace-to-notebook-map))

(defun pynt-notebook-buffer (&optional namespace)
  "Get the buffer of the notebook."
  (ein:notebook-buffer (pynt-notebook (or namespace pynt-namespace))))

(defun pynt-notebook-window (&optional namespace)
  "Get the notebook window."
  (get-buffer-window (ein:notebook-buffer (pynt-notebook (or namespace pynt-namespace)))))

(defun pynt-notebook-kernel (&optional namespace)
  (ein:$notebook-kernel (pynt-notebook (or namespace pynt-namespace))))

(defun pynt-module-name ()
  "Extract the module-level name of the pynt code buffer.

If the buffer is associated with a python file then chop off the
'.py' suffix. Otherwise (e.g. if this is a *scratch* buffer) then
just return the buffer name.

Throw an error if the buffer name has a period in it because that
will mess with the namespace naming convention that pynt uses."
  (let* ((script-name (file-name-nondirectory pynt-code-buffer-file-name)))
    (file-name-sans-extension script-name)))

(defun pynt-recover-notebook-window (&optional detach)
  "Recover the notebook window.

Use the function `python-info-current-defun' primarily. Handle
the case where we are outside any defun."
  (interactive "p")
  (let* ((defun-at-point (python-info-current-defun))
         (namespace-at-point (if defun-at-point
                                 (concat (pynt-module-name) "." defun-at-point)
                               (pynt-module-name))))
    (pynt-switch-or-init namespace-at-point detach)))

(defun pynt-dump-namespace ()
  "Dump the code in `pynt-active-namespace' into its EIN worksheet buffer.

This is done by sending the code region out to the AST server
where it is annotated with EPC calls and then the resulting code
is sent to the IPython kernel to be executed."
  (interactive)
  (with-current-buffer pynt-code-buffer
    (pynt-offload-to-scratch-worksheet))
  (let ((code (buffer-substring-no-properties (point-min) (point-max))))
    (deferred:$
      (epc:call-deferred pynt-ast-server 'annotate `(,code ,pynt-namespace ,t))
      (deferred:nextc it
        (lambda (cells)
          (with-current-buffer pynt-code-buffer
            (dolist (cell cells)
              (apply 'pynt-make-cell cell))))))))

(defun pynt-goto-next-cell-line ()
  "Move the point to the next line with a cell.

Helps you get to where you want to get quicker."
  (interactive)
  (setq line-number (1+ (line-number-at-pos))
        max-line-number (seq-max (map-keys pynt-line-to-cell-map)))
  (while (and (< line-number max-line-number) (not (gethash line-number pynt-line-to-cell-map)))
    (setq line-number (1+ line-number)))
  (when (gethash line-number pynt-line-to-cell-map)
      (goto-line line-number)))

(defun pynt-goto-prev-cell-line ()
  "Move the point to the next line with a cell.

Helps you get to where you want to get quicker."
  (interactive)
  (setq line-number (1- (line-number-at-pos))
        min-line-number (seq-min (map-keys pynt-line-to-cell-map)))
  (while (and (> line-number min-line-number) (not (gethash line-number pynt-line-to-cell-map)))
    (setq line-number (1- line-number)))
  (when (gethash line-number pynt-line-to-cell-map)
    (goto-line line-number)))

(defun pynt-trace-namespace ()
  "Dump the code in `pynt-active-namespace' into its notebook.

FIXME this is experimental and not currently used."
  (interactive)
  (pynt-offload-to-scratch-worksheet)
  (let ((code (buffer-substring-no-properties (point-min) (point-max))))
    (deferred:$
      (epc:call-deferred pynt-ast-server 'annotate `(,code ,pynt-namespace))
      (deferred:nextc it
        (lambda (annotated-code)
          (ein:connect-eval-buffer)
          (pynt-log "Annotated code = %s" annotated-code)
          (ein:shared-output-eval-string annotated-code))))))

(defun pynt-unpack (only-first)
  "Unpack an experession.

Applies to the cell corresponding to the line at point. Pass the
universal prefix argument to set TAKE-FIRST to t if you just want
the first branch of the expression. Only try exps are currently
supported."
  (interactive "P")
  (let* ((code (buffer-substring-no-properties (point-min) (point-max)))
         (only-first (if only-first 1 0)))
    (deferred:$
      (message "Making deferred call!")
      (epc:call-deferred pynt-ast-server 'unpack `(,code ,pynt-namespace ,(line-number-at-pos) ,only-first))
      (deferred:nextc it
        (lambda (cells)
          (with-current-buffer (pynt-notebook-buffer)
            (call-interactively 'ein:worksheet-kill-cell)
            (if (not (pynt-last-cell-p))
                (call-interactively 'ein:worksheet-goto-prev-input)))
          (dolist (cell cells)
            (apply 'pynt-make-cell (add-to-list 'cell :at-point :append))))))))

(defun pynt-last-cell-p ()
  "Return t if you are at the last cell in a notebook.

Expects to be called in a notebook buffer."
  (let ((start (point)))
    (condition-case nil
        (save-excursion
          (call-interactively 'ein:worksheet-goto-next-input))
      (error nil t))))

(defun pynt-scroll-cell-window ()
  "Scroll the EIN worksheet buffer with the code buffer.

Do it so the cell which corresponds to the line of code the point
is on goes to the top.  Make sure the cell we're about to jump to
is is indeed the active buffer.

Wrap the main logic in a condition case because it could be the
case that the cell that did correspond to a line has since been
deleted. Basically there is a bunch of data invalidation that I
don't want to worry about at this time."
  (interactive)
  (when pynt-scroll
    (save-selected-window
      (let ((entry (gethash (line-number-at-pos) pynt-line-to-cell-map)))
        (when entry
          (condition-case exception
              (multiple-value-bind (namespace cell) entry
                (if (string= namespace pynt-namespace)
                    (let* ((cell-marker (ein:cell-location cell :input))
                           (point-line (count-screen-lines (window-start) (point))))
                      (when cell-marker
                        (select-window (pynt-notebook-window))
                        (widen)
                        (goto-char cell-marker)
                        (recenter point-line)))
                  (pynt-switch-to-namespace namespace)))
            ('error)))))))

(defun pynt-pop-up-notebook-buffer (buffer)
  "Pop up the notebook window.

Always try and display the notebook to the right of the code
buffer. This makes it so we can have multiple code buffers on top
of each other and their notebooks to the right."
  (condition-case nil
      (save-selected-window
        (windmove-right)
        (switch-to-buffer buffer))
    (error nil (with-selected-window (split-window-horizontally)
                 (switch-to-buffer buffer)))))

(defun pynt-rename-notebook ()
  "Rename the notebook to the current namespace.

TODO I've tried to get this working twice and it leads to weird
errors each time. It would be very nice to get working eventually!"
  (interactive)
  (let* ((relative-path (replace-regexp-in-string (expand-file-name "~/") "" pynt-code-buffer-file-name))
         (relative-dir (file-name-directory relative-path))
         (notebook-path (concat relative-dir pynt-namespace ".ipynb")))
    (condition-case nil
        (delete-file (file-name-nondirectory notebook-path))
      (error nil))
    (with-current-buffer (pynt-notebook-buffer)
      (message "Attempting rename to %s..." notebook-path)
      (let* ((old-notebook-path (ein:$notebook-notebook-path ein:%notebook%))
             (old-notebook-name (file-name-nondirectory old-notebook-path)))
        (ein:notebook-rename-command notebook-path)
        (delete-file old-notebook-name)))))

(defun pynt-setup-notebook (&rest -ignore-)
  "Default callback for `ein:notebook-open'.

Create a notebook for the module-level namespace. In the future
maybe do this for all the namespaces in the beginning!"
  ;; Possibly pop up the notebook.
  (when pynt-pop-up-notebook
    (pynt-pop-up-notebook-buffer (current-buffer)))
  (setq pynt-pop-up-notebook nil)

  (setq notebook ein:%notebook%)
  (with-current-buffer pynt-code-buffer
    (pynt-log "Putting %s into hash..." pynt-namespace)
    (puthash pynt-namespace notebook pynt-namespace-to-notebook-map)
    (add-to-list 'pynt-notebook-files (ein:notebook-name notebook))

    (with-current-buffer (pynt-notebook-buffer)
      (ein:notebook-worksheet-insert-next ein:%notebook% ein:%worksheet% :render nil))

    (pynt-dump-namespace)

    (pynt-connect-to-notebook-buffer (pynt-notebook-buffer))))

(defun pynt-new-notebook (&optional pop-up-notebook)
  "Create a new EIN notebook and bring it up side-by-side.

Make sure the new notebook is created in the same directory as
the python file so that relative imports in the code work fine.

Set the pynt code buffer name because this function will jump the
point to another window. In general buffer names are not to be
relied on remember!"
  (interactive)
  (multiple-value-bind (url-or-port token) (ein:jupyter-server-conn-info)
    (let* ((nb-dir (replace-regexp-in-string (or ein:jupyter-default-notebook-directory
                                                 (expand-file-name "~/"))
                                             ""
                                             default-directory)))
      (with-current-buffer (ein:notebooklist-get-buffer url-or-port)
        (setq pynt-pop-up-notebook pop-up-notebook)
        (ein:notebooklist-new-notebook url-or-port
                                       (ein:get-kernelspec url-or-port pynt-kernelspec)
                                       (string-trim-right nb-dir "/")
                                       'pynt-setup-notebook)))))

(defun pynt-start-epc-server ()
  "Start the EPC server and register its associated handlers.

Exit if there is already an EPC server."
  (when (not pynt-epc-server)

    ;; Handlers.
    (defun handle-make-cell (&rest args)
      (multiple-value-bind (expr namespace cell-type line-number) args
        (pynt-make-cell expr namespace cell-type (string-to-number line-number))
        nil))

    ;; Views.
    (let ((connect-function
           (lambda (mngr)
             (let ((mngr mngr))
               (epc:define-method mngr 'make-cell 'handle-make-cell)))))

      ;; Server.
      (setq pynt-epc-server (epcs:server-start connect-function pynt-epc-port)))))


(defun pynt-make-cell (expr namespace cell-type line-number &optional at-point)
  "Make a new EIN cell and evaluate it.

Insert a new code cell with contents EXPR into the worksheet
buffer NAMESPACE with cell type CELL-TYPE at the end of the
worksheet and evaluate it.

This function is called from python code running in a jupyter
kernel via RPC.

LINE-NUMBER is the line number in the code that the cell
corresponds and is used during pynt scroll mode. If LINE-NUMBER
is -1 then that means the cell has no corresponding line. This
happens with certain markdown cells which are generated.

Since the variable `pynt-line-to-cell-map' is buffer-local we
have to take special care to not access it while we're over in
the worksheet buffer. Instead we save the variable we wish to
append to `pynt-line-to-cell-map' into a temporary variable and
then add it to `pynt-line-to-cell-map' when we're back in the
code buffer.

If AT-POINT is t then insert the cell at the point."
  (pynt-log "(pytn-make-cell %S %S %S %S)..." expr namespace cell-type line-number)

  ;; These variables are buffer local so we need to grab them before switching
  ;; over to the worksheet buffer.
  (setq new-cell nil)                   ; new cell to be added
  (with-current-buffer (pynt-notebook-buffer)
    (when (not at-point)
      (end-of-buffer))
    (call-interactively 'ein:worksheet-insert-cell-below)
    (insert expr)
    (let ((cell (ein:get-cell-at-point))
          (ws (ein:worksheet--get-ws-or-error)))
      (cond ((string= cell-type "code") (ein:cell-set-autoexec cell t))
            ((string= cell-type "markdown") (ein:worksheet-change-cell-type ws cell "markdown"))
            (t (ein:worksheet-change-cell-type ws cell "heading" (string-to-number cell-type))))
      (setq new-cell cell)))
  (when (and (not at-point) (pynt-notebook-window))
    (with-selected-window (pynt-notebook-window)
      (beginning-of-buffer)))
  (when (not (eq line-number -1))
    (puthash line-number (list namespace new-cell) pynt-line-to-cell-map)))

(defun pynt-start-ast-server ()
  "Start python AST server."
  (when (not pynt-ast-server)
    (setq pynt-ast-server (epc:start-epc "pynt-serve" nil))))

(defun pynt-init-epc-client (additional-code &optional callback cbargs)
  "Initialize the EPC client for the EIN notebook.

This needs to be done so python can send commands to Emacs to
create code cells. Use the variables
`pynt-epc-server-hostname' and `pynt-epc-port' to define
the communication channels for the EPC client.

Argument CALLBACK is a function to call afterwards."
  (pynt-log "Initiating EPC cient...")

  (deferred:$
    ;; Poll until kernel is live and then connect code buffer to notebook.
    (deferred:next
      (deferred:lambda ()
        (with-current-buffer pynt-code-buffer
          (if (ein:kernel-live-p (pynt-notebook-kernel))
              (progn
                (pynt-log "Kernel is live!")
                'kernel-is-live)
            (pynt-log "Kernel not live...")
            (deferred:nextc (deferred:wait 500) self)))))

    ;; Evaluate init code.
    (deferred:nextc it
      (lambda (msg)
        (let ((pynt-init-code (format pynt-init-code-template pynt-epc-server-hostname pynt-epc-port additional-code)))
          (pynt-log "Evaluating initial code!")
          (ein:shared-output-eval-string pynt-init-code))
        nil))

    ;; Run callback.
    (deferred:nextc it
      (lambda (msg)
        (when callback (apply callback cbargs))))))

(defun pynt-intercept-ein-notebook-name (old-function buffer-or-name)
  "Advice to add around `ein:connect-to-notebook-buffer'.

So pynt mode can grab the buffer name of the main worksheet.

Argument OLD-FUNCTION the function we are wrapping.
Argument BUFFER-OR-NAME the name of the notebook we are connecting to."
  (pynt-log "Setting main worksheet name = %S" buffer-or-name)
  (apply old-function (list buffer-or-name)))

(defun pynt-offload-to-scratch-worksheet ()
  "Move cells from the main notebook to the scratch notebook."
  (with-current-buffer (pynt-notebook-buffer)
    (beginning-of-buffer)
    (push-mark (point-max))
    (activate-mark)
    (condition-case nil                 ; worksheet may be empty
        (progn
          (call-interactively 'ein:worksheet-kill-cell)
          (let ((worksheets (ein:$notebook-worksheets ein:%notebook%)))
            (with-current-buffer (ein:worksheet-buffer (nth 1 worksheets))
              (beginning-of-buffer)
              (call-interactively 'ein:worksheet-yank-cell))))
      (error nil))))

(defun pynt-run-all-cells-above ()
  "Execute all cells above and including the cell at point.

This is a convenience function meant to be used by users of
pynt (and EIN)."
  (interactive)
  (save-excursion
    (let ((end-cell (ein:get-cell-at-point)))
      (beginning-of-buffer)
      (setq cell (ein:get-cell-at-point))
      (while (not (eq cell end-cell))
        (call-interactively 'ein:worksheet-execute-cell-and-goto-next)
        (setq cell (ein:get-cell-at-point)))
      (call-interactively 'ein:worksheet-execute-cell))))

(defun pynt-project-root ()
  "Get the project root.

Ask projectile for the project root. If not in a project then
just return the current directory."
  (condition-case nil
      (projectile-project-root)
    (error (file-name-directory pynt-code-buffer-file-name))))

(defun pynt-jupyter-server-start ()
  "Start a jupyter notebook server.

Start it in the user's home directory and use the
`ExternalIPythonKernelManager' so we can attach to external
IPython kernels.

Only start a jupyter notebook server if one has not already been
started."
  (interactive)
  (condition-case nil
      (ein:jupyter-server-conn-info)
    (error nil
           (let* ((extipy-args '("--NotebookApp.kernel_manager_class=codebook.ExternalIPythonKernelManager"
                                 "--Session.key=b'\"\"'"))
                  (ein:jupyter-server-args (append ein:jupyter-server-args extipy-args)))
             (ein:jupyter-server-start (executable-find ein:jupyter-default-server-command)
                                       (or ein:jupyter-default-notebook-directory
                                           (expand-file-name "~/")))))))

(defun pynt-reattach-save-detach (f &rest args)
  (if (not (called-interactively-p 'interactive))
      (apply f args)
    (if (not pynt-mode)
        (apply f args)
      (write-file pynt-code-buffer-file-name)
      (apply f args)
      (when pynt-namespace
        (pynt-detach-from-underlying-file)))))

(defun pynt-switch-to-namespace (namespace)
  "Switch to NAMESPACE.

This involves switching out the active notebook and also
attaching the code buffer to it.

The function `pynt-pop-up-notebook-buffer' calls `display-buffer'
which will run the `pynt-rebalance-on-window-change' hook which
will run this function again and we will get into an infinite
loop. Hence we set this lock so that the buffer and window hooks
won't run until this finishes."
  (pynt-log "Switching to namespace = %s..." namespace)
  (setq pynt-namespace namespace)
  (pynt-pop-up-notebook-buffer (pynt-notebook-buffer))
  (deferred:$
    (deferred:next
      (lambda ()
        (with-current-buffer pynt-code-buffer
          (pynt-log "Connecting to code buffer to notebook...")
          (pynt-connect-to-notebook-buffer (pynt-notebook-buffer))
          (pynt-detach-from-underlying-file))))))

(defun pynt-connect-to-notebook-buffer (notebook-buffer)
  (ein:connect-to-notebook-buffer notebook-buffer)
  (when (not (slot-value ein:%connect% 'autoexec))
    (ein:connect-toggle-autoexec)))

(defun pynt-switch-or-init (namespace &optional detach)
  "Switch to NAMESPACE.

Initialize it if it has not been initialized.

This function is necessary because of the way we can create
notebooks. When we run the command `pynt-switch-namespace' if the
selected namespace has not been created then we create it. It's
like launching pynt mode for the very first time. Otherwise if it
exists we just switch to it."
  (if (gethash namespace pynt-namespace-to-notebook-map)
      (pynt-switch-to-namespace namespace)
    (pynt-init namespace :pop-up-notebook detach)))

(defun pynt-invalidate-scroll-map (&optional a b c)
  (pynt-log "Invalidating scroll map!")
  (setq pynt-line-to-cell-map (make-hash-table :test 'equal)))

(defun pynt-detach-from-underlying-file ()
  "Replace namespace in underlying file with a kernel breakpoint.

Save the buffer first. Then detach from the underlying file."
  (write-file pynt-code-buffer-file-name)
  (save-buffer)
  (set-visited-file-name nil)
  (start-process "*pynt embed*"
                 "*pynt embed*"
                 "pynt-embed"
                 "-namespace" pynt-namespace))

(defun pynt-init (namespace &optional pop-up detach)
  "Initialize a namespace.

This involves creating a notebook if we haven't created one yet."

  ;; Locals.
  (setq pynt-namespace namespace
        pynt-code-buffer (buffer-name))

  ;; Detach from visited file and replace file with kernel break point.
  (when detach
    (pynt-detach-from-underlying-file))

  ;; Create new notebook.
  (pynt-new-notebook pop-up))

(defun pynt-mode-deactivate (&optional buffer)
  "Deactivate pynt mode."

  ;; Remove hooks.
  (advice-remove 'ein:connect-to-notebook-buffer 'pynt-intercept-ein-notebook-name)
  (remove-hook 'after-change-functions 'pynt-invalidate-scroll-map :local)
  (remove-hook 'post-command-hook 'pynt-scroll-cell-window :local)

  ;; I suspect the call to the function
  ;; `ein:notebook-kill-kernel-then-close-command' pops us into another buffer
  ;; unexpectedly. Save the code buffer here and force each command to execute
  ;; from within the code buffer.
  (setq code-buffer (or buffer (current-buffer)))

  ;; Delete notebook window.
  (condition-case nil
      (with-current-buffer code-buffer
        (when (pynt-notebook-window)
          (delete-window (pynt-notebook-window))))
    (error nil))

  ;; Kill kernels. Sometimes EIN deletes the notebooks before we can get here.
  ;; Hence the function `pynt-notebook-buffer' sometimes returns nil. But this
  ;; may be only when the notebook is deemed "modified" by EIN (or not). In any
  ;; event do our best to clean up.
  (condition-case nil
      (with-current-buffer code-buffer
        (dolist (namespace (map-keys pynt-namespace-to-notebook-map))
          (with-current-buffer (pynt-notebook-buffer namespace)
            (call-interactively 'ein:notebook-kill-kernel-then-close-command))))
    (error nil))

  ;; Reattach to underlying file and save to disk. Save the file for real. Don't
  ;; detach from it. But also don't disable this for other buffers using pynt
  ;; mode.
  (with-current-buffer code-buffer
    (write-file pynt-code-buffer-file-name)
    (advice-remove 'save-buffer 'pynt-reattach-save-detach)
    (save-buffer)
    (advice-add 'save-buffer :around 'pynt-reattach-save-detach))

  ;; Delete all the notebook files.
  (with-current-buffer code-buffer
    (dolist (notebook-file pynt-notebook-files)
      (delete-file notebook-file))
    (message (format "Deleted %s" pynt-notebook-files)))

  ;; Disable ein connect mode.
  (ein:connect-mode -1))

(defun pynt-deactivate-buffers ()
  "Clean up pynt mode from all the buffers."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when pynt-mode
        (pynt-mode-deactivate buffer)))))

(defvar pynt-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-e") 'pynt-dump-namespace)
    (define-key map (kbd "C-c C-s") 'pynt-recover-notebook-window)
    (define-key map (kbd "C-c C-k") 'pynt-unpack)
    (define-key map (kbd "C-c C-n") 'pynt-goto-next-cell-line)
    (define-key map (kbd "C-c C-p") 'pynt-goto-prev-cell-line)
    (define-key map (kbd "<up>") 'pynt-next-cell-instance)
    (define-key map (kbd "<down>") 'pynt-prev-cell-instance)
    map))

;;;###autoload
(define-minor-mode pynt-mode
  "Minor mode for generating and interacting with jupyter notebooks via EIN

\\{pynt-mode-map}"
  :keymap pynt-mode-map
  :lighter "pynt"
  (if pynt-mode
      (progn

        ;; Variables.
        (setq pynt-namespace-to-notebook-map (make-hash-table :test 'equal)
              pynt-namespace-to-kernel-pid-map (make-hash-table :test 'equal)
              pynt-line-to-cell-map (make-hash-table :test 'equal)
              pynt-code-buffer-file-name (buffer-file-name)
              pynt-code-buffer (current-buffer))

        ;; Initialize servers.
        (pynt-start-epc-server)
        (pynt-start-ast-server)
        (pynt-jupyter-server-start)

        ;; Hooks.
        (add-hook 'after-change-functions 'pynt-invalidate-scroll-map nil :local)
        (add-hook 'post-command-hook 'pynt-scroll-cell-window nil :local)
        (add-hook 'kill-emacs-hook 'pynt-deactivate-buffers)
        (add-hook 'kill-buffer-hook 'pynt-mode-deactivate nil :local)
        (advice-add 'save-buffer :around 'pynt-reattach-save-detach))

    (pynt-mode-deactivate)))

;;;###autoload
(add-hook 'python-mode-hook
          (lambda ()
            (when (not (string-match-p (regexp-quote "ein:") (buffer-name)))
              (pynt-mode))))

(provide 'pynt)
;;; pynt.el ends here
