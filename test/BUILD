load("utils.bzl",
     "asterius_boot",
     "ahc_link",
)
load(
    "@rules_haskell//haskell:defs.bzl",
    "haskell_toolchain_library",
    "haskell_library",
    "haskell_binary",
    "haskell_repl",
)

load(
    "@rules_haskell//haskell:toolchain.bzl",
    "haskell_toolchain",
)

load("@rules_pkg//:pkg.bzl", "pkg_tar", "pkg_deb")

#load("//bazel_utils/packaging:packaging.bzl", "package_app")


asterius_boot(
    name = "asterius_boot",
    srcs = [
        "//asterius:asterius_datadir",
        "launch_ahc_boot_from_utils.sh",
    ],
    tools = [
        "//ghc-toolkit:ghc-toolkit-datafiles",
        "@cabal//:bin",
        "//asterius:ahc",
        "//asterius:ahc-pkg",
        "//asterius:ahc-cabal",
        "//asterius:ahc-dist",
        "//asterius:ahc-ld",
        "//asterius:ahc-link",
        "//asterius:Setup-ghc-prim",
        "//asterius:ahc-boot",
        "@ghc//:bin",
        "@autoconf//:bin",
        "@automake//:bin",
        "@bazel_tools//tools/bash/runfiles",

    ],
)

# ahc_link(
#     name = "test_ahc_link",
#     srcs = [],
#     deps = [],
#     tools = ["//asterius:ahc"],
#     asterius_boot_rule = ":asterius_boot",
#     ahc_link_exe = "//asterius:ahc-link",
# )

# pkg_tar(
#     name = "asterius-output",
#     strip_prefix = "/src",
#     srcs = [
#         ":asterius_boot",
#         "//asterius:ahc",
#         "//asterius:ahc-pkg",
#         "//asterius:ahc-cabal",
#         "//asterius:ahc-dist",
#         "//asterius:ahc-ld",
#         "//asterius:ahc-link",
#     ],
#     mode = "0755",
# )

# package_app(
#     name = "asterius-out",
#     binary = "//asterius:ahc",
#     resources = [
#         # "//bazel_utils/packaging:package-app.sh",
#         # ":daml-base-anchors.json",
#         # ":ghc-pkg-dist",
#         # "//compiler/damlc:ghcversion",
#         # "//compiler/damlc:hpp",
#         # "//compiler/damlc/daml-ide-core:dlint.yaml",
#         # "//compiler/damlc/pkg-db",
#         # "//compiler/damlc/stable-packages",
#         # "//compiler/repl-service/server:repl_service_jar",
#         # "//compiler/scenario-service/server:scenario_service_jar",
#         # "@static_asset_d3plus//:js/d3.min.js",
#         # "@static_asset_d3plus//:js/d3plus.min.js",
#     ],
#     tags = ["no-cache"],
#     visibility = ["//visibility:public"],
# )
