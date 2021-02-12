To espy is to see something at a distance which is what this package is about.
This package allows users to fetch a  user and password from a file
without visiting it. It gathers all headers containing passwords or
usernames as defined by `espy-header-prefix' and `espy-pass-prefix' and
presents them to the user. The choosen password gets added to the kill ring.

For example using a file with the content of
(with no whitespace before any prefix)

   *** Header1
   user: User1
   pass: Password1

and running

   (espy-get-pass)

would result in one entry `Header1' being selectable. Choosing this entry
would result in `Password1' being copied to the kill-ring
