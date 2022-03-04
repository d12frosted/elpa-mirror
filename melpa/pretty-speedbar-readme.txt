Pretty Speedbar defaults to Font Awesome 6 Free Solid, which must be
installed from the otf available from Font Awesome's GitHub repository --
https://github.com/FortAwesome/Font-Awesome.
To use svg icons, you must first run pretty-speedbar-generate.  This
creates static icon files in the pretty-speedbar-icons-dir.  Alternatively,
icons may be created by hand in the pretty-speedbar-icons-dir.
To customize the folder colors, set a hex color for
pretty-speedbar-icon-folder-fill and pretty-speedbar-icon-folder-stroke.
To customize the non-folder icons, set a hex color for
pretty-speedbar-icon-fill and pretty-speedbar-icon-stroke.
To customize checks and locks, set a hex color for
pretty-speedbar-about-fill and pretty-speedbar-about-stroke.
To customize the plus and minus signs used on both the folder and
non-folder icons, set pretty-speedbar-signs-fill.
To alter the icon size, set pretty--speedbar-icon-size.   This sets the
folder and non-folder icon height in pixels.  Icon width and the about
icons (check and lock icons) are calculated based on this value.
Changing the icon font requires changing the unicode setting for each icon.
Please see the 'Icon Reference' section in the readme file for complete
table of these variables matched to their unicodes and the output image.
