# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

FROM debian:12
LABEL authors="Julien Fischer"

ARG DIRECTORY="test_env"
WORKDIR /app

ENV PATH="/usr/local/bin:${PATH}"

#########################################################
# Dependencies
#########################################################

# Install coreutils which includes cat, ls, etc
RUN apt-get update && apt-get install -y coreutils && rm -rf /var/lib/apt/lists/*
# Install sudo
RUN apt update && apt install -y sudo
# Install git
RUN apt install -y bash git

#########################################################
# File gathering
#########################################################

# Generate the directory tree
RUN mkdir -p "${DIRECTORY}/help"
RUN mkdir -p "${DIRECTORY}"
RUN mkdir -p "${DIRECTORY}/tests"

# Copy the source code to the container
COPY tests/tests.sh "/app/${DIRECTORY}/tests"
COPY . "/app/${DIRECTORY}"

# make it executable
RUN chmod +x "/app/${DIRECTORY}/tests/tests.sh"
RUN chmod +x "/app/${DIRECTORY}/linx.sh"
RUN chmod +x "/app/${DIRECTORY}/install.sh"
RUN chmod +x "/app/${DIRECTORY}/uninstall.sh"

#########################################################
# Build
#########################################################

# Install Linx
RUN "/app/${DIRECTORY}/install.sh" -y

# Run the automated tests
ENTRYPOINT ["/app/test_env/tests/tests.sh"]


# keep the container running indefinitely for debugging / interacting with it
CMD ["tail", "-f", "/dev/null"]
