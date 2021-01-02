This module adds support for RPM archives to archive-mode, so you
can open RPM files and see the files inside them just like you
would with a tarball or a zip file.

RPM files consist of metadata plus a compressed CPIO archive, so
this module relies on `archive-cpio'.
