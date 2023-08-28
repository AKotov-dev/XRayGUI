#!/bin/bash

if [ "$1" == "set" ]; then
echo "set proxy..."
# SET SYSTEM-WIDE PROXY
export all_proxy="socks://127.0.0.1:1080/"
export ftp_proxy="http://127.0.0.1:8889/"
export http_proxy="http://127.0.0.1:8889/"
export https_proxy="http://127.0.0.1:8889/"
export no_proxy="localhost,127.0.0.0/8,::1"

export ALL_PROXY="socks://127.0.0.1:1080/"
export FTP_PROXY="http://127.0.0.1:8889/"
export HTTP_PROXY="http://127.0.0.1:8889/"
export HTTPS_PROXY="http://127.0.0.1:8889/"
export NO_PROXY="localhost,127.0.0.0/8,::1"

# GNOME or gsettings
	gsettings set org.gnome.system.proxy mode "manual"
	gsettings set org.gnome.system.proxy.http host "127.0.0.1"
	gsettings set org.gnome.system.proxy.http port "8889"
	gsettings set org.gnome.system.proxy.https host "127.0.0.1"
	gsettings set org.gnome.system.proxy.https port "8889"
	gsettings set org.gnome.system.proxy.ftp host "127.0.0.1"
	gsettings set org.gnome.system.proxy.ftp port "8889"
	gsettings set org.gnome.system.proxy.socks host "127.0.0.1"
	gsettings set org.gnome.system.proxy.socks port "1080"
# KDE-5
	kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key ProxyType 1
	kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key httpProxy "http://127.0.0.1 8889"
	kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key httpsProxy "http://127.0.0.1 8889"
	kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key ftpProxy "http://127.0.0.1 8889"
	kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key socksProxy "socks://127.0.0.1 1080"
	    else
echo "unset proxy..."
# UNSET SYSTEM-WIDE PROXY
unset all_proxy
unset ftp_proxy
unset http_proxy
unset https_proxy
unset no_proxy

unset ALL_PROXY
unset FTP_PROXY
unset HTTP_PROXY
unset HTTPS_PROXY
unset NO_PROXY

# GNOME or gsettings
	gsettings set org.gnome.system.proxy mode none
# KDE
	kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key ProxyType 0
fi;
