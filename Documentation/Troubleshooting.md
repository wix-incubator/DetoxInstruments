# Troubleshooting

### Installation

- If Homebrew complains about a conflict in the `wix/brew` tap, **run `brew untap wix/brew && brew tap wix/brew` and install again**
- If installation still fails, **run `brew doctor` and fix all issues & warnings**

### Building

- If, when building your project, you see the following error:

  ```
  ld: framework not found DTXProfiler
  clang: error: linker command failed with exit code 1 (use -v to see invocation)
  ```

  You need to install Detox Instruments on your machine. See [Installation](../Readme.md#installation) for more information.

- If you have trouble building your project for Mac Catalyst, make sure your `Other Linker Flags` are correctly set to:

  ```
  -ObjC -F"${CODESIGNING_FOLDER_PATH}/${BUNDLE_FRAMEWORKS_FOLDER_PATH}" -framework DTXProfiler
  ```

  See [Profiler Framework Integration Guide](XcodeIntegrationGuide.md) for more information.

### Mac Catalyst

- If you build your project with the Sandbox enabled, and your app is not discoverable in Detox Instruments, you will need to enable **Incoming Connections (Server)** under **Signing & Capabilities**.