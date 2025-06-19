FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1) Install CA certs so HTTPS works
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 2) Switch to HTTPS mirrors
RUN sed -i \
  -e 's|http://us.archive.ubuntu.com/ubuntu|https://us.archive.ubuntu.com/ubuntu|g' \
  -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
  -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' \
  /etc/apt/sources.list

# 3) Install the rest of your tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl git unzip xz-utils zip gnupg wget \
      libglu1-mesa openjdk-11-jdk ca-certificates-java \
      clang cmake ninja-build pkg-config \
      lib32stdc++6 lib32z1 \
 && rm -rf /var/lib/apt/lists/*

# 3.1) Desktop dev deps (GTK + eglinfo)  
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libgtk-3-dev \
      mesa-utils \
 && rm -rf /var/lib/apt/lists/*

# 4) Clone Flutter & disable analytics
RUN git clone --depth 1 --branch stable \
      https://github.com/flutter/flutter.git /opt/flutter \
 && /opt/flutter/bin/flutter config --no-analytics

# 5) Put flutter on the PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 6) Pre-warm the engine & artifacts
RUN flutter precache --all

# 7) Install Chrome (for web debugging)
RUN wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && dpkg -i /tmp/chrome.deb || (apt-get update && apt-get -fy install) \
 && rm /tmp/chrome.deb
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome-stable

# 8) Android cmdline-tools
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
 && wget -qO /tmp/cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
 && unzip /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
 && rm /tmp/cmdline-tools.zip \
 && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/tools

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
  && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
       "platform-tools" \
       "platforms;android-34" \
       "build-tools;34.0.0"

WORKDIR /workspace
CMD ["bash"]
