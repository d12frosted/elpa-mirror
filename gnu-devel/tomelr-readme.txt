           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            EMACS-LISP LIBRARY FOR CONVERTING S-EXPRESSIONS
                                TO TOML
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[https://github.com/kaushalmodi/tomelr/actions/workflows/test.yml/badge.svg]
[https://elpa.gnu.org/packages/tomelr.svg]
[https://img.shields.io/badge/License-GPL%20v3-blue.svg]


[https://github.com/kaushalmodi/tomelr/actions/workflows/test.yml/badge.svg]
<https://github.com/kaushalmodi/tomelr/actions>

[https://elpa.gnu.org/packages/tomelr.svg]
<https://elpa.gnu.org/packages/tomelr.html>

[https://img.shields.io/badge/License-GPL%20v3-blue.svg]
<https://www.gnu.org/licenses/gpl-3.0>


1 Installation
══════════════

  `tomelr' is a library that will typically be auto-installed via
  another package requiring it.

  If you are developing a package and want to use this library, you can
  install it locally using Emacs `package.el' as follows as it's
  available via GNU ELPA:

  *M-x* `package-install' *RET* `tomelr' *RET*


2 How to develop using this library
═══════════════════════════════════

  1. Add this library in the /Package-Requires/ header. Here's an
     example from [`ox-hugo']:
     ┌────
     │ ;; Package-Requires: ((emacs "24.4") (org "9.0") tomelr))
     └────
  2. Require it.
     ┌────
     │ (require 'tomelr)
     └────
  3. Use the `tomelr-encode' function.
     Input
           Lisp data expression in Alist or Plist format
     Output
           TOML string


[`ox-hugo'] <https://ox-hugo.scripter.co>

2.1 Example
───────────

2.1.1 Alist data
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Here's an example of input *alist* that can be processed by
  `tomelr-encode'.
  ┌────
  │ '((title . "Some Title") ;String
  │   (author . ("fn ln"))   ;List
  │   (description . "some long description\nthat spans multiple\nlines") ;Multi-line string
  │   (date . 2022-03-14T01:49:00-04:00)    ;RFC 3339 date format
  │   (tags . ("tag1" "tag2"))
  │   (draft . "false")                     ;Boolean
  │   (versions . ((emacs . "28.1.50") (org . "release_9.5-532-gf6813d"))) ;Map or TOML Table
  │   (org_logbook . (((timestamp . 2022-04-08T14:53:00-04:00) ;Array of maps or TOML Tables
  │ 		   (note . "This note addition prompt shows up on typing the `C-c C-z` binding.\nSee [org#Drawers](https://www.gnu.org/software/emacs/manual/html_mono/org.html#Drawers)."))
  │ 		  ((timestamp . 2018-09-06T11:45:00-04:00)
  │ 		   (note . "Another note **bold** _italics_."))
  │ 		  ((timestamp . 2018-09-06T11:37:00-04:00)
  │ 		   (note . "A note `mono`.")))))
  └────


2.1.2 Plist data
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Here's an example of input *plist* that can be processed by
  `tomelr-encode'.
  ┌────
  │ '(:title "Some Title" ;String
  │   :author ("fn ln")   ;List
  │   :description "some long description\nthat spans multiple\nlines" ;Multi-line string
  │   :date 2022-03-14T01:49:00-04:00    ;RFC 3339 date format
  │   :tags ("tag1" "tag2")
  │   :draft "false"                     ;Boolean
  │   :versions (:emacs "28.1.50" :org "release_9.5-532-gf6813d") ;Map or TOML Table
  │   :org_logbook ((:timestamp 2022-04-08T14:53:00-04:00  ;Array of maps or TOML Tables
  │ 		 :note "This note addition prompt shows up on typing the `C-c C-z` binding.\nSee [org#Drawers](https://www.gnu.org/software/emacs/manual/html_mono/org.html#Drawers).")
  │ 		(:timestamp 2018-09-06T11:45:00-04:00
  │ 		 :note "Another note **bold** _italics_.")
  │ 		(:timestamp 2018-09-06T11:37:00-04:00
  │ 		 :note "A note `mono`.")))
  └────


2.1.3 TOML Output
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You will get the below TOML output for either of the above input data:
  ┌────
  │ title = "Some Title"
  │ author = ["fn ln"]
  │ description = """
  │ some long description
  │ that spans multiple
  │ lines"""
  │ date = 2022-03-14T01:49:00-04:00
  │ tags = ["tag1", "tag2"]
  │ draft = false
  │ [versions]
  │   emacs = "28.1.50"
  │   org = "release_9.5-532-gf6813d"
  │ [[org_logbook]]
  │   timestamp = 2022-04-08T14:53:00-04:00
  │   note = """
  │ This note addition prompt shows up on typing the `C-c C-z` binding.
  │ See [org#Drawers](https://www.gnu.org/software/emacs/manual/html_mono/org.html#Drawers)."""
  │ [[org_logbook]]
  │   timestamp = 2018-09-06T11:45:00-04:00
  │   note = "Another note **bold** _italics_."
  │ [[org_logbook]]
  │   timestamp = 2018-09-06T11:37:00-04:00
  │   note = "A note `mono`."
  └────


3 Limitations
═════════════

  Right now, the scalars and tables/array of tables does not get ordered
  in the right order automatically. So the user needs to ensure that the
  S-exp has all the scalars in the very beginning and then followed by
  TOML tables and arrays of tables.


3.1 Correct Use Example
───────────────────────

​:white_check_mark: Put the scalars first and then maps or tables.
  ┌────
  │ '((title . "Hello")           ;First the scalar
  │   (img . ((file . "foo.png")  ;Then the map or table
  │ 	  (credit . "Bar Zoo"))))
  └────
  ┌────
  │ title = "Hello"
  │ [img]
  │   file = "foo.png"
  │   credit = "Bar Zoo"
  └────


3.2 Incorrect Use Example
─────────────────────────

​:x: *Don't do this!*: Map or table first and then scalar.
  ┌────
  │ '((img . ((file . "foo.png")
  │ 	  (credit . "Bar Zoo")))
  │   (title . "Hello"))
  └────

  *Incorrect order!* Now the `title' became part of the `[img]' table!

  ┌────
  │ [img]
  │   file = "foo.png"
  │   credit = "Bar Zoo"
  │ title = "Hello"
  └────


4 Specification and Conversion Examples
═══════════════════════════════════════

  [Companion blog post]

  Following examples shown how S-expressions get translated to various
  TOML object types.


[Companion blog post] <https://scripter.co/defining-tomelr/>

4.1 Scalars
───────────

4.1.1 DONE Boolean
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <https://toml.io/en/v1.0.0#boolean>


◊ 4.1.1.1 S-expression

  ┌────
  │ '((bool1 . t)
  │   (bool2 . :false))
  └────


◊ 4.1.1.2 TOML

  ┌────
  │ bool1 = true
  │ bool2 = false
  └────


◊ 4.1.1.3 JSON Reference

  ┌────
  │ {
  │   "bool1": true,
  │   "bool2": false
  │ }
  └────


4.1.2 DONE Integer
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <https://toml.io/en/v1.0.0#integer>


◊ 4.1.2.1 S-expression

  ┌────
  │ '((int1 . +99)
  │   (int2 . 42)
  │   (int3 . 0)
  │   (int4 . -17))
  └────


◊ 4.1.2.2 TOML

  ┌────
  │ int1 = 99
  │ int2 = 42
  │ int3 = 0
  │ int4 = -17
  └────


◊ 4.1.2.3 JSON Reference

  ┌────
  │ {
  │   "int1": 99,
  │   "int2": 42,
  │   "int3": 0,
  │   "int4": -17
  │ }
  └────


4.1.3 DONE Float
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <https://toml.io/en/v1.0.0#float>


◊ 4.1.3.1 S-expression

  ┌────
  │ '((flt1 . +1.0)
  │   (flt2 . 3.1415)
  │   (flt3 . -0.01)
  │   (flt4 . 5e+22)
  │   (flt5 . 1e06)
  │   (flt6 . -2E-2)
  │   (flt7 . 6.626e-34))
  └────


◊ 4.1.3.2 TOML

  ┌────
  │ flt1 = 1.0
  │ flt2 = 3.1415
  │ flt3 = -0.01
  │ flt4 = 5e+22
  │ flt5 = 1000000.0
  │ flt6 = -0.02
  │ flt7 = 6.626e-34
  └────


◊ 4.1.3.3 JSON Reference

  ┌────
  │ {
  │   "flt1": 1.0,
  │   "flt2": 3.1415,
  │   "flt3": -0.01,
  │   "flt4": 5e+22,
  │   "flt5": 1000000.0,
  │   "flt6": -0.02,
  │   "flt7": 6.626e-34
  │ }
  └────


4.1.4 DONE String
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <https://toml.io/en/v1.0.0#string>


◊ 4.1.4.1 S-expression

  ┌────
  │ '((str1 . "Roses are red")
  │   (str2 . "Roses are red\nViolets are blue"))
  └────


◊ 4.1.4.2 TOML

  ┌────
  │ str1 = "Roses are red"
  │ str2 = """
  │ Roses are red
  │ Violets are blue"""
  └────


◊ 4.1.4.3 JSON Reference

  ┌────
  │ {
  │   "str1": "Roses are red",
  │   "str2": "Roses are red\nViolets are blue"
  │ }
  └────


4.1.5 DONE Date
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <https://toml.io/en/v1.0.0#local-date>


◊ 4.1.5.1 S-expression

  ┌────
  │ '((ld1 . "1979-05-27"))
  └────


◊ 4.1.5.2 TOML

  ┌────
  │ ld1 = 1979-05-27
  └────


◊ 4.1.5.3 JSON Reference

  ┌────
  │ {
  │   "ld1": "1979-05-27"
  │ }
  └────


4.1.6 DONE Date + Time with Offset
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  <https://toml.io/en/v1.0.0#offset-date-time>


◊ 4.1.6.1 S-expression

  ┌────
  │ '((odt1 . "1979-05-27T07:32:00Z")
  │   (odt2 . "1979-05-27T00:32:00-07:00")
  │   (odt3 . "1979-05-27T00:32:00.999999-07:00"))
  └────


◊ 4.1.6.2 TOML

  ┌────
  │ odt1 = 1979-05-27T07:32:00Z
  │ odt2 = 1979-05-27T00:32:00-07:00
  │ odt3 = 1979-05-27T00:32:00.999999-07:00
  └────


◊ 4.1.6.3 JSON Reference

  ┌────
  │ {
  │   "odt1": "1979-05-27T07:32:00Z",
  │   "odt2": "1979-05-27T00:32:00-07:00",
  │   "odt3": "1979-05-27T00:32:00.999999-07:00"
  │ }
  └────


4.2 DONE Nil
────────────

◊ 4.2.0.1 S-expression

  ┌────
  │ '((key1 . 123)
  │   (key2 . nil)
  │   (key3 . "abc")
  │   (key4 . :false)
  │   (key5 . t))
  └────


◊ 4.2.0.2 TOML

  ┌────
  │ key1 = 123
  │ key3 = "abc"
  │ key4 = false
  │ key5 = true
  └────


◊ 4.2.0.3 JSON Reference

  ┌────
  │ {
  │   "key1": 123,
  │   "key2": null,
  │   "key3": "abc",
  │   "key4": false,
  │   "key5": true
  │ }
  └────


4.3 TOML Arrays: Lists
──────────────────────

  <https://toml.io/en/v1.0.0#array>


4.3.1 DONE Plain Arrays
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 4.3.1.1 S-expression

  ┌────
  │ '((integers . (1 2 3))
  │   (integers2 . [1 2 3])                 ;Same as above
  │   (colors . ("red" "yellow" "green"))
  │   ;; Mixed-type arrays are allowed
  │   (numbers . (0.1 0.2 0.5 1 2 5)))
  └────


