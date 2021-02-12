Chinese-number is a package for converting number format between
Arabic and Chinese.

If you want to convert a Arabic number to chinese, you can:

    M-x chinese-number--convert-arabic-to-chinese

and input the Arabic number, or you may want to convert a number
from Chinese to Arabic, you can:

    M-x chinese-number--convert-chinese-to-arabic

If you want use this converting in your elisp code, then you can
call the following two function:

    chinese-number--convert-arabic-number-to-chinese

and

    chinese-number--convert-chinese-number-to-arabic

; Installation:

Chinese-number lives in a Git repository. To obtain it, do

    git clone https://github.com/zhcosin/chinese-number.git

Move chinese-number to ~/.emacs.d/chinese-number (or somewhere
else in the `load-path'). Then add the following lines to ~/.emacs:

    (add-to-list 'load-path "~/.emacs.d/chinese-number")
    (require 'chinese-number)

.
; 算法介绍

 阿拉伯数字转换为中文
    最基本也是最核心的概念就是数字(digit)与权(weight)，分别将数字与权转换为对应的中文，再作字符串
连接即可(这是最基本的转换操作)，但是零这个特殊的数字是需要特殊处理的，这个后面再描述。
    但这只适合10000以下的数，在中文中，数字还有更高级的权，上了10000就是1万，10000个1万就是1亿，
（在英文中这个更高级的权是千)，所以这个转换是有两个层次的，低层次的转换以10为基数，高层次的转换以
万为基数，但这两个层次的转换所用的算法是一致的，都是反复将阿拉伯数字除以基数，得到商和余数(称为切
片，slice)，然后对余数利用基本的转换操作进行转换，将其结果与对商的递归转换所得结果进行连接即可。
    零的规则如下:
    1. 如果某位数字为零，则不带权。
    1. 从个位数开始的连续任意个数的零，忽略之。
    1. 数字中间的连续任意个数的零，只转换为一个零，并且不带权.
    1. 对于一个切片，如果其数字小于基的十分之一，需要在前端补零(数字本来就是零除外)。
