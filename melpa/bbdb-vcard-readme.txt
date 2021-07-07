
Purpose
=======

Import and export of vCards as defined in RFC 2425 and RFC 2426
to/from The Insidious Big Brother Database (BBDB).


Usage
=====

vCard Import
------------

On a file, a buffer or a region containing one or more vCards, use
`bbdb-vcard-import-file', `bbdb-vcard-import-buffer', or
`bbdb-vcard-import-region' respectively to import them into BBDB.

Preferred input format is vCard version 3.0.  Version 2.1 vCards
are converted to version 3.0 on import.


vCard Export
------------

In buffer *BBDB*, press v to export the record under point.  Press
* v to export all records in buffer into one vCard file.  Press *
C-u v to export them into one file each.

To put one or all vCard(s) into the kill ring, press V or * V
respectively.

Exported vCards are always version 3.0.  They can be re-imported
without data loss with one exception: North American phone numbers
lose their structure and are stored as flat strings.


There are a few customization variables grouped under `bbdb-vcard'.


Installation
============

Put this file and file vcard.el into your `load-path' and add the
following line to your Emacs initialization file:

  (require 'bbdb-vcard)


Implementation
==============

vCard Import
------------

For conversion of v2.1 vCards into v3.0 on import, Noah Friedman's
vcard.el is needed.

An existing BBDB record is extended by new information from a vCard

  (a) if name and company and an email address match
  (b) or if name and company match
  (c) or if name and an email address match
  (d) or if name and birthday match
  (e) or if name and a phone number match.

Otherwise, a fresh BBDB record is created.

When `bbdb-vcard-try-merge' is set to nil, there is always a fresh
record created.

In cases (c), (d), and (e), if the vCard has ORG defined, this ORG
would overwrite an existing Company in BBDB.

Phone numbers are always imported as strings.

For vCard types that have more or less direct counterparts in BBDB,
labels and parameters are translated and structured values
(lastname; firstname; additional names; prefixes etc.) are
converted appropriately with the risk of some (hopefully
unessential) information loss.  For labels of the vCard types ADR
and TEL, parameter translation is defined in
`bbdb-vcard-import-translation-table'.

If there is a REV element, it is stored in BBDB's creation-date in
newly created BBDB records, or discarded for existing ones.  Time
and time zone information from REV are stored there as well if
there are any, but are ignored by BBDB (v2.36).

VCard type prefixes (A.ADR:..., B.ADR:... etc.) are stripped off
and discarded from the following types: N, FN, NICKNAME, ORG (first
occurrence), ADR, TEL, EMAIL, URL, BDAY (first occurrence), NOTE.

VCard types that are prefixed `X-BBDB-' are stored in BBDB without
the prefix.

VCard type X-BBDB-ANNIVERSARY may contain (previously exported)
newline-separated non-birthday anniversaries that are meant to be
read by org-mode.

All remaining vCard types that don't match the regexp in
`bbdb-vcard-skip-on-import' and that have a non-empty value are
stored unaltered in the BBDB Notes alist where, for instance,
`TZ;VALUE=text:-05:00' is stored as `(tz\;value=text . "-05:00")'.
From the BBDB data fields AKA, Phones, Addresses, Net Addresses,
and Notes, duplicates are removed, respectively.

VCards found inside other vCards (as values of type AGENT) are
imported as well.


