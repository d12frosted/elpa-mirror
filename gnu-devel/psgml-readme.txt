This is the READ ME file for psgml.el version 1.3.3.       -*- outline -*-

This is an ALPHA release. 


* User interface changes (1.3.3)

** Catalog files now can contain SYSTEM and OVERRIDE 
as per OASIS Technical Resolution 9401:1997 
<https://www.oasis-open.org/specs/a401.htm>

  SYSTEM sysid file

Will map a system identifier sysid to the file. 
  
  OVERRIDE {yes|no}

If yes following entries (public, entity, doctype) will override a
system identifier and if no they will not.  Initiall override is
decided by variable sgml-system-identifiers-are-preferred.


* User interface changes (1.3.2)

** Rename sgml-general-dtd-info to sgml-describe-dtd. Keep old name as
   alias.

** Made menus compact, only one top level menu.

** Added new function sgml-show-structure (C-c C-s)
(May need latest emacs version (22))

** Changed C-c C-t to sgml-show-current-element-type
New more comprehensive information display.

** New mouse menu, sgml-right-menu on S-mouse-3 
If invoked on a start-tag will include entries to manipulate the
tag/element, including setting attributes. If invoked in content it
will be a menu of valid elements.

** The <?PSGML> process instruction
Not new, but now documented and improved.

<?PSGML ELEMENT FOO  
     face=italic
     nofill=t
     help-text="marks a foo"
     attnames=("ID" "STYLE")
     structure=ignore ?>

Must be placed in the DTD.

