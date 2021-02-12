
Importer of csv (comma separated value) text into Emacs’s bbdb database,
version 3+. Works out of the box with csv exported from Thunderbird, Gmail,
Linkedin, Outlook.com/hotmail, and probably others.
Easily extensible to handle new formats.

; Installation:

If you installed this file with a package manager, just

(require 'bbdb-csv-import)

Else, note the min versions of dependencies above in "Package-Requires:",
and load this file. The exact minimum bbdb version is unknown, something 3+.

; Basic Usage:

Back up bbdb by copying `bbdb-file' in case things go wrong.

Simply M-x `bbdb-csv-import-buffer' or `bbdb-csv-import-file'.
When called interactively, they prompt for file or buffer arguments.

Then view your bbdb records: M-x bbdb .* RET
If the import looks good save the bbdb database: C-x s (bbdb-save)

; Advanced usage / notes:

Tested to work with thunderbird, gmail, linkedin,
outlook.com/hotmail.com. For those programs, if it's exporter has an option
of what kind of csv format, choose it's own native format if available, if
not, choose an outlook compatible format. If you're exporting from some other
program and its csv exporter claims outlook compatibility, there is a good
chance it will work out of the box. If it doesn't, you can try to fix it as
described below, or the maintainer will be happy to help, just anonymize your
csv data using the M-x bbdb-csv-anonymize-current-buffer (make sure csv
buffer is the current one) and attach it to an email to the mailing list.

Duplicate contacts (according to email address) are skipped if
bbdb-allow-duplicates is nil (default). Any duplicates found are echoed at
the end of the import.

; Custom mapping of csv fields

If a field is handled wrong or you want to extend the program to handle a new
kind of csv format, you need to setup a custom field mapping variable. Use
the existing tables as an example. By default, we use a combination of most
predefined mappings, and look for all of their fields, but it is probably
best to avoid that kind of table when setting up your own as it is an
unnecessary complexity in that case. If you have a problem with data from a
supported export program, start by testing its specific mapping table instead
of the combined one. Here is a handy template to set each of the predefined
mapping tables if you would rather avoid the configure interface:

(setq bbdb-csv-import-mapping-table bbdb-csv-import-combined)
(setq bbdb-csv-import-mapping-table bbdb-csv-import-thunderbird)
(setq bbdb-csv-import-mapping-table bbdb-csv-import-gmail)
(setq bbdb-csv-import-mapping-table bbdb-csv-import-gmail-typed-email)
(setq bbdb-csv-import-mapping-table bbdb-csv-import-linkedin)
(setq bbdb-csv-import-mapping-table bbdb-csv-import-outlook-web)
(setq bbdb-csv-import-mapping-table bbdb-csv-import-outlook-typed-email)

The doc string for `bbdb-create-internal' may also be useful when creating a
mapping table. If you create a table for a program not not already supported,
please share it with the mailing list so it can be added to this program.
The maintainer should be able to help with any issues and may create a new
mapping table given sample data.

Mapping table tips:
* The repeat keyword expands numbered field names, based on the first
  field, as many times as they exist in the csv data.
* All mapping fields are optional. A simple mapping table could be
  (setq bbdb-csv-import-mapping-table '((:mail "Primary Email")))
* :xfields uses the csv field name to create custom fields in bbdb. It downcases
  the field name, and replaces spaces with "-", and repeating dashes with a
  single one . For example, if you had a csv named "Mail Alias" or "Mail - alias",
  you could add it to :xfields in a mapping table and it would become "mail-alias"
  in bbdb.

; Misc tips/troubleshooting:

- ASynK looks promising for syncing bbdb/google/outlook.
- The git repo contains a test folder with exactly tested version info and working
  test data.  Software, and especially online services are prone to changing how they
  export. Please send feedback if you run into problems.
- bbdb doesn't work if you delete the bbdb database file in
  the middle of an emacs session. If you want to empty the current bbdb database,
  do M-x bbdb then .* then C-u * d on the beginning of a record.
- After changing a mapping table variable, don't forget to re-execute
  (setq bbdb-csv-import-mapping-table ...) so that it propagates.
- :namelist is used instead of :name if 2 or more non-empty fields from :namelist are
  found in a record. If :name is empty, we try a single non-empty field from :namelist
  This sounds a bit strange, but it's to try and deal with Thunderbird idiosyncrasies.

; Bugs, patches, discussion, feedback

Patches and bugs are very welcome via https://gitlab.com/iankelling/bbdb-csv-import

Questions, feedback, or anything is very welcome at to the bbdb-csv-import mailing list
https://lists.iankelling.org/listinfo/bbdb-csv-import, no subscription needed to post via
bbdb-csv-import@lists.iankelling.org. The maintainer would probably be happy
to work on new features if something is missing.
