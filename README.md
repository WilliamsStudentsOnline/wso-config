# WSO-Config
The new server setup for WSO's infrastructure.

## Onboarding
Run the short script to download the ISO file and install Ansible & third party modules:
``` shell
$ ./setup.sh
```
Or, if you're on Windows:
``` shell
# ./setup.ps1 
```
You will need to install [Ansible](https://www.ansible.com), which you can do with
`$ brew install ansible` on macOS, or `pip install ansible` anywhere. On Linux it's in your package manager. On Windows, get it by installing WSL.

You will also need something to manage VMs. You can get [UTM](https://mac.getutm.app) on macOS or [VirtualBox](https://www.virtualbox.org) on Windows and Linux. Alternatively, use QEMU if you know what you're doing.

Go get a copy of [AlmaLinux 9](https://almalinux.org)'s ISO image, then do a barebones vanilla install into the VM. Install as few packages as possible! It's very difficult for Ansible to safely batch remove unneeded packages, and it will only add what is strictly needed. So rather than installing something, simply add it to this configuration.

Once you have your installation done and remove the ISO from your virtual disk drive, make a copy of your installed VM. You can do this any way you want, but make sure to actually do this, because when a bad Ansible command trashes your VM you'll really wish you had it. Besides: you should test ideally on a vanilla installation anyways, restoring to vanilla and running Ansible to ensure it really works.
## Building
Run the command:
``` shell
$ make run # runs it as it would in production
``` 
Alternatively, do:
``` shell
$ make run-dev # get better debugging
```
At this point, you will be prompted to enter the root password. Be sure that you have enabled password login in your VM's ssh config, and that the root account has a password. Change the Makefile to log in as another user (they must be able to run `sudo` though). Then, Ansible will execute all of the tasks as you requested. You can safely re-run this over and over again as you test.
## Directory Structure
The directory is organized as follows:
``` shell
roles/ # where we keep specific tasks (mostly by-package)
inventory/
	hosts.ini 
group_vars/
	all.yml # variables for all hosts
host_vars/ # variables per-host
	prod.yml
	dev.yml
	backup.yml
library/ # any modules we use
site.yml # the main, site-agnostic config
```
Looking for something moved from `wso-go`? It's probably in `roles/`, under the appropriate package.
