#!/bin/bash
set -eu

cat <<"EOF"
         o           o__ __o           o           o__ __o     o         o      o__ __o     __o              
        <|>         <|     v\         <|>         /v     v\   <|>       <|>    /v     v\    __|>             
        / \         / \     <\        / \        />       <\  / \       / \   />       <\     |              
      o/   \o       \o/     o/      o/   \o    o/             \o/       \o/  _\o____         <o>       __o__ 
     <|__ __|>       |__  _<|      <|__ __|>  <|               |         |        \_\__o__    |       />  \  
     /       \       |       \     /       \   \\             < >       < >             \    < >      \o     
   o/         \o    <o>      /   o/         \o   \         /   \         /    \         /     |        v\    
  /v           v\    |      o   /v           v\   o       o     o       o      o       o      o         <\   
 />             <\  / \  __/>  />             <\  <\__ __/>     <\__ __/>      <\__ __/>    __|>_  _\o__</   

    Install ABACUS in one second.
EOF

progress=0
total_progress=5
logging() {
  echo -e "\033[32mABACUS1s [${progress}/${total_progress}] $1\033[0m"
}
logging "This script will automatically download and install ABACUS (${ABACUS_VERSION:-"lastest version"}) for you."

ABACUS1S_HOME=${ABACUS1S_HOME:-~/.abacus1s}
export PIXI_HOME=$ABACUS1S_HOME
ABACUS1S_BIN_PATH=$ABACUS1S_HOME/bin
ABACUS1S_CACHE_DIR=${ABACUS1S_CACHE_DIR:-"$ABACUS1S_HOME/cache"}
ABACUS1S_MIRROR_CACHE=${ABACUS1S_MIRROR_CACHE:-"$ABACUS1S_CACHE_DIR/mirror-choice"}
ABACUS1S_MIRROR_CACHE_TTL=${ABACUS1S_MIRROR_CACHE_TTL:-86400}

conda_mirror_names() {
  if [[ -n "${ABACUS1S_CONDA_MIRRORS:-}" ]]; then
    echo "${ABACUS1S_CONDA_MIRRORS}" | tr ',' ' '
  else
    echo "ustc tuna bfsu nju pku hit njtech nyist ha sjtu sustech zju lzu cqupt conda-forge"
  fi
}

pixi_mirror_names() {
  if [[ -n "${ABACUS1S_PIXI_MIRRORS:-}" ]]; then
    echo "${ABACUS1S_PIXI_MIRRORS}" | tr ',' ' '
  else
    echo "github ghfast ghproxy ghproxy-v4 ghproxy-v6 ghproxy-cdn"
  fi
}

conda_mirror_base() {
  case "$1" in
    conda-forge|official) echo "conda-forge" ;;
    ustc) echo "https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/" ;;
    tuna) echo "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/" ;;
    bfsu) echo "https://mirrors.bfsu.edu.cn/anaconda/cloud/conda-forge/" ;;
    nju) echo "https://mirror.nju.edu.cn/anaconda/cloud/conda-forge/" ;;
    pku) echo "https://mirrors.pku.edu.cn/anaconda/cloud/conda-forge/" ;;
    hit) echo "https://mirrors.hit.edu.cn/anaconda/cloud/conda-forge/" ;;
    njtech) echo "https://mirrors.njtech.edu.cn/anaconda/cloud/conda-forge/" ;;
    nyist) echo "https://mirror.nyist.edu.cn/anaconda/cloud/conda-forge/" ;;
    ha) echo "https://mirrors.ha.edu.cn/anaconda/cloud/conda-forge/" ;;
    sjtu) echo "https://mirror.sjtu.edu.cn/anaconda/cloud/conda-forge/" ;;
    sustech) echo "https://mirrors.sustech.edu.cn/anaconda/cloud/conda-forge/" ;;
    zju) echo "https://mirrors.zju.edu.cn/anaconda/cloud/conda-forge/" ;;
    lzu) echo "https://mirror.lzu.edu.cn/anaconda/cloud/conda-forge/" ;;
    cqupt) echo "https://mirrors.cqupt.edu.cn/anaconda/cloud/conda-forge/" ;;
    http://*|https://*) echo "$1" ;;
    *) return 1 ;;
  esac
}

conda_mirror_probe() {
  local base="$1"
  if [[ "${base}" == "conda-forge" ]]; then
    echo "https://conda.anaconda.org/conda-forge/noarch/current_repodata.json"
  else
    echo "${base%/}/noarch/current_repodata.json"
  fi
}

