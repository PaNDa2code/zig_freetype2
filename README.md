# zig_freetype2

**zig_freetype2** is a minimal Zig wrapper around FreeType2, designed to make integrating FreeType into Zig projects easier.

---

## Usage

### 1. Add as a dependency

Use `zig fetch` to add the module to your project:

```bash
zig fetch --save git+https://github.com/PaNDa2code/zig_freetype2
```

---

### 2. Add to your build script

In your `build.zig` file:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const freetype = b.dependency("zig_freetype2", .{});
    const freetype_mod = freetype.module("zig_freetype2");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("freetype", freetype_mod);

    const exe = b.addExecutable(.{
        .name = "my_project",
        .root_module = exe_mod,
        .linkage = if (target.result.abi == .musl) .static else .dynamic,
    });

    b.installArtifact(exe);
}
```

### 3. Use in your project

Exmaple:
```zig
const std = @import("std");
const freetype = @import("freetype");

pub fn main() !void {
    const gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer gpa.deinit();

    const library = try freetype.Library.init(allocator);
    defer library.deinit();
    
    const face = try library.face("arial.ttf");
    const glyph = try face.getGlyph('A');
}
```
