
If there is a string like \"[[ref:1234]]\" in some buffer, then this minor mode
will turn it into a \"Reference\". A reference may be viewed as a button
such that a click will search for the matching \"Location\" in files'
content, file names and buffers. A matching location may be a string
\"[[id:1234]]\" or a file named \"1234\".

More precisely:

- A location is defined as:
  - or :ID: <ID>
  - or [[id:<ID>]]
  - or [[id:<ID>][<name>]]

- A reference is defined as:
  - or :REF: <ID>
  - or [[ref:<ID>]]
  - or [[ref:<ID>][<name>]]

This package requires `ripgrep' and `fd' to be installed on your system
for full functionality.

- Ripgrep: For fast text search.
- fd: For fast file search.
