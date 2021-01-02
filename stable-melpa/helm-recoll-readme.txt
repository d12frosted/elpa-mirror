
Helm interface for the recoll [1] desktop search tool.

[1] http://www.lesbonscomptes.com/recoll/

; Create recoll indexes:

First you have to create an index for each directory you want
to index, for this create some directories like "~/.recoll-<your-directory-name>"
then create "recoll.conf" config files in each directory containing
topdirs = <full/path/to/your/directory>
then run recollindex -c ~/.recoll-<your-directory-name>
to create index for each directory.
See https://bitbucket.org/medoc/recoll/wiki/MultipleIndexes
for more infos.
