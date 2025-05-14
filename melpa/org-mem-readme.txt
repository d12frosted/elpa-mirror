A cache of metadata about the structure of all your Org files - headings,
links and so on.

Builds quickly, so that there is no need to persist data
across sessions.

Provides two independent APIs:

 - Emacs Lisp: regularly named accessors such as `org-mem-entry-olpath',
               `org-mem-link-pos', `org-mem-all-id-nodes' etc

 - SQL: an in-memory SQLite database that can be queried like
        (emacsql (org-mem-roamy-db) [:select * :from links :limit 10])
