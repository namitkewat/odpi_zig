import sys
from pathlib import Path

# --- Configuration ---
# A dictionary where the key is the file to patch
# and the value is the content to prepend.
PATCHES = {
    "libs/odpi/test/test_4500_sessionless_txn.c": """#ifdef _WIN32
    #include <windows.h>
    #define sleep(s) Sleep((s) * 1000)
#else
    #include <unistd.h>
#endif""",
    "libs/odpi/samples/DemoBFILE.c": """#if defined(_WIN32)
    #include <direct.h>
    #define chdir _chdir
#else
    #include <unistd.h>
#endif""",
}
# --------------------

def apply_patch(file_path_str: str, patch_content: str):
    """
    Prepends content to a file if it's not already there.
    This makes the patching operation idempotent (safe to run multiple times).
    """
    file_path = Path(file_path_str)
    print(f"--- Checking {file_path} ---")

    if not file_path.exists():
        print(f"ERROR: File not found at {file_path}. Skipping.")
        return False

    try:
        original_content = file_path.read_text(encoding="utf-8")

        # Normalize patch content to avoid whitespace issues
        normalized_patch = patch_content.strip()

        if original_content.startswith(normalized_patch):
            print("Patch already applied, skipping.")
            return True
        
        print("Applying patch...")
        new_content = normalized_patch + "\n\n" + original_content
        file_path.write_text(new_content, encoding="utf-8")
        print("Successfully applied patch.")
        return True

    except Exception as e:
        print(f"ERROR: Failed to patch file {file_path}: {e}")
        return False

def main():
    """Main function to apply all defined patches."""
    print("Starting C source file patching process...")
    success_count = 0
    total_count = len(PATCHES)

    for path, content in PATCHES.items():
        if apply_patch(path, content):
            success_count += 1
    
    print("-----------------------------------------")
    print(f"Patching process complete. {success_count}/{total_count} files checked/patched successfully.")
    if success_count != total_count:
        sys.exit(1)


if __name__ == "__main__":
    main()