//! Minimal FFI layer for LazyNote.
//! Only use-case-level APIs should be exposed here.

use lazynote_core::{core_version, ping};

/// Internal Rust-friendly wrapper for early tests.
pub fn ping_text() -> String {
    ping().to_string()
}

/// Internal Rust-friendly wrapper for early tests.
pub fn version_text() -> String {
    core_version().to_string()
}

/// C ABI smoke-check function.
#[no_mangle]
pub extern "C" fn lazynote_ping_code() -> u32 {
    1
}

#[cfg(test)]
mod tests {
    use super::{ping_text, version_text};

    #[test]
    fn ping_text_returns_pong() {
        assert_eq!(ping_text(), "pong");
    }

    #[test]
    fn version_is_not_empty() {
        assert!(!version_text().is_empty());
    }
}
