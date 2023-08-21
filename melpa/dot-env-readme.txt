dot-env is a package that reproduces the functionality in
https://github.com/motdotla/dotenv/tree/master and allows the use of
environment variables stored in a .env file, similar to a technique used
in the node.js ecosystem.

VARIABLES:
dot-env-filepath            : Path to .env file (defaults to .emacs.d/.env)
dot-env-environment         : alist that stores environment variables
dot-env-file-is-encrypted   : non-nil prevents values being stored in Emacs environment

COMMANDS:
dot-env-config    : Loads the .env file into dot-env-environment
dot-env-parse     : Parses a dotenv string into an association list and return the result
dot-env-populate  : Loads the values from an association list into dot-env-environment

FUNCTIONS:
dot-env-get   : Takes a string parameter and returns corresponding value