◊ 4.3.1.2 TOML

  ┌────
  │ integers = [1, 2, 3]
  │ integers2 = [1, 2, 3]
  │ colors = ["red", "yellow", "green"]
  │ numbers = [0.1, 0.2, 0.5, 1, 2, 5]
  └────


◊ 4.3.1.3 JSON Reference

  ┌────
  │ {
  │   "integers": [
  │     1,
  │     2,
  │     3
  │   ],
  │   "integers2": [
  │     1,
  │     2,
  │     3
  │   ],
  │   "colors": [
  │     "red",
  │     "yellow",
  │     "green"
  │   ],
  │   "numbers": [
  │     0.1,
  │     0.2,
  │     0.5,
  │     1,
  │     2,
  │     5
  │   ]
  │ }
  └────


4.3.2 DONE Array of Arrays
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 4.3.2.1 S-expression

  ┌────
  │ '((nested_arrays_of_ints . [(1 2) (3 4 5)])
  │   (nested_mixed_array . [(1 2) ("a" "b" "c")]))
  └────


◊ 4.3.2.2 TOML

  ┌────
  │ nested_arrays_of_ints = [[1, 2], [3, 4, 5]]
  │ nested_mixed_array = [[1, 2], ["a", "b", "c"]]
  └────


◊ 4.3.2.3 JSON Reference

  ┌────
  │ {
  │   "nested_arrays_of_ints": [
  │     [
  │       1,
  │       2
  │     ],
  │     [
  │       3,
  │       4,
  │       5
  │     ]
  │   ],
  │   "nested_mixed_array": [
  │     [
  │       1,
  │       2
  │     ],
  │     [
  │       "a",
  │       "b",
  │       "c"
  │     ]
  │   ]
  │ }
  └────


