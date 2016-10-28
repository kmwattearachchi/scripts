#!/bin/sh
set -x
sudo -v
chmod -R 700 ./bin 2>./error_log
chmod -R 700 ./temp 2>>./error_log

os=`uname -s`
osName="Unknown"
distribution="Unknown"


Apache2_vhost_http(){
 echo "<VirtualHost domain_ip_address:80>

	ServerAdmin webmaster@localhost

	#ServerName flipmyroom.local

	ServerAlias domain_name

	DocumentRoot project_directory_path

	<Directory />

		Options FollowSymLinks

		AllowOverride None

    		Require all granted

	</Directory>

	<Directory project_directory_path>

		php_admin_flag engine on

		Options Indexes FollowSymLinks MultiViews

		AllowOverride All

		Order allow,deny

		allow from all

		RewriteEngine On

		RewriteOptions Inherit

		Require all granted

	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/

	<Directory \"/usr/lib/cgi-bin\">

		AllowOverride None

		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch

		Order allow,deny

		Allow from all

	</Directory>



	ErrorLog ${APACHE_LOG_DIR}/error.log



	# Possible values include: debug, info, notice, warn, error, crit,

	# alert, emerg.

	LogLevel debug

	CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>" >> /etc/apache2/sites-available/${domain_name}.conf

}

Apache2_vhost_https(){
	echo "<VirtualHost domain_ip_address:443>

			SSLEngine on

			ServerName flipmyroom.local

			DocumentRoot project_directory_path

			SSLCertificateFile ssl_certificate_file_path

			SSLCertificateKeyFile ssl_certificate_key_file_path

		ErrorLog ${APACHE_LOG_DIR}/error.log

		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch



		<Directory project_directory_path>

			php_admin_flag engine on

			Options Indexes FollowSymLinks MultiViews

			AllowOverride All

			Order allow,deny

			allow from all

			RewriteEngine On

			RewriteOptions Inherit

			Require all granted

		</Directory>



		# Possible values include: debug, info, notice, warn, error, crit,

		# alert, emerg.

		LogLevel debug

		CustomLog ${APACHE_LOG_DIR}/access.log combined

	</VirtualHost>
	" >> /etc/apache2/sites-available/${domain_name}.conf
}


Apache2_vhost_debine(){
printf "Enter Vhost domain name ( \033[1mex:- www.example.local\033[0m ) : "
read domain_name
printf "Enter ip address ( \033[1mex:- 127.0.4.10\033[0m ) : "
read domain_ip

printf "Enter the project path ( \033[1mex:- home/sayanthan/test\033[0m ) : "
read apps_path

echo "Default configuration only HTTP. if you want to other configuration please select corresponding number
Enter a chareter for HTTP only => 1 HTTPS => 2 : \c"
read enable_https

printf "\n#write by script\n" >> /etc/hosts
printf "${domain_ip}\t\t${domain_name}\n" >> /etc/hosts

if [ ! -d $apps_path ] ; then
	echo "Your apps path not exist. your path created.."
	mkdir -p $apps_path
	if [ "$?" ! "0" ] ; then
		echo "Your apps path not exist. can not create please retry."
		exit
	fi
fi

if [ -f "/etc/apache2/sites-available/${domain_name}.conf" ]
then
	unlink "/etc/apache2/sites-available/${domain_name}.conf"
fi
touch "/etc/apache2/sites-available/${domain_name}.conf"

#cat lib/debine/apache2_http_vhost.conf >> /etc/apache2/sites-available/${domain_name}.conf
Apache2_vhost_http

if [ "$enable_https" = 2 ]
then
	if [ ! -d /etc/apache2/ssl ]
	then
		mkdir /etc/apache2/ssl
	fi
	printf "\033[1mssl certificate and key genarteing..........\033[0m\n\n"
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/${domain_name}.key -out /etc/apache2/ssl/${domain_name}.crt
	printf "\n"
	chmod -R 600 /etc/apache2/ssl/

	printf "\n\n\n\n" >> /etc/apache2/sites-available/${domain_name}.conf
	#cat lib/debine/apache2_https_vhost.conf >> /etc/apache2/sites-available/${domain_name}.conf
	Apache2_vhost_https

	sed -i -e "s:ssl_certificate_file_path:/etc/apache2/ssl/${domain_name}.crt:g" /etc/apache2/sites-available/${domain_name}.conf
	sed -i -e "s:ssl_certificate_key_file_path:/etc/apache2/ssl/${domain_name}.key:g" /etc/apache2/sites-available/${domain_name}.conf
fi

sed -i -e "s/domain_ip_address/${domain_ip}/g" /etc/apache2/sites-available/${domain_name}.conf
sed -i -e "s/domain_name/${domain_ip}/g" /etc/apache2/sites-available/${domain_name}.conf
sed -i -e "s:project_directory_path:${apps_path}:g" /etc/apache2/sites-available/${domain_name}.conf


a2ensite ${domain_name}.conf
service apache2 reload

}



