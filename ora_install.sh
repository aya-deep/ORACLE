#!/bin/bash

###############################################################################
# Script Name   : install_oracle.sh
# Description   : Installation of Oracle database 19
# Author        : Allali Ayoub
# Created       : 2026-01-28
# Version       : 1.0
# Usage         : sudo ./install_oracle.sh path_oracle_zip
###############################################################################

# Check if the user is root
if [[ $UID -ne 0 ]]; then
	echo "To install oracle on your machine, you need to be root !"
	exit 1
fi

usage() {
    echo "Usage: $0 <fichier.zip>"
    echo ""
    echo "Description:"
    echo "  This script take a ZIP file."
    echo ""
    echo "Arguments:"
    echo "  <fichier.zip>    Path to the ZIP file to be processed"
    echo ""
    echo "Exemple:"
    echo "  $0 archive.zip"
    echo "  $0 /path/to/oracle.zip"
}

# The script must take the zip file
if [[ $# -ne 1 ]]; then
	usage
	exit 1
else
	zip_path="$1"
fi

# Function for the creation of the necessary groups
func_groups () {
groups=(oinstall dba oper backupdba dgdba kmdba asmdba asmoper asmadmin racdba)
gid_value=54321

for group in "${groups[@]}"; do
	groupadd -g "$gid_value" "$group" 2>/dev/null
	if [[ $? -eq 0 ]]; then
		echo "$group group created"
	else
		if getent group "$group" > /dev/null; then
			echo "$group group already exists"
		else
			echo "Failed to create $group"
		fi
	fi
	((gid_value++))
done
}

# Function for the creation of the necessary users
func_users() {
	useradd -u 54321 -m -g oinstall -G dba,oper oracle 2>/dev/null
	if [[ $? -eq 0 ]]; then
		echo "oracle user created"
	else
		if getent passwd oracle > /dev/null; then
			echo "oracle user already exists"
		else
			echo "Failed to create user oracle"
		fi
	fi

	echo "oracle:oracle" | chpasswd
}

# Function to install the necessary packages for oracle database
install_packages () {

	packages=(
	bc
	binutils
	compat-openssl11
	elfutils-libelf
	fontconfig
	glibc
	glibc-devel
	ksh
	libaio
	libasan
	liblsan
	libX11
	libXau
	libXi
	libXrender
	libXtst
	libxcrypt-compat
	libgcc
	libibverbs
	libnsl
	librdmacm
	libstdc++
	libxcb
	libvirt-libs
	make
	policycoreutils
	policycoreutils-python-utils
	smartmontools
	sysstat
	glibc-headers
	ipmiutil
	libnsl2
	libnsl2-devel
	net-tools
	nfs-utils
	gcc 
	unixODBC
	)

	for package in ${packages[@]}; do
		dnf install -y $package > /dev/null
		if [[ $? -eq 0 ]]; then
			echo "Package $package installed"
		fi
	done
}

# Function for the creation of the necessary directory for oracle database
directory_creation() {
	mkdir -p /u01/app
        mkdir -p /u01/app/oraInventory
	mkdir -p /u02/app/oracle/oradata
	mkdir -p /u01/app/oracle/fast_recovery_area
	mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1

	chown -R oracle:oinstall /u01 /u02
	chmod -R 755 /u01 /u02
}

# Function for updating the kernel options for oracle database
kernel_settings() {
    cat <<EOF > /etc/sysctl.d/99-oracle.conf
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF

    sysctl --system
}

# Function for editing the limits of the user oracle on the os for oracle database
limits_setting () {
	cat << EOF > /etc/security/limits.d/oracle-database-preinstall-19c.conf 
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
oracle   hard   memlock    134217728
oracle   soft   memlock    134217728
EOF

}

# Function to export the env var for oracle database
env_var () {
	cat << 'EOF' >> /home/oracle/.bashrc
export ORACLE_BASE=/u01/app/oracle     
export ORACLE_HOME="$ORACLE_BASE"/product/19.0.0/dbhome_1 
export ORACLE_SID=ORCL                 
export PATH="$ORACLE_HOME"/bin:"$PATH"      
export LD_LIBRARY_PATH="$ORACLE_HOME"/lib:"$LD_LIBRARY_PATH"
EOF
}

# Function for editing the SELINUX for oracle database
se_linux () {

	setenforce 0
}

# Function to recup the zip file for the installation of oracle database
install_zip () {
	if [ ! -f $zip_path ]; then
		echo "error: zip file doesn't exist"
		return 1
	fi
	unzip "$zip_path" -d /u01/app/oracle/product/19.0.0/dbhome_1
}

# Main function to execute everything
main() {
    echo "========================================="
    echo "Installation Oracle Database 19c"
    echo "========================================="
    echo ""
    
    echo "=== Creation of the groups ==="
    func_groups
    echo ""
    
    echo "=== Creation of oracle user ==="
    func_users
    echo ""
    
    echo "=== Installation of packages ==="
    install_packages
    echo ""
    
    echo "=== Creation of repertories ==="
    directory_creation
    echo ""
    
    echo "=== Configuration of kernel ==="
    kernel_settings
    echo ""
    
    echo "=== Configuration of the Os limits ==="
    limits_setting
    echo ""
    
    echo "=== Configuration of the environnement variables ==="
    env_var
    echo ""
    
    echo "=== Desactivation of SELinux ==="
    se_linux
    echo ""
    
    echo "=== Unzip the oracle zip in ORACLE_HOME ==="
    install_zip

    echo "========================================="
    echo "✅ The OS preparation is complete !"
    echo "========================================="
    echo "To launch the installation:"
    echo "cd \$ORACLE_HOME && ./runInstaller"
}

main
