Draw timed events as an interactive SVG week calendar and edit them by
dragging or from the keyboard.  This file has no Org dependency: it renders
whatever a backend supplies, through the protocol in `org-timegrid-model'.
`org-timegrid-org' is the Org implementation of that protocol.
Drawing data lives in `org-timegrid-scene', SVG interpretation in
`org-timegrid-svg', and cache/resource ownership in `org-timegrid-display'.
