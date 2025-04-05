const std = @import("std");
const testing = std.testing;

/// Standard RGB function, return BGR u32 for usage in win32
pub export fn rgb(red: u8, green: u8, blue: u8) u32 {
    return @as(u32, red) | @as(u32, green) << 8 | @as(u32, blue) << 16;
}

test "rgb" {
    try testing.expect(rgb(255, 0, 0) == 0x0000FF);
    try testing.expect(rgb(0, 0, 255) == 0xFF0000);
    try testing.expect(rgb(0, 255, 0) == 0x00FF00);
    try testing.expect(rgb(255, 255, 255) == 0xFFFFFF); // White
    try testing.expect(rgb(0, 0, 0) == 0x000000); // Black
    try testing.expect(rgb(128, 128, 128) == 0x808080); // Gray
    try testing.expect(rgb(255, 165, 0) == 0x00A5FF); // Orange
    try testing.expect(rgb(75, 0, 130) == 0x82004B); // Indigo
    try testing.expect(rgb(173, 216, 230) == 0xE6D8AD); // Light Blue
    try testing.expect(rgb(34, 139, 34) == 0x228B22); // Forest Green
    try testing.expect(rgb(255, 192, 203) == 0xCBC0FF); // Pink
    try testing.expect(rgb(139, 69, 19) == 0x13458B); // Saddle Brown
    try testing.expect(rgb(240, 230, 140) == 0x8CE6F0); // Khaki
}

/// Removes all chars untill selected one, if the char is at the end of the string it will be ignored
pub fn strBspaceUntilChar(path: []const u8, char: u8) []const u8 {
    if (path.len == 0) return path;
    var end_i: usize = path.len - 1;
    if (path[end_i] == char) end_i -|= 1;

    while (end_i > 0 and !(path[end_i] == char)) {
        end_i -= 1;
    }

    return path[0..end_i];
}

test "strBspaceUntilChar" {
    try std.testing.expect(std.mem.eql(u8, "C:\\root\\some_dir\\some_other_dir", strBspaceUntilChar("C:\\root\\some_dir\\some_other_dir\\run.exe", '\\')));
    try std.testing.expect(std.mem.eql(u8, "", strBspaceUntilChar("hello_world!", '\\')));
    try std.testing.expect(std.mem.eql(u8, "", strBspaceUntilChar("", '\\')));
    try std.testing.expect(std.mem.eql(u8, "C:\\root\\some_dir", strBspaceUntilChar("C:\\root\\some_dir\\some_other_dir", '\\')));
    try std.testing.expect(std.mem.eql(u8, "C:\\root\\some_dir", strBspaceUntilChar("C:\\root\\some_dir\\some_other_dir\\", '\\')));
    try std.testing.expect(std.mem.eql(u8, "", strBspaceUntilChar("\\", '\\')));
    try std.testing.expect(std.mem.eql(u8, "Hello", strBspaceUntilChar("Hello World!", ' ')));
    try std.testing.expect(std.mem.eql(u8, "", strBspaceUntilChar("Hello World!", '!')));
    try std.testing.expect(std.mem.eql(u8, "Hello World", strBspaceUntilChar("Hello World!!", '!')));
    try std.testing.expect(std.mem.eql(u8, "H", strBspaceUntilChar("Hello World!", 'e')));
    try std.testing.expect(std.mem.eql(u8, "Hello", strBspaceUntilChar("Hello#World!", '#')));
}

///Writes to a null terminated u8 buffer
const path_separator: [1]u8 = .{@as(u8, @intCast(std.fs.path.sep))};
pub const PathWritter = struct {
    buffer: [260]u8 = [_]u8{0} ** 260,
    len: u16 = 0,
    sep: []const u8 = path_separator[0..],

    ///Write to path adding a separator
    pub fn write(self: *PathWritter, str: []const u8) !void {
        if (self.len + str.len > self.buffer.len - 1) return BufferError.BufferOverflow;
        if (self.buffer[self.len] != self.sep[0] and self.len != 0) {
            @memcpy(self.buffer[self.len .. self.len + self.sep.len], self.sep);
            self.len += 1;
        }
        @memcpy(self.buffer[self.len .. self.len + str.len], str);
        self.len +|= @as(u16, @intCast(str.len));
    }

    ///Write to buffer as is nothing will be added
    pub fn writeNoSep(self: *PathWritter, str: []const u8) !void {
        if (self.len + str.len > self.buffer.len) return BufferError.BufferOverflow;
        @memcpy(self.buffer[self.len .. self.len + str.len], str);
        self.len +|= @as(u16, @intCast(str.len));
    }

    /// If char not in buffer the whole buffer will be empty
    pub fn removeUntilSep(self: *PathWritter) void {
        const end = self.len;
        if (self.buffer[end] == self.sep[0]) self.len -= 1;
        while (self.buffer[self.len] != self.sep[0]) {
            if (self.len == 0) break;
            self.len -= 1;
        }
        @memset(self.buffer[self.len..end], 0);
    }

    /// Return string/value until char
    pub fn returnUntilSep(self: *PathWritter) []const u8 {
        if (self.len == 0) return "";
        if (self.buffer[self.len] == self.sep[0]) self.len -= 1;
        var i = self.len;
        while (self.buffer[i] != self.sep[0]) : (i -= 1) {
            if (i == 0) break;
        }
        return self.buffer[i + 1 .. self.len];
    }

    ///Reset the buffer
    pub fn clear(self: *PathWritter) void {
        @memset(self.buffer[0..self.len], 0);
        self.len = 0;
    }

    /// Return the string/value as a slice
    pub fn value(self: *PathWritter) []const u8 {
        return self.buffer[0..self.len];
    }
};

