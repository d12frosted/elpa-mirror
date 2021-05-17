* pyim-basedict README                         :README:doc:

** 简介
pyim-basedict 是 pyim 输入法的默认词库，词库数据来源为 libpinyin 项目。

 https://github.com/libpinyin/libpinyin/releases (Data files we need is in release tarball)

注意：这个词库的词条量大概在 10 万左右，是一个 *比较小* 的词库，只能确保 pyim
可以正常工作，如果用户想让 pyim 更加顺手，需要添加其它附加词库，具体添加词库的
方式可以参考 pyim 的 README.

** 安装和使用
1. M-x package-install RET pyim-basedict RET
2. 在 Emacs 配置文件中（比如: "~/.emacs"）添加如下代码：
   #+BEGIN_EXAMPLE
   (pyim-basedict-enable)
   #+END_EXAMPLE
