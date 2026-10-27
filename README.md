# Voxel Engine - Free Pascal & Raylib

A first-person 3D voxel-based engine built from scratch using Free Pascal and Raylib 4.0 Pascal bindings.

---

## Compiler & Dependency Requirements

* **Compiler:** **Free Pascal Compiler (FPC)** version **3.2.2** or higher (x64 / Win64 target).
* **Bindings:** `Raylib.4.0.Pascal` source package.
* **Shared Library:** `raylib.dll` (v4.0 compatible, 64-bit) placed in the root directory alongside your executable or source file.

---

## Project Directory Structure

```text
pascal_block/
├── main.pas
├── raylib.dll
└── Raylib.4.0.Pascal/
    └── src/
        ├── Raylib.pas
        └── ...
```

DO THIS IN THE PROJECT DIRECTORY HARLY
```ps
fpc -Fu"Raylib.4.0.Pascal\src" main.pas
```

