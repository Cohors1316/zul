const std = @import("std");
const builtin = @import("builtin");

const Endian = std.builtin.Endian;
const Allocator = std.mem.Allocator;

pub const View = struct {
	pos: usize,
	sb: *StringBuilder,

	pub fn writeByte(self: *View, b: u8) void {
		const pos = self.pos;
		writeByteInto(self.sb.buf, pos, b);
		self.pos = pos + 1;
	}

	pub fn writeByteNTimes(self: *View, b: u8, n: usize) void {
		const pos = self.pos;
		writeByteNTimesInto(self.sb.buf, pos, b, n);
		self.pos = pos + n;
	}

	pub fn write(self: *View, data: []const u8) void {
		const pos = self.pos;
		writeInto(self.sb.buf, pos, data);
		self.pos = pos + data.len;
	}

	pub fn writeU16(self: *View, value: u16) void {
		return self.writeIntT(u16, value, self.endian);
	}

	pub fn writeI16(self: *View, value: i16) void {
		return self.writeIntT(i16, value, self.endian);
	}

	pub fn writeU32(self: *View, value: u32) void {
		return self.writeIntT(u32, value, self.endian);
	}

	pub fn writeI32(self: *View, value: i32) void {
		return self.writeIntT(i32, value, self.endian);
	}

	pub fn writeU64(self: *View, value: u64) void {
		return self.writeIntT(u64, value, self.endian);
	}

	pub fn writeI64(self: *View, value: i64) void {
		return self.writeIntT(i64, value, self.endian);
	}

	pub fn writeU16Little(self: *View, value: u16) void {
		return self.writeIntT(u16, value, .little);
	}

	pub fn writeI16Little(self: *View, value: i16) void {
		return self.writeIntT(i16, value, .little);
	}

	pub fn writeU32Little(self: *View, value: u32) void {
		return self.writeIntT(u32, value, .little);
	}

	pub fn writeI32Little(self: *View, value: i32) void {
		return self.writeIntT(i32, value, .little);
	}

	pub fn writeU64Little(self: *View, value: u64) void {
		return self.writeIntT(u64, value, .little);
	}

	pub fn writeI64Little(self: *View, value: i64) void {
		return self.writeIntT(i64, value, .little);
	}

	pub fn writeU16Big(self: *View, value: u16) void {
		return self.writeIntT(u16, value, .big);
	}

	pub fn writeI16Big(self: *View, value: i16) void {
		return self.writeIntT(i16, value, .big);
	}

	pub fn writeU32Big(self: *View, value: u32) void {
		return self.writeIntT(u32, value, .big);
	}

	pub fn writeI32Big(self: *View, value: i32) void {
		return self.writeIntT(i32, value, .big);
	}

	pub fn writeU64Big(self: *View, value: u64) void {
		return self.writeIntT(u64, value, .big);
	}

	pub fn writeI64Big(self: *View, value: i64) void {
		return self.writeIntT(i64, value, .big);
	}

	fn writeIntT(self: *View, comptime T: type, value: T, endian: Endian) void {
		const l = @divExact(@typeInfo(T).Int.bits, 8);
		const pos = self.pos;
		writeIntInto(T, self.sb.buf, pos, value, l, endian);
		self.pos = pos + l;
	}

	pub fn writeInt(self: *View, value: anytype) void {
		return self.writeIntAs(value, self.endian);
	}

	pub fn writeIntAs(self: *View, value: anytype, endian: Endian) void {
		const T = @TypeOf(value);
		switch (@typeInfo(T)) {
			.ComptimeInt => @compileError("Writing a comptime_int is slightly ambiguous, please cast to a specific type: sb.writeInt(@as(i32, 9001))"),
			.Int => |int| {
				if (int.signedness == .signed) {
					switch (int.bits) {
						8 => return self.writeByte(value),
						16 => return self.writeIntT(i16, value, endian),
						32 => return self.writeIntT(i32, value, endian),
						64 => return self.writeIntT(i64, value, endian),
						else => {},
					}
				} else {
					switch (int.bits) {
						8 => return self.writeByte(value),
						16 => return self.writeIntT(u16, value, endian),
						32 => return self.writeIntT(u32, value, endian),
						64 => return self.writeIntT(u64, value, endian),
						else => {},
					}
				}
			},
			else => {},
		}
		@compileError("Unsupported integer type: " ++ @typeName(T));
	}
};

