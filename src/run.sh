#!/bin/bash
file=account.csv
count=0
while read line
do
    for((i=0;i<4;i=i+1))
    do
        account[$count]=`echo $line | cut -d ',' -f 1`
        password[$count]=`echo $line | cut -d ',' -f 2`
        echo "account[$count]=${account[$count]}"
        echo "password[$count]=${password[$count]}  "
        let count++
    done
done < $file

for((i=0;i<28;i=i+1))
do
  #(ruby star.rb ../data/repo$i ${account[$i]} ${password[$i]})
  (nohup ruby star.rb ../data/repo$i ${account[$i]} ${password[$i]}> output$i 2>&1 & )&
done