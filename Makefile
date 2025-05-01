##### WSO-Config WSO 2.0 #####

run-debug:
	ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook -i inventory.ini playbook.yaml

run:
	ansible-playbook -i inventory.ini playbook.yaml
