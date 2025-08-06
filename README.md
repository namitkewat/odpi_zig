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