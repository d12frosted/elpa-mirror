;;; gvpr-mode.el --- A major mode offering basic syntax coloring for gvpr scripts.

;; Copyright (C) 2013 Rod Waldhoff
;;
;; Author: Rod Waldhoff <r.waldhoff@gmail.com>
;; Maintainer: Rod Waldhoff <r.waldhoff@gmail.com>
;; Created: 7 Dec 2013
;; Version: 0.1.0
;; Package-Version: 20201007.2054
;; Package-Commit: a729fa4623a6d846ab860778842b38f685246c95
;; Keywords: graphviz, gv, dot, gvpr, graph
;; URL: https://raw.github.com/rodw/gvpr-lib/master/extra/gvpr-mode.el

;; This file is NOT part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA. or visit <http://www.gnu.org/licenses/>.

;;; Commentary:
;; `gvpr` is the "graph pattern recognizer", a graph processing and
;; transformation tool that is part of the Graphviz open-source graph
;; visualization suite (<http://www.graphviz.org/>).
;;
;; `gvpr` is an `awk`-like processor for graphs defined in Graphviz's
;; DOT language.  `gvpr` can apply a user-specified *action* to every
;; graph, node, or edge that meets the conditions of the corresponding
;; *predicate*.
;;
;; `gvpr` defines a C-like language for this.
;;
;; This file defines a very basic emacs mode for syntax coloring
;; of `gvpr` scripts.
;;
;; To use it simply load` or `require` this file.
;; You can then enable this mode by executing `M-x gvpr-mode`.
;; The `.gvpr` file extension is associated with this mode
;; by default.
;;

;;; Code:

(require 'generic-x)

;;;###autoload
(define-generic-mode
  'gvpr-mode                      ;; name of the mode
  '("//")                         ;; comments
  '(                              ;; keywords
    "void" "int" "char" "float" "long" "unsigned" "double" "string" "node_t" "edge_t" "graph_t" "obj_t"
    "if" "else" "for" "forr" "while" "switch" "case" "break" "continue" "return"
    )
  '(                              ;; other syntax-colored terms
    ;; clauses
    ("\\<BEGIN\\>"   . 'font-lock-preprocessor-face)
    ("\\<BEGIN_G\\>" . 'font-lock-preprocessor-face)
    ("\\<N\\>"       . 'font-lock-preprocessor-face)
    ("\\<E\\>"       . 'font-lock-preprocessor-face)
    ("\\<END_G\\>"   . 'font-lock-preprocessor-face)
    ("\\<END\\>"     . 'font-lock-preprocessor-face)

    ;; operators
    ("--" . 'font-lock-constant-face)
    ("->" . 'font-lock-constant-face)
    ("==" . 'font-lock-constant-face)
    ("!=" . 'font-lock-constant-face)
    ("+"  . 'font-lock-constant-face)
    ("-"  . 'font-lock-constant-face)
    ("*"  . 'font-lock-constant-face)
    ("/"  . 'font-lock-constant-face)
    ("="  . 'font-lock-constant-face)
    ("<"  . 'font-lock-constant-face)
    (">"  . 'font-lock-constant-face)
    ("<=" . 'font-lock-constant-face)
    (">=" . 'font-lock-constant-face)
    ("#"  . 'font-lock-constant-face)
    ("\\<in\\>" . 'font-lock-constant-face)

    ;; common attributes
    ("\\<head\\>"      . 'font-lock-builtin-face)
    ("\\<tail\\>"      . 'font-lock-builtin-face)
    ("\\<name\\>"      . 'font-lock-builtin-face)
    ("\\<indegree\\>"  . 'font-lock-builtin-face)
    ("\\<outdegree\\>" . 'font-lock-builtin-face)
    ("\\<degree\\>"    . 'font-lock-builtin-face)
    ("\\<root\\>"      . 'font-lock-builtin-face)
    ("\\<parent\\>"    . 'font-lock-builtin-face)
    ("\\<n_edges\\>"   . 'font-lock-builtin-face)
    ("\\<n_nodes\\>"   . 'font-lock-builtin-face)
    ("\\<directed\\>"  . 'font-lock-builtin-face)
    ("\\<strict\\>"    . 'font-lock-builtin-face)

    ;; built-in functions
    ("\\<graph\\>"       . 'font-lock-builtin-face)
    ("\\<sugb\\>"        . 'font-lock-builtin-face)
    ("\\<isSubg\\>"      . 'font-lock-builtin-face)
    ("\\<fstsubg\\>"     . 'font-lock-builtin-face)
    ("\\<nxtsugb\\>"     . 'font-lock-builtin-face)
    ("\\<isDirect\\>"    . 'font-lock-builtin-face)
    ("\\<isStrict\\>"    . 'font-lock-builtin-face)
    ("\\<nNodes\\>"      . 'font-lock-builtin-face)
    ("\\<nEdges\\>"      . 'font-lock-builtin-face)
    ("\\<node\\>"        . 'font-lock-builtin-face)
    ("\\<subnode\\>"     . 'font-lock-builtin-face)
    ("\\<fstnode\\>"     . 'font-lock-builtin-face)
    ("\\<nxtnode\\>"     . 'font-lock-builtin-face)
    ("\\<isNode\\>"      . 'font-lock-builtin-face)
    ("\\<isSubnode\\>"   . 'font-lock-builtin-face)
    ("\\<indegreeOf\\>"  . 'font-lock-builtin-face)
    ("\\<outdegreeOf\\>" . 'font-lock-builtin-face)
    ("\\<degreeOf\\>"    . 'font-lock-builtin-face)
    ("\\<edge\\>"        . 'font-lock-builtin-face)
    ("\\<edge_sg\\>"     . 'font-lock-builtin-face)
    ("\\<subedge\\>"     . 'font-lock-builtin-face)
    ("\\<isEdge\\>"      . 'font-lock-builtin-face)
    ("\\<isSubedge\\>"   . 'font-lock-builtin-face)
    ("\\<fstout\\>"      . 'font-lock-builtin-face)
    ("\\<fstout_sg\\>"   . 'font-lock-builtin-face)
    ("\\<nxtout\\>"      . 'font-lock-builtin-face)
    ("\\<nxtout_sg\\>"   . 'font-lock-builtin-face)
    ("\\<fstin\\>"       . 'font-lock-builtin-face)
    ("\\<fstin_sg\\>"    . 'font-lock-builtin-face)
    ("\\<nxtin\\>"       . 'font-lock-builtin-face)
    ("\\<nxtin_sg\\>"    . 'font-lock-builtin-face)
    ("\\<fstedge\\>"     . 'font-lock-builtin-face)
    ("\\<nxtedge\\>"     . 'font-lock-builtin-face)
    ("\\<opp\\>"         . 'font-lock-builtin-face)
    ("\\<write\\>"       . 'font-lock-builtin-face)
    ("\\<writeG\\>"      . 'font-lock-builtin-face)
    ("\\<fwriteG\\>"     . 'font-lock-builtin-face)
    ("\\<readG\\>"       . 'font-lock-builtin-face)
    ("\\<freadG\\>"      . 'font-lock-builtin-face)
    ("\\<delete\\>"      . 'font-lock-builtin-face)
    ("\\<isIn\\>"        . 'font-lock-builtin-face)
    ("\\<cloneG\\>"      . 'font-lock-builtin-face)
    ("\\<clone\\>"       . 'font-lock-builtin-face)
    ("\\<copy\\>"        . 'font-lock-builtin-face)
    ("\\<copyA\\>"       . 'font-lock-builtin-face)
    ("\\<induce\\>"      . 'font-lock-builtin-face)
    ("\\<hasAttr\\>"     . 'font-lock-builtin-face)
    ("\\<isAttr\\>"      . 'font-lock-builtin-face)
    ("\\<aget\\>"        . 'font-lock-builtin-face)
    ("\\<aset\\>"        . 'font-lock-builtin-face)
    ("\\<getDflt\\>"     . 'font-lock-builtin-face)
    ("\\<setDflt\\>"     . 'font-lock-builtin-face)
    ("\\<fstAttr\\>"     . 'font-lock-builtin-face)
    ("\\<nxtAttr\\>"     . 'font-lock-builtin-face)
    ("\\<copmOf\\>"      . 'font-lock-builtin-face)
    ("\\<kindOf\\>"      . 'font-lock-builtin-face)
    ("\\<lock\\>"        . 'font-lock-builtin-face)
    ("\\<sprintf\\>"     . 'font-lock-builtin-face)
    ("\\<gsub\\>"        . 'font-lock-builtin-face)
    ("\\<sub\\>"         . 'font-lock-builtin-face)
    ("\\<substr\\>"      . 'font-lock-builtin-face)
    ("\\<strcmp\\>"      . 'font-lock-builtin-face)
    ("\\<length\\>"      . 'font-lock-builtin-face)
    ("\\<index\\>"       . 'font-lock-builtin-face)
    ("\\<rindex\\>"      . 'font-lock-builtin-face)
    ("\\<match\\>"       . 'font-lock-builtin-face)
    ("\\<toupper\\>"     . 'font-lock-builtin-face)
    ("\\<tolower\\>"     . 'font-lock-builtin-face)
    ("\\<canon\\>"       . 'font-lock-builtin-face)
    ("\\<html\\>"        . 'font-lock-builtin-face)
    ("\\<ishtml\\>"      . 'font-lock-builtin-face)
    ("\\<xOf\\>"         . 'font-lock-builtin-face)
    ("\\<yOf\\>"         . 'font-lock-builtin-face)
    ("\\<llOf\\>"        . 'font-lock-builtin-face)
    ("\\<urOf\\>"        . 'font-lock-builtin-face)
    ("\\<sscanf\\>"      . 'font-lock-builtin-face)
    ("\\<split\\>"       . 'font-lock-builtin-face)
    ("\\<tokens\\>"      . 'font-lock-builtin-face)
    ("\\<print\\>"       . 'font-lock-builtin-face)
    ("\\<printf\\>"      . 'font-lock-builtin-face)
    ("\\<scanf\\>"       . 'font-lock-builtin-face)
    ("\\<openF\\>"       . 'font-lock-builtin-face)
    ("\\<closeF\\>"      . 'font-lock-builtin-face)
    ("\\<readL\\>"       . 'font-lock-builtin-face)
    ("\\<exp\\>"         . 'font-lock-builtin-face)
    ("\\<log\\>"         . 'font-lock-builtin-face)
    ("\\<sqrt\\>"        . 'font-lock-builtin-face)
    ("\\<pow\\>"         . 'font-lock-builtin-face)
    ("\\<cos\\>"         . 'font-lock-builtin-face)
    ("\\<sin\\>"         . 'font-lock-builtin-face)
    ("\\<atan2\\>"       . 'font-lock-builtin-face)
    ("\\<MIN\\>"         . 'font-lock-builtin-face)
    ("\\<MAX\\>"         . 'font-lock-builtin-face)
    ("\\<unset\\>"       . 'font-lock-builtin-face)
    ("\\<exit\\>"        . 'font-lock-builtin-face)
    ("\\<system\\>"      . 'font-lock-builtin-face)
    ("\\<rand\\>"        . 'font-lock-builtin-face)
    ("\\<srand\\>"       . 'font-lock-builtin-face)
    ("\\<colorx\\>"      . 'font-lock-builtin-face)

    ;; built-in variables
    ("\\<$\\>"        . 'font-lock-builtin-face)
    ("\\<$F\\>"       . 'font-lock-builtin-face)
    ("\\<$G\\>"       . 'font-lock-builtin-face)
    ("\\<$NG\\>"      . 'font-lock-builtin-face)
    ("\\<$O\\>"       . 'font-lock-builtin-face)
    ("\\<$T\\>"       . 'font-lock-builtin-face)
    ("\\<$trgname\\>" . 'font-lock-builtin-face)
    ("\\<$tvroot\\>"  . 'font-lock-builtin-face)
    ("\\<$tvnext\\>"  . 'font-lock-builtin-face)
    ("\\<$tvnext\\>"  . 'font-lock-builtin-face)
    ("\\<$tvedge\\>"  . 'font-lock-builtin-face)
    ("\\<$tvtype\\>"  . 'font-lock-builtin-face)
    ("\\<ARGC\\>"     . 'font-lock-builtin-face)
    ("\\<ARGV\\>"     . 'font-lock-builtin-face)

    ;; built-in constants
    ("\\<NULL\\>"          . 'font-lock-builtin-face)
    ("\\<TV_flat\\>"       . 'font-lock-builtin-face)
    ("\\<TV_ne\\>"         . 'font-lock-builtin-face)
    ("\\<TV_en\\>"         . 'font-lock-builtin-face)
    ("\\<TV_dfs\\>"        . 'font-lock-builtin-face)
    ("\\<TV_postdfs\\>"    . 'font-lock-builtin-face)
    ("\\<TV_prepostdfs\\>" . 'font-lock-builtin-face)
    ("\\<TV_fwd\\>"        . 'font-lock-builtin-face)
    ("\\<TV_postfwd\\>"    . 'font-lock-builtin-face)
    ("\\<TV_prepostfwd\\>" . 'font-lock-builtin-face)
    ("\\<TV_rev\\>"        . 'font-lock-builtin-face)
    ("\\<TV_postrev\\>"    . 'font-lock-builtin-face)
    ("\\<TV_prepostrev\\>" . 'font-lock-builtin-face)
    ("\\<TV_bfs\\>"        . 'font-lock-builtin-face)

    )
  '("\\.gvpr$")                   ;; files for which to activate this mode
  nil                             ;; other functions
  "A basic mode for gvpr scripts" ;; doc string
  )

(provide 'gvpr-mode)
;;; gvpr-mode.el ends here
