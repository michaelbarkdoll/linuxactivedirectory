# linuxactivedirectory
A simple repository for managing active directory membership.

## Configure site specific variables:
```
cp ~/group_vars/all.yaml.sample ~/group_vars/all.yaml
vi ~/group_vars/all.yaml
```

```
ansible-vault encrypt group_vars/all.yaml
#New Vault password: 
#Confirm New Vault password: 
#Encryption successful
```

Use the following arguments to unlock encrypted ansible variables:
```
--ask-vault-pass
--vault-password-file=filename
```

```
echo "secret_password" > .vault_pass
```

## Create Active Directory Computer Object
```
ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook --vault-password-file=.vault_pass -i staging playbook.yml --tags create-ad --extra-vars '{"ansible_user":"aduser","ansible_password":"","ansible_host":"192.168.1.10","ad_computer_ou":"ou=Sample,dc=dc,dc=domain,dc=edu","ad_short_hostname":""}'
```

## Check if Computer Object Exists Prior to Joining AD
```
ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook --vault-password-file=.vault_pass -i staging playbook.yml --tags join-ad --extra-vars '{"ansible_user":"aduser","ansible_password":"","ansible_host":"192.168.1.10","ad_computer_ou":"ou=Sample,dc=dc,dc=domain,dc=edu","ad_short_hostname":""}'
```

## Remove Active Directory Computer Object
```
ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook --vault-password-file=.vault_pass -i staging playbook.yml --tags remove-ad --extra-vars '{"ansible_user":"aduser","ansible_password":"","ansible_host":"192.168.1.10","ad_computer_ou":"ou=Sample,dc=dc,dc=domain,dc=edu","ad_short_hostname":""}'
```

<!-- --extra-vars '{"version":"1.23.45","other_variable":"foo"}' -->