use super::*;

/// Queries workspace-scoped atoms through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn query_atoms(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse {
    query_atoms_impl(caller, descriptor, projection)
}

pub(super) fn query_atoms_impl(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse {
    query_atoms_impl_with_noop_guard(caller, descriptor, projection)
}

fn query_atoms_impl_with_noop_guard(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse {
    query_atoms_impl_inner(caller, descriptor, projection, Box::new(NoopGuard))
}

fn query_atoms_impl_inner(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
    guard: Box<dyn AccessGuard>,
) -> ScopedQueryResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return scoped_query_failure(err),
    };
    let query = match build_scoped_query(descriptor) {
        Ok(value) => value,
        Err(err) => return scoped_query_failure(err),
    };
    let projection = map_projection_mode(projection);

    match with_guarded_query_service_using_guard(guard, |service| {
        service.query_atoms(&caller, query, projection)
    }) {
        Ok(items) => ScopedQueryResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} scoped atom(s).", items.len()),
            items: items.into_iter().map(to_scoped_atom_item).collect(),
        },
        Err(err) => scoped_query_failure(err),
    }
}

#[cfg(test)]
pub(super) fn query_atoms_impl_with_guard(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
    guard: Box<dyn AccessGuard>,
) -> ScopedQueryResponse {
    query_atoms_impl_inner(caller, descriptor, projection, guard)
}
