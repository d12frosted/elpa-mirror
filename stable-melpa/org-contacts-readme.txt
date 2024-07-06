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

;; Usage:

How to search?
- You can use [M-x org-contacts] command to search.

- You can use `org-sparse-tree' [C-c / p] to filter based on a
  specific property. Or other matcher on `org-sparse-tree'.
