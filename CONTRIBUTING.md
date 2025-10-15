# Contributing Guide

Contributions to this project are welcome. If you have an idea for a bigger change, [open an issue first](https://github.com/brettchalupa/graphql-docs/issues/new/choose) and we can discuss it.

For fixes and small additions, follow the steps below to get developing and contributing:

1. Fork & clone the repository in GitHub
2. Run the `bin/setup` script to install development dependencies
3. Work on a branch
4. Make changes
5. Ensure tests and code style checks pass by running `bin/rake` (runs both StandardRB and tests)
6. Commit your changes, this project follows [the Conventional Commits spec](https://www.conventionalcommits.org/en/v1.0.0/)
7. Open up a pull request

## Code Style

This project uses [StandardRB](https://github.com/standardrb/standard) for Ruby code style. StandardRB is an opinionated, zero-configuration linter and formatter.

Before committing your changes, make sure your code passes StandardRB:

```console
bundle exec rake standard
```

To automatically fix most style issues:

```console
bundle exec rake standard:fix
```

The default `bin/rake` command runs both StandardRB checks and the test suite, so you can verify everything at once.

## Finding Issues

- Good First Issue — If you're new to the project or Ruby, check out the ["good first issue" tag](https://github.com/brettchalupa/graphql-docs/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22). They're smaller, approachable issues if you're just getting started.
- Web — tasks that don't require much Ruby knowledge but require HTML and CSS have the ["web" tag](https://github.com/brettchalupa/graphql-docs/issues?q=is%3Aopen+is%3Aissue+label%3A%22web%22+)
