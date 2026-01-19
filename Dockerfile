FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    binutils ca-certificates git cmake make gcc g++ libc6-dev \
    clang-tidy \
    && rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir pre-commit

# Build uncrustify 0.64
WORKDIR /tmp
RUN git clone -b uncrustify-0.64 --single-branch https://github.com/uncrustify/uncrustify.git uncrustify && \
    cd uncrustify && \
    mkdir build && cd build && \
    cmake -D CMAKE_INSTALL_PREFIX=/usr/local -D CMAKE_BUILD_TYPE=RelWithDebInfo ../ && \
    make -j "$(nproc)" && \
    make install && \
    cd /tmp && rm -rf uncrustify

# Set up Action resources
WORKDIR /action
COPY .pre-commit-config.yaml /action/
COPY tools /action/tools
COPY entrypoint.sh /entrypoint.sh

# Fix paths in pre-commit config to point to absolute paths inside the container
RUN sed -i 's|\./uncrustify/uncrustify.cfg|/action/tools/uncrustify/uncrustify.cfg|g' .pre-commit-config.yaml && \
    sed -i 's|\./.github/coding-convention-tool/tools/.codespell/.codespellrc|/action/tools/.codespell/.codespellrc|g' .pre-commit-config.yaml && \
    sed -i 's|\./.clang-tidy|/action/tools/.clang-tidy|g' .pre-commit-config.yaml && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
