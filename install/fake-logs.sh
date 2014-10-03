#! /bin/bash

for i in dependencies admin; do 
  echo -n "("; cat install-${i}.sh | grep "date\ +" | tr "\n" ";"; echo ") > log/install/$i.out 2> log/install/$i.err";
done

echo -n "("; cat install-dependencies2.sh | grep "date\ +" | tr "\n" ";"; echo ") > log/install/dependencies.out 2> log/install/dependencies.err";

for i in moses casmacat; do 
  echo -n "("; cat install-${i}.sh | grep "date\ +" | tr "\n" ";"; echo ") > log/install/$i.out 2> log/install/$i.err";
done

echo -n "("; cat download-test-model.sh | grep "date\ +" | tr "\n" ";"; echo ") > log/install/test-model.out 2> log/install/test-model.err";

for i in casmacat-upvlc thot ; do 
  echo -n "("; cat install-${i}.sh | grep "date\ +" | tr "\n" ";"; echo ") > log/install/$i.out 2> log/install/$i.err";
done
