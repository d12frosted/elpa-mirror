imbot is inspired by https://github.com/laishulu/emacs-smart-input-source
usage:
emacs uses xim, make sure environment variables are set correctly, in case of ibus, eg:
export XIM="ibus"
export XIM_PROGRAM="ibus"
ibus is slow in restoring application im state, make sure to share ibus state in all apllications
1. redefine these functions according to your input method manager:
   imbot--active-p, imbot--activate, imbot--deactivate
2. disable inline english with:
   (delq 'imbot--english-p imbot--suppression-predicates)
3. the key to exit inline english is return
4. add imbot-mode to relevant startup hooks, eg:
   (add-hook 'evil-mode-hook 'imbot-mode)
