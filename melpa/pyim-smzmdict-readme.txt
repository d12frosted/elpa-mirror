* pyim-smzmdict README                         :README:doc:

** 简介
This is the Sanma(triple) Zhengma dict for based on pyim.
User needs to install [[Pyim][https://github.com/tumashu/pyim]] before using this package!

这是适用于 pyim 的三码郑码（至至）词库文件，请先安装 pyim 并进行配置后使用。

本词库中的原始数据由三码郑码的作者至至本人提供，可用于非盈利性的交流、分享与使用。

** 安装和使用
1. 下载 pyim 及本词库到 Emacs 可读取的位置；
2. 在emacs配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim-smzmdict)
   (pyim-smzmdict-enable)
   #+END_EXAMPLE
3. M-x 之后调用 toggle-input-method 函数，回车开始使用。
