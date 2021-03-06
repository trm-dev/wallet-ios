# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Defines Skylark providers that propagated by the Swift BUILD rules."""

SwiftInfo = provider(
    doc = """\
Contains information about the compiled artifacts of a Swift module.

This provider contains a large number of fields and many custom rules may not
need to set all of them. Instead of constructing a `SwiftInfo` provider
directly, consider using the `swift_common.create_swift_info` function, which
has reasonable defaults for any fields not explicitly set.
""",
    fields = {
        "direct_defines": """\
`List` of `string`s. The values specified by the `defines` attribute of the
library that directly propagated this provider.
""",
        "direct_swiftdocs": """\
`List` of `File`s. The Swift documentation (`.swiftdoc`) files for the library
that directly propagated this provider.
""",
        "direct_swiftmodules": """\
`List` of `File`s. The Swift modules (`.swiftmodule`) for the library that
directly propagated this provider.
""",
        "module_name": """\
`String`. The name of the Swift module represented by the target that directly
propagated this provider.

This field will be equal to the explicitly assigned module name (if present);
otherwise, it will be equal to the autogenerated module name.
""",
        "swift_version": """\
`String`. The version of the Swift language that was used when compiling the
propagating target; that is, the value passed via the `-swift-version` compiler
flag. This will be `None` if the flag was not set.
""",
        "transitive_defines": """\
`Depset` of `string`s. The transitive `defines` specified for the library that
propagated this provider and all of its dependencies.
""",
        "transitive_generated_headers": """\
`Depset` of `File`s. The transitive generated header files that can be used by
Objective-C sources to interop with the transitive Swift libraries.
""",
        "transitive_modulemaps": """\
`Depset` of `File`s. The transitive module map files that will be passed to
Clang using the `-fmodule-map-file` option.
""",
        "transitive_swiftdocs": """\
`Depset` of `File`s. The transitive Swift documentation (`.swiftdoc`) files
emitted by the library that propagated this provider and all of its
dependencies.
""",
        "transitive_swiftinterfaces": """\
`Depset` of `File`s. The transitive Swift interface (`.swiftinterface`) files
emitted by the library that propagated this provider and all of its
dependencies.
""",
        "transitive_swiftmodules": """\
`Depset` of `File`s. The transitive Swift modules (`.swiftmodule`) emitted by
the library that propagated this provider and all of its dependencies.
""",
    },
)

SwiftProtoInfo = provider(
    doc = "Propagates Swift-specific information about a `proto_library`.",
    fields = {
        "module_mappings": """\
`Sequence` of `struct`s. Each struct contains `module_name` and
`proto_file_paths` fields that denote the transitive mappings from `.proto`
files to Swift modules. This allows messages that reference messages in other
libraries to import those modules in generated code.
""",
        "pbswift_files": """\
`Depset` of `File`s. The transitive Swift source files (`.pb.swift`) generated
from the `.proto` files.
""",
    },
)

SwiftToolchainInfo = provider(
    doc = """
Propagates information about a Swift toolchain to compilation and linking rules
that use the toolchain.
""",
    fields = {
        "action_configs": """\
This field is an internal implementation detail of the build rules.
""",
        "all_files": """\
A `depset` of `File`s containing all the Swift toolchain files (tools,
libraries, and other resource files) so they can be passed as `tools` to actions
using this toolchain.
""",
        "cc_toolchain_info": """\
The `cc_common.CcToolchainInfo` provider from the Bazel C++ toolchain that this
Swift toolchain depends on.
""",
        "command_line_copts": """\
`List` of `strings`. Flags that were passed to Bazel using the `--swiftcopt`
command line flag. These flags have the highest precedence; they are added to
compilation command lines after the toolchain default flags
(`SwiftToolchainInfo.swiftc_copts`) and after flags specified in the `copts`
attributes of Swift targets.
""",
        "cpu": """\
`String`. The CPU architecture that the toolchain is targeting.
""",
        "linker_opts_producer": """\
Skylib `partial`. A partial function that returns the flags that should be
passed to Clang to link a binary or test target with the Swift runtime
libraries.

The partial should be called with two arguments:

*   `is_static`: A `Boolean` value indicating whether to link against the static
    or dynamic runtime libraries.
*   `is_test`: A `Boolean` value indicating whether the target being linked is a
    test target.
""",
        "object_format": """\
`String`. The object file format of the platform that the toolchain is
targeting. The currently supported values are `"elf"` and `"macho"`.
""",
        "optional_implicit_deps": """\
`List` of `Target`s. Library targets that should be added as implicit
dependencies of any `swift_library`, `swift_binary`, or `swift_test` target that
does not have the feature `swift.minimal_deps` applied.
""",
        "requested_features": """\
`List` of `string`s. Features that should be implicitly enabled by default for
targets built using this toolchain, unless overridden by the user by listing
their negation in the `features` attribute of a target/package or in the
`--features` command line flag.

These features determine various compilation and debugging behaviors of the
Swift build rules, and they are also passed to the C++ APIs used when linking
(so features defined in CROSSTOOL may be used here).
""",
        "required_implicit_deps": """\
`List` of `Target`s. Library targets that should be unconditionally added as
implicit dependencies of any `swift_library`, `swift_binary`, or `swift_test`
target.
""",
        "root_dir": """\
`String`. The workspace-relative root directory of the toolchain.
""",
        "stamp_producer": """\
Skylib `partial`. A partial function that compiles build data that should be
stamped into binaries. This value may be `None` if the toolchain does not
support link stamping.

The `swift_binary` and `swift_test` rules call this function _whether or not_
link stamping is enabled for that target. This provides toolchains the option of
still linking fixed placeholder data into the binary if desired, instead of
linking nothing at all. Whether stamping is enabled can be checked by inspecting
`ctx.attr.stamp` inside the partial's implementation.

The rule implementation will call this partial and pass it the following four
arguments:

*    `ctx`: The rule context of the target being built.
*    `cc_feature_configuration`: The C++ feature configuration to use when
     compiling the stamp code.
*    `cc_toolchain`: The C++ toolchain (`CcToolchainInfo` provider) to use when
     compiling the stamp code.
*    `binary_path`: The short path of the binary being linked.

The partial should return a `CcLinkingContext` containing the data (such as
object files) to be linked into the binary, or `None` if nothing should be
linked into the binary.
""",
        "supports_objc_interop": """\
`Boolean`. Indicates whether or not the toolchain supports Objective-C interop.
""",
        "swift_worker": """\
`File`. The executable representing the worker executable used to invoke the
compiler and other Swift tools (for both incremental and non-incremental
compiles).
""",
        "system_name": """\
`String`. The name of the operating system that the toolchain is targeting.
""",
        "test_configuration": """\
`Struct` containing two fields:

*   `env`: A `dict` of environment variables to be set when running tests
    that were built with this toolchain.
*   `execution_requirements`: A `dict` of execution requirements for tests
    that were built with this toolchain.

This is used, for example, with Xcode-based toolchains to ensure that the
`xctest` helper and coverage tools are found in the correct developer
directory when running tests.
""",
        "tool_configs": """\
This field is an internal implementation detail of the build rules.
""",
        "unsupported_features": """\
`List` of `string`s. Features that should be implicitly disabled by default for
targets built using this toolchain, unless overridden by the user by listing
them in the `features` attribute of a target/package or in the `--features`
command line flag.

These features determine various compilation and debugging behaviors of the
Swift build rules, and they are also passed to the C++ APIs used when linking
(so features defined in CROSSTOOL may be used here).
""",
    },
)

