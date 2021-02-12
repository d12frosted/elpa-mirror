This package will immediately run a callback (a finalizer) after
its registered lisp object has been garbage collected. This allows
for extra resources, such as buffers and processes, to be cleaned
up after the object has been freed.

Unlike finalizers in other languages, the actual object to be
finalized will *not* be available to the finalizer. To help deal
with this, arguments can be passed to the finalizer to provide
context as to which object was collected. The object itself must
*not* be on of these arguments.

-- Function: `finalize-register' object finalizer &rest finalizer-args
     Registers an object for finalization. FINALIZER will be called
     with FINALIZER-ARGS when OBJECT has been garbage collected.

Usage:

    (cl-defstruct (pinger (:constructor pinger--create))
      process host)

    (defun pinger-create (host)
      (let* ((process (start-process "pinger" nil "ping" host))
             (object (pinger--create :process process :host host)))
        (finalize-register object #'kill-process process)
        object))

There is also a "finalizable" mixin class for EIEIO that provides a
`finalize' generic function.

    (require 'finalizable)
