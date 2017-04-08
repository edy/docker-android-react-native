RUN if [ -z {$NAME} ] \
        exit 1

FROM openjdk:8-jdk

ENV ANDROID_SDK_FILENAME android-sdk_r24.4.1-linux.tgz
ENV ANDROID_SDK_URL http://dl.google.com/android/${ANDROID_SDK_FILENAME}
ENV ANDROID_API_LEVELS android-25,android-24,android-23
ENV ANDROID_BUILD_TOOLS_VERSION 23.0.3
ENV ANDROID_HOME /usr/local/opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.9.1

RUN dpkg --add-architecture i386 && \
    apt-get update -y && \
    apt-get install -y \
        expect \
        lib32gcc1 \
        lib32gomp1 \
        lib32ncurses5 \
        lib32stdc++6 \
        lib32z1 \
        lib32z1-dev \
        libc6-i386 \
        libc6:i386 \
        libncurses5:i386 \
        libstdc++6:i386 \
        proguard \
        lftp \
    && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean

# Install Android SDK
RUN mkdir -p /usr/local/opt && \
    ln -s /usr/local/opt/android-sdk-linux /usr/local/opt/android-sdk && \
    cd /usr/local/opt && \
    curl -sSLO ${ANDROID_SDK_URL} && \
    tar -xzf ${ANDROID_SDK_FILENAME} && \
    rm ${ANDROID_SDK_FILENAME}

RUN ( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) | android update sdk --no-ui -a --filter tools,platform-tools,${ANDROID_API_LEVELS},build-tools-23.0.1,build-tools-${ANDROID_BUILD_TOOLS_VERSION},extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,addon-google_apis-google-24,extra-android-support

# Install nodejs
RUN set -ex \
    && for key in \
        9554F04D7259F04124DE6B476D5A82AC7E37093B \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    ; do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done && \
    curl -sSLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -sSLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

RUN npm install -g react-native-cli

RUN react-native init {$NAME}

VOLUME [ "/{$NAME}" ]
WORKDIR [ "/{$NAME}" ]
