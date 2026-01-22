# graphql-docs Changelog

A concise overview of the public-facing changes to the gem from version to version. Does not include internal changes to the dev experience for the gem.

## Unreleased

## v6.0.0 - 2026-01-22

### Features

- Add Rake task `graphql-docs:generate` for integration with Rails and other Ruby projects that use Rake. Supports both task arguments and environment variables for configuration. Can be used with `Rake::Task["assets:precompile"].enhance(["graphql-docs:generate"])` to generate docs as part of the build process.
- Add support for running as a Rack app for easy integration with existing web applications
- Add resizable sidebar for better UX
- Add Dark Mode styles support
- Render deprecation info for queries and mutations

### Improvements

- Replace jQuery with vanilla JavaScript for smaller bundle size and fewer dependencies
- Optimize packaged gem size and use system fonts for better performance
- Run CI against Ruby 4.0

### Breaking Changes

- **breaking:** Upgrade commonmarker, html-pipeline, and gemoji dependencies, see **BREAKING CHANGES** section below

### 🚨 BREAKING CHANGES

This release upgrades three major dependencies with significant breaking changes.

#### Dependency Upgrades

- **commonmarker**: `0.23.x` → `2.0.x` - Complete API rewrite with improved performance and standards compliance
- **html-pipeline**: `2.14.x` → `3.0.x` - Simplified architecture, filter API changed
- **gemoji**: `3.0.x` → `4.0.x` - Updated emoji mappings
- **Removed**: `extended-markdown-filter` (no longer maintained, incompatible with html-pipeline 3)

#### Breaking Changes for Advanced Users

1. **Custom html-pipeline filters no longer work**
   - html-pipeline 3.x has a completely different filter API
   - If you configured custom filters via `pipeline_config[:pipeline]`, they will not work
   - **Migration**: Rewrite custom filters using html-pipeline 3.x API (see [html-pipeline migration guide](https://github.com/jch/html-pipeline/blob/main/CHANGELOG.md))
   - The gem now handles markdown and emoji rendering directly

2. **Custom Renderer API changes**
   - If you implemented a custom renderer that directly uses CommonMarker:
   - **Old API**: `CommonMarker.render_html(string, :UNSAFE)`
   - **New API**: `Commonmarker.parse(string).to_html(options: {render: {unsafe: true}})`
   - Note the lowercase 'm' in `Commonmarker` in version 2.x

3. **Table of Contents filter removed from defaults**
   - The default `TableOfContentsFilter` is no longer applied
   - **Migration**: Implement a custom post-processing step if needed

#### What Still Works (and is Better!)

- ✅ GitHub Flavored Markdown (tables, strikethrough, autolinks, task lists)
- ✅ **Emoji rendering** - `:emoji:` syntax like `:smile:` works out of the box
- ✅ Header anchors (automatically generated with IDs)
- ✅ Safe and unsafe HTML rendering modes
- ✅ Code blocks with syntax highlighting
- ✅ All existing templates and layouts
- ✅ Faster markdown rendering
- ✅ More standards-compliant HTML output

#### Why Upgrade?

- **Security**: Updates to latest stable versions with security patches
- **Performance**: commonmarker 2.x is significantly faster and more standards-compliant
- **Maintainability**: All dependencies are actively maintained
- **Modern**: Uses current Ruby ecosystem standards

#### Migration Guide

For most users with default configuration, this upgrade should be seamless. Advanced users should check:

- [ ] Do you use custom `pipeline_config[:pipeline]` filters? → Rewrite for html-pipeline 3.x
- [ ] Do you have a custom `Renderer` subclass that calls CommonMarker directly? → Update API calls
- [ ] Run full test suite after upgrade
- [ ] Regenerate documentation and visually inspect output

## v5.2.0 - 2025-02-09

- Add search filter to sidebar. Thanks @denisahearn!

## v5.1.0 - 2024-12-09

- List queries in the sidebar, similar to mutations. See https://github.com/brettchalupa/graphql-docs/pull/156. Thanks @denisahearn!
- Fix Sass `@import` deprecation
- Add ostruct and logger gems to dependencies since they're being removed from the Ruby standard library in a future release
- Test and fixture improvements

## v5.0.0 - 2024-07-03

- **breaking**: The graphql gem 2.2.0+ breaks some of the parsing and displaying of comments from a GraphQL schema file
- **breaking**: Ruby 2.6, 2.7, 3.0 are no longer supported as they are End of Life (EOL)
- feat: CLI version flag: `graphql-docs --version` / `graphql-docs -v`
- fix: CLI now works outside of a Bundler project
- fix: test suite
- chore: switch to sess-embedded gem for more maintained dependency

## v4.0.0 - 2023-01-26

- **Breaking change**: drop support for Ruby 2.5 and earlier
- CLI with limited options, e.g. `graphql-docs schema.graphql`
- Dart Sass replaces Ruby Sass because Ruby Sass is deprecated
- Fixes:
  - Upgrade commonmarker to latest ver to address security vulnerabilities
  - commonmarker pinned to version without security vulnerability
- Chores:
  - Dev env refresh

## v3.0.1 - 2022-10-14

- fix: Relieves `EscapeUtils.escape_html is deprecated. Use GCI.escapeHTML instead, it's faster` deprecation warning until it gets released in an downstream dependency
- meta: Maintainership change from [gjtorikian](https://github.com/gjtorikian) to [brettchalupa](https://github.com/brettchalupa)

## v3.0.0 - 2022-03-23

- Upgrades `graphql` gem to the 2.x series