4.4 TOML Tables: Maps or Dictionaries or Hash Tables
────────────────────────────────────────────────────

  <https://toml.io/en/v1.0.0#table>


4.4.1 DONE Basic TOML Tables
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 4.4.1.1 S-expression

  ┌────
  │ '((table-1 . ((key1 . "some string")
  │ 	      (key2 . 123)))
  │   (table-2 . ((key1 . "another string")
  │ 	      (key2 . 456))))
  └────


◊ 4.4.1.2 TOML

  ┌────
  │ [table-1]
  │   key1 = "some string"
  │   key2 = 123
  │ [table-2]
  │   key1 = "another string"
  │   key2 = 456
  └────


◊ 4.4.1.3 JSON Reference

  ┌────
  │ {
  │   "table-1": {
  │     "key1": "some string",
  │     "key2": 123
  │   },
  │   "table-2": {
  │     "key1": "another string",
  │     "key2": 456
  │   }
  │ }
  └────


4.4.2 DONE Nested TOML Tables
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 4.4.2.1 S-expression

  ┌────
  │ '((table-1 . ((table-1a . ((key1 . "some string")
  │ 			   (key2 . 123)))
  │ 	      (table-1b . ((key1 . "foo")
  │ 			   (key2 . 98765)))))
  │   (menu . (("auto weight" . ((weight . 4033)
  │ 			     (identifier . "foo"))))))
  └────


