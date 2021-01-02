
exiftool.el is an elisp wrapper around ExifTool.  ExifTool supports
reading and writing metadata in various formats including EXIF, XMP
and IPTC.

There is a significant overhead in loading ExifTool for every
command to be exected.  So, exiftool.el starts an ExifTool process
in the -stay_open mode, and passes all commands to it.  For more
about ExifTool's -stay_open mode, see
http://www.sno.phy.queensu.ca/~phil/exiftool/#performance
