This is a forward compatibility package, which provides (a subset of) the
features of the cl-generic package introduced in Emacs-25, for use on
previous emacsen.

Make sure this is installed *late* in your `load-path`, i.e. after Emacs's
built-in .../lisp/emacs-lisp directory, so that if/when you upgrade to
Emacs≥25, the built-in version of the file will take precedence, otherwise
you could get into trouble (although we try to hack our way around the
problem in case it happens).

AFAIK, the main incompatibilities between cl-generic and EIEIO's defmethod
 are:
- EIEIO does not support multiple dispatch.  We ignore this difference here
  and rely on EIEIO to detect and signal the problem.
- EIEIO only supports primary, :before, and :after qualifiers.  We ignore
  this difference here and rely on EIEIO to detect and signal the problem.
- EIEIO does not support specializers other than classes.  We ignore this
  difference here and rely on EIEIO to detect and signal the problem.
- EIEIO uses :static instead of (subclass <foo>) and :static methods match
  both class arguments as well as object argument of that class.  Here we
  turn (subclass <foo>) into a :static qualifier and ignore the semantic
  difference, hoping noone will notice.
- EIEIO's defgeneric does not reset the function.  We ignore this difference
  and hope for the best.
- EIEIO uses `call-next-method' and `next-method-p' while cl-defmethod uses 
  `cl-next-method-p' and `cl-call-next-method' (simple matter of renaming).
  We handle that by renaming the calls in the `cl-defmethod' macro.
- The errors signaled are slightly different.  We make
  cl-no-applicable-method into a "parent" error of no-method-definition,
  which should cover the usual cases.
- EIEIO's no-next-method and no-applicable-method have different calling
  conventions from cl-generic's.  We don't try to handle this, so just
  refrain from trying to call (or add methods to) `cl-no-next-method' or
  `cl-no-applicable-method'.
- EIEIO's `call-next-method' and `next-method-p' have dynamic scope whereas
  cl-generic's `cl-next-method-p' and `cl-call-next-method' are lexically
  scoped.  The cl-defmethod here handles the common subset between the two.