◊ 4.4.2.2 TOML

  ┌────
  │ [table-1]
  │   [table-1.table-1a]
  │     key1 = "some string"
  │     key2 = 123
  │   [table-1.table-1b]
  │     key1 = "foo"
  │     key2 = 98765
  │ [menu]
  │   [menu."auto weight"]
  │     weight = 4033
  │     identifier = "foo"
  └────


◊ 4.4.2.3 JSON Reference

  ┌────
  │ {
  │   "table-1": {
  │     "table-1a": {
  │       "key1": "some string",
  │       "key2": 123
  │     },
  │     "table-1b": {
  │       "key1": "foo",
  │       "key2": 98765
  │     }
  │   },
  │   "menu": {
  │     "auto weight": {
  │       "weight": 4033,
  │       "identifier": "foo"
  │     }
  │   }
  │ }
  └────


4.5 TOML Array of Tables: Lists of Maps
───────────────────────────────────────

  <https://toml.io/en/v1.0.0#array-of-tables>


4.5.1 DONE Basic Array of Tables
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 4.5.1.1 S-expression

  ┌────
  │ '((products . (((name . "Hammer")
  │ 		(sku . 738594937))
  │ 	       ()
  │ 	       ((name . "Nail")
  │ 		(sku . 284758393)
  │ 		(color . "gray"))))
  │   (org_logbook . (((timestamp . 2022-04-08T14:53:00-04:00)
  │ 		   (note . "This note addition prompt shows up on typing the `C-c C-z` binding.\nSee [org#Drawers](https://www.gnu.org/software/emacs/manual/html_mono/org.html#Drawers)."))
  │ 		  ((timestamp . 2018-09-06T11:45:00-04:00)
  │ 		   (note . "Another note **bold** _italics_."))
  │ 		  ((timestamp . 2018-09-06T11:37:00-04:00)
  │ 		   (note . "A note `mono`.")))))
  └────


