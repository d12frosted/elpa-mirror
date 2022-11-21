;;; conkeror-minor-mode.el --- Mode for editing conkeror javascript files.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>>
;; URL: http://github.com/Bruce-Connor/conkeror-minor-mode
;; Package-Version: 20150114.1604
;; Package-Commit: 476e81c27b056e21c192391fe674a2bf875466b0
;; Version: 1.6.2
;; Keywords: programming tools
;; Prefix: conkeror
;; Separator: -

;;; Commentary:
;;
;; **Mode for editing conkeror javascript files.**
;; -----------------------------------------------
;; 
;; Currently, this minor-mode defines:
;; 
;; 1. A function for sending current javascript statement to be
;; evaluated by conkeror. This function is
;; `eval-in-conkeror' bound to **C-c C-c**.
;; 2. Syntax coloring.
;; 3. Indentation according to
;; [Conkeror Guidelines](http://conkeror.org/DevelopmentGuidelines).
;; 4. Warning colors when anything in your code is not compliant with
;; [Conkeror Guidelines](http://conkeror.org/DevelopmentGuidelines). If
;; you find this one excessive, you can set
;; `conkeror-warn-about-guidelines' to `nil'.
;; 
;; Installation:
;; =============
;; 
;; If you install from Melpa just skip to the activation instructions below.
;; 
;; If you install manually, make sure it's loaded
;; 
;;     (add-to-list 'load-path "/PATH/TO/CONKEROR-MINOR-MODE.EL/")
;;     (autoload 'conkeror-minor-mode "conkeror-minor-mode")
;;     
;; then follow activation instructions below.
;; 
;; Activation
;; ==========
;; 
;; It is up to you to define when `conkeror-minor-mode' should be
;; activated. If you want it on every javascript file, just do
;; 
;;     (add-hook 'js-mode-hook 'conkeror-minor-mode)
;; 
;; If you want it only on some files, you can have it activate only on
;; your `.conkerorrc' file:
;; 
;;     (add-hook 'js-mode-hook (lambda ()
;;                               (when (string= ".conkerorrc" (buffer-name))
;;                                 (conkeror-minor-mode 1))))
;; 
;; or, alternatively, only on files with "conkeror" somewhere in the path:
;; 
;;     (add-hook 'js-mode-hook (lambda ()
;;                               (when (string-match "conkeror" (buffer-file-name))
;;                                 (conkeror-minor-mode 1))))

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 1.6.1 - 2014/07/05 - Include require_match in font-locking.
;; 1.6   - 2013/12/18 - eval-in-conkeror better windows support.
;; 1.5.5 - 2013/12/14 - False with conkeror--font-lock-warnings on ternary operator.
;; 1.5.4 - 2013/11/29 - Fix issue #2.
;; 1.5.3 - 2013/11/04 - Use built-in show-trailing-whitespace
;; 1.5.2 - 2013/10/31 - Closing } on column 0 counts as a statement ending.
;; 1.5.1 - 2013/10/31 - A few more warnings
;; 1.5   - 2013/10/31 - next-to-full compliance with Whitespace & Style Guidelines
;; 1.4.1 - 2013/10/30 - Fix bug-report
;; 1.4.1 - 2013/10/30 - Shell-quote-argument
;; 1.4   - 2013/10/29 - Indentation according to http://conkeror.org/DevelopmentGuidelines
;; 1.3.1 - 2013/10/26 - Add provide as a keyword
;; 1.3   - 2013/10/25 - Font-locking
;; 1.0   - 2013/10/25 - Created File.
;;; Code:

(defconst conkeror-minor-mode-version "1.6.2" "Version of the conkeror-minor-mode.el package.")
(defconst conkeror-minor-mode-version-int 14 "Version of the conkeror-minor-mode.el package, as an integer.")
(defun conkeror-bug-report ()
  "Opens github issues page in a web browser. Please send me any bugs you find, and please inclue your emacs and conkeror versions."
  (interactive)
  (message "Your conkeror-version is: %s, and your emacs version is: %s.
Please include this in your report!"
           conkeror-minor-mode-version emacs-version)
  (browse-url "https://github.com/Bruce-Connor/conkeror-minor-mode/issues/new"))
