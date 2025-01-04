Boxy provides an interface to create a 3D representation of boxes.
Each box has a relationship with one other box.  Multiple boxes can
be related to one box.  The relationship can be any of the
following:

- in
- on
- behind
- on top of
- in front of
- above
- below
- to the right of
- to the left of

The relationship determines the ordering and structure of the
resulting boxy diagram.

Only boxes which have their :name slot set will be drawn to the
buffer.  Boxes without names still take up space and can have
children, so can be used for grouping.  All diagrams have one top
level unnamed box called a `world'.

Each box should have either a list of markers or an action
function.  When viewing a box that has a list of markers, the
following keybindings are available:

RET/mouse-1   - Jump to the first marker
o             - Open next marker in other window.
                  Pressed multiple times, cycle through markers.
M-RET         - Open all markers as separate buffers.
                  This will split the current window as needed.

When viewing a box with an action function, RET and <mouse-1> will
be bound to that function.

Additionally, all boxes have the following keybindings defined:

r     - Jump to the box directly related to the current box.
          Repeated presses will eventually take you to the
          top level box.
TAB   - Cycle visibility of box's children

See the class definition for `boxy-box' for all other available
properties.

To start, create an empty box named `world'.

  (let ((world (boxy-box)))

Use the method `boxy-add-next' to add top-level boxes to the world,
without relationships:

  (let ((cyprus (boxy-box :name "Cyprus"))
        (greece (boxy-box :name "Greece")))
    (boxy-add-next cyprus world)
    (boxy-add-next greece world)

To ease the boxy renderer, use the :expand-siblings and
:expand-children slots.  These should be list of functions which
take the current box as an argument and call `boxy-add-next' to add
sibling boxes and children boxes respectively.  Children boxes are
defined as any box with a relationship of in, on, behind, in front
of, or on top of.  Sibling boxes are defined as any box with a
relationship of above, below, to the left of, or to the right of.

   (push '(lambda (box)
            (boxy-add-next
             (boxy-box :name "Lebanon" :rel "below")
             box))
         (boxy-box-expand-siblings cyprus))

The expansion slots will be called when the user toggles the box's
visibility.

To display a box in a popup buffer, use the function `boxy-pp'.

The methods `boxy-merge' and `boxy-merge-into' should be used to
merge boxes together.  `boxy-merge' takes a list of boxes and
merges them into one box.  `boxy-merge-into' takes two boxes and
merges the first into the second.