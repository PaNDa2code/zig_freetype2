const FaceIterator = @This();

ft_face: c.FT_Face,
char_code: usize,
index: usize,

pub fn next(self: *FaceIterator) void {
    self.char_code = @intCast(c.FT_Get_Next_Char(self.ft_face, self.char_code, @ptrCast(&self.index)));
}

const c = @import("c.zig").c;
