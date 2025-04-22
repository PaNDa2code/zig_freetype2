const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_freetype = b.dependency("freetype", .{});

    const freetype_lib = blk: {
        const freetype = b.addStaticLibrary(.{
            .name = "freetype2",
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });

        freetype.addCSourceFiles(.{
            .files = ft2_srcs,
            .flags = ft2_flags,
            .root = c_freetype.path("."),
        });

        const ftsys =
            switch (target.result.os.tag) {
                .windows => "builds/windows/ftsystem.c",
                else => "src/base/ftsystem.c",
            };

        freetype.addCSourceFile(.{
            .file = c_freetype.path(ftsys),
            .flags = ft2_flags,
        });

        if (optimize == .Debug) {
            const ftdbg: []const []const u8 =
                switch (target.result.os.tag) {
                    .windows => &.{ "builds/windows/ftdebug.c", "src/base/ftver.rc" },
                    else => &.{"src/base/ftdebug.c"},
                };

            freetype.addCSourceFiles(.{
                .files = ftdbg,
                .flags = ft2_flags,
                .root = c_freetype.path("."),
            });
        }

        freetype.addIncludePath(c_freetype.path("include"));

        break :blk freetype;
    };

    b.installArtifact(freetype_lib);

    const freetype_mod = b.addModule("zig_freetype2", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    freetype_mod.linkLibrary(freetype_lib);
    freetype_mod.addIncludePath(c_freetype.path("include"));

    const lib_unit_tests = b.addTest(.{
        .root_module = freetype_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

const ft2_srcs: []const []const u8 = &.{
    "src/autofit/autofit.c",
    "src/base/ftbase.c",
    "src/base/ftbbox.c",
    "src/base/ftbdf.c",
    "src/base/ftbitmap.c",
    "src/base/ftcid.c",
    "src/base/ftfstype.c",
    "src/base/ftgasp.c",
    "src/base/ftglyph.c",
    "src/base/ftgxval.c",
    "src/base/ftinit.c",
    "src/base/ftmm.c",
    "src/base/ftotval.c",
    "src/base/ftpatent.c",
    "src/base/ftpfr.c",
    "src/base/ftstroke.c",
    "src/base/ftsynth.c",
    "src/base/fttype1.c",
    "src/base/ftwinfnt.c",
    "src/bdf/bdf.c",
    "src/bzip2/ftbzip2.c",
    "src/cache/ftcache.c",
    "src/cff/cff.c",
    "src/cid/type1cid.c",
    "src/gzip/ftgzip.c",
    "src/lzw/ftlzw.c",
    "src/pcf/pcf.c",
    "src/pfr/pfr.c",
    "src/psaux/psaux.c",
    "src/pshinter/pshinter.c",
    "src/psnames/psnames.c",
    "src/raster/raster.c",
    "src/sdf/sdf.c",
    "src/sfnt/sfnt.c",
    "src/smooth/smooth.c",
    "src/svg/svg.c",
    "src/truetype/truetype.c",
    "src/type1/type1.c",
    "src/type42/type42.c",
    "src/winfonts/winfnt.c",
};

const ft2_flags: []const []const u8 = &.{
    "-DFT2_BUILD_LIBRARY",
    "-O3",
    "-ffunction-sections",
    "-fdata-sections",
};
