This package enables automatic disassembly of LLVM bitcode, when
opening an LLVM .bc file.

When `llvm-mode' is available, it is automatically selected for the
current LLVM bitcode-containing buffer.

In any case, `llvm-dis' must be installed in the system for this
extension to have any effect, since that is the tool that actually
performs the disassembly.  If not, you will have to customize the
variable `ad-llvm-bitcode-disassembler' to point to another
disassembler command.
