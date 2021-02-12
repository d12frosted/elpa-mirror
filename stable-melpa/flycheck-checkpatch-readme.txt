An easy way to write Linux kernel or QEMU code
according to the style guidelines.

Enable this checker by adding code like the following
to your startup files:

    (eval-after-load 'flycheck
      '(flycheck-checkpatch-setup))
