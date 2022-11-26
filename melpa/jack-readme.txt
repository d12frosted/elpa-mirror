`jack' provides the function `jack-html' that takes a data structure
as input representing the HTML tree you want to generate and generates it
as a string.

For instance:

    (jack-html '(:section (:div (:p "foo"))))
    ;; "<section><div><p>foo</p></div></section>"

HTML attributes are specified in a list starting by the '@' sign

    (jack-html '(:div (@ :id "id" :class "class" :style "color:red;") "foo"))
    ;; "<div id=\"id\" class=\"class\" style=\"color:red;\">foo</div>"

In the keyword defining the HTML tag you can use '/' to declare its
'id' and '.' to declare its classes like this:

    (jack-html '(:div/id.class-1.class-2
                 (@ :class "class-3" :style "color:red;")
                 "foo"))
    ;; "<div id=\"id\" class=\"class-1 class-2 class-3\" style=\"color:red;\">foo</div>"

Note that I would have prefered to use '#' for declaring the 'id' but it
has to be escaped in keywords which is ugly.

More in the docs either in directory 'docs' or at https://jack.tonyaldon.com.
