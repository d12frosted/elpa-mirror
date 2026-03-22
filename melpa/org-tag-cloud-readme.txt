This package is designed to allow you to maintain a "tag cloud"
of all the tags stored within a particular file.

The cloud is rendered as an `org-mode' table and can be updated
automatically when the file is saved.  The rendered table will
make each tag clickable via a newly-installed protocol handler
for links of the form [[tag::foo]].

There are three main functions of interest:

`org-tag-cloud-insert' - Insert a tag cloud at the current point.

`org-tag-cloud-update' - Update an existing cloud.

`org-tag-cloud-save-hook' - Something to add to save-hook to
automate this package.
