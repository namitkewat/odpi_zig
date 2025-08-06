# Building Oracle ODPI-C with Zig 🛠️

This project provides an alternative, cross-platform build system for the [Oracle ODPI-C](https://github.com/oracle/odpi) library using the [Zig programming language](https://ziglang.org/) and its build tools.

The official ODPI-C source code is included as a Git submodule in the `libs/odpi` directory. This makes the project self-contained and easy to set up.

The primary goal is to compile the ODPI-C shared library on any platform **without requiring a C toolchain like Visual Studio, GCC, or Clang to be installed**. Zig's build system bundles its own high-quality C compiler, enabling a simple, fast, and dependency-free build process.

## 🎯 Project Goal

* 🔄 To replace the traditional Makefiles and Visual Studio project files with a single `build.zig` file.
* 💻 Compile the ODPI-C library on Windows, macOS, and Linux.
* 🌍 Cross-compile the library for any target platform from any host.
* 🚫 Remove the need for external C compilers and build tools.
* 📖 Serve as a practical example of using Zig to build existing C projects.

## ✅ Prerequisites

1.  🐙 **Git:** To clone this repository and initialize the ODPI-C submodule.
2.  ⚡ **Zig:** [Install the latest version of Zig](https://ziglang.org/learn/getting-started/). This single dependency provides everything else you need.

## 🚀 How to Build

The entire build process is self-contained within this repository.

### 1️⃣ **Clone this repository:**

```bash
git clone https://github.com/namitkewat/odpi_zig.git
cd odpi_zig
```

### 2️⃣ **Initialize the ODPI-C submodule:**

This will download the ODPI-C source code into the `libs/odpi` directory.

```bash
git submodule update --init --recursive
```

### 3️⃣**Run the Zig build command:**

From the root of the project directory, execute the following command:

```bash
zig build
```

This command will compile the C source files and produce a shared library (`odpic.dll` on Windows, `libodpic.so` on Linux, `libodpic.dylib` on macOS) in the `zig-out/lib` directory. It will also install the public header files into `zig-out/include`.

## 🏷️ Building a Different ODPI-C Version

The ODPI-C library is a Git submodule, which means you can easily check out a different version (tag or branch) to build against.

1.  ➡️ Navigate into the submodule directory:
    ```bash
    cd libs/odpi
    ```

2.  📥 Fetch the latest tags from the official repository:
    ```bash
    git fetch --tags
    ```

3.  🔖 Check out the version you want to build. For example, to build version `v5.6.0`:
    ```bash
    git checkout v5.6.0
    ```

4.  ↩️ Return to the project root and build as usual:
    ```bash
    cd ../..
    zig build
    ```
The build script will automatically detect the new version from the header files and compile it accordingly.

## ⚙️ Build Commands and Options

Zig's build system is highly flexible. Here are some common commands:

* **Build in Release (Optimized) Mode:**
    ```bash
    zig build -Doptimize=ReleaseSafe
    ```

* **Cross-Compile for Windows from Linux/macOS:**
    ```bash
    zig build -Dtarget=x86_64-windows-msvc
    ```

* **Cross-Compile for ARM64 Linux:**
    ```bash
    zig build -Dtarget=aarch64-linux-gnu
    ```

* **Clean the Build Artifacts:**
    ```bash
    zig build clean
    ```

## ✨ Optional Build Steps

Beyond the default library compilation, the `build.zig` script includes additional steps for developers and automation. These steps are not run by default and must be invoked explicitly by name.

### 🤖 Exposing the ODPI-C Version for CI Automation

This is a lightweight helper step designed primarily for automation, such as the GitHub Actions release workflow. It provides a fast, platform-independent way to get the version of the underlying ODPI-C library that the project is building against.

**Command:**
```bash
zig build print-odpi-version
```
**Purpose & Mechanism:**
Instead of printing to the console, this command creates a file at **`zig-out/bin/odpi_version.txt`**. The file will contain just the version string (e.g., `v5.6.2`).

The GitHub Actions workflow runs this step, reads the content of the file, and uses the version string to name the final release artifacts (e.g., `odpi_zig-v0.1.0-with-odpi-v5.6.2-x86_64-linux.zip`), providing clear traceability for each build.

### 🧪 Translating C Tests to Zig

This step is a developer tool for translating the original ODPI-C C test suite into Zig code using `zig translate-c`. This is useful for learning how C constructs map to Zig or as a starting point for creating a native Zig test suite.

**Command:**
```bash
zig build translate-tests
```

This will generate `.zig` files for each C test and place them in the `zig-out/test/` directory.

### Handling Translation Errors

The `zig translate-c` process is strict and may fail on certain C patterns or non-portable code. This section lists known issues and their solutions.

#### Error: Undeclared function 'sleep'

You will likely encounter an error when the process tries to translate `test_4500_sessionless_txn.c` because the `sleep()` function is used without its declaring header file.

To fix this for your local translation, you must temporarily patch the file:

1.  Open the source file from the submodule: `libs/odpi/test/test_4500_sessionless_txn.c`.

2.  Add the following code block to the top of the file, near the other `#include` statements:
    ```
    #ifdef _WIN32
        #include <windows.h>
        #define sleep(s) Sleep((s) * 1000)
    #else
        #include <unistd.h>
    #endif
    ```

3.  Save the file and run `zig build translate-tests` again. The process should now complete successfully.

### 📖 Translating C Demos to Zig

Similar to the test suite, you can also translate the C demo applications provided by ODPI-C into Zig code. This is an excellent way to see practical examples of the library's usage translated into Zig.

**Command:**
```bash
zig build translate-demos
```

This will generate `.zig` files for each C demo and place them in the `zig-out/demos/` directory.

#### Handling Translation Errors

The C demo files are generally self-contained but may have their own portability issues.

##### Error: Undeclared function 'chdir'
You may encounter this error when translating `DemoBFILE.c`. The `chdir()` function, used to change the current directory, requires a specific header.

1.  Open the source file from the submodule: `libs/odpi/samples/DemoBFILE.c`.

2.  Add the following code block to the top of the file to provide the correct header and a compatibility mapping for Windows:
    ```
    #if defined(_WIN32)
        #include <direct.h>
        #define chdir _chdir
    #else
        #include <unistd.h>
    #endif
    ```

3.  Save the file and run `zig build translate-demos` again.

### 🩹 Applying C Source Patches (for Translation)

The ODPI-C C source code contains minor, non-portable patterns that can cause the strict `zig translate-c` commands (used by `zig build translate-tests` and `zig build translate-demos`) to fail. To make the translation process smoother, a Python helper script is provided to automatically apply the necessary fixes.

**Command:**
```bash
python apply_patch.py
```

**What It Does:**
This command will perform the following modifications:
-   **Fixes `sleep` function:** Prepends a cross-platform header include and definition for `sleep()` to `libs/odpi/test/test_4500_sessionless_txn.c`.
-   **Fixes `chdir` function:** Prepends a cross-platform header include and definition for `chdir()` to `libs/odpi/samples/DemoBFILE.c`.

The command is idempotent, meaning it is safe to run multiple times; it will not apply a patch if it already exists.


**Note:** Since you are modifying a file within a Git submodule, this change is temporary and may be overwritten if you update or clean the submodule. This process is intended for local experimentation and analysis.

## 📁 File Descriptions

* `build.zig`: The core build script. It contains all the logic for compiling the C source files from the `libs/odpi` submodule, setting platform-specific flags, linking libraries, and installing the final artifacts. It dynamically parses the version from `libs/odpi/include/dpi.h` to ensure the compiled library is correctly versioned.

* `build.zig.zon`: A package manifest file required by the Zig build system. It declares the project name, version, and dependencies.

* `libs/odpi`: A Git submodule pointing to the official [Oracle ODPI-C repository](https://github.com/oracle/odpi).

## ✨ Benefits of this Approach

* 📦 **Simplicity & Self-Contained:** A `git clone` and `zig build` workflow is all you need. The source code is managed via a submodule, so you don't need to clone multiple repositories.
* 🚫 **Zero C Toolchain Dependencies:** Zig ships with its own C compiler. You don't need to install Visual Studio, build-essentials, or Xcode command-line tools.
* 🌍 **Effortless Cross-Compilation:** Building for a different OS or architecture is as simple as adding a `-Dtarget` flag.
* 🔄 **Reproducibility:** The build is more consistent across different machines since it doesn't rely on the host's installed toolchains.

---

⚠️ *Disclaimer: This is an unofficial, alternative build system for the ODPI-C library and is not supported by Oracle. It is intended for educational purposes and as a demonstration of the Zig build system's capabilities.*