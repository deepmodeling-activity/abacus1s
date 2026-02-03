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

# 1. check the location of the machine
((progress++)) || :

country=$(curl -s https://ipinfo.io/country)
logging "Location: ${country}"
if [ "$country" = "CN" ]
then
  conda_channel="https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/"
  export PIXI_REPOURL=https://ghfast.top/https://github.com/prefix-dev/pixi
else
  conda_channel="conda-forge"
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
  --channel=$conda_channel \

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