◊ 4.5.1.2 TOML

  ┌────
  │ [[products]]
  │   name = "Hammer"
  │   sku = 738594937
  │ [[products]]
  │ [[products]]
  │   name = "Nail"
  │   sku = 284758393
  │   color = "gray"
  │ [[org_logbook]]
  │   timestamp = 2022-04-08T14:53:00-04:00
  │   note = """
  │ This note addition prompt shows up on typing the `C-c C-z` binding.
  │ See [org#Drawers](https://www.gnu.org/software/emacs/manual/html_mono/org.html#Drawers)."""
  │ [[org_logbook]]
  │   timestamp = 2018-09-06T11:45:00-04:00
  │   note = "Another note **bold** _italics_."
  │ [[org_logbook]]
  │   timestamp = 2018-09-06T11:37:00-04:00
  │   note = "A note `mono`."
  └────


◊ 4.5.1.3 JSON Reference

  ┌────
  │ {
  │   "products": [
  │     {
  │       "name": "Hammer",
  │       "sku": 738594937
  │     },
  │     null,
  │     {
  │       "name": "Nail",
  │       "sku": 284758393,
  │       "color": "gray"
  │     }
  │   ],
  │   "org_logbook": [
  │     {
  │       "timestamp": "2022-04-08T14:53:00-04:00",
  │       "note": "This note addition prompt shows up on typing the `C-c C-z` binding.\nSee [org#Drawers](https://www.gnu.org/software/emacs/manual/html_mono/org.html#Drawers)."
  │     },
  │     {
  │       "timestamp": "2018-09-06T11:45:00-04:00",
  │       "note": "Another note **bold** _italics_."
  │     },
  │     {
  │       "timestamp": "2018-09-06T11:37:00-04:00",
  │       "note": "A note `mono`."
  │     }
  │   ]
  │ }
  └────


4.5.2 DONE Nested Array of Tables
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 4.5.2.1 S-expression

  ┌────
  │ '((fruits . (((name . "apple")
  │ 	      (physical . ((color . "red")
  │ 			   (shape . "round")))
  │ 	      (varieties . (((name . "red delicious"))
  │ 			    ((name . "granny smith")))))
  │ 	     ((name . "banana")
  │ 	      (varieties . (((name . "plantain"))))))))
  └────


◊ 4.5.2.2 TOML

  ┌────
  │ [[fruits]]
  │   name = "apple"
  │   [fruits.physical]
  │     color = "red"
  │     shape = "round"
  │   [[fruits.varieties]]
  │     name = "red delicious"
  │   [[fruits.varieties]]
  │     name = "granny smith"
  │ [[fruits]]
  │   name = "banana"
  │   [[fruits.varieties]]
  │     name = "plantain"
  └────


◊ 4.5.2.3 JSON Reference

  ┌────
  │ {
  │   "fruits": [
  │     {
  │       "name": "apple",
  │       "physical": {
  │         "color": "red",
  │         "shape": "round"
  │       },
  │       "varieties": [
  │         {
  │           "name": "red delicious"
  │         },
  │         {
  │           "name": "granny smith"
  │         }
  │       ]
  │     },
  │     {
  │       "name": "banana",
  │       "varieties": [
  │         {
  │           "name": "plantain"
  │         }
  │       ]
  │     }
  │   ]
  │ }
  └────


4.6 DONE Combinations of all of the above
─────────────────────────────────────────

