A read-only viewer with reduced clutter and prettier rendering in org files.
To enter the view-mode run: `M-x org-view-mode'.  To turn it off run the same
command.  The mode tries very hard to not do any changes to the buffer and
the content.  However, it does use text properties for some effects, so at
least in theory, if you don't exit the viewer cleanly, via some of its exit
methods, it might happened that the view is not restored properly.  In that
case you may re-enter, and exit the viewer again, or re-open the file.

; Issues
