#!/bin/bash

if [[ ! -f lib/abelard/load.rb ]]
then
 echo "Not in correct directory, load missing"
fi

function t() {
 name=$1

 mkdir -p temp/$name
 for feed in samplefeeds/${name}*.xml 
 do
  ruby -I lib lib/abelard/load.rb -f $feed temp/$name
 done

 if ruby -I lib lib/abelard/dump.rb temp/$name | diff -q sampleoutput/${name}.xml -
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
