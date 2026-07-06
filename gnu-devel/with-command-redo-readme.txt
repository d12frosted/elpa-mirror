#################
With Command Redo
#################

A generic mechanism for running a command repeatedly without cluttering your undo history.

Where each successive call undoes the previous result before applying the next.
Consumers build cycling, completion, or other repeat-with-redo behaviors on top.

Note that this is middle-ware since it's intended for other packages to use.

Available via `melpa <https://melpa.org/#/with-command-redo>`__.


Usage
=====

This package exposes:

- ``with-command-redo`` macro.
- ``with-command-redo-fn`` function variant.
- ``with-command-redo-active-p`` query if a redo-chain is active, takes a single ``id`` symbol.
- ``with-command-redo-break`` end an active redo-chain (so a later call starts a
  new chain instead of continuing it), takes a single ``id`` symbol.


Arguments
---------

Both ``with-command-redo`` and ``with-command-redo-fn`` accept:

``:id SYMBOL``
   Identifies the chain. Multiple commands sharing the same id
   continue each other's chain. Required.
``:on-other-command FUNCTION``
   Called from ``post-command-hook`` when a non-modifying external command
   runs while the chain is active. Receives the cache as its sole argument.
   Side effects (messaging, cache mutation) are permitted.
   Return non-nil to break the chain, nil to keep it alive.

The body (macro) or callback (function) receives a plist with:

``:count``
   The execution count (0 on the first call).
``:cache``
   nil on the first call. Use ``plist-put`` to pass a value to the next call.
``:result``
   Defaults to t. Use ``plist-put`` to set nil when the operation has no result.


Example
-------

Cycle through a list of strings, each call undoes the previous insertion:

.. code-block:: elisp

   ;; Macro variant.
   (defun my-cycle-insert ()
     (interactive)
     (with-command-redo (list :id 'my-cycle) props
       (let ((count (plist-get props :count))
             (items '("alpha" "beta" "gamma")))
         (insert (nth (mod count (length items)) items)))))

   ;; Function variant (for conditional use without macro expansion).
   (defun my-cycle-insert ()
     (interactive)
     (with-command-redo-fn
      (list :id 'my-cycle)
      (lambda (props)
        (let ((count (plist-get props :count))
              (items '("alpha" "beta" "gamma")))
          (insert (nth (mod count (length items)) items))))))


Installation
============

.. code-block:: elisp

   (use-package with-command-redo)
