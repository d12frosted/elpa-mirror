Minor mode allowing LESS stylesheet manipulation via `skewer-mode'.

Note that this is intended for use in place of `skewer-css-mode',
which does not work with lesscss.

Enable `skewer-less-mode' in a ".less" buffer. Save the buffer to
trigger an update, or hit "C-c C-k" just like in
`skewer-css-mode'.

Operates by invoking "less.refresh()" via skewer on demand, or
whenever the buffer is saved.

For this to work properly, the less javascript should be included
in the target web page, and less should be configured in
development mode, e.g.

   <script>
     var less = {env: "development"};
   </script>
   <link href="/stylesheets/application.less" rel="stylesheet/less">
   <script src="/path/to/less.js" type="text/javascript"></script>

I may consider providing an option to instead run "lessc" from
Emacs, then send the output via skewer-css. Let me know if you want this.
