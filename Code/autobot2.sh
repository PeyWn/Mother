#!/bin/sh

R="Succesfull" #python ../Assembler/assemble.py $1 
S=$R | grep -c Succesfull
if (($S  >= 1)) 
then
    echo "hejsan"
else
    echo "fail"
fi 
