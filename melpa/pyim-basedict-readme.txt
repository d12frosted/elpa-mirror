* pyim-basedict README                         :README:doc:

** 简介
pyim-basedict 是 pyim 输入法的默认词库，词库来源:

1. libpinyin 项目的内置词库
2. pyim 用户贡献的个人词库

注意：这个词库的词条量大概在 10 万左右，是一个 *比较小* 的词库，只能确保 pyim
可以正常工作，如果用户想让 pyim 更加顺手，需要添加其它附加词库，
一个比较好的选择是安装 pyim-greatdict（不过这个词库非常庞大，词条量
超过300万，不适合计算机 cpu 和内存不足的用户）。用户也可以使用其它方式
添加词库，具体请阅读 pyim README：

        https://github.com/tumashu/pyim

** 安装和使用
1. 配置melpa源，参考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim-basedict RET
3. 在emacs配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim-basedict)
   (pyim-basedict-enable)
   #+END_EXAMPLE
