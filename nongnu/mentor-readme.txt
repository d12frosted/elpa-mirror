Table of Contents
─────────────────

1. mentor
.. 1. Screenshot
.. 2. Features
.. 3. Installing mentor
..... 1. Installing through NonGNU ELPA (recommended)
..... 2. Installing mentor manually
.. 4. Quick Start
.. 5. Configuration
..... 1. General
..... 2. External rTorrent
..... 3. Configuring rtorrent
.. 6. Key Bindings
..... 1. Downloads
..... 2. Marking
..... 3. Sorting
..... 4. Misc
.. 7. Mapping from rTorrent commands to Mentor
..... 1. Main view keys
.. 8. Known issues
.. 9. Contact


1 mentor
════════

  [https://elpa.nongnu.org/nongnu/mentor.svg]
  [https://melpa.org/packages/mentor-badge.svg]

  mentor is a [GNU Emacs] frontend for the [rTorrent] bittorrent client.

  By default, it will start and run rTorrent from within Emacs but can
  also be configured to use an external rTorrent instance over XML-RPC.

  This project aims to provide a feature complete and highly
  customizable interface, that will feel familiar to Emacs users.  Key
  bindings are chosen to be as close to the vanilla rTorrent curses
  interface as possible.

  mentor still has some way to go before it can really be considered a
  complete interface, so please moderate your expectations.  It works
  fine for many common tasks though, and in some cases (dare we say?)
  much better than the standard ncurses interface.


[https://elpa.nongnu.org/nongnu/mentor.svg]
<https://elpa.nongnu.org/nongnu/mentor.html>

[https://melpa.org/packages/mentor-badge.svg]
<https://melpa.org/#/mentor>

[GNU Emacs] <https://www.gnu.org/software/emacs>

[rTorrent] <http://libtorrent.rakshasa.no/>

1.1 Screenshot
──────────────



  Screenshot of moving a download and its data to another directory
  using ido integration.  Sort your downloads in a breeze!


1.2 Features
────────────

  Here is a summary of some of the features:

  • Show torrents in a table, with configurable columns.
  • Search torrents using `C-s' (no more of the manual up/down).
  • Mark and perform operations on more than one torrent at once.
  • Sort torrents according to one or more criteria.
  • Move downloads together with their data in one command.
  • Switch between views, create new etc. (like numbers)
  • Support for most standard operations.  (Start/stop/rehash/move etc.)
  • Use all Emacs features you are used to: macros, Emacs Lisp, etc.


1.3 Installing mentor
─────────────────────

1.3.1 Installing through NonGNU ELPA (recommended)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can install mentor from [NonGNU ELPA] or [MELPA].

  NonGNU ELPA is configured by default in Emacs 28.1 or later.  Find and
  install Mentor using this command:

  ┌────
  │ M-x package-list-packages
  └────


  For earlier versions, please see the specific instructions for how to
  configure [NonGNU ELPA] and [MELPA].


[NonGNU ELPA] <https://elpa.nongnu.org/>

[MELPA] <https://melpa.org/>

[MELPA] <https://melpa.org/#/getting-started>


1.3.2 Installing mentor manually
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can also install mentor manually.  First, make sure you have the
  minimum version of [xml-rpc.el] installed.

  Clone this repository using:

  ┌────
  │ git clone https://github.com/skangas/mentor.git
  └────


  Add this to your init.el:

  ┌────
  │ (add-to-list 'load-path "~/src/mentor/")
  │ (require 'mentor)
  └────


  Change `"~/src/mentor"' to the path where you keep the mentor source
  code.

  To byte-compile mentor, go to the source directory and run:

  ┌────
  │ make
  └────


  To setup autoloading, you can add this to your Init file:

  ┌────
  │ (autoload 'mentor "mentor" nil t)
  └────


[xml-rpc.el] <https://github.com/xml-rpc-el/xml-rpc-el>


1.4 Quick Start
───────────────

  Make sure that you have rTorrent (0.9.0 or later) installed on your
  system.

  To start mentor, just run:

  ┌────
  │ M-x mentor
  └────


  It should work out of the box, but you may want to do some additional
  configuration.


1.5 Configuration
─────────────────

1.5.1 General
╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can find additional Mentor options in customize.

  ┌────
  │ M-x customize-group RET mentor RET
  └────


  Two useful variables to customize are
  `mentor-rtorrent-download-directory' and
  `mentor-rtorrent-keep-session'.


1.5.2 External rTorrent
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you are already running rTorrent outside of Emacs, it is easy to
  configure Mentor to use it.

  Add this to your `~/.rtorrent.rc' and restart rTorrent:

  ┌────
  │ scgi_local = ~/.rtorrent-rpc.socket
  │ encoding.add = utf8
  └────


  Customize `mentor-rtorrent-external-rpc', or add this to your Init
  file and restart Emacs.

  ┌────
  │ (setq mentor-rtorrent-external-rpc "~/.rtorrent-rpc.socket")
  └────


  You can also specify an absolute path:

  ┌────
  │ ;; Alternative 2: Absolute path
  │ (setq mentor-rtorrent-external-rpc "/path/to/rtorrent-rpc.socket")
  └────


  It is also possible to connect to rtorrent over http.  There are
  instructions on configuring this on the [rtorrent wiki].

  ┌────
  │ ;; Alternative 3: Use a web server
  │ (setq mentor-rtorrent-external-rpc "http://127.0.0.1:8080/RPC2")
  └────


  Finally, you can connect directly to rtorrent over scgi.  However,
  anyone that can send rtorrent xmlrpc requests can in all likelihood
  also execute arbitrary code as the user running rtorrent.  Therefore,
  this is inadvisable on anything but the loopback device
  (e.g. `127.0.0.1') on single-user systems.

  It is almost always easier and better to use a Unix domain socket
  (file) as suggested above.

  ┌────
  │ ;; Alternative 4: Connect directly to rtorrent over scgi
  │ (setq mentor-rtorrent-external-rpc "scgi://127.0.0.1:5000")
  └────


[rtorrent wiki]
<https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC>


1.5.3 Configuring rtorrent
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  For more information on configuring rTorrent, refer to the [rTorrent
  wiki].


[rTorrent wiki] <https://github.com/rakshasa/rtorrent/wiki>


1.6 Key Bindings
────────────────

1.6.1 Downloads
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `DEL'  Add torrent file                          
   `l'    Add Magnet link, URL or torrent file path 
   `s'    Start download                            
   `d'    Stop download                             
   `D'    Remove download                           
   `k'    Close download                            
   `K'    Remove download including data            
   `r'    Initiate hash check for download          
   `g'    Update screen                             
   `G'    Re-initialize all download data           
   `v'    Show download in dired                    
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.6.2 Marking
╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━
   `m'  Mark item        
   `u'  Unmark item      
   `M'  Mark all items   
   `U'  Unmark all items 
  ━━━━━━━━━━━━━━━━━━━━━━━


1.6.3 Sorting
╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `t c'  Sort downloads by state          
   `t D'  Sort downloads by directory      
   `t d'  Sort downloads by download speed 
   `t n'  Sort downloads by name           
   `t p'  Sort downloads by size           
   `t t'  Sort downloads by tied file name 
   `t u'  Sort downloads by upload speed   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.6.4 Misc
╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `RET'  Enter file details screen 
   `R'    Move download data        
   `C'    Copy download data        
   `x'    Call XML-RPC command      
   `q'    Bury mentor               
   `Q'    Shutdown mentor           
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.7 Mapping from rTorrent commands to Mentor
────────────────────────────────────────────

1.7.1 Main view keys
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   *rTorrent*  *Mentor*   *Description*                                                     
   `->'        `RET'      View download                                                     
   `0' - `9'   `0' - `9'  Change view                                                       
   `^S'        `s'        Start download                                                    
   `^D' (1)    `d'        Stop an active download                                           
   `^D' (2)    `D'        Remove download                                                   
   `^K'        `k'        Close a torrent and its files                                     
   /n/a/       `K'        Remove download including data                                    
   `^E'        `e'        Set 'create/resize queued' flags                                  
   `^R'        `r'        Initiate hash check of torrent                                    
   `^O'        `o'        Change the destination directory of the download                  
   `^X'        `x'        Call commands or change settings                                  
   `^B'        /n/a/      Set download to perform initial seeding                           
   `+' / `-'   `+' / `-'  Change the priority of the download                               
   `<DEL>'     `DEL'      Add torrent file                                                  
               `l'        Add Magnet link, URL or torrent file path                         
   `l'         /n/a/      View log.  Exit by pressing the space-bar                         
   `U'         /n/a/      Delete the file the torrent is tied to, and clear the association 
   `I'         /n/a/      Toggle whether torrent ignores ratio settings                     
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.8 Known issues
────────────────

  • There is no view for trackers/peers/extra information.

  • Mentor used to have performance issues when there were several
    hundreds or thousands of torrents.  So I wrote a patch for
    xml-rpc.el to add support for Emacs built-in libxml support, which
    was helpfully merged by the xml-rpc.el maintainer Mark
    A. Hershberger.  This improved performance by a factor of 100.  Make
    sure you upgrade to Emacs 27.1, build it with libxml support, and
    use the latest xml-rpc.el version to benefit from this speed
    increase.


1.9 Contact
───────────

  You can find the latest version of mentor here:

  <https://www.github.com/skangas/mentor>

  Bug reports, comments, and suggestions are welcome! Send them to
  Stefan Kangas <stefankangas@gmail.com> or report them on GitHub.
