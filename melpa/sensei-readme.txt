This package provides two basic tools to interact with a remote
instance of sensei, a tool for note taking and time management:

* The ability to take notes on the fly within a given project's
  context.  This opens a temporary buffer whose content will be
  sent as-is to sensei with the project's directory and current
  timestamp,

* Quick recording of current "Flow" according to what flows are
  recorded within the current user's profile.

Proper operation depends on the existence of ~/.config/sensei/client.json
configuration file defining user name and authentication token.
