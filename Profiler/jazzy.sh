#!/bin/sh -e
#--skip-undocumented 
jazzy --objc --clean --author Wix --author_url https://github.com/wix --github_url https://github.com/wix/DetoxInstruments --module-version 1.6 --umbrella-header Profiler/DTXProfiler/DTXProfiler.h --framework-root Profiler/ --module DTXProfiler --theme fullwidth --readme README.md