pub const StringBuilder = struct {
	buf: []u8,
	pos: usize,
	endian: Endian,
	allocator: Allocator,

	pub fn init(allocator: Allocator) StringBuilder {
		return .{
			.pos = 0,
			.buf = &[_]u8{},
			.allocator = allocator,
			.endian = builtin.cpu.arch.endian(),
		};
	}

	pub fn deinit(self: StringBuilder) void {
		self.allocator.free(self.buf);
	}

	pub fn clearRetainingCapacity(self: *StringBuilder) void {
		self.pos = 0;
	}

	pub fn len(self: StringBuilder) usize {
		return self.pos;
	}

	pub fn string(self: StringBuilder) []u8 {
		return self.buf[0..self.pos];
	}

	pub fn copy(self: StringBuilder, allocator: Allocator) ![]u8 {
		const pos = self.pos;
		const c = try allocator.alloc(u8, pos);
		@memcpy(c, self.buf[0..pos]);
		return c;
	}

	pub fn truncate(self: *StringBuilder, n: usize) void {
		const pos = self.pos;
		if (n >= pos) {
			self.pos = 0;
			return;
		}
		self.pos = pos - n;
	}

	pub fn skip(self: *StringBuilder, n: usize) !View {
		try self.ensureUnusedCapacity(n);
		const pos = self.pos;
		self.pos = pos + n;
		return .{
			.pos = pos,
			.sb = self,
		};
	}

	pub fn writeByte(self: *StringBuilder, b: u8) !void {
		try self.ensureUnusedCapacity(b);
		self.writeByteAssumeCapacity(b);
	}

	pub fn writeByteAssumeCapacity(self: *StringBuilder, b: u8) void {
		const pos = self.pos;
		writeByteInto(self.buf, pos, b);
		self.pos = pos + 1;
	}

	pub fn writeByteNTimes(self: *StringBuilder, b: u8, n: usize) !void {
		try self.ensureUnusedCapacity(n);
		const pos = self.pos;
		writeByteNTimesInto(self.buf, pos, b, n);
		self.pos = pos + n;
	}

	pub fn write(self: *StringBuilder, data: []const u8) !void {
		try self.ensureUnusedCapacity(data.len);
		self.writeAssumeCapacity(data);
	}

	pub fn writeAssumeCapacity(self: *StringBuilder, data:[] const u8) void {
		const pos = self.pos;
		writeInto(self.buf, pos, data);
		self.pos = pos + data.len;
	}

	pub fn writeU16(self: *StringBuilder, value: u16) !void {
		return self.writeIntT(u16, value, self.endian);
	}

	pub fn writeI16(self: *StringBuilder, value: i16) !void {
		return self.writeIntT(i16, value, self.endian);
	}

	pub fn writeU32(self: *StringBuilder, value: u32) !void {
		return self.writeIntT(u32, value, self.endian);
	}

	pub fn writeI32(self: *StringBuilder, value: i32) !void {
		return self.writeIntT(i32, value, self.endian);
	}

	pub fn writeU64(self: *StringBuilder, value: u64) !void {
		return self.writeIntT(u64, value, self.endian);
	}

	pub fn writeI64(self: *StringBuilder, value: i64) !void {
		return self.writeIntT(i64, value, self.endian);
	}

	pub fn writeU16Little(self: *StringBuilder, value: u16) !void {
		return self.writeIntT(u16, value, .little);
	}

	pub fn writeI16Little(self: *StringBuilder, value: i16) !void {
		return self.writeIntT(i16, value, .little);
	}

	pub fn writeU32Little(self: *StringBuilder, value: u32) !void {
		return self.writeIntT(u32, value, .little);
	}

	pub fn writeI32Little(self: *StringBuilder, value: i32) !void {
		return self.writeIntT(i32, value, .little);
	}

	pub fn writeU64Little(self: *StringBuilder, value: u64) !void {
		return self.writeIntT(u64, value, .little);
	}

	pub fn writeI64Little(self: *StringBuilder, value: i64) !void {
		return self.writeIntT(i64, value, .little);
	}

	pub fn writeU16Big(self: *StringBuilder, value: u16) !void {
		return self.writeIntT(u16, value, .big);
	}

	pub fn writeI16Big(self: *StringBuilder, value: i16) !void {
		return self.writeIntT(i16, value, .big);
	}

	pub fn writeU32Big(self: *StringBuilder, value: u32) !void {
		return self.writeIntT(u32, value, .big);
	}

	pub fn writeI32Big(self: *StringBuilder, value: i32) !void {
		return self.writeIntT(i32, value, .big);
	}

	pub fn writeU64Big(self: *StringBuilder, value: u64) !void {
		return self.writeIntT(u64, value, .big);
	}

	pub fn writeI64Big(self: *StringBuilder, value: i64) !void {
		return self.writeIntT(i64, value, .big);
	}

	fn writeIntT(self: *StringBuilder, comptime T: type, value: T, endian: Endian) !void {
		const l = @divExact(@typeInfo(T).Int.bits, 8);
		try self.ensureUnusedCapacity(l);
		const pos = self.pos;
		writeIntInto(T, self.buf, pos, value, l, endian);
		self.pos = pos + l;
	}

	pub fn writeInt(self: *StringBuilder, value: anytype) !void {
		return self.writeIntAs(value, self.endian);
	}

	pub fn writeIntAs(self: *StringBuilder, value: anytype, endian: Endian) !void {
		const T = @TypeOf(value);
		switch (@typeInfo(T)) {
			.ComptimeInt => @compileError("Writing a comptime_int is slightly ambiguous, please cast to a specific type: sb.writeInt(@as(i32, 9001))"),
			.Int => |int| {
				if (int.signedness == .signed) {
					switch (int.bits) {
						8 => return self.writeByte(value),
						16 => return self.writeIntT(i16, value, endian),
						32 => return self.writeIntT(i32, value, endian),
						64 => return self.writeIntT(i64, value, endian),
						else => {},
					}
				} else {
					switch (int.bits) {
						8 => return self.writeByte(value),
						16 => return self.writeIntT(u16, value, endian),
						32 => return self.writeIntT(u32, value, endian),
						64 => return self.writeIntT(u64, value, endian),
						else => {},
					}
				}
			},
			else => {},
		}
		@compileError("Unsupported integer type: " ++ @typeName(T));
	}


	pub fn ensureUnusedCapacity(self: *StringBuilder, n: usize) !void {
		return self.ensureTotalCapacity(self.pos + n);
	}

	pub fn ensureTotalCapacity(self: *StringBuilder, required_capacity: usize) !void {
		const buf = self.buf;
		if (required_capacity <= buf.len) {
			return;
		}

		// from std.ArrayList
		var new_capacity = buf.len;
		while (true) {
			new_capacity +|= new_capacity / 2 + 8;
			if (new_capacity >= required_capacity) break;
		}

		const allocator = self.allocator;
		if (allocator.resize(buf, new_capacity)) {
			self.buf = buf.ptr[0..new_capacity];
			return;
		}
		const new_buffer = try allocator.alloc(u8, new_capacity);
		@memcpy(new_buffer[0..buf.len], buf);
		allocator.free(buf);
		self.buf = new_buffer;
	}

	pub fn writer(self: *StringBuilder) Writer.IOWriter {
			return .{.context = Writer.init(self)};
		}

	pub const Writer = struct {
		sb: *StringBuilder,

		pub const Error = Allocator.Error;
		pub const IOWriter = std.io.Writer(Writer, error{OutOfMemory}, Writer.write);

		fn init(sb: *StringBuilder) Writer {
			return .{.sb = sb};
		}

		pub fn write(self: Writer, data: []const u8) Allocator.Error!usize {
			try self.sb.write(data);
			return data.len;
		}
	};
};

