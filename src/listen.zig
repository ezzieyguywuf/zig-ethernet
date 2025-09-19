const std = @import("std");
const Socket = @import("Socket.zig").Socket;

// Import C headers for low-level socket programming
const c = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("linux/if_ether.h");
});

const Frame = @import("Frame.zig").Frame;
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

    // Filter incoming packets - only accept 0x0080 byte packets
    const socket = try Socket.init(interface_name, 0x0080);
    defer socket.deinit();

    std.debug.print("Made socket: {f}\n", .{socket});

    // --- Bind socket to the specific interface ---
    // This tells the kernel to only deliver packets from this interface.
    const bind_addr = std.os.linux.sockaddr.ll{
        .family = c.AF_PACKET,
        .protocol = std.mem.nativeToBig(u16, c.ETH_P_ALL),
        .ifindex = socket.interface_index,
        .hatype = 0,
        .pkttype = 0,
        .halen = 0,
        .addr = undefined,
    };

    try std.posix.bind(socket.socket_filedescriptor, @ptrCast(&bind_addr), @sizeOf(@TypeOf(bind_addr)));

    std.debug.print("Socket bound successfully. Listening for packets on {s}...\n", .{interface_name});

    // --- Receive Loop ---
    while (true) {
        var buffer: [2048]u8 = undefined;
        const bytes_read = try std.posix.recvfrom(socket.socket_filedescriptor, &buffer, 0, null, null);

        if (bytes_read < @sizeOf(Frame)) {
            std.debug.print("Runt frame, skipping\n", .{});
        }

        const received_frame = Frame.unpack(buffer[0..@sizeOf(Frame)]);
        std.debug.print("Unpacked Frame: {f}\n", .{received_frame});
    }
}
