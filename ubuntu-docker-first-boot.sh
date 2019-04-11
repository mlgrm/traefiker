#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/first-boot.log 2>&1
set -x
set -e

# set up data disk as DATA_DIR
# export data="/dev/disk/by-id/google-data
# try to mount data partition
mkdir -p /mnt/disks/data
if ! mount /dev/disk/by-id/google-data /mnt/disks/data; then
    # format data disk
    mkfs -t ext4 /dev/disk/by-id/google-data
    # mount /dev/disk/by-id/google-data /mnt/
    # copy persistent data to data disk
    # tar c -C /var/lib . | tar x -C /mnt
    # umount /mnt
    mount /dev/disk/by-id/google-data /mnt/disks/data
fi
echo -e "/dev/disk/by-id/google-data /mnt/disks/data ext4 defaults 0 0" >> /etc/fstab

# put images on the data disk
mkdir -p /mnt/disks/data/docker/
mkdir -p /var/lib/docker/
mount --bind /mnt/disks/data/docker/ /var/lib/docker/
echo -e "/mnt/disks/data/docker/ /var/lib/docker/ none defaults,bind 0 0" >> /etc/fstab

apt-get update && apt-get upgrade -y

# install docker
addgroup --system docker
id -u "$USER" &>/dev/null || useradd -D "$USER"
adduser "$USER" docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
[[ -n $(docker ps -a -q) ]] && docker rm "$(docker ps -a -q)"

# enable docker over tls
sed -ie 's/-H fd:\/\/ //' /lib/systemd/system/docker.service
cat > /etc/docker/daemon.json <<EOF
{
  "tlsverify": true,
  "tlscacert": "/etc/docker/tls/ca.pem",
  "tlscert"  : "/etc/docker/tls/server-cert.pem",
  "tlskey"   : "/etc/docker/tls/server-key.pem",
  "hosts"    : ["fd://", "tcp://0.0.0.0:2376"]
}
EOF
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

