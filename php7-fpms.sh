user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="/home/$user/web/$domain/public_html"
WEB_FPM="php-fpm"
template="php7-dynamics"
WEBTPL="/usr/local/vesta/data/templates/web/php-fpm"

if [ -d "/etc/php-fpm.d" ]; then
        pool="/etc/php-fpm.d"
    fi
    if [ -d "/etc/php5/fpm/pool.d" ]; then
        pool="/etc/php5/fpm/pool.d"
    fi
    if [ ! -e "$pool" ]; then
        pool=$(find /etc/php* -type d \( -name "pool.d" -o -name "*fpm.d" \))
        if [ ! -e "$pool" ]; then
            check_result $E_NOTEXIST "php-fpm pool doesn't exist"
        fi
    fi

ubic="$pool/$domain.conf"

# Adding backend config
cat $WEBTPL/$template.tpl |\
    sed -e "s|%user%|$1|g"\
        -e "s|%domain%|$2|"\
        -e "s|%docroot%|$docroot|"\
        -e "s|%backend%|$2|g" > $pool/$2.conf


sed -i -e "s/%backend_lsnr_cust%/127.0.0.1:$backend_port/g" /home/$user/conf/web/$domain.httpd.conf > /dev/null

sed -i -e "s/%backend_lsnr_cust%/127.0.0.1:$backend_port/g" /home/$user/conf/web/$domain.shttpd.conf > /dev/null

service $WEB_FPM restart >/dev/null
