This package allows you to query Wolfram Alpha from within Emacs.

It is required to get a WolframAlpha Developer AppID in order to use this
package.
 - Create an account at https://developer.wolframalpha.com/portal/signin.html.
 - Once you sign in with the Wolfram ID at
   https://developer.wolframalpha.com/portal/myapps/, click on "Get an AppID"
   to get your Wolfram API or AppID.
 - Follow the steps where you put in your app name and description, and
   you will end up with an AppID that looks like "ABCDEF-GHIJKLMNOP",
   where few of those characters could be numbers too.
 - Set the custom variable `wolfram-alpha-app-id' to that AppID.

To make a query, run `M-x wolfram-alpha' then type your query. It will show
the results in a buffer called `*WolframAlpha*'.
