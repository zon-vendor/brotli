pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Library linkage (default: static)") orelse .static;

    const brotli_dep = b.dependency("brotli", .{});

    const brotli_builder: BrotliBuilder = .init(b, brotli_dep, .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }, linkage);
    b.installArtifact(brotli_builder.addLibrary(.common));
    b.installArtifact(brotli_builder.addLibrary(.dec));
    b.installArtifact(brotli_builder.addLibrary(.enc));
}

const BrotliBuilder = struct {
    b: *std.Build,
    options: std.Build.Module.CreateOptions,
    dependency: *std.Build.Dependency,
    brotli_path: std.Build.LazyPath,
    brotli_include_path: std.Build.LazyPath,
    linkage: std.builtin.LinkMode,

    pub fn init(
        b: *std.Build,
        dep: *std.Build.Dependency,
        options: std.Build.Module.CreateOptions,
        linkage: std.builtin.LinkMode,
    ) BrotliBuilder {
        var options_copy = options;
        options_copy.link_libc = true;

        return .{
            .b = b,
            .options = options_copy,
            .dependency = dep,
            .brotli_path = dep.path(""),
            .brotli_include_path = dep.path("c/include"),
            .linkage = linkage,
        };
    }

    pub fn addLibrary(self: BrotliBuilder, comptime brotli_lib: BrotliLib) *std.Build.Step.Compile {
        const brotli_lib_str = @tagName(brotli_lib);
        const sources = switch (brotli_lib) {
            .common => common_src,
            .dec => dec_src,
            .enc => enc_src,
        };
        const lib = self.b.addLibrary(.{
            .name = "brotli" ++ brotli_lib_str,
            .root_module = self.b.createModule(self.options),
            .version = std.SemanticVersion.parse(zon.version) catch unreachable,
            .linkage = self.linkage,
        });
        lib.addCSourceFiles(.{ .root = self.brotli_path, .files = sources });
        lib.addIncludePath(self.brotli_path.path(self.b, "c/" ++ brotli_lib_str));
        lib.addSystemIncludePath(self.brotli_include_path);

        return lib;
    }

    const BrotliLib = enum {
        common,
        dec,
        enc,
    };

    const common_src: []const []const u8 = &.{
        "c/common/constants.c",
        "c/common/context.c",
        "c/common/dictionary.c",
        "c/common/platform.c",
        "c/common/shared_dictionary.c",
        "c/common/transform.c",
    };

    const dec_src: []const []const u8 = &.{
        "c/dec/bit_reader.c",
        "c/dec/decode.c",
        "c/dec/huffman.c",
        "c/dec/state.c",
    };

    const enc_src: []const []const u8 = &.{
        "c/enc/backward_references.c",
        "c/enc/backward_references_hq.c",
        "c/enc/bit_cost.c",
        "c/enc/block_splitter.c",
        "c/enc/brotli_bit_stream.c",
        "c/enc/cluster.c",
        "c/enc/command.c",
        "c/enc/compound_dictionary.c",
        "c/enc/compress_fragment.c",
        "c/enc/compress_fragment_two_pass.c",
        "c/enc/dictionary_hash.c",
        "c/enc/encode.c",
        "c/enc/encoder_dict.c",
        "c/enc/entropy_encode.c",
        "c/enc/fast_log.c",
        "c/enc/histogram.c",
        "c/enc/literal_cost.c",
        "c/enc/memory.c",
        "c/enc/metablock.c",
        "c/enc/static_dict.c",
        "c/enc/utf8_util.c",
    };
};

const std = @import("std");
const zon = @import("build.zig.zon");
