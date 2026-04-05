org-invox provides a complete invoicing workflow for software
contractors and freelancers using Org mode.

Features:
- Contract-based invoice management (one contract per client)
- Auto-incrementing invoice numbers with configurable format
- Configurable tax rates (HST, GST, VAT, etc.) per contract
- Configurable payment terms per contract
- PDF export via LaTeX with a professional template
- Plain Org records for bookkeeping
- Master index file per contract with links to all invoices

Quick Start:

  1. Configure your business details:
     (setq org-invox-from-name "Your Name"
           org-invox-from-company "Your Company"
           org-invox-from-address "Your Address"
           org-invox-from-email "you@example.com")

  2. Create a new contract:
     M-x org-invox-new-contract

  3. Create an invoice:
     M-x org-invox-create

  4. Export to PDF:
     M-x org-invox-export-pdf

  5. Mark as paid:
     M-x org-invox-mark-paid
