Purpose:

 Fast search for selected org-nodes and things outside.

 `org-index' (package and interactive function) helps to create and
 update an index-table with keywords; each line either points to a
 heading in org, references a folder outside of org or carries an url or
 a snippet of text.  When searching the index, the set of matching lines
 is updated with every keystroke; results are sorted by usage count and
 date, so that frequently or recently used entries appear first in the
 list of results.

 Please note, that org-index uses org-id throughout and therefore adds
 an id-property to all nodes in the index.

 In addition to the index table, org-index introduces the concept of
 references: These are decorated numbers (e.g. 'R237' or '--455--');
 they are well suited to be used outside of org, e.g. in folder names,
 ticket systems or on printed documents.  Use of references is optional.

 On first invocation org-index will assist you in creating the index
 table.  The index table is a normal org table, that needs to be stored
 in a dedicated node anywhere within your org files.

 To start using your index, invoke the subcommand 'add' to create index
 entries and 'occur' to find them.  The first call to 'add' will trigger
 the one-time assistant to create the index table.

 The set of columns within the index-table is fixed (see variable
 `oidx--all-columns') but can be arranged in any order you wish; just
 edit the index table.  The number of columns shown during occur is
 determined by `org-index-occur-columns'.  Using both features allows to
 ignore columns during search.


Setup:

 - org-index can be installed with package.el
 - Invoke `org-index'; on first run it will assist in creating your
   index table.

 - Optionally invoke `M-x org-customize', group 'Org Index', to tune
   its settings.


Further Information:

 - Watch the screencast at http://2484.de/org-index.html.
 - See the documentation of `org-index', which can also be read by
   invoking `org-index' and typing 'help'.
