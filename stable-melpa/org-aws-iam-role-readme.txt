Provides an interactive interface for browsing and modifying AWS IAM
roles directly within Emacs. The package renders all role data in a
detailed Org mode buffer and uses a custom Org Babel language,
`aws-iam`, to apply policy changes via the AWS CLI.

Key Features:
- Interactive browsing and selection of IAM roles.
- Full display of all policy types: Trust Policy, Permissions Boundary,
  AWS-Managed, Customer-Managed, and Inline policies.
- Direct modification of any policy through Org Babel source blocks. Use
  header arguments like `:create`, `:delete`, or `:detach` for full
  CRUD (Create, Read, Update, Delete) operations.
- Built-in IAM Policy Simulator to test a role's permissions against
  specific AWS actions and resources.
- View a combined JSON policy of all permission policies for easy export
  or analysis.
- Asynchronous fetching of initial role and policy data for a fast UI.
- Safe by default: the role viewer buffer opens in read-only mode.
- Ability to easily switch between different AWS profiles.
- Clear feedback on command success or failure in Babel results blocks.

Keybindings:

In the IAM Role Viewer Buffer:
- C-c C-e: Toggle read-only mode to enable/disable editing.
- C-c C-s: Simulate the role's policies against specific actions.
- C-c C-j: View a combined JSON of all permission policies.
- C-c C-a: Get service last accessed details for the role.
- C-c C-c: Inside a source block, apply changes to AWS.
- C-c (:   Hide all property drawers.
- C-c ):   Reveal all property drawers.

In the Simulation Results Buffer:
- C-c C-c: Rerun the simulation for the last used role.
- C-c C-j: View the raw JSON output from the simulation API call.
