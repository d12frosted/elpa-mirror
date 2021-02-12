
  (require 'namespaces)

  (namespace foo :export [hello])
  (defn hello () "Hello, world!")

  (namespace bar)
  (foo/hello)    ; # => "Hello, world!"


See documentation at https://github.com/chrisbarrett/elisp-namespaces
