const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;

// TODO parse csv []u8 into structs
// TODO help fn given filestring
pub fn Parser(comptime T: type) type {
    // if (@typeOf(T) != builtin.TypeInfo.Struct) {
    //     @panic("TODO Cannot create a parser for a non struct");
    // }

    return struct {
       pub rows: ArrayList(T),
       allocator: *Allocator,

       const Self = @This();

        pub fn init(allocator: *Allocator) Self {
            return Self{
                .rows = ArrayList(T).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn parse(self: *Self, contents: []u8) !void {
            var start: usize = 0;
            for (contents) |byte, i| {
                if (byte == '\r') {
                    if (contents.len <= i + 1) {
                        break; // EOF
                    }
                    if (contents[i+1] == '\n') {
                        continue;
                    }
                }

                if (byte == '\n') {
                    try self.parse_line(contents[start..i-1]);
                }
            }

            if (contents[contents.len-1] != '\n') {
                try self.parse_line(contents[start..contents.len-1]);
            }
        }

        pub fn parse_line(self: *Self, line: []u8) !void {
            warn("\n");

            var row = try self.allocator.create(T);

            const info = comptime @typeInfo(T);
            inline for (info.Struct.fields) |field| {
                warn(field.name);
                warn("\n");
                switch (@typeId(field.field_type)) {
                    builtin.TypeId.Int => {
                        var v = try std.fmt.parseInt(field.field_type, line[0..line.len], 10);
                        @field(row.*, field.name) = v;
                    },
                    builtin.TypeId.Float => {
                        var v = try std.fmt.parseFloat(field.field_type, line[0..line.len]);
                        @field(row.*, field.name) = v;
                    },
                    else => {
                        std.debug.panic("Type '{}' cannot be used for column of a CSV file", @typeId(field.field_type));
                    }
                }
            }

            try self.rows.append(row.*);
        }
   };
}

test "basic parse_line test int" {
    var direct_allocator = std.heap.DirectAllocator.init();
    defer direct_allocator.deinit();

    var file = 
        \\11
    ;

    const TestRow = struct {
        pub id: isize,
    };

    var parser = Parser(TestRow).init(&direct_allocator.allocator);

    try parser.parse_line(file[0..]);

    assert(parser.rows.count() == 1);
    assert(parser.rows.toSlice()[0].id == 11);
}

test "basic parse_line test float" {
    var direct_allocator = std.heap.DirectAllocator.init();
    defer direct_allocator.deinit();

    var file = 
        \\11.0
    ;

    const TestRow = struct {
        pub id: f32,
    };

    var parser = Parser(TestRow).init(&direct_allocator.allocator);

    try parser.parse_line(file[0..]);

    assert(parser.rows.count() == 1);
    assert(parser.rows.toSlice()[0].id == 11.0);
}

// TODO test for should fail
// test "basic parse_line canont use column type" {
//     var direct_allocator = std.heap.DirectAllocator.init();
//     defer direct_allocator.deinit();

//     var file = 
//         \\11.0
//     ;

//     const TestRow = struct {
//         pub id: []u8,
//     };

//     var parser = Parser(TestRow).init(&direct_allocator.allocator);

//     try parser.parse_line(file[0..file.len]);

//     assert(parser.rows.count() == 1);
// }