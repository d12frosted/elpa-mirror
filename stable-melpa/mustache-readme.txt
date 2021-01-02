See documentation at https://github.com/Wilfred/mustache.el

Note on terminology: We treat mustache templates as a sequence of
strings (plain text), and tags (anything wrapped in delimeters:
{{foo}}). A section is a special tag that requires closing
(e.g. {{#foo}}{{/foo}}).

We treat mustache templates as if they conform to a rough grammar:

TEMPLATE = plaintext | TAG | SECTION | TEMPLATE TEMPLATE
SECTION = OPEN-TAG TEMPLATE CLOSE-TAG
TAG = "{{" text "}}"

Public functions are of the form `mustache-FOO`, private
functions/variables are of the form `mst--FOO`.