4.6.1 S-expression
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ '((title . "Keyword Collection")
  │   (author . ("firstname1 lastname1" "firstname2 lastname2" "firstname3 lastname3"))
  │   (aliases . ("/posts/keyword-concatenation" "/posts/keyword-merging"))
  │   (images . ("image 1" "image 2"))
  │   (keywords . ("keyword1" "keyword2" "three word keywords3"))
  │   (outputs . ("html" "json"))
  │   (series . ("series 1" "series 2"))
  │   (tags . ("mega front-matter" "keys" "collection" "concatenation" "merging"))
  │   (categories . ("cat1" "cat2"))
  │   (videos . ("video 1" "video 2"))
  │   (draft . :false)
  │   (categories_weight . 999)
  │   (tags_weight . 88)
  │   (weight . 7)
  │   (myfoo . "bar")
  │   (mybaz . "zoo")
  │   (alpha . 1)
  │   (beta . "two words")
  │   (gamma . 10)
  │   (animals . ("dog" "cat" "penguin" "mountain gorilla"))
  │   (strings-symbols . ("abc" "def" "two words"))
  │   (integers . (123 -5 17 1234))
  │   (floats . (12.3 -5.0 -1.7e-05))
  │   (booleans . (t :false))
  │   (dog . ((legs . 4)
  │ 	  (eyes . 2)
  │ 	  (friends . ("poo" "boo"))))
  │   (header . ((image . "projects/Readingabook.jpg")
  │ 	     (caption . "stay hungry stay foolish")))
  │   (collection . ((nothing . :false)
  │ 		 (nonnil . t)
  │ 		 (animals . ("dog" "cat" "penguin" "mountain gorilla"))
  │ 		 (strings-symbols . ("abc" "def" "two words"))
  │ 		 (integers . (123 -5 17 1234))
  │ 		 (floats . (12.3 -5.0 -1.7e-05))
  │ 		 (booleans . (t :false))))
  │   (menu . ((foo . ((identifier . "keyword-collection")
  │ 		   (weight . 10)))))
  │   (resources . (((src . "*.png")
  │ 		 (name . "my-cool-image-:counter")
  │ 		 (title . "The Image #:counter")
  │ 		 (params . ((foo . "bar")
  │ 			    (floats . (12.3 -5.0 -1.7e-05))
  │ 			    (strings-symbols . ("abc" "def" "two words"))
  │ 			    (animals . ("dog" "cat" "penguin" "mountain gorilla"))
  │ 			    (integers . (123 -5 17 1234))
  │ 			    (booleans . (t :false))
  │ 			    (byline . "bep"))))
  │ 		((src . "image-4.png")
  │ 		 (title . "The Fourth Image"))
  │ 		((src . "*.jpg")
  │ 		 (title . "JPEG Image #:counter")))))
  └────


4.6.2 TOML
╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ title = "Keyword Collection"
  │ author = ["firstname1 lastname1", "firstname2 lastname2", "firstname3 lastname3"]
  │ aliases = ["/posts/keyword-concatenation", "/posts/keyword-merging"]
  │ images = ["image 1", "image 2"]
  │ keywords = ["keyword1", "keyword2", "three word keywords3"]
  │ outputs = ["html", "json"]
  │ series = ["series 1", "series 2"]
  │ tags = ["mega front-matter", "keys", "collection", "concatenation", "merging"]
  │ categories = ["cat1", "cat2"]
  │ videos = ["video 1", "video 2"]
  │ draft = false
  │ categories_weight = 999
  │ tags_weight = 88
  │ weight = 7
  │ myfoo = "bar"
  │ mybaz = "zoo"
  │ alpha = 1
  │ beta = "two words"
  │ gamma = 10
  │ animals = ["dog", "cat", "penguin", "mountain gorilla"]
  │ strings-symbols = ["abc", "def", "two words"]
  │ integers = [123, -5, 17, 1234]
  │ floats = [12.3, -5.0, -1.7e-05]
  │ booleans = [true, false]
  │ [dog]
  │   legs = 4
  │   eyes = 2
  │   friends = ["poo", "boo"]
  │ [header]
  │   image = "projects/Readingabook.jpg"
  │   caption = "stay hungry stay foolish"
  │ [collection]
  │   nothing = false
  │   nonnil = true
  │   animals = ["dog", "cat", "penguin", "mountain gorilla"]
  │   strings-symbols = ["abc", "def", "two words"]
  │   integers = [123, -5, 17, 1234]
  │   floats = [12.3, -5.0, -1.7e-05]
  │   booleans = [true, false]
  │ [menu]
  │   [menu.foo]
  │     identifier = "keyword-collection"
  │     weight = 10
  │ [[resources]]
  │   src = "*.png"
  │   name = "my-cool-image-:counter"
  │   title = "The Image #:counter"
  │   [resources.params]
  │     foo = "bar"
  │     floats = [12.3, -5.0, -1.7e-05]
  │     strings-symbols = ["abc", "def", "two words"]
  │     animals = ["dog", "cat", "penguin", "mountain gorilla"]
  │     integers = [123, -5, 17, 1234]
  │     booleans = [true, false]
  │     byline = "bep"
  │ [[resources]]
  │   src = "image-4.png"
  │   title = "The Fourth Image"
  │ [[resources]]
  │   src = "*.jpg"
  │   title = "JPEG Image #:counter"
  └────


