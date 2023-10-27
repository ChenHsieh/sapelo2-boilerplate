# sapelo2 

the sequence databases described [here](https://github.com/Trinotate/Trinotate/wiki/Software-installation-and-data-required#2-sequence-databases-required) can be reused if not outdated. GACRC have the required database here after loading the module:

```
ml Trinotate/4.0.2-foss-2022a

# $TRINOTATE_DATA_DIR
/db/trinotate/20231016

# boilerplate.sqlite mentioned in the wiki
/db/trinotate/20231016/TrinotateBoilerplate.sqlite
```

user might need to copy the database files and the boilerplate file to their own directory for writing access.


# FAQ and troubleshooting

1. when downloading and creating the required databases, the server might be unreachable, just ask the GACRC for help

2. sometimes the program have stopped due to error but the job would not end, users need to check the .err file to see what happened
