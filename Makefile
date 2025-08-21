##### WSO-Config WSO 2.0 #####

run-debug:
	ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook -vvvv -i inventory/hosts.ini site.yml

run:
	ansible-playbook -i inventory/hosts.ini site.yml
ping:
	ansible -i inventory/hosts.ini wso_prod -m ping
	ansible -i inventory/hosts.ini wso_dev -m ping
