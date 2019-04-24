const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const warn = std.debug.warn;

const T = struct {
    a: u32,
    b: u8,
    c: isize,
    d: i32,
    e: f32,
};
const info = @typeInfo(T);

pub fn parse_line(allocator: *std.mem.Allocator, line: []u8) !T {
    var fieldIdx: u32 = 0;
    var start: u32 = 0;
    var end: u32 = 0;

    // var value = try allocator.create(T);
    var value: T = undefined;

    for (line) |char| {
        if (char == ',') {
            inline for (info.Struct.fields) |field, i| {
                if (fieldIdx == i) {
                    const cell = line[start..end];
                    warn("\n'{}' '{}' '{}'\n", start, end, cell);
                    switch (@typeId(field.field_type)) {
                        builtin.TypeId.Int => {
                            var v = try std.fmt.parseInt(field.field_type, cell, 10);
                            @field(value, field.name) = v;
                        },
                        builtin.TypeId.Float => {
                            var v = try std.fmt.parseFloat(field.field_type, cell);
                            @field(value, field.name) = v;
                        },
                        else => {
                            std.debug.panic("Type '{}' cannot be used for column of a CSV file", @typeId(field.field_type));
                        }
                    }
                }
            }

            start = end + 1;
            end = start;
            fieldIdx += 1;
        } else {
            end += 1;
        }
    }

    // catch last comma sep val
    inline for (info.Struct.fields) |field, j| {
        if (fieldIdx == j) {
            const cell = line[start..end];
            warn("\n'{}' '{}' '{}'\n", start, end, cell);
            switch (@typeId(field.field_type)) {
                builtin.TypeId.Int => {
                    var v = try std.fmt.parseInt(field.field_type, cell, 10);
                    @field(value, field.name) = v;
                },
                builtin.TypeId.Float => {
                    warn("\n'HERE'\n");
                    var v = try std.fmt.parseFloat(field.field_type, cell);
                    @field(value, field.name) = v;
                },
                else => {
                    std.debug.panic("Type '{}' cannot be used for column of a CSV file", @typeId(field.field_type));
                }
            }
        }
    }

    return value;
}

test "test" {
    var direct_allocator = std.heap.DirectAllocator.init();
    defer direct_allocator.deinit();

    var contents = "1,22,333,-4444,5";
    // TODO var contents = "1,22,333,-4444,0.5"; int overflow??
    var row = try parse_line(&direct_allocator.allocator, contents[0..]);
    warn("\n\n{}\n\n", row);
    assert(row.a == 1);
    assert(row.b == 22);
    assert(row.c == 333);
    assert(row.d == -4444);
    assert(row.e == 5);
    // assert(row.e == 0.5);
}
