This package provides a quick way to look up any Javadoc
documentation from Emacs, using your browser to display the
information. Since the mechanism is already there, java-import.el
provides the completing function `javadoc-add-import' for quickly
adding an import to a source file.

This mode stores database and index information in
`javadoc-lookup-cache-dir'.

Indexing:

Give `javadoc-lookup' your root Java documentation directories. It
will scan and index those directories, exposing them to
`javadoc-lookup'. Multiple directories can be provided at once, for
example,

  (javadoc-add-roots "/usr/share/doc/openjdk-6-jdk/api"
                     "~/src/project/doc")

If you haven't loaded the core Java Javadoc, it will load a
pre-made database for you, which indexes the official website.

More conveniently, you can list Maven artifacts to index,

  (javadoc-add-artifacts [org.lwjgl.lwjgl lwjgl "2.8.2"]
                         [com.nullprogram native-guide "0.2"]
                         [org.apache.commons commons-math3 "3.0"])

Browser configuration:

To view documentation, the browser is launched with `browse-url'.
This may require setting `browse-url-browser-function' in order to
select the proper browser. For example,

  (setq browse-url-browser-function 'browse-url-firefox)
