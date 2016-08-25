#!/bin/bash

SITE_DIR="/tmp/site"
SITE_URL="http://site.dev"
SITE_HOST="127.0.0.1";

OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "f:u:h:" opt; do
    case "$opt" in
    f)  SITE_DIR=$OPTARG
        ;;
    u)  SITE_URL=$OPTARG
        ;;
    h)  SITE_HOST=$OPTARG
        ;;
    esac
done

BREATH="\n\n"
SEP="================================================================================\n"

printf $BREATH
echo "Site from $SITE_DIR will be served on $SITE_URL (resolving domain name to $SITE_HOST address)"
printf $SEP

shift $((OPTIND-1))

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

echo "Script executing from path $SCRIPT_DIR"
printf $BREATH
echo "Updating and installing apache2 packages"
printf $SEP

apt-get update
apt-get install -y --force-yes apache2 libapache2-mod-fastcgi make
apt-get install -y --force-yes php5-dev php-pear php5-mysql php5-cSITE_URL php5-gd php5-json php5-sqlite php5-pgsql
a2enmod headers

printf $BREATH
echo "Enabling php-fpm"
printf $SEP

# credit: https://www.marcus-povey.co.uk/2016/02/16/travisci-with-php-7-on-apache-php-fpm/
if [[ ${TRAVIS_PHP_VERSION:0:3} == "7.0" ]]; then cp $SCRIPT_DIR/assets/www.conf ~/.phpenv/versions/$(phpenv version-name)/etc/php-fpm.d/; fi
cp ~/.phpenv/versions/$(phpenv version-name)/etc/php-fpm.conf.default ~/.phpenv/versions/$(phpenv version-name)/etc/php-fpm.conf
a2enmod rewrite actions fastcgi alias
echo "cgi.fix_pathinfo = 1" >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini
~/.phpenv/versions/$(phpenv version-name)/sbin/php-fpm

printf $BREATH
echo "Configuring Apache virtual hosts"
printf $SEP

cp -f $SCRIPT_DIR/assets/travis-ci-apache /etc/apache2/sites-available/default
sed -e "s?%DIR%?$SITE_DIR?g" --in-place /etc/apache2/sites-available/default
sed -e "s?%URL%?$SITE_URL?g" --in-place /etc/apache2/sites-available/default
echo "$SITE_HOST $SITE_URL" | tee --append /etc/hosts > /dev/null

printf $BREATH
echo "Restarting Apache"
printf $SEP

service apache2 restart