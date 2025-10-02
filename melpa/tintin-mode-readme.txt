This package provides a major mode for editing TinTin++ configuration
files. TinTin++ is a MUD client that uses scripting files with .tin
and .tt extensions.

Example TinTin++ code this mode highlights:

  #nop This is a comment
  #variable {hp} {100}
  #action {%0 tells you '%1'} {
      #if {"%1" == "hello"} {
          tell %0 Hello there!
      }
  }
  #function {heal} {
      #if {$hp < 50} {
          cast heal
      }
  }

Features:
- Enhanced indentation that handles empty lines and nested blocks
- Context-aware completion for commands, variables, and functions
- Smart newline handling for brace pairs
- Syntax highlighting for TinTin++ commands, variables, and functions
- Comment support (#nop commands)
- Imenu integration for navigation to functions and variables
- Electric pair insertion for braces and parentheses
- Outline mode support for code folding
- Which-function-mode support
