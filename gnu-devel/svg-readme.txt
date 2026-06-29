This package allows creating SVG images in Emacs.  SVG images are
vector-based XML files, really, so you could create them directly
as XML.  However, that's really tedious, as there are some fiddly
bits.

In addition, the `svg-insert-image' function allows inserting an
SVG image into a buffer that's updated "on the fly" as you
add/alter elements to the image, which is useful when composing the
images.

Here are some usage examples:

Create the base image structure, add a gradient spec, and insert it
into the buffer:

    (setq svg (svg-create 800 800 :stroke "orange" :stroke-width 5))
    (svg-gradient svg "gradient" 'linear '((0 . "red") (100 . "blue")))
    (save-excursion (goto-char (point-max)) (svg-insert-image svg))

Then add various elements to the structure:

    (svg-rectangle svg 100 100 500 500 :gradient "gradient" :id "rec1")
    (svg-circle svg 500 500 100 :id "circle1")
    (svg-ellipse svg 100 100 50 90 :stroke "red" :id "ellipse1")
    (svg-line svg 100 190 50 100 :id "line1" :stroke "yellow")
    (svg-polyline svg '((200 . 100) (500 . 450) (80 . 100))
                  :stroke "green" :id "poly1")
    (svg-polygon svg '((100 . 100) (200 . 150) (150 . 90))
                 :stroke "blue" :fill "red" :id "gon1")