BUGS

- Indentation thinks "." can only be the termination marker of
  an LF declaration.  This can mess things up badly.
- Indentation after curried terms like "fn x => fn y =>" is twice that
  after "fn x y =>".
