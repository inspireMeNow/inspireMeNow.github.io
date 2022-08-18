bundle exec jekyll build
sudo sed -i 's/4000/80/g' /var/www/html/index.html
sudo su -c "cp -r _site/* /var/www/html"
