#!/bin/bash

diamond makedb --in h1.fa -d h1
diamond blastp -d h1 -q h1.fa -o blast_h1_self.txt --more-sensitive -e 0.001
