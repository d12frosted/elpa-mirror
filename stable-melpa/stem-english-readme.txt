* English word stemmer

This library stems an English word, based on the algorithm
described in the paper "An algorithm for suffix stripping
(M.F.Porter)".

Function `stem-english (str)' returns a list of possible stems in
order of string length.

This is a re-written version of `stem.el' originally written by
Tsuchiya Masatoshi, to be compatible with modern Emacs, removing
all compiler warnings by explicitly defining lexicographically
bounded variables.

[original Japanese document]

論文『An algorithm for suffix stripping (M.F.Porter)』に記述されて
いるアルゴリズムに基づいて、英単語の語尾を取り除くためのライブラリ。
利用及び再配布の際は、GNU 一般公用許諾書の適当なバージョンにしたがっ
て下さい。

一次配布元
 http://www-nagao.kuee.kyoto-u.ac.jp/member/tsuchiya/sdic/index.html
