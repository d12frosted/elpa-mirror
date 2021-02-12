
* Introduction
Tabbar ruler is an Emacs package that allows both the tabbar and the
ruler to be used together.  In addition it allows auto-hiding of the
menu-bar and tool-bar.


Tabbar appearance based on reverse engineering Aquaemacs code and
changing to my preferences, and Emacs Wiki.

Tabbar/Ruler integration is new.  Tabbar should be active on mouse
move.  Ruler should be active on self-insert commands.

Also allows auto-hiding of toolbar and menu.

To use this, put the library in your load path and use


  (setq tabbar-ruler-global-tabbar t) ; If you want tabbar
  (setq tabbar-ruler-global-ruler t) ; if you want a global ruler
  (setq tabbar-ruler-popup-menu t) ; If you want a popup menu.
  (setq tabbar-ruler-popup-toolbar t) ; If you want a popup toolbar
  (setq tabbar-ruler-popup-scrollbar t) ; If you want to only show the
                                        ; scroll bar when your mouse is moving.
  (require 'tabbar-ruler)




* Changing how tabbar groups files/buffers
The default behavior for tabbar-ruler is to group the tabs by frame.
You can change this back to the old-behavior by:

  (tabbar-ruler-group-buffer-groups)

or by issuing the following code:


  (setq tabbar-buffer-groups-function 'tabbar-buffer-groups)


In addition, you can also group by projectile project easily by:


  (tabbar-ruler-group-by-projectile-project)

* Adding key-bindings to tabbar-ruler
You can add key-bindings to change the current tab.  The easiest way
to add the bindings is to add a key like:


  (global-set-key (kbd "C-c t") 'tabbar-ruler-move)


After that, all you would need to press is Control+c t and then the
arrow keys will allow you to change the buffer quite easily.  To exit
the buffer movement you can press enter or space.

* Known issues
the left arrow is text instead of an image.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
