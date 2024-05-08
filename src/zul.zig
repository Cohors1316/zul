const std = @import("std");

pub const fs = @import("fs.zig");
pub const http = @import("http.zig");
pub const pool = @import("pool.zig");
pub const testing = @import("testing.zig");
pub const benchmark = @import("benchmark.zig");

pub const UUID = @import("uuid.zig").UUID;
pub const Scheduler = @import("scheduler.zig").Scheduler;
pub const ThreadPool = @import("thread_pool.zig").ThreadPool;
pub const StringBuilder = @import("string_builder.zig").StringBuilder;
pub const CommandLineArgs = @import("command_line_args.zig").CommandLineArgs;

const datetime = @import("datetime.zig");
pub const Date = datetime.Date;
pub const Time = datetime.Time;
pub const DateTime = datetime.DateTime;

pub fn Managed(comptime T: type) type {
	return struct {
		value: T,
		arena: *std.heap.ArenaAllocator,

		const Self = @This();

		pub fn fromJson(parsed: std.json.Parsed(T)) Self {
			return  .{
				.arena = parsed.arena,
				.value = parsed.value,
			};
		}

		pub fn deinit(self: Self) void {
			const arena = self.arena;
			const allocator = arena.child_allocator;
			arena.deinit();
			allocator.destroy(arena);
		}
	};
}

test {
	@import("std").testing.refAllDecls(@This());
}
