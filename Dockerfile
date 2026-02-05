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
COPY handle_custom_inputs.py /action/handle_custom_inputs.py
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /action/handle_custom_inputs.py

ENTRYPOINT ["/entrypoint.sh"]
