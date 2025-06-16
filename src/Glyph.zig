const Glyph = @This();

ft_glyph: FT_Glyph,

pub fn glyphBitmap(self: *Glyph) !FT_BitmapGlyph {
    if (self.ft_glyph.format != .BITMAP) {
        try ft_error.ftErrorFromInt(
            c.FT_Glyph_To_Bitmap(@ptrCast(self.ft_glyph), c.FT_RENDER_MODE_NORMAL, null, 1),
        );
    }
    return @ptrCast(self.ft_glyph);
}

pub fn deinit(self: *const Glyph) void {
    _ = c.FT_Done_Glyph(@ptrCast(self.ft_glyph));
}

const GlyphFormat = enum(c_int) {
    NONE = c.FT_GLYPH_FORMAT_NONE,
    COMPOSITE = c.FT_GLYPH_FORMAT_COMPOSITE,
    BITMAP = c.FT_GLYPH_FORMAT_BITMAP,
    OUTLINE = c.FT_GLYPH_FORMAT_OUTLINE,
    PLOTTER = c.FT_GLYPH_FORMAT_PLOTTER,
    SVG = c.FT_GLYPH_FORMAT_SVG,
};

pub const FT_GlyphRec = extern struct {
    ft_library: c.FT_Library,
    clazz: usize, // Privte pointer
    format: GlyphFormat,
    advance: c.FT_Vector,
};
pub const FT_Glyph = *FT_GlyphRec;

pub const FT_BitmapGlyphRec = extern struct {
    root: FT_GlyphRec,
    left: i32,
    top: i32,
    bitmap: FT_Bitmap,
};
pub const FT_BitmapGlyph = *FT_BitmapGlyphRec;

pub const FT_Bitmap = extern struct {
    rows: u32,
    width: u32,
    pitch: i32,
    buffer: ?[*]u8,
    num_grays: u16,
    pixel_mode: u8,
    palette_mode: u8,
    palette: ?*anyopaque,
};

const c = @import("c.zig");
const ft_error = @import("ft_error.zig");
