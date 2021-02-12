
Lookup and download bibliographic records from Bibsonomy.

Installation:

  1. Install biblio-bibsonomy.el
  2. Create an account on www.bibsonomy.org
  3. In the Settings tab of the account page, find your API key under the API heading
  4. Set the following variables in your Emacs init file:

     (require 'biblio-bibsonomy)

     (setq
      biblio-bibsonomy-api-key "my-api-key"
      biblio-bibsonomy-username "my-user-name")

Usage:

  M-x biblio-lookup

biblio-bibsonomy automatically adds itself as a biblio.el backend.
