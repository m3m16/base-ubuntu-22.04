# Base image
FROM ubuntu:22.04

# Maintainer information
LABEL maintainer="m3m16 <mapmapmaptema@proton.me>"

# Disable TTY interaction
ARG DEBIAN_FRONTEND=noninteractive

# Install essential packages and prepare for package installations
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        locales \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install and setup gosu
ENV GOSU_VERSION 1.14
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    command -v gpgconf && gpgconf --kill all || :; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# Update system packages, install core dependencies
# and generate default locales
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        curl \
        git \
        sudo \
        libarchive-tools \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Create a default user and group (docker)
# (also sets permissions for the /app volume)
RUN groupadd \
        --system \
        --gid 1000 \
        docker && \
    useradd \
        --create-home \
        --home /app \
        --uid 1000 \
        --gid 1000 \
        --groups docker,users,staff \
        --shell /bin/false \
        docker && \
    mkdir -p /app && \
	chown -R docker:docker /app

# Set default environment variables
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.utf8
ENV TERM xterm
ENV TZ Etc/UTC
ENV PGID 1000
ENV PUID 1000
ENV CHOWN_DIRS "/app"
ENV ENABLE_PASSWORDLESS_SUDO "false"


# Add base image initialization script
ADD ./ex/exe.sh /exe.sh
RUN chmod +x /exe.sh

# Set the main entry point to our initialization script
ENTRYPOINT ["/exe.sh"]

# Set the default command to run
CMD ["/bin/bash"]
