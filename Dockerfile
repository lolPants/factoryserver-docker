# syntax=docker/dockerfile:1.3
FROM steamcmd/steamcmd as steam

# Update SteamCMD
RUN steamcmd +quit

# ---
FROM steam as download

# Download server software
WORKDIR /satisfactory-dedicated
RUN steamcmd +login anonymous \
  +force_install_dir /satisfactory-dedicated \
  +app_update 1690800 \
  +quit

# ---
FROM debian:bullseye

ARG GIT_REPO
LABEL org.opencontainers.image.source=${GIT_REPO}

# Add new non-root user
RUN groupadd --gid 1000 server && \
  useradd --uid 1000 --gid server --shell /bin/bash --create-home server && \
  # Install dependencies
  apt-get update && \
  apt-get install -y ca-certificates libsdl2-2.0-0 && \
  rm -rf /var/lib/apt/lists/* && \
  # Setup directories
  mkdir /satisfactory-dedicated /data && \
  chown server:server /satisfactory-dedicated && \
  chown server:server /data

# Copy in server files and setup library path
COPY --from=download --chown=server:server /satisfactory-dedicated /satisfactory-dedicated
ENV LD_LIBRARY_PATH /satisfactory-dedicated/linux64

# Run as non-root user
USER server
WORKDIR /satisfactory-dedicated

# Setup /data symlink
RUN mkdir -p /home/server/.config/Epic/ && ln -s /data /home/server/.config/Epic/FactoryGame
VOLUME ["/data"]

ENTRYPOINT ["/satisfactory-dedicated/FactoryServer.sh"]
EXPOSE 15777/udp
EXPOSE 15000/udp
EXPOSE 7777/udp