// Functions that write for either a *StringBuilder or a *View
inline fn writeInto(buf: []u8, pos: usize, data: []const u8) void {
	const end_pos = pos + data.len;
	@memcpy(buf[pos..end_pos], data);
}

inline fn writeByteInto(buf: []u8, pos: usize, b: u8) void {
	buf[pos] = b;
}

inline fn writeByteNTimesInto(buf: []u8, pos: usize, b: u8, n: usize) void {
	for (0..n) |offset| {
		buf[pos+offset] = b;
	}
}

inline fn writeIntInto(comptime T: type, buf: []u8, pos: usize, value: T, l: usize, endian: Endian) void {
	const end_pos = pos + l;
	std.mem.writeInt(T, buf[pos..end_pos][0..l], value, endian);
}

const t = @import("zul.zig").testing;

test "StringBuilder: growth" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	// we clearRetainingCapacity at the end of the loop, and things should work
	// the same the second time
	for (0..2) |_| {
		try t.expectEqual(0, sb.len());
		try sb.writeByte('o');
		try t.expectEqual(1, sb.len());
		try t.expectEqual("o", sb.string());

		// stays in static
		try sb.write("ver 9000!");
		try t.expectEqual(10, sb.len());
		try t.expectEqual("over 9000!", sb.string());

		// grows into dynamic
		try sb.write("!!!");
		try t.expectEqual(13, sb.len());
		try t.expectEqual("over 9000!!!!", sb.string());


		try sb.write("If you were to run this code, you'd almost certainly see a segmentation fault (aka, segfault). We create a Response which involves creating an ArenaAllocator and from that, an Allocator. This allocator is then used to format our string. For the purpose of this example, we create a 2nd response and immediately free it. We need this for the same reason that warning1 in our first example printed an almost ok value: we want to re-initialize the memory in our init function stack.");
		try t.expectEqual(492, sb.len());
		try t.expectEqual("over 9000!!!!If you were to run this code, you'd almost certainly see a segmentation fault (aka, segfault). We create a Response which involves creating an ArenaAllocator and from that, an Allocator. This allocator is then used to format our string. For the purpose of this example, we create a 2nd response and immediately free it. We need this for the same reason that warning1 in our first example printed an almost ok value: we want to re-initialize the memory in our init function stack.", sb.string());

		sb.clearRetainingCapacity();
	}
}

