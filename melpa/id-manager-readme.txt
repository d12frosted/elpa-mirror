ID-password management utility.
This utility manages ID-password list and generates passwords.

The ID-password DB is saved in the tab-separated file.  The default
file name of the DB `idm-database-file' is "~/.idm-db.gpg".
The file format is following:
  (name)^t(ID)^t(password)^t(Update date "YYYY/MM/DD")[^t(memo)]
. One can prepare an initial data or modify the data by hand or
the Excel.

Implicitly, this elisp program expects that the DB file is
encrypted by the some GPG encryption elisp, such as EasyPG or
alpaca.

Excuting the command `idm-open-list-command', you can open the
ID-password list buffer. Check the function `describe-bindings'.
