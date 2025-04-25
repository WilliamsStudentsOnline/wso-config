# WSO-Config
The new server setup for WSO's infrastructure.

## Onboarding - Automatic
Run the short script:
``` shell
$ ./setup.sh
```
Or, if you're on Windows:
``` shell
$ ./setup.ps1 
``` 
Then follow all the instructions it tells you to do.
## Onboarding - Manual
You will need to install [Ansible](https://www.ansible.com), which you can do with
`$ brew install ansible` on macOS, or `pip install ansible` anywhere. On Linux it's in your package manager. On Windows, get it by installing WSL.

You will also need something to manage VMs. You can get [UTM](https://mac.getutm.app) on macOS or [VirtualBox](https://www.virtualbox.org) on Windows and Linux. Alternatively, use QEMU if you know what you're doing.

Go get a copy of [AlmaLinux 9](https://almalinux.org)'s ISO image, then do a barebones vanilla install into the VM. If you would like to make the VM a little nicer to work with, install the guest utilities provided by your hypervisor. It's not needed though.

Once you have your installation configured, make a copy of your installed VM. You can do this any way you want, but make sure to actually do this, because when a bad Ansible command trashes your VM you'll really wish you had it. Besides: you should test ideally on a vanilla installation anyways. 
## Building
Run the command:
``` shell
$ ansible-playbook playbook.yml
``` 
> TODO: improve this

## Directory Structure
The directory is organized as follows:
``` shell
inventories/ # system-specific stuff
	hosts.ini # the actual server locations
	prod/ # production server
	dev/ # development server
	backup/ # backup server
library/ # any modules we use
site.yml # the main, site-agnostic config
roles/ # any WSO-specific actions we use
```
Looking for something moved from `wso-go`? It's probably in `inventories/prod`.
