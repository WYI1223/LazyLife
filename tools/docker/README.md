# docker

TODO: Container and image planning.

用法（只跑 Rust 相关）

在仓库根目录：
````bash
docker build -t lazynote-dev -f tools/docker/Dockerfile .
docker run --rm -v ${PWD}:/work -w /work lazynote-dev cargo fmt --all -- --check
docker run --rm -v ${PWD}:/work -w /work lazynote-dev cargo clippy --all -- -D warnings
docker run --rm -v ${PWD}:/work -w /work lazynote-dev cargo test --all
````