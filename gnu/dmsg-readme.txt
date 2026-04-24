`dmsg' writes structured entries to a dedicated buffer and provides
`dmsg-mode' to interact with the buffer.

Buffer format:

  [LVL] [YYYY-MM-DD HH:MM:SS.mmm] first line of message
   continuation line               (exactly one leading space per \n)
  (fn-name args)                backtrace frame
  (fn-name ...)                unevaluated frame


Default keys (dmsg-mode):
  <tab>   Toggle compact fn <- fn <- fn chain for entry at point
  b       Open detailed backtrace for entry at point in a side window
  c       Clear entries without modifying buffer (toggle)
  e       Erase buffer (destructive)
  f       Filter entries by regexp
  s       Snapshot visible entries to a .log file
  l1-l4   Set minimum display level (l1=debug l2=info l3=warn l4=error)

Usage:
  (require 'dmsg)
  (dmsg "value is %S" x)
  (dmsg 'warn "something odd: %=S" x)