SwiftUsageInfo = provider(
    doc = """\
A provider that indicates that Swift was used by a target or any target that it
depends on, and specifically which toolchain was used.
""",
    fields = {
        "toolchain": """\
The Swift toolchain that was used to build the targets propagating this
provider.
""",
    },
)

def create_swift_info(
        defines = [],
        generated_headers = [],
        modulemaps = [],
        module_name = None,
        swiftdocs = [],
        swiftmodules = [],
        swiftinterfaces = [],
        swift_infos = [],
        swift_version = None):
    """Creates a new `SwiftInfo` provider with the given values.

    This function is recommended instead of directly creating a `SwiftInfo`
    provider because it encodes reasonable defaults for fields that some rules
    may not be interested in and ensures that the direct and transitive fields
    are set consistently.

    This function can also be used to do a simple merge of `SwiftInfo`
    providers, by leaving all of the arguments except for `swift_infos` as their
    empty defaults. In that case, the returned provider will not represent a
    true Swift module; it is merely a "collector" for other dependencies.

    Args:
        defines: A list of defines that will be provided as `copts` of the
            target being built.
        generated_headers: A list of headers generated by Swift for Objective-C
            interop for the target being built.
        modulemaps: A list of module maps that should be passed to ClangImporter
            by any target that depends on the one propagating this provider.
        module_name: A string containing the name of the Swift module. If this
            is `None`, the provider does not represent a compiled module but
            rather a collection of modules (this happens, for example, with
            `proto_library` targets that have no sources of their own but depend
            on others that do).
        swiftdocs: A list of `.swiftdoc` files that are the direct outputs of
        the target being built. If omitted, an empty list is used.
        swiftinterfaces: A list of `.swiftinterface` files that are the direct
            outputs of the target built. If omitted, an empty list is used.
        swiftmodules: A list of `.swiftmodule` files that are the direct outputs
            of the target being built. If omitted, an empty list is used.
        swift_infos: A list of `SwiftInfo` providers from dependencies, whose
            transitive fields should be merged into the new one. If omitted, no
            transitive data is collected.
        swift_version: A string containing the value of the `-swift-version`
            flag used when compiling this target, or `None` (the default) if it
            was not set or is not relevant.

    Returns:
        A new `SwiftInfo` provider with the given values.
    """
    transitive_defines = []
    transitive_generated_headers = []
    transitive_modulemaps = []
    transitive_swiftdocs = []
    transitive_swiftinterfaces = []
    transitive_swiftmodules = []
    for swift_info in swift_infos:
        transitive_defines.append(swift_info.transitive_defines)
        transitive_generated_headers.append(
            swift_info.transitive_generated_headers,
        )
        transitive_modulemaps.append(swift_info.transitive_modulemaps)
        transitive_swiftdocs.append(swift_info.transitive_swiftdocs)
        transitive_swiftinterfaces.append(swift_info.transitive_swiftinterfaces)
        transitive_swiftmodules.append(swift_info.transitive_swiftmodules)

    return SwiftInfo(
        direct_defines = defines,
        direct_swiftdocs = swiftdocs,
        direct_swiftmodules = swiftmodules,
        module_name = module_name,
        swift_version = swift_version,
        transitive_defines = depset(defines, transitive = transitive_defines),
        transitive_generated_headers = depset(
            generated_headers,
            transitive = transitive_generated_headers,
        ),
        transitive_modulemaps = depset(
            modulemaps,
            transitive = transitive_modulemaps,
        ),
        transitive_swiftdocs = depset(
            swiftdocs,
            transitive = transitive_swiftdocs,
        ),
        transitive_swiftinterfaces = depset(
            swiftinterfaces,
            transitive = transitive_swiftinterfaces,
        ),
        transitive_swiftmodules = depset(
            swiftmodules,
            transitive = transitive_swiftmodules,
        ),
    )
