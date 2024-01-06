           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              BUFFERLO.EL - MANAGE FRAME/TAB-LOCAL BUFFER
                                 LISTS
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This gives you separate buffer lists per frame and per (tab-bar) tab.

Bufferlo is a lightweight wrapper around Emacs's buffer-list frame
parameter.  In contrast to similar solutions, it integrates seamlessly
with the standard frame and tab management facilities, including
undeletion of frames and tabs, tab duplication and moving, frame
cloning, and persisting sessions (via desktop.el).

A buffer is added to the local buffer list when it is displayed in the
frame/tab (e.g., by opening a new file in the tab or by switching to the
buffer from the global buffer list).  In addition, bufferlo provides
functions that allow the manipulation of the local buffer list.
Bufferlo does not touch the global buffer list or the existing
buffer-management facilities.  Use the equivalent bufferlo variants to
work with the frame/tab local buffer list.

The packages [frame-bufs] (unmaintained) and [beframe] provide similar
functionality, but only at the frame level, without support for tabs and
desktop.el.

You may also have a look at full workspace solutions like [bufler]
(automatic rule-based workspace management and buffer grouping) or
[perspective] (comprehensive workspace isolation, workspace merging,
workspace persistence).  They work quite differently than bufferlo.


[frame-bufs] <https://github.com/alpaker/frame-bufs>

[beframe] <https://protesilaos.com/emacs/beframe>

[bufler] <https://github.com/alphapapa/bufler.el>

[perspective] <https://github.com/nex3/perspective-el>


