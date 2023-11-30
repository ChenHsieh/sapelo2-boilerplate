# sapelo2-boilerplate

Makes running stuff on sapelo2 (UGA's high perfomance computing system) easier.

## some useful commands

quickly check the usage of the node your job is running on 

```bash
ssh -t {node} htop -u {myID}
```

archive folders for backup or transfer

```bash
tar -czvf mydata-archive.tar.gz mydata
```
