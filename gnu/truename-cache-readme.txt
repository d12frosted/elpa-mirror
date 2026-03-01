This library provides two things:

1. A caching alternative to `file-truename'.

   See docstring of `truename-cache-get'.

2. An alternative to `directory-files-recursively' that pre-populates said
   cache and returns truenames while minimizing calls to `file-truename'.

   See docstring of `truename-cache-collect-files-and-attributes'.