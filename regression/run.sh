#!/bin/bash

if [[ ! -f bin/abelard ]]
then
    echo "Not in correct directory, load missing"
    exit 1
fi

function t() {
 name=$1

 mkdir -p temp/$name
 for feed in samplefeeds/${name}*.xml 
 do
  ruby -I lib bin/abelard load -f $feed temp/$name
 done

 if ruby -I lib bin/abelard dump temp/$name | diff -q sampleoutput/${name}.xml -
 then
  echo $name OK
 else
  echo $name Failed
  exit 1
 fi
}

mkdir -p temp

t codinghorror
t bloggerbuzz
t toomuch