Handling of the individual types defined in RFC2426 during import
(assuming default label translation and no vCard type exclusion):
"
|----------------------+----------------------------------------|
| VCARD TYPE;          | STORAGE IN BBDB                        |
| PARAMETERS           |                                        |
|----------------------+----------------------------------------|
| VERSION              | -                                      |
|----------------------+----------------------------------------|
| N                    | First occurrence:                      |
|                      | Firstname                              |
|                      | Lastname                               |
|                      |                                        |
|                      | Rest:                                  |
|                      | AKAs (append)                          |
|----------------------+----------------------------------------|
| FN                   | AKAs (append)                          |
| NICKNAME             | AKAs (append)                          |
|----------------------+----------------------------------------|
| ORG                  | First occurrence:                      |
|                      | Company                                |
|                      |                                        |
|                      | Rest:                                  |
|                      | Notes<org                              |
|                      | (repeatedly)                           |
|----------------------+----------------------------------------|
| ADR;TYPE=x,HOME,y    | Addresses<Home                         |
| ADR;TYPE=x;TYPE=HOME | Addresses<Home                         |
| ADR;TYPE=x,WORK,y    | Addresses<Office                       |
| ADR;TYPE=x;TYPE=WORK | Addresses<Office                       |
| ADR;TYPE=x,y,z       | Addresses<x,y,z                        |
| ADR;TYPE=x;TYPE=y    | Addresses<x,y                          |
| ADR                  | Addresses<Office                       |
|----------------------+----------------------------------------|
| TEL;TYPE=x,HOME,y    | Phones<Home (append)                   |
| TEL;TYPE=x;TYPE=HOME | Phones<Home (append)                   |
| TEL;TYPE=x,WORK,y    | Phones<Office (append)                 |
| TEL;TYPE=x;TYPE=WORK | Phones<Office (append)                 |
| TEL;TYPE=x,CELL,y    | Phones<Mobile (append)                 |
| TEL;TYPE=x;TYPE=CELL | Phones<Mobile (append)                 |
| TEL;TYPE=x,y,z       | Phones<x,y,z (append)                  |
| TEL;TYPE=x;TYPE=y    | Phones<x,y (append)                    |
| TEL                  | Phones<Office (append)                 |
|----------------------+----------------------------------------|
| EMAIL;TYPE=x,y,z     | Net-Addresses (append)                 |
| URL                  | Notes<www                              |
|----------------------+----------------------------------------|
| BDAY                 | Notes<anniversary (append as birthday) |
| X-BBDB-ANNIVERSARY   | Notes<anniversary (append)             |
|----------------------+----------------------------------------|
| NOTE                 | Notes<notes (append)                   |
| REV                  | Notes<creation-date                    |
| CATEGORIES           | Notes<mail-alias (append)              |
| SORT-STRING          | Notes<sort-string                      |
| KEY                  | Notes<key                              |
| GEO                  | Notes<geo                              |
| TZ                   | Notes<tz                               |
| PHOTO                | Notes<photo                            |
| LABEL                | Notes<label                            |
| LOGO                 | Notes<logo                             |
| SOUND                | Notes<sound                            |
| TITLE                | Notes<title                            |
| ROLE                 | Notes<role                             |
| AGENT                | Notes<agent                            |
| MAILER               | Notes<mailer                           |
| UID                  | Notes<uid                              |
| PRODID               | Notes<prodid                           |
| CLASS                | Notes<class                            |
| X-foo                | Notes<x-foo                            |
| X-BBDB-bar           | Notes<bar                              |
|----------------------+----------------------------------------|
| anyJunK;a=x;b=y      | Notes<anyjunk;a=x;b=y                  |
|----------------------+----------------------------------------|
"

vCard Export
------------

VCard types N (only fields lastname, firstname) and FN both come
from BBDB's Name.

Members of BBDB field AKA are stored comma-separated under the
vCard type NICKNAME.

Labels of Addresses and Phones are translated as defined in
`bbdb-vcard-export-translation-table' into type parameters of
vCard types ADR and TEL, respectively.

In vCard type ADR, fields postbox and extended address are always
empty.  Newlines which subdivide BBDB Address fields are converted
into commas subdividing vCard ADR fields.

The value of 'anniversary in Notes is supposed to be subdivided by
newlines.  The birthday part (either just a date or a date followed
by \"birthday\") is stored under vCard type BDAY. The rest is
stored newline-separated in the non-standard vCard type
X-BBDB-ANNIVERSARY.

Field names listed in `bbdb-vcard-x-bbdb-candidates' are in the
exported vCard prepended by `X-BBDB-'.

The creation-date of the BBDB record is stored as vCard type REV.

Remaining members of BBDB Notes are exported to the vCard without
change.
