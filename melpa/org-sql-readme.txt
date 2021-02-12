This code stores org buffers in a variety of SQL databases for use in
processing org-mode data outside of Emacs where SQL operations might be more
appropriate.

The rough process by which this occurs is:
 1) query state of org files on disk and in db (if any) and classify
    files as 'updates', 'deletes', or 'inserts'
   - updates: a file on disk is also in the database but the path on disk has
     changed; this is the part that will be updated
   - deletes: a file in the db is not on disk; therefore delete from db
   - inserts: a file is on disk but not in the db, therefore insert into db
   - NOTE: file equality will be assessed using a hash algorithm (eg md5)
   - NOTE: in the case that a file on disk has changed and its path is also
     in the db, this file will be deleted and reinserted
 2) convert the updates/deletes/inserts into meta query language (MQL, an
    internal, database agnostic representation of the SQL statements to be
    sent)
   - inserts will be constructed using `org-element'/`org-ml' from target
     files on disk
 3) format MQL to database-specific SQL statements
 4) send SQL statements to the configured database

The code is roughly arranged as follows:
- constants
- customization variables
- stateless functions
- stateful IO functions
