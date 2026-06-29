


1 _Brief_
═════════

  The Brief editor v3.1 was once very popular among programmers in the
  MS-DOS days.  It is famous for its easy-to-learn.  Most of the command
  'K'eys are associated with meaningful 'K'eywords.  Usually, it can be
  mastered within an hour and difficult to forget.

  For example, the first `<home>' key bring the cursor to home
  (beginning) of current line, a consecutive second `<home>' key to the
  home (beginning) of the window and a third `<home>' to the home
  (beginning) of the file.  Similarly for the `<end>' key.  To
  paste/insert clipboard contents into current file just press
  `<insert>',… and so on.

  Personally, I've been using this key combination for over 32+ years
  (by the time Y2023 this guide was updated) and have never changed,
  since the beginning of the MS-DOS Brief Editor days; the later 22+
  years of the 32 are using Emacs with this Brief Mode.

  [Actually, after 22+ years of Emacs I still can't (or simply, don't
   need to) memorize the default Emacs keys, except for `<Ctrl>-g'
   (cancel half-entered commands) and `<Ctrl>-x <Ctrl>-c' (quit Emacs,
   in case I don't have my Brief mode at hand, yet).]


2 _Installation_
════════════════

2.1 Quick steps for non-Emacs users:
────────────────────────────────────

  1. Install Emacs, better be Emacs version 24 above (Emacs26+
     recommended).  For Debian/Ubuntu users:

     `$ sudo apt install emacs -y'

  2. Download Brief package using emacs command line:

     `$ emacs --batch --eval "(progn (package-initialize)
     (package-refresh-contents) (package-install 'brief))"'

  3. Now the Brief package should be installed in
     "~/.emacs.d/elpa/brief-#.##" (where #.## is the version number, by
     the time this document is written it's 5.87).  You can either add
     this into PATH, or copy (link) the launcher bash script
     "~/.emacs.d/elpa/brief-#.##/b" to anywhere within your PATH (notice
     this launcher exists only after v5.87).

     Now you can start Emacs brief emulator, just run the launcher:

     `$ b'

     That's it!  (If 'b' fail to launch, the package might not be
     properly installed, try step 2 and 3 again, or do it like Emacs
     users below.)


