# brotli

[Brotli](https://github.com/google/brotli), packaged for the Zig build system.

## Installation

First, fetch the package using Zig's package manager:
```shell
zig fetch --save 'git+https://github.com/zon-vendor/brotli.git#v1.1.0'
```

Then, import the dependency in your `build.zig`:
```zig
    const brotli_dep = b.dependency("brotli", .{
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(brotli_dep.artifact("brotli"));
```
