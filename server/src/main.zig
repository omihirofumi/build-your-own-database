const std = @import("std");
const log = std.log;
const Io = std.Io;

const PORT = 8083;

fn read4bytes(reader: *std.Io.Reader) ![]u8 {
    return try reader.peek(4);
}

fn handleStream(io: std.Io, stream: *std.Io.net.Stream) void {
    defer stream.close(io);

    log.info("TCP connection established!", .{});

    var read_buf: [1024]u8 = undefined;
    // var chunks: [1][]u8 = .{read_buf[0..]};

    var reader = stream.reader(io, &read_buf);
    const in = &reader.interface;

    const nstr = read4bytes(in) catch |err| switch (err) {
        error.EndOfStream => {
            log.info("EOF", .{});
            return;
        },
        else => {
            log.err("read failed: {}", .{err});
            return;
        },
    };
    const n: u32 = std.fmt.parseUnsigned(u32, nstr, 10) catch {
        log.err("failed to parse nstr to int", .{});
        return;
    };

    std.debug.print("{d}\n", .{n});
}

pub fn main(init: std.process.Init) !void {
    log.info("Listening on http://127.0.0.1:{d}", .{PORT});

    const io = init.io;
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", PORT);

    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    var group: std.Io.Group = .init;
    defer group.cancel(io);

    while (true) {
        log.info("Waiting for connection...", .{});
        var stream = try server.accept(io);
        group.async(io, handleStream, .{ io, &stream });
    }

    try group.await(io);
}
