#!/bin/bash

#Collor :v
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
NC='\033[0m'		  # No Collor

#Reads User Input & Vars
read -r -d '' ME << EOM
Made by:
______________________________________
  / ___/(_)________  ____  _______  __
  \__ \/ / ___/ __ \/ __ \/ ___/ / / /
 ___/ / / /  / /_/ / / / / /__/ /_/ /
/____/_/_/   \____/_/ /_/\___/\__, /
                             /____/

EOM
echo -e "${Green}$ME${NC}"
echo -e "${Green}#####################################${NC}"
echo ""
echo -e "${Green}GUIDE:${NC}"
echo -e "${Green}Script ini dibuat untuk menyelesaikan soal UKK dan mempermudah hidup :)"
echo -e "${Green}Kamu bisa menghentikan Script ini dengan ${Yellow}CTRL + C${NC}"
echo -e "${Green}Pastikan menjalankan Script ini menggunakan user ${Red}ROOT${NC} "
echo -e "${Red}JANGAN SALAH MENGINPUTKAN PADA PROMPT DIBAWAH, JIKA SALAH LANGSUNG HENTIKAN PROGRAM${NC}"
echo ""
read -p "Masukan nama domain kamu, contoh (rafi.id): " domain
read -p "Masukan IP kamu, contoh (10.10.10.69): " ip
read -p "Masukan User Database Wordpress kamu, contoh (wp_admin): " admindb
read -p "Masukan Password Database Wordpress kamu, contoh (admin123): " admindbpw
host=$( echo $ip | cut -d '.' -f4 )
pathfw="/etc/bind/$domain"
pathrv="/etc/bind/$domain.reverse"
revnetid=$( echo $ip | awk -F '.' '{print $3"."$2"."$1}')
revzone="$revnetid.in-addr.arpa"
webcfg="/etc/apache2/sites-available/wordpress.conf"
wpcfg="/var/www/wordpress/wp-config.php"

#Update Repository
echo -e "${Purple} Updating Repository...${NC} "
apt-get update

#Install BIND9
echo -e "${Purple} Installing Bind9 and His Friend... ${NC} "
apt-get install -y bind9 resolvconf dnsutils

#Copying zone configuration
cp /etc/bind/db.local /etc/bind/$domain
cp /etc/bind/db.127 /etc/bind/$domain.reverse

#Configuring Forward zone
echo -e "${Blue} Membuat Forward zone...${NC}"
sed -i "s/localhost/$domain/g" /etc/bind/$domain
sed -i "s/127.0.0.1/$ip/g" /etc/bind/$domain
sed -i '$d' /etc/bind/$domain
echo "www	IN	A	$ip" >> /etc/bind/$domain

#Configuring Reverse zone
echo -e "${Blue} Membuat Reverse zone...${NC}"
sed -i "s/localhost/$domain/g" /etc/bind/$domain.reverse
sed -i "s/1.0.0/$host/g" /etc/bind/$domain.reverse
echo "$host	IN	PTR	www.$domain." >> /etc/bind/$domain.reverse

#Zone Declaration
echo -e "${Blue} Mendeklarasi Zones di named.conf.local ${NC}"
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup
echo "" >> /etc/bind/named.conf.local
echo "zone \"$domain\" {" >> /etc/bind/named.conf.local
echo "	type master;" >> /etc/bind/named.conf.local
echo "	file \"$pathfw\";" >> /etc/bind/named.conf.local
echo "};" >> /etc/bind/named.conf.local

echo "" >> /etc/bind/named.conf.local
echo "zone \"$revzone\" {" >> /etc/bind/named.conf.local
echo "	type master;" >> /etc/bind/named.conf.local
echo "	file \"$pathrv\";" >> /etc/bind/named.conf.local
echo "};" >> /etc/bind/named.conf.local

#Setting up Forwarders
echo -e "${Blue} Mengatur Forwarders... ${NC}"
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
sed -i '12i\    	forwarders {' /etc/bind/named.conf.options
sed -i '13i\            	1.1.1.1;' /etc/bind/named.conf.options
sed -i '14i\    	};' /etc/bind/named.conf.options
sed -i "s/auto/no/g" /etc/bind/named.conf.options

#Restarting Bind
echo -e "${Green} restarting Bind service...${NC}"
systemctl restart named

#Setup Resolvconf
echo -e "${Purple} Mengganti Resolvconf...${NC}"
sed -i "s/127.0.0.53/$ip/g" /etc/resolv.conf

#Install LAMPP
echo -e "${Blue} Installing LAMPP ${NC}"
apt-get install -y apache2 libapache2-mod-php mariadb-server php php-{cli,curl,xmlrpc,mysql,fpm,gd,mbstring,soap,imagick}

#Configuring Database
systemctl start mariadb.service
systemctl restart mariadb.service
echo -e "${Purple} Creating Database and Granting Privileges...${NC}"
mysql --user root <<EOFMYSQL

CREATE DATABASE wordpress;
CREATE USER '$admindb'@'localhost' IDENTIFIED BY '$adminpw';
GRANT ALL PRIVILEGES ON wordpress.* to '$admindb'@'localhost' IDENTIFIED BY '$adminpw';
FLUSH PRIVILEGES;
EOFMYSQL

#Configure Apache2
echo -e "${Purple} Downloading Wordpress zzz${NC}"
wget https://wordpress.org/latest.tar.gz
tar -xf latest.tar.gz
mv wordpress /var/www/
cp /etc/apache2/sites-available/000-default.conf $webcfg
sed -i 's/webmaster/root/g' $webcfg
sed -i 's/html/wordpress/g' $webcfg
#14,15,16
sed -i '14i\		<Directory /var/www/wordpress/>' $webcfg 
sed -i '15i\			Options FollowSymLinks' $webcfg
sed -i '16i\			AllowOverride all' $webcfg
sed -i '17i\			Require all granted' $webcfg
sed -i '18i\		</Directory>' $webcfg
sed -i 's/error.log/wp.error.log/g' $webcfg
sed -i 's/access.log/wp.access.log/g' $webcfg

#Configure Wordpress
echo -e "${Purple} Configuring Wordpress...${NC}"
cp /var/www/wordpress/wp-config-sample.php $wpcfg
sed -i 's/database_name_here/wordpress/g' $wpcfg
sed -i "s/username_here/$admindb/g" $wpcfg
sed -i "s/password_here/$adminpw/g" $wpcfg
chown -R www-data:www-data /var/www/wordpress/
chmod -R 777 /var/www/wordpress/

#Enabling Site
echo -e "${Purple} Disable default site...${NC}"
a2dissite 000-default.conf
echo -e "${Purple} Enabling Wordpress site...${NC}"
a2ensite wordpress.conf
echo -e "${Green} Restarting Apache...${NC}"
systemctl restart apache2

echo -e "${Yellow}##############################################################################${NC}"
echo -e "${Yellow}Kamu sudah bisa mengakses Wordpress kamu dengan Link: http://$domain"
echo -e "${Yellow}Tambahan Informasi:"
echo -e "${Yellow}	Nama Database : wordpress"
echo -e "${Yellow} 	Nama Database Admin : $admindb"
echo -e "${Yellow} 	Password Database Admin : $admindbpw"
echo -e "##############################################################################${NC}"
echo ""
echo -e "Testing nslookup Domain: "
nslookup $domain
echo -e "${Red}Jangan lupa mengganti settingan Adapter Windows untuk DNS diarahkan ke IP Ubuntu!${NC}"
rm $0
echo -e "${Blue}Thanks for using my Services${NC}"
echo -e "${Blue}-R${NC}"


