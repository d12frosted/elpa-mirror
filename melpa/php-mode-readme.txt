`php-mode' is a major mode for editing PHP script.  Unlike the legacy
`php-cc-mode' (kept for backward compatibility in lisp/php-cc-mode.el),
this implementation does NOT depend on CC Mode.  Indentation is handled
by the `syntax-ppss'-based engine in php-indent.el, coding styles by
php-style.el, and the PHP vocabulary comes from php-keywords.el.

This mode is designed for PHP scripts consisting of a single <?php
block.  We recommend Web Mode for HTML and Blade templates mixed with
PHP.  http://web-mode.org/
