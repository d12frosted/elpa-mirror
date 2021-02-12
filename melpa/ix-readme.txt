ix.el is a simple emacs client to http://ix.io cmdline pastebin. At
the moment using the `ix' command on a selection sends the
selection to ix.io, entire buffer is sent if selection is inactive,
on success the url is notified in the minibuffer as well as saved
in the kill ring.

It is recommended to set a user name and token so that you can
later delete or replace a paste. Set this via the variables
`ix-user' and `ix-token' via M-x customize-group RET ix

Posts (if posted with user and token) can be deleted by `ix-delete'
command which prompts for post id (the string after http://ix.io/)

curl is used as the backend via grapnel http request library.


History

0.5 - Initial release.
0.6 - Added delete posts functionality
0.6.1 - Minor fix for `ix-delete' interactive form & adding
        `ix-version' as a const
0.6.2 - `ix-delete' accepts a full url or the post id
0.7.0 - Adding `ix-browse'
          `ix-browse' lets you browse a post at http://ix.io
