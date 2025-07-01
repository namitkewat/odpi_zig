# Building Oracle ODPI-C with Zig

This project provides an alternative, cross-platform build system for the [Oracle ODPI-C](https://github.com/oracle/odpi) library using the [Zig programming language](https://ziglang.org/) and its build tools.

The primary goal is to compile the ODPI-C shared library on any platform **without requiring a C toolchain like Visual Studio, GCC, or Clang to be installed**. Zig's build system bundles its own high-quality C compiler, enabling a simple, fast, and dependency-free build process.

## Project Goal

To replace the traditional Makefiles and Visual Studio project files with a single `build.zig` file that can:

* Compile the ODPI-C library on Windows, macOS, and Linux.
* Cross-compile the library for any target platform from any host.
* Remove the need for external C compilers and build tools.
* Serve as a practical example of using Zig to build existing C projects.

## Prerequisites

1.  **Git:** To clone the official ODPI-C repository.
2.  **Zig:** [Install the latest version of Zig](https://ziglang.org/learn/getting-started/). This single dependency provides everything else you need.

## How to Build

The build files in this repository are designed to be dropped into the root of the official `odpi` source tree.

1.  **Clone the official Oracle ODPI-C repository:**
    ```bash
    git clone https://github.com/oracle/odpi.git
    cd odpi
    ```

2.  **Add the Zig build files to the root directory:**
    Copy the `build.zig` and `build.zig.zon` files from this project into the `odpi` directory you just cloned.

3.  **Run the Zig build command:**
    From within the `odpi` directory, execute the following command to compile the library:
    ```bash
    zig build
    ```

This command will compile the C source files and produce a shared library (`odpic.dll` on Windows, `libodpic.so` on Linux, `libodpic.dylib` on macOS) in the `zig-out/lib` directory. It will also install the public header files into `zig-out/include`.

## Build Commands and Options

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

## File Descriptions

* `build.zig`: The core build script. It contains all the logic for compiling the C source files, setting platform-specific flags, linking libraries, and installing the final artifacts. It dynamically parses the version from `include/dpi.h` to ensure the compiled library is correctly versioned.

* `build.zig.zon`: A package manifest file required by the Zig build system. It declares the project name, version, and dependencies (though in this case, there are no external dependencies).


## Benefits of this Approach

* **Simplicity:** A single `zig build` command replaces complex Makefiles and platform-specific scripts.
* **Zero C Toolchain Dependencies:** Zig ships with its own C compiler. You don't need to install Visual Studio, build-essentials, or Xcode command-line tools.
* **Effortless Cross-Compilation:** Building for a different OS or architecture is as simple as adding a `-Dtarget` flag.
* **Reproducibility:** The build is more consistent across different machines since it doesn't rely on the host's installed toolchains.

---

*Disclaimer: This is an unofficial, alternative build system for the ODPI-C library and is not supported by Oracle. It is intended for educational purposes and as a demonstration of the Zig build system's capabilities.*
