
Watch videos of BiliBili in org mode.

https://bilibili.com is a popular Chinese video website.

在 Emacs 中看 B 站。结合 org + mpvi 食用的一系列辅助方法。

使用步骤:

 1. 安装 `mpvi', (use-package bilibili :ensure t)
 2. 扫码登录: M-x bilibili-login (某些功能需要登录状态)
 3. 在 org buffer 中调用 `bilibili-insert-xxx' 插入相关视频
 4. 点击链接进行播放
