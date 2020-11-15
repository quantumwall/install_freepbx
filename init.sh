#!/bin/bash
echo check OS####

os=($(cat /etc/*release | egrep -e 'ID=' -e 'VERSION_ID=' | tr -d '"' | cut -d = -f2))
if [[ ${os[0]} != centos || ${os[1]} != 7 ]]; then
echo "This program only works on the Cenos7 operating system"
echo "Your operation system is ${os[0]} ${os[1]}"
exit 1
fi

##################
echo check if asterisk already installed####

if [ -e '/etc/asterisk' ]; then
	echo 'Asterisk already installed'
    echo 'Want to continue?(this can delete all current settings and the asterisk database) [y/n]'
    read choice
    while [ $choice != y && $choice != n ]; do
        echo "You must enter y o n. Please try again"
        read choice
    done        
    case $choice in
        y)
            echo "Continue"
        ;;
        n)
            echo "Break"
            exit 1
        ;;
    esac 
fi

####################
echo setting repositories to variables####

centOsSources='[centos-base-source]
name=CentOS-$releasever - Base Sources
baseurl=http://vault.centos.org/centos/$releasever/os/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[centos-updates-source]
name=CentOS-$releasever - Updates Sources
baseurl=http://vault.centos.org/centos/$releasever/updates/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[centos-extras-source]
name=CentOS-$releasever - Extras Sources
baseurl=http://vault.centos.org/centos/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centos-centosplus-source]
name=CentOS-$releasever - Plus Sources
baseurl=http://vault.centos.org/centos/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7'

sangomaBase='[sng-base]
name=Sangoma-$releasever - Base
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=os&dist=$dist&staging=$staging
#baseurl=http://package1.sangoma.net/os/$releasever/os/x86_64/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Sangoma-7

[sng-updates]
name=Sangoma-$releasever - Updates
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=updates&dist=$dist&staging=$staging
#baseurl=http://package1.sangoma.net/os/$releasever/updates/x86_64/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Sangoma-7

[sng-extras]
name=Sangoma-$releasever - Extras
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=extras&dist=$dist&staging=$staging
#baseurl=http://package1.sangoma.net/os/$releasever/extras/x86_64/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Sangoma-7

[sng-pkgs]
name=Sangoma-$releasever - Sangoma Open Source Packages
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=sng7&dist=$dist&staging=$staging
#baseurl=http://package1.sangoma.net/sng7/sng7
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Sangoma-7

[sng-epel]
name=Sangoma-$releasever - Sangoma Epel mirror
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=epel&dist=$dist&staging=$staging
#baseurl=http://package1.sangoma.net/sng7/epel
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7'

sangomaCommercial='[sng-commercial]
name=Sangoma-$releasever - Commercial Modules
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=commercial&dist=$dist
#baseurl=http:/package1.sangoma.net/sng7/$releasever/commercial/$basearch/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Sangoma-7
enabled=0'

sangomaCR='[sng-cr]
name=Sangoma-$releasever - cr
baseurl=http://package1.sangoma.net/sng7/$releasever/cr/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=0'

sangomaFasttrack='[fasttrack]
name=Sangoma-7 - fasttrack
mirrorlist=http://mirrorlist.sangoma.net/?release=$releasever&arch=$basearch&repo=fasttrack&dist=$dist
#baseurl=http:/package1.sangoma.net/sng7/$releasever/fasttrack/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7'

sangomaMedia='[sng7-media]
name=Sangoma-$releasever - Media
baseurl=file:///media/Sangoma/
        file:///media/cdrom/
        file:///media/cdrecorder/
gpgcheck=0
enabled=0'

sangomaSources='[src-sng]
name=SRPMs for Sanoma specific packages
baseurl=http://sng7.com/src
gpgcheck=0
enabled=0

[src-sng-os]
name=SRPMs for Sanoma OS
baseurl=http://sng7.com/sng7/src/os
gpgcheck=0
enabled=0

[src-sng-updates]
name=SRPMs for Sanoma Updates
baseurl=http://sng7.com/sng7/src/updates
gpgcheck=0
enabled=0

[src-sng-epel]
name=SRPMs for Epel Packages
baseurl=http://sng7.com/sng7/src/epel
gpgcheck=0
enabled=0'

#####################
echo switchoff selinux####

if [[ $(sestatus | grep 'SELinux status' | tr -d ' ' | cut -d : -f2) == enabled ]]; then
sed -i 's/\(^SELINUX=\).*/\1\disabled/' /etc/selinux/config
setenforce 0
fi

####################
echo resetting the cache####

yum clean packages
yum clean all

#####################
echo backup of CentOS repos####

mkdir /etc/yum.repos.d/backUpRepos
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backUpRepos

#####################
echo make sangoma repositories####

echo "$centOsSources" > /etc/yum.repos.d/CentOS-Sources.repo
echo "$sangomaBase" > /etc/yum.repos.d/Sangoma-Base.repo
echo "$sangomaCommercial" > /etc/yum.repos.d/Sangoma-Commercial.repo
echo "$sangomaCR" > /etc/yum.repos.d/Sangoma-CR.repo
echo "$sangomaFasttrack" > /etc/yum.repos.d/Sangoma-fasttrack.repo
echo "$sangomaMedia" > /etc/yum.repos.d/Sangoma-Media.repo
echo "$sangomaSources" > /etc/yum.repos.d/Sangoma-Sources.repo

######################
echo updating####

yum -y update

######################
echo install asterisk-version-switch####

yum -y install asterisk-version-switch

######################
echo editing the current version in asterisk-version-switch####
 
sed -i 's/\(^current_version=\).*/\1\"16\"/' /usr/local/sbin/asterisk-version-switch

echo launching asterisk-version-switch####
asterisk-version-switch

######################
echo configuring the web server on port 80####

sed -i '/^#Listen/c Listen 80' /etc/httpd/conf/httpd.conf 
systemctl enable httpd
systemctl restart httpd

#######################
echo put asterisk in autorun####
systemctl enable asterisk
systemctl start asterisk
asterisk
exit 0
