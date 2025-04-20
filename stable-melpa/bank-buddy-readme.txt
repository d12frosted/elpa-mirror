
This package provides financial analysis and reporting capabilities
for bank statement data, it includes:

- Transaction summaries and overviews
- Spending category analysis
- Top merchant identification
- Monthly spending patterns
- Recurring subscription detection

The package reads CSV bank statement data *asynchronously*, categorizes
transactions, and generates detailed reports in Org-mode format.

; Quick Start

 (use-package bank-buddy)
 (with-eval-after-load 'bank-buddy
   (add-hook 'org-mode-hook 'bank-buddy-cat-maybe-enable))

 1. Export your bank statement as a CSV file
 2. Edit CSV using csv-mode for all lines to DATE,DESCRIPTION,AMOUNT
 3. Open CSV file
 4. Run: =M-x bank-buddy-generate=
 5. Open the generated report
