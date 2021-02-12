csv.el provides functions for reading and parsing CSV (Comma Separated
Value) files.  It follows the format as defined in RFC 4180 "Common
Format and MIME Type for CSV Files" (http://tools.ietf.org/html/rfc4180).

Main routine is `csv-parse-buffer' which takes a buffer containing a
CSV file and converts its contents into list form.  The first line of
the CSV file can be interpreted as a list of keys.  In this case

Key1,Key 2,"Key3"
Value1a,Value1b,"Value1c"
Value2a,Value2b,"Very, very long Value
2c"

gets translated into a list of alists:

((("Key1" . "Value1a") ("Key 2" . "Value1b") ("Key3" . "Value1c"))
 (("Key1" . "Value2a") ("Key 2" . "Value2b") ("Key3" . "Very, very long Value\n2c")))

If the first line of the CSV file shall NOT be interpreted as a list of
key names the result is a list of lists:

(("Key1" "Key 2" "Key3")
 ("Value1a" "Value1b" "Value1c")
 ("Value2a" "Value2b" "Very, very long Value\n2c"))

The function `csv-insert-contents' demonstrates how to use
`csv-parse-buffer'.
