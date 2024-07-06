beeminder.el provides a way for Emacs to interact with the Beeminder API.  It
adds the following functionality:
  - A client for viewing and modifying Beeminder goals.
  - Functions for adding data to Beeminder goals.
  - Integration with org-mode for submitting clocked time and task completions.
  - API access methods for fetching and modifying Beeminder goal information.

Please set `beeminder-username' and `beeminder-auth-token' before using.

You can find your auth token by logging in to Beeminder and then visiting the
following URI: https://www.beeminder.com/api/v1/auth_token.json

Load beeminder.el with (require 'beeminder).  This must be called after your
Org is set up if you want to use org-mode integration.
