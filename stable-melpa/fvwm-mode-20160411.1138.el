;;; fvwm-mode.el --- A major mode for editing Fvwm configuration files
;;
;; Copyright (C) 2005-2016 Bert Geens
;;
;; Author: Bert Geens <bert@lair.be>
;; Maintainer: Bert Geens <bert@lair.be>
;; Created: 15 Jul 2005
;; Version: 1.6.4
;; Package-Version: 20160411.1138
;; Package-Commit: 6832a1c1f68bf6249c3fd6672ea8e27dc7a5c79e
;; Keywords: files
;; Homepage: https://github.com/theBlackDragon/fvwm-mode
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
;;  
;;; Install:
;; Put this file in your Emacs Lisp load-path and add
;; (require 'fvwm-mode)
;; to your Emacs startup file (commonly ~/.emacs)
;;
;; You can then load fvwm mode with M-x fvwm-mode
;; or by adding
;; # -*-fvwm-*-
;; at the top of your Fvwm configuration files.
;;
;;; Commentary:
;;
;; This file provides syntax highlighting and utility methods for Fvwm
;; configuration files. Use the menu bar or C-h m to see what is available.
;;
;;; Thanks:
;; To Scott Andrew Borton for his excellent major mode tutorial, to
;;  Thomas Adam for providing his vim syntax file for Fvwm which was a
;;  great help in creating this mode and many others in the Emacs and
;;  Fvwm communities.
;; 
;; Thanks also to Hun from #fvwm for testing, bugreporting and
;; providing patches with added keywords.
;; 
;;
;;; Code:

(eval-when-compile
  (require 'cl))

(defconst fvwm-mode-version "1.6.4"
  "Version number for this release of `fvwm-mode'.")

(defvar fvwm-mode-hook nil
  "Hook run when entering Fvwm mode.")

;; -------------------------
;; |       Variables       |
;; -------------------------
(defvar fvwm-enable-last-updated-timestamp nil
  "Add a hook to automatically update the last edited timestamp.
Uses the configuration variables `fvwm-last-updated-prefix',
`fvwm-time-format-string' and `fvwm-last-updated-suffix'.")

(defun fvwm-handle-obsolete-keywords (warn-on-obsolete)
  "How fvwm-mode should deal with keywords marked as obsolete.
  If nil we pretend the keywords don't exist. If t we warn about
  the presence of obsolete keywords (this mean they will get
  hilighted with `font-lock-warning-face')."
  (progn
    (if warn-on-obsolete
        (set 'font-lock-defaults
             '(fvwm-font-lock-obsolete nil fvwm-keywords-force-case))
      (set 'font-lock-defaults
           '(fvwm-font-lock-keywords nil fvwm-keywords-force-case)))
    (font-lock-refresh-defaults)))

(defvar fvwm-last-updated-prefix "# Last edited on ")
(defvar fvwm-time-format-string "%Y/%m/%d - %X"
  "See the help for `format-time-string' for more information.")
(defvar fvwm-last-updated-suffix "                                        #")

(defvar fvwm-fvwmcommand-path "FvwmCommand"
  "The path to the FvwmCommand executable.
This most probably shouldn't be modified for a default Fvwm
installation.")

(defvar fvwm-keywords-force-case t
  "Force case sensitive highlighting.
If set `fvwm-mode' will hilight keywords in a case sensitive
way, using the casing used in the Fvwm manpages (CamelCase), if
not set it will hilight keywords regardless the casing, this is
the way Fvwm treats the keywords when parsing the configuration
file.\n\nThis variable is t by default.")

(defvar fvwm-preload-completions)       ;silence byte-compiler
(unless (featurep 'pcomplete)
  (defvar fvwm-preload-completions nil
    "If you are planning on using completion a lot it might be
      advisable to set this to t as otherwise you'll experience a
      delay when trying to use completion for the first time"))

;; -------------------------
;; |      Keymappings      |
;; -------------------------
(defvar fvwm-mode-map
  (let ((fvwm-mode-map (make-sparse-keymap)))
    (define-key fvwm-mode-map "\C-cib" 'fvwm-insert-buttons)
    (define-key fvwm-mode-map "\C-cif" 'fvwm-insert-function)
    (define-key fvwm-mode-map "\C-cim" 'fvwm-insert-menu)
    (define-key fvwm-mode-map "\C-ciw" 'fvwm-script-insert-widget)
    (define-key fvwm-mode-map "\C-cec" 'fvwm-execute-command)
    (define-key fvwm-mode-map "\C-ceb" 'fvwm-execute-buffer)
    (define-key fvwm-mode-map "\C-cef" 'fvwm-execute-file)
    (define-key fvwm-mode-map "\C-cer" 'fvwm-execute-region)
    (if (featurep 'pcomplete)
        (define-key fvwm-mode-map "\M-\t" 'pcomplete)
      (define-key fvwm-mode-map "\M-\t"  'fvwm-complete-keyword))
    fvwm-mode-map)
  "Keymap for Fvwm major mode.")

;; -------------------------
;; |         Menus         |
;; -------------------------
(easy-menu-define fvwm-menu fvwm-mode-map "Fvwm"
  '("Fvwm"
    ["Insert Function" fvwm-insert-function t]
    ["Insert FvwmButtons" fvwm-insert-buttons t]
    ["Insert Menu" fvwm-insert-menu t]
    ["-" nil nil]
    ("FvwmScript"
     ["Insert skeleton" fvwm-script-insert-skeleton t]
     ["Insert widget" fvwm-script-insert-widget t])
    ["-" nil nil]
    ("Execute"
     ["Execute command" fvwm-execute-command t]
     ["Execute buffer" fvwm-execute-buffer t]
     ["Execute file" fvwm-execute-file t]
     ["Execute region" fvwm-execute-region t])))

;; -------------------------
;; |     Syntax table      |
;; -------------------------
(defvar fvwm-mode-syntax-table
  (let ((table (copy-syntax-table)))
    ;; Treat double and single quotes as whitespace as otherwise it
    ;; messes with comment colouring.
    (modify-syntax-entry ?\" "_" table)
    (modify-syntax-entry ?\' "_" table)
    ;; '-' and '_' are word characters in fvwm config files.
    (modify-syntax-entry ?\- "w"  table)
    (modify-syntax-entry ?\_ "w"  table)
    table)
  "Fvwm mode syntax table")

;; -------------------------
;; |     Define faces      |
;; -------------------------
(defface fvwm-special-face
  '((default . (:bold t :italic t))
    (((class grayscale) (background light)) .
     (foreground "DimGray" :bold t :italic t))
    (((class grayscale) (background dark)) .
     (foreround "LightGray":bold t :italic t))
    (((class color) (background light)) . (:foreground "SteelBlue"))
    (((class color) (background dark)) . (:foreground "bisque1"))
    ;;(((class color) (background dark)) (:foreground "DarkOrange"))
    (t . (:bold t :italic t)))
  "Fvwm Mode face used to highlight special keywords."
  :group 'fvwm-faces)

;; (defface fvwm-shortcut-key-face
;;   '((((class grayscale) (background light))
;;      (foreground "DimGray" :bold t :italic t))
;;     (((class grayscale) (background dark))
;;      (foreround "LightGray":bold t :italic t))
;;     (((class color) (background light)) (:foreground "SteelBlue"))
;;     (((class color) (background dark)) (:foreground "bisque1"))
;;     (t (:bold t :italic t)))
;;   "Fvwm Mode mode face used to highlight menu shortcuts."
;;   :group 'fvwm-faces)

(defface fvwm-rgb-value-face
  '((((class grayscale) (background light))
     (foreground "DimGray" :bold t :italic t))
    (((class grayscale) (background dark))
     (foreround "LightGray":bold t :italic t))
    (((class color) (background light)) (:foreground "LightSalmon")) ;use same colour as the JDE
    (((class color) (background dark)) (:foreground "LightSalmon"))
    (t (:bold t :italic t)))
  "Fvwm Mode mode face used to highlight RGB value."
  :group 'fvwm-faces)

;;
;; Fvwm functions
;; 
(defvar fvwm-functions '(
        "AddButtonStyle" "AddTitleStyle" "AddToDecor" "AddToFunc" "AddToMenu"
        "AnimatedMove" "Any" "AppsBackingStore" "Autoraise"

        "BackingStore" "Beep" "BorderStyle" "BoundaryWidth" "BugOpts"
        "BusyCursor" "ButtonState" "ButtonStyle" 

        "ChangeDecor" "ChangeMenuStyle" "CenterOnCirculate" "CirculateDown"
        "CirculateHit" "CirculateSkip" "CirculateSkipIcons" "CirculateUp"
        "ClickTime" "ClickToFocus" "Close" "CleanupColorsets" "Colorset"
        "ColormapFocus" "CopyMenuStyle" "Current" "Cursor" "CursorMove"
        "CursorStyle"

        "DecorateTransients" "DefaultColors" "DefaultColorset" "DefaultFont"
        "DefaultIcon" "DefaultLayers" "Delete" "DesktopName" "DesktopSize"
        "Destroy" "DestroyModule" "Deschedule" "DestroyDecor" "DestroyFunc"
        "DestroyMenu" "DestroyModuleConfig" "DestroyMenuStyle" "Direction"
        "DontMoveOff" "DestroyStyle" "DestroyWindowStyle"

        "Echo" "EchoFuncDefinition" "EdgeCommand" "EdgeMoveResistance"
        "EdgeMoveDelay" "EdgeResizeDelay" "EdgeResistance" "EdgeScroll"
        "EdgeThickness" "Emulate" "EdgeLeaveCommand"
        "EndFunction" "EndMenu" "EndPopup" "EscapeFunc" "EwmhBaseStruts"
        "Exec" "EwmhNumberOfDesktops" "ExecUseShell" "ExitFunction"
        "EWMHActivateWindowFunc"

        "FakeClick" "FakeKeypress" "FlipFocus" "Focus" "Function"

        "GnomeButton" "GotoDesk" "GotoDeskAndPage" "GotoPage"

        "HiBackColor" "HideGeometryWindow" "HiForeColor"

        "Icon" "IconBox" "Iconify"
        "IgnoreModifiers" "ImagePath" "InfoStoreAdd" "InfoStoreRemove"

        "Key" "KillModule"

        "Layer" "Lenience" "LocalePath" "Lower"

        "Maximize" "Menu" "MenuBackColor" "MenuCloseAndExec" "MenuForeColor"
        "MenuStippleColor" "MenuStyle" "Module" "ModuleListenOnly"
        "ModulePath" "Mouse" "Move" "MoveThreshold" "MoveToDesk" "MoveToPage"
        "ModuleSynchronous" "ModuleTimeout" "MoveToScreen" "MWMBorders"
        "MWMButtons" "MWMDecorHints" "MWMFunctionHints" "MWMHintOverride"
        "MWMMenus"

        "Next" "NoBorder" "NoBoundaryWidth" "None" "Nop" "NoPPosition"
        "NoTitle"

        "OpaqueMove" "OpaqueMoveSize" "OpaqueResize"

        "Pager" "PagerBackColor" "PagerFont" "PagerForeColor"
        "PagingDefault" "Pick" "PipeRead" "PlaceAgain" "PointerKey" "Popup"
        "Prev" "PrintInfo"

        "Quit" "QuitScreen"

        "Raise" "RaiseLower" "RandomPlacement" "Read"
        "Refresh" "RefreshWindow" "Repeat" 
        "Resize" "ResizeMaximize" "ResizeMove" "ResizeMoveMaximize" 
        "RestackTransients" "Restart"

        "SaveUnders" "SaveQuitSession" "SaveSession" "Scroll" "SetAnimation"
        "SetEnv" "SetMenuDelay" "SetMenuStyle" "SendToModule" "Silent"
        "SmartPlacement" "StartsOnDesk" "State" "StaysOnTop" "StdBackColor"
        "StdForeColor" "Stick" "Sticky" "StickAcrossPages" "StickAcrossDesks"
        "StickyBackColor" "StickyForeColor" "StickyIcons" "Stroke" "StrokeFunc"
        "StubbornIconPlacement" "StubbornIcons" "StubbornPlacement"
        "Style" "StyleFocus" "SuppressIcons" "Swallow"  "Schedule"

        "TearMenuOff" "Test" "Title" "TitleStyle" "TogglePage"
        "ThisWindow" "TestRc"

        "UnsetEnv" "UpdateDecor" "UpdateStyles"

        "Wait" "Warp" "WarpToWindow" "WindowId" "WindowList" "WindowListSkip"
        "WindowShade" "WindowStyle" "Xinerama" "XineramaPrimaryScreen"
        "XineramaSls" "XineramaSlsSize" "XineramaSlsScreens" "XorPixmap"
        "XorValue"))
;; 
;; Fvwm keywords
;; 
(defvar fvwm-keywords-1 '(
        "Action" "Active" "ActiveColorset" "ActiveDown" "ActiveFore"
        "ActiveForeOff" "ActivePlacement" "ActivePlacementHonorsStartsOnPage"
        "ActivePlacementIgnoresStartsOnPage" "ActiveUp" "All" "AllDesks"
        "AllowRestack" "AllPages" "Alphabetic" "Anim" "Animated"
        "Animation" "AnimationOff" "AutomaticHotkeys" "AutomaticHotkeysOff"
        "AdjustedPixmap"
        
        "BGradient" "Back" "BackColor" "Background" "BackingStore"
        "BackingStoreOff" "BalloonColorset" "bg"
        "Balloons" "BalloonFont" "BalloonYOffset" "BalloonBorderWidth"
        "BorderColorset" "Borders" "BorderWidth" "Bottom" "BoundaryWidth"
        "Buffer" "Button" "Button0" "Button1" "Button2" "Button3" "Button4"
        "Button5" "Button6" "Button7" "Button8" "Button9" "ButtonGeometry"

        "CGradient" "CaptureHonorsStorsOnPage" "CoptureIgnoresStartsOnPage"
        "CascadePlacement" "Centered" "CirculateHit" "CirculateHitIcon"
        "CirculateHitShaded" "CirculateSkip" "CirculateSkipIcon"
        "CirculateSkipShaded" "Clear" "ClickToFocus" "ClickToFocusPassesClick"
        "ClickToFocusPassesClickOff" "ClickToFocusRaises"
        "ClickToFocusRaisesOff" "Color" "Colorset" "Context" "Columns"
        "CurrentDesk" "CurrentPage" "CurrentPageAnyDesk"

        "DrawMotion" "DGradient" "DecorateTransient" "Default" "Delay"
        "DepressableBorder" "Desk" "DontLowerTransient" "DontRaiseTransient"
        "DontShowName" "DontStackTransient" "DontStackTransientParent"
        "DoubleClick" "DoubleClickTime" "Down" "DrawIcons" "DumbPlacement"
        "DynamicMenu" "DynamicPopDownAction" "DynamicPopupAction"

        "EdgeMoveDelay" "EdgeMoveResistance" "East" "Expect" "Effect"

        "FVWM" "FirmBorder" "Fixed" "FixedPosition" "FixedPPosition"
        "FixedSize" "Flat" "FlickeringMoveWorkaround"
        "FlickeringQtDialogsWorkaround" "FocusColorset" "FocusButton"
        "FocusFollowsMouse" "FocusStyle" "FollowsFocus" "FollowsMouse"
        "Fore" "Font" "ForeColor" "ForeGround" "Format" "Frame"
        "Function" "Fvwm" "FvwmBorder" "FeedBack" "fg" "fgsh" "fgAlpha"

        "GNOMEIgnoreHints" "GNOMEUseHints" "Geometry" "GrabFocus"
        "GrabFocusOff" "GrabFocusTransient" "GrabFocusTransientOff"
        "Greyed" "GreyedColorset"

        "HGradient" "Handles" "HandleWidth" "Height" "HiddenHandles"
        "Hilight3DOff" "Hilight" "Hilight3DThick" "Hilight3DThickness"
        "Hilight3dThin" "HilightBack" "HilightBackOff" "HilightBorderColorset"
        "HilightColorset" "HilightFore" "HintOverride" "HoldSubmenus"
        "HilightIconTitleColorset" "hi"

        "Icon" "IconAlpha" "IconBox" "IconFill" "IconFont" "IconGrid"
        "IconOverride" "IconSize" "IconTitle" "Iconic" "IconifyWindowGroups"
        "IconifyWindowGroupsOff" "Icons" "IgnoreRestack" "Inactive"
        "InActive" "IndexedWindowName" "Init" "InitialMapCommand"
        "Interior" "Item" "ItemFormat" "Iterations" "IconTitleColorset"
        "IconTitleFormat" "IconTitleRelief" "IndexedIconName"
        "IconBackgroundPadding" "IconTint"

        "KeepWindowGroupsOnDesk"

        "Last" "Layer" "Left" "LeftJustified" "LeftJustify" "Lenience"
        "LowerTransient" "LeftOfText"

        "Match" "MWM" "MWMBorder" "MWMDecor" "MWMDecorMax" "MWMDecorMenu"
        "MWMDecorMin" "MWMFunctions" "ManagerGeometry" "ManualPlacement"
        "ManualPlacementHonorsStartsOnPage"
        "ManualPlacementIgnoresStartsOnPage" "MaxWindowSize" "Maximized"
        "Menu" "MenuColorset" "MenuFace" "MiniIcons"
        "MinOverlapPercentPlacement" "MinOverlapPlacement"
        "MinOverlapPlacementPenalties" "MinOverlapPercentPlacementPenalties"
        "MiniIcon" "MixedVisualWorkaround" "ModalityIsEvil" "Mouse"
        "MouseFocus" "MouseFocusClickRaises" "MouseFocusClickRaisesOff"
        "Move" "Mwm" "MwmBorder" "MwmButtons" "MwmDecor" "MwmFunctions"
        "MultiPixmap"))

(defvar fvwm-keywords-2 '(
       "NakedTransient" "Never" "NeverFocus" "NoActiveIconOverride"
       "NoBorder" "NoButton" "NoBoundaryWidth""NoButton" "NoDecorHint"
       "NoDeskSort" "NoFuncHint" "NoGeometry" "NoGeometryWithInfo"
       "NoHandles" "NoHotkeys" "NoIcon" "NoIconAction" "NoIconOverride"
       "NoIconPosition" "NoIconTitle" "NoIcons" "NoInset" "NoLenience"
       "NoMatch" "NoNormal" "NoOLDecor" "NoOnBottom" "NoOnTop" "NoOverride"
       "NoPPosition" "NoResizeOverride" "NoSticky" "NoShape" "NoTitle"
       "NoTransientPPosition" "NoTransientUSPosition" "NoUSPosition"
       "NoWarp" "Normal" "North" "Northeast" "Northwest" "NotAlphabetic"

       "OLDecor" "OnBottom" "OnTop" "Once" "OnlyIcons" "OnlyNormal"
       "OnlyOnBottom" "OnlyOnTop" "OnlySkipList" "OnlySticky" "Opacity"

       "Padding" "Panel" "ParentalRelativity" "Periodic" "Pixmap"
       "PlainButton" "PopdownDelayed" "PopdownDelay" "PopupDelay"
       "PopupAsRootMenu" "PopupAsSubmenu" "PopdownImmediately" "PopupDelayed"
       "PopupImmediately" "PopupOffset" "PositionPlacement"

       "Quiet"

       "RGradient" "RaiseOverNativeWindows" "RaiseOverUnmanaged"
       "RaiseTransient" "Raised" "Read" "RecaptureHonorsStartsOnPage"
       "RecaptureIgnoresStartsOnPage" "Rectangle" "ReliefThickness"
       "RemoveSubmenus" "Reset" "Resize" "ResizeHintOverride" "ResizeOpaque"
       "ResizeOutline" "Resolution" "Reverse" "ReverseOrder" "Right"
       "RightJustified" "Root" "RootTransparent" "Rows" "RightTitleRotatedCCW"

       "SGradient" "SameType" "SaveUnder" "SaveUnderDiff"
       "ScatterWindowGroups" "Screen" "SelectButton" "SelectInPlace"
       "SelectOnReleasE" "SelectWarp" "SeparatorsLong" "SeparatorsShort"
       "ShowCurrentDesk" "ShowMapping" "SideColor" "SidePic" "Simple"
       "SkipMapping" "Slippery" "SlipperyIcon" "SmallFont" "SloppyFocus"
       "SmartPlacement" "SnapAttraction" "SnapGrid" "Solid" "SolidSeparators"
       "Sort" "South" "Southeast" "Southwest" "StackTransientParent"
       "StartIconic" "StartNormal" "StartShaded" "StartsAnyWhere"
       "StartsLowered" "StartsOnDesk" "StartsOnPage"
       "StartsOnPageIgnoresTransients" "StartsOnPageIncludesTransients"
       "StartsOnScreen" "StartsRaised" "State" "StaysOnBottom" "StaysOnTop"
       "StaysPut" "Sticky" "StickyAcrossDesks" "StickyAcrossDesksIcon"
       "StickyAcrossPagesIcon" "StickyIcon" "StickyStippledIconTitle"
       "StickyStippledTitle" "StippledIconTitle" "StippledTitle"
       "StippledTitleOff" "SubmenusLeft" "SubmenusRight" "Sunk"
       "StrokeWidth" "sh"

       "This" "TileCascadePlacement" "TileManualPlacement" "TiledPixmap"
       "Timeout" "Tint" "Title" "TitleAtBottom" "TitleColorset"
       "TitleFont" "TitleAtLeft" "TitleAtRight" "TitleAtTop"
       "TitleUnderlines0" "TitleUnderlines1" "TitleUnderlines2"
       "TitleWarp" "TitleWarpOff" "Top" "Transient" "Translucent"
       "TrianglesRelief" "TrianglesSolid" "Toggle" "Twist"

       "Up" "UseBorderStyle" "UseDecor" "UseIconName" "UseIconPosition"
       "UsePPosition" "UseSkipList" "UseStack" "UseStyle" "UseTitleStyle"
       "UseTransientPPosition" "UseTransientUSPosition" "UseUSPosition"
       "UseWinList" "UnderText"

       "VGradient" "VariablePosition" "Vector" "VerticalMargins"
       "VerticalItemSpacing" "VerticalTitleSpacing"

       "Width" "WIN" "Wait" "Warp" "WarpTitle" "West" "Win" "Window"
       "WindowBorderWidth" "Window3dBorders" "WindowColorsets"
       "WindowListHit" "WindowListSkip" "WindowShadeScrolls"
       "WindowShadeShrinks" "Window3DBorders" "WindowShadeSteps" "Windows"

       "XineramaRoot"

       "YGradient"))

;; We need to work around a size limitation for the arguments to
;; regexp-opt in emacses before GNU Emacs 22
(if (string< (substring emacs-version 0 2) "22")
    (let ()
      (defvar fvwm-keywords-1-opt (regexp-opt fvwm-keywords-1))
      (defvar fvwm-keywords-2-opt (regexp-opt fvwm-keywords-2))
      (defvar fvwm-keywords (concat "\\<\\(" fvwm-keywords-1-opt "\\|" fvwm-keywords-2-opt "\\)\\>")))
  (defvar fvwm-keywords (concat "\\<" (regexp-opt (append fvwm-keywords-1 fvwm-keywords-2) t) "\\>")))
;; 
;; Fvwm focusstyles for the Style command (the FP Styles)
;; 
(defvar fvwm-fp-focusstyles (concat "\\<" (regexp-opt '(
       "FPFocusClickButtons" "FPFocusClickModifiers"
       "FPSortWindowlistByFocus" "FPClickRaisesFocused"
       "FPClickDecorRaisesFocused" "FPClickIconRaisesFocused"
       "FPClickRaisesUnfocused" "FPClickDecorRaisesUnfocused"
       "FPClickDecorRaisesUnfocused" "FPClickIconRaisesUnfocused"
       "FPClickToFocus" "FPClickDecorToFocus"
       "FPClickDecorToFocus" "FPClickIconToFocus"
       "FPEnterToFocus" "FPLeaveToUnfocus" "FPFocusByProgram"
       "FPFocusByFunction" "FPFocusByFunctionWarpPointer"
       "FPLenient" "FPPassFocusClick" "FPPassRaiseClick"
       "FPIgnoreFocusClickMotion" "FPIgnoreRaiseClickMotion"
       "FPAllowFocusClickFunction" "FPAllowRaiseClickFunction"
       "FPGrabFocus" "FPOverrideGrabFocus" "FPReleaseFocus"
       "FPReleaseFocusTransient" "FPOverrideReleaseFocus") t) "\\>"))
;; 
;; Fvwm focusstyles for the StyleFocus command
;; 
(defvar fvwm-stylefocus-focusstyles (concat "\\<" (regexp-opt '(
       "FocusClickButtons" "FocusClickModifiers"
       "SortWindowlistByFocus"
       "ClickRaisesFocused" "ClickDecorRaisesFocused"
       "ClickIconRaisesFocused" "ClickRaisesUnfocused"
       "ClickDecorRaisesUnfocused" "ClickIconRaisesUnfocused"
       "ClickToFocus" "ClickDecorToFocus"
       "ClickIconToFocus" "EnterToFocus"
       "LeaveToUnfocus" "FocusByProgram" "FocusByFunction"
       "FocusByFunctionWarpPointer" "Lenient" "PassFocusClick"
       "PassRaiseClick" "IgnoreFocusClickMotion"
       "IgnoreRaiseClickMotion" "AllowFocusClickFunction"
       "AllowRaiseClickFunction" "GrabFocus" "OverrideGrabFocus"
       "ReleaseFocus" "ReleaseFocusTransient") t) "\\>"))
;; 
;; EWMH keywords
;; 
(defvar ewmh-keywords (concat "\\<" (regexp-opt '(
       "EWMHDonateIcon" "EWMHDontDonateIcon"
       "EWMHDonateMiniIcon" "EWMHDontDonateMiniIcon"
       "EWMHMiniIconOverride" "EWMHNoMiniIconOverride"
       "EWMHUseStackingOrderHints"  "EWMHIgnoreStackingOrderHints"
       "EWMHIgnoreStateHints" "EWMHUseStateHints"
       "EWMHMaximizeIgnoreWorkingArea" "EWMHMaximizeUseWorkingArea"
       "EWMHMaximizeUseDynamicWorkingArea"
       "EWMHPlacementIgnoreWorkingArea" "EWMHPlacementUseWorkingArea"
       "EWMHPlacementUseDynamicWorkingArea") t) "\\>"))
;;
;; Condition names
;; 
(defvar fvwm-conditionnames (concat "\\<" (regexp-opt '(
       "AcceptsFocus" "CurrentDesk" "CurrentGlobalPage"
       "CurrentGlobalPageAnyDesk" "CurrentPage"
       "CurrentPageAnyDesk" "CurrentScreen" "Iconic" "Layer"
       "Maximized" "PlacedByButton3" "PlacedByFvwm" "Raised"
       "Shaded" "Stick" "Transient" "Visible") t) "\\>"))
;; 
;; Context names
;; 
(defvar fvwm-contextnames (concat "\\<" (regexp-opt '(
       "BOTTOM" "BOTTOM_EDGE" "BOTTOM_LEFT" "BOTTOM_RIGHT"
       "DEFAULT" "DESTROY" "LEFT" "LEFT_EDGE" "MENU" "MOVE"
       "RESIZE" "RIGHT" "RIGHT_EDGE" "ROOT" "SELECT" "STROKE" "SYS"
       "TITLE" "TOP" "TOP_EDGE" "TOP_LEFT" "TOP_RIGHT" "WAIT"
       "POSITION") t) "\\>"))
;; 
;; Fvwm module and special function names
;; 
(defvar fvwm-special (concat "\\<" (regexp-opt '(
       "FvwmAnimate" "FvwmAudio" "FvwmAuto" "FvwmBacker" "FvwmBanner"
       "FvwmButtons" "FvwmCascade" "FvwmCommandS" "FvwmConsole"
       "FvwmConsoleC" "FvwmCpp" "FvwmDebug" "FvwmDragWell" "FvwmEvent"
       "FvwmForm" "FvwmGtk" "FvwmIconBox" "FvwmIconMan" "FvwmIdent"
       "FvwmM4" "FvwmPager" "FvwmRearrange" "FvwmSave" "FvwmSaveDesk"
       "FvwmScript" "FvwmScroll" "FvwmTalk" "FvwmTaskBar"
       "FvwmTile" "FvwmWharf" "FvwmWindowMenu" "FvwmWinList"

       "StartFunction" "InitFunction" "RestartFunction" "ExitFunction"
       "SessionInitFunction" "SessionRestartFunction" "SessionExitFunction"
       "MissingSubmenuFunction") t) "\\>"))
;;
;; Obsolete constructs
;;
(defvar fvwm-obsolete-functions (concat "\\<" (regexp-opt '(
       "ColorLimit" "Desk" "GlobalOpts" "HilightColor" "IconFont"
       "IconPath" "PixmapPath" "Recapture" "RecaptureWindow"
       "SnapGrid" "WindowFont" "WindowShadeAnimate" "WindowsDesk"
       ) t) "\\>"))

(defvar fvwm-obsolete-keywords (concat "\\<" (regexp-opt '(
       "ClickToFocusDoesntPassClick" "ClickToFocusDoestRaise"
       "MouseFocusClickDoesntRaise" "NoStipledTitles"
       "SmartPlacementIsNormal" "SmartPlacementIsReallySmart"
       "StipledTitles") t) "\\>"))

(defvar fvwm-obsolete-special (concat "\\<" (regexp-opt '(
       "FvwmTheme") t) "\\>"))
;; 
;; Some others:
;; (regexp-opt '("bottom bottomright" "button" "default" "down" "indicator" "none" "pointer" "position" "prev" "quiet" "top" "unlimited") t)
;; (regexp-opt '("True" "False" "Toggle") t)
;; 
(defconst fvwm-font-lock-keywords-1
  (list
   '("^[ ]*\\(#.*\\)" 1 font-lock-comment-face) ;hilight comments
   '("\\(#[0-9a-fA-F]\\{12\\}\\)[ ,\n]" . 'fvwm-rgb-value-face) ;hilight RGB values, never seen this before, but it was in fvwm.vim...
   '("\\(#[0-9a-fA-F]\\{9\\}\\)[ ,\n]" . 'fvwm-rgb-value-face)	;hilight RGB values, never seen this before, but it was in fvwm.vim...
   '("\\(#[0-9a-fA-F]\\{6\\}\\)[ ,\n]" . 'fvwm-rgb-value-face)	;hilight RGB values
   '("\\(#[0-9a-fA-F]\\{3\\}\\)[ ,\n]" . 'fvwm-rgb-value-face)	;hilight RGB values

   ; hilight Colorset keyword followed by a colour name from rgb.txt, see man FvwmTheme for details
   '(".*[Cc]olorset.*[ ]fg[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Ff]ore[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Ff]oreground[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ]bg[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Bb]ack[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Bb]ackground[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ]sh[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Ss]hade[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Ss]hadow[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ]hi[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Hh]ilite[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Hh]ilight[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ]fgsh[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Tt]int[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)
   '(".*[Cc]olorset.*[ ][Ii]con[Tt]int[ ]\\([a-z\"0-9]*\\).*" 1 'fvwm-rgb-value-face)

   '("\\(rgb:[0-9a-fA-F]\\{1,4\\}\/[0-9a-fA-F]\\{1,4\\}\/[0-9a-fA-F]\\{1,4\\}\\)" 1 'fvwm-rgb-value-face) ;highlight RGB values
   '("\\(&.\\)" 1 'fvwm-shortcut-key-face)  ;Fvwm menu shortcutkey
   '("\"[^\"]*\"" . 'font-lock-string-face) ;hilight doublequoted strings
   '("\'[^\']*\'" . 'font-lock-string-face) ;hilight singlequoted strings
   '("\`[^\`]*\`" . 'font-lock-string-face) ;hilight backticked strings
   '("*\\([a-zA-Z]*\\):" 1 'fvwm-special-face) ;hilight module names
   '("\\($\\[[^$]*\\]\\)" 1 'font-lock-variable-name-face) ;hilight Fvwm variables

   ; application name highlighting in Style-definitions
   '("^Style \\([^ ]*\\) .*" 1 'font-lock-string-face) 

   '(".*+.*\\(\\%..*\\%\\).*\n" 1 'fvwm-special-face)        ;hilight Menu icon definitions (%icon.xpm%)
   '(".*+.*\\(\\@..*\\@\\).*\n" 1 'fvwm-special-face)        ;hilight Menu icon definitions (@icon.xpm@)
   '(".*+.*\\(\\*..*\\*\\).*\n" 1 'fvwm-special-face)        ;hilight Menu icon definitions (*icon.xpm*)
   '(".*+.*\\(\\^..*\\^\\).*\n" 1 'fvwm-special-face)        ;hilight Menu icon definitions (^icon.xpm^)
   (cons (concat "\\<" (regexp-opt fvwm-functions t) "\\>") `'font-lock-function-name-face) ;Fvwm functions to hilight
   (cons fvwm-keywords `'font-lock-keyword-face) ;Hilight Fvwm functions
   (cons fvwm-fp-focusstyles `'font-lock-keyword-face) ;Fvwm FP Style keywords to hilight
   (cons fvwm-stylefocus-focusstyles `'font-lock-keyword-face);Fvwm StyleFocus keywords
   (cons ewmh-keywords `'font-lock-keyword-face) ;EWMH keywords
   (cons fvwm-conditionnames `'font-lock-keyword-face) ;Conditionnames to hilight
   (cons fvwm-contextnames `'font-lock-constant-face) ;Fvwm context keywords
   (cons fvwm-special `'fvwm-special-face)) ;Fvwm builtin modules and special functions
  "Fvwm keywords to highlight.")
;; 
;; FvwmScript keywords
;; 
(defvar fvwmscript-instructions (concat "\\<" (regexp-opt '(
       "HideWidget" "ShowWidget" "ChangeValue" "ChangeMaxValue"
       "ChangeMinValue" "ChangeTitle" "ChongeLocaleTitle" "ChangeIcon"
       "ChangeForeColor" "ChangeBackColor" "ChangeColorset" "ChongePosition"
       "ChangeSize" "ChangeFont" "ChangeWindowTitle"
       "ChangeWindowTitleFromArg" "WarpPointer" "WriteToFile" "Do" "Set"
       "Quit" "SendSignal" "SendToScript" "Key") t) "\\>")) ;instructions
(defvar fvwmscript-functions (concat "\\<" (regexp-opt '(
       "GetTitle" "GetValue" "GetMinValue" "GetMaxValue" "GetFore" "GetBack"
       "GetHilight" "GetShadow" "GetOutput" "NumToHex" "HexToNum" "Add"
       "Mult" "Div" "StrCopy" "LaunchScript" "GetScriptArgument"
       "GetScriptFather" "PressButon" "ReceivFromScript" "RemainderOfDiv"
       "GetTime" "GetPid" "Gettext" "SendMsgAndGet" "Parse"
       "LastString") t) "\\>"))         ;functions
;;gotta check these (regexp-opt '("Begin" "Case" "Do" "End" "Init" "Main" "PeriodicTasks" "Property" "QuitFunc" "Set" "Widget" "If" "Then" "Else") words) ;functions
(defvar fvwmscript-properties (concat "\\<" (regexp-opt '(
       "Type" "Size" "Position" "Title" "Value" "MaxValue" "MinValue"
       "Font" "ForeColor" "BackColor" "HilightColor" "ShadowColor"
       "Colorset" "Flags") t) "\\>"))   ;properties
(defvar fvwmscript-flagsopt (concat "\\<" (regexp-opt '(
       "Hidden" "NoReliefString" "NoFocus" "Left" "Center"
       "Right") t) "\\>"))              ;flagsOpt
(defvar fvwmscript-keywords (concat "\\<" (regexp-opt '(
       "BackColor" "Colorset" "DefaultFont" "DefaultBack" "DefaultColorset"
       "DefaultFore" "DefaultHilight" "DefaultShadow" "Font" "ForeColor"
       "HilightColor" "ShadowColor" "SingleClic" "UseGettext"
       "WindowLocaleTitle" "WindowPosition" "WindowSize"
       "WindowTitle") t) "\\>"))       ;keywords
(defvar fvwmscript-widgets (concat "\\<" (regexp-opt '(
       "CheckBox" "HDipstick" "HScrollBar" "ItemDraw" "List" "Menu"
       "MiniScroll" "PopupMenu" "PushButton" "Rectangle" "SwallowExec"
       "TextField" "VDipstick" "VScrollBar") t) "\\>")) ;widgets
;; 
(defconst fvwm-font-lock-keywords-2
  (append fvwm-font-lock-keywords-1
          (list
           '("\\(rgb:..\/..\/..\\)" 1 'fvwm-rgb-value-face)
           '("\\($[-_a-zA-Z0-9]*\\)" 1 'font-lock-variable-name-face)
           (cons fvwmscript-instructions `'font-lock-function-name-face) ;instructions
           (cons fvwmscript-functions `'font-lock-function-name-face) ;functions
           '("\\<\\(Begin\\|Case\\|Do\\|E\\(?:lse\\|nd\\)\\|I\\(?:f\\|nit\\)\\|Main\\|P\\(?:eriodicTasks\\|roperty\\)\\|QuitFunc\\|Set\\|Then\\|Widget\\)\\>" . 'font-lock-keyword-face)
           (cons fvwmscript-properties `'font-lock-keyword-face) ;properties
           (cons fvwmscript-flagsopt `'font-lock-function-name-face) ;flagsOpt
           (cons fvwmscript-keywords `'font-lock-keyword-face) ;keywords
           (cons fvwmscript-widgets `'font-lock-keyword-face))) ;widgets
  "FvwmScript keywords to hilight.")

(defvar fvwm-font-lock-keywords fvwm-font-lock-keywords-2
  "Default highlighting for Fvwm mode.")

(defconst fvwm-font-lock-obsolete
  (append fvwm-font-lock-keywords
          (list
           (cons fvwm-obsolete-functions `'font-lock-warning-face)
           (cons fvwm-obsolete-keywords `'font-lock-warning-face)
           (cons fvwm-obsolete-special `'font-lock-warning-face)))
  "Highlight obsolete keywords on top of the regular keywords
  specified by `fvwm-font-lock-keywords'")
;; -------------------------
;; |       Functions       |
;; -------------------------
(defun fvwm-insert-function (name)
  "Insert a skeleton for an Fvwm Function into the current buffer.
NAME is used as the Function name."
  (interactive "sFunction name? ")
  (skeleton-insert
   '(nil "AddToFunc " name "\n"
     " + " _ )))

(defun fvwm-insert-menu (name)
  "Insert a skeleton for an Fvwm Menu into the current buffer.
NAME is used as the menu name."
  (interactive "sMenu name? ")
  (skeleton-insert
   '(nil "DestroyMenu name\n"
     "AddToMenu name\n"
     " + " _)))

(defun fvwm-insert-buttons (name rows columns geometry)
  "Insert a skeleton for an FvwmButtons and add it to your StartFunction (if possible).
Pressing enter at any prompt skips that option and doesn't
include it in the skeleton. NAME is the FvwmButtons alias name,
ROWS the number or rows, COLUMNS the number of columns and
GEOMETRY sets the FvwmButtons Geometry option."
  (interactive "sFvwmButtons alias? \nsAmount of rows? \nsAmount of columns? \nsGeometry? ")
  (skeleton-insert
   '(nil "DestroyModuleConfig " name ": *\n"
     (when (not (string-equal rows "" ))
         (insert (concat "*" name ": Rows " rows "\n")))
     (when (not (string-equal columns "" ))
         (insert (concat "*" name ": Columns " columns "\n")))
     (when (not (string-equal geometry "" ))
         (insert (concat "*" name ": Geometry " geometry "\n")))
     "\n")))

(defun fvwm-script-insert-skeleton (title width height font)
  "Insert a  skeleton for an FvwmScript into the current buffer.
TITLE sets the scripts title, WIDTH, HEIGHT and FONT set their
respective FvwmScript properties."
  (interactive "sFvwmScript title: \nsWidth (default: empty): \nsHeight (default: empty): \nsFont definition (default: empty): ")
  (goto-char (point-min))
  (skeleton-insert
   '(nil "#-*-fvwm-*-\n"
	 "WindowTitle {" title "}\n"
	 (when (and (not (string-equal width "")) (not (string-equal height "")))
           (insert (concat "WindowSize " width " " height)))
	 (when (not (string-equal font ""))
           (insert (concat "Font " font)))
     "Init\n"
     "Begin\n"
     " " _ "\n"
     "End\n\n"
     "PeriodicTasks\n"
     "Begin\n"
     " \n"
     "End\n")))

(defun fvwm-script-insert-widget (type title number x-pos y-pos width height)
  "Insert a skeleton for a new FvwmScript widget.
The TYPE is the type of widget to insert (see man FvwmButtons for details),
the TITLE is the title for the widget, or nothing if left empty,
the NUMBER is the number the widget will get it defaults to
number one higher than the current highest widget number."
  (interactive "sWidget type (default: ItemDraw): \nsWidget title (default: empty): \nsWidget number (default: next highest number): \nsx-position (default: 0): \nsy-position (default: 0): \nsWidth (default: 100): \nsHeight (default: 50): ")
  (when (string= number "")
      (let ((widget-number "0") temp-widget-number (working-point-position (point))) ; use save-excursion instead of saving the point position
	"Find the highest numbered widget"
	(goto-char (point-max))
	(while (re-search-backward "^Widget \\(.*\\)" nil t)
	  (setq temp-widget-number (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
	  (when (string< widget-number temp-widget-number)
            (setq widget-number temp-widget-number)
            (forward-word 1)))
	(setq number (+ (string-to-number widget-number) 1))
	(goto-char working-point-position)))
  (skeleton-insert
   '(nil "Widget " (number-to-string number) "\n"
	 "Property\n"
	 " Position " x-pos | "0" " " y-pos | "0" "\n"
	 " Size " width | "100" " " height | "50" "\n"
	 " Type " type | "ItemDraw" "\n"
	 " Title {" title "}\n"
	 "Main\n"
	 " Case message of\n"
	 "  SingleClic:\n"
	 "  Begin\n"
	 "   " _ "\n"
	 "  End\n"
	 "End\n")))

;; -------------------------
;; |      Completion       |
;; -------------------------
(if (featurep 'pcomplete)
    (let (fvwm-all-completions)
      (defun pcomplete-fvwm-setup ()
        (when (not fvwm-all-completions)
            (setq fvwm-all-completions (append fvwm-functions fvwm-keywords-1 fvwm-keywords-2)))
        (set (make-local-variable 'pcomplete-parse-arguments-function)
             'pcomplete-parse-fvwm-arguments)
        (set (make-local-variable 'pcomplete-default-completion-function)
             'pcomplete-fvwm-default-completion))

      (defun pcomplete-fvwm-default-completion ()
        (pcomplete-here fvwm-all-completions))

      (defun pcomplete-parse-fvwm-arguments ()
        (save-excursion
          (let* ((thispt (point))
                 (pt (search-backward-regexp "[ \t\n]" nil t))
                 (ptt (if pt (+ pt 1) thispt)))
            (list
             (list "dummy" (buffer-substring-no-properties ptt thispt))
             (point-min) ptt)))))
    

    ;; Still need the following two functions for XEmacs which doesn't
    ;; support pcomplete
    (progn
      (defvar fvwm-keywords-map)

      (defun fvwm-generate-hashmap ()
        "Generate the alist or hash-map needed by fvwm-complete-keyword."
        (let ((fvwm-keywords-all (append fvwm-functions fvwm-keywords-1 fvwm-keywords-2)))
          (message "Generating list of completions...")
          (if (and (not (featurep 'xemacs)) (> emacs-major-version 21))
              (progn
                (setq fvwm-keywords-map (make-hash-table))
                (let ((i 0))
                  (while (< i (length fvwm-keywords-all))
                    (puthash (nth i fvwm-keywords-all) nil fvwm-keywords-map)
                    (incf i))))
              (progn
                (setq fvwm-keywords-map (list))
                (let ((i 0) (cur))
                  (while (< i (length fvwm-keywords-all))
                    (mapc (lambda (e)
                              (add-to-list 'fvwm-keywords-map (cons e nil)))
                            fvwm-keywords-all)
                    (incf i)))))))

      (defun fvwm-complete-keyword ()
        "Complete the Fvwm keywords before point by comparing it
against the known Fvwm keywords."
        ;; This function is largely based on lisp-complete-symbol from GNU Emacs' lisp.el
        (interactive)
        
        (when (and
               (not fvwm-keywords-map)
               (fboundp 'fvwm-generate-hashmap)) ;should always be defined when we get here; silence byte compiler with explicit check
          (fvwm-generate-hashmap))
        
        (let ((window (get-buffer-window "*Completions*")))
          (if (and (eq last-command this-command)
                   window (window-live-p window) (window-buffer window)
                   (buffer-name (window-buffer window)))
              ;; If there's already a completion buffer open, reuse it.
              (with-current-buffer (window-buffer window)
                (if (pos-visible-in-window-p (point-max) window)
                    (set-window-start window (point-min))
                    (save-selected-window
                      (select-window window)
                      (scroll-up))))

              ;; Do completion
              (let* ((end (point))
                     (beg (with-syntax-table (standard-syntax-table)
                            (save-excursion
                              (backward-sexp 1)
                              (while (= (char-syntax (following-char)) ?\')
                                (forward-char 1))
                              (point))))
                     (pattern (buffer-substring-no-properties beg end))
                     (completion (try-completion pattern fvwm-keywords-map)))
                (cond ((eq completion t))
                      ((null completion)
                       (message "Can't find completion for \"%s\"" pattern)
                       (ding))
                      ((not (string= pattern completion))
                       (delete-region beg end)
                       (insert completion))
                      (t
                       (message "Making completion list...")
                       (let ((list (all-completions pattern fvwm-keywords-map)))
                         (setq list (sort list 'string<))
                         (let (new)
                           (while list
                             (setq new (cons (if (fboundp (intern (car list)))
                                                 (list (car list) " <f>")
                                                 (car list))
                                             new))
                             (setq list (cdr list)))
                           (setq list (nreverse new)))
                         (with-output-to-temp-buffer "*Completions*"
                           (display-completion-list list)))
                       (message "Making completion list...%s" "done")))))))))

;; -------------------------
;; |    Timestamp file     |
;; -------------------------
(defun fvwm-timestamp-file ()
  (save-excursion
    (goto-char (point-min))
    (when (and (buffer-modified-p)
               (re-search-forward (concat "^" fvwm-last-updated-prefix ".*")
                                  nil t))
      (replace-match (concat fvwm-last-updated-prefix
                             (format-time-string fvwm-time-format-string)
                             fvwm-last-updated-suffix)))))

;; -------------------------
;; |   Run Fvwm commands   |
;; -------------------------
(defun fvwm-execute-command (command)
  "Execute the specified Fvwm COMMAND using FvwmCommand.
FvwmCommandS needs to be running, see man FvwmCommand for
detailed instructions."
  (interactive "sCommand? ")
  (call-process-shell-command
   (concat fvwm-fvwmcommand-path (shell-quote-argument command)) nil nil nil))

(defun fvwm-execute-region (&optional beg end partial-exp)
  "Execute the Fvwm commands in the selected region using FvwmCommand.
FvwmCommandS needs to be running, see man FvwmCommand for
detailed instructions."
  (interactive "r")  
  (save-excursion
    (let ((beg-orig (region-beginning))
          (end-orig (region-end)))
      (let ((beg (progn (goto-char beg-orig)
                        (back-to-indentation)
                        (point)))
            (end (progn (goto-char end-orig)
                        (end-of-line)
                        (point))))
        (call-process-region beg end fvwm-fvwmcommand-path nil nil nil "-c")))))

(defun fvwm-execute-buffer ()
  "Execute the current buffer using FvwmCommand.
FvwmCommand needs to be running, see 'man FvwmCommand' for
detailed instructions."
  (interactive)
  (save-excursion
    (call-process-region (buffer-end -1)
                         (buffer-end 1)
                         fvwm-fvwmcommand-path nil nil nil "-c")))

(defun fvwm-execute-file ()
  "Execute the file containing Fvwm commands as the 'Read' Fvwm
statement would do, you need to have FvwmCommand working for this
to actually work, see man FvwmCommand for details on that."
  (interactive)
  (fvwm-execute-command (concat "Read " (expand-file-name (read-file-name "Path to file: " "~/.fvwm")))))

;; -------------------------
;; |    Entry function     |
;; -------------------------
;;;###autoload
(define-derived-mode fvwm-mode prog-mode "Fvwm"
  "Major mode for editing Fvwm configuration files.

Commands:
\\{fvwm-mode-map}
Entry to this mode calls the value of `fvwm-mode-hook'"
  (set (make-local-variable 'comment-start) "#")

  (set (make-local-variable 'font-lock-defaults)
       '(fvwm-font-lock-keywords nil fvwm-keywords-force-case))

  (when fvwm-enable-last-updated-timestamp
    (add-hook 'before-save-hook 'fvwm-timestamp-file))
  
  ;; XEmacs needs this, otherwise the menu isn't displayed.
  (when (featurep 'xemacs)
    (easy-menu-add fvwm-menu fvwm-mode-map))

  ;; Create the completions database when the mode is first loaded on XEmacs
  ;; (or any other Emacs not providing pcomplete)
  (when (and
         (not (featurep 'pcomplete))
         (fboundp 'fvwm-generate-hashmap)
         fvwm-preload-completions)
    (fvwm-generate-hashmap)))

;;;###autoload
(dolist (pattern '("/home/[^/]*/\\.fvwm/config\\'"
                   "/home/[^/]*\\(/\\|\\/.fvwm/\\).fvwm2rc\\'" "\\.fvwm\\'"
                   "/ConfigFvwm" "/FvwmScript-" "/FvwmForm-" "/FvwmTabs-"))
  (add-to-list 'auto-mode-alist (cons pattern 'fvwm-mode)))

(provide 'fvwm-mode)

;;; fvwm-mode.el ends here
