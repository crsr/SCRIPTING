#!/bin/bash

reponame=$1;
while true; do
echo '======================';    
read -p "Stergi $reponame ?! (y/n)" yn
    case $yn in
        [Yy]* ) echo "Stergem repo $reponame..."; echo "Pastram continutul proiectului..."; echo "Proces finalizat!"; rm -rf /var/www/html/projects/$reponame/.git /var/www/html/projects/$reponame.git; exit;;
        [Nn]* ) exit;;
        * ) echo "Raspunde cu y sau n!";;
    esac
done 
