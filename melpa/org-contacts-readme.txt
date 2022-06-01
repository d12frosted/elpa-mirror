This file contains the code for managing your contacts into Org-mode.

To enter new contacts, you can use `org-capture' and a minimal template just like
this:

        ("c" "Contacts" entry (file "~/Org/contacts.org")
         "* %(org-contacts-template-name)
:PROPERTIES:
:EMAIL: %(org-contacts-template-email)
:END:")))

You can also use a complex template, for example:

        ("c" "Contacts" entry (file "~/Org/contacts.org")
         "* %(org-contacts-template-name)
:PROPERTIES:
:EMAIL: %(org-contacts-template-email)
:PHONE:
:ALIAS:
:NICKNAME:
:IGNORE:
:ICON:
:NOTE:
:ADDRESS:
:BIRTHDAY:
:END:")))
