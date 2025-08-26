const std = @import("std");
const builtin = @import("builtin");

pub const c = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("freetype/ftmodapi.h");
    @cInclude("freetype/ftglyph.h");
});

const ft_error = @import("ft_error.zig");

const Allocator = std.mem.Allocator;

const TEST_FONT_FILE = switch (builtin.os.tag) {
    .windows => "C:\\windows\\Fonts\\arial.ttf",
    .linux => "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    else => "",
};

pub const Error = ft_error.FreeTypeError;

/// FreeType library wrapper struct to be able to use zig allocation interfaces
pub const Library = @import("Library.zig");

test "Library" {
    const ft_lib = try Library.init(std.testing.allocator);
    defer ft_lib.deinit();
}

pub const Face = @import("Face.zig");

test "Face" {
    const ft_lib = try Library.init(std.testing.allocator);
    defer ft_lib.deinit();

    const face = ft_lib.face(TEST_FONT_FILE, 32) catch |e| {
        std.log.err("freetype {}", .{e});
        return e;
    };
    defer face.deinit();
}

pub const Glyph = @import("Glyph.zig");
