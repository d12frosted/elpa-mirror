
Go to the end of any of the following lines and run `M-x lively'
  Current time:      (current-time-string)
  Last command:      last-command
  Open buffers:      (length (buffer-list))
  Unix processes:    (lively-shell-command "ps -a | wc -l")

then the code will be replaced by its formatted result -- and
periodically updated.  You can create little dashboards.
Use `M-x lively-stop' to restore order.

Based on the Squeak hack by Scott Wallace.
