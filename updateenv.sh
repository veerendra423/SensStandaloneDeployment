#!/bin/bash

#This function is used for to replace the value to .env file...
replace_var()
{
        rc=`grep "^$1=" $3`
        if [ -z "$rc" ]; then
                echo $1=$2 >> $3
        else
              sudo sed "\|^$1|s|=.*$|=$2|1" $3 > t
               sudo  mv t $3
        fi
}


#To reading the key of .envcmd file,checking the key is available or not in .env.If its available update the value in .env file.if the key is not available append the key and value to .env file.

while IFS== read -r key val ;
do
    val=${val%\"}; val=${val#\"}; key=${key#export };
    if grep -q "$key" "./.env";
    then
        value=`cat .envcmd | grep -w $key | awk -F '=' '{ print $2}'`
        replace_var $key ${value} .env
    else
        echo "$key=$val" >> .env
    fi
done < .envcmd
