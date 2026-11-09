This is a Wayland client implementation in Elisp.

Protocol XML is translated into pack/unpack functions using bindat.
Objects are represented by `ewc-object' structs.
Global client state is represented by `ewc-client'.

Main entry points:

- Event listener functions with common PREFIX, e.g. "YOURAPP-on-"
- Protocol XML parsing via ewc-read
- ewc-start to connect and send initial get-registry request
- ewc-object-add to create new wayland objects
- ewc-request
