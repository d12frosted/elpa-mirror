org-agenda-property is a package which displays the properties of
an org item beside (or below) the item's title in the agenda
buffer. Customize the variable `org-agenda-property-list' to add
which properties you which to show.

; Instructions:

INSTALLATION

If you installed from Melpa, you shouldn't need to do anything
else. Just customize `org-agenda-property-list' and call your
agenda buffer (tipically `org-agenda-list') to see the magic.

     If you installed manually, just make sure it's in your
     load-path and call
	(require 'org-agenda-property)

Variables

	All variables can be edited by running
	`org-agenda-property-customize' (seriously, chech it out, they
	are just a few :-)). The documentations are mostly self
	explanatory, I list here only the most important two.

`org-agenda-property-list'
             This should be a list of all properties you want
             displayed in the buffer. Default is "LOCATION".

	`org-agenda-property-position'
		This is where you want the properties to be displayed
		(besides the title or below the title?).
