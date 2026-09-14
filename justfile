alias c := check
alias a := audit
alias d := docs
alias f := fmt
alias l := lock
alias t := test
alias p := pre-push

export nightly := `cargo rbmt toolchains --nightly`
export RBMT_LOG_LEVEL := env("RBMT_LOG_LEVEL", "progress")

_default:
    @echo "> rustreexo"
    @echo "> A Rust implementation of Utreexo\n"
    @just --list

# Quality

[doc: "Audit dependencies"]
[group("Quality")]
audit:
    @echo "Auditing Cargo.lock"
    cargo generate-lockfile
    cargo audit --file Cargo.lock

    @echo "\nAuditing Cargo-recent.lock"
    cargo audit --file Cargo-recent.lock

    @echo "\nAuditing Cargo-minimal.lock"
    cargo audit --file Cargo-minimal.lock

[doc: "Check Formatting, Linting and Documentation"]
[group("Quality")]
check:
    cargo rbmt fmt --check
    cargo rbmt lint
    cargo rbmt docs

[doc: "Check Commit Signatures"]
[group("Quality")]
check-sigs:
    bash contrib/check-commit-signatures.sh

[doc: "Format Code"]
[group("Quality")]
fmt:
    cargo rbmt fmt

[doc: "Run pre-push suite: lock, fmt, check, and test"]
[group("Quality")]
pre-push:
    @just check-sigs
    @just lock
    @just fmt
    @just check
    @just test
    @just shellcheck
    @just zizmor

[doc: "Run ShellCheck"]
[group("Quality")]
shellcheck:
    @command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck was not found on \$PATH" && exit 1; }
    find . -name '*.sh' -print -exec shellcheck {} +

[doc: "Run Zizmor Static Analysis"]
[group("Quality")]
zizmor:
   zizmor .

# Documentation

[doc: "Generate Documentation"]
[group("Documentation")]
docs:
    cargo rbmt docs

[doc: "Generate and Open Documentation"]
[group("Documentation")]
docs-open:
    cargo rbmt docs --open

# Testing

[doc: "Run Benchmarks: accumulator, proof, stump"]
[group("Testing")]
bench BENCH="":
    cargo rbmt run bench {{ if BENCH != "" { "--bench " + BENCH } else { "" } }}

[doc: "Run Fuzz Targets: list, all, or TARGET"]
[group("Testing")]
fuzz TARGET="list" TIME="600":
    #!/usr/bin/env bash
    set -euo pipefail

    case "{{TARGET}}" in
        list)
            cargo +{{ nightly }} fuzz list
            ;;
        all)
            targets=$(cargo +{{ nightly }} fuzz list)
            for target in $targets; do
                echo "Fuzzing Target: $target"
                cargo +{{ nightly }} fuzz run "$target" -- -max_total_time={{TIME}}
            done
            ;;
        *)
            cargo +{{ nightly }} fuzz run "{{TARGET}}" -- -max_total_time={{TIME}}
            ;;
    esac

[doc: "Run Tests"]
[env("RBMT_LOG_LEVEL", "verbose")]
[group("Testing")]
test:
    cargo rbmt test --toolchain stable --lockfile recent
    cargo rbmt test --toolchain stable --lockfile minimal
    cargo rbmt test --toolchain msrv --lockfile minimal

# Dependencies

[doc: "Generate Lockfiles"]
[group("Dependencies")]
lock:
  cargo rbmt lock

# Setup

[doc: "Setup Tools and Toolchains"]
[group("Setup")]
setup-tools-toolchains:
    cargo rbmt tools
    cargo rbmt toolchains

[doc: "Update Tools and Toolchains"]
[group("Setup")]
update-tools-toolchains:
    cargo rbmt tools --update
    cargo rbmt toolchains --update-stable
    cargo rbmt toolchains --update-nightly
