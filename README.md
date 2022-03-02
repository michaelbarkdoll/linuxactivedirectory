# linuxactivedirectory
A simple repository for managing active directory membership.

## Configure site specific variables:
```
cp ~/group_vars/all.yaml.sample ~/group_vars/all.yaml
vi ~/group_vars/all.yaml
```

```
ansible_user
ansible_password
ad_workstation
```

## Create Active Directory Computer Object
```
ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i staging playbook.yml --tags create-ad
```

<!-- --extra-vars '{"version":"1.23.45","other_variable":"foo"}' -->