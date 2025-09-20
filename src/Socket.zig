const std = @import("std");

pub const Socket = struct {
    socket_filedescriptor: std.posix.socket_t,
    interface_index: c_int,
    interface_mac: [14]u8,

    pub fn init(interface_name: []u8, protocol: u16) !Socket {

        // AF_PACKET: Low-level packet interface
        // SOCK_RAW: Raw network protocol access
        // htons(ETH_P_ALL): All Ethernet protocols
        const socket_fd = try std.posix.socket(std.c.AF.PACKET, std.c.SOCK.RAW, std.mem.nativeToBig(u16, protocol));

        var ifreq = std.mem.zeroInit(std.posix.ifreq, .{});
        if (interface_name.len >= ifreq.ifrn.name.len) return error.InterfaceNameTooLong;
        @memcpy(ifreq.ifrn.name[0..interface_name.len], interface_name);

        const if_index = std.c.if_nametoindex(@ptrCast(&ifreq.ifrn.name));
        if (if_index == 0) {
            std.debug.print("Error: Could not find interface '{s}'\n", .{interface_name});
            return error.InterfaceNotFound;
        }

        // We can reuse the ifreq, it already has the name in it.
        const ret = std.os.linux.ioctl(socket_fd, std.os.linux.SIOCGIFHWADDR, @intFromPtr(&ifreq));
        if (ret < 0) {
            std.debug.print("Error calling ioctl: {any}\n", .{@as(std.os.linux.E, @enumFromInt(std.c._errno().*))});
            std.process.exit(1);
        }

        return Socket{
            .socket_filedescriptor = socket_fd,
            .interface_index = if_index,
            .interface_mac = ifreq.ifru.hwaddr.data,
        };
    }

    pub fn deinit(self: *const Socket) void {
        std.posix.close(self.socket_filedescriptor);
    }

    pub fn format(self: Socket, writer: anytype) !void {
        try writer.print("filedescriptor: {d}, interface_index: {d}, mac: {x:02}:{x:02}:{x:02}:{x:02}:{x:02}:{x:02}", .{
            self.socket_filedescriptor,
            self.interface_index,
            self.interface_mac[0],
            self.interface_mac[1],
            self.interface_mac[2],
            self.interface_mac[3],
            self.interface_mac[4],
            self.interface_mac[5],
        });
    }
};
