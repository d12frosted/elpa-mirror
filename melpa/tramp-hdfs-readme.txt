Access hadoop/hdfs over Tramp.
This program uses rest api/webhdfs to access hadoop server.

Configuration:
  Add the following lines to your .emacs:

  (add-to-list 'load-path "<<directory containing tramp-hdfs.el>>")
  (require 'tramp-hdfs);;; Code:

Usage:
  open /hdfs:root@node-1:/tmp/ in Emacs
  where root   is the user that you want to use
        node-1 is the name of the hadoop server