pub const BufferError = error{BufferOverflow};

test "PathWriter" {
    var test_writer = PathWritter{};
    try test_writer.write("C:\\root");
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:\\root"));
    try std.testing.expect(std.mem.eql(u8, test_writer.buffer[0..test_writer.len], "C:\\root"));
    try test_writer.write("new_dir");
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:\\root\\new_dir"));
    try std.testing.expect(std.mem.eql(u8, test_writer.returnUntilSep(), "new_dir"));
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:\\root\\new_dir"));
    test_writer.removeUntilSep();
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:\\root"));
    test_writer.removeUntilSep();
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:"));
    test_writer.removeUntilSep();
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), ""));
    try std.testing.expect(std.mem.eql(u8, test_writer.returnUntilSep(), ""));
    try std.testing.expectEqual(BufferError.BufferOverflow, test_writer.write("C:\\root\\new_dir\\This_should_trigger_a_BufferOverflow_error\\Since_the_lenghth_is_higher_than_the_buffer_array_lenght\\The_buffer_array_is_a_fixed_size_of_260_since_that_is_the_maximum_allowed_path_lemghth_under_windows\\as_you_can_see_it_is_plenty_long_even_for_th"));
    try test_writer.write("C:\\root\\new_dir\\This_should_not_trigger_a_BufferOverflow_error\\Since_the_lenghth_is_lower_than_the_buffer_array_lenght\\The_buffer_array_is_a_fixed_size_of_260_since_that_is_the_maximum_allowed_path_lemghth_under_windows\\as_you_can_see_it_is_plenty_long_even_t");
    try std.testing.expectEqual(test_writer.buffer.len - 1, test_writer.len);
    test_writer.clear();
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), ""));
    try test_writer.write("C:\\root");
    try test_writer.writeNoSep("Hello World!");
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:\\rootHello World!"));
    test_writer.clear();
    try test_writer.write("C:\\root\\");
    try test_writer.writeNoSep("Hello World!");
    try std.testing.expect(std.mem.eql(u8, test_writer.value(), "C:\\root\\Hello World!"));
    test_writer.clear();
    try test_writer.writeNoSep("C:\\root\\new_dir\\This_should_not_trigger_a_BufferOverflow_error\\Since_the_lenghth_is_lower_than_the_buffer_array_lenght\\The_buffer_array_is_a_fixed_size_of_260_since_that_is_the_maximum_allowed_path_lemghth_under_windows\\as_you_can_see_it_is_plenty_long_even_th");
    try std.testing.expectEqual(test_writer.buffer.len, test_writer.len);
}

//Dirty and ugly untill better methods for input validation become available
//This function is probably more strict than windows in some cassess and theres probably
// some edge cassess I missed.
/// Checks if path is a valid Windows path
pub fn isPathValid(path: []const u8) bool {
    if (path.len > std.os.windows.MAX_PATH or path.len < 3) return false;
    if (path[1] != ':') return false;

    var dot_handoff_i: usize = 0;
    var last_bslash_i: usize = 0;
    const forbiden_chars = [_]u8{ '<', '>', '"', '/', '|', '?', '*' };
    var dot_i: usize = 0;
    for (path, 0..) |char, i| {
        if (char == '\\' and i != path.len) last_bslash_i = i;
        if (char == ':' and i != 1) return false;
        if (char == '.') {
            dot_handoff_i = i;
            dot_i += 1;
        }

        if (char >= 0 and char < 32) return false;
        for (forbiden_chars) |forbiden| {
            if (char == forbiden) return false;
        }
    }

    if (dot_i > 1) return false;
    if (path.len - dot_handoff_i < 3 or last_bslash_i < 2) {
        return false;
    }

    if (dot_handoff_i == 0) dot_handoff_i = path.len;
    const reserved_names: [7][]const u8 = .{ "CON", "PRN", "AUX", "NUL", "COM", "LPT", "NUL" };

    while (last_bslash_i + 3 < dot_handoff_i) : (last_bslash_i += 1) {
        for (reserved_names) |name| {
            if (std.mem.eql(u8, path[last_bslash_i .. last_bslash_i + 3], name)) return false;
        }
    }
    return true;
}

test "isPathValid" {
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\ziONt"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\new_folder"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\newfolder\\"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\ziz"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\\\\\"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\ziCONt"), false);
    try std.testing.expectEqual(isPathValid("C\\To:ols\\my_projects\\zig\\zag\\ziONt"), false);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_proj|ects\\zig\\zag\\"), false);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projects\\zig\\zag\\ziONt.exe"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my_projeLPTcts\\zig\\zag\\ziONt"), true);
    try std.testing.expectEqual(isPathValid("C:\\Tools\\my._projects.\\zig\\zag"), false);
    try std.testing.expectEqual(isPathValid(""), false);
}