test "StringBuilder: truncate" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	sb.truncate(100);
	try t.expectEqual(0, sb.len());

	try sb.write("hello world!1");

	sb.truncate(0);
	try t.expectEqual(13, sb.len());
	try t.expectEqual("hello world!1", sb.string());

	sb.truncate(1);
	try t.expectEqual(12, sb.len());
	try t.expectEqual("hello world!", sb.string());

	sb.truncate(5);
	try t.expectEqual(7, sb.len());
	try t.expectEqual("hello w", sb.string());
}

test "StringBuilder: fuzz" {
	defer t.reset();

	var control = std.ArrayList(u8).init(t.allocator);
	defer control.deinit();

	for (1..25) |_| {
		var sb = StringBuilder.init(t.allocator);
		defer sb.deinit();

		for (1..25) |_| {
			var buf: [30]u8 = undefined;
			const input = t.Random.fillAtLeast(&buf, 1);
			try sb.write(input);
			try control.appendSlice(input);
			try t.expectEqual(control.items, sb.string());
		}
		control.clearRetainingCapacity();
	}
}

test "StringBuilder: writer" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	try std.json.stringify(.{.over = 9000, .spice = "must flow", .ok = true}, .{}, sb.writer());
	try t.expectEqual("{\"over\":9000,\"spice\":\"must flow\",\"ok\":true}", sb.string());
}

test "StringBuilder: copy" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	try sb.write("hello!!");
	const c = try sb.copy(t.allocator);
	defer t.allocator.free(c);
	try t.expectEqual("hello!!", c);
}

test "StringBuilder: write little" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	{
		// unsigned
		try sb.writeU64Little(11234567890123456789);
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155}, sb.string());

		try sb.writeU32Little(3283856184);
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155, 56, 171, 187, 195}, sb.string());

		try sb.writeU16Little(15000);
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155, 56, 171, 187, 195, 152, 58}, sb.string());
	}

	{
		// signed
		sb.clearRetainingCapacity();
		try sb.writeI64Little(-1123456789012345678);
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240}, sb.string());

		try sb.writeI32Little(-328385618);
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240, 174, 59, 109, 236}, sb.string());

		try sb.writeI16Little(-15001);
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240, 174, 59, 109, 236, 103, 197}, sb.string());
	}

	{
		// writeXYZ with sb.endian == .litle, unsigned
		sb.clearRetainingCapacity();
		sb.endian = .little;
		try sb.writeU64(11234567890123456789);
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155}, sb.string());

		try sb.writeU32(3283856184);
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155, 56, 171, 187, 195}, sb.string());

		try sb.writeU16(15000);
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155, 56, 171, 187, 195, 152, 58}, sb.string());
	}

	{
		// writeXYZ with sb.endian == .litle, signed
		sb.clearRetainingCapacity();
		sb.endian = .little;
		try sb.writeI64(-1123456789012345678);
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240}, sb.string());

		try sb.writeI32(-328385618);
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240, 174, 59, 109, 236}, sb.string());

		try sb.writeI16(-15001);
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240, 174, 59, 109, 236, 103, 197}, sb.string());
	}

	{
		// writeInt with sb.endian == .litle, unsigned
		sb.clearRetainingCapacity();
		sb.endian = .little;
		try sb.writeInt(@as(u64, 11234567890123456789));
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155}, sb.string());

		try sb.writeInt(@as(u32, 3283856184));
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155, 56, 171, 187, 195}, sb.string());

		try sb.writeInt(@as(u16, 15000));
		try t.expectEqual(&[_]u8{21, 129, 209, 7, 249, 51, 233, 155, 56, 171, 187, 195, 152, 58}, sb.string());
	}

	{
		// writeInt with sb.endian == .litle, signed
		sb.clearRetainingCapacity();
		sb.endian = .little;
		try sb.writeInt(@as(i64, -1123456789012345678));
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240}, sb.string());

		try sb.writeInt(@as(i32, -328385618));
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240, 174, 59, 109, 236}, sb.string());

		try sb.writeInt(@as(i16, -15001));
		try t.expectEqual(&[_]u8{178, 12, 107, 178, 0, 174, 104, 240, 174, 59, 109, 236, 103, 197}, sb.string());
	}
}