4.6.3 JSON Reference
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ {
  │   "title": "Keyword Collection",
  │   "author": [
  │     "firstname1 lastname1",
  │     "firstname2 lastname2",
  │     "firstname3 lastname3"
  │   ],
  │   "aliases": [
  │     "/posts/keyword-concatenation",
  │     "/posts/keyword-merging"
  │   ],
  │   "images": [
  │     "image 1",
  │     "image 2"
  │   ],
  │   "keywords": [
  │     "keyword1",
  │     "keyword2",
  │     "three word keywords3"
  │   ],
  │   "outputs": [
  │     "html",
  │     "json"
  │   ],
  │   "series": [
  │     "series 1",
  │     "series 2"
  │   ],
  │   "tags": [
  │     "mega front-matter",
  │     "keys",
  │     "collection",
  │     "concatenation",
  │     "merging"
  │   ],
  │   "categories": [
  │     "cat1",
  │     "cat2"
  │   ],
  │   "videos": [
  │     "video 1",
  │     "video 2"
  │   ],
  │   "draft": false,
  │   "categories_weight": 999,
  │   "tags_weight": 88,
  │   "weight": 7,
  │   "myfoo": "bar",
  │   "mybaz": "zoo",
  │   "alpha": 1,
  │   "beta": "two words",
  │   "gamma": 10,
  │   "animals": [
  │     "dog",
  │     "cat",
  │     "penguin",
  │     "mountain gorilla"
  │   ],
  │   "strings-symbols": [
  │     "abc",
  │     "def",
  │     "two words"
  │   ],
  │   "integers": [
  │     123,
  │     -5,
  │     17,
  │     1234
  │   ],
  │   "floats": [
  │     12.3,
  │     -5.0,
  │     -1.7e-05
  │   ],
  │   "booleans": [
  │     true,
  │     false
  │   ],
  │   "dog": {
  │     "legs": 4,
  │     "eyes": 2,
  │     "friends": [
  │       "poo",
  │       "boo"
  │     ]
  │   },
  │   "header": {
  │     "image": "projects/Readingabook.jpg",
  │     "caption": "stay hungry stay foolish"
  │   },
  │   "collection": {
  │     "nothing": false,
  │     "nonnil": true,
  │     "animals": [
  │       "dog",
  │       "cat",
  │       "penguin",
  │       "mountain gorilla"
  │     ],
  │     "strings-symbols": [
  │       "abc",
  │       "def",
  │       "two words"
  │     ],
  │     "integers": [
  │       123,
  │       -5,
  │       17,
  │       1234
  │     ],
  │     "floats": [
  │       12.3,
  │       -5.0,
  │       -1.7e-05
  │     ],
  │     "booleans": [
  │       true,
  │       false
  │     ]
  │   },
  │   "menu": {
  │     "foo": {
  │       "identifier": "keyword-collection",
  │       "weight": 10
  │     }
  │   },
  │   "resources": [
  │     {
  │       "src": "*.png",
  │       "name": "my-cool-image-:counter",
  │       "title": "The Image #:counter",
  │       "params": {
  │         "foo": "bar",
  │         "floats": [
  │           12.3,
  │           -5.0,
  │           -1.7e-05
  │         ],
  │         "strings-symbols": [
  │           "abc",
  │           "def",
  │           "two words"
  │         ],
  │         "animals": [
  │           "dog",
  │           "cat",
  │           "penguin",
  │           "mountain gorilla"
  │         ],
  │         "integers": [
  │           123,
  │           -5,
  │           17,
  │           1234
  │         ],
  │         "booleans": [
  │           true,
  │           false
  │         ],
  │         "byline": "bep"
  │       }
  │     },
  │     {
  │       "src": "image-4.png",
  │       "title": "The Fourth Image"
  │     },
  │     {
  │       "src": "*.jpg",
  │       "title": "JPEG Image #:counter"
  │     }
  │   ]
  │ }
  └────


