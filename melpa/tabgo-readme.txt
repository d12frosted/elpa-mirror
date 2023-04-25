tabgo is a package that allows the user to switch between tabs in a
graphical and more intuitive way, like avy.

Typically you'll want to bind `tabgo' function to a key.

    (define-key global-map (kbd "M-t") #'tabgo)

Once you have bound `tabgo', you can call it by pressing the key
you bound it to.  You'll see that highlighted characters appear on
the tab-bar and tab-line tab names.  Simply press the one that you
want to go to and `tabgo' will switch to it for you.
