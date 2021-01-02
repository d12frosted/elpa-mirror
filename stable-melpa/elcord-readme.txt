elcord allows you to show off your buffer with all your Discord friends via the new rich presence feature
To use, enable the global minor mode `elcord-mode'
When enabled, elcord will communicate with the local Discord client in order to display information under
the 'Playing a Game' status, updating this information at a regular interval.

elcord will display an Emacs title, icon, as well as information about your current buffer:
1) The name and an icon (if available) for the current major mode
2) The name of the current buffer
3) The line number of the cursor, as well as total line count for the buffer
`elcord-display-buffer-details' can be customized so that buffer name and line number are omitted.
