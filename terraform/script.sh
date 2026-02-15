#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

############################################
# System Update & Base Packages
############################################
apt-get update -y
apt-get upgrade -y

apt-get install -y \
  curl \
  git \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  bash-completion \
  apt-transport-https \
  unzip \
  openjdk-21-jdk \
  gitleaks


############################################
# Install AWS CLI v2
############################################

# Download AWS CLI v2
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip

# Unzip
unzip -q /tmp/awscliv2.zip -d /tmp

# Install (idempotent)
if ! command -v aws &>/dev/null; then
  /tmp/aws/install
fi

# Cleanup
rm -rf /tmp/aws /tmp/awscliv2.zip

# Verify
aws --version

############################################
# Install kubectl (Official Kubernetes Repo)
############################################
sleep 5
mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" \
| tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubectl

############################################
# kubectl Completion & Alias (Persistent)
############################################

cat <<'EOF' >/etc/profile.d/kubectl.sh
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
EOF

chmod +x /etc/profile.d/kubectl.sh

############################################
# Install eksctl
############################################
sleep 5
ARCH=amd64
PLATFORM="$(uname -s)_${ARCH}"

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"

curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" \
  | grep "${PLATFORM}" | sha256sum --check -

tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl

rm -f eksctl_${PLATFORM}.tar.gz /tmp/eksctl

############################################
# eksctl Completion & Alias
############################################
cat <<'EOF' >/etc/profile.d/eksctl.sh
source <(eksctl completion bash)
alias e=eksctl
complete -F __start_eksctl e
EOF

chmod +x /etc/profile.d/eksctl.sh

############################################
# Install Helm (Official Repo)
############################################

sleep 5
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
  | gpg --dearmor -o /usr/share/keyrings/helm.gpg

chmod 644 /usr/share/keyrings/helm.gpg

echo "deb [signed-by=/usr/share/keyrings/helm.gpg] \
https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
| tee /etc/apt/sources.list.d/helm-stable-debian.list

sudo apt-get update -y
sudo apt-get install -y helm

############################################
# Helm Completion & Alias
############################################
cat <<'EOF' >/etc/profile.d/helm.sh
source <(helm completion bash)
alias h=helm
complete -F __start_helm h
EOF

chmod +x /etc/profile.d/helm.sh

############################################
# Done
############################################


############################################
# Install Terraform (Official Repo)
############################################
sleep 5
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform packer git 

############################################
# terraform Completion & Alias
############################################
cat <<'EOF' >/etc/profile.d/terraform.sh
source <(terraform completion bash)
alias t=terraform
complete -F __start_terraform t
EOF

chmod +x /etc/profile.d/terraform.sh

############################################
# Done
############################################

############################################
# Install Jenkins (Official Repo)
############################################
sleep 5
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
  
sudo apt update
sudo apt install jenkins -y
sudo systemctl enable --now jenkins
sudo systemctl start jenkins


############################################
# Done
############################################

############################################
# Install Docker (Official Repo)
############################################
sleep 5
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (log out / in or newgrp to apply)
sudo usermod -aG docker  ubuntu
newgrp docker


sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

############################################
# Done
############################################

############################################
# Trivy installation 
############################################
sleep 5
sudo apt-get install wget gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

############################################
# Done
############################################

############################################
# Cosign installation 
############################################
sleep 5
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign


############################################
# Done
############################################


echo "gitleaks, kubectl, eksctl, trivy, cosign, docker, jenkins, terraform, helm, installed successfully"