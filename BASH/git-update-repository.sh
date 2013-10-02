#!/bin/bash
reponame=$1;
cd /var/www/html/projects/$reponame
git pull /var/www/html/projects/$reponame.git/
