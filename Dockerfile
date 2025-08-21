#Install Package: miniconda
FROM ubuntu:24.04 AS common_pkg_provider

ARG CONDA_DIR=/opt/conda
ARG CONDA_VER=latest  
ENV PATH=${CONDA_DIR}/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64)   conda_arch="x86_64"  ;; \
      arm64)   conda_arch="aarch64" ;; \
      ppc64el) conda_arch="ppc64le" ;; \
      s390x)   conda_arch="s390x"   ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    url="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VER}-Linux-${conda_arch}.sh"; \
    echo "Downloading: $url"; \
    curl -fsSL "$url" -o /tmp/miniconda.sh; \
    bash /tmp/miniconda.sh -b -p "${CONDA_DIR}"; \
    rm -f /tmp/miniconda.sh; \
    ln -sf "${CONDA_DIR}/etc/profile.d/conda.sh" /etc/profile.d/conda.sh; \
    "${CONDA_DIR}/bin/conda" config --system --set auto_update_conda false; \
    "${CONDA_DIR}/bin/conda" clean -afy

#Install Package: Verilator
FROM ubuntu:24.04 AS verilator_provider
RUN apt-get update && apt-get install -y --no-install-recommends \
    git make g++ \
    autoconf flex bison \
    libfl2 libfl-dev \
    zlib1g zlib1g-dev \
    perl python3 \
    pkg-config help2man \
    ca-certificates curl \
    make autoconf g++ flex bison \
    libfl2 libfl-dev zlib1g zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/verilator/verilator.git /tmp/verilator && \
    cd /tmp/verilator && \
    autoconf && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/verilator

#Install Package: Systemc
FROM ubuntu:24.04 AS systemc_provider
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake ninja-build \
    curl ca-certificates tar \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

ARG SYSTEMC_VERSION=2.3.4
ARG SYSTEMC_PREFIX=/opt/systemc

RUN set -eux; \
    curl -fsSL -o /tmp/systemc.tar.gz \
      https://github.com/accellera-official/systemc/archive/refs/tags/${SYSTEMC_VERSION}.tar.gz; \
    mkdir -p /tmp/systemc-src; \
    tar -xzf /tmp/systemc.tar.gz -C /tmp/systemc-src --strip-components=1; \
    cd /tmp/systemc-src; \
    cmake -S . -B build \
      -DCMAKE_INSTALL_PREFIX="${SYSTEMC_PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_CXX_EXTENSIONS=ON \
      -DBUILD_SHARED_LIBS=ON \
      -G Ninja; \
    cmake --build build -j"$(nproc)"; \
    cmake --install build; \
    rm -rf /tmp/systemc.tar.gz /tmp/systemc-src


#Base Image(Stage base)
FROM ubuntu:24.04 AS base

# Add Environment Settings in Stage base
ENV TZ=Asia/Taipei
ARG UID=1001
ARG GID=1001
ARG USERNAME=user

RUN groupadd -g ${GID} ${USERNAME} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

#Copy built stages to Stage base
COPY --from=common_pkg_provider /opt/conda /opt/conda
COPY --from=common_pkg_provider /etc/profile.d/conda.sh /etc/profile.d/conda.sh
ENV PATH=/opt/conda/bin:$PATH

COPY --from=verilator_provider /usr/local /usr/local
ENV PATH=/usr/local/bin:$PATH

COPY --from=systemc_provider /opt/systemc /opt/systemc
COPY --from=systemc_provider /etc/ld.so.conf.d /etc/ld.so.conf.d
RUN echo "/opt/systemc/lib" > /etc/ld.so.conf.d/systemc.conf && ldconfig
ENV SYSTEMC_HOME=/opt/systemc
ENV SYSTEMC_CXXFLAGS="-I/opt/systemc/include -std=gnu++17"
ENV SYSTEMC_LDFLAGS="-L/opt/systemc/lib -lsystemc -lm -lpthread"

RUN chown -R ${USERNAME}:${USERNAME} /opt/conda /opt/systemc /usr/local

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD [ "bash" ]


# docker build -t test .
# docker run --rm -it test
# g++ $SYSTEMC_CXXFLAGS test.cpp $SYSTEMC_LDFLAGS -o test && ./test