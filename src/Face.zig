const Face = @This();

ft_face: c.FT_Face,

pub fn deinit(self: *const Face) void {
    _ = c.FT_Done_Face(self.ft_face);
}

pub fn iter(self: *const Face) !FaceIterator {
    var char_index: usize = 0;
    try ft_error.ftErrorFromInt(
        c.FT_Get_First_Char(self.ft_face, @ptrCast(&char_index)),
    );

    return .{
        .ft_face = self.ft_face,
        .index = char_index,
        .char_code = 0,
    };
}

pub fn getGlyph(self: *const Face, char_code: u32) !Glyph {
    var glyph: Glyph = undefined;
    const glyph_slot_ptr: *c.FT_GlyphSlotRec = @ptrCast(self.ft_face.*.glyph);

    try ft_error.ftErrorFromInt(
        c.FT_Load_Char(self.ft_face, char_code, c.FT_LOAD_NO_BITMAP),
    );

    try ft_error.ftErrorFromInt(
        c.FT_Get_Glyph(glyph_slot_ptr, @ptrCast(&glyph)),
    );

    return .{ .ft_glyph = glyph.ft_glyph };
}

pub fn getGlyphSlot(self: *const Face, char_code: u32) !*c.FT_GlyphSlotRec {
    const glyph_slot_ptr: *c.FT_GlyphSlotRec = @ptrCast(self.ft_face.*.glyph);

    try ft_error.ftErrorFromInt(
        c.FT_Load_Char(self.ft_face, char_code, c.FT_LOAD_RENDER),
    );

    return glyph_slot_ptr;
}

pub fn isFixedWidth(self: *const Face) bool {
    return c.FT_IS_FIXED_WIDTH(self.ft_face);
}

pub fn setCharSize(
    self: *const Face,
    char_width: u32,
    char_height: u32,
    horz_resolution: u32,
    vert_resolution: u32,
) !void {
    try ft_error.ftErrorFromInt(
        c.FT_Set_Char_Size(
            self.ft_face,
            @intCast(char_width),
            @intCast(char_height),
            horz_resolution,
            vert_resolution,
        ),
    );
}

pub fn setPixelSize(
    self: *const Face,
    pixel_width: u32,
    pixel_height: u32,
) !void {
    try ft_error.ftErrorFromInt(
        c.FT_Set_Pixel_Sizes(
            self.ft_face,
            pixel_width,
            pixel_height,
        ),
    );
}

pub fn glyphCount(self: *const Face) i64 {
    return self.ft_face.*.num_glyphs;
}

const std = @import("std");
const builtin = @import("builtin");

const c = @import("c.zig").c;

const ft_error = @import("ft_error.zig");

const Allocator = std.mem.Allocator;
const Glyph = @import("Glyph.zig");
const FaceIterator = @import("FaceIterator.zig");
