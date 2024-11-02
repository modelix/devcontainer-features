#!/bin/sh
set -e
set -x

echo "Activating feature 'mps'"

MPS_VERSION=${MPS_VERSION:-"2024.1.1"}
MPS_MAJOR_VERSION=`echo "$MPS_VERSION" | grep -oE '20[0-9]{2}\.[0-9]+'`
echo "MPS version: $MPS_VERSION"
echo "MPS major version: $MPS_MAJOR_VERSION"

# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final 
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

echo "The effective dev container containerUser is '$_CONTAINER_USER'"
echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"

# install packages
(
  apt-get update -y
  apt-get -y install --no-install-recommends zip unzip wget ca-certificates
  update-ca-certificates
  mkdir /tmp/mps
  cd /tmp/mps
  wget "https://download.jetbrains.com/mps/${MPS_MAJOR_VERSION}/MPS-${MPS_VERSION}.tar.gz"
  tar -xf $(ls | head -n 1)
  mv "MPS $MPS_MAJOR_VERSION" "/mps"
)

# enable debug port
echo "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5071" >> /mps/bin/mps64.vmoptions

# change heap limit
sed -i.bak '/-Xmx/d' /mps/bin/mps64.vmoptions
echo "-XX:MaxRAMPercentage=85" >> /mps/bin/mps64.vmoptions

# An "End User Agreement" dialog prevents the startup if the vendor name is 'JetBrains'
# See
# - https://github.com/JetBrains/intellij-community/blob/777669cc01eb14e6fcf2ed3ba11d2c1d3832d6e2/platform/platform-impl/src/com/intellij/idea/eua.kt#L19-L20
# - https://github.com/JetBrains/MPS/blob/418307944be761dd1e62af65881c8eade086386f/plugins/mps-build/solutions/mpsBuild/source_gen/jetbrains/mps/ide/build/mps.sh#L224
# - https://github.com/JetBrains/MPS/blob/418307944be761dd1e62af65881c8eade086386f/plugins/mps-build/solutions/mpsBuild/source_gen/jetbrains/mps/ide/build/mps.sh#L57
sed -i.bak "s/IDEA_VENDOR_NAME='JetBrains'/IDEA_VENDOR_NAME='Modelix'/g" /mps/bin/mps.sh

# Changing the vendor here is required to remove the "Data Sharing" dialog
./patch-branding.sh

cp log.xml /mps/bin/log.xml
cp run-indexer.sh /
cp install-plugins.sh /
cp update-recent-mps-projects.sh /

mkdir /mps-projects
cp -r default-mps-project /mps-projects/default-mps-project

mkdir -p $_REMOTE_USER_HOME/.config/Modelix/
cp -r mps-config $_REMOTE_USER_HOME/.config/Modelix/MPS$MPS_MAJOR_VERSION

chown -R $_REMOTE_USER:$_REMOTE_USER $_REMOTE_USER_HOME/.config
chown -R $_REMOTE_USER:$_REMOTE_USER /mps

runas -u $_REMOTE_USER /run-indexer.sh
