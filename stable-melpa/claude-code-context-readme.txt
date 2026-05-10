This package automatically shares your current buffer context
(file, line, column, selection, and diagnostics) with Claude Code
via a context file that Claude Code hooks can read.

Setup:
1. Add to your init.el:
   (require 'claude-code-context)
   (claude-code-context-mode 1)

2. Add this hook to your ~/.claude/settings.json:
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "CONTEXT_FILE=\"${XDG_CONFIG_HOME:-$HOME/.config}/emacs/claude-code-context.json\"; [ -f \"$CONTEXT_FILE\" ] || CONTEXT_FILE=\"$HOME/.emacs.d/claude-code-context.json\"; if [ -f \"$CONTEXT_FILE\" ]; then echo \"\\n---\\n## Emacs Context\\n\"; cat \"$CONTEXT_FILE\"; echo \"\\n---\"; fi"
             }
           ]
         }
       ]
     }
   }

Usage:
- C-c C-l u : Manually update context
- C-c C-l d : Add flymake diagnostics to context
- C-c C-l c : Clear context
- C-c C-l m : Toggle automatic context mode
