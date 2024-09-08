# Alpine Containers for AI (ACAI) :bowl_with_spoon::grapes::blueberries:
A base image called "ACAI" (pronounced "ahh-saa-ee") to build Python packages for data science/AI applications that are compatible with [Alpine Linux](https://hub.docker.com/_/alpine).

#### Benefits of Using ACAI in [Multi-Stage](https://docs.docker.com/build/building/multi-stage/) Builds:
1. System dependencies for popular Python packages are already compiled on ACAI
    - which means you can just proceed to run `pip install` to install the packages
2. Smaller generated images
3. Fewer vulnerabilities for threat actors to exploit
4. Faster CI/CD builds

_Refer to `build-with-acai` folder for an example on how to use `acai`._

## Building `acai` :grapes:

Run `docker build`:
- Ensure you are within the `acai` directory.
- Since the size of `acai` is large, ensure you have enough disk space to store it on your local machine.
```bash
docker build -t acai:latest .
```
or `podman build`:
```bash
podman build -t acai:latest .
```

## Multi-Stage Build with `acai` :bowl_with_spoon:
Using a working example to build an AWS Lambda image for data processing.

```dockerfile
#======================================
# Build Stage: Required python packages
#======================================

# Use ACAI to build python packages
FROM acai:latest as build-base

# Set build arguments
ARG BASE_PATH=/base
ARG PYTHON_DEP_BUILD_PATH=/dockerbuild_python_deps

# Copy requirements.txt
COPY requirements.txt ${BASE_PATH}/

# Install Python packages
RUN pip3 install --no-deps -r ${BASE_PATH}/requirements.txt --target "${PYTHON_DEP_BUILD_PATH}"

#=======================================
# Runner Stage
#=======================================

# Production Environment
FROM python:3.12-alpine3.20

# Set build arguments
ARG PYARROW_BUILD_PATH=/dockerbuild_pyarrow
ARG PYTHON_DEP_BUILD_PATH=/dockerbuild_python_deps
ARG BASE_PATH=/base

# Set environment variables
ENV TASK_ROOT=/var/task

# Create function directory
RUN mkdir -p "${TASK_ROOT}"

# Install system dependencies for python packages
RUN apk add --no-cache \
    curl-dev \
    gcc \
    gcompat \
    libcurl \
    libstdc++ \
    libthrift \
    re2-dev

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
```
1. Use the first `FROM` statement to specify `acai` as the base image to build the python packages.
    - `RUN pip3 install --no-deps -r ${BASE_PATH}/requirements.txt --target "${PYTHON_DEP_BUILD_PATH}"`
        - `--no-deps`: This flag is used to avoid installing each package's dependencies, as `acai` should already handle them.
        - `--target`: This flag specifies the destination path for the installed python packages.
2. Use the second `FROM` statement to specify `python:3.12-alpine3.20` as the base image, copy the Python packages from the build stage, and install any specific system dependencies required by those Python packages.
    - `COPY --from=build-base ${PYTHON_DEP_BUILD_PATH} ${TASK_ROOT}/`: 
        - This command copies all compiled python packages from the build stage into the final image's working directory.

The final image is a lightweight and secure container image that only includes what is necessary to run your application. You may need to install additional system dependencies in the final image to support other Python packages.

## Features :coconut:
ACAI contains C and C++ binaries used to build and compile many common python packages used for data science/AI.

It can directly build common data science packages such as `pandas` (which uses `pyarrow` under the hood - a PITA to build from scratch so I have it built into `acai`) and `numpy`.

Feel free to add on system dependencies inside ACAI's `Dockerfile` to expand its capabilities to build specific python packages.

## Dependencies :blueberries:
Application code needs to be written in python 3.12, with all python packages compatible with this version.
