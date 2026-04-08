alias c := check
alias cs := check-sigs
alias d := doc
alias do := doc-open
alias f := fmt
alias l := lock
alias t := test
alias tns := test-no-std
alias p := pre-push

_default:
    @echo "> rustreexo"
    @echo "> A Rust implementation of Utreexo\n"
    @just --list

[doc: "Run benchmarks: accumulator, proof, stump"]
bench BENCH="":
    cargo bench {{ if BENCH != "" { "--bench " + BENCH } else { "" } }}

[doc: "Check code formatting, compilation, and linting"]
check:
    cargo rbmt fmt --check
    cargo rbmt lint
    cargo rbmt docs
    RUSTFLAGS="--cfg=bench" cargo +nightly check --benches

[doc: "Checks whether all commits in this branch are signed"]
check-sigs:
    #!/usr/bin/env bash
    TOTAL=$(git log --pretty='tformat:%H' origin/main..HEAD | wc -l | tr -d ' ')
    UNSIGNED=$(git log --pretty='tformat:%H %G?' origin/main..HEAD | grep " N$" | wc -l | tr -d ' ')
    if [ "$UNSIGNED" -gt 0 ]; then
        echo "⚠️ Unsigned commits in this branch [$UNSIGNED/$TOTAL]"
        exit 1
    else
        echo "🔏 All commits in this branch are signed [$TOTAL/$TOTAL]"
    fi

[doc: "Generate documentation"]
doc:
    cargo rbmt docs
    cargo doc --no-deps

[doc: "Generate and open documentation"]
doc-open:
    cargo rbmt docs
    cargo doc --no-deps --open

[doc: "Format code"]
fmt:
    cargo rbmt fmt

[doc: "Regenerate Cargo-recent.lock and Cargo-minimal.lock"]
lock:
    cargo rbmt lock

[doc: "Run tests across all toolchains and lockfiles"]
test:
    rustup target add thumbv7m-none-eabi
    cargo rbmt test --toolchain stable --lock-file recent
    cargo rbmt test --toolchain stable --lock-file minimal

[doc: "Run no_std build check with the MSRV toolchain (1.74.0)"]
test-no-std:
    rustup target add thumbv7m-none-eabi --toolchain 1.74.0
    cargo rbmt test --toolchain msrv --lock-file minimal

[doc: "Run pre-push suite: lock, fmt, check, test, and test-no-std"]
pre-push: lock fmt check check-sigs test test-no-std
