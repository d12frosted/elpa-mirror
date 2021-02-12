
  This defines a new local minor-mode `sotclojure-mode', which is
  activated by the global `speed-of-thought-mode' on any clojure
  buffers.

  The mode is quite simple, and is composed of two parts:

1.1 Abbrevs
───────────

  A large number of abbrevs which expand function initials to their
  name. A few examples:

  • wl -> when-let [|]
  • n -> not
  • wo -> with-open
  • np -> number? (the p stands for predicate)
  • ck -> :keys [|] (the c stands for colon)

  Note that, in order to avoid frustration, the 1-letter abbrevs will
  only expand after a `(' or after a `/', so you can still use 1-letter
  local variables like `a' and `n'.

1.2 Commands
────────────

  It also defines 4 commands, which really fit into this "follow the
  thought-flow" way of writing. The bindings are as follows:
  `M-RET': Break line, and insert `()' with point in the middle.
  `C-RET': Do `forward-up-list', then do M-RET.

  Hitting RET followed by a `(' was one of the most common key sequences
  for me while writing elisp, so giving it a quick-to-hit key was a
  significant improvement.

  `C-c f': Find function under point. If it is not defined, create a
  definition for it below the current function and leave point inside.

  With these commands, you just write your code as you think of it. Once
  you hit a “stop-point” of sorts in your tought flow, you hit `C-c f/v'
  on any undefined functions/variables, write their definitions, and hit
  `C-u C-SPC' to go back to the main function.

1.3 Small Example
─────────────────

  With the above (assuming you use something like paredit or
  electric-pair-mode), if you write:

  ┌────
  │ (wl SPC {ck SPC x C-f C-RET (a SPC (np SPC y C-f SPC f SPC y
  └────

  You get

  ┌────
  │ (when-let [{:keys [x]}
  │            (and (number? y) (first y))])
  └────
