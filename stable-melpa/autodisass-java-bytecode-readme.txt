This package enables automatic disassembly of Java bytecode.

It was inspired by a blog post of Christopher Wellons:
   http://nullprogram.com/blog/2012/08/01/

Disassembly can happen in two cases:
(a) when opening a Java .class file
(b) when disassembling a .class file inside a jar

In any case, `javap' must be installed in the system for this
extension to have any effect, since that is the tool that actually
performs the disassembly.
