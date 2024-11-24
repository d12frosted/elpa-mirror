This package provides an unofficial Emacs client for Imgur API.  Currently it
makes the basic functionality available such as authorization, uploading and
deleting in both interactive and non-interactive approach.  On top of that it
provides an option to keep multiple sessions active with functions/commands
named "*-with-session" (otherwise using an automatically created default
session).

How to:
* `imgur-authorize-interactive' (or `imgur-authorize')
* `imgur-upload-interactive' (or `imgur-upload')
  * for simpler access `imgur-upload-image-interactive'
* `imgur-delete-interactive' (or `imgur-delete')

Check these resources' documentation for more info:
* https://status.imgur.com
* https://apidocs.imgur.com
* customization group `imgur'
* imgur-*-success-func / imgur-*-fail-func
