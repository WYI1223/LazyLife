use lazynote_core::{core_version as core_version_inner, ping as ping_inner};

/// Minimal health-check API for FRB smoke integration.
#[flutter_rust_bridge::frb(sync)]
pub fn ping() -> String {
    ping_inner().to_owned()
}

/// Expose core crate version through FFI.
#[flutter_rust_bridge::frb(sync)]
pub fn core_version() -> String {
    core_version_inner().to_owned()
}

#[cfg(test)]
mod tests {
    use super::{core_version, ping};

    #[test]
    fn ping_returns_pong() {
        assert_eq!(ping(), "pong");
    }

    #[test]
    fn version_is_not_empty() {
        assert!(!core_version().is_empty());
    }
}
