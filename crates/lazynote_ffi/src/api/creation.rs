use super::*;

/// Creates one atom through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn atom_create(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse {
    atom_create_impl(caller, request)
}

pub(super) fn atom_create_impl(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse {
    atom_create_impl_with_noop_guard(caller, request)
}

fn atom_create_impl_with_noop_guard(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse {
    atom_create_impl_inner(caller, request, Box::new(NoopGuard))
}

fn atom_create_impl_inner(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
    guard: Box<dyn AccessGuard>,
) -> AtomCreateResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return atom_create_failure(err),
    };
    let request = match build_create_atom_request(request) {
        Ok(value) => value,
        Err(err) => return atom_create_failure(err),
    };

    match with_guarded_creation_service_using_guard(guard, |service| {
        service.create_atom(&caller, &request)
    }) {
        Ok(result) => AtomCreateResponse {
            ok: true,
            error_code: None,
            message: "Atom created.".to_string(),
            atom_uuid: Some(result.atom.uuid.to_string()),
            node_uuid: Some(result.node.node_uuid.to_string()),
        },
        Err(err) => atom_create_failure(err),
    }
}

#[cfg(test)]
pub(super) fn atom_create_impl_with_guard(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
    guard: Box<dyn AccessGuard>,
) -> AtomCreateResponse {
    atom_create_impl_inner(caller, request, guard)
}
