# Troubleshooting

### Installation

- If Homebrew complains about a conflict in the `wix/brew` tap, **run `brew untap wix/brew && brew tap wix/brew` and install again**
- If installation still fails, **run `brew doctor` and fix all issues & warnings**

### Building

If, when building your project, you see the following error:

```
ld: framework not found DTXProfiler
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

You need to install Detox Instruments on your machine. See [Installation](../Readme.md#installation) for more information.