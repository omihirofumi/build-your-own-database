const std = @import("std");
const Io = std.Io;

const client = @import("client");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const peer = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8083);
    const stream = try peer.connect(io, .{ .mode = .stream });
    defer stream.close(io);

    var buf: [1024]u8 = undefined;
    var writer = stream.writer(io, &buf);
    const out = &writer.interface;

    try out.writeAll("1234");
    try out.flush();
}

// nstr | len | str1 | len | str2 | ...
//   4B    4B           4B
const Body = struct { len: u32, str: []const u8 };
const Data = struct {
    nstr: u32,
    body: []Body,
};