test "StringBuilder: write big" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();
	{
		// unsigned
		try sb.writeU64Big(11234567890123456789);
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21}, sb.string());

		try sb.writeU32Big(3283856184);
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21, 195, 187, 171, 56}, sb.string());

		try sb.writeU16Big(15000);
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21, 195, 187, 171, 56, 58, 152}, sb.string());
	}

	{
		// signed
		sb.clearRetainingCapacity();
		try sb.writeI64Big(-1123456789012345678);
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178}, sb.string());

		try sb.writeI32Big(-328385618);
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178, 236, 109, 59, 174}, sb.string());

		try sb.writeI16Big(-15001);
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178, 236, 109, 59, 174, 197, 103}, sb.string());
	}

	{
		// writeXYZ with sb.endian == .litle, unsigned
		sb.clearRetainingCapacity();
		sb.endian = .big;
		try sb.writeU64(11234567890123456789);
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21}, sb.string());

		try sb.writeU32(3283856184);
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21, 195, 187, 171, 56}, sb.string());

		try sb.writeU16(15000);
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21, 195, 187, 171, 56, 58, 152}, sb.string());
	}

	{
		// writeXYZ with sb.endian == .litle, signed
		sb.clearRetainingCapacity();
		sb.endian = .big;
		try sb.writeI64(-1123456789012345678);
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178}, sb.string());

		try sb.writeI32(-328385618);
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178, 236, 109, 59, 174}, sb.string());

		try sb.writeI16(-15001);
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178, 236, 109, 59, 174, 197, 103}, sb.string());
	}

	{
		// wrinteInt with sb.endian == .big, unsigned
		sb.clearRetainingCapacity();
		sb.endian = .big;
		try sb.writeInt(@as(u64, 11234567890123456789));
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21}, sb.string());

		try sb.writeInt(@as(u32, 3283856184));
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21, 195, 187, 171, 56}, sb.string());

		try sb.writeInt(@as(u16, 15000));
		try t.expectEqual(&[_]u8{155, 233, 51, 249, 7, 209, 129, 21, 195, 187, 171, 56, 58, 152}, sb.string());
	}

	{
		// writeInt with sb.endian == .big, signed
		sb.clearRetainingCapacity();
		sb.endian = .big;
		try sb.writeInt(@as(i64, -1123456789012345678));
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178}, sb.string());

		try sb.writeInt(@as(i32, -328385618));
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178, 236, 109, 59, 174}, sb.string());

		try sb.writeInt(@as(i16, -15001));
		try t.expectEqual(&[_]u8{240, 104, 174, 0, 178, 107, 12, 178, 236, 109, 59, 174, 197, 103}, sb.string());
	}
}

test "StringBuilder: skip" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	{
		try sb.writeByte('!');
		var view = try sb.skip(3);
		view.write("123");

		try t.expectEqual("!123", sb.string());
	}

	{
		sb.clearRetainingCapacity();
		try sb.writeByte('D');
		var view = try sb.skip(2);
		view.writeU16Little(9001);
		try t.expectEqual(&.{'D', 41, 35}, sb.string());
	}
}

test "StringBuilder: doc example" {
	var sb = StringBuilder.init(t.allocator);
	defer sb.deinit();

	var view = try sb.skip(4);
	try sb.writeByte(10);
	try sb.write("hello");
	view.writeU32Big(@intCast(sb.len() - 4));
	try t.expectEqual(&.{0, 0, 0, 6, 10, 'h', 'e', 'l', 'l', 'o'}, sb.string());
}
