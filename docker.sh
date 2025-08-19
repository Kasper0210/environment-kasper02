#!/usr/bin/env bash
set -euo pipefail

# Defaults 
IMAGE_NAME=""
CONT_NAME=""
USERNAME="${USER:-user}"
HOSTNAME_DEF=""
MOUNTS=()                 
DOCKERFILE="Dockerfile"   

log() { printf "[INFO] %s\n" "$*" >&2; }
warn(){ printf "[WARN] %s\n" "$*" >&2; }
die() { printf "[ERR ] %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
usage：
  ./docker.sh build         [--image-name NAME] [--dockerfile PATH]
  ./docker.sh run           [--image-name NAME] [--cont-name NAME] [--username USER] [--hostname NAME] [--mount HOST[:CONT]]...
  ./docker.sh clean         [--image-name NAME] [--cont-name NAME]
  ./docker.sh rebuild       [--image-name NAME] [--cont-name NAME] [--dockerfile PATH] [其餘同 run]

parameter：
  --image-name NAME     指定 image 名稱
  --cont-name NAME      指定 container 名稱
  --username USER       指定容器內要使用的使用者名稱
  --hostname NAME       指定容器 hostname
  --mount HOST[:CONT]   綁定目錄，可重複。若只給 HOST，則掛載到容器同路徑 HOST。
                        例：--mount /home/me/work:/workspace  或  --mount /home/me/work
  --dockerfile PATH     指定 Dockerfile 路徑（預設：./Dockerfile）

example：
  ./docker.sh run \
      --username "$USER" \
      --mount /data \
      --mount /home \
      --image-name aoc2026-env \
      --cont-name aoc2026-dev

  ./docker.sh clean --image-name aoc2026-env --cont-name aoc2026-dev
  ./docker.sh rebuild --image-name aoc2026-env
USAGE
}

# 解析子命令
CMD="${1:-}"; shift || true
[[ -z "${CMD}" ]] && { usage; exit 1; }

# 解析通用參數
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image-name)   IMAGE_NAME="${2:?}"; shift 2;;
    --cont-name)    CONT_NAME="${2:?}"; shift 2;;
    --username)     USERNAME="${2:?}"; shift 2;;
    --hostname)     HOSTNAME_DEF="${2:?}"; shift 2;;
    --mount)        MOUNTS+=("${2:?}"); shift 2;;
    --dockerfile)   DOCKERFILE="${2:?}"; shift 2;;
    -h|--help)      usage; exit 0;;
  esac
done

# Docker status
image_exists() {
  docker image inspect "$IMAGE_NAME" >/dev/null 2>&1
}

container_exists() {
  docker container inspect "$CONT_NAME" >/dev/null 2>&1
}

container_is_running() {
  [[ "$(docker ps -q -f "name=^${CONT_NAME}$")" != "" ]]
}

container_status() {
  if container_exists; then
    if container_is_running; then
      echo "running"
    else
      echo "stopped"
    fi
  else
    echo "not_existed"
  fi
}

# Build Image
build_image() {
  if image_exists; then
    warn "Image exist：${IMAGE_NAME}"
    echo "If tou want to delete：docker rmi -f ${IMAGE_NAME}"
    return 0
  fi
  log "Build image：${IMAGE_NAME}（Dockerfile=${DOCKERFILE}）"
  docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE}" .
  log "Finish：${IMAGE_NAME}"
}

# Run / Attach Container
make_mount_args() {
  local args=()
  for m in "${MOUNTS[@]:-}"; do
    if [[ "$m" == *:* ]]; then
      local host="${m%%:*}"; local cont="${m#*:}"
      args+=("-v" "${host}:${cont}")
    else
      args+=("-v" "${m}:${m}")
    fi
  done
  printf '%s\n' "${args[@]}"
}

run_container() {
  if ! image_exists; then
    log "Image not existed，building：${IMAGE_NAME}"
    build_image
  fi

  local status
  status="$(container_status)"
  log "Container status：${status}"

  local uid gid
  uid="$(id -u)"; gid="$(id -g)"

  case "$status" in
    running)
      exec docker exec -it "${CONT_NAME}" bash
      ;;
    stopped)
      docker start "${CONT_NAME}" >/dev/null
      exec docker exec -it "${CONT_NAME}" bash
      ;;
    not_existed)
      readarray -t MOUNT_ARGS < <(make_mount_args)
      MOUNT_ARGS+=( -v "$PWD:/workspace" )

    exec docker run -it \
      --name "${CONT_NAME}" \
      --hostname "${HOSTNAME_DEF}" \
      --user "${uid}:${gid}" \
      -e USER="${USERNAME}" -e USERNAME="${USERNAME}" \
      -e HOME=/workspace \
      -w /workspace \
      "${MOUNT_ARGS[@]}" \
      "${IMAGE_NAME}" \
      bash
      ;;
    *)
      die "未知狀態：${status}"
      ;;
  esac
}

# Clean & Rebuild
clean_all() {
  if container_exists; then
    if container_is_running; then
      docker stop "${CONT_NAME}" >/dev/null || true
    fi
    docker rm -f "${CONT_NAME}" >/dev/null || true
  fi

  if image_exists; then
    docker rmi -f "${IMAGE_NAME}" >/dev/null || true
  fi
}

rebuild_all() {
  clean_all
  build_image
}

# Main switch
case "$CMD" in
  build)   build_image ;;
  run)     run_container ;;
  clean)   clean_all ;;
  rebuild) rebuild_all ;;
  *)       usage; exit 1 ;;
esac
