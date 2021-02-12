Automatic programming language detection using pre-trained random
forest classifier.

Supported languages:

 * ada
 * awk
 * c
 * clojure
 * cpp
 * csharp
 * css
 * dart
 * delphi
 * emacslisp
 * erlang
 * fortran
 * fsharp
 * go
 * groovy
 * haskell
 * html
 * java
 * javascript
 * json
 * latex
 * lisp
 * lua
 * matlab
 * objc
 * perl
 * php
 * prolog
 * python
 * r
 * ruby
 * rust
 * scala
 * shell
 * smalltalk
 * sql
 * swift
 * visualbasic
 * xml

Entrypoints:

 * language-detection-buffer
   - When called interactively, prints the language of the current
     buffer to the echo area
   - When called non-interactively, returns the language of the
     current buffer
 * language-detection-string
   - Non-interactive function, returns the language of its argument
