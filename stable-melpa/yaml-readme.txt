yaml.el contains the code for parsing YAML natively in Elisp with
no dependencies.  The main function to parse YAML provided is
`yaml-parse-string'.  The following are some examples of its usage:

(yaml-parse-string "key1: value1\nkey2: value2")
(yaml-parse-string "key1: value1\nkey2: value2" :object-type 'alist)
(yaml-parse-string "numbers: [1, 2, 3]" :sequence-type 'list)
