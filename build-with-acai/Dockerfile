#======================================
# Build Stage: Required python packages
#======================================

# Build-python-dependencies environment (using ACAI)
FROM acai:latest AS build-base

# Set build arguments
ARG BASE_PATH=/base
ARG PYTHON_DEP_BUILD_PATH=/dockerbuild_python_deps

# Create local directory to store packages
RUN mkdir -p "${PYTHON_DEP_BUILD_PATH}"

# Copy requirements.txt
COPY requirements.txt ${BASE_PATH}/

# Install Python packages
RUN pip3 install --no-deps -r ${BASE_PATH}/requirements.txt --target "${PYTHON_DEP_BUILD_PATH}"

#=======================================
# Runner Stage
#=======================================

# Production environment
FROM python:3.12-alpine3.20

# Set build arguments
ARG PYARROW_BUILD_PATH=/dockerbuild_pyarrow
ARG PYTHON_DEP_BUILD_PATH=/dockerbuild_python_deps

# Set environment variables
ENV TASK_ROOT=/var/task
ENV USER_NAME=test
ENV USER_ID=1001
ENV GROUP_NAME=test
ENV GROUP_ID=1001

# Create function directory
RUN mkdir -p "${TASK_ROOT}"

# Upgrade busybox (due to vulnerabilities flagged in older version)
RUN apk upgrade busybox

# Install system dependencies for python packages
RUN apk add --no-cache \
    curl-dev \
    gcc \
    gcompat \
    libcurl \
    libstdc++ \
    libthrift \
    re2-dev

# Create a group and add user
RUN addgroup -S ${GROUP_NAME} && \
adduser -S -u ${USER_ID} ${USER_NAME} -G ${GROUP_NAME}

# Copy pyarrow and its dependencies
RUN mkdir -p "/usr/local/lib/"
COPY --from=build-base /usr/local/lib/ /usr/local/lib/
COPY --from=build-base ${PYARROW_BUILD_PATH} ${TASK_ROOT}/

# Copy python dependencies
COPY --from=build-base ${PYTHON_DEP_BUILD_PATH} ${TASK_ROOT}/

# Copy function code
COPY lambda_function.py ${TASK_ROOT}/

# Set working directory to function root directory
WORKDIR ${TASK_ROOT}

# Set runtime interface client as default command for the container runtime
ENTRYPOINT [ "python", "-m", "awslambdaric" ]

# Set default parameters for docker's entrypoint
CMD ["lambda_function.lambda_handler"]