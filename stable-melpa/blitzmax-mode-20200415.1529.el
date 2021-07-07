;;; blitzmax-mode.el --- A major mode for editing BlitzMax source code -*- lexical-binding: t; -*-

;; Copyright (C) 2012-2020 Phil Newton

;; Version: 1.0.0
;; Package-Version: 20200415.1529
;; Package-Commit: 5f67bb3c8e4baf1f6881cc998f9f031641a7b08a
;; Keywords: languages blitzmax
;; Author: Phil Newton
;; URL: https://www.sodaware.net/dev/tools/blitzmax-mode/
;; Package-Requires: ((emacs "24.1"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Emacs; see the file COPYING, or type `C-h C-c'. If not,
;; write to the Free Software Foundation at this address:

;; Free Software Foundation
;; 51 Franklin Street, Fifth Floor
;; Boston, MA 02110-1301
;; USA

;;; Commentary:

;; This is a major mode for editing BlitzMax files.  It supports syntax
;; highlighting, keyword capitalization, and automatic indentation.

;; blitzmax-mode provides the following configuration options:

;; blitzmax-mode-indent ::
;;   The number of spaces to indent by.  By default blitzmax-mode indents by 4
;;   spaces which is converted to a single tab.

;; blitzmax-mode-capitalize-keywords-p ::
;;   Disable automatic capitalization of keywords by setting this to =nil=.  =t=
;;   by default.

;; blitzmax-mode-smart-indent-p
;;   Disable smart indentation by setting this to =nil=.  =t= by default.

;; blitzmax-mode-compiler-pathname
;;   Full pathname to the BlitzMax compiler bmk.  "bmk" by default.

;; To enable quickrun integration, add the following code to your Emacs
;; initialization file.

;;   (with-eval-after-load 'quickrun
;;     (blitzmax-mode-quickrun-integration))

;;; Code:

;; --------------------------------------------------
;; -- Configuration

(defgroup blitzmax nil
  "Major mode for editing BlitzMax source files."
  :group 'languages
  :prefix "blitzmax-")

(defcustom blitzmax-mode-indent 4
  "Default indentation per nesting level."
  :type 'integer
  :group 'blitzmax)

(defcustom blitzmax-mode-smart-indent-p t
  "Whether to use smart-indentation."
  :type 'boolean
  :group 'blitzmax)

(defcustom blitzmax-mode-capitalize-keywords-p t
  "Whether to automatically capitalize keywords."
  :type 'boolean
  :group 'blitzmax)

(defcustom blitzmax-mode-compiler-pathname "bmk"
  "The full pathname of the BlitzMax compiler (e.g. /usr/bin/bmk)."
  :type 'string
  :group 'blitzmax)

(defcustom blitzmax-mode-hook nil
  "Hook run when entering blitzmax mode."
  :type 'hook
  :group 'hook)


;; --------------------------------------------------
;; -- Local Variables

(defvar blitzmax-mode-abbrev-table nil)
(defvar blitzmax-mode-font-lock-keywords)


;; --------------------------------------------------
;; -- Regex for indentation

(defconst blitzmax-mode-type-start-regexp
  (concat
   "^[ \t]*[Tt]ype"
   "[ \t]+_?\\(\\w+\\)[ \t]*?"))

(defconst blitzmax-mode-type-end-regexp
  "^[ \t]*[Ee]nd[ ]*[Tt]ype")

(defconst blitzmax-mode-defun-start-regexp
  (concat
   "^[\t ]*\\([Mm]ethod\\|[Ff]unction\\)"
   "[ \t ]+_?\\(\\w+\\)[ \t ]*(?"))

(defconst blitzmax-mode-defun-end-regexp
  "^[ \t]*[Ee]nd[ \t]*\\([Mm]ethod\\|[Ff]unction\\)")

(defconst blitzmax-mode-abstract-defun-regexp
  (concat
   "^[\t ]*\\([Mm]ethod\\|[Ff]unction\\)"
   "[ \t ]+\\(\\w+\\)[ \t ]*(?"
   ".*[ \t]+[Aa]bstract"))

(defconst blitzmax-mode-extern-start-regexp
  "^[\t ]*[Ee]xtern")

(defconst blitzmax-mode-extern-end-regexp
  "^[ \t]*[Ee]nd[ ]*[Ee]xtern")

(defconst blitzmax-mode-if-regexp "^[ \t]*[Ii]f")
(defconst blitzmax-mode-if-oneline-regexp "^[ \t]*[Ii]f.*[Tt]hen[\\ t:]*[[:alnum:]]+[^']+?")
(defconst blitzmax-mode-else-regexp "^[ \t]*[Ee]lse\\([Ii]f\\)?")
(defconst blitzmax-mode-endif-regexp "[ \t]*[Ee]nd[ \t]*[Ii]f")

(defconst blitzmax-mode-continuation-regexp "[ \t]*\\.\\.")
(defconst blitzmax-mode-label-regexp "^[ \t]*#[a-zA-Z0-9_]+$")

(defconst blitzmax-mode-select-regexp "^[ \t]*[Ss]elect")
(defconst blitzmax-mode-case-regexp "^[ \t]*\\([Cc]ase\\|[Dd]efault\\)")
(defconst blitzmax-mode-select-end-regexp "^[ \t]*[Ee]nd[ \t]*[Ss]elect")

(defconst blitzmax-mode-for-regexp "^[ \t]*[Ff]or[ \t]+[[:alnum:]]+")
(defconst blitzmax-mode-next-regexp "^[ \t]*[Nn]ext")

(defconst blitzmax-mode-while-regexp "^[ \t]*[Ww]hile")
(defconst blitzmax-mode-wend-regexp "^[ \t]*[Ww]end")

(defconst blitzmax-mode-repeat-regexp "^[ \t]*[Rr]epeat")
(defconst blitzmax-mode-until-regexp "^[ \t]*\\([Ff]orever\\|[Uu]ntil\\)")

(defconst blitzmax-mode-try-regexp "^[ \t]*[Tt]ry")
(defconst blitzmax-mode-catch-regexp "^[ \t]*[Cc]atch")
(defconst blitzmax-mode-try-end-regexp "^[ \t]*[Ee]nd[ \t]*[Tt]ry")

(defconst blitzmax-mode-blank-regexp "^[ \t]*$")
(defconst blitzmax-mode-comment-regexp "^[ \t]*\\s<.*$")


;; --------------------------------------------------
;; -- Keywords

(defconst blitzmax-mode-all-keywords
  '("CreateStaticAudioSample" "TStreamWriteException" "TStreamReadException"
    "bglFixedFontBitmaps" "CountGraphicsModes" "CreateSocketStream"
    "CreateStaticPixmap" "GraphicsModeExists" "LittleEndianStream"
    "TAudioSampleLoader" "bglSetMouseVisible" "bglSetSwapInterval"
    "CreateAudioSample" "CreateGNetMessage" "GNetMessageObject" "GNetPeerTCPSocket"
    "GNetPeerUDPSocket" "GNetTotalBytesOut" "SetGraphicsDriver" "CreateBankStream"
    "CreateGNetObject" "CreateStaticBank" "GNetObjectRemote" "GNetTotalBytesIn"
    "SetChannelVolume" "SocketRemotePort" "StandardIOStream" "TStreamException"
    "bglAdjustTexSize" "bglCreateContext" "bglDeleteContext" "bglTexFromPixmap"
    "HandleFromObject" "HandleToObject"
    "BigEndianStream" "CloseGNetObject" "CreateRamStream" "CreateTCPSocket"
    "CreateUDPSocket" "D3D7Max2DDriver" "GNetObjectLocal" "GNetObjectState"
    "GetGraphicsMode" "LoadAudioSample" "ResetCollisions" "SendGNetMessage"
    "SetChannelDepth" "SocketConnected" "SocketLocalPort" "SocketReadAvail"
    "bglDisplayModes" "AutoImageFlags" "ChannelPlaying" "CreateGNetHost"
    "GraphicsHeight" "ImagesCollide2" "MidHandleImage" "PixmapPixelPtr"
    "SetChannelRate" "SetImageHandle" "SocketRemoteIP" "TStreamFactory"
    "TStreamWrapper" "bglSwapBuffers" "AutoMidHandle" "CasedFileName"
    "CloseGNetHost" "CloseGNetPeer" "ConnectSocket" "ConvertPixmap" "DrawImageRect"
    "GLMax2DDriver" "GetGNetString" "GetGNetTarget" "GraphicsWidth" "ImagesCollide"
    "JoyButtonCaps" "ListFromArray" "LoadAnimImage" "LoadByteArray" "LoadImageFont"
    "LoadPixmapPNG" "ResumeChannel" "SaveByteArray" "SavePixmapPNG" "SetChannelPan"
    "SetGNetString" "SetGNetTarget" "SocketLocalIP" "TPixmapLoader" "AllocChannel"
    "BankCapacity" "CollideImage" "CreatePixmap" "GNetMessages" "GetGNetFloat"
    "GetImageFont" "GetLineWidth" "GetMaskColor" "ListAddFirst" "ListContains"
    "ListFindLink" "PauseChannel" "PixmapFormat" "PixmapHeight" "PixmapWindow"
    "ResizePixmap" "RuntimeError" "SetGNetFloat" "SetImageFont"
    "SetLineWidth" "SetMaskColor" "SetTransform" "SocketAccept" "SocketListen"
    "TAudioSample" "CloseSocket" "CloseStream" "CollideRect" "CreateImage"
    "CreateTimer" "CurrentDate" "CurrentTime" "EndFunction" "EndGraphics"
    "FlushStream" "GNetConnect" "GNetObjects" "GetClsColor" "GetGraphics"
    "GetRotation" "GetViewport" "ImageHeight" "JoyAxisCaps" "ListAddLast"
    "ListIsEmpty" "ListToArray" "PixmapPitch" "PixmapWidth" "RequestFile"
    "RestoreData" "ReverseList" "SetClsColor" "SetFileMode" "SetRotation"
    "SetViewport" "StopChannel" "SuperStrict" "TBankStream" "UnlockImage"
    "WriteDouble" "WriteStderr" "WriteStdout" "WriteStream" "WriteString"
    "XFlipPixmap" "bglDrawText" "BindSocket" "CopyPixmap" "CopyStream" "CreateBank"
    "CreateFile" "CreateList" "CurrentDir" "DeleteFile" "DrawPixmap" "ExtractDir"
    "ExtractExt" "GNetAccept" "GNetListen" "GetGNetInt" "GrabPixmap" "ImageWidth"
    "ListRemove" "LoadPixmap" "LoadString" "MaskPixmap" "MemAlloced" "ModuleInfo"
    "OpenStream" "PeekDouble" "PokeDouble" "PollSystem" "ReadDouble" "ReadStream"
    "ReadString" "RemoveLink" "RenameFile" "RequestDir" "ResizeBank" "SaveString"
    "SeekStream" "SetGNetInt" "StreamSize" "StripSlash" "TextHeight" "WaitSystem"
    "WriteFloat" "WritePixel" "WriteShort" "uncompress" "ChangeDir" "ClearList"
    "CloseFile" "CopyBytes" "CountList" "CreateDir" "DebugStop" "DeleteDir"
    "DrawImage" "EndExtern" "EndMethod" "EndSelect" "FlushKeys" "Framework"
    "GCSetMode" "GCSuspend" "GCResume" "GCCollect" "GCMemAlloced" "GCEnter" "GCLeave"
    "GNetPeers" "GetHandle" "GetOrigin" "GrabImage" "HideMouse" "IncbinLen"
    "IncbinPtr" "LaunchDir" "LoadImage" "LoadSound" "LockImage" "MemExtend"
    "MilliSecs" "MouseDown" "MoveMouse" "PeekFloat" "PeekShort" "PlaySound"
    "PokeFloat" "PokeShort" "ReadFloat" "ReadPixel" "ReadShort" "ReadStdin"
    "RndDouble" "SetHandle" "SetOrigin" "ShowMouse" "StreamPos" "SwapLists"
    "TListEnum" "TextWidth" "TileImage" "WaitMouse" "WaitTimer" "WriteBank"
    "WriteByte" "WriteFile" "WriteLine" "WriteLong" "compress2" "Abstract"
    "AppTitle" "BankSize" "CloseDir" "Continue" "CopyBank" "CueSound" "DebugLog"
    "DottedIP" "DrawLine" "DrawOval" "DrawPoly" "DrawRect" "DrawText" "FileMode"
    "FileSize" "FileTime" "FileType" "FlushMem" "Function" "GCMalloc"
    "GNetSync" "GetAlpha" "GetBlend" "GetColor" "GetScale" "Graphics" "HostName"
    "JoyCount" "JoyPitch" "JoyWheel" "LoadBank" "MemAlloc" "MemClear" "MemUsage"
    "MouseHit" "NextFile" "OpenFile" "PeekByte" "PeekLong" "PokeByte" "PokeLong"
    "ReadBank" "ReadByte" "ReadData" "ReadFile" "ReadLine" "ReadLong" "RealPath"
    "RndFloat" "SaveBank" "SetAlpha" "SetBlend" "SetColor" "SetScale" "SortList"
    "StripAll" "StripDir" "StripExt" "TCStream" "TChannel" "WaitChar" "WriteInt"
    "compress" "AppArgs" "AppFile" "BankBuf" "Confirm" "DefData" "Default" "EndType"
    "Extends" "Forever" "GetChar" "HostIps" "Include" "JoyDown" "JoyName" "JoyRoll"
    "KeyDown" "LoadDir" "LongBin" "LongHex" "MemCopy" "MemFree" "MemMove" "PeekInt"
    "PokeInt" "Private" "Proceed" "ReadDir" "Readint" "Release" "Replace" "Restore"
    "RndSeed" "SeedRnd" "TPixmap" "TStream" "WaitKey" "AppDir" "Assert" "Before"
    "Delete" "EachIn" "ElseIf" "EndRem" "EndTry" "Extern" "Global"
    "HostIp" "Import" "Incbin" "Insert" "JoyHat" "JoyYaw" "KeyHit" "Method" "Module"
    "MouseX" "MouseY" "MouseZ" "Notify" "Public" "Repeat" "Return" "Select"
    "SizeOf" "Strict" "TSound" "Varptr" "ATan2" "After" "Catch" "Const"
    "Delay" "EndIf"  "Field" "Final" "First" "Floor" "Gosub"
    "Input" "Instr" "Local" "Log10" "Lower" "OnEnd" "Print" "Right" "Super"
    "TBank" "TLink" "TList" "Throw" "Until" "Upper" "While" "ACos" "ASin" "ATan"
    "Case" "Ceil" "Cosh" "Data" "Each" "Else"  "Exit" "Flip" "Goto" "JoyR" "JoyU"
    "JoyV" "JoyX" "JoyY" "JoyZ" "LSet" "Last" "Left" "Next" "Plot"
    "RSet" "Rand" "Read" "Self" "Sinh" "Step" "Tanh" "Then" "Trim" "Type"
    "Wend" "Abs" "And" "Asc" "Bin" "Chr" "Cls" "Cos" "Dim" "End" "Eof" "Exp" "For"
    "Hex" "Len" "Log" "Max" "Mid" "Min" "Mod" "New" "Not" "Ptr" "Rem" "Rnd"
    "Sar" "Sgn" "Shl" "Shr" "Sin" "Sqr" "Str" "TIO" "Tan" "Try" "Var" "Xor" "YFl"
    "If" "Or" "Pi" "To"))

(defconst blitzmax-mode-type-keywords
  '("Int" "String" "Float" "Object" "Short" "Byte" "Long" "Double"))

(defconst blitzmax-mode-constant-keywords
  '("True" "False" "Null"))


;; --------------------------------------------------
;; -- Automatic capitalization

(defun blitzmax-mode--abbrev-keyword-lookup ()
  "Fetch a keyword lookup for all keywords, types and constants.

Returns a list of abbrev pairs.  The first member of the pair is
a lowercase word, the second is the correctly-capitalized word."
  (let ((all-keywords (append blitzmax-mode-all-keywords
                              blitzmax-mode-type-keywords
                              blitzmax-mode-constant-keywords)))
    (mapcar (lambda (word)
              (list (downcase word) word))
            all-keywords)))

(defun blitzmax-mode--create-abbrev-table ()
  "Create a new abbreviation table for automatic capitalization.

Returns `t` if the table was created, `nil` if it already exists."
  (unless blitzmax-mode-abbrev-table
    (define-abbrev-table
      'blitzmax-mode-abbrev-table
      (blitzmax-mode--abbrev-keyword-lookup))
    t))
(blitzmax-mode--create-abbrev-table)

(defun blitzmax-mode--in-code-context-p ()
  "Check if point is in code.

Returns `t` if in code, `nil` if in a comment or string."
  (if (fboundp 'buffer-syntactic-context)
      (null (buffer-syntactic-context))
    (let* ((beg (save-excursion
                  (beginning-of-line)
                  (point)))
           (list
            (parse-partial-sexp beg (point))))
      (and (null (nth 3 list))      ;; Is inside string.
           (null (nth 4 list))))))  ;; Is inside comment.

(defun blitzmax-mode--capitalize-keywords ()
  "Automatically capitalize keywords if in a code context."
  (setq local-abbrev-table
        (when (blitzmax-mode--in-code-context-p)
          blitzmax-mode-abbrev-table)))


;; --------------------------------------------------
;; -- Font-lock functions

(defun blitzmax-mode--fontify-buffer ()
  "Enable BlitzMax syntax highlighting for the current buffer."
  (let ((blitzmax-mode-keywords-regexp  (regexp-opt blitzmax-mode-all-keywords      'symbols))
        (blitzmax-mode-types-regexp     (regexp-opt blitzmax-mode-type-keywords     'symbols))
        (blitzmax-mode-constants-regexp (regexp-opt blitzmax-mode-constant-keywords 'symbols)))

    ;; Build highlight table.
    (make-local-variable 'blitzmax-mode-font-lock-keywords)
    (setq blitzmax-mode-font-lock-keywords
          `((,blitzmax-mode-types-regexp     . font-lock-type-face)
            (,blitzmax-mode-keywords-regexp  . font-lock-keyword-face)
            (,blitzmax-mode-constants-regexp . font-lock-constant-face)))

    ;; Highlight keywords.
    (setq font-lock-defaults
          '(blitzmax-mode-font-lock-keywords nil t))))

;; Propertize Rem/End Rem comments. BlitzMax ignores the case, so REM and rEm
;; are treated exactly the same (i.e. the start of a comment).
(defconst blitzmax-mode--syntax-propertize-function
  (syntax-propertize-rules
   ("\\_<\\([Rr]\\)[Ee][Mm]\\_>"        (1 "<"))            ;; Start of comment.
   ("\\_<[Ee][Nn][Dd][ ]?[Rr][Ee]\\([Mm]\\)\\_>" (1 ">")))) ;; End of comment.


;; --------------------------------------------------
;; -- Indentation functions

(defun blitzmax-mode--one-line-if-p ()
  "Check if the current IF statement is complete on a single line."
  (looking-at blitzmax-mode-if-oneline-regexp))

(defun blitzmax-mode--abstract-defun-p ()
  "Check if the current function or method is abstract."
  (looking-at blitzmax-mode-abstract-defun-regexp))

(defun blitzmax-mode--externed-function-p ()
  "Check if the current function is part of an `Extern` block."
  (save-excursion
    (blitzmax-mode--find-matching-extern)
    (looking-at blitzmax-mode-extern-start-regexp)))

(defun blitzmax-mode--previous-line-of-code ()
  "Move to the previous line of code, skipping over any comments or whitespace."
  (unless (bobp)
    (forward-line -1))
  (while (and (not (bobp))
              (or (looking-at blitzmax-mode-blank-regexp)
                  (looking-at blitzmax-mode-comment-regexp)))
    (forward-line -1)))

(defun blitzmax-mode--find-original-statement ()
  "Move to original statement if current line is part of a continuation."
  (let ((here (point)))
    (blitzmax-mode--previous-line-of-code)
    (while (and (not (bobp))
                (looking-at blitzmax-mode-continuation-regexp))
      (setq here (point))
      (blitzmax-mode--previous-line-of-code))
    (goto-char here)))

(defun blitzmax-mode--find-matching-statement (open-regexp close-regexp)
  "Find the start of a pair that begins with OPEN-REGEXP and ends with CLOSE-REGEXP."
  (let ((level 0))
    (while (and (>= level 0) (not (bobp)))
      (blitzmax-mode--previous-line-of-code)
      (blitzmax-mode--find-original-statement)
      (cond ((looking-at close-regexp)
             (setq level (+ level 1)))
            ((looking-at open-regexp)
             (setq level (- level 1)))))))

(defun blitzmax-mode--find-matching-extern ()
  "Find the start of an If/End If statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-extern-start-regexp blitzmax-mode-extern-end-regexp))

(defun blitzmax-mode--find-matching-if ()
  "Find the start of an If/End If statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-if-regexp blitzmax-mode-endif-regexp)
  (when (blitzmax-mode--one-line-if-p)
    (blitzmax-mode--find-matching-if)))

(defun blitzmax-mode--find-matching-select ()
  "Find the start of a Select/End Select statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-select-regexp blitzmax-mode-select-end-regexp))

(defun blitzmax-mode--find-matching-for ()
  "Find the start of a For/Next statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-for-regexp blitzmax-mode-next-regexp))

(defun blitzmax-mode--find-matching-while ()
  "Find the start of a While/Wend statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-while-regexp blitzmax-mode-wend-regexp))

(defun blitzmax-mode--find-matching-repeat ()
  "Find the start of a Repeat/Until statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-repeat-regexp blitzmax-mode-until-regexp))

(defun blitzmax-mode--find-matching-defun ()
  "Find the start of a Method/End Method OR Function/End Function statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-defun-start-regexp blitzmax-mode-defun-end-regexp))

(defun blitzmax-mode--find-matching-try ()
  "Find the start of a Try/Catch statement."
  (blitzmax-mode--find-matching-statement blitzmax-mode-try-regexp blitzmax-mode-try-end-regexp))

(defun blitzmax-mode--calculate-indent ()
  "Calculate the indent level for the current line."
  (save-excursion
    (beginning-of-line)

    ;; Don't indent if at the start or end of a type.
    (cond ((or (looking-at blitzmax-mode-type-start-regexp)
               (looking-at blitzmax-mode-type-end-regexp))
           0)

          ;; Don't indent if at the start of end of an Extern
          ((or (looking-at blitzmax-mode-extern-start-regexp)
               (looking-at blitzmax-mode-extern-end-regexp))
           0)

          ;; Don't indent if on a label (#whatever).
          ((or (looking-at blitzmax-mode-label-regexp))
           0)

          ;; If in an Else/End If - indent to indentation of the matching If.
          ((or (looking-at blitzmax-mode-else-regexp)
               (looking-at blitzmax-mode-endif-regexp))
           (blitzmax-mode--find-matching-if)
           (current-indentation))

          ;; Remove indent for end function / end method
          ((looking-at blitzmax-mode-defun-end-regexp)
           (blitzmax-mode--find-matching-defun)
           (current-indentation))

          ;; All the other matching pairs act alike.
          ;; For/Next
          ((looking-at blitzmax-mode-next-regexp)
           (blitzmax-mode--find-matching-for)
           (current-indentation))

          ;; while/wend
          ((looking-at blitzmax-mode-wend-regexp)
           (blitzmax-mode--find-matching-while)
           (current-indentation))

          ;; repeat/until
          ((looking-at blitzmax-mode-until-regexp)
           (blitzmax-mode--find-matching-repeat)
           (current-indentation))

          ;; select case/end select
          ((looking-at blitzmax-mode-select-end-regexp)
           (blitzmax-mode--find-matching-select)
           (current-indentation))

          ;; CASE within a SELECT block.
          ((looking-at blitzmax-mode-case-regexp)
           (blitzmax-mode--find-matching-select)
           (+ (current-indentation) blitzmax-mode-indent))

          ;; Try/End Try block.
          ((or (looking-at blitzmax-mode-catch-regexp)
               (looking-at blitzmax-mode-try-end-regexp))
           (blitzmax-mode--find-matching-try)
           (current-indentation))

          ;; All other indentation depends on the previous lines.
          (t
           (blitzmax-mode--previous-line-of-code)

           ;; Skip over label lines, which always have 0 indent.
           (while (looking-at blitzmax-mode-label-regexp)
             (blitzmax-mode--previous-line-of-code))

           (blitzmax-mode--find-original-statement)
           (let ((indent (current-indentation)))
             ;; All the various +indent regexps.
             (cond ((and (looking-at blitzmax-mode-defun-start-regexp)
                         (not (blitzmax-mode--abstract-defun-p))
                         (not (blitzmax-mode--externed-function-p)))
                    (+ indent blitzmax-mode-indent))

                   ((looking-at blitzmax-mode-type-start-regexp)
                    (+ indent blitzmax-mode-indent))

                   ;; Extern block.
                   ((looking-at blitzmax-mode-extern-start-regexp)
                    (+ indent blitzmax-mode-indent))

                   ;; "Else"/"ElseIf is always indented
                   ((looking-at blitzmax-mode-else-regexp)
                    (+ indent blitzmax-mode-indent))

                   ;; Check if the "If" is a multi-line one.
                   ((and (looking-at blitzmax-mode-if-regexp)
                         (not (blitzmax-mode--one-line-if-p)))
                    (+ indent blitzmax-mode-indent))

                   ;; Select...Case block.
                   ((or (looking-at blitzmax-mode-select-regexp)
                        (looking-at blitzmax-mode-case-regexp))
                    (+ indent blitzmax-mode-indent))

                   ;; For...Next, While...Wend and Repeat...Until loops.
                   ((or (looking-at blitzmax-mode-for-regexp)
                        (looking-at blitzmax-mode-while-regexp)
                        (looking-at blitzmax-mode-repeat-regexp))
                    (+ indent blitzmax-mode-indent))

                   ;; Try...End Try.
                   ((or (looking-at blitzmax-mode-try-regexp)
                        (looking-at blitzmax-mode-catch-regexp))
                    (+ indent blitzmax-mode-indent))

                   ;; If nothing has changed, copy indent from prev line.
                   (t
                    indent)))))))

(defun blitzmax-mode--indent-to-column (col)
  "Indent current line to COL."
  (let* ((bol (save-excursion
                (beginning-of-line)
                (point)))
         (point-in-whitespace
          (<= (point) (+ bol (current-indentation))))
         (blank-line-p
          (save-excursion
            (beginning-of-line)
            (looking-at blitzmax-mode-blank-regexp))))

    (cond ((/= col (current-indentation))
           (save-excursion
             (beginning-of-line)
             (back-to-indentation)
             (delete-region bol (point))
             (indent-to col))))

    ;; If point was in the whitespace, move back-to-indentation.
    (cond (blank-line-p
           (end-of-line))
          (point-in-whitespace
           (back-to-indentation)))))

(defun blitzmax-mode-indent-line ()
  "Indent the current line."
  (interactive)
  (blitzmax-mode--indent-to-column (blitzmax-mode--calculate-indent)))


;; --------------------------------------------------
;; -- Quickrun Support

(declare-function quickrun-add-command "quickrun")
(defvar quickrun-file-alist)

;;;###autoload
(defun blitzmax-mode-quickrun-integration ()
  "Register BlitzMax with quickrun."

  ;; Will compile the current buffer in threaded + debug mode and then run it.
  (quickrun-add-command
    "blitzmax"
    `((:command  . ,blitzmax-mode-compiler-pathname)
      (:cmdopt   . "makeapp -h -d -o %e")
      (:exec     . ("%c %o %s"
                    "%e %a"))
      (:tempfile . nil)
      (:remove   . ("%e")))
    :mode 'blitxmax-mode
    :default "blitzmax")

  ;; Add `.bmx` to list of quickrun file types.
  (add-to-list 'quickrun-file-alist '("\\.bmx$" . "blitzmax")))


;; --------------------------------------------------
;; -- Main Mode

;;;###autoload
(define-derived-mode blitzmax-mode prog-mode "BlitzMax"
  "Major mode for editing BlitzMax source files."

  ;; Fontify buffer.
  (blitzmax-mode--fontify-buffer)

  ;; Enable smart indentation.
  (when blitzmax-mode-smart-indent-p
    (make-local-variable 'indent-line-function)
    (setq indent-line-function #'blitzmax-mode-indent-line))

  ;; Enable automatic capitalization.
  (when blitzmax-mode-capitalize-keywords-p
    (make-local-variable 'pre-abbrev-expand-hook)
    (add-hook 'pre-abbrev-expand-hook #'blitzmax-mode--capitalize-keywords)
    (abbrev-mode 1))

  ;; Add single line comments to syntax table.
  (modify-syntax-entry ?\' "< b" blitzmax-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" blitzmax-mode-syntax-table)

  ;; Configure comment syntax for comment-line/comment-region.
  (setq-local comment-start      "' ")
  (setq-local comment-end        "")
  (setq-local comment-start-skip "'[ \t]*")
  (setq-local comment-column     0)
  (setq-local comment-use-syntax t)

  ;; Modify syntax to not treat \ as an escape char. Treat ~ as one instead.
  (modify-syntax-entry ?\\ "." blitzmax-mode-syntax-table)
  (modify-syntax-entry ?~ "\\" blitzmax-mode-syntax-table)

  ;; Additional syntax support.
  (setq syntax-propertize-function blitzmax-mode--syntax-propertize-function))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bmx\\'" . blitzmax-mode))

;;;###autoload
(add-to-list 'interpreter-mode-alist '("bmx" . blitzmax-mode))

(provide 'blitzmax-mode)
;;; blitzmax-mode.el ends here
