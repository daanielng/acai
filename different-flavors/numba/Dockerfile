# Base image
FROM python:3.12-alpine3.20

# Set build arguments
ARG PYTHON_DEP_BUILD_PATH=/dockerbuild_python_deps

# Create local directory to store packages
RUN mkdir -p "${PYTHON_DEP_BUILD_PATH}"

# Upgrade busybox
RUN apk upgrade busybox

# Add edge alpine repo to install newer libstdc++ package and then remove edge alpine repo
RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
    apk add libstdc++=14.2.0-r3 && \
    sed -i '$d' /etc/apk/repositories

# Install system dependencies
RUN apk add \
    clang-dev \
    libc++ \
    llvm15-dev \
    man-pages \
    musl \
    ninja-build \
    rust \
    rustup \
    rust-bindgen \
    samurai \
    wasi-libcxx

# Configure llvm paths
RUN export LLVM_CONFIG=/usr/bin/llvm-config && \
    mkdir -p /usr/bin && \
    mv /usr/lib/llvm15/bin/llvm-config /usr/bin/llvm-config && \
    mkdir -p /usr/include && \
    mv /usr/lib/llvm15/include/* /usr/include && \
    mv /usr/lib/llvm15/* /usr/lib

# Clone llvmlite repo and compile llvmlite pkg
RUN git clone https://github.com/numba/llvmlite.git && \
    mkdir -p llvmlite/llvm && \
    mv /usr/lib/llvm15 llvmlite/llvm && \
    cd llvmlite && \
    python3 setup.py build && \
    python3 setup.py install && \
    cd ..

# Compile Numba pkg
RUN git clone https://github.com/numba/numba.git && \
    cd numba && \
    python3 setup.py install && \
    cd ..

# ADD PYTHON PACKAGES THAT REQUIRES NUMBA PACKAGE IN A REQUIREMENTS.TXT TO INSTALL
# -- uncomment line below to run installation
# RUN pip3 install --no-deps --no-cache-dir -r requirements.txt --target "${PYTHON_DEP_BUILD_PATH}"