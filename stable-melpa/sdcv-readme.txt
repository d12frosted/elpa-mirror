
Interface for sdcv (StartDict console version).

Translate word by sdcv (console version of Stardict), and display
translation use popup tooltip or buffer.

Below are commands you can use:

`sdcv-search-pointer'
Search around word and display with buffer.
`sdcv-search-pointer+'
Search around word and display with `popup tooltip'.
`sdcv-search-input'
Search input word and display with buffer.
`sdcv-search-input+'
Search input word and display with `popup tooltip'.

Tips:

If current mark is active, sdcv commands will translate
region string, otherwise translate word around point.


; Installation:

To use this extension, you have to install Stardict and sdcv
If you use Debian, it's simply, just:

     sudo aptitude install stardict sdcv -y

And the following to your ~/.emacs startup file.

(require 'sdcv)

And then you need set two options.

 sdcv-dictionary-simple-list         (a simple dictionary list for popup tooltip display)
 sdcv-dictionary-complete-list       (a complete dictionary list for buffer display)

Example, setup like this:

(setq sdcv-dictionary-simple-list        ;; a simple dictionary list
      '(
        "懒虫简明英汉词典"
        "懒虫简明汉英词典"
        "KDic11万英汉词典"
        ))
(setq sdcv-dictionary-complete-list      ;; a complete dictionary list
      '("KDic11万英汉词典"
        "懒虫简明英汉词典"
        "朗道英汉字典5.0"
        "XDICT英汉辞典"
        "朗道汉英字典5.0"
        "XDICT汉英辞典"
        "懒虫简明汉英词典"
        "牛津英汉双解美化版"
        "stardict1.3英汉辞典"
        "英汉汉英专业词典"
        "CDICT5英汉辞典"
        "Jargon"
        "FOLDOC"
        "WordNet"
        ))