pixi_mirror_base() {
  case "$1" in
    github|official) echo "https://github.com/prefix-dev/pixi" ;;
    ghfast) echo "https://ghfast.top/https://github.com/prefix-dev/pixi" ;;
    ghproxy) echo "https://gh-proxy.org/https://github.com/prefix-dev/pixi" ;;
    ghproxy-v4) echo "https://v4.gh-proxy.org/https://github.com/prefix-dev/pixi" ;;
    ghproxy-v6) echo "https://v6.gh-proxy.org/https://github.com/prefix-dev/pixi" ;;
    ghproxy-cdn) echo "https://cdn.gh-proxy.org/https://github.com/prefix-dev/pixi" ;;
    http://*|https://*) echo "$1" ;;
    *) return 1 ;;
  esac
}

pixi_mirror_probe() {
  local base="$1"
  echo "${base%/}/releases/latest/download/pixi-x86_64-unknown-linux-musl.tar.gz"
}

probe_url() {
  local url="$1"
  curl -fsSL --connect-timeout "${ABACUS1S_MIRROR_CONNECT_TIMEOUT:-60}" --max-time "${ABACUS1S_MIRROR_TIMEOUT:-60}" \
    --range 0-8191 -o /dev/null -w '%{time_total}' "$url"
}

pick_fastest_mirror() {
  local kind="$1"
  local tmpdir result_file name base probe_time probe_url_path mirror_list pending pids pid
  tmpdir=$(mktemp -d)

  case "$kind" in
    conda) mirror_list=$(conda_mirror_names) ;;
    pixi) mirror_list=$(pixi_mirror_names) ;;
    *) return 1 ;;
  esac

  pids=""
  pending=0
  for name in $mirror_list; do
    case "$kind" in
      conda)
        base=$(conda_mirror_base "$name" 2>/dev/null || true)
        [[ -n "$base" ]] || continue
        probe_url_path=$(conda_mirror_probe "$base")
        ;;
      pixi)
        base=$(pixi_mirror_base "$name" 2>/dev/null || true)
        [[ -n "$base" ]] || continue
        probe_url_path=$(pixi_mirror_probe "$base")
        ;;
      *) return 1 ;;
    esac
    result_file="$tmpdir/${kind}-${pending}-${name//[^A-Za-z0-9_.-]/_}"
    (
      if probe_time=$(probe_url "$probe_url_path" 2>/dev/null); then
        printf 'ok\t%s\t%s\t%s\t%s\n' "$probe_time" "$name" "$base" "$probe_url_path" > "$result_file"
      else
        printf 'failed\t%s\t%s\t%s\n' "$name" "$base" "$probe_url_path" > "$result_file"
      fi
    ) &
    pids="$pids $!"
    pending=$((pending + 1))
  done

  if [[ "$pending" -eq 0 ]]; then
    rm -rf "$tmpdir"
    return 1
  fi

  local finished success_line completed=0 status probe_seconds result_name result_base result_probe_url
  while (( completed < pending )); do
    for result_file in "$tmpdir"/${kind}-*; do
      [[ -f "$result_file" ]] || continue
      finished="$result_file.done"
      [[ -e "$finished" ]] && continue
      : > "$finished"
      completed=$((completed + 1))

      IFS=$'\t' read -r status probe_seconds result_name result_base result_probe_url < "$result_file" || true
      if [[ "$status" == "ok" ]]; then
        success_line=$(cat "$result_file")
        for pid in $pids; do
          kill "$pid" 2>/dev/null || true
        done
        wait 2>/dev/null || true
        IFS=$'\t' read -r status probe_seconds result_name result_base result_probe_url <<< "$success_line"
        printf '%s\t%s\t%s\n' "$result_name" "$result_base" "$probe_seconds"
        rm -rf "$tmpdir"
        return 0
      fi
    done
    sleep 0.05
  done

  wait 2>/dev/null || true
  rm -rf "$tmpdir"
  return 1
}

read_mirror_cache() {
  [[ -f "$ABACUS1S_MIRROR_CACHE" ]] || return 1
  local now ts cache_conda_name cache_conda_channel cache_pixi_name cache_pixi_repo
  now=$(date +%s)
  IFS=$'\t' read -r ts cache_conda_name cache_conda_channel cache_pixi_name cache_pixi_repo < "$ABACUS1S_MIRROR_CACHE" || return 1
  [[ "$ts" =~ ^[0-9]+$ ]] || return 1
  (( now - ts < ABACUS1S_MIRROR_CACHE_TTL )) || return 1
  conda_channel="$cache_conda_channel"
  conda_channel_name="$cache_conda_name"
  if [[ -z "${PIXI_REPOURL:-}" ]]; then
    export PIXI_REPOURL="$cache_pixi_repo"
    pixi_repo_name="$cache_pixi_name"
  fi
}

