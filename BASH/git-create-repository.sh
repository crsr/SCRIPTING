#!/bin/bash

reponame=$1;
timestamp=`date "+%Y-%m-%d %H:%M:%S"`

if [ -z "$reponame" ];
then
echo '=================================================';
echo 'EROARE: Adauga numele repo-ului dupa comanda';
echo '=================================================';
else
echo '=================================================';
echo "Creare folderul $reponame in PROJECTS...";
mkdir /var/www/html/projects/$reponame
echo 'Creat!';
echo '=================================================';
echo 'Initializam GIT...';
cd /var/www/html/projects/$reponame
git init
echo 'Repo GIT initializat!';
echo '=================================================';
echo 'Creare readme.md si commit...';
touch readme.md
echo '======================================================' >> readme.md
echo "* Fisier readme.md pentru proiectul $reponame         " >> readme.md
echo "* Timestamp: $timestamp                         " >> readme.md
echo "* Path: /var/www/html/projects/$reponame              " >> readme.md
echo "======================================================" >> readme.md
git add .
git commit -m "Creare repo si fisier readme.md";
echo 'Commit cu succes!';
echo '=================================================';
echo 'Creare clona publica...';
cd /var/www/html/projects/
git clone --bare ./$reponame $reponame.git
touch $reponame.git/git-daemon-export-ok
chown -R :git /var/www/html/projects/$reponame.git
chgrp -R git /var/www/html/projects/$reponame.git
chmod -R g+w /var/www/html/projects/$reponame.git
echo 'Clona creata';
echo '=================================================';
echo 'Repo creat cu succes!';
echo "Comanda: git clone ssh://username@10.1.1.1/var/www/html/projects/$reponame.git calea_ta";
echo '=================================================';
fi
