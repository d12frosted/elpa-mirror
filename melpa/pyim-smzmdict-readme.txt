# pyim-smzmdict README #

## 简介 ##

There are some modified Zhengma schemas that meet users' strange demands. This project originated from one of the aforementioned schemas, which is based on pyim for implementation.

The first version only included the Sanma(triple) Zhengma. Now, the dict of the normal Zhengma has been added. The next step is to add a schema dict that distinguishes between simplified and traditional Chinese character roots.

User needs to install [Pyim](https://github.com/tumashu/pyim) before using this package!

这是适用于 pyim 的郑码词库文件，请先安装 pyim 并进行配置后使用。

本词库最初为三码郑码(至至)创建，故名smzmdict，现已加入普通郑码词库，
计划加入其他方案，以原本为Zheng码，此为邪，更名Strange scheMas of
ZhengMa.

三码郑码的原始数据由原作者至至本人提供，可用于非盈利性的交流、分享与使用。
普通郑码词库来自于[rime-zhengma](https://github.com/acevery/rime-zhengma)项目。

## 安装和使用 ##

1. 下载 pyim 及本词库到 Emacs 可读取的位置；
2. 在emacs配置文件中（比如: ~/.emacs）添加如下代码：

  ``` emacs-lisp
  (require 'pyim-smzmdict)
  ;; 启用普通郑码
  (setq pyim-default-scheme 'nmzm)
  (pyim-nmzmdict-enable)
  ;; 启用三码郑码
  (setq pyim-default-scheme 'smzm)
  (pyim-smzmdict-enable)
  ```

3. M-x 之后调用 toggle-input-method 函数，回车开始使用。
