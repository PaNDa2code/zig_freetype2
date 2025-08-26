const Glyph = @This();

ft_glyph: FT_Glyph,

pub fn glyphBitmap(self: *Glyph) !FT_BitmapGlyph {
    if (self.ft_glyph.format != .Bitmap) {
        try ft_error.ftErrorFromInt(
            c.FT_Glyph_To_Bitmap(@ptrCast(self.ft_glyph), c.FT_RENDER_MODE_NORMAL, null, 1),
        );
    }
    return @ptrCast(self.ft_glyph);
}

pub fn glyphOutline(self: *Glyph) !FT_OutlineGlyph {
    if (self.ft_glyph.format != .Outline) {
        unreachable;
    }
    return @ptrCast(self.ft_glyph);
}

pub fn deinit(self: *const Glyph) void {
    _ = c.FT_Done_Glyph(@ptrCast(self.ft_glyph));
}

const GlyphFormat = enum(c_int) {
    None = c.FT_GLYPH_FORMAT_NONE,
    Composite = c.FT_GLYPH_FORMAT_COMPOSITE,
    Bitmap = c.FT_GLYPH_FORMAT_BITMAP,
    Outline = c.FT_GLYPH_FORMAT_OUTLINE,
    Plotter = c.FT_GLYPH_FORMAT_PLOTTER,
    Svg = c.FT_GLYPH_FORMAT_SVG,
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

pub const FT_Outline = extern struct {
    n_contoures: u16,
    n_points: u16,
    points: [*]c.FT_Vector,
    tags: [*]Tag,
    contoures: [*]u16,
    flags: Flags,

    pub const Tag = packed struct {
        on_curve: bool,
        third_order: bool,
        dropout_flag: bool,
        _reserved: u2,
        dropout_mode: u3,
    };

    pub const Flags = packed struct {
        owner: bool,
        even_odd_fill: bool,
        reverse_fill: bool,
        ignore_dropouts: bool,
        smart_dropouts: bool,
        include_stubs: bool,
        overlap: bool,
        _padding1: u1,
        high_precision: bool,
        single_pass: bool,
        _padding2: u22,
    };
};

pub const FT_OutlineGlyphRec = extern struct {
    root: FT_GlyphRec,
    outline: FT_Outline,
};
pub const FT_OutlineGlyph = *FT_OutlineGlyphRec;

const c = @import("root").c;
const ft_error = @import("ft_error.zig");
