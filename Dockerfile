# 1. Pick a base image with the tools we need
FROM ubuntu:22.04

# 2. Install prerequisites
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      curl git unzip xz-utils zip libglu1-mesa openjdk-11-jdk ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 3. Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
    && /opt/flutter/bin/flutter config --no-analytics

# 4. Add Flutter (and Dart) to PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 5. Pre-warm Flutter (downloads engine + web + linux artifacts)
RUN flutter channel stable \
 && flutter upgrade --force \
 && flutter precache --all \
 && flutter doctor -v

# 6. Set your workspace
WORKDIR /workspace

# 7. Default command: run a shell
CMD ["bash"]
