load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:new_sets.bzl", "sets")
load(
    "@rules_haskell//haskell:providers.bzl",
    "HaddockInfo",
    "HaskellInfo",
    "HaskellLibraryInfo",
    "all_dependencies_package_ids",
)

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

# boot_dir = paths.join(data_dir, ".boot")
# boot_env = {"ASTERIUS_BOOT_LIBS_DIR": paths.join(data_dir, "boot-libs"), 
#             "ASTERIUS_SANDBOX_GHC_LIBDIR": paths.join(data_dir, "ghc-libdir"),
#             "ASTERIUS_LIB_DIR": paths.join(boot_dir,"asterius_lib"),
#             "ASTERIUS_TMP_DIR": bootTmpDir args,
#             "ASTERIUS_AHCPKG": ahc_pkg_path,
#             "ASTERIUS_SETUP_GHC_PRIM": setupGhcPrim,
#             "ASTERIUS_CONFIGURE_OPTIONS": configureOptions
#             }

def paths_of_environment(ctx):
    print("environment")
    path = sets.make()
    ld_library_path = sets.make()
    for d in ctx.attr.tools:
        print("d=", d)
        print("DefaultInfo", d[DefaultInfo])
        if HaskellInfo in d and HaskellLibraryInfo not in d:
            # haskell binary rule
            print("HaskellInfo", d[HaskellInfo])
            for f in d.files.to_list():
                sets.insert(path, paths.dirname(f.path))
                print(f)

        if d.label.name == "bin":
            for f in d.files.to_list():
                sets.insert(path, paths.dirname(f.path))

        if d.label.name == "lib":
            for f in d.files.to_list():
                sets.insert(ld_library_path, paths.dirname(f.path))

        # todo include ?

    path_string = " ".join(sets.to_list(path))
    ld_library_path_string = " ".join(sets.to_list(ld_library_path))

    print("end path = ", path_string)
    print("end ld_library_path = ", ld_library_path_string)
    return {"PATH_BZL": path_string, "LD_LIBRARY_PATH_BZL": ld_library_path_string}


def _asterius_boot_impl(ctx):
    paths_of_env = paths_of_environment(ctx)
    data_dir = ctx.actions.declare_directory(
        "datadir",
    )
    #ahc_boot_path = ctx.attr.ahc_boot.files.to_list()[0].path
    nix_shell_path = ctx.file.nix_shell.path
    for f in ctx.attr.ghc_toolkit.files.to_list():
        if paths.basename(f.path) == "settings":
            original_ghc_libdir = paths.dirname(f.path)
            original_boot_libs = paths.join(paths.dirname(original_ghc_libdir), "boot-libs")

    for f in ctx.attr.asterius.files.to_list():
        if paths.basename(f.path) == "boot-init.sh":
            original_datadir = paths.dirname(f.path)

    for f in ctx.attr.cabal.files.to_list():
        print(f)
    # nixpkgs_name = ctx.attr.nixpkgs_src.label.workspace_name
    # nix_path = "external/{}".format(nixpkgs_name)

    ahc_boot_path = ctx.file.ahc_boot.path
    tools = depset(transitive =
                   [t.files for t in ctx.attr.environment]+
                   [t.files for t in ctx.attr.tools]+
                                [ctx.attr.ahc_boot.files,
                                 ctx.attr.nix_shell.files,
                                 ctx.attr.ghc_toolkit.files,
                                 ctx.attr.asterius.files,
                                 ])
    inputs = depset(transitive = [t.files for t in ctx.attr.srcs])

    cc_toolchain = find_cpp_toolchain(ctx)
    cc_bin_path = paths.dirname(cc_toolchain.compiler_executable)

    haskell_toolchain =  ctx.toolchains["@rules_haskell//haskell:toolchain"]
    print(haskell_toolchain)
    for f in haskell_toolchain.bindir:
        haskell_bin_path = paths.dirname(f.path)

    print("haskell_toolchain", haskell_toolchain.bindir)
    ctx.actions.run_shell(
        tools = tools,
        inputs = inputs,
        outputs = [data_dir],
        #command = "{} nix/bazel-nix-shell.nix --pure -I nixpkgs={} --run \"env && exit 1\""
        #          .format(nix_shell_path, nix_path),
        # command = "echo $PATH && ghc && exit 1",

        command = "PATH={}:{}:$PATH test/launch_ahc_boot_from_utils.sh $1 $2 $3 $4 $5".format(cc_bin_path, haskell_bin_path),

        # command = "{} nix/bazel-nix-shell.nix --pure -I nixpkgs={} --run \"test/launch_ahc_boot_from_utils.sh $1 $2 $3 $4 $5\""
        #           .format(nix_shell_path, nix_path),
        env = paths_of_env,
        arguments = [ahc_boot_path, data_dir.path, original_datadir, original_ghc_libdir, original_boot_libs],
    )

    # ctx.actions.run_shell(
    #     tools = tools,
    #     inputs = [],
    #     command = "PATH={}:$PATH ln -s $(ahc_pkg field base haddock-html --simple-output) docdir".format(haskell_bin_path),

    # )
    default_info = DefaultInfo(files = depset([data_dir]))
    return [default_info]

asterius_boot = rule(
    _asterius_boot_impl,
    attrs = {
        # "deps": attr.label_list(),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "",
        ),
        "tools": attr.label_list(),
        "ahc_boot": attr.label(allow_single_file = True),
        "asterius": attr.label(),
        "nixpkgs_src": attr.label(),
        "ghc_toolkit": attr.label(),
        "nix_shell": attr.label(allow_single_file = True),
        "cabal": attr.label(),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
        "environment": attr.label_list(),
    },
    toolchains = [
        "@rules_haskell//haskell:toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
                  ] ,

    )


def _ahc_link_impl(ctx):
    ahc_link_executable = ctx.attr.ahc_link_exe.files
    asterius_boot_rule = ctx.file.asterius_boot_rule
    ahc_link_executable_path = ahc_link_executable.to_list()[0]
    source_files = ctx.attr.srcs
    output_file = ctx.actions.declare_file(
        "output_file_name"
    )
    tools = depset(direct = [asterius_boot_rule], transitive = [t.files for t in ctx.attr.tools]+[ahc_link_executable])
    ctx.actions.run(
        tools = tools,
        inputs = source_files,
        outputs = [output_file],
        executable = ahc_link_executable_path,
        env = {"asterius_datadir": asterius_boot_rule.path} ,
        arguments = ["--input-hs"] + [s.path for s in source_files] + ["--browser", "--bundle"],
        # arguments = ["--input-hs"+" ".join([s.path for s in source_files]) + "--browser --bundle"],
    )
    default_info = DefaultInfo(
        files = depset([output_file])
    )
    return [default_info]

ahc_link = rule(
    _ahc_link_impl,
    attrs = {
        "srcs": attr.label_list(),
        "deps": attr.label_list(),
        "tools": attr.label_list(),
        "asterius_boot_rule": attr.label(allow_single_file = True),
        "ahc_link_exe": attr.label(),
    },
)
