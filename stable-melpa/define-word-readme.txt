
This package will send an anonymous request to https://wordnik.com/
to get the definition of word or phrase at point, parse the resulting HTML
page, and display it with `message'.

Extra services can be added by customizing `define-word-services'
where an url, a parsing function, and an (optional) function other
than `message' to display the results can be defined.

The HTML page is retrieved asynchronously, using `url-retrieve-link'.
