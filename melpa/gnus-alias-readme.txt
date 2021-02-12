
 gnus-alias provides a simple mechanism to switch Identities when
 using a message-mode or a message-mode derived mode.  An Identity
 is one or more of the following elements:

 o From - sets the From header (i.e. the sender)
 o Organization - sets the Organization header (a common, optional header)
 o Extra headers - a list of arbitrary header to set (e.g. X-Archive: no)
 o Body - adds text to the body of the message (just above the signature)
 o Signature - adds a signature to the message

 All of this is also provided by the standard `gnus-posting-styles'
 (which see).  Whereas Posting Styles let you set these up
 initially, though, gnus-alias lets you change them on the fly
 easily, too (in this regard gnus-alias is much like gnus-pers,
 upon which it is based; see 'Credits' below).  With a simple
 command (`gnus-alias-select-identity') you can select & replace
 one Identity with another.

 There are other significant differences between gnus-alias and
 Posting Styles, too.  gnus-alias has a much simpler interface/API
 for selecting an initial Identity automatically.  Posting Styles is
 much more flexible (especially in that you can build up an
 "Identity" piece by piece), but with that flexibility can come
 some complexity.

 Other advantages to using gnus-alias:

 o the ability to switch Identities in a message buffer
 o can access original message to help determine Identity of the
   followup/reply message
 o can act on a forwarded message as if it were a message being
   replied to
 o can start a new message with a given Identity pre-selected

 It is possible to use both Posting Styles and gnus-alias, with
 `gnus-posting-styles' setup occuring before gnus-alias selects an
 Identity.  That much co-ordination is beyond my attention span,
 though; I just use this package.

 There may also be some overlap between this package and
 `message-alternative-emails' (which see), though I'm not exactly
 sure what that really does.

; Installation:

 Put this file on your Emacs-Lisp load path, then add one of the
 following to your ~/.emacs startup file.  You can load gnus-alias
 every time you start Emacs:

    (require 'gnus-alias)
    (gnus-alias-init)

 or you can load the package via autoload:

    (autoload 'gnus-alias-determine-identity "gnus-alias" "" t)
    (add-hook 'message-setup-hook 'gnus-alias-determine-identity)

 To add a directory to your load-path, use something like the following:

     (add-to-list 'load-path (expand-file-name "/some/load/path"))
