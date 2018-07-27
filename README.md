# VestaCP-httpd-nginx-php-fpm-php-7
 VestaCP httpd+nginx+php-fpm+php 7
 
Інструкція буде перероблятися це ще чорновий варіант. 

В редагувані домена потрібно вибрати шаблон для httpd(php5-fpms) i nginx(customs) і примінити, буде створений шаблон для nginx який перенаправлятиме запроси на php-fpm, і створені налаштування для домену в розділі /etc/php-fpm.d/ . При активації шаблона відбудеться автоматичний рестарт php-fpm. php-fpm працює через сокети, сокети створюють в розділі /var/run/php-fpm/
При видалені домена самостійно потрібно удалити конфіг для видаленого домена в директорії /etc/php-fpm.d/ і ребутнути php-fpm


1. Встановимо php-fmp   yum install php-fpm

2. Створюємо темплейт для httpd для того щоб генерити конфіг php-fpm для кожного нашого сайта

2.1 nano /usr/local/vesta/data/templates/web/httpd/php7-fpms.tpl 
і вносимо в нього наступні дані 
```
  <VirtualHost %ip%:%web_port%>
    ServerName %domain_idn%
    %alias_string%
    ServerAdmin %email%
    DocumentRoot %docroot%
    ScriptAlias /cgi-bin/ %home%/%user%/web/%domain%/cgi-bin/
    Alias /vstats/ %home%/%user%/web/%domain%/stats/
    Alias /error/ %home%/%user%/web/%domain%/document_errors/
    SuexecUserGroup %user% %group%
    CustomLog /var/log/%web_system%/domains/%domain%.bytes bytes
    CustomLog /var/log/%web_system%/domains/%domain%.log combined
    ErrorLog /var/log/%web_system%/domains/%domain%.error.log
    <Directory %docroot%>
        AllowOverride All
        Options +Includes -Indexes +ExecCGI
        DirectoryIndex index.php index.html index.htm
         <FilesMatch \.php$>
        SetHandler "proxy:fcgi://%backend_lsnr_cust%"
        </FilesMatch>   
    </Directory>
    <Directory %home%/%user%/web/%domain%/stats>
        AllowOverride All
    </Directory>
    IncludeOptional %home%/%user%/conf/web/%web_system%.%domain%.conf*
  </VirtualHost>
```

2.2 nano /usr/local/vesta/data/templates/web/httpd/php7-fpms.stpl
і вносимо в нього наступні дані 

<pre>
<VirtualHost %ip%:%web_ssl_port%>

    ServerName %domain_idn%
    %alias_string%
    ServerAdmin %email%
    DocumentRoot %sdocroot%
    ScriptAlias /cgi-bin/ %home%/%user%/web/%domain%/cgi-bin/
    Alias /vstats/ %home%/%user%/web/%domain%/stats/
    Alias /error/ %home%/%user%/web/%domain%/document_errors/
    SuexecUserGroup %user% %group%
    CustomLog /var/log/%web_system%/domains/%domain%.bytes bytes
    CustomLog /var/log/%web_system%/domains/%domain%.log combined
    ErrorLog /var/log/%web_system%/domains/%domain%.error.log
    <Directory %sdocroot%>
        SSLRequireSSL
        AllowOverride All
        Options +Includes -Indexes +ExecCGI
        DirectoryIndex index.php index.html index.htm

        <FilesMatch \.php$>
        SetHandler "proxy:fcgi://%backend_lsnr_cust%"
        </FilesMatch>   

    </Directory>
    <Directory %home%/%user%/web/%domain%/stats>
        AllowOverride All
    </Directory>
    SSLEngine on
    SSLVerifyClient none
    SSLCertificateFile %ssl_crt%
    SSLCertificateKeyFile %ssl_key%
    %ssl_ca_str%SSLCertificateChainFile %ssl_ca%

    IncludeOptional %home%/%user%/conf/web/s%web_system%.%domain%.conf*

</VirtualHost>
</pre>
2.3  nano /usr/local/vesta/data/templates/web/httpd/php7-fpms.sh
і вносимо в нього наступні дані 
<pre>
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

</pre>
2.4 nano /usr/local/vesta/data/templates/web/php-fpm/php7-dynamics.tpl
і вносимо в нього наступні дані 
<pre>
[%backend%]
user = %user%
listen.owner = %user%
listen.group = nginx
listen.mode = 0660
listen = /run/php-fpm/$pool.sock

pm = dynamic
pm.max_children = 2
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 2
pm.max_requests = 500

pm.status_path = /status
request_terminate_timeout = 30s
rlimit_files = 131072


php_admin_value[open_basedir] = %docroot%:/home/%user%/tmp:/bin:/usr/bin:/usr/local/bin:/var/www/html:/tmp:/usr/share:/etc/phpMyAdmin:/etc/phpmyadmin:/var/lib/phpmyadmin:/etc/roundcubemail:/var/lib/roundcube:/var/run/nginx-cache
php_admin_value[upload_tmp_dir] = /home/%user%/tmp
php_admin_value[session.save_path] = /home/%user%/tmp
php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f info@%domain%
php_admin_value[upload_max_filesize] = 32M
php_admin_value[max_execution_time] = 30
php_admin_value[max_input_time] = 60
php_admin_value[post_max_size] = 64M
php_admin_value[memory_limit] = 256M
php_admin_flag[mysql.allow_persistent] = off
php_admin_flag[safe_mode] = off
php_admin_flag[enable_dl] = off
php_admin_value[disable_functions] = passthru,pcntl_exec,popen,openlog,allow_url_fopen




env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp

</pre>

2.5 Далі робимо його виконуваним chmod +x  /usr/local/vesta/data/templates/web/httpd/php7-fpms.sh

