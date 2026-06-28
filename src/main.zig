const std = @import("std");
const log = std.log;
const Io = std.Io;

const PORT = 8083;

pub fn main(init: std.process.Init) !void {
    log.info("Listening on http://127.0.0.1:{d}", .{PORT});

    const io = init.io;
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", PORT);

    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    while (true) {
        log.info("Waiting for connection...", .{});
        var stream = try server.accept(io);
        defer stream.close(io);

        log.info("TCP connection established!", .{});

        var read_buf: [1024]u8 = undefined;
        var write_buf: [1024]u8 = undefined;
        var reader = stream.reader(io, &read_buf);
        var writer = stream.writer(io, &write_buf);

        var http_server = std.http.Server.init(&reader.interface, &writer.interface);
        var req = try http_server.receiveHead();
        log.info("header: \n", .{});
        log.info("{s}", .{req.head_buffer});

        try req.respond("hello", .{});
    }
}
