# WSO-Config
The new server setup for WSO's infrastructure.

## Onboarding
Run the short script to download the ISO file and install Ansible & third party modules:
``` shell
$ ./setup.sh
```
Or, if you're on Windows:
``` shell
$ ./setup.ps1 
```
You will need to install [Ansible](https://www.ansible.com), which you can do with
`$ brew install ansible` on macOS, or `pip install ansible` anywhere. On Linux it's in your package manager. On Windows, get it by installing WSL, then running the Linux installation shell script.

You will also need something to manage VMs. You can get [UTM](https://mac.getutm.app) on macOS or [VirtualBox](https://www.virtualbox.org) on Windows and Linux. Alternatively, use [QEMU](https://qemu.org) if you know what you're doing.

Go get a copy of [AlmaLinux 9](https://almalinux.org)'s ISO image, then do a barebones vanilla install into the VM. Install as few packages as possible! It's very difficult for Ansible to safely batch remove unneeded packages, and it will only add what is strictly needed. So rather than installing something, simply add it to this configuration. Make sure that you make **multiple** VMs by cloning that first installation, one for each role (Prod, Dev, Backup). This way, you can accurately simulate a real deployment. 

Once you have your installation done and remove the ISO from your virtual disk drive, make a copy of your installed VM. You can do this any way you want, but make sure to actually do this, because when a bad Ansible command trashes your VM you'll really wish you had it. Besides: you should test ideally on a vanilla installation anyways, restoring to vanilla and running Ansible to ensure it really works. You will need a fast internet connection for the Ansible tests to work (they re-install the DNF package cache a few times, which can be slow). 

Jobs should never fail, but some jobs always result in a change or a skip. If a job fails, file a bug report.

## Building
When running for the first time, run the following command: 
``` shell
$ ansible-galaxy collection install community.general 
```
This will install the required dependencies.

Be sure that you have enabled password login in your VM's SSH config, and that the root account has a password. Change the Makefile to log in as another user if you'd prefer (they must be able to run `sudo` though). Another thing: make sure that when you cloned the VMs, you changed the MAC address on each one; if you did not, do this now. Also take this moment to quickly determine what the IP address is of each machine (you can find this by running `ip a` and noting down the address, called `inet`, for the interface it uses to connect to the internet, which is likely `enp0s1` if you're in a VM), and edit `inventory/hosts.ini` accordingly. Make sure each machine has the same root password, which can be changed with `passwd root`.

Then, run the command:
``` shell
$ make run # runs it as it would in production
``` 
Alternatively, do:
``` shell
$ make run-dev # get better debugging
```

Enter the password you use to login as root for the machines. Then, Ansible will execute all of the tasks as you requested. You can safely re-run this over and over again as you test. Be sure sure that all machines use *the same root password*, otherwise this may not work!

Once Ansible finishes, reboot each machine. You've now got your new machines, set up just like they should be! Make sure to `dnf -y update && dnf -y upgrade` in each to make sure they get the latest packages, as we don't do it for you in case it accidentally breaks something.

## Known Caveats

- For no reason, UFW will randomly fail when changing its settings if it's already running, and crash the Ansible playbook. In the event it happens to you, try turning it off with `ufw disable`. Don't worry, Ansible will fix it for you, this just helps it do so.
- If you have a slow internet connection, none of this will work well. You really want a fast one.
- Some commands may be slow, especially so on the first run. There is no fix for this other than patience. They will eventually be completed; just give them some time.

## Directory Structure
The directory is organized as follows:
``` shell
roles/ # where we keep specific tasks (mostly by-package)
inventory/
	hosts.ini 
group_vars/
	wso_hosts.yml # variables for all hosts
host_vars/ # variables per-host
	wso_prod.yml
	wso_dev.yml
	wso_backup.yml
library/ # any modules we use
site.yml # the main, site-agnostic config
```
Looking for something moved from `wso-go`? It's probably in `roles/`, under the appropriate package.

## Roles Structure
Roles are named to indicate what purpose they serve. You should name your roles correctly, so that changes can be picked up by Ansible and so that future developers understand where every setting is configured.
- Roles lacking a prefix: these are special roles that add key features. They will be moved later into one with a prefix (likely `settings`). 
- `service` roles: These roles add new daemons to the servers and configure them. Please do not use a service for adding packages which are intended to be manually invoked.
- `wso` roles: These roles implement WSO's services and ensure stable deployment of WSO code. Do not use these to add anything else.
- `user` roles: These roles add login data for real human users; non-human users should be made in the `service` role they are used for. 
