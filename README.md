# Chatless

## Optional pre-commit formatting

This repository includes an opt-in pre-commit hook that runs the Swift toolchain's formatter on
staged Swift files. Enable it once in your clone:

```sh
./install-git-hooks.sh
```

The hook formats files with `swift format` using the checked-in `.swift-format` configuration and
adds any formatting changes back to the commit. It is a convenience only: if the Swift toolchain is
not available, the commit continues without formatting.

Partially staged Swift files are skipped so that the hook cannot accidentally stage unrelated
working-tree edits. Format those files manually or stage the complete file if you want the hook to
handle them.

To disable the hook again:

```sh
git config --local --unset core.hooksPath
```
