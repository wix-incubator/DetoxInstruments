# Contributing to Detox Instruments

Detox Instruments is a complex project, comprised of several components. Before opening the project make sure your environment meets the following requirements:

- macOS 10.14.3
- Xcode 10.2

### Cloning

The project uses Git submodules for its first- and third-party dependency needs. The easiest way to clone the project is by using the `--recurse-submodules -j8` arguments:

```shell
git clone --recurse-submodules -j8 https://github.com/wix/DetoxInstruments.git
```

If you’ve already cloned the repo, you can initialize all submodules recursively:

```shell
git submodule update --init --recursive
```

### Projects

The project is separated into three main components, which have their own project files:

- Profiler Framework—`Profiler/DTXProfiler.xcodeproj`
  iOS framework for profiling and recording various device metrics and events
- Detox Instruments—`DetoxInstruments/DetoxInstruments.xcodeproj`
  macOS project for the main Detox Instruments app, providing live profiling capabilities, device management, recording documents opening, viewing and data export, and Requests Playgrounds
- CLI—`CLI/CLI.xcodeproj`
  macOS project for querying information out recording documents from the command-line
- Shim Profiler Framework—`ProfilerShim/DTXProfilerShim.xcodeproj`
  iOS framework, providing an empty implementation of the Profiler framework, intended as a replacement during build time when the Profiler framework integration is not desired

