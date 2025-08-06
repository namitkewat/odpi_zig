const std = @import("std");

/// Build script for the Oracle ODPI-C library.
/// This script compiles the C source files into a shared library (.dll or .so)
/// and installs it along with the necessary public header files.
pub fn build(b: *std.Build) void {
    // 1. SETUP: Standard target and optimization options.
    // Allows for cross-compilation and release builds (e.g., `zig build -Doptimize=ReleaseSafe`).
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 2. VERSIONING: Parse version dynamically from the `dpi.h` header.
    const versions = parseDpiVersion(b, "libs/odpi/include/dpi.h") catch std.SemanticVersion{ .major = 1, .minor = 0, .patch = 0 };
    std.debug.print("Building odpi v{}.{}.{} library\n", .{ versions.major, versions.minor, versions.patch });

    // 3. ARTIFACT CREATION: Define the shared library artifact.
    //  Create shared library with version info
    const lib = b.addSharedLibrary(.{
        .name = "odpic",
        .version = .{
            .major = versions.major,
            .minor = versions.minor,
            .patch = versions.patch,
        },
        .target = target,
        .optimize = optimize,
    });

    // Link against the C standard library, which is required by the C source code.
    lib.linkLibC();

    // Make the `include` directory available to the C compiler.
    // This allows source files to use `#include "dpi.h"`.
    lib.addIncludePath(b.path("libs/odpi/include"));

    // 4. PLATFORM-SPECIFIC CONFIGURATION:
    const is_windows = target.result.os.tag == .windows;

    // Link against required system libraries on non-Windows platforms.
    // - 'dl' is for dynamic linking functions like dlopen.
    // - 'pthread' is for POSIX threads.
    if (!is_windows) {
        lib.linkSystemLibrary("dl");
        lib.linkSystemLibrary("pthread");
    }

    // Add all source files
    const src_files = &.{
        "libs/odpi/src/dpiConn.c",
        "libs/odpi/src/dpiContext.c",
        "libs/odpi/src/dpiData.c",
        "libs/odpi/src/dpiDebug.c",
        "libs/odpi/src/dpiDeqOptions.c",
        "libs/odpi/src/dpiEnqOptions.c",
        "libs/odpi/src/dpiEnv.c",
        "libs/odpi/src/dpiError.c",
        "libs/odpi/src/dpiGen.c",
        "libs/odpi/src/dpiGlobal.c",
        "libs/odpi/src/dpiHandleList.c",
        "libs/odpi/src/dpiHandlePool.c",
        "libs/odpi/src/dpiJson.c",
        "libs/odpi/src/dpiLob.c",
        "libs/odpi/src/dpiMsgProps.c",
        "libs/odpi/src/dpiObject.c",
        "libs/odpi/src/dpiObjectAttr.c",
        "libs/odpi/src/dpiObjectType.c",
        "libs/odpi/src/dpiOci.c",
        "libs/odpi/src/dpiOracleType.c",
        "libs/odpi/src/dpiPool.c",
        "libs/odpi/src/dpiQueue.c",
        "libs/odpi/src/dpiRowid.c",
        "libs/odpi/src/dpiSodaColl.c",
        "libs/odpi/src/dpiSodaCollCursor.c",
        "libs/odpi/src/dpiSodaDb.c",
        "libs/odpi/src/dpiSodaDoc.c",
        "libs/odpi/src/dpiSodaDocCursor.c",
        "libs/odpi/src/dpiStmt.c",
        "libs/odpi/src/dpiStringList.c",
        "libs/odpi/src/dpiSubscr.c",
        "libs/odpi/src/dpiUtils.c",
        "libs/odpi/src/dpiVar.c",
        "libs/odpi/src/dpiVector.c",
    };

    // Add C source files with platform-specific compiler flags.
    if (is_windows) {
        // On Windows, -DDPI_EXPORTS is crucial. It defines the DPI_EXPORTS macro,
        // which controls whether __declspec(dllexport) or __declspec(dllimport)
        // is used when defining library functions, making them accessible from the DLL.
        lib.addCSourceFiles(.{ .files = src_files, .flags = &.{ "-std=c99", "-DDPI_EXPORTS" } });
    } else {
        // On other platforms, this macro is not needed
        lib.addCSourceFiles(.{ .files = src_files, .flags = &.{"-std=c99"} });
    }

    // Install library
    b.installArtifact(lib);

    // Install header file
    const install_header = b.addInstallFileWithDir(b.path("libs/odpi/include/dpi.h"), .header, "dpi.h");
    b.getInstallStep().dependOn(&install_header.step);
}

// Parse version from dpi.h
fn parseDpiVersion(b: *std.Build, path: []const u8) !std.SemanticVersion {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const size = (try file.stat()).size;
    const content = try b.allocator.alloc(u8, size);
    defer b.allocator.free(content);

    _ = try file.readAll(content);

    var major: u32 = 0;
    var minor: u32 = 0;
    var patch: u32 = 0;
    var found: u32 = 0;

    var lines = std.mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "DPI_MAJOR_VERSION") != null) {
            major = try extractNumber(line);
            found += 1;
        } else if (std.mem.indexOf(u8, line, "DPI_MINOR_VERSION") != null) {
            minor = try extractNumber(line);
            found += 1;
        } else if (std.mem.indexOf(u8, line, "DPI_PATCH_LEVEL") != null) {
            patch = try extractNumber(line);
            found += 1;
        }
        if (found == 3) break;
    }

    if (found != 3) return error.VersionNotFound;
    return std.SemanticVersion{ .major = major, .minor = minor, .patch = patch };
}

// Extracts the last integer from a string containing a '#define' line.
fn extractNumber(line: []const u8) !u32 {
    var tokens = std.mem.tokenizeSequence(u8, line, " ");
    while (tokens.next()) |token| {
        if (std.fmt.parseInt(u32, token, 10)) |num| {
            return num;
        } else |_| {}
    }
    return error.NumberNotFound;
}
