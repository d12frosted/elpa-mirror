
A reference like \"[[ref:1234]]\" should be transformed into a button. A click should
display the matching locations \"[[id:1234]]\" in files' content, file names and
buffers. A click on a location should display the references to it.

More precisely:

- A location is defined as:
  - or :ID: <ID>
  - or [[id:<ID>]]
  - or [[id:<ID>][<name>]]

- A reference is defined as:
  - or :REF: <ID>
  - or [[ref:<ID>]]
  - or [[ref:<ID>][<name>]]

This package requires `ripgrep' and `fd'.