if [ "$os" = "Linux" ] ; then
	#Linux
	osName="Linux os"
	linux_distribution=`cat /etc/*release | grep '^ID=' | sed 's/ID=//g'`

	if [ "$linux_distribution" = "ubuntu" ] ; then
		distribution="debine"
		printf "\033[1mOS:- ${os} \t\t DISTRIBUTION:- ${distribution}\033[0m\n"
		if [ -z `which apache2` ] ; then
			printf "Apache server not install yet.. if you want to install and continue enter Y\n"
			printf 'Please Enter Y/N '
			read continue_work
			if [ "$continue_work" = "Y" -o "$continue_work" = "y" ] ; then
				#./bin/debine/apache2_uninstall_debine.sh

				echo "Uninstalling....."
				service apache2 stop 2>/dev/null
				apt-get purge -y apache2 apache2-* >/dev/null
				apt-get -y autoremove >/dev/null
				rm -rf /etc/apache2

				echo "Installing....."
				apt-get update -y > /dev/null
				apt-get install -y apache2 > /dev/null

				#./bin/debine/apache2_install_debine.sh
			else
				exit
			fi
		fi

		apachectl configtest 2> ./temp/temp
		if [ -z "`cat ./temp/temp | grep 'Syntax OK'`" ]
		then
			printf  "\033[1myour apache server configration alredy error state. please fixt that and try again.\033[0m\n"
			printf "Can not contunue......\n\n"
			exit
		fi
		Apache2_vhost_debine
		#./bin/debine/apache2_vhost_debine.sh
		
	else
		printf "\033[1mOS:- ${os} \t\t DISTRIBUTION:- ${distribution}\033[0m\n"
		echo "Currently did not implemented for your os or distribution"
		echo "please report or comment  your os and distribution. https://github.com/sayanthanpera/apache_vhost"
		exit
	fi
elif [ "$os" = "SunOS" ] ; then
	osName="Solaris os"
	printf "\033[1mOS:- ${os} \t\t DISTRIBUTION:- ${distribution}\033[0m\n"
	echo "Currently did not implemented for your os or distribution"
	echo "please report or comment  your os and distribution. https://github.com/sayanthanpera/apache_vhost"
	exit
elif [ "$os" = "Darwin" ] ; then
	#Mac os x
	osName="Os x"
	printf "\033[1mOS:- ${os} \t\t DISTRIBUTION:- ${distribution}\n\033[0m"
	echo "Currently did not implemented for your os or distribution"
	echo "please report or comment  your os and distribution. https://github.com/sayanthanpera/apache_vhost"
	exit
else 
	printf "\033[1mOS:- ${os} \t\t DISTRIBUTION:- ${distribution}\n\033[0m"
	echo "Currently did not implemented for your os or distribution"
	echo "please report or comment  your os and distribution. https://github.com/sayanthanpera/apache_vhost"
	exit
fi
