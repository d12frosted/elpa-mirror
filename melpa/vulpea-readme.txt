
Vulpea is a collection of functions for note taking based on `org'
and `org-roam'. In most cases, you should simply load `vulpea'
module to get all available functions.

Please note that loading this module automatically advices
`org-roam-capture--new-file' in order to automatically update
`org-roam' database in an efficient manner during `vulpea-create'
(e.g. instead of building cache for all changed files, only created
file is updated). In case you don't want it to happen, use the
following code after loading `vulpea' module:

  (advice-remove 'org-roam-capture--new-file
                 #'vulpea--capture-new-file)

Keep in mind that in such case you will need to manually update
`org-roam' database after using `vulpea-create' using
`org-roam-db-update-file' or `org-roam-db-build-cache'.
