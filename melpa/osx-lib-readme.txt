Provides functions for:
  1. Running Apple Script / osascript
  2. Play beep
     (setq ring-bell-function #'osx-lib-do-beep)
  3. Notification functions
     (osx-lib-notify2 "Emacs" "Text Editor")
  4. Copying to/from clipboard
  5. Show the current file in Finder.  Works with dired.
  6. Get/Set Sound volume
     (osx-lib-set-volume 25)
     (osx-lib-get-volume)
  6. Mute/unmute Sound volume
     (osx-lib-mute-volume)
     (osx-lib-unmute-volume)
  8. VPN Connect/Disconnect
     (defun work-vpn-connect ()
       "Connect to Work VPN."
       (interactive)
       (osx-lib-vpn-connect "WorkVPN" "VPN_Password"))
  9. Use speech
     (osx-lib-say "Emacs")
  10.Use mdfind(commandline equivalent of Spotlight) for locate
     (setq locate-make-command-line #'osx-locate-make-command-line)
