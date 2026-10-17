#!/usr/bin/env bash
# Cloud Agent install. Idempotent dependency setup after checkout.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gettext \
  libffi-dev \
  libjpeg-dev \
  liblcms2-2 \
  libmagic1 \
  libopenjp2-7 \
  libpq5 \
  libpq-dev \
  libssl-dev \
  libtiff6 \
  libwebp7 \
  libxml2 \
  libxml2-dev \
  libxslt1.1 \
  libxslt1-dev \
  media-types \
  pkg-config \
  postgresql \
  postgresql-contrib \
  python3-dev \
  python3-venv \
  redis-server \
  shared-mime-info \
  zlib1g-dev

if ! command -v uv >/dev/null 2>&1 || [[ "$(uv --version)" != "uv 0.12.1"* ]]; then
  curl -LsSf https://astral.sh/uv/0.12.1/install.sh | sudo env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh
fi

cd /workspace
if [[ ! -f .env ]]; then
  cp .env.example .env
fi

uv sync --frozen
