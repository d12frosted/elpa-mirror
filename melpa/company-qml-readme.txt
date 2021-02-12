                             _____________

                              COMPANY-QML

                              Junpeng Qiu
                             _____________


Table of Contents
_________________

1 Screenshots
2 Usage
3 Config
4 *TODO*


A company-mode backend for QML files.


1 Screenshots
=============

  [https://github.com/cute-jumper/company-qml/tree/master/screenshots/object.png]
  [https://github.com/cute-jumper/company-qml/tree/master/screenshots/field.png]
  [https://github.com/cute-jumper/company-qml/tree/master/screenshots/global.png]


2 Usage
=======

  *Since 2016-02-12*, this package should work out of box if you only
  want completions for standard QML objects.

  To use it:
  ,----
  | (add-to-list 'company-backends 'company-qml)
  `----
  Done!

  *For users of old versions*: Please note that
  `qmltypes-parser-file-list' is /obsolete/ now. It has been renamed to
  `company-qml-default-qmltypes-files'. What's more, if you set this
  variable, it will *override* the default completions that comes with
  this package. For most of the users, it will be sufficient to delete
  the settings of `qmltypes-parser-file-list'(it's not needed any more!)
  and use the default completions provided by this package.


3 Config
========

  If you want this package to provide completions for third-party
  libraries, follow the steps below:

  1. First, you need plugins.qmltypes files so that they can be parsed
     to get the completion information for QML objects. You can try to
     find these plugins.qmltypes files under the third-party library's
     directory. If you can't find them, refer to [this page] for the
     information of generating qmltypes files.

  2. Set the variable `company-qml-extra-qmltypes-files' to a list of
     plugins.qmltypes files. For example,
     ,----
     | (setq company-qml-extra-qmltypes-files '("/path/to/lib1/module1/plugins.qmltypes"
     |                                          "/path/to/lib1/module2/plugins.qmltypes"
     |                                          "/path/to/lib2/module1/plugins.qmltypes"
     |                                          "/path/to/lib2/module2/plugins.qmltypes"))
     `----

  You can also override the default completions provided by this
  packages by setting the variable `company-qml-default-qmltypes-files'.
  Find out the locations of plugins.qmltypes files for standard QML
  objects and then set the variable `company-qml-default-qmltypes-files'
  in the same way as `company-qml-extra-qmltypes-files'.


  [this page]
  http://doc.qt.io/qtcreator/creator-qml-modules-with-plugins.html#generating-qmltypes-files


4 *TODO*
========

  - Support "as" in import statement.
  - Implement a better QML parser. So far we only support very simple
    completions.
  - Javascript completions.

    I'm not proficient in either QML or the development of company-mode
    extensions. Any improvements or suggestions are welcome!
