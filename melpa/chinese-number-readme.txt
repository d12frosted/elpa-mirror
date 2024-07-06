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
