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
    const versions = parseDpiVersion(b, "include/dpi.h") catch std.SemanticVersion{ .major = 1, .minor = 0, .patch = 0 };
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
    lib.addIncludePath(b.path("include"));

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
        "src/dpiConn.c",
        "src/dpiContext.c",
        "src/dpiData.c",
        "src/dpiDebug.c",
        "src/dpiDeqOptions.c",
        "src/dpiEnqOptions.c",
        "src/dpiEnv.c",
        "src/dpiError.c",
        "src/dpiGen.c",
        "src/dpiGlobal.c",
        "src/dpiHandleList.c",
        "src/dpiHandlePool.c",
        "src/dpiJson.c",
        "src/dpiLob.c",
        "src/dpiMsgProps.c",
        "src/dpiObject.c",
        "src/dpiObjectAttr.c",
        "src/dpiObjectType.c",
        "src/dpiOci.c",
        "src/dpiOracleType.c",
        "src/dpiPool.c",
        "src/dpiQueue.c",
        "src/dpiRowid.c",
        "src/dpiSodaColl.c",
        "src/dpiSodaCollCursor.c",
        "src/dpiSodaDb.c",
        "src/dpiSodaDoc.c",
        "src/dpiSodaDocCursor.c",
        "src/dpiStmt.c",
        "src/dpiStringList.c",
        "src/dpiSubscr.c",
        "src/dpiUtils.c",
        "src/dpiVar.c",
        "src/dpiVector.c",
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
    const install_header = b.addInstallFileWithDir(b.path("include/dpi.h"), .header, "dpi.h");
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
