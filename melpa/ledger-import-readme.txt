This file contains code to simplify importing new transactions into your
Ledger file.  Transactions are fetched using a fetcher (only Bank from the
woob project is supported for now) and the OFX file format.  Then, the OFX
buffers are converted into Ledger format through ledger-autosync.

To use ledger-import, you first have to install and configure boobank, from
the woob project:

- https://woob.tech/
- https://woob.tech/applications/bank

When you manage to visualize your bank accounts with boobank, you should
configure each in `ledger-import-accounts'.  Use `customize-variable' to do
that if you want to.  You can check that your configuration works with `M-x
ledger-import-fetch-boobank': after a few tens of seconds, you will get a
buffer with OFX data.  If boobank imports transactions that are too old, you
can configure `ledger-import-boobank-import-from-date'.

To convert an OFX file into Ledger format, ledger-import uses ledger-autosync
that you have to install as well:

- https://github.com/egh/ledger-autosync

This doesn't require additional configuration.  To test that ledger-autosync
works fine, go back to the buffer containing OFX data (or create a new one),
and type `M-x ledger-import-convert-ofx-to-ledger'.  After a few seconds, you
should get your transactions in Ledger format.  If you instead get a message
saying that the OFX data did not provide any FID, then you can provide a
random one in `ledger-import-accounts'.

To fetch transactions from all configured accounts and convert them to Ledger
format, type `M-x ledger-import-all-accounts'.  When this is finished, you
can open the result with `M-x ledger-import-pop-to-buffer'.

If you keep manually modifying the Ledger transactions after they have been
converted, you might prefer to let ledger-import do that for you.
ledger-import gives you 2 ways to rewrite OFX data: either through the
`ledger-import-fetched-hook' or through `ledger-import-ofx-rewrite-rules'.
