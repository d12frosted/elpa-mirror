;;; pine-script-mode.el --- Trading View Pine Script major mode
;;
;;; Copyright (C) 2018  Free Software Foundation, Inc.
;;
;;; Author: Eric Crosson <eric.s.crosson@utexas.edu>
;; Version: 1.0.3
;; Package-Version: 20210629.1257
;; Package-Commit: 1959d2d5e09fde5244f9f945fec043cdffd5d37e
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
;; Pine script mode automatically loads for ".pine" files 
;;
;; (require 'pine-script-mode)
;; 
;; or:
;;
;; (use-package pine-script-mode
;;   :ensure t)
;; 
;; or:
;; 
;; (straight-use-package
;;   '(pine-script-mode :type git :host github :repo "EricCrosson/pine-script-mode"))
;; 

;;; Code:

(defvar pine-script-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; C++ style comment “// …”
    (modify-syntax-entry ?\/ ". 12b" table)
    (modify-syntax-entry ?\n "> b" table)
    ;; Single and double quotes count as strings
    (modify-syntax-entry ?' "\"\'" table)
    (modify-syntax-entry ?\" "\"\"" table) 
    ;; Fix various operators and punctuation.
    (modify-syntax-entry ?&  "." table)
    (modify-syntax-entry ?|  "." table)
    ;; Parenthesis, braces and brackets
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    table)
  "Syntax table for `pine-script-mode'.")

(defvar pine-script-font-lock-keywords
  `(("$$(\\s *\\w+\\s *)" (0 font-lock-function-name-face t))
    ("$$\\[\\s *\\w+\\s *\\]" (0 font-lock-function-name-face t))
    (,(regexp-opt '("and" "else" "false" "for" "if" "not" "or" "true" "var" "varip") `words)
       (0 font-lock-keyword-face))
    (,(concat (regexp-opt '("float" "int" "bool" "string" "color") `words) "[^\.\\|\\(\\|=]")
        (0 font-lock-type-face))
    (,(regexp-opt '("accdist" "adjustment.dividends" "adjustment.none"
		    "adjustment.splits" "alert.freq_all" "alert.freq_once_per_bar"
		    "alert.freq_once_per_bar_close" "bar_index" "barmerge.gaps_off"
		    "barmerge.gaps_on" "barmerge.lookahead_off" "barmerge.lookahead_on"
		    "barstate.isconfirmed" "barstate.isfirst" "barstate.ishistory"
		    "barstate.islast" "barstate.isnew" "barstate.isrealtime" "close"
		    "color.aqua" "color.black" "color.blue" "color.fuchsia" "color.gray"
		    "color.green" "color.lime" "color.maroon" "color.navy" "color.olive"
		    "color.orange" "color.purple" "color.red" "color.silver"
		    "color.teal" "color.white" "color.yellow" "currency.AUD"
		    "currency.CAD" "currency.CHF" "currency.EUR" "currency.GBP"
		    "currency.HKD" "currency.JPY" "currency.NOK" "currency.NONE"
		    "currency.NZD" "currency.RUB" "currency.SEK" "currency.SGD"
		    "currency.TRY" "currency.USD" "currency.ZAR" "dayofmonth"
		    "dayofweek" "dayofweek.friday" "dayofweek.monday"
		    "dayofweek.saturday" "dayofweek.sunday" "dayofweek.thursday"
		    "dayofweek.tuesday" "dayofweek.wednesday" "display.all"
		    "display.none" "dividends.gross" "dividends.net" "earnings.actual"
		    "earnings.estimate" "extend.both" "extend.left" "extend.none"
		    "extend.right" "format.inherit" "format.percent" "format.price"
		    "format.volume" "high" "hl2" "hlc3" "hline.style_dashed"
		    "hline.style_dotted" "hline.style_solid" "hour" "iii" "input.bool"
		    "input.color" "input.float" "input.integer" "input.resolution"
		    "input.session" "input.source" "input.string" "input.symbol"
		    "input.time" "label.style_arrowdown" "label.style_arrowup"
		    "label.style_circle" "label.style_cross" "label.style_diamond"
		    "label.style_flag" "label.style_label_center"
		    "label.style_label_down" "label.style_label_left"
		    "label.style_label_lower_left" "label.style_label_lower_right"
		    "label.style_label_right" "label.style_label_up"
		    "label.style_label_upper_left" "label.style_label_upper_right"
		    "label.style_none" "label.style_square" "label.style_triangledown"
		    "label.style_triangleup" "label.style_xcross"
		    "line.style_arrow_both" "line.style_arrow_left"
		    "line.style_arrow_right" "line.style_dashed" "line.style_dotted"
		    "line.style_solid" "location.abovebar" "location.absolute"
		    "location.belowbar" "location.bottom" "location.top" "low" "math.e"
		    "math.phi" "math.pi" "math.rphi" "minute" "month" "na" "nvi" "obv"
		    "ohlc4" "open" "order.ascending" "order.descending"
		    "plot.style_area" "plot.style_areabr" "plot.style_circles"
		    "plot.style_columns" "plot.style_cross" "plot.style_histogram"
		    "plot.style_line" "plot.style_linebr" "plot.style_stepline"
		    "position.bottom_center" "position.bottom_left"
		    "position.bottom_right" "position.middle_center"
		    "position.middle_left" "position.middle_right" "position.top_center"
		    "position.top_left" "position.top_right" "pvi" "pvt" "scale.left"
		    "scale.none" "scale.right" "second" "session.extended"
		    "session.ismarket" "session.ispostmarket" "session.ispremarket"
		    "session.regular" "shape.arrowdown" "shape.arrowup" "shape.circle"
		    "shape.cross" "shape.diamond" "shape.flag" "shape.labeldown"
		    "shape.labelup" "shape.square" "shape.triangledown"
		    "shape.triangleup" "shape.xcross" "size.auto" "size.huge"
		    "size.large" "size.normal" "size.small" "size.tiny"
		    "splits.denominator" "splits.numerator" "strategy.cash"
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
		    "strategy.short" "strategy.wintrades" "syminfo.basecurrency"
		    "syminfo.currency" "syminfo.description" "syminfo.mintick"
		    "syminfo.pointvalue" "syminfo.prefix" "syminfo.root"
		    "syminfo.session" "syminfo.ticker" "syminfo.tickerid"
		    "syminfo.timezone" "syminfo.type" "text.align_center"
		    "text.align_left" "text.align_right" "time" "time_close"
		    "time_tradingday" "timeframe.isdaily" "timeframe.isdwm"
		    "timeframe.isintraday" "timeframe.isminutes" "timeframe.ismonthly"
		    "timeframe.isseconds" "timeframe.isweekly" "timeframe.multiplier"
		    "timeframe.period" "timenow" "tr" "volume" "vwap" "wad" "weekofyear"
		    "wvad" "xloc.bar_index" "xloc.bar_time" "year" "yloc.abovebar"
		    "yloc.belowbar" "yloc.price") `words)
     (0 font-lock-function-name-face))
    (,(regexp-opt '("abs" "acos" "alert" "alertcondition" "alma" "array.avg"
		    "array.clear" "array.concat" "array.copy" "array.covariance"
		    "array.fill" "array.from" "array.get" "array.includes"
		    "array.indexof" "array.insert" "array.join" "array.lastindexof"
		    "array.max" "array.median" "array.min" "array.mode" "array.new_bool"
		    "array.new_color" "array.new_float" "array.new_int"
		    "array.new_label" "array.new_line" "array.new_string" "array.pop"
		    "array.push" "array.range" "array.remove" "array.reverse"
		    "array.set" "array.shift" "array.size" "array.slice" "array.sort"
		    "array.standardize" "array.stdev" "array.sum" "array.unshift"
		    "array.variance" "asin" "atan" "atr" "avg" "barcolor" "barssince"
		    "bb" "bbw" "bgcolor" "bool" "cci" "ceil" "change" "cmo" "cog"
		    "color" "color.b" "color.from_gradient" "color.g" "color.new"
		    "color.r" "color.rgb" "color.t" "correlation" "cos" "cross"
		    "crossover" "crossunder" "cum" "dayofmonth" "dayofweek" "dev"
		    "dividends" "dmi" "earnings" "ema" "exp" "falling" "fill"
		    "financial" "fixnan" "float" "floor" "heikinashi" "highest"
		    "highestbars" "hline" "hma" "hour" "iff" "input" "int" "kagi" "kc"
		    "kcw" "label" "label.delete" "label.get_text" "label.get_x"
		    "label.get_y" "label.new" "label.set_color" "label.set_size"
		    "label.set_style" "label.set_text" "label.set_textalign"
		    "label.set_textcolor" "label.set_tooltip" "label.set_x"
		    "label.set_xloc" "label.set_xy" "label.set_y" "label.set_yloc"
		    "line" "line.delete" "line.get_price" "line.get_x1" "line.get_x2"
		    "line.get_y1" "line.get_y2" "line.new" "line.set_color"
		    "line.set_extend" "line.set_style" "line.set_width" "line.set_x1"
		    "line.set_x2" "line.set_xloc" "line.set_xy1" "line.set_xy2"
		    "line.set_y1" "line.set_y2" "linebreak" "linreg" "log" "log10"
		    "lowest" "lowestbars" "macd" "max" "max_bars_back" "median" "mfi"
		    "min" "minute" "mode" "mom" "month" "na" "nz" "offset"
		    "percentile_linear_interpolation" "percentile_nearest_rank"
		    "percentrank" "pivothigh" "pivotlow" "plot" "plotarrow" "plotbar"
		    "plotcandle" "plotchar" "plotshape" "pointfigure" "pow" "quandl"
		    "random" "range" "renko" "rising" "rma" "roc" "round" "rsi" "sar"
		    "second" "security" "sign" "sin" "sma" "splits" "sqrt" "stdev"
		    "stoch" "str.format" "str.length" "str.replace_all" "str.split"
		    "strategy" "strategy.cancel" "strategy.cancel_all" "strategy.close"
		    "strategy.close_all" "strategy.entry" "strategy.exit"
		    "strategy.order" "strategy.risk.allow_entry_in"
		    "strategy.risk.max_cons_loss_days" "strategy.risk.max_drawdown"
		    "strategy.risk.max_intraday_filled_orders"
		    "strategy.risk.max_intraday_loss" "strategy.risk.max_position_size"
		    "string" "study" "sum" "supertrend" "swma" "table" "table.cell"
		    "table.cell_set_bgcolor" "table.cell_set_height"
		    "table.cell_set_text" "table.cell_set_text_color"
		    "table.cell_set_text_halign" "table.cell_set_text_size"
		    "table.cell_set_text_valign" "table.cell_set_width" "table.clear"
		    "table.delete" "table.new" "table.set_bgcolor"
		    "table.set_border_color" "table.set_border_width"
		    "table.set_frame_color" "table.set_frame_width" "table.set_position"
		    "tan" "tickerid" "time" "time_close" "timestamp" "todegrees"
		    "tonumber" "toradians" "tostring" "tr" "tsi" "valuewhen" "variance"
		    "vwap" "vwma" "weekofyear" "wma" "wpr" "year") `words)
     (0 font-lock-keyword-face)))
  "Keyword highlighting specification for `pine-script-mode'.")

;;;###autoload
(define-derived-mode pine-script-mode prog-mode "Pine"
  "A major mode for editing Trading View Pine scripts."
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-start-skip) "//+ *")
  (set 'font-lock-defaults '(pine-script-font-lock-keywords)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pine\\'" . pine-script-mode))

(provide 'pine-script-mode)
;;; pine-script-mode.el ends here

