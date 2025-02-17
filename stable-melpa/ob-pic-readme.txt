
Org-Babel support for evaluating pic source code.

This package allows a source block to use the =pic= language designator on a
source block:

 #+header: :file output.png
 #+begin_src pic
   down;
   box "Emacs"; arrow;box "OrgMode"; arrow
   box "begin_src" "pic"; arrow; box "ob-pic"; arrow;
   box "pic2plot"; arrow; box "output.png"
 #+end_src

This produces a PNG file containing the generated diagram in output.png in
the current directory.

For further usage information on this package, see https://github.com/ddoherty03/ob-pic

For information on pic see https://pikchr.org/home/uv/pic.pdf and
  on gpic at https://pikchr.org/home/uv/gpic.pdf

The program actually used to generate the output is pic2plot, which is part
of the GNU plotutils collection of programs.  Thus, you must have it
installed on your system in order for this to work.

On ubuntu, you can install with `apt install plotutils`; on arch linux, do
something like `pacman -Sy plotutils`.

This means that pic differs from most standard org-babel languages in that

1) there is no such thing as a "session" in pic

2) we are generally only going to return results of type "file"

3) we are adding the "file" and "cmdline" header arguments

4) there are no variables (at least for now)

5) one of the command line arguments is "-T <type>" where <type> is one of
   "X", "png", "pnm", "gif", "svg", "ai", "ps", "cgm", "fig", "pcl",
   "hpgl", "regis", "tek", and "meta".  By default, this implementation
   assumes an output type of "png".  If you use "X", it will pop up an X
   window with the graph displayed.
