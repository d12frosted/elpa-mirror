A set of commands to facilitate the usual multiple-cursors
workflows with the use of regular keyboard macros (kmacros).
This way all the pitfalls of rolling a custom implementation are
avoided, while all the kmacro facilities, such as counters, queries
and kmacro editing, are gained virtually for free.

It is assumed the user didn't rebind the basic isearch commands,
otherwise the behavior may be unpredictable.

A typical workflow with `kmacro-mc-region':

1. Select the text whose occurences are to be manipulated (in
   a trivial case: a symbol to be renamed).
2. M-x kmacro-mc-region RET
3. Do the necessary edits, either within the region or in its
   vicinity outside of it (this is the part that cannot be achieved
   with other mc alternatives such as iedit or query-replace).
   They will get recorded as a kmacro.
4. Press any key that would end the kmacro recording:
   F4, C-x ) or C-x C-k C-k
5. Repeat the kmacro with F4, C-x e or C-x C-k C-k.