2.2 For Emacs users, just install the ELPA brief package with menu -> "Options"
───────────────────────────────────────────────────────────────────────────────

  -> "Manage Emacs Packages", then add

  ┌────
  │ (require 'brief)
  │ (brief-easy-start) ;; will do (brief-mode 1)
  └────

  into ~/.emacs to enable it. (For what `brief-easy-start' does please
  search "brief-easy-start" following.)


3 _Key Commands:_
═════════════════

3.1 Basic editing commands are just like any other editor, cursor movement
──────────────────────────────────────────────────────────────────────────

  using `arrow up/down/left/right'; `page up/down'; line `home/end';
  with `<shift>' key pressed cursor movement keys mark text selection.
  `<Enter>', `<Backspace>', and `<Delete>' also behaves the same as
  other editors; when text region is selected, `<Backspace>' and
  `<Delete>' deletes the whole selection.


3.2 The first thing need to memorize about Emacs is that the cancellation
─────────────────────────────────────────────────────────────────────────

  is usually *not* done by the `<Esc>' key but mostly by `<Ctrl>-g' key.


3.3 All of the `<Alt>' command keys are easy to memorize by the meaningful
──────────────────────────────────────────────────────────────────────────

  'K'eyword associated 'K'ey: (for Mac systems the `<Alt>' key is
  usually the `<option>' key or the `<command>' key)

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `==========================================='  `===================' 
   *Command & 'K'eyword*                          *'K'ey*               
   `==========================================='  `===================' 
   e'X'it Emacs Brief Mode/Emulator:              `<Alt>-X'             
  ──────────────────────────────────────────────────────────────────────
   'E'dit a file:                                 `<Alt>-E'             
  ──────────────────────────────────────────────────────────────────────
   'B'uffer list:                                 `<Alt>-B'             
   press `<q>' to quit buffer list                                      
  ──────────────────────────────────────────────────────────────────────
   Go to 'home' (beginning) of line:              `<Home>'              
   Go to 'home' (beginning) of window:            `<Home> (2nd <Home>)' 
   Go to 'home' (beginning) of file:              `<Home> (3rd <Home>)' 
  ──────────────────────────────────────────────────────────────────────
   Go to 'end' of line:                           `<End>'               
   Go to 'end' of window:                         `<End> (2nd <End>)'   
   Go to 'end' of file:                           `<End> (3rd <End>)'   
  ──────────────────────────────────────────────────────────────────────
   'H'elp:                                        `<Alt>-H'             
   press `<q>' or `<Esc>' to quit help system                           
   (For key-specific help, press `<Alt>-h k',                           
   then followed by the key command sequence.                           
   For example: `<Alt>-h k <Home>')                                     
  ──────────────────────────────────────────────────────────────────────
   'G'oto line:                                   `<Alt>-G'             
  ──────────────────────────────────────────────────────────────────────
   'L'ine oriented text selection:                `<Alt>-L'             
   followed by cursor movements                                         
  ──────────────────────────────────────────────────────────────────────
   'C'olumn oriented text selection:              `<Alt>-C'             
   followed by cursor movements                                         
  ──────────────────────────────────────────────────────────────────────
   Start line 'M'arking:                          `<Alt>-M'             
  ──────────────────────────────────────────────────────────────────────
   Copy ('+') text selection into clipboard:      `<Keypad +>'          
   if no text selected, copy current line         `<Ctrl>-<Insert>'     
  ──────────────────────────────────────────────────────────────────────
   Cut ('-') text selection into clipboard:       `<Keypad ->'          
   if no text selected, cut current line          `<Shift>-<Delete>'    
  ──────────────────────────────────────────────────────────────────────
   Paste/insert clipboard texts into current      `<Insert>'            
   line, if text selected, replace selected:                            
  ──────────────────────────────────────────────────────────────────────
   'D'elete a line(s):                            `<Alt>-D'             
   if text selected, delete selected                                    
  ──────────────────────────────────────────────────────────────────────
   'K'ill texts till end of line:                 `<Alt>-K'             
  ──────────────────────────────────────────────────────────────────────
   'R'ead a file and insert into current line:    `<Alt>-R'             
  ──────────────────────────────────────────────────────────────────────
   'W'rite (save) editing file:                   `<Alt>-W'             
   if text selected, save selected region to                            
   a file (will prompt for a file name)                                 
  ──────────────────────────────────────────────────────────────────────
   'O'utput as another file name:                 `<Alt>-O'             
   (save as, will prompt for a file name)                               
  ──────────────────────────────────────────────────────────────────────
   'P'rint buffer/selected region:                `<Alt>-P'             
  ──────────────────────────────────────────────────────────────────────
   Toggle 'I'nserting/overwriting mode:           `<Alt>-I'             
  ──────────────────────────────────────────────────────────────────────
   'U'ndo:                                        `<Alt>-U'             
                                                  `<Keypad *>'          
  ──────────────────────────────────────────────────────────────────────
   Buffer 'F'ilename:                             `<Alt>-F'             
  ──────────────────────────────────────────────────────────────────────
   Jump to bookmark '0' … '9':                    `<Alt>-0 .. <Alt>-9'  
  ──────────────────────────────────────────────────────────────────────
   Set a bookmark 'J'ump:                         `<Alt>-J'             
  ──────────────────────────────────────────────────────────────────────
   Switch to previous ('-') buffer:               `<Alt>-<->'           
                                                  `<Alt>-<_>'           
  ──────────────────────────────────────────────────────────────────────
   Switch to next ('+') buffer:                   `<Alt>-<+>'           
                                                  `<Alt>-<=>'           
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.4 Frequently used commands adjusted for Emacs:
────────────────────────────────────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Cancel a command                              `<Ctrl>-G'          
                                                 `<Esc> <Esc> <Esc>' 
  ───────────────────────────────────────────────────────────────────
   Execute Emacs extended command (the original  `<F10>'             
   Emacs `M-x')                                                      
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.5 Search (`<F5>') and Replace (`<F6>') commands:
──────────────────────────────────────────────────

  By default the un-prefixed commands search/replace forwards. Prefixed
  key change their meaning: `<alt>' (ALTer direction) means "backward",
  `<shift>' means "repeat" and `<'C'ontrol>' means "'C'urrent" or
  sometimes "forwards".

  If text selected, the search/replace command will be restricted within
  the region.


3.5.1 Search:
╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Search regular expression/string forwards          `<F5>'                   
   Search regular expression/string backwards         `<Alt>-<F5>'             
  ─────────────────────────────────────────────────────────────────────────────
   Repeat previous search in the last direction       `<Shift>-<F5>'           
   Repeat previous search forwards                    `<Shift>-<Control>-<F5>' 
   Repeat previous search backwards                   `<Shift>-<Alt>-<F5>'     
  ─────────────────────────────────────────────────────────────────────────────
   Search current word (at cursor) forwards           `<Control>-<F5>'         
   Search current word (at cursor) backwards          `<Control>-<Alt>-<F5>'   
   If selected text region is small (within one line                           
   and less than 80 characters) then it's selected                             
   as current word                                                             
  ─────────────────────────────────────────────────────────────────────────────
   Interactive search forwards                        `<Control>-S'            
   Interactive search backwards                       `<Alt>-S'                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.5.2 Replace:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Replace regular expression/string forwards         `<F6>'                   
   Replace regular expression/string backwards        `<Alt>-<F6>'             
  ─────────────────────────────────────────────────────────────────────────────
   Repeat previous replacement in the last direction  `<Shift>-<F6>'           
   Repeat previous replacement forwards               `<Shift>-<Control>-<F6>' 
   Repeat previous replacement backwards              `<Shift>-<Alt>-<F6>'     
  ─────────────────────────────────────────────────────────────────────────────
   Replace current word (at cursor) forwards          `<Control>-<F6>'         
   Replace current word (at cursor) backwards         `<Control>-<Alt>-<F6>'   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.5.3 Toggle search & replace behavior (for current buffer):
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Toggle case sensitivity (default case sensitive)      `<Control>-<X> <F5>' 
  ────────────────────────────────────────────────────────────────────────────
   Toggle regular expression (default) or simple string  `<Control>-<X> <F6>' 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.6 Window control commands:
────────────────────────────

  All commands are relative to the current cursor location; issue a
  window command <F1>…<F4> from the cursor, to the direction the
  followed <arrow> key points to:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Switch to the window the arrow points to            `<F1> <arrow>' 
  ────────────────────────────────────────────────────────────────────
   Adjust current window edge on the side the arrow    `<F2> <arrow>' 
   points to                                                          
  ────────────────────────────────────────────────────────────────────
   Split a new window in the direction that the arrow  `<F3> <arrow>' 
   points to                                                          
  ────────────────────────────────────────────────────────────────────
   Merge and delete the window the arrow points to     `<F4> <arrow>' 
  ────────────────────────────────────────────────────────────────────
   Delete current window                               `<Ctrl>-<F4>'  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.7 Window frame commands:
──────────────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Create a new window frame, when prefixed with `C-u'     `<Alt>-<F3>' 
   it tries to restore the frame just closed (this help                 
   user restores an accidentally closed frame)                          
  ──────────────────────────────────────────────────────────────────────
   Close current window frame. This is usually controlled  `<Alt>-<F4>' 
   by system window manager; if user accidentally closed                
   a frame use `<C-u> <Alt>-<F3>' to restore it)                        
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.8 Keystroke macro commands:
─────────────────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Start/End remembering keystroke commands into a macro   `<F7>'         
  ────────────────────────────────────────────────────────────────────────
   Pause recording keystroke macro                         `<Shift>-<F7>' 
  ────────────────────────────────────────────────────────────────────────
   Playback the just recorded macro                        `<F8>'         
  ────────────────────────────────────────────────────────────────────────
   Load keystroke macro from a file, will prompt for a     `<Alt>-<F7>'   
   file name                                                              
  ────────────────────────────────────────────────────────────────────────
   Save keystroke macro to a file, will prompt for a file  `<Alt>-<F8>'   
   name                                                                   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.9 Compilation commands:
─────────────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Compile buffer, will prompt for a compilation command     `<Alt>-<F10>' 
  ─────────────────────────────────────────────────────────────────────────
   From current buffer, jump to the first compilation error  `<Ctrl>-P'    
   message in the compilation buffer; when in the                          
   compilation buffer, it jumps to previous error message                  
  ─────────────────────────────────────────────────────────────────────────
   Jump to the next compilation error message when in the    `<Ctrl>-N'    
   compilation buffer                                                      
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


4 _Emacs specific and miscellaneous extended commands:_
═══════════════════════════════════════════════════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Move backwards an expression, or matching           `<Alt>-<Left>'           
   parenthesis backwards                                                        
   Move forwards an expression, or matching            `<Alt>-<Right>'          
   parenthesis forwards                                                         
  ──────────────────────────────────────────────────────────────────────────────
   Move backwards a word                               `<Ctrl>-<Left>'          
   Move forwards a word                                `<Ctrl>-<Right>'         
  ──────────────────────────────────────────────────────────────────────────────
   Go back to previous TAB stop place, according to    `<Shift>-<Tab>'          
   the current `tab-width' setting                                              
  ──────────────────────────────────────────────────────────────────────────────
   Indent current line, or region if text selected.    `<Tab>'                  
   If previous command is `<shift>-<tab>' then it go                            
   forwards to the next TAB stop place.                                         
   When prefixed with `C-u' insert a raw TAB char.                              
  ──────────────────────────────────────────────────────────────────────────────
   Indent whole buffer or selected region              `<Ctrl>-<Alt>-<Tab>'     
  ──────────────────────────────────────────────────────────────────────────────
   Untabify selected region                            `<Ctrl>-C <Tab>'         
  ──────────────────────────────────────────────────────────────────────────────
   Emacs `C-x' prefix                                  `<Ctrl>-X'               
  ──────────────────────────────────────────────────────────────────────────────
   Emacs `C-u' universal prefix argument               `<Ctrl>-U'               
  ──────────────────────────────────────────────────────────────────────────────
   Open menu bar                                       `<Shift>-<F10>'          
  ──────────────────────────────────────────────────────────────────────────────
   Open shell                                          `<Alt>-Z'                
  ──────────────────────────────────────────────────────────────────────────────
   Find a file                                         `<F9>'                   
  ──────────────────────────────────────────────────────────────────────────────
   Toggle current buffer read only                     `<Alt>-<F11>'            
  ──────────────────────────────────────────────────────────────────────────────
   Toggle Emacs auto-backup ON/OFF                     `<Ctrl>-W'               
  ──────────────────────────────────────────────────────────────────────────────
   Delete following word                               `<Alt>-<Backspace>'      
  ──────────────────────────────────────────────────────────────────────────────
   Delete previous word                                `<Ctrl>-<Backspace>'     
                                                       `<Shift>-<Backspace>'    
  ──────────────────────────────────────────────────────────────────────────────
   Redo during undo: one arrow key, then do undos      `<arrow> <Alt>-Us'       
  ──────────────────────────────────────────────────────────────────────────────
   Show Brief mode 'V'ersion                           `<Alt>-V'                
  ──────────────────────────────────────────────────────────────────────────────
   Scroll up one line                                  `<Ctrl>-E'               
   Scroll down one line                                `<Ctrl>-D'               
  ──────────────────────────────────────────────────────────────────────────────
   Go to beginning of file                             `<Ctrl>-<PageUp>'        
   Go to end of file                                   `<Ctrl>-<PageDown>'      
  ──────────────────────────────────────────────────────────────────────────────
   Go to beginning of window                           `<Alt>-<Home>'           
   Go to end of window                                 `<Alt>-<End>'            
  ──────────────────────────────────────────────────────────────────────────────
   Go to first line of window                          `<Ctrl>-<Home>'          
   Go to last line of window                           `<Ctrl>-<End>'           
  ──────────────────────────────────────────────────────────────────────────────
   Open a new next line and goto it, but does not      `<Ctrl>-<Enter>'         
   split current line                                                           
  ──────────────────────────────────────────────────────────────────────────────
   Recenter horizontally, this is usually used for a   `<Ctrl>-<Shift>-L'       
   long line in truncation mode to scroll texts                                 
   leftwards or rightwards to left/middle/right of                              
   current window.  It's an implementation against                              
   Emacs default `<Ctrl>-L' which recenter vertically                           
   to top/middle/bottom of current window                                       
  ──────────────────────────────────────────────────────────────────────────────
   Save buffer and exit Emacs immediately              `<Ctrl>-<Alt>-<Shift>-X' 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


5 Less favored default Emacs settings:
══════════════════════════════════════

  There are some less favored default Emacs settings which makes the
  editing experience in Emacs quite unlike others, especially for
  programmers. For example, text wrapping is by default enabled so a
  program line could easily wrapped to next line if window size changed;
  text scrolling is jumppy in both horizontal and vertical directions
  and on `<page up>' / `<page down>' the cursor does not stay at the
  same position.  Some of these behaviors can be easily adjusted by
  changing default settings.

  With the quick launcher 'b' all these are fixed.  The `<page up>' /
  `<page down>' are rewritten in Brief while function `brief-easy-start'
  changed other settings then do `(brief-mode 1)' to enable Brief mode.

  If you launch Emacs without using quick launcher 'b' or
  `brief-easy-start' function, you may want to include those changes
  into your ~/.emacs init script:

  ┌────
  │ ;;--------------------------------------------------------------------------;
  │ (setq-default truncate-lines t)  ;; disable line wrapping                   ;
  │ ;;(setq-default global-visual-line-mode t)                                  ;
  │ (setq scroll-step 1              ;; set vertical scroll not jumppy          ;
  │       scroll-conservatively 101)                                            ;
  │ (setq hscroll-margin 1           ;; set horizontal scroll not jumppy        ;
  │       hscroll-step 1)                                                       ;
  │ (scroll-bar-mode -1)             ;; small border without scroll bar         ;
  │ ;;--------------------------------------------------------------------------;
  └────

  Or you can refer to the source code "brief.el" for function
  `brief-easy-start'.


6 Cygwin:
═════════

  For more details like Cygwin 2.x users note, please check the comments
  in the source code "brief.el".

  Luke Lee
