# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

FROM debian:12
LABEL authors="Julien Fischer"

ARG UID=1001
ARG GID=1001
ARG USERNAME="john"
ARG DIRECTORY="linx"
ARG WORK_DIR="/home/${USERNAME}/Desktop/${DIRECTORY}"

ENV PATH="/usr/local/bin:${PATH}"

#########################################################
# Dependencies
#########################################################

# Install coreutils (which includes cat, ls, etc) and other required dependencies
# Create user john and grant it sudo permissions
RUN apt-get update && apt-get install -y \
    coreutils \
    lsof \
    git \
    sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    groupadd -g "${GID}" testgroup && \
    useradd -m -u "${UID}" -s /bin/bash -g testgroup ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#########################################################
# File gathering
#########################################################

# Generate the directory tree
RUN mkdir -p \
    "${WORK_DIR}/help" \
    "${WORK_DIR}/tests" \
    "${WORK_DIR}/commands"

# Copy the source code to the container
COPY tests/tests.sh "${WORK_DIR}/tests"
COPY commands/* "${WORK_DIR}/commands"
COPY . ${WORK_DIR}

# make scripts executable
RUN chmod +x \
    "${WORK_DIR}/commands/"* \
    "${WORK_DIR}/linx.sh" \
    "${WORK_DIR}/install.sh" \
    "${WORK_DIR}/uninstall.sh" \
    "${WORK_DIR}/tests/tests.sh"

#########################################################
# Build
#########################################################
WORKDIR ${WORK_DIR}

# Install Linx
RUN "${WORK_DIR}/install.sh" -y

# Step down from root user permissions
#USER ${USERNAME}


# Run the tests
ENTRYPOINT ["/home/john/Desktop/linx/tests/tests.sh"]


# keep the container running in the background for debugging and live interaction
#CMD ["tail", "-f", "/dev/null"]
