const std = @import("std");
const Frame = @import("Frame.zig").Frame;
const Socket = @import("Socket.zig").Socket;

pub fn main() !void {
    // --- Get interface name from command line arguments ---
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Usage: {s} <interface_name>\n", .{args[0]});
        return;
    }
    const interface_name = args[1];

    // Just sending, so filter any incoming packets
    const socket = try Socket.init(interface_name, 0);
    defer socket.deinit();

    std.debug.print("Made socket: {f}\n", .{socket});

    // --- Construct Ethernet Frame ---
    const payload: [16]u8 = .{ 'h', 'e', 'l', 'l', 'o', ',', ' ', 'e', 't', 'h', 'e', 'r', 'n', 'e', 't', '!' };
    const frame = Frame{
        .src_addr = socket.interface_mac[0..6].*,
        // broadcast address
        .dst_addr = @splat(0xff),
        // ether_type < 1500 indicates payload length
        .ether_type = @sizeOf(@TypeOf(payload)),
        .data = payload,
    };
    std.debug.print("We have a frame: {f}\n", .{frame});

    const frame_bytes = frame.pack();
    std.debug.print("The packed bytes are: {x}\n", .{frame_bytes});

    const sock_addr = std.os.linux.sockaddr.ll{
        .family = std.c.AF.PACKET,
        .protocol = std.mem.nativeToBig(u16, frame.ether_type),
        .ifindex = socket.interface_index,
        .hatype = 0,
        .pkttype = 0,
        .halen = 6,
        .addr = frame.dst_addr[0..6].* ++ .{ 0, 0 },
    };

    const bytes_sent = std.posix.sendto(socket.socket_filedescriptor, &frame_bytes, 0, @ptrCast(&sock_addr), @sizeOf(@TypeOf(sock_addr))) catch |err| {
        std.debug.print("Error: {any}\n", .{err});
        std.process.exit(1);
    };

    std.debug.print("Sent {d} bytes\n", .{bytes_sent});
}
