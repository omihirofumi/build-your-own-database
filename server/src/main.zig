const std = @import("std");
const log = std.log;
const Io = std.Io;

const PORT = 8083;

fn read4bytes(reader: *std.Io.Reader) ![]u8 {
    return try reader.take(4);
}

fn handleStream(gpa: std.mem.Allocator, io: std.Io, stream: *std.Io.net.Stream) void {
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
    _ = std.fmt.parseUnsigned(u32, nstr, 10) catch {
        log.err("failed to parse nstr to int", .{});
        return;
    };
    var cmd = std.ArrayList(u8).initCapacity(gpa, 4) catch {
        log.err("failed to init array list(cmd)", .{});
        return;
    };
    defer cmd.deinit(gpa);

    const lenstr = read4bytes(in) catch |err| switch (err) {
        error.EndOfStream => {
            log.info("EOF", .{});
            return;
        },
        else => {
            log.err("read failed: {}", .{err});
            return;
        },
    };
    const len: u32 = std.fmt.parseUnsigned(u32, lenstr, 10) catch {
        log.err("failed to parse len", .{});
        return;
    };
    const body = in.peek(len) catch @panic("panic!!");
    // add to array

    std.debug.print("{s}\n", .{body});
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
        group.async(io, handleStream, .{ init.gpa, io, &stream });
    }

    try group.await(io);
}
