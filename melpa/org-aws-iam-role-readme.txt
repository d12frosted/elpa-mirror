Provides an interactive interface for browsing and modifying AWS IAM
roles directly within Emacs. The package renders all role data in a
detailed Org mode buffer and uses a custom Org Babel language,
`aws-iam`, to apply policy changes via the AWS CLI.

Key Features:
- Interactive browsing and selection of IAM roles.
- Full display of all policy types: Trust Policy, Permissions Boundary,
  AWS-Managed, Customer-Managed, and Inline policies.
- Direct modification via Org Babel. Supports "Upsert" logic: automatically
  creates policies if they don't exist, or updates them if they do.
- Smart Version Management: Automatically offers to delete the oldest
  policy version if the AWS version limit is reached during an update.
- Advanced Header Arguments: Support for `:tags`, `:path`, and sequential
  `:detach` + `:delete` operations.
- Built-in IAM Policy Simulator to test a role's permissions against
  specific AWS actions and resources.
- View a combined JSON policy of all permission policies for easy export.
- Asynchronous fetching of initial role and policy data for a fast UI.
- Safe by default: the role viewer buffer opens in read-only mode.
- Ability to easily switch between different AWS profiles.

Keybindings:

In the IAM Role Viewer Buffer:
- C-c C-e: Toggle read-only mode to enable/disable editing.
- C-c C-s: Simulate the role's policies against specific actions.
- C-c C-j: View a combined JSON of all permission policies.
- C-c C-a: Get service last accessed details for the role.
- C-c C-m: Find the last modified date for the role or its policies.
- C-c C-c: Inside a source block, apply changes to AWS.
- C-c (:   Hide all property drawers.
- C-c ):   Reveal all property drawers.

In the Simulation Results Buffer:
- C-c C-c: Rerun the simulation for the last used role.
- C-c C-j: View the raw JSON output from the simulation API call.
