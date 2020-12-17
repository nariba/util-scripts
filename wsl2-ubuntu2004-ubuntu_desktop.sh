#!/bin/bash
# Copyright (c) 2020 astherier
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php
#
#WSL2+Ubuntu 20.04でGUIアプリが動くように設定し、Ubuntu Desktopをインストールします

function guide_exit(){
    echo "終了しました。"
    echo "環境変数の設定をしていますので、bashの再起動か"
    echo " $ source ~/.profile"
    echo "を実行してください。"
    exit 0
}

# https://astherier.com/blog/2020/07/install-wsl2-on-windows-10-may-2020/
#WSL環境の各パッケージをアップデートします。
sudo apt update -y
sudo apt upgrade -y

# https://astherier.com/blog/2020/08/run-gui-apps-on-wsl2/
#GUIアプリを動かすため、いくつかソフトを入れて設定します。
#Windows側の設定も必要です。詳細はリンクを見てください。
sudo apt install -y libgl1-mesa-dev xorg-dev xbitmaps x11-apps

echo 'export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '\''{print $2}'\''):0.0' >> ~/.zshrc.mine

cat <<EOF
 EOS | sudo tee /etc/fonts/local.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <dir>/mnt/c/Windows/Fonts</dir>
</fontconfig>
EOS
#起動確認：
# $ xeyes

#https://astherier.com/blog/2020/08/install-ubuntu-desktop-on-wsl2/
#Ubuntu Desktopのインストール
sudo apt -y install ubuntu-desktop
sudo service x11-common start
sudo service dbus start
#起動確認：
#WSLの再起動（管理者権限PowerShellでnet stop LxssManager）をし、
#VcXsrvの設定を変更し、
# $ sudo service x11-common start && sudo service dbus start && gnome-shell --x11 -r

guide_exit 
EOF
