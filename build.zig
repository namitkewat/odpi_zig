const std = @import("std");

/// Build script for the Oracle ODPI-C library.
/// This script compiles the C source files into a shared library (.dll or .so)
/// and installs it along with the necessary public header files.
pub fn build(b: *std.Build) void {
    // 1. SETUP: Standard target and optimization options.
    // Allows for cross-compilation and release builds (e.g., `zig build -Dtarget=...`).
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 2. VERSIONING: Parse version dynamically from the `dpi.h` header.
    const versions = parseDpiVersion(b, "libs/odpi/include/dpi.h") catch std.SemanticVersion{ .major = 1, .minor = 0, .patch = 0 };
    std.debug.print("Building odpi v{}.{}.{} library\n", .{ versions.major, versions.minor, versions.patch });

    // 3. ARTIFACT CREATION: Define the shared library artifact.
    // This is the primary output of a standard `zig build` command.
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

    // Link against the C standard library, which is required by the ODPI-C source code.
    lib.linkLibC();

    // Make the `libs/odpi/include` directory available to the C compiler.
    lib.addIncludePath(b.path("libs/odpi/include"));

    // 4. PLATFORM-SPECIFIC CONFIGURATION:
    const is_windows = target.result.os.tag == .windows;

    // Link against required system libraries on non-Windows platforms.
    if (!is_windows) {
        lib.linkSystemLibrary("dl");
        lib.linkSystemLibrary("pthread");
    }

    // Define the list of all C source files for the library.
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
        // On Windows, -DDPI_EXPORTS is crucial for creating a usable DLL.
        lib.addCSourceFiles(.{ .files = src_files, .flags = &.{ "-std=c99", "-DDPI_EXPORTS" } });
    } else {
        lib.addCSourceFiles(.{ .files = src_files, .flags = &.{"-std=c99"} });
    }

    // Install the compiled library to `zig-out/lib`.
    b.installArtifact(lib);

    // Install the public header to `zig-out/include`.
    const install_header = b.addInstallFileWithDir(b.path("libs/odpi/include/dpi.h"), .header, "dpi.h");
    b.getInstallStep().dependOn(&install_header.step);

    // ======================================================================
    // CI HELPER: EFFICIENT & PORTABLE ODPI-C VERSION OUTPUT
    //
    // This optional step provides a platform-independent way for automation
    // (like GitHub Actions) to get the detected ODPI-C version.
    // It avoids non-portable system commands like 'echo'.
    //
    // To run, use: `zig build print-odpi-version`
    // This will create a file at: `zig-out/bin/odpi_version.txt`
    // ======================================================================
    const print_version_step = b.step("print-odpi-version", "Writes the detected ODPI-C version to a file");

    // Format the version string we parsed earlier.
    const version_string = b.fmt("v{d}.{d}.{d}", .{
        versions.major,
        versions.minor,
        versions.patch,
    });

    // 1. Write the version string to a temporary file in the build cache.
    const version_file_in_cache = b.addWriteFile(
        "odpi_version.txt", // A temporary name for the file in the cache
        version_string,
    );

    // // 2. Install that temporary file from the cache to the final output directory.
    const install_version_file = b.addInstallFile(
        version_file_in_cache.getDirectory().path(b, "odpi_version.txt"), // Source is the artifact from the previous step
        "bin/odpi_version.txt", // Destination is zig-out/bin/odpi_version.txt
    );

    print_version_step.dependOn(&install_version_file.step);

    // ======================================================================
    // Optional Developer Step: Translate all C test files to Zig
    //
    // This step is NOT run by default.
    // To execute, run: `zig build translate-tests`
    //
    // As noted in the README, this may fail on certain files due to C
    // portability issues that require temporary manual patching of the
    // source file in the `libs/odpi/test` submodule.
    // ======================================================================
    const translate_tests_step = b.step("translate-tests", "Translate all ODPI-C test files to Zig");

    const test_c_files = [_][]const u8{
        "TestSuiteRunner.c",
        "test_1000_context.c",
        "test_1100_numbers.c",
        "test_1200_conn.c",
        "test_1300_conn_properties.c",
        "test_1400_pool.c",
        "test_1500_pool_properties.c",
        "test_1600_queries.c",
        "test_1700_transactions.c",
        "test_1800_misc.c",
        "test_1900_variables.c",
        "test_2000_statements.c",
        "test_2100_data_types.c",
        "test_2200_object_types.c",
        "test_2300_objects.c",
        "test_2400_enq_options.c",
        "test_2500_deq_options.c",
        "test_2600_msg_props.c",
        "test_2700_aq.c",
        "test_2800_lobs.c",
        "test_2900_implicit_results.c",
        "test_3000_scroll_cursors.c",
        "test_3100_subscriptions.c",
        "test_3200_batch_errors.c",
        "test_3300_dml_returning.c",
        "test_3400_soda_db.c",
        "test_3500_soda_coll.c",
        "test_3600_soda_coll_cursor.c",
        "test_3700_soda_doc.c",
        "test_3800_soda_doc_cursor.c",
        "test_3900_sess_tags.c",
        "test_4000_queue.c",
        "test_4100_binds.c",
        "test_4200_rowids.c",
        "test_4300_json.c",
        "test_4400_vector.c",
        "test_4500_sessionless_txn.c",
    };

    // Loop through each C test file and create a translation job for it.
    inline for (test_c_files) |c_filename| {
        // Define the translation step for the current C file.
        const translate = b.addTranslateC(.{
            .root_source_file = b.path("libs/odpi/test/" ++ c_filename),
            .target = target,
            .optimize = optimize,
        });

        // Add the necessary include paths for the C preprocessor to find headers.
        translate.addIncludePath(b.path("libs/odpi/include")); // For finding "dpi.h"
        translate.addIncludePath(b.path("libs/odpi/test")); // For finding "TestLib.h"

        // Add C preprocessor definitions if needed, like for Windows DLL exports.
        if (is_windows) {
            translate.defineCMacro("DPI_EXPORTS", null);
        }

        // Create the destination path string, e.g., "test/test_1200_conn.zig".
        const stem = std.fs.path.stem(c_filename);
        const zig_filepath = std.fmt.allocPrint(b.allocator, "test/{s}.zig", .{stem}) catch @panic("Failed to allocate memory for filename");

        // Install the translated Zig file into the `zig-out/test/` directory.
        const install_file = b.addInstallFile(translate.getOutput(), zig_filepath);

        // Make the main "translate-tests" step depend on this file's installation.
        translate_tests_step.dependOn(&install_file.step);
    }
}

// Helper function to parse the version numbers from the dpi.h header file.
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

// Helper function to extract a number from a '#define' line.
fn extractNumber(line: []const u8) !u32 {
    var tokens = std.mem.tokenizeSequence(u8, line, " ");
    while (tokens.next()) |token| {
        if (std.fmt.parseInt(u32, token, 10)) |num| {
            return num;
        } else |_| {}
    }
    return error.NumberNotFound;
}
