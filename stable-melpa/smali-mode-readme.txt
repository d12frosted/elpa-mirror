
A major mode for editing Smali files, the human-readable
representation of Dalvik bytecode used by the smali/baksmali
assembler/disassembler for Android.

Features:
- Syntax highlighting for Dalvik opcodes, directives, access
  modifiers, type descriptors, registers, and labels
- Imenu support for methods, fields, and annotations
- Comment syntax for `#' (standard) and `//' (non-standard)

Usage:
The mode activates automatically for files ending in `.smali'.
To enable it manually: M-x smali-mode

For the Smali language specification, see:
https://source.android.com/docs/core/runtime/dalvik-bytecode