3 Створюємо темплейт для nginx який буде слухати 80 i 443 порт і перенаправляти на наш php-fpm

3.1  nano /usr/local/vesta/data/templates/web/nginx/customs.tpl

<pre>
server {
    listen	%ip%:80;
    server_name %domain_idn% %alias_idn%;
    root        %docroot%;
    index	index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    location / {

        location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|css|js)$ {
            expires     max;
        }

	location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    unix:/var/run/php-fpm/%domain_idn%.sock;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }
    }

    error_page  403 /error/404.html;
    error_page  404 /error/404.html;
    error_page  500 502 503 504 /error/50x.html;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~* "/\.(htaccess|htpasswd)$" {
        deny    all;
        return  404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        #include %home%/%user%/conf/web/%domain%.auth;
    }

    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;
    include     /etc/nginx/conf.d/webmail.inc*;

    include     %home%/%user%/conf/web/nginx.%domain_idn%.conf*;
}
</pre>

3.2 nano usr/local/vesta/data/templates/web/nginx/customs.stpl 

<pre>
server {
    listen	%ip%:443;
    server_name %domain_idn% %alias_idn%;
    root        %sdocroot%;
    index	index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    ssl         on;
    ssl_certificate	 %ssl_pem%;
    ssl_certificate_key  %ssl_key%;

    location / {

        location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|css|js)$ {
            expires     max;
        }

	location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    unix:/var/run/php-fpm/%domain_idn%.sock;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }
    }

    error_page  403 /error/404.html;
    error_page  404 /error/404.html;
    error_page  500 502 503 504 /error/50x.html;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~* "/\.(htaccess|htpasswd)$" {
        deny    all;
        return  404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
       #include %home%/%user%/conf/web/%domain%.auth;
    }

    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;
    include     /etc/nginx/conf.d/webmail.inc*;

    include     %home%/%user%/conf/web/snginx.%domain_idn%.conf*;
}

</pre>

4 тепер потрібно виконати команди 

/usr/local/vesta/bin/v-list-web-templates
/usr/local/vesta/bin/v-list-web-templates-proxy 
systemctl restart php-fpm.service
Обновлюємо шаблони вести, тепер вилогінюємо з вебморди і знову логінимося.

5. Вибираємо потрібен домен і в шаблонах Web TemplateHTTPD вибираємо php5-fpms

5.1 В цьому домені вибираємо для Nginx Proxy Template customs. нажимаємо примінити


6 Тепер додамо службу php-fpm в розділ SERVER (https://185.86.77.185:8083/list/server/) !888.png!

6.1  nano /usr/local/vesta/conf/vesta.conf
в кінець додаємо WEB_FPM='php-fpm'
6.2 nano /usr/local/vesta/bin/v-list-sys-config
<pre>
В розділ # JSON list function нижче 
        "WEB_BACKEND": "'$WEB_BACKEND'",
Додаємо
        "WEB_FPM": "'$WEB_FMP'",

В розділі # Shell list нижче 
    if [ ! -z "$WEB_BACKEND" ]; then
        echo "WEB Backend:    $WEB_BACKEND"
    fi
Додаємо 
    if [ ! -z "$WEB_FPM" ]; then
        echo "WEB FPM:    $WEB_FPM"
    fi

В розділі # PLAIN list function нижче 
    echo -ne "$WEB_SSL_PORT\t$WEB_BACKEND\t$PROXY_SYSTEM\t$PROXY_PORT\t"
Додаємо
    echo -ne "$WEB_SSL_PORT\t$WEB_FPM\t$PROXY_SYSTEM\t$PROXY_PORT\t"

В розділі # CSV list низче
    echo -n "'WEB_SSL_PORT','WEB_BACKEND','PROXY_SYSTEM','PROXY_PORT',"
Додаємо
    echo -n "'WEB_SSL_PORT','WEB_FPM','PROXY_SYSTEM','PROXY_PORT',"
Також в цьому розділі низче
    echo -n "'$WEB_SSL_PORT','$WEB_BACKEND','$PROXY_SYSTEM','$PROXY_PORT',"
Додаємо
    echo -n "'$WEB_SSL_PORT','$WEB_FPM','$PROXY_SYSTEM','$PROXY_PORT'," 
</pre>
6.3 nano /usr/local/vesta/bin/v-list-sys-services  
<pre>
Нижче розділу 
# Checking WEB Backend
if [ ! -z "$WEB_BACKEND" ] && [ "$WEB_BACKEND" != 'remote' ]; then
   proc_name=$(ls /usr/sbin/php*fpm* | rev | cut -d'/' -f 1 | rev)
    get_srv_state $proc_name
    data="$data\nNAME='$WEB_BACKEND' SYSTEM='backend server' STATE='$state'"
    data="$data CPU='$cpu' MEM='$mem' RTIME='$rtime'"
fi
Додаємо
# Checking WEB FPM
if [ ! -z "$WEB_FPM" ] && [ "$WEB_FOM" != 'remote' ]; then
   proc_name=$(ls /usr/sbin/php*fpm* | rev | cut -d'/' -f 1 | rev)
    get_srv_state $proc_name
    data="$data\nNAME='$WEB_FPM' SYSTEM='backend server' STATE='$state'"
    data="$data CPU='$cpu' MEM='$mem' RTIME='$rtime'"
fi
</pre>
6.4 service vesta restart

7 Для повної красоти потрібно щоб при видалені домену чи зміні темплейта ребутався автоматично php-fpm

Відкриваємо /usr/local/vesta/bin/v-restart-web і в кінець перед exit дописуємо "service $WEB_FPM restart >/dev/null 2>&1"
