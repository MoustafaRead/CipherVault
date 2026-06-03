<div align="center">

```
   ______    _              __                  _    __                    __   __
  / ____/   (_)    ____    / /_   ___    _____ | |  / /  ____ _  __  __   / /  / /_
 / /       / /    / __ \  / __ \ / _ \  / ___/ | | / /  / __ `/ / / / /  / /  / __/
/ /___    / /    / /_/ / / / / //  __/ / /     | |/ /  / /_/ / / /_/ /  / /  / /_
\____/   /_/    / .___/ /_/ /_/ \___/ /_/      |___/   \__,_/  \__,_/  /_/   \__/
        /_/
```

# CipherVault

**File-based encryption/decryption tool built entirely in x86 Assembly**

![Language](https://img.shields.io/badge/Language-x86%20Assembly-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Assembler](https://img.shields.io/badge/Assembler-MASM32-orange)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

---

## Overview

CipherVault is a low-level, console-based encryption and decryption tool written entirely in **x86 Assembly** using MASM32. It operates directly on the file system — recursively traversing directories and applying cryptographic byte-level transformations to every file found, including files inside subfolders.

No external cryptographic libraries are used. All logic is implemented from scratch at the assembly level using direct Win32 API calls.

---

## Features

- Encrypt or decrypt entire directory trees with a single command
- Recursive subfolder traversal — processes every file at any depth
- Direct Win32 API file I/O (`CreateFileA`, `ReadFile`, `WriteFile`)
- In-memory byte-level transformation (no temp files)
- Skips itself (`CipherVault.exe`) automatically during processing
- Displays a live tree of all processed files and directories
- Zero external dependencies — pure Assembly

---

## How It Works

CipherVault reads each file into a heap-allocated buffer, applies a byte transformation to every byte, then overwrites the original file with the modified content.

| Operation | Transformation |
|-----------|----------------|
| Encrypt   | `byte += 169` for every byte in the file |
| Decrypt   | `byte -= 169` for every byte in the file |

Since `169 + 169 = 338 = 256 + 82`, the operations are perfectly reversible — encrypting twice does **not** restore the original.

---

## Requirements

- Windows (32-bit or 64-bit with 32-bit support)
- [MASM32 SDK](http://www.masm32.com/) installed at `C:\masm32\`

---

## Build Instructions

> Make sure MASM32 is installed and its `\bin` directory is in your system PATH.

### Step 1 — Assemble `.asm` → `.obj`

```bat
ml /c /coff CipherVault.asm
```

| Flag   | Description                          |
|--------|--------------------------------------|
| `/c`   | Compile only, do not link            |
| `/coff`| Output in COFF format (required for 32-bit Windows) |

This produces `CipherVault.obj`.

---

### Step 2 — Link `.obj` → `.exe`

```bat
link /SUBSYSTEM:CONSOLE /OUT:CipherVault.exe CipherVault.obj ^
  c:\masm32\lib\kernel32.lib ^
  c:\masm32\lib\user32.lib ^
  c:\masm32\lib\msvcrt.lib
```

This produces `CipherVault.exe`.

---

### Quick Build (one-liner)

```bat
ml /c /coff CipherVault.asm && link /SUBSYSTEM:CONSOLE /OUT:CipherVault.exe CipherVault.obj c:\masm32\lib\kernel32.lib c:\masm32\lib\user32.lib c:\masm32\lib\msvcrt.lib
```

---

## Usage

Run the executable from a terminal:

```bat
CipherVault.exe
```

You will be greeted with the ASCII banner, then prompted to choose an operation:

```
Choose an option:
1. Encrypt
2. Decrypt
>>> _
```

After selecting an option, enter the full path to the target directory:

```
Enter Path to encrypt files:
Path:
>>> C:\Users\You\Documents\SecretFolder
```

CipherVault will recursively scan the directory and process every file found, displaying the tree as it goes:

```
    <DIR>  SubFolder
        <FILE>  notes.txt
        <FILE>  image.png
    <FILE>  report.docx
```

---

## Example Workflow

```
# 1. Encrypt a folder
>>> 1
>>> C:\Users\You\Desktop\MyFiles

# 2. Decrypt the same folder to restore original content
>>> 2
>>> C:\Users\You\Desktop\MyFiles
```

> ⚠️ **Warning:** CipherVault modifies files **in place**. Always keep a backup before encrypting important data.

---

## Project Structure

```
CipherVault/
│
├── CipherVault.asm       # Full source code (Assembly)
├── CipherVault.obj       # Compiled object file (generated)
├── CipherVault.exe       # Final executable (generated)
└── README.md
```

---

## Known Limitations

- Windows only (uses Win32 API)
- 32-bit only (`.386` flat model)
- Does not encrypt filenames, only file contents
- No password/key protection — the transformation is fixed

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">
Built with ❤️ in pure x86 Assembly
</div>
