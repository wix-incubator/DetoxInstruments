#!/usr/bin/python

import lldb
import sys
import os
import shlex
import argparse


# Global constants
# This path assumes that the script is stored in Contents/SharedSupport/Scripts inside the Detox Instruments bundle.
instrumentsLocalSharedSupportPath = os.path.dirname(os.path.dirname(__file__))


# Entry point
def __lldb_init_module(debugger, internal_dict):
    # Make the options parser so we can generate the help text for the LLDB command prior to registering it below
    HandleProfilerCommand.__doc__ = CreateProfilerCommandOptionsParser().format_help()
    # Install the debugger command
    debugger.HandleCommand("command script add -f {0}.HandleProfilerCommand dtxprofiler".format(__name__))


# Command options parsing
def CreateProfilerCommandOptionsParser():
    subcommands = {}
    subcommands["load"] = { "func" : HandleProfilerLoadCommand, "help" : "Load DTXProfiler.framework into the current process." }
    subcommands["status"] = { "func" : HandleProfilerStatusCommand, "help" : "Print the status of the current DTXProfiler.framework." }
    
    description = "Commands for loading DTXProfiler.framework in the current debugging session."
    parser = argparse.ArgumentParser(prog="dtxprofiler", description=description)
    subparsers = parser.add_subparsers(title="Available actions", metavar="action")
    
    subparsersMap = {}
    for key, info in subcommands.iteritems():
        subparser = subparsers.add_parser(key, help=info["help"])
        subparser.set_defaults(func=info["func"])
        subparsersMap[key] = subparser
    
    return parser


# Command handlers
def HandleProfilerCommand(debugger, command, exe_ctx, result, internal_dict):
    # Parse the command
    parser = CreateProfilerCommandOptionsParser()
    commandArgs = shlex.split(command)
    
    if len(commandArgs) == 0:
        parser.print_help()
        return
    
    try:
        args = parser.parse_args(commandArgs)
    except:
        return

    # Bail out if running an incompatible target
    target = exe_ctx.target
    if TargetIsCompatible(target) == False:
        result.SetError("target {0} is not supported by DTXProfiler.framework.".format(target.triple))
        return

    # Check that process is already in the right state
    process = exe_ctx.process
    if lldb.SBDebugger.StateIsStoppedState(process.state) == False:
        result.SetError("process must be paused to execute Profiler commands.")
        return

    # Create a loader object with main thread's current frame and execute the command with it
    mainThreadFrame = process.GetThreadAtIndex(0).GetSelectedFrame()
    loader = ProfilerLoader(mainThreadFrame)
    args.func(loader, result, args)

def HandleProfilerLoadCommand(loader, result, args):
    # If target is running in the simulator, load local Profiler
    if TargetIsSimulator(loader.process.target):
        binaryPath = loader.localProfilerBinaryPath()
        loader.injectProfiler(binaryPath, result)
    else:
        # If target is running on device, check if Profiler framework is included in the bundle and try loading it if it exists
        remoteServerBinaryPath = loader.remoteProfilerBinaryPath()
        if loader.remoteFileExists(remoteServerBinaryPath):
            loader.injectProfiler(remoteServerBinaryPath, result)
        else:
            # Can't load the Profiler
            result.SetError("failed to load DTXProfiler.framework because it was not found in the application bundle. For information about profiling apps with Detox Instruments on device, please refer to INTEGRATION.md.")
            return

def HandleProfilerStatusCommand(loader, result, args):
    if loader.isProfilerLoaded():
        version = loader.getProfilerVersion()
        result.AppendMessage("DTXProfiler.framework version {0} is loaded.".format(version))
    else:
        result.AppendMessage("DTXProfiler.framework is not loaded.")


# Profiler Loader
class ProfilerLoader(object):
    def __init__(self, frame):
        self.frame = frame
        self.process = frame.thread.process
    
    def localProfilerBinaryPath(self):
        librariesDirectory = "iphoneos"
        return os.path.join(instrumentsLocalSharedSupportPath, librariesDirectory, "DTXProfiler.framework/DTXProfiler")
    
    def remoteProfilerBinaryPath(self):
        expression = "(id)[[objc_getClass(\"NSBundle\") mainBundle] pathForResource:@\"DTXProfiler\" ofType:@\"framework\"]"
        profilerFrameworkPath = self.frame.EvaluateExpression(expression, GetCommonExpressionOptions()).GetObjectDescription()
        if profilerFrameworkPath is not None and profilerFrameworkPath != "nil":
            return os.path.join(profilerFrameworkPath, "DTXProfiler")
        else:
            return ""

    def remoteFileExists(self, remoteFilePath):
        expression = "(BOOL)[[objc_getClass(\"NSFileManager\") defaultManager] fileExistsAtPath:@\"{0}\"] != NO".format(remoteFilePath)
        return self.frame.EvaluateExpression(expression, GetCommonExpressionOptions()).value == "true"

    def isProfilerLoaded(self):
        expression = "(void*)dlsym((void*)-2, \"OBJC_CLASS_$_DTXProfiler\")"
        value = self.frame.EvaluateExpression(expression, GetCommonExpressionOptions()).value
        pointerValue = int(value, 16)
        return pointerValue != 0

    def getProfilerVersion(self):
        expression = "(id)[objc_getClass(\"DTXProfiler\") version]"
        return self.frame.EvaluateExpression(expression, GetCommonExpressionOptions()).GetObjectDescription()

    def injectProfiler(self, path, result):
        # Check that the Profiler is not already loaded
        if self.isProfilerLoaded():
            result.AppendWarning("DTXProfiler.framework is already loaded in the current process.")
            return
                
        # Load Profiler image from the specified path
        print("Loading DTXProfiler.framework from {0}...".format(path))
        error = lldb.SBError()
        self.process.LoadImage(lldb.SBFileSpec(path), error)

        if error.fail:
            result.SetError(error)
        else:
            result.AppendMessage("DTXProfiler.framework was loaded successfully.")


# Target info utilities
def TargetIsCompatible(target):
    return target.triple.endswith("apple-ios")

def TargetIsSimulator(target):
    return target.platform.GetName().endswith("simulator")


# Process info utilities
def ProcessMainThreadContainsFrameWithName(process, frameName):
    mainThreadFrames = process.GetThreadAtIndex(0).frames
    for frame in mainThreadFrames:
        if frame.name == frameName:
            return True
    
    return False


# Debugger utilities
def GetCommonExpressionOptions():
    options = lldb.SBExpressionOptions()
    options.SetLanguage(lldb.eLanguageTypeObjC)
    options.SetSuppressPersistentResult(True)
    return options