(defun conkeror-customize ()
  "Open the customization menu in the `conkeror-minor-mode' group."
  (interactive)
  (customize-group 'conkeror-minor-mode t))

(defface conkeror-warning-whitespace
  '((t
     :background "Red"
     :inherit default
     ))
  "Face to warn the user he's using a tab (which is a no-no) or other inappropriate whitespace."
  :group 'conkeror-minor-mode-faces)

(defcustom conkeror-file-path nil
  "The path to a script that runs conkeror, or to the \"application.ini\" file.

If this is nil we'll try to find an executable called
\"conkeror\" or \"conkeror.sh\" in your path."
  :type 'string
  :group 'conkeror-minor-mode)

(defun eval-in-conkeror ()
  "Send current javacript statement to conqueror.

This command determines the current javascript statement under
point and evaluates it in conkeror. The point of this is NOT to
gather the result (there is no return value), but to customize
conkeror directly from emacs by setting variables, defining
functions, etc.

If mark is active, send the current region instead of current
statement."
  (interactive)
  (message "Result was:\n%s"
           (let ((comm 
                  (concat
                   (shell-quote-argument (conkeror--command))
                   " -q -batch -e "
                   (shell-quote-argument (js--current-statement)))))
             (message "Running:\n%s" comm)
             (shell-command-to-string comm))))

(defun conkeror--command ()
  "Generate the string for the conkeror command."
  (if (stringp conkeror-file-path)
      (if (file-name-absolute-p conkeror-file-path)      
          (if (string-match "\.ini\\'" conkeror-file-path)
              (concat (executable-find "xulrunner")
                      " " (expand-file-name conkeror-file-path))
            (expand-file-name conkeror-file-path))
        (error "%S must be absolute." 'conkeror-file-path))
    (or
     (executable-find "conkeror")
     (executable-find "conkeror.sh")
     (executable-find "conkeror.exe")
     (error "Couldn't find a conkeror executable! Please set %S." 'conkeror-file-path))))

(defun js--current-statement ()
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (let ((l (point-min))
          initial-point r)
      (save-excursion
        (skip-chars-backward "[:blank:]\n")
        (setq initial-point (point))
        (goto-char (point-min))
        (forward-sexp 1) ;(Skip over comments and whitespace)
        (forward-sexp -1)
        (while (null (or r (eobp)))
          (when (or (looking-back "^}\\s-*")
                    (and (skip-chars-forward "[:blank:]\n")
                         (looking-at ";")))
            (when (looking-at ";") (forward-char 1))
            (if (>= (point) initial-point)
                (setq r (point))
              (forward-sexp 1) ;(Skip over comments and whitespace)
              (forward-sexp -1)
              (setq l (point))))
          (forward-sexp 1)))
      (buffer-substring-no-properties l r))))

(defcustom conkeror-warn-about-guidelines t
  "If non-nil, apply a warning face on any code that doesn't follow the guidelines.

Indentation will always follow the guidelines. This variable only
customizes the behavior of font-locking (since it can be slightly
annoyin at times).

Guidelines can be found at http://conkeror.org/DevelopmentGuidelines ."
  :type 'boolean
  :group 'conkeror-minor-mode
  :package-version '(conkeror-minor-mode . "1.5"))

(defconst conkeror--font-lock-warnings
  '(;; Warnings
    ;; tabs
    ("[\t]+" 0 'conkeror-warning-whitespace t)
    ;; space at end of line is now handled by show-trailing-whitespace
    ;; ("[^\n ]\\(\\s-+\\)$" 1 'conkeror-warning-whitespace t)
    ;; more than one space between function name and parenthesis
    ("\\_<function\\(?:\\s-+[[:alnum:]_]+\\|\\)\\(?:\\(?1:\\s-\\s-+\\)(\\|.*)\\(?1:\\s-\\s-+\\){\\s-*$\\)"
     1 'conkeror-warning-whitespace t)
    ;; More than one space between "function" and function name (or parentheses)
    ("\\_<function\\(?1:\\s-\\s-+\\)[[:alnum:]_(]+"
     1 'conkeror-warning-whitespace t)
    ;; no space between function name and parentheses
    ("\\_<function\\(?:\\s-+[[:alnum:]_]+\\|\\)\\(?1:(\\)"
     1 font-lock-warning-face t)
    ("\\_<function\\_>.*\\(?1:){\\)\\s-*$"
     1 font-lock-warning-face t)
    ;; typeOf with parenthesis
    ("\\_<\\(?:typeof\\s-*\\(?1:(\\)\\)\\_>"
     1 font-lock-warning-face t)
    ;; no space between for/if/while and parentheses
    ("\\_<\\(?:fo\\(?1:r(\\)\\|i\\(?1:f(\\)\\|whil\\(?1:e(\\)\\)"
     1 font-lock-warning-face t)
    ;; more than one space between for/if/while and parentheses
    ("\\_<\\(?:for\\|if\\|while\\)\\(?1:\\s-\\s-+\\)("
     1 'conkeror-warning-whitespace t)
    ("\\_<\\(?:for\\|if\\|while\\)\\s-*(.*)\\(?1:\\s-\\s-+\\){"
     1 'conkeror-warning-whitespace t)
    ;; ;; Assignment inside if/while without double parentheses 
    ;; Had to remove this because it gives false positives when the assignment is preceded by a && or ||.
    ;; ("\\_<\\(if\\|while\\)\\_>\\s-*\\(?1:(\\)\\(?:[^()][^)]*[^)=><!]\\(?3:=\\)[^)=]\\|[^()]\\(?3:=\\)[^)=]\\)[^)]*\\(?2:)\\)"
    ;;  (1 font-lock-warning-face t) (2 font-lock-warning-face t) (3 'conkeror-warning-whitespace t))
    ;; ;; space between key and colon
    ;; Had to remove this because it gives false positives against the ternary operator.
    ;; ("^[^\\?]*[^ ]\\(?1:\\s-+\\):" 1 'conkeror-warning-whitespace t)
    )
  "Font-locks for warning the user of bad formatting.")

(defconst conkeror--font-lock-keywords
  '(;; keywords
    ("\\_<\\(\\$\\(?:a\\(?:ction\\|l\\(?:ign\\|low_www\\|ternative\\)\\|nonymous\\|rgument\\|uto\\(?:_complete\\(?:_\\(?:delay\\|initial\\)\\)?\\)?\\)\\|b\\(?:inding\\(?:_list\\|s\\)?\\|rowser_object\\|uffers?\\)\\|c\\(?:harset\\|lass\\|o\\(?:m\\(?:mand\\(?:_list\\)?\\|plet\\(?:er\\|ions\\)\\)\\|nstructor\\)\\|rop\\|wd\\)\\|d\\(?:e\\(?:fault\\(?:_completion\\)?\\|scription\\)\\|isplay_name\\|o\\(?:c\\|mains?\\)\\)\\|f\\(?:allthrough\\|ds\\|lex\\)\\|get_\\(?:description\\|string\\)\\|h\\(?:e\\(?:aders\\|lp\\)\\|i\\(?:nt\\(?:_xpath_expression\\)?\\|story\\)\\)\\|in\\(?:dex_file\\|fo\\|itial_value\\)\\|key\\(?:_sequence\\|map\\)\\|load\\|m\\(?:od\\(?:ality\\|e\\)\\|ultiple\\)\\|name\\(?:space\\)?\\|o\\(?:bject\\|p\\(?:ener\\|ml_file\\|tions\\)\\|ther_bindings\\|verride_mime_type\\)\\|p\\(?:a\\(?:rent\\|ssword\\|th\\)\\|erms\\|osition\\|r\\(?:e\\(?:fix\\|pare_download\\)\\|ompt\\)\\)\\|re\\(?:gexps\\|peat\\|quire_match\\)\\|s\\(?:elect\\|hell_command\\(?:_cwd\\)?\\)\\|t\\(?:e\\(?:mp_file\\|st\\)\\|lds\\)\\|u\\(?:rl\\(?:\\(?:_prefixe\\)?s\\)\\|se\\(?:_\\(?:bookmarks\\|cache\\|history\\|webjumps\\)\\|r\\)\\)\\|va\\(?:lidator\\|riable\\)\\|wrap_column\\)\\)\\_>"
     1 font-lock-constant-face)
    ;; "Macros" (and a couple big functions)
    ("\\_<\\(define_\\(?:browser_object_class\\|key\\(?:map\\(?:s_page_mode\\)?\\)?\\|webjump\\)\\|\\(?:interactiv\\|provid\\|requir\\)e\\)\\_>"
     1 font-lock-keyword-face)
    ;; common functions
    ("\\(a\\(?:dd_hook\\|lternates\\)\\|build_url_regexp\\|call_on_focused_field\\|exec\\|focus_next\\|mod\\(?:e_line_\\(?:adder\\|mode\\)\\|ify_region\\)\\|p\\(?:age_mode_activate\\|op\\|ush\\)\\|re\\(?:ad_from_clipboard\\|gister_user_stylesheet\\|move_hook\\)\\|s\\(?:e\\(?:ssion_pref\\|t_protocol_handler\\)\\|witch_to_buffer\\)\\|test\\)\\s-*("
     1 font-lock-function-name-face)
    ;; keymaps
    ("\\_<\\(\\(?:c\\(?:aret\\|ontent_buffer_\\(?:anchor\\|button\\|checkbox\\|embed\\|form\\|normal\\|richedit\\|select\\|text\\(?:area\\)?\\)\\)\\|d\\(?:efault_\\(?:base\\|global\\|help\\)\\|ownload_buffer\\|uckduckgo\\(?:_\\(?:anchor\\|select\\)\\)?\\)\\|f\\(?:acebook\\|eedly\\|ormfill\\)\\|g\\(?:ithub\\|lobal_overlay\\|ma\\(?:il\\|ne\\)\\|oogle_\\(?:calendar\\|gqueues\\|maps\\|reader\\|search_results\\|voice\\)\\|rooveshark\\)\\|h\\(?:elp_buffer\\|int\\(?:_quote_next\\)?\\)\\|isearch\\|key_binding_reader\\|list_by\\|minibuffer\\(?:_\\(?:base\\|message\\|space_completion\\)\\)?\\|new\\(?:sblur\\)?\\|over\\(?:lay\\|ride\\)\\|quote\\(?:_next\\)?\\|re\\(?:ad_buffer\\|ddit\\)\\|s\\(?:equence_\\(?:abort\\|help\\)\\|ingle_character_options_minibuffer\\|pecial_buffer\\|tackexchange\\)\\|t\\(?:arget\\|ext\\|witter\\)\\|universal_argument\\|wikipedia\\|youtube_player\\)_keymap\\)\\_>"
     1 font-lock-variable-name-face)
    ;; mods
    ("\\_<\\(\\(?:d\\(?:ailymotion\\|uckduckgo\\)\\|f\\(?:acebook\\|eedly\\)\\|g\\(?:ithub\\|ma\\(?:il\\|ne\\)\\|oogle_\\(?:calendar\\|gqueues\\|images\\|maps\\|reader\\|search_results\\|v\\(?:ideo\\|oice\\)\\)\\|rooveshark\\)\\|key_kill\\|newsblur\\|reddit\\|s\\(?:mbc\\|tackexchange\\)\\|twitter\\|wikipedia\\|xkcd\\|youtube\\(?:_player\\)?\\)_mode\\)\\_>"
     1 font-lock-variable-name-face)
    ;; user variables
    ("\\_<\\(a\\(?:ctive_\\(?:\\(?:img_\\)?hint_background_color\\)\\|llow_browser_window_close\\|uto_mode_list\\)\\|b\\(?:lock_content_focus_change_duration\\|rowser_\\(?:automatic_form_focus_window_duration\\|default_open_target\\|form_field_xpath_expression\\|relationship_patterns\\)\\|ury_buffer_position\\)\\|c\\(?:an_kill_last_buffer\\|l\\(?:icks_in_new_buffer_\\(?:button\\|target\\)\\|ock_time_format\\)\\|ontent_handlers\\|wd\\)\\|d\\(?:aemon_quit_exits\\|e\\(?:fault_minibuffer_auto_complete_delay\\|lete_temporary_files_for_command\\)\\|ownload_\\(?:buffer_\\(?:automatic_open_target\\|min_update_interval\\)\\|temporary_file_open_buffer_delay\\)\\)\\|e\\(?:dit\\(?:_field_in_external_editor_extension\\|or_shell_command\\)\\|xternal_\\(?:\\(?:content_handler\\|editor_extension_override\\)s\\)\\|ye_guide_\\(?:context_size\\|highlight_new\\|interval\\)\\)\\|f\\(?:avicon_image_max_size\\|orced_charset_list\\)\\|generate_filename_safely_fn\\|h\\(?:int\\(?:_\\(?:background_color\\|digits\\)\\|s_a\\(?:\\(?:mbiguous_a\\)?uto_exit_delay\\)\\)\\|omepage\\)\\|i\\(?:mg_hint_background_color\\|ndex_\\(?:webjumps_directory\\|xpath_webjump_tidy_command\\)\\|search_keep_selection\\)\\|k\\(?:ey\\(?:_bindings_ignore_capslock\\|board_key_sequence_help_timeout\\)\\|ill_whole_line\\)\\|load_paths\\|m\\(?:edia_scrape\\(?:_default_regexp\\|rs\\)\\|i\\(?:me_type_external_handlers\\|nibuffer_\\(?:auto_complete_\\(?:default\\|preferences\\)\\|completion_rows\\|history_max_items\\|input_mode_show_message_timeout\\|read_url_select_initial\\)\\)\\)\\|new_buffer_\\(?:\\(?:with_opener_\\)?position\\)\\|opensearch_load_paths\\|r\\(?:ead_\\(?:buffer_show_icons\\|url_handler_list\\)\\|un_external_editor_function\\)\\|title_format_fn\\|url_\\(?:completion_\\(?:sort_order\\|use_\\(?:bookmarks\\|history\\|webjumps\\)\\)\\|remoting_fn\\)\\|view_source_\\(?:function\\|use_external_editor\\)\\|w\\(?:ebjump_partial_match\\|indow_extra_argument_max_delay\\)\\|xkcd_add_title\\)\\_>"
     1 font-lock-variable-name-face))
  "General font-locking.")

(defvar conkeror--original-indent nil)
(make-variable-buffer-local 'conkeror--original-indent)

(defcustom conkeror-macro-names "\\`\\(interactive\\|define_.*\\)\\'"
  "A regexp matching functions which should be indented as macros."
  :type 'regexp
  :group 'conkeror-minor-mode
  :package-version '(conkeror-minor-mode . "1.3.1"))

(defun conkeror-indent-line ()
  "Indent current line as a conkeror source file.

Relies on `indent-line-function' being defined by the major-mode."
  (interactive)
  (funcall conkeror--original-indent)
  (save-restriction
    (widen)
    (let* ((cur (current-indentation))
           (offset (- (current-column) cur))
           (open (save-excursion (cadr (syntax-ppss (point-at-bol)))))
           (is-in-macro
            (when (integer-or-marker-p open)
              (save-excursion
                (goto-char open)
                (forward-char -1)
                (let ((macro-candidate (thing-at-point 'symbol)))
                  (and
                   (stringp macro-candidate)
                   (string-match conkeror-macro-names
                                 macro-candidate)))))))
      (when is-in-macro
        (indent-line-to 4)
        (when (> offset 0) (forward-char offset))))))

(defvar conkeror--backup-show-trailing-whitespace nil "")
(make-variable-buffer-local 'conkeror--backup-show-trailing-whitespace)

;;;###autoload
(define-minor-mode conkeror-minor-mode nil nil " Conk"
  '(("" . eval-in-conkeror))
  :group 'conkeror-minor-mode
  (if conkeror-minor-mode
      (progn
        (when conkeror-warn-about-guidelines
          (font-lock-add-keywords nil conkeror--font-lock-warnings))
        (font-lock-add-keywords nil conkeror--font-lock-keywords)
        (setq conkeror--original-indent indent-line-function)
        (setq indent-line-function 'conkeror-indent-line)
        (setq conkeror--backup-show-trailing-whitespace show-trailing-whitespace)
        (setq show-trailing-whitespace t))
    (setq indent-line-function conkeror--original-indent)))


(provide 'conkeror-minor-mode)
;;; conkeror-minor-mode.el ends here.

;; Local Variables:
;; coding: utf-8
;; truncate-lines: t
;; End:
