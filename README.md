# InContext

[![build](https://github.com/inseven/incontext/actions/workflows/build.yaml/badge.svg)](https://github.com/inseven/incontext/actions/workflows/build.yaml)

Multimedia-focused static site builder for macOS

## Installation

InContext can be installed using [Homebrew](https://brew.sh):

```bash
brew install inseven/incontext/incontext
```

## Documentation

See [https://incontext.app/docs](https://incontext.app/docs).

## Frontmatter

Frontmatter is supported in Markdown files and image and video descriptions. InContext will pass through all unknown markdown fields, but puts type constraints on fields that have specific meaning:

- `title` String?
- `subtitle` String?
- `date` Date?
- `queries` [[String: Any]]?
- `tags` [String]?

## Issues

### Background

- Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but it would be much easier if we had a way to generate these as part of the site so importers don't have to think too hard
- Store the origin mime type in the database and expose through `DocumentContext`
- Provide a simple, clean API to inline a relative document
- Resolve
  - Introduce a render-time `resolve` method that can figure out what happened to a document and include it
  - The current `resolve` implementation is hand-tuned and isn't guaranteed to work with new document types

- Test resolving relative paths '.'
- Support building to a custom build destination; this will make it much easier to use for GitHub Pages based deployments

## License

InContext is licensed under the MIT License (see [LICENSE](https://github.com/inseven/thoughts/blob/main/LICENSE)). It depends on the following separately licensed third-party libraries and components:

- [Diligence](https://github.com/inseven/diligence), MIT License
- [Hummingbird](https://github.com/hummingbird-project/hummingbird), Apache License, Version 2.0
- [Interact](https://github.com/inseven/interact), MIT License
- [Licensable](https://github.com/inseven/licensable), MIT License
- [LuaSwift](https://github.com/tomsci/LuaSwift), MIT License
- [SQLite.swift](https://github.com/stephencelis/SQLite.swift), MIT License
- [Tilt](https://github.com/tomsci/tomscis-lua-templater), MIT License
- [Titlecaser](https://github.com/jwells89/Titlecaser), MIT License
- [Yams](https://github.com/jpsim/Yams), MIT License
