# cdp-base-jumpstart

The goal of this repo is to automate the install of CDP-DC

### Install Git and pull the repo


* ssh into a new Centos 7 instance and run the below commands

```
sudo -i

#install git
yum install -y git

# change directory
cd ~

# clone the repo:
git clone https://github.com/tlepple/cdp-base-jumpstart.git

# change into directory
cd ~/cdp-base-jumpstart


```


### Edit values in the file --> `input.properties`

```
vi ~/cdp-base-jumpstart/input.properties

```
---
---

### Run the Build

* acceptable parameter are:  `aws`, `azure`, `gcp`, `proxmox`

```
# pass the correct cloud provider to the build script.

# change into directory
cd ~/cdp-base-jumpstart

# Example:
. setup aws

```
