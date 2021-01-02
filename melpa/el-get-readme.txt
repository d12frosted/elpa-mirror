
Version String are now inspired by how Emacs itself numbers its version.
First is the major version number, then a dot, then the minor version
number.  The minor version number is 0 when still developping the next
major version.

So 2.0 is a developer release while 2.1 will be the next stable release.

Please note that this versioning policy has been picked while backing
1.2~dev, so 1.0 was a "stable" release in fact.  Ah, history.

In addition to the version, you can also get the exact git revision
by running M-x `el-get-self-checksum'. You should provide this
checksum when seeking support or reporting a bug, so that the
developers will know exactly which version you are using.
