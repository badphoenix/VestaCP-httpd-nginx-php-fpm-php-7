#!/bin/bash

### Install php-fpm

yum-config-manager --enable remi-php70 -y
yum install php-fpm -y
systemctl restart httpd

###
### copy template ###
cp /usr/local/vesta/data/templates/web/httpd/phpcgi.tpl /usr/local/vesta/data/templates/web/httpd/php7-fpms.tpl
cp /usr/local/vesta/data/templates/web/httpd/phpcgi.stpl /usr/local/vesta/data/templates/web/httpd/php7-fpms.stpl

cd /usr/local/vesta/data/templates/web/httpd/

wget https://raw.githubusercontent.com/badphoenix/VestaCP-httpd-nginx-php-fpm-php-7/master/php7-fpms.sh
chmod +x php7-fpms.sh

### change template php7-fpms.tpl and php7-fpms.stpl ### 

sed -i '/php_admin_value/d' php7-fpms.tpl
sed -i 's/Action phpcgi-script \/cgi-bin\/php/DirectoryIndex index.php index.html index.htm/' php7-fpms.tpl
sed -i 's/phpcgi-script/"proxy:fcgi:\/\/%backend_lsnr_cust%"/' php7-fpms.tpl
sed -i 's/<Files \*.php>/<FilesMatch \\.php$>/' php7-fpms.tpl
sed -i 's/<\/Files>/<\/FilesMatch>/' php7-fpms.tpl
sed -i 's/httpd/%web_system%/' php7-fpms.tpl

### php7-fpms.stpl ###

sed -i '/php_admin_value/d' php7-fpms.stpl
sed -i 's/Action phpcgi-script \/cgi-bin\/php/DirectoryIndex index.php index.html index.htm/' php7-fpms.stpl
sed -i 's/phpcgi-script/"proxy:fcgi:\/\/%backend_lsnr_cust%"/' php7-fpms.stpl
sed -i 's/<Files \*.php>/<FilesMatch \\.php$>/' php7-fpms.stpl
sed -i 's/<\/Files>/<\/FilesMatch>/' php7-fpms.stpl
sed -i 's/httpd/%web_system%/' php7-fpms.stpl
 
### php7-dynamics.tpl  ###
cd /usr/local/vesta/data/templates/web/php-fpm/
wget https://raw.githubusercontent.com/badphoenix/VestaCP-httpd-nginx-php-fpm-php-7/master/php7-dynamics.tpl

### nginx ###

cp /usr/local/vesta/data/templates/web/nginx/php-fpm/default.tpl /usr/local/vesta/data/templates/web/nginx/customs.tpl
cp /usr/local/vesta/data/templates/web/nginx/php-fpm/default.stpl /usr/local/vesta/data/templates/web/nginx/customs.stpl
cd /usr/local/vesta/data/templates/web/nginx/
sed -i 's/%web_port%/80/' customs.tpl
sed -i 's/%backend_lsnr%/unix:\/var\/run\/php-fpm\/%domain_idn%.sock/' customs.tpl
sed -i 's/include %home%/#include %home%/' customs.tpl
sed -i 's/%web_ssl_port%/443/' customs.stpl
sed -i 's/%backend_lsnr%/unix:\/var\/run\/php-fpm\/%domain_idn%.sock/' customs.stpl
sed -i 's/include %home%/#include %home%/' customs.stpl

/usr/local/vesta/bin/v-list-web-templates
/usr/local/vesta/bin/v-list-web-templates-proxy 
systemctl restart php-fpm.service

echo WEB_FPM="'php-fpm'" >>  /usr/local/vesta/conf/vesta.conf

cd /usr/local/vesta/bin/

sed -i '/"WEB_BACKEND": "/a "WEB_FPM": "'\''$WEB_FMP'\''",' v-list-sys-config
t=`grep -n "WEB Backend:    $WEB_BACKEND"  v-list-sys-config | awk -F: '{print $1}'`
sed -i ''$t'a\    fi' v-list-sys-config
sed -i ''$t'a\        echo "WEB FPM:    $WEB_FPM"' v-list-sys-config
sed -i ''$t'a\    if [ ! -z "$WEB_FPM" ]; then' v-list-sys-config
sed -i '/echo -ne "$WEB_SSL_PORT\\t$WEB_BACKEND\\t$PROXY_SYSTEM\\t$PROXY_PORT\\t"/a echo -ne "$WEB_SSL_PORT\\t$WEB_FPM\\t$PROXY_SYSTEM\\t$PROXY_PORT\\t"' v-list-sys-config
sed -i '/echo -n "'\''WEB_SSL_PORT'\'','\''WEB_BACKEND'\'','\''PROXY_SYSTEM'\'','\''PROXY_PORT'\'',"/a echo -n "'\''WEB_SSL_PORT'\'','\''WEB_FPM'\'','\''PROXY_SYSTEM'\'','\''PROXY_PORT'\'',"' v-list-sys-config
sed -i '/echo -n "'\''$WEB_SSL_PORT'\'','\''$WEB_BACKEND'\'','\''$PROXY_SYSTEM'\'','\''$PROXY_PORT'\'',"/a      echo -n "'\''$WEB_SSL_PORT'\'','\''$WEB_FPM'\'','\''$PROXY_SYSTEM'\'','\''$PROXY_PORT'\'',"' /usr/local/vesta/bin/v-list-sys-config
#/usr/local/vesta/bin/v-list-sys-services
t=`grep -n "Checking WEB Backend"  v-list-sys-services | awk -F: '{print $1}'`

let "t+=6"
sed -i ''$t'a\    fi' v-list-sys-services
sed -i ''$t'a\    data="$data CPU='\''$cpu'\'' MEM='\''$mem'\'' RTIME='\''$rtime'\''"' v-list-sys-services
sed -i ''$t'a\    data="$data\\nNAME='\''$WEB_FPM'\'' SYSTEM='\''backend server'\'' STATE='\''$state'\''"' v-list-sys-services
sed -i ''$t'a\    get_srv_state $proc_name' v-list-sys-services
sed -i ''$t'a\    proc_name=$(ls /usr/sbin/php*fpm* | rev | cut -d'\''/'\'' -f 1 | rev)' v-list-sys-services
sed -i ''$t'a\    if [ ! -z "$WEB_FPM" ] && [ "$WEB_FOM" != '\''remote'\'' ]; then' v-list-sys-services
sed -i ''$t'a\    # Checking WEB FPM' v-list-sys-services

service vesta restart

sed -i '$d'  v-restart-web

echo 'service $WEB_FPM restart >/dev/null 2>&1' >> v-restart-web

echo 'exit' >> v-restart-web

