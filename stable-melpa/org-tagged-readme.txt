To create a tagged table for an org file, simply put the dynamic block
`
#+BEGIN: tagged :columns "%10tag1(Tag1)|tag2" :match "kanban"
#+END:
'
somewhere and run `C-c C-c' on it.
