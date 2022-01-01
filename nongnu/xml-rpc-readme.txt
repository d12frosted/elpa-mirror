Table of Contents
─────────────────

1. Commentary:
2. Installation:
3. Requirements
4. Bug reports
5. Representing data types
6. Examples
.. 1. Normal synchronous operation
.. 2. Asynchronous example (cb-foo will be called when the methods returns)
.. 3. Some real world working examples for fun and play
..... 1. Check the temperature (celsius) outside jonas@codefactory.se's apartment
..... 2. Fetch the latest NetBSD news the past 5 days from O'reillynet


1 Commentary:
═════════════

  This is an XML-RPC client implementation in elisp, capable of both
  synchronous and asynchronous method calls (using the url package's
  async retrieval functionality).  XML-RPC is remote procedure calls
  over HTTP using XML to describe the function call and return values.

  xml-rpc.el represents XML-RPC datatypes as lisp values, automatically
  converting to and from the XML datastructures as needed, both for
  method parameters and return values, making using XML-RPC methods
  fairly transparent to the lisp code.


2 Installation:
═══════════════

  If you use ELPA (<http://tromey.com/elpa>), you can install via the
  M-x package-list-packages interface. This is preferrable as you will
  have access to updates automatically.

  Otherwise, just make sure this file in your load-path (usually
  `~/.emacs.d' is included) and put
  ┌────
  │ (require 'xml-rpc) 
  └────
  in your `~/.emacs' or `~/.emacs.d/init.el' file.


3 Requirements
══════════════

  xml-rpc.el uses the url package for http handling and `xml.el' for XML
  parsing or, if you have Emacs 27 with `libxml' included, `libxml'. url
  is a part of the W3 browser package.  The url package that is part of
  Emacs 22+ works great.


4 Bug reports
═════════════

  Please use `M-x xml-rpc-submit-bug-report' to report bugs directly to
  the maintainer, or use [github's issue system].


[github's issue system]
<https://github.com/xml-rpc-el/xml-rpc-el/issues>


5 Representing data types
═════════════════════════

  XML-RPC datatypes are represented as follows

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   type          data                                   
   int           42                                     
   float/double  42.0                                   
   string        "foo"                                  
   base64        (list :base64                          
                 (base64-encode-string "hello" t))      
                 '(:base64 "aGVsbG8=")                  
   array         '(1 2 3 4)   '(1 2 3 (4.1 4.2))  [ ]   
                 '(:array (("not" "a") ("struct" "!"))) 
   struct        '(("name" . "daniel")                  
                 ("height" . 6.1))                      
   dateTime      '(:datetime (1234 124))                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


6 Examples
══════════

  Here follows some examples demonstrating the use of xml-rpc.el


6.1 Normal synchronous operation
────────────────────────────────

  ┌────
  │ (xml-rpc-method-call "http://localhost:80/RPC" 'foo-method foo bar zoo)
  └────


6.2 Asynchronous example (cb-foo will be called when the methods returns)
─────────────────────────────────────────────────────────────────────────

  ┌────
  │ (defun cb-foo (foo)
  │   (print (format "%s" foo)))
  │ 
  │ (xml-rpc-method-call-async 'cb-foo "http://localhost:80/RPC"
  │ 			   'foo-method foo bar zoo)
  └────


6.3 Some real world working examples for fun and play
─────────────────────────────────────────────────────

6.3.1 Check the temperature (celsius) outside jonas@codefactory.se's apartment
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (xml-rpc-method-call
  │      "http://flint.bengburken.net:80/xmlrpc/onewire_temp.php"
  │      'onewire.getTemp)
  └────


6.3.2 Fetch the latest NetBSD news the past 5 days from O'reillynet
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (xml-rpc-method-call "http://www.oreillynet.com/meerkat/xml-rpc/server.php"
  │ 		  'meerkat.getItems
  │ 		  '(("channel" . 1024)
  │ 		    ("search" . "/NetBSD/")
  │ 		    ("time_period" . "5DAY")
  │ 		    ("ids" . 0)
  │ 		    ("descriptions" . 200)
  │ 		    ("categories" . 0)
  │ 		    ("channels" . 0)
  │ 		    ("dates" . 0)
  │ 		    ("num_items" . 5)))
  └────
