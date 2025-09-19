const std = @import("std");

pub const Frame = struct {
    dst_addr: [6]u8,
    src_addr: [6]u8,
    ether_type: u16,
    data: [16]u8,

    pub fn format(self: Frame, writer: anytype) !void {
        try writer.print("dst: {x:02}:{x:02}:{x:02}:{x:02}:{x:02}:{x:02}", .{ self.dst_addr[0], self.dst_addr[1], self.dst_addr[2], self.dst_addr[3], self.dst_addr[4], self.dst_addr[5] });
        try writer.print(", src: {x:02}:{x:02}:{x:02}:{x:02}:{x:02}:{x:02}", .{ self.src_addr[0], self.src_addr[1], self.src_addr[2], self.src_addr[3], self.src_addr[4], self.src_addr[5] });
        try writer.print(", type: 0x{x:04}", .{self.ether_type});
        try writer.print(", data: {s}", .{self.data});
    }

    pub fn pack(self: Frame) [30]u8 {
        var bytes = std.mem.zeroes([30]u8);
        @memcpy(bytes[0..6], &self.dst_addr);
        @memcpy(bytes[6..12], &self.src_addr);
        std.mem.writeInt(u16, bytes[12..14], self.ether_type, .big);
        @memcpy(bytes[14..30], &self.data);

        return bytes;
    }

    pub fn unpack(bytes: *const [30]u8) Frame {
        var frame: Frame = undefined;
        @memcpy(&frame.dst_addr, bytes[0..6]);
        @memcpy(&frame.src_addr, bytes[6..12]);
        frame.ether_type = std.mem.readInt(u16, bytes[12..14], .big);
        @memcpy(&frame.data, bytes[14..30]);

        return frame;
    }
};
