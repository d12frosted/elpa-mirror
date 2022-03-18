	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		OSM.EL - OPENSTREETMAP VIEWER FOR EMACS
	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Features
2. Configuration
3. Bookmarks, Org and Elisp links
4. Commands and Key Bindings
5. Related projects
6. Contributions


<https://github.com/minad/osm/blob/screenshots/osm.png?raw=true> The map
data is © [OpenStreetMap] contributors, licensed under the [ODbL] The
map rendering is © [OpenTopoMap], licensed under the [CC-BY-SA.]


[OpenStreetMap] <https://www.openstreetmap.org/copyright>

[ODbL] <https://opendatacommons.org/licenses/odbl/>

[OpenTopoMap] <https://opentopomap.org/about>

[CC-BY-SA.] <https://creativecommons.org/licenses/by-sa/3.0/>


1 Features
══════════

  • Zoomable and moveable map display
  • Display of tracks and POIs from GPX file
  • Parallel fetching of tiles with curl
  • Moving in large and small steps
  • Mouse support (dragging, clicking, menu)
  • Map scale indicator
  • Go to coordinate
  • Search for location by name
  • Org and Elisp link support
  • Bookmarked positions with pins
  • Multiple preconfigured tile servers


2 Configuration
═══════════════

  The package is available on GNU ELPA and can be installed with
  `package-install'.  The following is an example configuration which
  relies on `use-package'. Please take a look at the [wiki] for
  additional configuration.

  ┌────
  │ (use-package osm
  │   :bind (("C-c m h" . osm-home)
  │ 	 ("C-c m s" . osm-search)
  │ 	 ("C-c m v" . osm-server)
  │ 	 ("C-c m t" . osm-goto)
  │ 	 ("C-c m x" . osm-gpx-show)
  │ 	 ("C-c m j" . osm-bookmark-jump))
  │ 
  │   :custom
  │   ;; Take a look at the customization group `osm' for more options.
  │   (osm-server 'default) ;; Configure the tile server
  │   (osm-copyright t)     ;; Display the copyright information
  │ 
  │   :init
  │   ;; Load Org link support
  │   (with-eval-after-load 'org
  │     (require 'osm-ol)))
  └────


[wiki] <https://github.com/minad/osm/wiki>


3 Bookmarks, Org and Elisp links
════════════════════════════════

  To store a bookmark press the key `b', to store Org/Elisp links press
  the keys `l' or `e' respectively. You can also use a custom binding,
  e.g., `C-c l'. Then the link can be inserted into an Org buffer with
  `C-c C-l'. Bookmarks and Org links can be created at point with the
  mouse, see `osm-bookmark-set-click' and `osm-org-link-click'.


◊ 3.0.0.1 Org link examples

  Click on a link or press `RET' to jump to the location. These links
  work in Org buffers in Emacs.

  • 
  • 
  • 
  • 
  • 


◊ 3.0.0.2 Elisp link examples

  Place the point behind the closing parenthesis and press `C-x C-e' to
  jump to the location. The Elisp links can be used in arbitary text
  files.

  ┌────
  │ (osm 41.869561 12.458496 6 opentopomap "Lazio, Italia")
  │ (osm 51.489507 -0.144196 11 "London, Greater London, England, SW1A 2DX, United Kingdom")
  │ (osm 55.686875 12.569733 12 cyclosm "København, Københavns Kommune, Region Hovedstaden, 1357, Danmark")
  │ (osm 40.729568 -73.979187 12 stamen-watercolor "New York County, New York, United States")
  │ (osm 27.961656 86.892242 13 opentopomap "Khumjung, Khumbupasanglahmu, सोलुखुम्बु, Province #1, Nepal")
  └────


4 Commands and Key Bindings
═══════════════════════════

  Top-level commands:
  • `osm-home': Open new map at home coordinates
  • `osm-search': Search and jump to location
  • `osm-goto': Go to coordinates
  • `osm-server': Select server
  • `osm-bookmark-jump': Jump to bookmark
  • `osm-gpx-show': Show GPX file in map viewer

  Key bindings in `osm-mode' buffer:
  • `<arrow>': Small step scrolling
  • `C-<arrow>', `M-<arrow>': Large step scrolling
  • `+', `SPC': `osm-zoom-in' - Zoom in
  • `-', `S-SPC': `osm-zoom-out' - Zoom out
  • `<mouse-1>': `osm-center-click' - Center to point
  • `<mouse-2>': `osm-org-link-click' - Store point as Org link
  • `<mouse-3>': `osm-bookmark-set-click' - Store point as bookmark
  • `<osm-bookmark mouse-*>': `osm-bookmark-delete-click' - Click on
    bookmark at point to delete
  • `<down-mouse-*>': `osm-mouse-drag' - Drag the map with the mouse
  • `d', `DEL': `osm-bookmark-delete' - Delete selected bookmark
  • `n': `osm-bookmark-rename' - Rename selected bookmark
  • `t': `osm-goto' - Go to location
  • `h': `osm-home' - Go to home location
  • `s': `osm-search' - Search for location
  • `v': `osm-server' - Select tile server
  • `x': `osm-gpx-show' - Show tracks and POIs from GPX file
  • `X': `osm-gpx-hide' - Hide overlays from GPX file
  • `l': `org-store-link' - Store org link
  • `e': `osm-elisp-link' - Store Elisp link in the kill ring
  • `b': `osm-bookmark-set' - Set bookmark
  • `j': `osm-bookmark-jump' - Jump to bookmark
  • `q': `quit-window' - Close buffer and window
  • `c': `clone-buffer' - Clone buffer


5 Related projects
══════════════════

  There have been other attempts at map viewers in Emacs before.

  • <https://github.com/ruediger/osm-mode>
  • <https://github.com/svenssonjoel/Emacs-OSM>
  • <https://github.com/jd/google-maps.el>
  • <https://github.com/emacsattic/org-osm-link>


6 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <http://elpa.gnu.org/packages/osm.html>
