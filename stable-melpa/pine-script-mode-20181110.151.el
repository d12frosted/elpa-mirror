;;; pine-script-mode.el --- Trading View Pine Script major mode
;;
;;; Copyright (C) 2018  Free Software Foundation, Inc.
;;
;;; Author: Eric Crosson <eric.s.crosson@utexas.edu>
;; Version: 1.0.0
;; Package-Version: 20181110.151
;; Package-Commit: f7892d373e30df0b2e8d2191e4ddb2064a92dd3c
;; Keywords: extensions
;; Package-Requires: ((emacs "24"))
;; URL: https://github.com/ericcrosson/pine-script-mode
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;
;;; Commentary:
;;
;; Provides a major-mode for editing Trading View Pine script files.
;;
;; Add the following to your .emacs to install:
;;
;; (require 'pine-script-mode)
;; (add-to-list 'auto-mode-alist '("\\.pine$" . pine-script-mode))
;;
;; or:
;;
;; (use-package pine-script-mode
;;   :ensure t
;;   :mode ("\\.pine\\'"))

;;; Code:

(defvar pine-script-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; C++ style comment “// …”
    (modify-syntax-entry ?\/ ". 12b" table)
    (modify-syntax-entry ?\n "> b" table)
    ;; Single-quotes count as strings
    (modify-syntax-entry ?' "\"" table)
    table)
  "Syntax table for `pine-script-mode'.")

(defvar pine-script-font-lock-keywords
  `(("$$(\\s *\\w+\\s *)" (0 font-lock-function-name-face t))
    ("$$\\[\\s *\\w+\\s *\\]" (0 font-lock-function-name-face t))
    (,(regexp-opt '("barmerge.gaps_on" "barmerge.lookahead_off" "barmerge.lookahead_on"
                    "barstate.isconfirmed" "barstate.isfirst" "barstate.ishistory"
                    "barstate.islast" "barstate.isnew" "barstate.isrealtime" "black"
                    "blue" "bool" "circles" "close" "columns" "cross" "currency.AUD"
                    "currency.CAD" "currency.CHF" "currency.EUR" "currency.GBP"
                    "currency.HKD" "currency.JPY" "currency.NOK" "currency.NONE"
                    "currency.NZD" "currency.RUB" "currency.SEK" "currency.SGD"
                    "currency.TRY" "currency.USD" "currency.ZAR" "dashed" "dayofmonth"
                    "dayofweek" "dotted" "float" "friday" "fuchsia" "gray" "green" "high"
                    "histogram" "hl2" "hlc3" "hour" "integer" "interval" "isdaily" "isdwm"
                    "isintraday" "ismonthly" "isweekly" "lime" "line" "linebr"
                    "location.abovebar" "location.absolute" "location.belowbar"
                    "location.bottom" "location.top" "low" "maroon" "minute" "monday"
                    "month" "n" "na" "navy" "ohlc4" "olive" "open" "orange" "period"
                    "purple" "red" "resolution" "saturday" "scale.left" "scale.none"
                    "scale.right" "second" "session" "session.extended" "session.regular"
                    "shape.arrowdown" "shape.arrowup" "shape.circle" "shape.cross"
                    "shape.diamond" "shape.flag" "shape.labeldown" "shape.labelup"
                    "shape.square" "shape.triangledown" "shape.triangleup" "shape.xcross"
                    "silver" "size.auto" "size.huge" "size.large" "size.normal"
                    "size.small" "size.tiny" "solid" "source" "stepline" "strategy.cash"
                    "strategy.closedtrades" "strategy.commission.cash_per_contract"
                    "strategy.commission.cash_per_order" "strategy.commission.percent"
                    "strategy.direction.all" "strategy.direction.long"
                    "strategy.direction.short" "strategy.equity" "strategy.eventrades"
                    "strategy.fixed" "strategy.grossloss" "strategy.grossprofit"
                    "strategy.initial_capital" "strategy.long" "strategy.losstrades"
                    "strategy.max_contracts_held_all" "strategy.max_contracts_held_long"
                    "strategy.max_contracts_held_short" "strategy.max_drawdown"
                    "strategy.netprofit" "strategy.oca.cancel" "strategy.oca.none"
                    "strategy.oca.reduce" "strategy.openprofit" "strategy.opentrades"
                    "strategy.percent_of_equity" "strategy.position_avg_price"
                    "strategy.position_entry_name" "strategy.position_size"
                    "strategy.short" "strategy.wintrades" "string" "sunday" "symbol"
                    "syminfo.mintick" "syminfo.pointvalue" "syminfo.prefix" "syminfo.root"
                    "syminfo.session" "syminfo.timezone" "teal" "thursday" "ticker"
                    "tickerid" "time" "timenow" "tr" "tuesday" "volume" "vwap" "wednesday"
                    "weekofyear" "white" "year" "yellow") `words)
     (0 font-lock-function-name-face))
    (,(regexp-opt '("abs" "acos" "alertcondition" "alma" "asin" "atan" "atr" "avg"
                    "barcolor" "barssince" "bgcolor" "cci" "ceil" "change" "cog" "color"
                    "correlation" "cos" "cross" "crossover" "crossunder" "cum"
                    "dayofmonth" "dayofweek" "dev" "ema" "exp" "falling" "fill" "fixnan"
                    "floor" "heikinashi" "highest" "highestbars" "hline" "hour" "iff"
                    "input" "kagi" "linebreak" "linreg" "log" "log10" "lowest"
                    "lowestbars" "macd" "max" "min" "minute" "mom" "month" "na" "nz"
                    "offset" "percentile_linear_interpolation" "percentile_nearest_rank"
                    "percentrank" "pivothigh" "pivotlow" "plot" "plotarrow" "plotbar"
                    "plotcandle" "plotchar" "plotshape" "pointfigure" "pow" "renko"
                    "rising" "rma" "roc" "round" "rsi" "sar" "second" "security" "sign"
                    "sin" "sma" "sqrt" "stdev" "stoch" "strategy" "strategy.cancel"
                    "strategy.cancel_all" "strategy.close" "strategy.close_all"
                    "strategy.entry" "strategy.exit" "strategy.order"
                    "strategy.risk.allow_entry_in" "strategy.risk.max_cons_loss_days"
                    "strategy.risk.max_drawdown"
                    "strategy.risk.max_intraday_filled_orders"
                    "strategy.risk.max_intraday_loss" "strategy.risk.max_position_size"
                    "study" "sum" "swma" "tan" "tickerid" "time" "timestamp" "tostring"
                    "tr" "tsi" "valuewhen" "variance" "vwap" "vwma" "weekofyear" "wma"
                    "year") `words)
     (0 font-lock-keyword-face)))
  "Keyword highlighting specification for `pine-script-mode'.")

;;;###autoload
(define-derived-mode pine-script-mode prog-mode "Pine"
  "A major mode for editing Trading View Pine scripts."
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-start-skip) "//+ *")
  (set 'font-lock-defaults '(pine-script-font-lock-keywords)))



(provide 'pine-script-mode)
;;; pine-script-mode.el ends here
