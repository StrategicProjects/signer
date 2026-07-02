# pdfsigner 0.2.5

* Accepted by CRAN on 2026-07-02.
* Fixed an installation ERROR on rustc 1.86.0 (reported for 0.2.4 via CRAN's
  "Additional issues" / donttest check). Transitive dependencies
  `time`/`time-core`/`time-macros` (pulled in via `lopdf` and
  `x509-parser`/`asn1-rs`) had quietly raised their MSRV to rustc 1.88.0. We now
  pin `time = "=0.3.45"` (MSRV 1.83.0) in `src/rust/Cargo.lock` before vendoring,
  so the offline build only requires a rustc over two years old.
* `pdf_signer` is now consumed as a normal crates.io dependency
  (`default-features = false`, `features = ['https']`) instead of a bundled,
  hand-synced path copy; `src/rust/vendor.tar.xz` was re-vendored accordingly.
  No user-facing behavior change.

# pdfsigner 0.2.4

* Fixed the M1mac linker WARNING ("object file ... was built for newer 'macOS'
  version than being linked") on the C/assembly objects of the `ring` crate, by
  exporting an explicit `MACOSX_DEPLOYMENT_TARGET` for the `cargo build` step
  (`tools/config.R` / `src/Makevars.in`) so all objects share a deployment
  target at or below R's link target.

# pdfsigner 0.2.3

* Synced the pure-Rust backend to `pdf_signer` engine v0.2.0.

# pdfsigner 0.2.2

* CRAN submission. Do not regenerate the extendr wrappers at install time (the
  wrappers are committed); the Windows/CRAN build only runs `cargo build --lib`.

# pdfsigner 0.2.0

* Replaced the previous Java/`pdfsig` backend with a bundled pure-Rust engine
  wrapped via extendr. No Java, OpenSSL, or external command-line tools required.
* Public API: `sign_pdf()` and `verify_pdf_signature()`.