4.7 DONE P-lists
────────────────

◊ 4.7.0.1 S-expression

  ┌────
  │ '(:int 123
  │   :remove_this_key  nil
  │   :str "abc"
  │   :bool_false :false
  │   :bool_true t
  │   :int_list (1 2 3)
  │   :str_list ("a" "b" "c")
  │   :bool_list (t :false t :false)
  │   :list_of_lists [(1 2) (3 4 5)]
  │   :map (:key1 123
  │ 	:key2 "xyz")
  │   :list_of_maps [(:key1 123
  │ 		  :key2 "xyz")
  │ 		 (:key1 567
  │ 		  :key2 "klm")])
  └────


◊ 4.7.0.2 TOML

  ┌────
  │ int = 123
  │ str = "abc"
  │ bool_false = false
  │ bool_true = true
  │ int_list = [1, 2, 3]
  │ str_list = ["a", "b", "c"]
  │ bool_list = [true, false, true, false]
  │ list_of_lists = [[1, 2], [3, 4, 5]]
  │ [map]
  │   key1 = 123
  │   key2 = "xyz"
  │ [[list_of_maps]]
  │   key1 = 123
  │   key2 = "xyz"
  │ [[list_of_maps]]
  │   key1 = 567
  │   key2 = "klm"
  └────


◊ 4.7.0.3 JSON Reference

  ┌────
  │ {
  │   "int": 123,
  │   "remove_this_key": null,
  │   "str": "abc",
  │   "bool_false": false,
  │   "bool_true": true,
  │   "int_list": [
  │     1,
  │     2,
  │     3
  │   ],
  │   "str_list": [
  │     "a",
  │     "b",
  │     "c"
  │   ],
  │   "bool_list": [
  │     true,
  │     false,
  │     true,
  │     false
  │   ],
  │   "list_of_lists": [
  │     [
  │       1,
  │       2
  │     ],
  │     [
  │       3,
  │       4,
  │       5
  │     ]
  │   ],
  │   "map": {
  │     "key1": 123,
  │     "key2": "xyz"
  │   },
  │   "list_of_maps": [
  │     {
  │       "key1": 123,
  │       "key2": "xyz"
  │     },
  │     {
  │       "key1": 567,
  │       "key2": "klm"
  │     }
  │   ]
  │ }
  └────


5 Development
═════════════

5.1 Running Tests
─────────────────

5.1.1 Run all tests
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ make test
  └────


5.1.2 Run tests matching a specific string
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Run `make test MATCH=<string>'. For example, to run all tests where
  the name matches "scalar" completely or partially, run:

  ┌────
  │ make test MATCH=scalar
  └────


6 Credit
════════

  This library started off by extracting the JSON Encoding pieces from
  the Emacs core library [*json.el*].

  It was then refactored to meet the specification defined below.


[*json.el*]
<https://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/json.el>


7 References
════════════

  • [TOML v1.0.0 Spec]
  • [Online JSON/TOML/YAML converter]


[TOML v1.0.0 Spec] <https://toml.io/en/v1.0.0/>

[Online JSON/TOML/YAML converter] <https://toolkit.site/format.html>
