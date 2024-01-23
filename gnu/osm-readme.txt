               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                OSM.EL - OPENSTREETMAP VIEWER FOR EMACS
               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Osm.el is a tile-based map viewer, with a responsive movable and
zoomable display. The map can be controlled with the keyboard or with
the mouse. The viewer fetches the map tiles in parallel from tile
servers via the `curl' program.  The package comes with a list of
multiple preconfigured tile servers. You can bookmark your favorite
locations using regular Emacs bookmarks or create links from Org files
to locations. Furthermore the package provides commands to search for
locations by name and to open and display GPX tracks.

Table of Contents
─────────────────

1. Features
2. Configuration
3. Bookmarks, Org links, Geo urls and Elisp links
4. Distance measurement
5. Commands and Key Bindings
6. Related projects
7. Contributions


1 Features
══════════

  • Responsive, zoomable and movable map display
  • Display of tracks and POIs from GPX file
  • Parallel fetching of tiles with curl
  • Moving in large and small steps
  • Mouse support (dragging, clicking, menu)
  • Map scale indicator
  • Distance measurement
  • Go to coordinate
  • Search for location by name
  • Org link, Geo url and Elisp link support
  • Bookmarked positions with pins
  • Multiple preconfigured tile servers


2 Configuration
═══════════════

  The package is available on GNU ELPA and can be installed with
  `package-install'.  Note that Osm.el requires Emacs 27 and depends on
  the external `curl' program.  Emacs must be built with `libxml',
  `libjansson', `librsvg', `libjpeg' and `libpng' support. The following
  is an example configuration which relies on `use-package'.  Please
  take a look at the [wiki] for additional configuration.

  ┌────
  │ (use-package osm
  │   :bind ("C-c m" . osm-prefix-map) ;; Alternatives: `osm-home' or `osm'
  │ 
  │   :custom
  │   ;; Take a look at the customization group `osm' for more options.
  │   (osm-server 'default) ;; Configure the tile server
  │   (osm-copyright t)     ;; Display the copyright information
  │ 
  │   :config
  │ 
  │   ;; Add custom servers, see also https://github.com/minad/osm/wiki
  │   ;; (osm-add-server 'myserver
  │   ;;   :name "My tile server"
  │   ;;   :group "Custom"
  │   ;;   :description "Tiles based on aerial images"
  │   ;;   :url "https://myserver/tiles/%z/%x/%y.png?apikey=%k")
  │ )
  └────


[wiki] <https://github.com/minad/osm/wiki>


3 Bookmarks, Org links, Geo urls and Elisp links
════════════════════════════════════════════════

  There exist multiple methods to store a location, such that you can
  return there afterwards.

  • `b': Create a bookmark of the current location. The bookmark is
    stored as an Emacs bookmark in `bookmark-alist'. You can jump to the
    bookmark via the completion commands `osm-bookmark-jump' or
    `bookmark-jump'.
  • `l': Store an Org link to the current location. The link can be
    inserted subsequently into an Org buffer with `C-c C-l'.
  • `u': Save the geo url of the current location in the kill ring. The
    url can be inserted in another buffer via `C-y'. A geo url has the
    form `geo:27.96,86.89;z=13'.
  • `C-u u': Save an Elisp link to the current location in the kill
    ring. An Elisp link has the form `(osm 51.49 -0.14 11)'.

  Bookmarks and Org links can be created at point by clicking with the
  mouse. See the docstrings of the commands `osm-bookmark-set' and
  `org-link-store'.


◊ 3.0.0.1 Org link examples

  Click on a link or press `RET' to jump to the location. These links
  work in Org buffers in Emacs. Furthermore you can open Org links in
  arbitrary buffers with `org-open-at-point-global'. I recommend binding
  the command to a convenient key, e.g., `C-c o'. The format of the
  links complies with the [geo URI scheme] defined by [RFC 5870].

  ┌────
  │ [[geo:41.869560826994544,12.45849609375;z=6;s=opentopomap][Italia, 41.87° 12.46° OpenTopoMap]]
  │ [[geo:51.48950698022105,-0.144195556640625;z=11][London, England, 51.49° -0.14°]]
  │ [[geo:55.686875255964424,12.569732666015625;z=12;s=cyclosm][København, Danmark, 55.69° 12.57° CyclOSM]]
  │ [[geo:27.961656050984658,86.89224243164062;z=13;s=opentopomap][Mount Everest, 27.96° 86.89° OpenTopoMap]]
  │ <geo:Tour Eiffel, Av. Gustave Eiffel, Paris> (Address link)
  └────


  [geo URI scheme] <https://en.wikipedia.org/wiki/Geo_URI_scheme>

  [RFC 5870] <https://datatracker.ietf.org/doc/html/rfc5870>


◊ 3.0.0.2 Elisp link examples

  Place the point behind the closing parenthesis and press `C-x C-e' to
  jump to the location. The Elisp links can be used in arbitrary text
  files. Since they are Elisp s-expressions they can be easily
  manipulated programatically.

  ┌────
  │ (osm 41.869561 12.458496 6 'opentopomap "Lazio, Italia")
  │ (osm 51.489507 -0.144196 11 "London, Greater London, England, SW1A 2DX, United Kingdom")
  │ (osm 55.686875 12.569733 12 'cyclosm "København, Københavns Kommune, Region Hovedstaden, 1357, Danmark")
  │ (osm 27.961656 86.892242 13 'opentopomap "Khumjung, Khumbupasanglahmu, सोलुखुम्बु, Province #1, Nepal")
  │ (osm "Tour Eiffel, Av. Gustave Eiffel, Paris") ;; Address link
  └────


4 Distance measurement
══════════════════════

  Osm provides a simple distance measurement utility. In order to
  measure a distance, place or select a pin by clicking with the left
  mouse button. Then create one or more additional way points by
  pressing shift and clicking the left mouse button. The length of the
  track will be shown in the echo area. You can select the way points of
  the track and delete them with `d' or `DEL'.


5 Commands and Key Bindings
═══════════════════════════

  Top-level commands in `osm-prefix-map'. These bindings are available
  globally if you bind `osm-prefix-map' to a key like `C-c m'. For
  example, to search for a location press the key sequence `C-c m
  s'. Furthermore the key bindings are available in Osm buffers. There
  it is sufficient to press the key `s' only to initiate a search.

  • `h': `osm-home' - Open new map at home coordinates
  • `s': `osm-search' - Search and jump to location
  • `t': `osm-goto' - Go to coordinates
  • `v': `osm-server' - Select server
  • `j': `osm-jump' - Jump to pin (bookmark or POI)
  • `x': `osm-gpx-show' - Show GPX file in map viewer

  Some additional key bindings are available in Osm buffers:

  • `<arrow>': Small step scrolling
  • `C-<arrow>', `M-<arrow>', `S-<arrow>': Large step scrolling
  • `+', `SPC': `osm-zoom-in' - Zoom in
  • `-', `S-SPC': `osm-zoom-out' - Zoom out
  • `<mouse-1>': `osm-mouse-pin' - Place pin at point
  • `<mouse-2>': `org-link-store' - Store point as Org link
  • `<mouse-3>': `osm-bookmark-set' - Store point as bookmark
  • `S-<mouse-1>': `osm-mouse-track' - Create track pin to measure
    distance
  • `<down-mouse-*>': `osm-mouse-drag' - Drag the map with the mouse
  • `d', `DEL': `osm-delete' - Delete selected pin (bookmark or way
    point)
  • `n': `osm-rename' - Rename selected pin
  • `c': `osm-center' - Center to currently selected pin
  • `X': `osm-gpx-hide' - Hide overlays from GPX file
  • `l': `org-store-link' - Store Org link
  • `u': `osm-save-url' - Save geo url in the kill ring
  • `b': `osm-bookmark-set' - Set bookmark
  • `q': `quit-window' - Close buffer and window
  • `o': `clone-buffer' - Clone buffer


6 Related projects
══════════════════

  There have been other attempts at map viewers in Emacs before.

  • <https://github.com/ruediger/osm-mode>
  • <https://github.com/svenssonjoel/Emacs-OSM>
  • <https://github.com/jd/google-maps.el>
  • <https://github.com/emacsattic/org-osm-link>


7 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/osm.html>
