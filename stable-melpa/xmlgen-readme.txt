Generate xml using sexps with the function `xmlgen':

(xmlgen '(p :class "big"))      => "<p class=\"big\" />")
(xmlgen '(p :class "big" "hi")) => "<p class=\"big\">hi</p>")

(xmlgen '(html
          (head
           (title "hello")
           (meta :something "hi"))
          (body
           (h1 "woohhooo")
           (p "text")
           (p "more text"))))

produces this (though wrapped):

<html>
  <head>
    <title>hello</title>
    <meta something="hi" />
  </head>
  <body>
    <h1>woohhooo</h1>
    <p>text</p>
    <p>more text</p>
  </body>
</html>
