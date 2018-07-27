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
