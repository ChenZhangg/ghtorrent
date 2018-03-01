#!/bin/bash
for((i=0;i<400;i=i+1))
do
  (nohup ruby star.rb ../data/repo$i > output$i 2>&1 & )&
done