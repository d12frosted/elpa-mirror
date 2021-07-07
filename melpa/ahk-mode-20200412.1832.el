;;; ahk-mode.el --- Major mode for editing AHK (AutoHotkey and AutoHotkey_L) -*- lexical-binding: t -*-

;; Copyright (C) 2015-2016 by Rich Alesi

;; Author: Rich Alesi
;; URL: https://github.com/ralesi/ahk-mode
;; Package-Version: 20200412.1832
;; Package-Commit: 729007b5f22a49f5187ff47fca18c0d674e73047
;; Version: 1.5.6
;; Keywords: ahk, AutoHotkey, hotkey, keyboard shortcut, automation
;; Package-Requires: ((emacs "24.3"))

;; Based on work from
;; xahk-mode - Author:   Xah Lee ( http://xahlee.org/ ) - 2012
;; ahk-mode - Author:   Robert Widhopf-Fenk

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or version 2.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing AutoHotkey (AHK) script.  Supports commenting,
;; indentation, syntax highlighting, and help lookup both localling and on
;; the web.

;;; INSTALL

;; Open the file, then type “M-x eval-buffer”.  You are done.  Open
;; any ahk script, then type “M-x ahk-mode”, you'll see the
;; source code syntax colored.

;; To have Emacs automatically load the file when it restarts, and
;; automatically use the mode when opening files ending in “.ahk”, do this:

;; This package is located within Melpa.  To install, add
;; ("melpa" . "http://melpa.org/packages/") to package-archives and
;; execute "M-x package-install RET ahk-mode RET".

;;; FEATURES

;; When opening a script file you will get:
;; - syntax highlighting
;; - Commenting - provide functions for block and standard commenting
;; - Imenu - jump to a function / label within a buffer
;; - Execute scripts
;; - Auto complete - adds options for `company-mode' and `auto-complete-mode'

;; TODO:
;; - smart identification of ahk_l and ahk - use chm file
;; - Indentation - indent based on current style
;; - Lookup reference - both on the web and through the installed CHM file
;; - Execute scripts - support redirects of error to stdout
;; - Debugging features - work with dgdb.ahk
;; - add yasnippet support

;; Notes on indentation
;; Indentation is styled with bracing on current line of if / else statements
;; or on empty next line.

;; Block types that can affect indentation
;; comments - ; AAA
;; - previous block beginning brace = +0
;; - indentation level is skipped when determining position for current line
;; function - AAA(.*) { .\n. } = +1
;; function - AAA(.*) { } = +0
;; label - AAA: = 0
;; Keybindings (next line) AAA:: = +1
;; Keybindings (current line) AAA:: =+0
;; Open block - {( +1 on next
;; Close block - {( -1 on current
;; Class AAA.* { ... } = +1
;; #if block open - #[iI]f[^ \n]* (.*) = +1
;; #if block close - #[iI]f[^ \n]*$ = -1
;; return block - [Rr]eturn = -1
;; for .*\n { .. } = +1
;; loop .*\n { .. } = +1
;; open assignment - .*operator-regexp$ = +1

;; existing issues :

;; paren broken across multiple lines
;; DllCall("SetWindowPos", "uint", Window%PrevRowText%, "uint", Window%PPrevRowText%
;;         , "int", 0, "int", 0, "int", 0, "int", 0
;;           , "uint", 0x13)  ; NOSIZE|NOMOVE|NOACTIVATE (0x1|0x2|0x10)


;;; HISTORY

;; version 1.5.2, 2015-03-07 improved auto complete to work with ac and company-mode
;; version 1.5.3, 2015-04-05 improved commenting and added imenu options
;; version 1.5.4, 2015-04-06 indentation is working, with bugs
;; version 1.5.5, 2015-07-20 added load website
;; version 1.5.6, 2016-03-20 execute script works

;;; Code:

;;; Requirements

(require 'font-lock)
(require 'thingatpt)
(require 'rx)

(defvar ac-modes)
(defvar company-tooltip-align-annotations)

;; add to auto-complete sources if ac is loaded
(eval-after-load "auto-complete"
  '(progn
     (require 'auto-complete-config)
     (add-to-list 'ac-modes 'ahk-mode)))

;;; Customization

(defconst ahk-mode-version "1.5.6"
  "Version of `ahk-mode'")

(defgroup ahk-mode nil
  "Major mode for editing AutoHotkey script."
  :group 'languages
  :prefix "ahk-"
  :link '(url-link :tag "Github" "https://github.com/ralesi/ahk-mode")
  :link '(emacs-commentary-link :tag "Commentary" "ahk-mode"))

(defcustom ahk-indentation (or tab-width 2)
  "The indentation level."
  :type 'integer
  :group 'ahk-mode)

(defvar ahk-debug nil
  "Allows additional output when set to non-nil.")

(defvar ahk-path nil
  "Custom path for AutoHotkey executable and related files.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ahk\\'"  . ahk-mode))

;;; keymap
(defvar ahk-mode-map
  (let ((map (make-sparse-keymap)))
    ;; key bindings
    (define-key map (kbd "C-c C-?") #'ahk-lookup-web)
    (define-key map (kbd "C-c C-r") #'ahk-lookup-chm)
    (define-key map (kbd "C-c M-i") #'ahk-indent-message)
    (define-key map (kbd "C-c C-c") #'ahk-comment-dwim)
    (define-key map (kbd "C-c C-b") #'ahk-comment-block-dwim)
    (define-key map (kbd "C-c C-k") #'ahk-run-script)
    map)
  "Keymap for Autohotkey major mode.")

;;; menu
(easy-menu-define ahk-menu ahk-mode-map
  "AHK Mode Commands"
  '("AHK"
    ["Lookup webdocs on command" ahk-lookup-web]
    ["Lookup local documentation on command" ahk-lookup-chm]
    ["Execute script" ahk-run-script]
    "---"
    ["Version" ahk-version]))

;;; syntax table
(defvar ahk-mode-syntax-table
  (let ((syntax-table (make-syntax-table)))
    ;; these are also allowed in variable names
    (modify-syntax-entry ?#  "w" syntax-table)
    (modify-syntax-entry ?_  "w" syntax-table)
    (modify-syntax-entry ?@  "w" syntax-table)
    ;; some additional characters used in paths and switches
    (modify-syntax-entry ?\\  "w" syntax-table)
    (modify-syntax-entry ?\;  "< b" syntax-table)
    ;; for multiline comments
    (modify-syntax-entry ?\/  ". 14" syntax-table)
    (modify-syntax-entry ?*  ". 23"   syntax-table)
    ;; New line
    (modify-syntax-entry ?\n "> b"  syntax-table)
    ;; ` is escape
    (modify-syntax-entry ?` "\\" syntax-table)
    syntax-table)
  "Syntax table for `ahk-mode'.")

;;; imenu support

(defconst ahk-imenu-generic-expression
  '(("Functions"   "^[ \t]*\\([^ ]+\\)(.*)[\n]{" 1)
    ("Labels"      "^[ \t]*\\([^:;]+\\):\n" 1)
    ("Keybindings" "^[ \t]*\\([^;: \t\r\n\v\f].*?\\)::" 1)
    ("Hotstrings" "^[ \t]*\\(:.*?:.*?::\\)" 1)
    ("Comments"    "^;imenu \\(.+\\)" 1))
  "imenu index for `ahk-mode'")

(defun ahk-run-script ()
  "Run the ahk-script in the current buffer."
  (interactive)
  (let ((file (shell-quote-argument
               (replace-regexp-in-string " " "\ "
                                         (replace-regexp-in-string "\/" "\\\\" (buffer-file-name) t t)))))
    (message "Executing script %s" file)
    (w32-shell-execute "open" file)))

(defun ahk-command-at-point ()
  "Determine command at point, and prompt if nothing found."
  (let ((command (or (if (region-active-p)
                         (buffer-substring-no-properties
                          (region-beginning)
                          (region-end))
                       (thing-at-point 'symbol))
                     (read-string "Command: "))))
    command))

(defun ahk-lookup-web ()
  "Look up current word in AutoHotkey's reference doc.
Launches default browser and opens the doc's url."
  (interactive)
  (let* ((acap (ahk-command-at-point))
         (url (concat "http://ahkscript.org/docs/commands/" acap ".htm")))
    (browse-url url)))

(defun ahk-lookup-chm ()
  "Look up current word in AutoHotkey's reference doc.
Finds the command in the internal AutoHotkey documentation."
  (interactive)
  (let* ((acap (ahk-command-at-point))
         (chm-path
          (or (and (file-exists-p "c:/Program Files (x86)/AutoHotkey/AutoHotkey.chm")
                   "c:/Program Files (x86)/AutoHotkey/AutoHotkey.chm")
              (and (file-exists-p "c:/Program Files/AutoHotkey/AutoHotkey.chm")
                   "c:/Program Files/AutoHotkey/AutoHotkey.chm")
              (and (file-exists-p (concat ahk-path "/AutoHotkey.chm"))
                   (concat ahk-path "/AutoHotkey.chm")))))
    (if chm-path
        (when acap (message "Opening help item for \"%s\"" acap)
              (w32-shell-execute 1 "hh.exe"
                                 (format
                                  "ms-its:%s::/docs/commands/%s.htm"
                                  chm-path acap)))
      (message "Help file could not be found, set ahk-path variable."))))

(defun ahk-version ()
  "Show the `ahk-mode' version in the echo area."
  (interactive)
  (message "ahk-mode version %s" ahk-mode-version))

;;;; indentation
(defun ahk-calc-indentation (str &optional offset)
  "Calculate the current indentation level of argument"
  (let ((i (* (or offset 0) ahk-indentation)))
    (while (string-match "\t" str)
      (setq i (+ i tab-width)
            str (replace-match "" nil t str)))
    (setq i (+ i (length str)))
    i))

;; the follwing regexp is used to detect if a condition is a one line statement or not,
;; i.e. it matches one line statements but should not match those where the THEN resp.
;; ELSE body is on its own line ...
(defvar ahk-one-line-if-regexp
  (concat "^\\([ \t]*\\)" ;; this is used for indentation
          "\\("
          "If\\(Not\\)?\\("
          (regexp-opt '("InString" "InStr"
                        "Less" "Greater" "Equal"
                        "LessOrEqual" "GreaterOrEqual"
                        ))
          "\\)[^,\n]*,[^,\n]*,[^,\n]*,"
          "\\|"
          "If\\(Not\\)?Exist[^,\n]*,[^,\n]*,"
          "\\|"
          "Else[ \t]+\\([^I\n][^f\n][^ \n]\\)"
          "\\)"))

(defun ahk-previous-indent ()
  "Return the indentation level of the previous non-blank line."
  (save-excursion
    (forward-line -1)
    (while (and (looking-at "^[ \t]*$") (not (bobp)))
      (forward-line -1))
    (current-indentation)))

(defun ahk-indent-message ()
  "Show message for current indentation level"
  (interactive)
  (message (format "%s" (current-indentation))))

(defun ahk-indent-line ()
  "Indent the current line."
  (interactive)
  (let ((indent 0)
        (opening-brace nil)
        (else nil)
        (label nil)
        (closing-brace nil)
        (loop nil)
        (prev-single nil)
        (return nil)
        (empty-brace nil)
        (block-skip nil)
        (case-fold-search t))
    ;; do a backward search to determine the indentation level
    (save-excursion
      (beginning-of-line)
      ;; save type of current line
      (setq opening-brace      (looking-at "^[ \t]*{[^}]"))
      (setq opening-paren      (looking-at "^[ \t]*([^)]"))
      (setq if-else            (looking-at "^[ \t]*\\([iI]f\\|[Ee]lse\\)"))
      (setq loop               (looking-at "^[ \t]*\\([Ll]oop\\)[^{]+"))
      (setq closing-brace      (looking-at "^[ \t]*\\([)}]\\|\\*\\/\\)"))  ; no "$" for the case of "} else {"
      (setq label              (looking-at "^[ \t]*[^:\n ]+:$"))
      (setq keybinding         (looking-at "^[ \t]*[^:\n ]+::\\(.*\\)$"))
      (setq return             (looking-at "^\\([ \t]*\\)[rR]eturn"))
      (setq blank              (looking-at "^\\([ \t]*\\)\n"))
      ;; skip previous empty lines and commented lines
      (setq indent (ahk-previous-indent))
      (setq prev (ahk-previous-indent))
      (save-excursion
        (when closing-brace
          (progn
            (beginning-of-line)
            (re-search-forward "\\(}\\|)\\)" nil t)
            (backward-list)
            (setq block-skip t)
            (setq indent (current-indentation))
            )
          )
        )
      (forward-line -1)
      (while (and
              (or (looking-at "^[ \t]*$") (looking-at "^;"))
              (not (bobp)))
        (forward-line -1))
      ;; we are now at the previous non-empty /non comment line
      (beginning-of-line)
      ;; default to previous indentation
      (cond
       (block-skip
        nil)
       (blank
        (setq indent 0))
       (closing-brace
        (setq indent (- indent ahk-indentation)))
       ;; if beginning with a comment, take its indentation
       ((looking-at "^\\([ \t]*\\);")
        nil)
       ;; keybindings
       ((and (looking-at "^[ \t]*[^:\n ]+:$")
             (not label))
        (setq indent (+ indent ahk-indentation)))
       ;; return
       ((looking-at "^\\([ \t]*\\)[rR]eturn")
        (setq indent (- indent ahk-indentation)))
       ;; label
       (label
        (setq indent 0))
       ((and
         (not opening-brace)
         (not block-skip)
         (looking-at "^[^: \n]+:$")
         (looking-at "^[^:\n]+:\\([^:\n]*\\)?[ 	]*$"))
        (setq indent (+ indent ahk-indentation)))
       ;; opening brace
       ((looking-at "^\\([ \t]*\\)[{(]$")
        (and
         (setq empty-brace t)
         (setq indent (+ indent ahk-indentation))))
       ;; brace at end of line
       ((or
         (looking-at "^\\([ \t]*\\).*[{][^}]*$")
         (looking-at "^\\([ \t]*\\).*[(][^)]*$"))
        (setq indent (+ indent ahk-indentation)))
       ;; If/Else with body on next line, but not opening { or (
       ((and (not opening-brace)
             (not block-skip)
             ;; (or if-else loop)
             (or
              (looking-at "^[ \t]*\\([Ll]oop\\)[^{=]*\n")
              (looking-at "^\\([ \t]*\\)\\([iI]f\\|[eE]lse\\)[^{]*\n"))
             )
        (and
         (setq prev-single t)
         (setq indent (+ indent ahk-indentation))))
       ((looking-at "^[ \t]*,[^\n]+[}]$")  ; last line of a multi-line list
         (setq indent (- indent ahk-indentation)))

       ;; (return
       ;;  (setq indent (- indent ahk-indentation)))
       ;; subtract indentation if closing bracket only
       ;; ((looking-at "^[ \t]*[})]")
       ;;  (setq indent (- indent ahk-indentation)))
       ;; zero indentation when at label or keybinding
       ((or (looking-at "^[ \t]*[^,: \t\n]*:$")
            (looking-at "^;;;"))
        (setq indent 0)))
      ;; check for single line if/else
      (forward-line -1)
      (when (and
             (not block-skip)
             (not empty-brace)
             (or
              (looking-at "^[ \t]*\\([Ll]oop\\)[^{]+\n")
              (looking-at "^\\([ \t]*\\)\\([iI]f\\|[eE]lse\\)[^{]+\n")))
        ;; adjust when stacking multiple single line commands
        (setq indent (- indent (if prev-single (- (* 2 ahk-indentation)) 0) ahk-indentation)))
      )
    ;; set negative indentation to 0
    (save-excursion
      (beginning-of-line)
      (if (< indent 0)
          (setq indent 0))
      ;; actual indentation performed here
      (if (looking-at "^[ \t]+")
          (replace-match ""))
      (indent-to indent))
    (when ahk-debug
      (message (format
                "indent: %s, current: %s previous: %s
ob: %s, op: %s, cb: %s, bs: %s,
if-else: %s, l: %s, kb: %s, ret: %s, bl: %s"
                indent
                (current-indentation)
                (ahk-previous-indent)
                opening-brace
                opening-paren
                closing-brace
                block-skip
                if-else
                label
                keybinding
                return
                blank
                )))))

(defun ahk-indent-region (start end)
  (interactive "r")
  (save-excursion
    (goto-char start)
    (while (and (not (eobp)) (< (point) end))
      (ahk-indent-line)
      (forward-line 1))))

;;;; commenting

(defun ahk-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For details, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((comment-start ";")
        (comment-end ""))
    (comment-dwim arg)))

(defun ahk-comment-block-dwim (arg)
  "Comment or uncomment current line or region using block notation.
For details, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((comment-style 'extra-line)
        (comment-start "/*")
        (comment-end "*/"))
    (comment-dwim arg)))

;;; font-lock

(defvar ahk-commands
  '("Abort" "AboveNormal" "Add" "All" "Alnum" "Alpha" "AltSubmit" "AlwaysOnTop" "And" "Asc" "AutoSize" "AutoTrim" "Background" "BackgroundTrans" "BelowNormal" "Between" "BitAnd" "BitNot" "BitOr" "BitShiftLeft" "BitShiftRight" "BitXOr" "BlockInput" "Border" "Bottom" "Break" "Button" "Buttons" "ByRef" "Cancel" "Capacity" "Caption" "Catch" "Ceil" "Center" "Check" "Check3" "Checkbox" "Checked" "CheckedGray" "Checks" "Choose" "ChooseString" "Chr" "Click" "ClipWait" "Close" "Color" "ComboBox" "Contains" "Continue" "Control" "ControlClick" "ControlFocus" "ControlGet" "ControlGetFocus" "ControlGetPos" "ControlGetText" "ControlList" "ControlMove" "ControlSend" "ControlSendRaw" "ControlSetText" "CoordMode" "Count" "Critical" "DDL" "Date" "DateTime" "Days" "Default" "Delete" "DeleteAll" "Delimiter" "Deref" "Destroy" "DetectHiddenText" "DetectHiddenWindows" "Digit" "Disable" "Disabled" "Displays" "Drive" "DriveGet" "DriveSpaceFree" "DropDownList" "Edit" "Eject" "Else" "Enable" "Enabled" "EnvAdd" "EnvDiv" "EnvGet" "EnvMult" "EnvSet" "EnvSub" "EnvUpdate" "Error" "ExStyle" "Exist" "Exit" "ExitApp" "Exp" "Expand" "FileAppend" "FileCopy" "FileCopyDir" "FileCreateDir" "FileCreateShortcut" "FileDelete" "FileEncoding" "FileGetAttrib" "FileGetShortcut" "FileGetSize" "FileGetTime" "FileGetVersion" "FileInstall" "FileMove" "FileMoveDir" "FileOpen" "FileRead" "FileReadLine" "FileRecycle" "FileRecycleEmpty" "FileRemoveDir" "FileSelectFile" "FileSelectFolder" "FileSetAttrib" "FileSetTime" "FileSystem" "Finally" "First" "Flash" "Float" "FloatFast" "Floor" "Focus" "Font" "For" "Format" "FormatTime" "GetKeyState" "Gosub" "Goto" "Grid" "Group" "GroupActivate" "GroupAdd" "GroupBox" "GroupClose" "GroupDeactivate" "Gui" "GuiClose" "GuiContextMenu" "GuiControl" "GuiControlGet" "GuiDropFiles" "GuiEscape" "GuiSize" "HKCC" "HKCR" "HKCU" "HKEY_CLASSES_ROOT" "HKEY_CURRENT_CONFIG" "HKEY_CURRENT_USER" "HKEY_LOCAL_MACHINE" "HKEY_USERS" "HKLM" "HKU" "HScroll" "Hdr" "Hidden" "Hide" "High" "Hotkey" "Hours" "ID" "IDLast" "Icon" "IconSmall" "If" "IfEqual" "IfExist" "IfGreater" "IfGreaterOrEqual" "IfInString" "IfLess" "IfLessOrEqual" "IfMsgBox" "IfNotEqual" "IfWinActive" "IfWinExist" "IfWinNotActive" "IfWinNotExist" "Ignore" "ImageList" "ImageSearch" "In" "IniDelete" "IniRead" "IniWrite" "Input" "InputBox" "Integer" "IntegerFast" "Interrupt" "Is" "Join" "KeyHistory" "KeyWait" "LTrim" "Label" "LastFound" "LastFoundExist" "Left" "Limit" "Lines" "List" "ListBox" "ListHotkeys" "ListLines" "ListVars" "ListView" "Ln" "Lock" "Log" "Logoff" "Loop" "Low" "Lower" "Lowercase" "MainWindow" "Margin" "MaxSize" "Maximize" "MaximizeBox" "Menu" "MinMax" "MinSize" "Minimize" "MinimizeBox" "Minutes" "Mod" "MonthCal" "Mouse" "MouseClick" "MouseClickDrag" "MouseGetPos" "MouseMove" "Move" "MsgBox" "Multi" "NA" "No" "NoActivate" "NoDefault" "NoHide" "NoIcon" "NoMainWindow" "NoSort" "NoSortHdr" "NoStandard" "NoTab" "NoTimers" "Normal" "Not" "Number" "Off" "Ok" "On" "OnExit" "Or" "OutputDebug" "OwnDialogs" "Owner" "Parse" "Password" "Pause" "Pic" "Picture" "Pixel" "PixelGetColor" "PixelSearch" "Pos" "PostMessage" "Pow" "Priority" "Process" "ProcessName" "Progress" "REG_BINARY" "REG_DWORD" "REG_EXPAND_SZ" "REG_MULTI_SZ" "REG_SZ" "RGB" "RTrim" "Radio" "Random" "Range" "Read" "ReadOnly" "Realtime" "Redraw" "RegDelete" "RegRead" "RegWrite" "Region" "Relative" "Reload" "Rename" "Report" "Resize" "Restore" "Retry" "Return" "Right" "Round" "Run" "RunAs" "RunWait" "Screen" "Seconds" "Section" "See" "Send" "SendInput" "SendLevel" "SendMessage" "SendMode" "SendPlay" "SendRaw" "Serial" "SetBatchLines" "SetCapslockState" "SetControlDelay" "SetDefaultMouseSpeed" "SetEnv" "SetFormat" "SetKeyDelay" "SetLabel" "SetMouseDelay" "SetNumlockState" "SetRegView" "SetScrollLockState" "SetStoreCapslockMode" "SetTimer" "SetTitleMatchMode" "SetWinDelay" "SetWorkingDir" "ShiftAltTab" "Show" "Shutdown" "Sin" "Single" "Sleep" "Slider" "Sort" "SortDesc" "SoundBeep" "SoundGet" "SoundGetWaveVolume" "SoundPlay" "SoundSet" "SoundSetWaveVolume" "SplashImage" "SplashTextOff" "SplashTextOn" "SplitPath" "Sqrt" "Standard" "Status" "StatusBar" "StatusBarGetText" "StatusBarWait" "StatusCD" "StringCaseSense" "StringGetPos" "StringLeft" "StringLen" "StringLower" "StringMid" "StringReplace" "StringRight" "StringSplit" "StringTrimLeft" "StringTrimRight" "StringUpper" "Style" "Submit" "Suspend" "SysGet" "SysMenu" "Tab" "Tab2" "TabStop" "Tan" "Text" "Theme" "Thread" "Throw" "Tile" "Time" "Tip" "ToggleCheck" "ToggleEnable" "ToolTip" "ToolWindow" "Top" "Topmost" "TransColor" "Transform" "Transparent" "Tray" "TrayTip" "TreeView" "Trim" "Try" "TryAgain" "Type" "UnCheck" "Unicode" "Unlock" "Until" "UpDown" "Upper" "Uppercase" "UrlDownloadToFile" "UseErrorLevel" "VScroll" "Var" "Vis" "VisFirst" "Visible" "Wait" "WaitClose" "WantCtrlA" "WantF2" "WantReturn" "While" "WinActivate" "WinActivateBottom" "WinClose" "WinGet" "WinGetActiveStats" "WinGetActiveTitle" "WinGetClass" "WinGetPos" "WinGetText" "WinGetTitle" "WinHide" "WinKill" "WinMaximize" "WinMenuSelectItem" "WinMinimize" "WinMinimizeAll" "WinMinimizeAllUndo" "WinMove" "WinRestore" "WinSet" "WinSetTitle" "WinShow" "WinWait" "WinWaitActive" "WinWaitClose" "WinWaitNotActive" "Wrap" "Xdigit" "Yes" "ahk_class" "ahk_group" "ahk_id" "ahk_pid" "bold" "global" "italic" "local" "norm" "static" "strike" "underline" "xm" "xp" "xs" "ym" "yp" "ys")
  "AHK keywords.")

(defvar ahk-directives
  '("#ClipboardTimeout" "#CommentFlag" "#ErrorStdOut" "#EscapeChar" "#HotkeyInterval" "#HotkeyModifierTimeout" "#Hotstring" "#If" "#IfTimeout" "#IfWinActive" "#IfWinExist" "#Include" "#InputLevel" "#InstallKeybdHook" "#InstallMouseHook" "#KeyHistory" "#LTrim" "#MaxHotkeysPerInterval" "#MaxMem" "#MaxThreads" "#MaxThreadsBuffer" "#MaxThreadsPerHotkey" "#MenuMaskKey" "#NoEnv" "#NoTrayIcon" "#Persistent" "#SingleInstance" "#UseHook" "#Warn" "#WinActivateForce")
  "AHK directives")

(defvar ahk-functions
  '("ACos" "ASin" "ATan" "Abs" "Asc" "Ceil" "Chr" "ComObjActive" "ComObjArray" "ComObjConnect" "ComObjCreate" "ComObjEnwrap" "ComObjError" "ComObjFlags" "ComObjGet" "ComObjMissing" "ComObjParameter" "ComObjQuery" "ComObjType" "ComObjUnwrap" "ComObjValue" "Cos" "DllCall" "Exp" "FileExist" "Floor" "Func" "Functions" "GetKeyName" "GetKeySC" "GetKeyState" "GetKeyVK" "IL_Add" "IL_Create" "IL_Destroy" "InStr" "IsByRef" "IsFunc" "IsLabel" "IsObject" "LV_Add" "LV_Delete" "LV_DeleteCol" "LV_GetCount" "LV_GetNext" "LV_GetText" "LV_Insert" "LV_InsertCol" "LV_Modify" "LV_ModifyCol" "LV_SetImageList" "Ln" "Log" "Mod" "NumGet" "NumPut" "OnMessage" "RegExMatch" "RegExReplace" "RegisterCallback" "Round" "SB_SetIcon" "SB_SetParts" "SB_SetText" "Sin" "Sqrt" "StrGet" "StrLen" "StrPut" "SubStr" "TV_Add" "TV_Delete" "TV_Get" "TV_GetChild" "TV_GetCount" "TV_GetNext" "TV_GetParent" "TV_GetPrev" "TV_GetSelection" "TV_GetText" "TV_Modify" "Tan" "VarSetCapacity" "WinActive" "WinExist")
  "AHK functions.")

(defvar ahk-variables
  '("A_AhkPath" "A_AhkVersion" "A_AppData" "A_AppDataCommon" "A_AutoTrim" "A_BatchLines" "A_CaretX" "A_CaretY" "A_ComputerName" "A_ControlDelay" "A_Cursor" "A_DD" "A_DDD" "A_DDDD" "A_DefaultMouseSpeed" "A_Desktop" "A_DesktopCommon" "A_DetectHiddenText" "A_DetectHiddenWindows" "A_EndChar" "A_EventInfo" "A_ExitReason" "A_FileEncoding" "A_FormatFloat" "A_FormatInteger" "A_Gui" "A_GuiControl" "A_GuiControlEvent" "A_GuiEvent" "A_GuiHeight" "A_GuiWidth" "A_GuiX" "A_GuiY" "A_Hour" "A_IPAddress1" "A_IPAddress2" "A_IPAddress3" "A_IPAddress4" "A_ISAdmin" "A_IconFile" "A_IconHidden" "A_IconNumber" "A_IconTip" "A_Index" "A_Is64bitOS" "A_IsAdmin" "A_IsCompiled" "A_IsCritical" "A_IsPaused" "A_IsSuspended" "A_IsUnicode" "A_KeyDelay" "A_Language" "A_LastError" "A_LineFile" "A_LineNumber" "A_LoopField" "A_LoopFileAttrib" "A_LoopFileDir" "A_LoopFileExt" "A_LoopFileFullPath" "A_LoopFileLongPath" "A_LoopFileName" "A_LoopFileName," "A_LoopFileShortName" "A_LoopFileShortPath" "A_LoopFileSize" "A_LoopFileSizeKB" "A_LoopFileSizeMB" "A_LoopFileTimeAccessed" "A_LoopFileTimeCreated" "A_LoopFileTimeModified" "A_LoopReadLine" "A_LoopRegKey" "A_LoopRegName" "A_LoopRegName," "A_LoopRegSubkey" "A_LoopRegTimeModified" "A_LoopRegType" "A_MDAY" "A_MM" "A_MMM" "A_MMMM" "A_MSec" "A_Min" "A_Mon" "A_MouseDelay" "A_MyDocuments" "A_Now" "A_NowUTC" "A_NumBatchLines" "A_OSType" "A_OSVersion" "A_PriorHotkey" "A_PriorKey" "A_ProgramFiles" "A_Programs" "A_ProgramsCommon" "A_PtrSize" "A_RegView" "A_ScreenDPI" "A_ScreenHeight" "A_ScreenWidth" "A_ScriptDir" "A_ScriptFullPath" "A_ScriptHwnd" "A_ScriptName" "A_Sec" "A_Space" "A_StartMenu" "A_StartMenuCommon" "A_Startup" "A_StartupCommon" "A_StringCaseSense" "A_Tab" "A_Temp" "A_ThisFunc" "A_ThisHotkey" "A_ThisLabel" "A_ThisMenu" "A_ThisMenuItem" "A_ThisMenuItemPos" "A_TickCount" "A_TimeIdle" "A_TimeIdlePhysical" "A_TimeSincePriorHotkey" "A_TimeSinceThisHotkey" "A_TitleMatchMode" "A_TitleMatchModeSpeed" "A_UserName" "A_WDay" "A_WinDelay" "A_WinDir" "A_WorkingDir" "A_YDay" "A_YEAR" "A_YWeek" "A_YYYY" "Clipboard" "ClipboardAll" "ComSpec" "ErrorLevel" "False" "ProgramFiles" "True" "Variable")
  "AHK variables.")

(defvar ahk-keys
  '("Alt" "AltDown" "AltTab" "AltTabAndMenu" "AltTabMenu" "AltTabMenuDismiss" "AltUp" "AppsKey" "BS" "BackSpace" "Browser_Back" "Browser_Favorites" "Browser_Forward" "Browser_Home" "Browser_Refresh" "Browser_Search" "Browser_Stop" "CapsLock" "Control" "Ctrl" "CtrlBreak" "CtrlDown" "CtrlUp" "Del" "Delete" "Down" "End" "Enter" "Esc" "Escape" "F1" "F10" "F11" "F12" "F13" "F14" "F15" "F16" "F17" "F18" "F19" "F2" "F20" "F21" "F22" "F23" "F24" "F3" "F4" "F5" "F6" "F7" "F8" "F9" "Home" "Ins" "Insert" "Joy1" "Joy10" "Joy11" "Joy12" "Joy13" "Joy14" "Joy15" "Joy16" "Joy17" "Joy18" "Joy19" "Joy2" "Joy20" "Joy21" "Joy22" "Joy23" "Joy24" "Joy25" "Joy26" "Joy27" "Joy28" "Joy29" "Joy3" "Joy30" "Joy31" "Joy32" "Joy4" "Joy5" "Joy6" "Joy7" "Joy8" "Joy9" "JoyAxes" "JoyButtons" "JoyInfo" "JoyName" "JoyPOV" "JoyR" "JoyU" "JoyV" "JoyX" "JoyY" "JoyZ" "LAlt" "LButton" "LControl" "LCtrl" "LShift" "LWin" "LWinDown" "LWinUp" "Launch_App1" "Launch_App2" "Launch_Mail" "Launch_Media" "Left" "MButton" "Media_Next" "Media_Play_Pause" "Media_Prev" "Media_Stop" "NumLock" "Numpad0" "Numpad1" "Numpad2" "Numpad3" "Numpad4" "Numpad5" "Numpad6" "Numpad7" "Numpad8" "Numpad9" "NumpadAdd" "NumpadClear" "NumpadDel" "NumpadDiv" "NumpadDot" "NumpadDown" "NumpadEnd" "NumpadEnter" "NumpadHome" "NumpadIns" "NumpadLeft" "NumpadMult" "NumpadPgdn" "NumpadPgup" "NumpadRight" "NumpadSub" "NumpadUp" "PGDN" "PGUP" "Pause" "PrintScreen" "RAlt" "RButton" "RControl" "RCtrl" "RShift" "RWin" "RWinDown" "RWinUp" "Right" "ScrollLock" "Shift" "ShiftDown" "ShiftUp" "Space" "Tab" "Up" "Volume_Down" "Volume_Mute" "Volume_Up" "WheelDown" "WheelLeft" "WheelRight" "WheelUp" "XButton1" "XButton2")
  "AHK keywords for keys.")

(defvar ahk-operator-words
  '("AND" "NOT" "OR")
  "AHK operator words.")

(defvar ahk-operators
  '("\\!" "!=" "&" "&&" "&=" "*" "**" "*=" "+" "++" "+=" "-" "--" "-=" "." "." ".=" "/" "//" "//=" "/=" ":=" "<" "<<" "<<=" "<=" "<>" "=" "==" ">" ">=" ">>" ">>=" "?:" "^" "^=" "|" "|=" "||" "~" "~=" ",")
  "AHK operators.")

(defvar ahk-commands-regexp (regexp-opt ahk-commands 'words))
(defvar ahk-functions-regexp (regexp-opt ahk-functions 'words))
(defvar ahk-directives-regexp (regexp-opt ahk-directives 'words))
(defvar ahk-variables-regexp (regexp-opt ahk-variables 'words))
(defvar ahk-keys-regexp (regexp-opt ahk-keys 'words))
(defvar ahk-operator-words-regexp (regexp-opt ahk-operator-words 'words))
(defvar ahk-operators-regexp (regexp-opt ahk-operators))

(defvar ahk-double-quote-string-re "[\"]\\(\\\\.\\|[^\"\n]\\)*[\"]"
  "Regexp used to match a double-quoted string literal")

(defvar ahk-single-quote-string-re "[']\\(\\\\.\\|[^'\n]\\)*[']"
  "Regexp used to match a single-quoted string literal")

(defvar ahk-font-lock-keywords
  `(("\\s-*;.*$"                      . font-lock-comment-face)
    ;; lLTrim0 usage
    ("(LTrim0\\(.*\n\\)+"            . font-lock-string-face)
    (,ahk-double-quote-string-re . font-lock-string-face)
    (,ahk-single-quote-string-re . font-lock-string-face)
    ;; block comments
    ("^/\\*\\(.*\r?\n\\)*\\(\\*/\\)?" . font-lock-comment-face)
    ;; bindings
    ("^\\([^\t\n:=]+\\)::"            . (1 font-lock-constant-face))
    ;; labels
    ("^\\([^\t\n :=]+\\):[^=]"        . (1 font-lock-doc-face))
    ;; return
    ("\\<\\([Rr]eturn\\)\\>"          . font-lock-warning-face)
    ;; functions
    ("^\\([^\t\n (]+\\)\\((.*)\\)"    . (1 font-lock-function-name-face))
    ;; variables
    ("%[^% ]+%"                       . font-lock-variable-name-face)
    (,ahk-commands-regexp             . font-lock-keyword-face)
    (,ahk-functions-regexp            . font-lock-function-name-face)
    (,ahk-directives-regexp           . font-lock-preprocessor-face)
    (,ahk-variables-regexp            . font-lock-variable-name-face)
    (,ahk-keys-regexp                 . font-lock-constant-face)
    (,ahk-operator-words-regexp       . font-lock-builtin-face)
    (,ahk-operators-regexp . font-lock-builtin-face)
    ;; note: order matters
    ))

;; keyword completion
(defvar ahk-kwd-list (make-hash-table :test 'equal)
  "AHK keywords.")

(defvar ahk-all-keywords (append ahk-commands ahk-functions ahk-variables)
  "List of all ahk keywords.")

(mapc (lambda (x) (puthash x t ahk-kwd-list)) ahk-commands)
(mapc (lambda (x) (puthash x t ahk-kwd-list)) ahk-functions)
(mapc (lambda (x) (puthash x t ahk-kwd-list)) ahk-directives)
(mapc (lambda (x) (puthash x t ahk-kwd-list)) ahk-variables)
(mapc (lambda (x) (puthash x t ahk-kwd-list)) ahk-keys)
(put 'ahk-kwd-list 'risky-local-variable t)

(defun ahk-completion-at-point ()
  "Complete the current work using the list of all syntax's."
  (interactive)
  (let ((pt (point)))
    (if (and (or (save-excursion (re-search-backward "\\<\\w+"))
                 (looking-at "\\<\\w+"))
             (= (match-end 0) pt))
        (let ((start (match-beginning 0))
              (prefix (match-string 0))
              (completion-ignore-case t)
              completions)
          (list start pt (all-completions prefix ahk-all-keywords) :exclusive 'no :annotation-function 'ahk-company-annotation)))))

(defun ahk-company-annotation (candidate)
  "Annotate company mode completions based on source."
  (cond
   ((member candidate ahk-commands)
    "c")
   ((member candidate ahk-functions)
    "f")
   ((member candidate ahk-variables)
    "v")
   ((member candidate ahk-directives)
    "d")
   ((member candidate ahk-keys)
    "k")
   (t "")))

(defvar ac-source-ahk
  '((candidates . (all-completions ac-prefix ahk-all-keywords))
    (limit . nil)
    (symbol . "f"))
  "Completion for AHK mode")

(defvar ac-source-keys-ahk
  '((candidates . (all-completions ac-prefix ahk-keys))
    (limit . nil)
    (symbol . "k"))
  "Completion for AHK keys mode")

(defvar ac-source-directives-ahk
  '((candidates . (all-completions ac-prefix ahk-directives))
    (limit . nil)
    (symbol . "d"))
  "Completion for AHK directives mode")

;; clear memory
;; (setq ahk-commands nil)
;; (setq ahk-functions nil)
;; (setq ahk-directives nil)
;; (setq ahk-variables nil)
;; (setq ahk-keys nil)

(defun ahk-font-lock-extend-region ()
  "Extend the search region to include an entire block of text."
  ;; Avoid compiler warnings about these global variables from font-lock.el.
  ;; See the documentation for variable `font-lock-extend-region-functions'.
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (let ((found (or (re-search-backward "(LTrim0" nil t) (point-min))))
      (goto-char font-lock-end)
      (when (re-search-forward "\n)" nil t)
        (beginning-of-line)
        (setq font-lock-end (point)))
      (setq font-lock-beg found))))

(defun ahk-ltrim-blocks ()
  "Match JavaScript blocks from the point to LAST."
  (cond ((re-search-backward "(LTrim0" nil t)
         (let ((beg (match-beginning 0)))
           (cond ((re-search-forward "\n)" nil t)
                  (set-match-data (list beg (point)))
                  t)
                 (t nil))))
        (t nil)))

;;;###autoload
(define-derived-mode ahk-mode prog-mode "AutoHotkey Mode"
  "Major mode for editing AutoHotkey script (AHK).

The hook functions in `ahk-mode-hook' are run after mode initialization.

Key Bindings
\\{ahk-mode-map}"
  (kill-all-local-variables)

  (set-syntax-table ahk-mode-syntax-table)

  (setq major-mode 'ahk-mode
        mode-name "AHK"
        local-abbrev-table ahk-mode-abbrev-table)

  ;; ui
  (use-local-map ahk-mode-map)
  (easy-menu-add ahk-menu)

  ;; imenu
  (setq-local imenu-generic-expression ahk-imenu-generic-expression)
  (setq-local imenu-sort-function 'imenu--sort-by-position)

  ;; font-lock
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '((ahk-font-lock-keywords) nil t))
  ;; (set (make-local-variable 'font-lock-multiline) t)
  ;; (add-hook 'font-lock-extend-region-functions
  ;;           'ahk-font-lock-extend-region)
  ;; (setq syntax-propertize-function)

  ;; clear memory
  ;; (setq ahk-commands-regexp nil)
  ;; (setq ahk-functions-regexp nil)
  ;; (setq ahk-variables-regexp nil)
  ;; (setq ahk-keys-regexp nil)

  (if (boundp 'evil-shift-width)
      (setq-local evil-shift-width ahk-indentation))

  (setq-local comment-start ";")
  (setq-local comment-end   "")
  (setq-local comment-start-skip ";+ *")

  (setq-local block-comment-start     "/*")
  (setq-local block-comment-end       "*/")
  (setq-local block-comment-left      " * ")
  (setq-local block-comment-right     " *")
  (setq-local block-comment-top-right "")
  (setq-local block-comment-bot-left  " ")
  (setq-local block-comment-char      ?*)

  (setq-local indent-line-function   'ahk-indent-line)
  (setq-local indent-region-function 'ahk-indent-region)

  (setq-local parse-sexp-ignore-comments t)
  (setq-local parse-sexp-lookup-properties t)
  (setq-local paragraph-start (concat "$\\|" page-delimiter))
  (setq-local paragraph-separate paragraph-start)
  (setq-local paragraph-ignore-fill-prefix t)

  ;; completion
  (setq-local company-tooltip-align-annotations t)
  (add-hook 'completion-at-point-functions 'ahk-completion-at-point nil t)

  (eval-after-load "auto-complete"
    '(when (listp 'ac-sources)
       (progn
         (make-local-variable 'ac-sources)
         (add-to-list 'ac-sources  'ac-source-ahk)
         (add-to-list 'ac-sources  'ac-source-directives-ahk)
         (add-to-list 'ac-sources  'ac-source-keys-ahk))))

  (run-mode-hooks 'ahk-mode-hook))

(when ahk-debug
  (mapc (lambda (buffer)
          (with-current-buffer buffer
            (when (eq major-mode 'ahk-mode)
              (message "%s" buffer)
              (font-lock-mode -1)
              (ahk-mode))))
        (buffer-list)))

(provide 'ahk-mode)

;;; ahk-mode.el ends here
