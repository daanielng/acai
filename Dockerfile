# Base image
FROM python:3.12-alpine3.20

# Set build arguments
ARG PYARROW_BUILD_PATH=/dockerbuild_pyarrow

# Create local directory to store packages
RUN mkdir -p "${PYARROW_BUILD_PATH}"

# Upgrade busybox
RUN apk upgrade busybox

# Add 3.19 alpine repo to install older autoconf package version
RUN echo https://dl-cdn.alpinelinux.org/alpine/v3.19/main >> /etc/apk/repositories
RUN echo https://dl-cdn.alpinelinux.org/alpine/v3.19/community >> /etc/apk/repositories

# ----------------- NOTES ------------------
# List of system dependencies required to persist in runner image of any application
# -> curl-dev, gcc, gcompat, libcurl, libstdc++, libthrift, re2-dev
# ------------------------------------------

# Install system dependencies for building python packages
RUN apk add \
    abseil-cpp-cord \
    abseil-cpp-flags-internal \
    abseil-cpp-flags-marshalling \
    autoconf=2.71-r2 \
    automake \
    build-base \
    cmake \
    curl-dev \
    elfutils-dev \
    gcc \
    gcompat \
    git \
    g++ \
    make \
    musl-dev \
    libcurl \
    libstdc++ \
    libtool \
    re2-dev

# Install system dependencies for arrow 
RUN apk add \
    automake \
    bash \
    build-base \
    boost-dev \
    curl-dev \
    c-ares \
    clang16-extra-tools \
    cmake \
    elfutils-dev \
    gcc \
    gcompat \
    git \
    g++ \
    jemalloc-dev \
    libcurl \
    libstdc++ \
    libtool \
    libunwind-dev \
    musl-dev \
    make \
    rapidjson \
    re2-dev \
    thrift-dev \
    utf8proc \
    unzip \
    xsimd-dev

# Install python dependencies for pyarrow
RUN pip install --no-cache-dir setuptools-scm six numpy cython

# Build Arrow C++ libraries
RUN export ARROW_HOME=/usr/local && \
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH && \
    export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH && \
    export PARQUET_HOME=/usr/local && \
    export PYARROW_WITH_PARQUET=1 && \
    export PYARROW_WITH_DATASET=1 && \
    export PYARROW_WITH_HDFS=1 && \
    export PYARROW_WITH_JSON=1 && \
    export PYARROW_WITH_S3=1 && \
    export PYARROW_WITH_CSV=1

# Clone Arrow repo and build Arrow libraries
RUN git clone https://github.com/apache/arrow.git
RUN cd arrow/cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DARROW_COMPUTE=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DARROW_CSV=ON \
    -DARROW_S3=ON \
    -DARROW_PARQUET=ON \
    -DARROW_HDFS=ON \
    -DARROW_DATASET=ON \
    -DARROW_JSON=ON \
    -DARROW_FILESYSTEM=ON && \
    make -j4 && \
    make install

# Build pyarrow and move folder to custom directory
RUN cd arrow/python && \
    python3 setup.py build_ext --with-parquet --inplace && \
    mv -R pyarrow ${PYARROW_BUILD_PATH}/
