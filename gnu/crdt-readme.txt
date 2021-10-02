* Introduction

~crdt.el~ is a real-time collaborative editing environment for Emacs using Conflict-free Replicated Data Types.

Highlights:
- [[https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type][CRDT]], darling child of collaborative editing researches...
- Share multiple buffer in one session
- See other users' cursor and region
- Synchronize Org mode folding status
- Org mode integration
- Comint derivatives integration (experimental)

* Usage

** Installation

~crdt.el~ is now on GNU ELPA! Just =M-x package-install crdt=.

*Caution!!!* Please make sure that you and your peers are on the same ~crdt.el~ version!
It turns out to be one of the most common causes of ~crdt.el~ not working.
Because currently the network protocol is not stablized, behavior when using mismatched versions is unexpectable.
- Strictly speaking, it should works when =crdt-protocol-version= are defined and the same on all peers.
  But why not save some hassle and keep everyone on the latest version.
- To upgrade, just =M-x package-reinstall crdt=, then preferably restart Emacs.

** Start a shared session

A shared session is a place that can contains multiple buffers (or files),
and multiple users can join to collaboratively edit those buffers (or files).
Think about a meeting room with some people working together on some papers.

In some buffer, =M-x crdt-share-buffer=. Then enter session name.
This add the current buffer to the existing session with that name.
If no such exists, it creates a new session with the provided session name,
and initially contains the current buffer as a shared buffer.

If a new session is to be created, you need to enter port (default to 6530),
optional password and your display name (default to your current =(user-full-name)=).

** Join a session

=M-x crdt-connect=, then enter address, port, and your display name.
  
** List active users

In a CRDT shared buffer (either server or client), =M-x crdt-list-users=.

In the displayed user list, press ~RET~ on an entry to goto that user's cursor position.
Press ~f~ to follow that user, and press ~f~ again or =M-x crdt-stop-follow= to stop following.

** List all sessions, and buffer in current session

=M-x crdt-list-sessions= lists all sessions.

=M-x crdt-list-buffers= lists all buffers in current session. Or you can also 
press ~RET~ in the session list to see buffers in the selected session.

** Stop sharing

=M-x crdt-stop-session= stops a session you've started and disconnect all other users from it.
This will ask for your confirmation, customize =crdt-confirm-stop-session= if you want to disable it.

You can also press ~k~ in the session list (show it by =M-x crdt-list-sessions=).

=M-x crdt-stop-share-buffer= removes current buffer from its CRDT session 
(this operation is only allowed at server side). Or press ~k~ in the buffer list.

** Disconnect from a session

=M-x crdt-disconnect=, then choose a session to disconnect from.

You can also press ~k~ in the session list (show it by =M-x crdt-list-sessions=).

The server Emacs has the privilege to disconnect a user from a session.
To do so, press ~k~ on an entry in the user list (show it by =M-x crdt-list-users=).

** Visualizing author of parts of the document
Turn on =crdt-visualize-author-mode=. Colored underlines are added to each part of the document,
based on which user authored it.

** Synchronizing Org folding status

Turn on =crdt-org-sync-overlay-mode=. All peers that have this enabled have their
folding status synchronized. Peers without enabling this minor mode are unaffected.

** Comint integration

Just go ahead and share you comint REPL buffer! Tested: ~shell~ and ~cmuscheme~.
By default, when sharing a comint buffer, ~crdt.el~ temporarily reset input history (as in =M-n= =M-p=)
so others don't spy into your =.bash_history= and alike.
You can customize this behavior using variable =crdt-comint-share-input-history=.

** What if we don't have a public IP?

There're various workaround.

- You can use [[https://gitlab.com/gjedeer/tuntox][tuntox]] to proxy your connection over the [[https://tox.chat][Tox]] protocol.
  =crdt.el= has experimental built-in integration for =tuntox=.
  To enable it, you need to install =tuntox=,
  set up the custom variable =crdt-tuntox-executable= accordingly (the path to your =tuntox= binary),
  and set the custom variable =crdt-use-tuntox=. 
  Setting it to =t= make =crdt.el= always create =tuntox= proxy for new server sessions, 
  and setting it to ='confirm= make =crdt.el= ask you every time when creating new sessions.
  After starting a session with =tuntox= proxy,
  you can =M-x crdt-copy-url= to copy a URL recognizable by =M-x crdt-connect= and share it to your friends.
  Be aware that according to my experience, =tuntox= takes significant time to establish a connection (sometimes up to half a minute),
  however it gets much faster after the connection is established.

- You can use Teredo to get a public routable IPv6 address. 
  One free software implementation is Miredo. Get it from your
  favorite package manager or from [[https://www.remlab.net/miredo/][their website]].
  A typical usage is (run as root)
  #+BEGIN_SRC
# /usr/local/sbin/miredo
# ifconfig teredo
  #+END_SRC
  The =ifconfig= command should print the information of your IPv6 address.
  Now your traffic go through IPv6, and once you start a =crdt.el= session,
  your friends should be able to join using the IPv6 address.
  For more information, see the user guide on the Miredo website.

- You can use SSH port forwarding if you have a VPS with public IP.
  Example usage:
  #+BEGIN_SRC 
$ ssh -R EXAMPLE.COM:6530:127.0.0.1:6530 EXAMPLE.COM
  #+END_SRC
  This make your =crdt.el= session on local port =6530= accessible from
  =EXAMPLE.COM:6530=.
  
  Note that you need to set the following =/etc/ssh/sshd_config= option on 
  your VPS
  #+BEGIN_SRC 
GatewayPorts yes
  #+END_SRC
