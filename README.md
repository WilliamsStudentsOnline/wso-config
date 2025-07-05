# WSO-Config
The new server setup for WSO's infrastructure.

## Onboarding
You will need something to manage VMs. You can get [UTM](https://mac.getutm.app) on macOS or [VirtualBox](https://www.virtualbox.org) on Windows and Linux. Alternatively, use [QEMU](https://qemu.org) if you know what you're doing.

Run the short script to download the ISO file and install Ansible & third party modules:
``` shell
$ ./setup.sh
```
Or, if you're on Windows and not running this in WSL:
``` shell
$ ./setup.ps1 
```

The scripts can fail in some circumstances. In that case, refer to the instructions below:

* On macOS, run ` brew install ansible`. 
* On Linux it's in your package manager (run `setup.sh` to have it automatically installed). 
* On Windows, get it by installing WSL, then running the Unix installation shell script (the `setup.sh` in this folder), or by running `setup.ps1`, which only works if you have `choco` installed. 
* If none of these work, you can try `pip install ansible` (works on any OS), but use a `venv` otherwise you might break your system Python.

Then, go get a copy of [AlmaLinux 10](https://almalinux.org)'s ISO image if the scripts haven't downloaded it for you (you'll know they did because they'll leave a `.iso` file in this folder). 

Do a barebones vanilla install into the VM (only `Minimal Install` selected in the packages menu). More detailed installation instructions will be added soon.

Once you have your installation done and remove the ISO from your virtual disk drive, make a copy of your installed VM. 

Make sure that you make **multiple** VMs by cloning that first installation, one for each role (Prod, Dev, Backup). This way, you can accurately simulate a real deployment. 

Jobs should never fail, but some jobs always result in a change or a skip. If a job fails, file a bug report.

## Tips For A 10/10 Pull Request
- Make sure you run your code in a testing VM before you push it to the repository. This is super important! It's very hard to undo a bad Ansible script and easy to deploy a good one.
- Also open a pull request on the [wiki](https://github.com/WilliamsStudentsOnline/wiki). Remember, it's important that future WSO members understand how our infrastructure works, so failing to do this is important.
- Write, and try to replace, all unidiomatic Ansible with better versions:
  - Don't write the same command over and over again, use `loop:` or other commands.
  - Don't write bare module names, use `ansible.builtins.` for everything
  - Don't remake the wheel, consider using `ansible-galaxy` modules (but document them!)
  - If you're adding a service, ensure your services follow the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) and the [principle of least astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment). Services shouldn't use complex options, or use insane configurations, or completely disregard default settings. They should be normal `systemd` service files or `cron` jobs that can be easily restarted and stopped by normal users. 
- Comment weird tricks in your code! Just because your code makes sense now doesn't mean it will make any sense to someone in five years from now.
- Write [idempotent](https://en.wikipedia.org/wiki/Idempotence) code. Your code will be run repeatedly on the servers, so it has to gracefully tolerate both first time setup and reruns. Ansible makes this easy, but you have to be careful about stateful code. 

## Building
When running for the first time, run the following command: 
``` shell
$ ansible-galaxy collection install community.general 
```
This will install the required dependencies. The scripts `setup.ps1` and `setup.sh` do this for you, but only if they successfully installed Ansible for you. If they did not, or you installed Ansible without them, you need to run this manually. 

Be sure that you have enabled password login in your VM's SSH config, and that the root account has a password. Change the Makefile to log in as another user if you'd prefer (they must be able to run `sudo` though). Another thing: make sure that when you cloned the VMs, you changed the MAC address on each one; if you did not, do this now. Also take this moment to quickly determine what the IP address is of each machine (you can find this by running `ip a` and noting down the address, called `inet`, for the interface it uses to connect to the internet, which is likely `enp0s1` if you're in a VM), and edit `inventory/hosts.ini` accordingly. Make sure each machine has the same root password, which can be changed with `passwd root`.

You will need a fast internet connection for the Ansible tests to work (the tasks re-install the DNF package cache a few times, which can be slow), so make sure to set up your internet connection accordingly before starting.

Then, run the command:
``` shell
$ make run # runs it as it would in production
``` 
Alternatively, do:
``` shell
$ make run-dev # get better debugging
```

Enter the password you use to login as root for the machines. Then, Ansible will execute all of the tasks as you requested. You can safely re-run this over and over again as you test. Be sure sure that all machines use *the same root password*, otherwise this may not work! You also want root login for SSH, so make sure you have that enabled.

Once Ansible finishes, reboot each machine. You've now got your new machines, set up just like they should be! Make sure to `dnf -y update && dnf -y upgrade` in each to make sure they get the latest packages, as we don't do it for you in case it accidentally breaks something.

## Known Caveats

- If you have a slow internet connection, none of this will work well. You really want a fast one.
- Some commands may be slow, especially so on the first run. There is no fix for this other than patience. They will eventually be completed; just give them some time.
- None of this will work well if you don't read the server documentation. Be sure to go and read that, it's hosted on WSO itself on our private developer wiki.
- On macOS, there is a rare bug where starting more than one VM at the same time can fail (this is due to a limitation in Apple's hardware accelerated virtual machines). To resolve this, simply start one virtual machine at a time, and wait for the boot of one to completely finish before launching the next one.
- On Windows, you may encounter strange bugs if you run this outside of WSL. Please report them, but if you need to get things working in a hurry, it may be best to just use a WSL environment for this.  

## Directory Structure
The directory is organized as follows:
``` shell
roles/ # where we keep specific tasks (mostly by-package)
inventory/
	hosts.ini # defines machine logins and ip addresses
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
