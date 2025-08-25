# Use uma imagem base
FROM debian:bookworm

# Defina variáveis de ambiente
ARG UNIFI_BRANCH=stable
ARG UBNT_PATH_REPOSITORY
ARG BUILD_DATE

# Obtenha a data e alimente a variável de ambiente
RUN if [ -z ${BUILD_DATE+x} ]; then \
    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
    fi

# Configure o ambiente
ENV DEBIAN_FRONTEND=noninteractive

# Atualize os pacotes e instale dependências básicas
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps curl wget gnupg software-properties-common libc6 libssl3
RUN apt-get install -y --no-install-recommends \
    ca-certificates-java java-common openjdk-17-jre-headless binutils logrotate binutils jsvc libcap2 \
    default-jre fonts-dejavu-extra fonts-ipafont-gothic fonts-ipafont-mincho fonts-wqy-microhei fonts-wqy-zenhei fonts-indic
RUN apt-get clean


# Instale o MongoDB
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-8.0.list

RUN apt-get update && apt-get install -y --no-install-recommends mongodb-org-server \
    && apt-get clean

# Adicione o repositório do UniFi
# RUN echo 'deb [ arch=amd64,arm64 ] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | tee /etc/apt/sources.list.d/100-ubnt-unifi.list \
#     && wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg \
#     && apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50

# Instale o UniFi Controller

# RUN apt-get update && apt download unifi && mv unifi_*.deb unifi.deb \
#     && dpkg -i --ignore-depends=mongodb-org-server unifi.deb \
#     && apt-get clean

ENV UBNT_BASE_URL=https://dl-origin.ubnt.com/unifi/debian/
RUN if [ -z ${UBNT_PATH_REPOSITORY+x} ]; then \
    UBNT_REPOSITORY_PATH=$(curl -sX GET ${UBNT_BASE_URL}dists/${UNIFI_BRANCH}/ubiquiti/binary-amd64/Packages \
    | grep -e 'Filename: ' \
    | awk -F ': ' '/Filename/{print $2;exit}'); \
    fi && \
    echo "Using UniFi repository path: ${UBNT_REPOSITORY_PATH}" && \
    curl -o /tmp/unifi.deb -L "${UBNT_BASE_URL}${UBNT_REPOSITORY_PATH}" && \
    dpkg -i /tmp/unifi.deb && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Adicione scripts de inicialização
RUN mkdir -p /scripts

COPY config/unifi /

WORKDIR /usr/lib/unifi

# Configure as portas do UniFi Controller
EXPOSE 8443 3478/udp 10001/udp 8080 1900/udp 8843 8880 6789 5514/udp

# Defina o ponto de entrada
CMD ["bash", "/scripts/run"] 