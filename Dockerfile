# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM quay.io/buildah/stable:v1.14.3

ENV KUBECTL_VERSION v1.17.0
ENV HELM_VERSION v3.0.2
ENV HOME=/home/theia
ENV BZL_VERSION=3.5.0
ENV BUIDLERS_VERSION=3.4.0
ENV JAVA_VERSION=latest
ENV JAVA_ARCH=x86_64

RUN mkdir /projects && mkdir -p /home/theia && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done && \
    # buildah login requires writing to /run
    chgrp -R 0 /run && chmod -R g+rwX /run && \
    curl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    curl -o- -L https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar xvz -C /usr/local/bin --strip 1 && \
    # 'which' utility is used by VS Code Kubernetes extension to find the binaries, e.g. 'kubectl'
    dnf install -y python3-devel wget gcc-c++ gcc file which unzip findutils nodejs git patch dnf-plugins-core java-${JAVA_VERSION}-openjdk-devel.${JAVA_ARCH} && \
    dnf install -y python38 python https://rpmfind.net/linux/fedora/linux/updates/31/Everything/x86_64/Packages/b/binutils-gold-2.32-31.fc31.x86_64.rpm && \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    wget -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/fedora/31/prod.repo && \
    dnf install -y dotnet-sdk-3.1 aspnetcore-runtime-3.1
    #dnf copr enable -y vbatts/bazel && \
    #dnf install -y bazel2

RUN cd /tmp && wget https://github.com/bazelbuild/bazel/releases/download/${BZL_VERSION}/bazel-${BZL_VERSION}-linux-x86_64 && mv bazel-${BZL_VERSION}-linux-x86_64 /bin/bazel && chmod +x /bin/bazel

RUN cd /tmp && wget https://github.com/bazelbuild/buildtools/releases/download/${BUIDLERS_VERSION}/buildifier && chmod 777 buildifier && mv buildifier /usr/bin/

RUN cd /tmp && wget https://github.com/bazelbuild/buildtools/releases/download/${BUIDLERS_VERSION}/buildozer && chmod 777 buildozer && mv buildozer /usr/bin/

RUN mkdir /projects/googleapis && git clone https://github.com/googleapis/googleapis.git /projects/googleapis && cd /projects/googleapis && ls -alh && \
    bazel fetch ...: && \
    bazel run -- //:build_gen --src=google/api/servicemanagement/v1 && bazel run -- //:build_gen --src=google/api/servicecontrol/v1 && \
    bazel run -- //:build_gen --src=google/api && bazel run -- //:build_gen --src=google/spanner && bazel run -- //:build_gen --src=google/monitoring/v3 && \
    sed -i "s/\/\/google/@com_google_googleapis\/\/google/g" google/spanner/BUILD.bazel && \
    sed -i "s/\/\/google/@com_google_googleapis\/\/google/g" google/monitoring/v3/BUILD.bazel && \
    sed -i "s/\/\/google/@com_google_googleapis\/\/google/g" google/api/servicemanagement/v1/BUILD.bazel
    sed -i "s/\/\/google/@com_google_googleapis\/\/google/g" google/api/servicecontrol/v1/BUILD.bazel
    bazel fetch //google/api/...: && bazel fetch //google/spanner/...: && bazel fetch //google/monitoring/v3/...: 

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