write_mirror_cache() {
  mkdir -p "$ABACUS1S_CACHE_DIR"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date +%s)" "${conda_channel_name:-manual}" "${conda_channel}" \
    "${pixi_repo_name:-manual}" "${PIXI_REPOURL:-}" > "$ABACUS1S_MIRROR_CACHE"
}

# 1. select mirrors
((progress++)) || :

conda_channel_name=""
pixi_repo_name=""
if [[ -n "${ABACUS1S_CONDA_CHANNEL:-}" ]]; then
  conda_channel="$ABACUS1S_CONDA_CHANNEL"
  conda_channel_name="manual"
  logging "Use conda channel from ABACUS1S_CONDA_CHANNEL: ${conda_channel}"
elif [[ "${ABACUS1S_CHANNEL_AUTO:-1}" != "0" ]] && read_mirror_cache; then
  logging "Use cached conda channel: ${conda_channel_name} (${conda_channel})"
  if [[ -n "${pixi_repo_name:-}" ]]; then
    logging "Use cached fastest pixi repo: ${pixi_repo_name} (${PIXI_REPOURL})"
  fi
elif [[ "${ABACUS1S_CHANNEL_AUTO:-1}" != "0" ]]; then
  logging "Benchmark conda channel mirrors"
  if fastest_conda=$(pick_fastest_mirror conda); then
    IFS=$'\t' read -r conda_channel_name conda_channel conda_probe_time <<< "$fastest_conda"
    logging "Use fastest conda channel: ${conda_channel_name} (${conda_channel}, ${conda_probe_time}s)"
  fi
fi

if [[ -z "${conda_channel:-}" ]]; then
  conda_channel="conda-forge"
  conda_channel_name="conda-forge"
  logging "Use fallback conda channel: ${conda_channel_name} (${conda_channel})"
fi

if [[ -n "${ABACUS1S_PIXI_REPOURL:-}" ]]; then
  export PIXI_REPOURL="$ABACUS1S_PIXI_REPOURL"
  pixi_repo_name="manual"
  logging "Use pixi repo from ABACUS1S_PIXI_REPOURL: ${PIXI_REPOURL}"
elif [[ -n "${PIXI_REPOURL:-}" ]]; then
  pixi_repo_name="manual"
elif [[ "${ABACUS1S_CHANNEL_AUTO:-1}" != "0" ]]; then
  logging "Benchmark pixi installer mirrors"
  if fastest_pixi=$(pick_fastest_mirror pixi); then
    IFS=$'\t' read -r pixi_repo_name PIXI_REPOURL pixi_probe_time <<< "$fastest_pixi"
    export PIXI_REPOURL
    logging "Use fastest pixi repo: ${pixi_repo_name} (${PIXI_REPOURL}, ${pixi_probe_time}s)"
  fi
fi

if [[ -z "${PIXI_REPOURL:-}" ]]; then
  export PIXI_REPOURL=https://github.com/prefix-dev/pixi
  pixi_repo_name="github"
  logging "Use fallback pixi repo: ${PIXI_REPOURL}"
fi

if [[ "${ABACUS1S_CHANNEL_AUTO:-1}" != "0" && "${conda_channel_name}" != "manual" && "${pixi_repo_name:-}" != "manual" ]]; then
  write_mirror_cache || true
fi

# 2. install pixi
((progress++))
logging "Install pixi"
if [[ -v ABACUS1S_NO_PATH_UPDATE ]]; then
  export PIXI_NO_PATH_UPDATE=1
fi

curl -fsSL https://pixi.sh/install.sh | sh

# 3. install ABACUS
((progress++))
logging "Install ABACUS"
$ABACUS1S_BIN_PATH/pixi global install \
  --environment abacus1s \
  --expose abacus \
  --expose mpirun \
  abacus==${ABACUS_VERSION:-"*"} \
  openmpi \
  --channel="$conda_channel"

# 4. check the installation
((progress++))
logging "Check the installation"
$ABACUS1S_BIN_PATH/abacus --version
$ABACUS1S_BIN_PATH/mpirun --version

# 5. Remove pixi
((progress++))
logging "Remove pixi to prevent conflict"
rm -f $ABACUS1S_BIN_PATH/pixi

if [[ -v ABACUS1S_NO_PATH_UPDATE ]]; then
  logging "ABACUS have been installed to ${ABACUS1S_BIN_PATH}. To activate the environment, add the following script before your script:"
  logging "export PATH=${ABACUS1S_BIN_PATH}:\$PATH"
else
  logging "ABACUS have been installed to ${ABACUS1S_BIN_PATH}. Restart the shell to use abacus and mpirun."
fi