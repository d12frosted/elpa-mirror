; Sometimes it is desirable to generate a byte array from a file for
; directly including into source code.
;
; `baff` provides this functionality via `M-x baff` and prompts for
; a filename, then creates a buffer containing that file's bytes as
; a byte array, eg:
;
; #include <array>
; // source : c:/dev/baff/README.md
; // sha256 : b2d9aa7ed942cf08d091f3cce3dd56603fef00f5082573cd8b8ad987d29d4351
;
; std::array<uint8_t,10> bytes = {
;     0x23, 0x20, 0x62, 0x61, 0x66, 0x66, 0x0d, 0x0a, 0x43, 0x72
; };
;
; This buffer can then be manipulated or saved how you wish.
;
; The default style is C++ but this can be changed to whatever style
; is desired via `M-x customize-group RET baff RET`
