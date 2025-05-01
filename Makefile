##### WSO-Config WSO 2.0 #####

run-debug:
	ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook --ask-pass --ask-become-pass -vvvv -i inventory/hosts.ini site.yml

run:
	ansible-playbook --ask-pass --ask-become-pass -i inventory/hosts.ini site.yml
