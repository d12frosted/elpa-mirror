emacs-sourcetrail
===========

emacs-sourcetrail is a plugin for Emacs to communicate with Sourcetrail_.

.. _Sourcetrail: https://sourcetrail.com

Install
-------

Usage
-----

From Sourcetrail to Emacs
~~~~~~~~~~~~~~~~~~~

* enable sourcetrail-mode in Emacs
* Right click in sourcetrail -> **Set IDE Curor**
* In the Emacs should now open the file and put the cursor in the position form sourcetrail.

From Emacs to Sourcetrail
~~~~~~~~~~~~~~~~~~~

* Navigate your cursor to the location in the text.
* Sent location to sourcetrail

;+ Press **M-x** and enter **sourcetrail-send-loation**
;+ bind **sourcetrail-send-location** to a key sequence and use it.

Preferences
-----------

* **M-x** customize
* search for sourcetrail
* 3 Settins should be displayed now

Emacs Sourcetrail Ip
~~~~~~~~~~~~~~

Ip address for the Tcp communcation, default is ``localhost``

Emacs Sourcetrail Port Sourcetrail
~~~~~~~~~~~~~~~~~~~~~~

Port Sourcetrail listens to, default is ``6667``

Emacs Sourcetrail Port Emacs
~~~~~~~~~~~~~~~~~~~~~~

Port Sourcetrail listens to, default is ``6666``
