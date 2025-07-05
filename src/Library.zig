const Library = @This();

allocator: *Allocator,
ft_library: c.FT_Library,
ft_memory: c.FT_Memory,

const max_alignment = if (@bitSizeOf(usize) == 64) 16 else 8;

pub fn init(allocator: Allocator) !Library {
    const allocator_ptr = try allocator.create(Allocator);
    errdefer allocator.destroy(allocator_ptr);

    allocator_ptr.* = allocator;

    const ft_memory = try allocator.create(c.FT_MemoryRec_);
    errdefer allocator.destroy(ft_memory);

    ft_memory.* = .{
        .user = allocator_ptr,
        .alloc = &ftAlloc,
        .free = &ftFree,
        .realloc = &ftRealloc,
    };

    var ft_library: c.FT_Library = null;

    const ft_err: c.FT_Error = c.FT_New_Library(ft_memory, &ft_library);
    try ft_error.ftErrorFromInt(ft_err);

    c.FT_Add_Default_Modules(ft_library);

    return .{
        .allocator = allocator_ptr,
        .ft_library = ft_library,
        .ft_memory = ft_memory,
    };
}

pub fn deinit(self: *const Library) void {
    // Copy the allocator to the stack before freeing the it's own heap buffer
    const allocator = self.allocator.*;
    _ = c.FT_Done_Library(self.ft_library);
    allocator.destroy(@as(*Allocator, @ptrCast(@alignCast(self.ft_memory.*.user))));
    allocator.destroy(@as(*c.FT_MemoryRec_, @ptrCast(self.ft_memory)));
}

pub fn face(self: *const Library, font_path: []const u8, size: u32) !Face {
    const pathz = try std.fs.path.joinZ(self.allocator.*, &.{font_path});
    defer self.allocator.free(pathz);

    var ft_face: c.FT_Face = null;
    try ft_error.ftErrorFromInt(
        c.FT_New_Face(self.ft_library, pathz.ptr, 0, &ft_face),
    );

    try ft_error.ftErrorFromInt(
        c.FT_Set_Pixel_Sizes(ft_face, @intCast(size), @intCast(size)),
    );

    return .{ .ft_face = ft_face };
}

pub fn memoryFace(self: *const Library, font_ttf: []const u8, size: u32) !Face {
    var ft_face: c.FT_Face = null;
    try ft_error.ftErrorFromInt(
        c.FT_New_Memory_Face(self.ft_library, font_ttf.ptr, @intCast(font_ttf.len), 0, &ft_face),
    );

    try ft_error.ftErrorFromInt(
        c.FT_Set_Pixel_Sizes(ft_face, @intCast(size), @intCast(size)),
    );

    return .{ .ft_face = ft_face };
}

// Writes the total size of the allocation into the beginning of the block_ptr
// (includeing the header size).
// Returns the slice after the size header.
fn addSizeHeader(block: []u8, header: usize) []u8 {
    std.mem.writeInt(usize, @ptrCast(block.ptr), header, .little);
    return block[@sizeOf(usize)..];
}

// Retrieves the full slice including the header, using the pointer returned to the user.
// The size is read from the header just before the actual data pointer.
fn getSizedSlice(ptr: *anyopaque) []u8 {
    const block_ptr: [*]u8 = @ptrFromInt(@intFromPtr(ptr) - @sizeOf(usize));
    const total_size = std.mem.readInt(usize, @ptrCast(block_ptr), .little);
    return block_ptr[0..total_size];
}

// Allocator callback for FreeType: allocates memory with extra space for the size header.
// Returns a pointer to the usable memory (after the header).
// TODO: Ensure returned pointer is properly aligned after offsetting for the size header.
fn ftAlloc(ft_memory: c.FT_Memory, size: c_long) callconv(.c) ?*anyopaque {
    const allocator: *Allocator = @alignCast(@ptrCast(ft_memory.*.user));
    const total_size: usize = @intCast(size + @sizeOf(usize));
    const buffer = allocator.alloc(u8, total_size) catch return null;
    const ptr = addSizeHeader(buffer, total_size).ptr;
    return ptr;
}

// Allocator callback for FreeType: frees memory previously allocated by ftAlloc.
// Retrieves the full slice including the size header and frees it.
fn ftFree(ft_memory: c.FT_Memory, block_ptr: ?*anyopaque) callconv(.c) void {
    const allocator: *Allocator = @alignCast(@ptrCast(ft_memory.*.user));
    const block = getSizedSlice(block_ptr.?);
    allocator.free(block);
}

// Allocator callback for FreeType: reallocates memory, preserving data and updating the size header.
// Asserts that the original size matches what was stored, resizes the block, and rewrites the header.
fn ftRealloc(ft_memory: c.FT_Memory, cur_size: c_long, new_size: c_long, block_ptr: ?*anyopaque) callconv(.c) ?*anyopaque {
    const allocator: *Allocator = @alignCast(@ptrCast(ft_memory.*.user));
    const old_block = getSizedSlice(block_ptr.?);
    std.debug.assert(old_block.len == cur_size + @sizeOf(usize));
    const new_total_size: usize = @intCast(new_size + @sizeOf(usize));
    const new_block = allocator.realloc(old_block, new_total_size) catch return null;
    return addSizeHeader(new_block, new_total_size).ptr;
}

const std = @import("std");
const builtin = @import("builtin");

const c = @import("c.zig");

const ft_error = @import("ft_error.zig");

const Allocator = std.mem.Allocator;
const Face = @import("Face.zig");
