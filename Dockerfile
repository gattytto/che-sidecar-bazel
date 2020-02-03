# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM debian:10-slim

ENV HOME=/home/theia

# Install bazel (https://docs.bazel.build/versions/master/install-ubuntu.html)
RUN apt-get -y install openjdk-8-jdk && \
    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add - && \
    apt-get update && \

    apt-get -y install bazel && \
    apt-get -y upgrade bazel 

RUN apt-get update && \
    apt-get install git wget gnupg unzip -y && \
    echo 'deb http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main' >> /etc/apt/sources.list && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    wget -O - https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && \
    apt-get install nodejs clangd-8 clang-8 clang-format-8 gdb autoconf gcc g++ libc6 make bison libxml2-dev -y && \
    apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-8 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-8 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-8 100

RUN cd /tmp && mkdir protoc-download && cd protoc-download && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v3.11.2/protoc-3.11.2-linux-x86_64.zip && \
    unzip protoc-3.11.2-linux-x86_64.zip && rm -f protoc-3.11.2-linux-x86_64.zip && \
    cp bin/protoc /usr/local/bin && cd ../ && rm -rf protoc-download
    
RUN cd /tmp && mkdir googleapis-download && cd googleapis-download && \
    wget https://github.com/googleapis/googleapis/archive/master.zip && unzip master.zip && \
    mkdir -p /go/src/github.com/googleapis && mv googleapis-master /go/src/github.com/googleapis/googleapis && \
    cd / && rm -rf /tmp/googleapis-download
    
RUN cd /tmp && wget https://github.com/bazelbuild/buildtools/releases/download/0.29.0/buildifier && chmod 777 buildifier && mv buildifier /usr/bin/

RUN cd /tmp && wget https://github.com/bazelbuild/buildtools/releases/download/0.29.0/buildozer && chmod 777 buildozer && mv buildozer /usr/bin/

#RUN cd /tmp && wget https://github.com/bazelbuild/bazel/releases/download/2.0.0/bazel-2.0.0-linux-x86_64 && chmod 777 bazel-2.0.0-linux-x86_64 && mv bazel-2.0.0-linux-x86_64 /usr/bin/bazel

RUN mkdir /projects ${HOME} && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects" "/go"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
