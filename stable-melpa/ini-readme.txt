
This converts .INI file format into an associated list and vice versa.
- The original implementation was done by Daniel Ness.
- Pierre Rouleau re-implemented the code, keeping the function names
  but with  a different implementation and with an API change.
  - `ini-decode':
    - Simplified API: its argument is the name of the file,
      instead of a string that is the content of the file.
      - the new implementation does not create a list of line strings,
        which could potentially be quite expensive; instead it uses a
        larger regexp to search for syntactic element and a FSM logic to
        process matched strings.  The regexp is more complex but described
        in comments.
    - Supports a wider syntax:
      - Comments can now start with # or ;
      - Supports multi-line values: values expressed in
        multiple line express a compound value that is a list of strings.
    - Supports files with key-value pairs without a section: the section
      is named after the file base name.
 - `ini-encode':
   - Supports the more complex data structure with list values.
 - `ini-store': a new function that stores the data structure directly into
    a file with append and overwrite capability.

The code hierarchy follows:

- `ini-decode'
  - `ini--add-to-alist'
    - `ini--add-to-keys'
  - `ini--add-extra-value'

- `ini-store'
  - `ini-encode'
