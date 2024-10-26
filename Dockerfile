# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

FROM debian:12
LABEL authors="Julien Fischer"

# Input parameters
ARG KEEP_ALIVE=""
ARG INTERACTIVE=""
# Constants
ARG UID=1001
ARG GID=1001
ARG USERNAME="john"
ARG GROUP="john"
ARG DIRECTORY="linx"
ARG WORK_DIR="/home/${USERNAME}/Desktop/${DIRECTORY}"

ENV PATH="/usr/local/bin:${PATH}"
ENV HOME="/home/${USERNAME}"

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
    groupadd -g "${GID}" ${GROUP} && \
    useradd -m -u "${UID}" -s /bin/bash -g ${GROUP} ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#########################################################
# File gathering
#########################################################

# Generate the directory tree
RUN mkdir -p \
    "${WORK_DIR}/help" \
    "${WORK_DIR}/tests/suites" \
    "${WORK_DIR}/commands"

# Add Linx source
COPY tests/test-runner.sh "${WORK_DIR}/tests"
COPY tests/suites/* "${WORK_DIR}/tests/suites"
COPY commands/* "${WORK_DIR}/commands"
COPY . ${WORK_DIR}

# Grant execute permission
RUN chmod +x \
    "${WORK_DIR}/commands/"* \
    "${WORK_DIR}/linx.sh" \
    "${WORK_DIR}/install.sh" \
    "${WORK_DIR}/uninstall.sh" \
    "${WORK_DIR}/tests/test-runner.sh"

# Transfer ownership to user john
RUN chown -R john:john \
    /home \
    /home/john \
    /home/john/Desktop \
    /home/john/Desktop/linx \
    /home/john/Desktop/linx/tests


#########################################################
# Build
#########################################################

# Install Linx
RUN "${WORK_DIR}/install.sh" -y

WORKDIR ${WORK_DIR}

# Step down from root user permissions
USER ${USERNAME}

# Run the tests
ENTRYPOINT ["/bin/bash", "/home/john/Desktop/linx/tests/test-runner.sh"]
