Summary:
this package provides eclipse-like forward/backward navigation
bound by default to <C-left> (backward-forward-previous-location)
and <C-right> (backward-forward-next-location)

More Info:
backward-forward hooks onto "push-mark" operations and keeps
track of all such operations in a global list of marks called backward-forward-mark-ring
this enables easy navigation forwards and backwards in your history
of marked locations using <C-left> and <C-right> (or feel free to change the keybindings).

Many Emacs commands (such as searching or switching buffers with certain packages enabled)
invoke push-mark.
Other Emacs commands can be configured to invoke push mark using the system below:
     (advice-add 'ggtags-find-tag-dwim :before #'backward-forward-push-mark-wrapper)
 You can see examples of the above convention below.

Use C-h k to see what command a given key sequence is invoking.

to use this package, install though the usual Emacs package install mechanism
then put the following in your .emacs

   ;(setf backward-forward-evil-compatibility-mode t) ;the line to the left is optional,
         ; and recommended only if you are using evil mode
   (backward-forward-mode t)


| Commmand                | Keybinding |
|-------------------------+------------|
| backward-forward-previous-location | <C-left>   |
| backward-forward-next-location     | <C-right>  |
