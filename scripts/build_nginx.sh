#!/usr/bin/env bash
# Build NGINX and modules on Dokku.

# fail hard
set -o pipefail

NGINX_VERSION=1.6.2
PCRE_VERSION=8.34

dep_dirname=nginx-${NGINX_VERSION}
dep_archive_name=${dep_dirname}.tar.gz
dep_url=http://nginx.org/download/${dep_archive_name}

cache_folder=$2/nginx-build
mkdir -p $cache_folder
cache_file=${cache_folder}/nginx-${NGINX_VERSION}-${PCRE_VERSION}

if [ -f $cache_file ]; then
	echo "-----> Using cached build of Nginx ${NGINX_VERSION}"
else
	echo "-----> Building Nginx ${NGINX_VERSION}"
	nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
	pcre_tarball_url=http://garr.dl.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2

	temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)
	cd $temp_dir

	curl -L $nginx_tarball_url | tar xz

	pushd nginx-${NGINX_VERSION}
	curl -L $pcre_tarball_url | tar xj

	echo "-----> Configuring nginx"
	./configure \
		--http-client-body-temp-path=/app/tmp/var/run/nginx/client_body_temp \
		--http-proxy-temp-path=/app/tmp/var/run/nginx/proxy_temp \
		--http-fastcgi-temp-path=/app/tmp/var/run/nginx/fastcgi_temp \
		--with-pcre=pcre-${PCRE_VERSION} \
		--with-http_realip_module \
		--with-http_gzip_static_module > /dev/null
	echo "-----> Building nginx"
	make -s -j 9

	# Remove old cached versions
	rm -f $cache_folder/*
	cp objs/nginx $cache_file
	popd
fi

cp $cache_file $1
mkdir -p $1/tmp/var/run/nginx

echo "-----> Done."