1 Installation
══════════════

  Bufferlo is available in [GNU ELPA].  Install it via `package-install'
  and enable `bufferlo-mode':
  ┌────
  │ (bufferlo-mode 1)
  └────

  Or use `use-package':
  ┌────
  │ (use-package bufferlo
  │  :ensure t
  │  :config
  │  (bufferlo-mode 1))
  └────


[GNU ELPA] <https://elpa.gnu.org/packages/bufferlo.html>


2 Usage
═══════

  Use the bufferlo buffer-list commands as an alternative to the
  respective global commands:
  • `bufferlo-switch-to-buffer': The `switch-to-buffer' command filtered
    for local buffers.  Call it with the prefix argument to get the
    global list (all buffers).
  • `bufferlo-ibuffer': `ibuffer' filtered for local buffers.
    Alternatively, use "/ l" in ibuffer.
  • `bufferlo-ibuffer-orphans': `ibuffer' filtered for orphan buffers.
    Orphan buffers are buffers that are not in any frame/tab's local
    buffer list.  Alternatively, use "/ L" in ibuffer.
  • `bufferlo-list-buffers': Display a list of local buffers in a
    buffer-menu buffer.
  • `bufferlo-list-orphan-buffers': Display a list of orphan buffers in
    a buffer-menu buffer.  Orphan buffers are buffers that are not in
    any frame/tab's local buffer list.

  Bufferlo provides functions to manage the local buffer lists:
  • `bufferlo-clear': Clear the frame/tab's buffer list.
  • `bufferlo-remove': Remove a buffer from the frame/tab's buffer list.
  • `bufferlo-remove-non-exclusive-buffers' Remove all buffers from the
    local list that are not exclusive to this frame/tab.
  • `bufferlo-bury': Bury and remove the current buffer from the
    frame/tab's buffer list.
  • `bufferlo-kill-buffers': Kill all buffers from the local list.
  • `bufferlo-kill-orphan-buffers': Kill all buffers that are not in any
    local list.
  • `bufferlo-delete-frame-kill-buffers': Delete the frame and kill all
    its local buffers.
  • `bufferlo-tab-close-kill-buffers': Close the tab and kill all its
    local buffers.
  • `bufferlo-isolate-project': Isolate a project in the frame or tab.
  • `bufferlo-find-buffer': Switch to (one of) the frame/tab that
    contains the buffer in its local list.
  • `bufferlo-find-buffer-switch': Switch to (one of) the frame/tab that
    contains the buffer in its local list, and select the buffer.


2.1 Consult Integration
───────────────────────

  You can integrate bufferlo with consult-buffer.

  This is an example configuration:
  ┌────
  │ (defvar my-consult--source-buffer
  │   `(:name "Other Buffers"
  │     :narrow   ?b
  │     :category buffer
  │     :face     consult-buffer
  │     :history  buffer-name-history
  │     :state    ,#'consult--buffer-state
  │     :items ,(lambda () (consult--buffer-query
  │ 			:predicate #'bufferlo-non-local-buffer-p
  │ 			:sort 'visibility
  │ 			:as #'buffer-name)))
  │     "Non-local buffer candidate source for `consult-buffer'.")
  │ 
  │ (defvar my-consult--source-local-buffer
  │   `(:name "Local Buffers"
  │     :narrow   ?l
  │     :category buffer
  │     :face     consult-buffer
  │     :history  buffer-name-history
  │     :state    ,#'consult--buffer-state
  │     :default  t
  │     :items ,(lambda () (consult--buffer-query
  │ 			:predicate #'bufferlo-local-buffer-p
  │ 			:sort 'visibility
  │ 			:as #'buffer-name)))
  │     "Local buffer candidate source for `consult-buffer'.")
  │ 
  │ (setq consult-buffer-sources '(consult--source-hidden-buffer
  │ 			       my-consult--source-local-buffer
  │ 			       my-consult--source-buffer
  │ 			       ;; ... other sources ...
  │ 			       ))
  └────

  <./img/consult1.svg> Fig.1: All buffers are shown; the local buffers
  are grouped separately.

  You can also configure consult-buffer to hide the non-local buffers by
  default:
  ┌────
  │ (defvar my-consult--source-buffer
  │   `(:name "All Buffers"
  │     :narrow   ?a
  │     :hidden   t
  │     :category buffer
  │     :face     consult-buffer
  │     :history  buffer-name-history
  │     :state    ,#'consult--buffer-state
  │     :items ,(lambda () (consult--buffer-query
  │ 			:sort 'visibility
  │ 			:as #'buffer-name)))
  │   "All buffer candidate source for `consult-buffer'.")
  │ 
  │ (defvar my-consult--source-local-buffer
  │   `(:name nil
  │     :narrow   ?b
  │     :category buffer
  │     :face     consult-buffer
  │     :history  buffer-name-history
  │     :state    ,#'consult--buffer-state
  │     :default  t
  │     :items ,(lambda () (consult--buffer-query
  │ 			:predicate #'bufferlo-local-buffer-p
  │ 			:sort 'visibility
  │ 			:as #'buffer-name)))
  │   "Local buffer candidate source for `consult-buffer'.")
  │ 
  │ (setq consult-buffer-sources '(consult--source-hidden-buffer
  │ 			       my-consult--source-buffer
  │ 			       my-consult--source-local-buffer
  │ 			       ;; ... other sources ...
  │ 			       ))
  └────

  <./img/consult2.svg> Fig.2: By entering 'a'+<space>, the global buffer
  list is shown ("All Buffers").

  A good alternative is to bind space to "All Buffers" (via `:narrow
  32').  By default, space is used for hidden buffers
  (`consult--source-hidden-buffer').  If you still need the hidden
  buffer list, you can make a new source for it, for example, with
  period as the narrowing key (`:narrow ?.').


2.2 Ivy Integration
───────────────────

  You can also integrate bufferlo with ivy.

  ┌────
  │ (defun ivy-bufferlo-switch-buffer ()
  │   "Switch to another local buffer.
  │ If the prefix arument is given, include all buffers."
  │     (interactive)
  │     (if current-prefix-arg
  │ 	(ivy-switch-buffer)
  │       (ivy-read "Switch to local buffer: " #'internal-complete-buffer
  │ 		:predicate (lambda (b) (bufferlo-local-buffer-p (cdr b)))
  │ 		:keymap ivy-switch-buffer-map
  │ 		:preselect (buffer-name (other-buffer (current-buffer)))
  │ 		:action #'ivy--switch-buffer-action
  │ 		:matcher #'ivy--switch-buffer-matcher
  │ 		:caller 'ivy-switch-buffer)))
  └────


2.3 Initial Buffer
──────────────────

  By default, the currently active buffer is shown in a newly created
  tab, so this buffer inevitably ends up in the new tab's local list.
  You can change the initial buffer by customizing
  `tab-bar-new-tab-choice':
  ┌────
  │ (setq tab-bar-new-tab-choice "*scratch*")
  └────
  This lets new tabs always start with the scratch buffer.

  You can also create a local scratch buffer for each tab:
  ┌────
  │ (setq tab-bar-new-tab-choice #'bufferlo-create-local-scratch-buffer)
  └────
  You can customize the name of the local scratch buffers by setting
  `bufferlo-local-scratch-buffer-name' accordingly.

  The same can be achieved for new frames.  Use this to set the scratch
  buffer as the initial buffer for new frames:
  ┌────
  │ (add-hook 'after-make-frame-functions #'bufferlo-switch-to-scratch-buffer)
  └────

  Alternatively, create a new local scratch buffer for new frames:
  ┌────
  │ (add-hook 'after-make-frame-functions #'bufferlo-switch-to-local-scratch-buffer)
  └────

  Of course, you can also set an arbitrary buffer as the initial frame
  buffer:
  ┌────
  │ (defun my-set-initial-frame-buffer (frame)
  │   (with-selected-frame frame
  │     (switch-to-buffer "<BUFFER_NAME>")))
  │ (add-hook 'after-make-frame-functions #'my-set-initial-frame-buffer)
  └────


2.4 Bufferlo Anywhere
─────────────────────

  "Bufferlo anywhere" is an optional feature that lets you have
  bufferlo's frame/tab-local buffer list anywhere you like, i.e. in any
  command with interactive buffer selection (via `read-buffer', e.g.,
  `diff-buffers', `make-indirect-buffer', …) – not just in the
  switch-buffer facilities.  You can configure which commands use
  bufferlo's local list and which use the global list.

  Enable `bufferlo-anywhere-mode' to use bufferlo's local buffer list by
  default.  Customize `bufferlo-anywhere-filter' and
  `bufferlo-anywhere-filter-type' to restrict the commands that use the
  local list.  With the command prefix
  `bufferlo-anywhere-disable-prefix', you can temporarily disable
  `bufferlo-anywhere-mode' for the next command.

  Instead the minor mode, you can use the command prefix
  `bufferlo-anywhere-enable-prefix', which only temporarily enables
  bufferlo's local buffer list for the next command.
