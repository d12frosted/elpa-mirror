
GPT-Commit is an Emacs package that automates the generation of
conventional commit messages.  By leveraging the power of GPT
(Generative Pre-trained Transformer) models, it suggests structured
commit messages following the conventional commit format.

With GPT-Commit, you no longer need to spend time crafting commit
messages manually.  It analyzes the changes in your Git repository and
generates meaningful commit messages automatically, ensuring
consistent and descriptive commit logs.

Features:
- Automatic generation of conventional commit messages
- Integration with Git and Magit for seamless workflow
- Easy configuration and customization

GPT-Commit streamlines the commit process and promotes best practices
for commit message formatting.  By using consistent commit messages,
you can enhance project clarity, facilitate collaboration, and improve
the overall maintainability of your codebase.

(require 'gpt-commit)
(setq gpt-commit-openai-key "YOUR_OPENAI_API_KEY")
(setq gpt-commit-model-name "gpt-3.5-turbo-16k")
(add-hook 'git-commit-setup-hook 'gpt-commit-message)
