#! /bin/bash
#2014 05
#
#============================================================================
#awk:
#http://bbs.chinaunix.net/forum.php?mod=viewthread&tid=2309494&fromuid=26669282
#http://unix.stackexchange.com/questions/155266/pass-two-piped-shell-commands-as-a-parameter-to-a-shell-function
#------------------------------------------------------------------------------
success() {
  printf "[\033[32mSUCCESS\033[0m]\n"
}
#------------------------------------------------------------------------------
failure() {
  printf "[\033[31mFAILURE\033[0m]\n"
}
#------------------------------------------------------------------------------
#eg: echo $PASSWD | sudo -S -k ./setup
#my_cmd command line # | "" tested ok
my_cmd(){
  pts_before=$(now_pts)
  #gnome-terminal -x $*
  #echo "password is: $PASSWD"
  #gnome-terminal -x echo $PASSWD | sudo -S -k  $*
  $*
  sleep 0.1
  pts_after=$(now_pts)
  pts_added=`added_pts "${pts_before[*]}" "${pts_after[*]}"`
  
  #pts_added still exists, cycle
  local length=${#pts_added[@]}

  if [ $length -gt 1 ]; then
    echo "==>请关闭多余虚拟终端！"
    exit 1
  fi
  #if certain pts exists, return 1

  flag=1
  while [ $flag -eq 1 ]
  do
    flag=0
    pts_all=`who | awk '{print $2}'`
    
    for l in $pts_all
    do
      if [ "$pts_added" == "$l" ]; then
        flag=1
        sleep 0.5
        break
      fi
    done
  done

  #$*
  #gnome-terminal -x wget -O ./$XXX_NM $XXX_URL
  #result=$($* 2>&1)
  #if [ $? -ne 0 ]; then
  #  failure
  #  echo $result
  #  exit 1
  #fi
  #success
}
#------------------------------------------------------------------------------
#my_cmdhd 'git archive --format=tar HEAD | tar xf - -C "$tmp"'
#my_cmdhd 'ls | grep test'
my_cmdhd(){
  pts_before=$(now_pts)
  eval $1
  #result=$(eval "$1" 2>&1)
  #result=$(eval "$1")
  sleep 0.1
  pts_after=$(now_pts)
  pts_added=`added_pts "${pts_before[*]}" "${pts_after[*]}"`
  
  #pts_added still exists, cycle
  local length=${#pts_added[@]}

  if [ $length -gt 1 ]; then
    echo "==>请关闭多余虚拟终端！"
    exit 1
  fi
  #if certain pts exists, return 1

  flag=1
  while [ $flag -eq 1 ]
  do
    flag=0
    pts_all=`who | awk '{print $2}'`
    
    for l in $pts_all
    do
      if [ "$pts_added" == "$l" ]; then
        flag=1
        sleep 0.5
        break
      fi
    done
  done
}
#------------------------------------------------------------------------------
#installIt $XXX_OP $XXX_NAME
installIt(){
    if [ $# -eq 2 ]; then
      XXX_INSTALLED_NM=$2
    else
      XXX_INSTALLED_NM=$3
    fi
    #
    if [ "$1" = "1" ]; then
        echo -e "==>正在安装$2...\c"
        echo $PASSWD | sudo -S -k apt-get -y install $2 1>/dev/null
        #
        which XXX_INSTALLED_NM >/dev/null
        XXX_INSTALLED=`echo $?`
        #which $2 >/dev/null
        #XXX_INSTALLED=`echo $?`
        #
        if [ $XXX_INSTALLED = "0" ]; then
          echo "安装成功！"
        else
          echo "安装失败！"
        fi
        #my_cmd apt-get install $2
        #my_cmdhd 'gnome-terminal -x bash -c echo "$PASSWD" "$MY_PIPE" sudo -S -k sleep 5'
        #my_cmdhd 'gnome-terminal -x bash -c  "echo lt | sudo -S sleep 5"'
        #hint: password for lt:
        #my_cmd gnome-terminal -x sudo -k apt-get install $2
    elif [ "$1" = "0" ]; then
        echo "==>不安装$2！"
    else
        echo "==>输入错误！"
    fi
}
#
#
#------------------------------------------------------------------------------
#如果文件夹不存在，创建文件夹
my_mkdir(){
  while [ $# -gt 0 ]
  do
    echo -e "==>创建文件夹$1...\c"
    if [ ! -d "$1" ]; then
      mkdir $1
      if [ "$?" = "0" ];then
        echo "文件夹创建成功！"
      else
        echo "文件夹创建失败！"
      fi
      shift
    else
      echo "文件夹已存在！"
      shift
    fi
  done
}
#
#------------------------------------------------------------------------------
#read_input LINE_NUM XXX_OP XXX_NM
read_input(){
  eval $2=`sed -n "$1p" $INPUT_FILE | awk '{print $1}'`
  eval $3=`sed -n "$1p" $INPUT_FILE | awk '{print $2}'`
}
#-----------------------------------------------------------------------------
#
#read_url XXX_OP LINE_NUM1 LINE_NUM2 LINE_NUM3 ...
#cheak XXX_OP and download file 
read_url(){
  #是否安装
  if [ "$1" = "1" ];then
    while [ $# -gt 1 ]
    do
      cd $WORKDIR/$URLDIR
      XXX_URL=`sed -n "$2p" $URL_FILE | awk '{print $1}'`
      XXX_DIR=`sed -n "$2p" $URL_FILE | awk '{print $3}'`
      XXX_NM=`sed  -n "$2p" $URL_FILE | awk '{print $5}'`
      shift
      cd $WORKDIR/$XXX_DIR
      #安装文件或配置文件是否存在
      if [ ! -f "$XXX_NM" ]; then
        echo -e "==>正在下载$XXX_NM到$WORKDIR/$XXX_DIR...\c"
        my_cmd gnome-terminal -x wget -O ./$XXX_NM $XXX_URL
        #my_cmdhd gnome-terminal -x wget -O ./$XXX_NM $XXX_URL
        #echo "pts_added is: $pts_added"
        #wget -O ./$XXX_NM $XXX_URL 1>/dev/$pts_added
        if [ "$?" = "0" ];then
          echo "下载成功！"
        else
          echo "下载失败！"
        fi
      else
        echo "==>$XXX_NM已存在！"
      fi
    done
  fi
}
#
#------------------------------------------------------------------------------
now_pts(){
  echo `who | awk '{print $2}'`
}
#
#------------------------------------------------------------------------------
#check if there are any pts added
#added_pts "${before[*]}" "${after[*]}" "${return[*]}"
added_pts(){
  # after[] is longer than before[]
  #echo "var 1 is: $1"
  #echo "var 2 is: $2"
  local before=($1)
  local after=($2)
  declare -a return_pts
  t=0
  flag=0
  for m in "${after[@]}"
  do
    for l in "${before[@]}"
      do
        if [ "$m" == "$l" ]; then
          flag=1
          break
        fi
      done
    if [ $flag -eq 0 ]; then
      return_pts[t]=$m
      t=$((t+1))
    else
      flag=0
    fi
  done
  #echo return_pts=${return_pts[*]}
  echo ${return_pts[*]}
  #eval $3="${return_pts[*]}"
}
#-------------------------------------------------------------------------------
#模拟鼠标点击
#http://blog.chinaunix.net/uid-9688646-id-1998438.html
#-------------------------------------------------------------------------------
#
#所有HTTP响应的第一行都是状态行，依次是当前HTTP版本号，3位数字组成的状态代码，以及描述状态的短语，彼此由空格分隔。
#状态代码的第一个数字代表当前响应的类型：
#    1xx消息——请求已被服务器接收，继续处理
#    2xx成功——请求已成功被服务器接收、理解、并接受
#    3xx重定向——需要后续操作才能完成这一请求
#    4xx请求错误——请求含有词法错误或者无法被执行
#    5xx服务器错误——服务器在处理某个正确请求时发生错误
#虽然RFC 2616中已经推荐了描述状态的短语，例如"200 OK"，"404 Not Found"，但是WEB开发者仍然能够自行决定采用何种短语，用以显示本地化的状态描述或者自定义信息。
#
#检测网络链接&&ftp上传数据  
test_network(){  
  #超时时间
  timeout=5
  #目标网站
  target=www.baidu.com
  #获取响应状态码
  ret_code=`curl -I -s --connect-timeout $timeout $target -w %{http_code} | tail -n1`
  if [ "x$ret_code" = "x200" ]; then
    #HTTP/1.1 200 OK
    echo "==>网络畅通！"
  else  
    echo "==>网络不畅通！"
    exit 1
  fi
}
#==============================================================================
CONFDIR=config
DEBDIR=deb
LIBDIR=lib
ISODIR=iso
BACKUPDIR=backup
STATEDIR=statement
WINFONTSDIR=winfonts
URLDIR=url
WORKDIR=`pwd`
INPUT_FILE=input
URL_FILE=url
LOG_FILE=log
STATEMENT_FILE=statement
I386_OR_AMD64="64"
TECPLOT_VERSION="2011"
MENTOHUST_DEB=mentohust_0.3.4-1_amd64.deb
LOGNAME=`whoami | awk '{print $1}'`
MY_PIPE="|"
MY_ECHO="echo"
MY_SUDO="sudo"
SLEEPTIME=5
NULL=""
OWNCLOUD_IP="10.129.16.19"
URL_URL='http://10.129.16.72/owncloud/index.php/s/j8af9dBGlBKY7N9/download'
#
if [ "$LOGNAME" = "root" ]; then
    echo "不能用root权限运行本脚本/不要使用sudo！"
    exit 1
fi
#
#
if [ ! -f "$INPUT_FILE" ]; then
  echo "==>文件input不存在！"
  exit 1
fi

#input
#input
read_input 1  SOURCE_OP    SOURCE_NM
read_input 2  BASH_OP      BASH_NM
read_input 3  CMATRIX_OP   CMATRIX_NM
read_input 4  IPTUX_OP     IPTUX_NM
read_input 5  GFORTRAN_OP  GFORTRAN_NM
read_input 6  GPP_OP       GPP_NM
read_input 7  VIM_OP       VIM_NM
read_input 8  MENTOHUST_OP MENTOHUST_NM
read_input 9  TECPLOT_OP   TECPLOT_NM
read_input 10 TEXLIVE_OP   TEXLIVE_NM
read_input 11 GIT_OP       GIT_NM
read_input 12 SSH_OP       SSH_NM
read_input 13 GDB_OP       GDB_NM
read_input 14 LAPACK_OP    LAPACK_NM
read_input 15 MPI_OP       MPI_NM
read_input 16 NAUT_OP      NAUT_NM
read_input 17 JAVA_OP      JAVA_NM
read_input 18 PETSC_OP     PETSC_NM
read_input 19 CHROME_OP    CHROME_NM
read_input 20 KATE_OP      KATE_NM
read_input 21 PETSC_OP     PETSC_NM
#
read -p "==>请输入系统密码：" -s PASSWD
#解决不回显之后下一行不换行的问题
echo $NULL
if [ ! "$MENTOHUST_OP" = "0" ]; then
  read -p "==>请输入锐捷帐号：" MENTOHUST_ACCOUNT
  read -p "==>请输入锐捷密码：" -s MENTOHUST_PASSWD
  echo $NULL
fi
#
echo "==>检测当前权限..."
echo $PASSWD |sudo -S -k whoami
success=`echo $?`
if [ "$success" = "0" ];then
    echo "==>密码输入正确"
else
    echo "==>密码输入错误"
    exit 1
fi
#
#检测系统信息
#echo "系统信息检测"
#echo "----------------------------------"
#dash -> bash
SHINFO=`ls -al /bin/sh | egrep -i "bash"`
if [ -z "$SHINFO" ]; then
  echo $PASSWD | sudo -S -k ln -fs /bin/bash /bin/sh
fi
echo "系统信息："`cat /proc/version`
SYSINFO=`cat /proc/version |egrep -i "ubuntu"`
if [ -z "$SYSINFO" ]; then
    echo "你的系统不是ubuntu，某些步骤可能不能正常工作："
    OPTIONS="继续 退出"
    select OPT in $OPTIONS;do
        if [ "$OPT" = "继续" ]; then
            break
        elif [ "$OPT" = "退出" ]; then
            exit 0
        else
            echo "错误选择！"
        fi
    done
fi
#
echo " "
echo " "
echo " "
echo " "
echo "********************************************************"
echo "            按一次回车键开始阅读免责声明                  "
echo "                                                        "
echo "            开始后，按空格键翻页                         "
echo "********************************************************"
echo " "
echo " "
read dummyarg
more "${WORKDIR}/${STATEDIR}/$STATEMENT_FILE"
echo " "
echo " "
echo " "
echo -n "同意，请输入\"y\":"
read STATEREPLY
#
if test "$STATEREPLY" != "y" -a "$STATEREPLY" != "Y" ; then
  echo " "
  echo "警告：前方高能，你必须同意以上声明！"
  echo " "
  exit
fi
#
#
if [ $BASH_OP = "1" ]; then
  echo "==>/etc/bash.bashrc..."
  BASHDIR=/etc/bash.bashrc
elif [ $BASH_OP = "0" ]; then
  echo "==>~/.bashrc..."
  BASHDIR=~/.bashrc
else
  echo "==>输入错误！"
fi
wait
#
my_mkdir $WORKDIR/$CONFDIR $WORKDIR/$DEBDIR $WORKDIR/$LIBDIR $WORKDIR/$ISODIR $WORKDIR/$BACKUPDIR $WORKDIR/$STATEDIR $WORKDIR/$WINFONTSDIR $WORKDIR/$URLDIR
#url
#
#open a new pts
#pts_before=$(now_pts)
#gnome-terminal
#sleep 0.1
#pts_after=$(now_pts)
#pts_added=`added_pts "${pts_before[*]}" "${pts_after[*]}"`
#echo $pts_added =>pts/N
#echo "该终端显示详细安装信息，请勿关闭！" >/dev/$pts_added
#
#
ping  -c 1 $OWNCLOUD_IP | grep -q "ttl=" && echo "==>$OWNCLOUD_IP is on!" || echo "==>$OWNCLOUD_IP is off!"
cd $WORKDIR/$URLDIR
if [ ! -f "$URL_FILE" ]; then
  echo -e "==>正在下载$URL_FILE到$WORKDIR/$URL_DIR...\c"
  my_cmd wget -q -O $WORKDIR/$URLDIR/$URL_FILE $URL_URL
  if [ "$?" = "0" ];then
    echo "下载成功！"
  else
    echo "下载失败！"
  fi
else
  echo "==>$URL_FILE已存在！"
fi
#
read_url 1 13
read_url $MENTOHUST_OP 2
read_url $MENTOHUST_OP 6
read_url $VIM_OP       3
read_url $SOURCE_OP    4
read_url $LAPACK_OP    5 12
read_url $MPI_OP       7
read_url $TECPLOT_OP   8
read_url $TEXLIVE_OP   9 10 11 14
#                                  
#read_url $IPTUX_OP     4
#read_url $GFORTRAN_OP  5
#
#
#------------------------------------------------------------------------expect
#echo $PASSWD | sudo -S -k apt-get install -y expect
#wait
#echo $PASSWD | sudo ln -fs /bin/bash /bin/sh
#
#$?符号显示上一条命令的返回值，如果为0则代表执行成功，其他表示失败。
#sudo -k 将会强迫使用者在下一次执行 sudo 时问密码（不论有没有超过 N 分钟） 
#
#---------------------------------------------------------------------mentohust
#mentohust
#mentohust.sh
if [ $MENTOHUST_OP = "1" ]; then
  echo "==>安装$MENTOHUST_NM..."
  cd ${WORKDIR}/$DEBDIR/
  echo $PASSWD | sudo  -S -k dpkg -i $MENTOHUST_DEB
  wait
  cd ../
  #edit /etc/mentohust.conf
  echo $PASSWD | sudo -S -k cp ./$CONFDIR/mentohust.conf /etc/
  cd /etc/
  echo $PASSWD | sudo -S -k sed -i "s/Username=/Username=$MENTOHUST_ACCOUNT/g" mentohust.conf
  echo $PASSWD | sudo -S -k sed -i "s/Password=/Password=$MENTOHUST_PASSWD/g" mentohust.conf
  echo $PASSWD | sudo -S -k sed -i "s/StartMode=/StartMode=1/g" mentohust.conf
  echo $PASSWD | sudo -S -k sed -i "s/DhcpMode=/DhcpMode=1/g" mentohust.conf
  echo $PASSWD | sudo -S -k sed -i "s/DaemonMode=/DaemonMode=2/g" mentohust.conf
  sleep 1
  #
  echo $PASSWD | sudo -S -k sed -i '$i\sleep 5\necho password | sudo mentohust' rc.local
  echo $PASSWD | sudo -S -k sed -i "s/password/$PASSWD/g" rc.local
  #edit input
  cd $WORKDIR
  awk 'NR==8{$1=0}{print}' input>input_new
  mv input input_backup
  mv input_new input
  #
  if [ $SOURCE_OP -eq 1 ]; then
    echo "更换电子科大的源必须重启以继续！同意，请输入\"y\":"
    read MENTREPLY
    #
    if test "$MENTREPLY" != "y" -a "$MENTREPLY" != "Y" ; then
      echo " "
      echo "警告：前方高能，你必须重启！"
      echo " "
      exit 1
    fi
    #reboot
    echo $PASSWD | sudo -S -k reboot
  fi
elif [ $MENTOHUST_OP = "0" ]; then
  echo "==>不安装$MENTOHUST_NM..."
else
  echo "==>输入错误！"
fi
wait
#
#-----------------------------------------------------------------------sources
#update sources list
if [ ! $SOURCE_OP = "0" ]; then
  cd $WORKDIR
  echo $PASSWD | sudo -S -k mv /etc/apt/sources.list $WORKDIR/$BACKUPDIR/
  if [ $SOURCE_OP = "1" ]; then
    echo "==>切换电子科大源并updates..."
    #检测网络连接
    test_network
    echo $PASSWD | sudo -S -k cp $WORKDIR/$CONFDIR/sources_uestc.list /etc/apt/
    echo $PASSWD | sudo -S -k mv /etc/apt/sources_uestc.list /etc/apt/sources.list
  elif [ $SOURCE_OP = "2" ]; then
    echo "==>切换中科大源并updates..."
    echo $PASSWD | sudo -S -k cp $WORKDIR/$CONFDIR/sources_uestc.list /etc/apt/
    echo $PASSWD | sudo -S -k mv /etc/apt/sources_uestc.list /etc/apt/sources.list
  else
    echo "==>输入错误！"
  fi
  echo $PASSWD | sudo -S -k apt-get update
else
  echo "==>不切换源..."
fi
wait
#
#------------------------------------------------------------------------------
#cmatrix, iptux, gfortran, g++, git, ssh, nautilus-open-terminal, chrome, kate
SSH_INSTALLED_NM="ssh"
NAUT_INSTALLED_NM="nautilus"
installIt $CMATRIX_OP $CMATRIX_NM
installIt $IPTUX_OP $IPTUX_NM
installIt $GFORTRAN_OP $GFORTRAN_NM
installIt $GPP_OP $GPP_NM
installIt $GIT_OP $GIT_NM
installIt $SSH_OP $SSH_NM $SSH_INSTALLED_NM
installIt $NAUT_OP $NAUT_NM $NAUT_INSTALLED_NM
installIt $CHROME_OP $CHROME_NM $CHROME_INSTALLED_NM
installIt $KATE_OP $KATE_NM
#if [ $? -eq 0 ];then
#  echo "Install success!"
#else
#  echo "Install fail!"
#fi
#echo "test done!"
#
#---------------------------------------------------------------------------vim
if [ $VIM_OP = "1" ]; then
  echo "==>安装$VIM_NM..."
  sudo -K
  echo $PASSWD| sudo -S apt-get -y install $VIM_NM
  wait
  cp ./$(CONFDIR)/my_vimrc ~/
  mv -f ~/my_vimrc ~/.vimrc
elif [ $VIM_OP = "0" ]; then
  echo "==>不安装$VIM_NM..."
else
  echo "==>输入错误！"
fi
wait
#
#------------------------------------------------------------------------tec360
#
if [ $TECPLOT_OP = "1" ]; then
  echo "==>安装$TECPLOT_NM..."
  #
  echo $PASSWD | sudo -S -k apt-get -y install libstdc++5
  wait
  cd ${WORKDIR}/$DEBDIR/
  tar -xf tec360_LINUX${I386_OR_AMD64}.tar.gz
  wait
  cd tec360/tec360_${TECPLOT_VERSION}_linux64/
  echo $PASSWD | sudo -S -k chmod +x setup
  cd 360/
  echo $PASSWD | sudo -S -k chmod +x setuptec
  #替换licaggr内容，防止过多输出
  #cat /dev/null > 要清空的文件
  #echo "" > 要清空的文件
  echo $PASSWD | sudo -S -k echo "XXXXXXXXXXXXXXXXXXXX--Liu--XXXXXXXXXXXXXXXXXXXX" > licaggr
  sleep 1
  #
  cd ../
  echo $PASSWD | sudo -S -k sed -i "s/InstallOption=0/InstallOption=1/g" setup
  cd 360/
  #
  echo $PASSWD | sudo -S -k sed -i "s/read dummyarg/#read dummyarg/g" setuptec
  echo $PASSWD | sudo -S -k sed -i "s/more/cat/g" setuptec
  echo $PASSWD | sudo -S -k sed -i "s/licreply=\`OptionRead\`/licreply=\"accept\"/g" setuptec
  echo $PASSWD | sudo -S -k sed -i "s/ExeOption=\`OptionRead\`/ExeOption=4/g" setuptec
  echo $PASSWD | sudo -S -k sed -i "s/InstallationDir=\`OptionRead\`/InstallationDir=\"\/opt\/tec360\"/g" setuptec
  echo $PASSWD | sudo -S -k sed -i "s/GoCreate=\`OptionRead Y\`/GoCreate=\"Y\"/g" setuptec
  echo $PASSWD | sudo -S -k sed -i "s/EnterLicenseNow=\`OptionRead y\`/EnterLicenseNow=\"N\"/g" setuptec
  #
  cd ../
  echo $PASSWD | sudo -S -k ./setup
  #
  #	tecplot install directory : /opt/tec360
  #	when a licence is needed, enter N
  cd ${WORKDIR}/$DEBDIR/tec360/
  echo $PASSWD | sudo -S -k cp tecplotlm.lic /opt/tec360
  cd lib
  echo $PASSWD | sudo -S -k cp libtec.so /opt/tec360/lib
  cd mesa
  echo $PASSWD | sudo -S -k cp libtec.so /opt/tec360/lib/mesa
  #	In your .bashrc file, add :
  #	export TEC_360_2011=/opt/tec360
  #	export PATH=$TEC_360_2011/bin:$PATH 
  #	export XLIB_SKIP_ARGB_VISUALS=1
  #cd ~/
  echo $PASSWD | sudo -S -k sed -i '$a\export TEC_360_2011=/opt/tec360\nexport PATH=$TEC_360_tecplot_version_tmp/bin:$PATH\nexport XLIB_SKIP_ARGB_VISUALS=1' ${BASHDIR}
  echo $PASSWD | sudo -S -k sed -i "s/tecplot_version_tmp/$TECPLOT_VERSION/g" ${BASHDIR}
  wait
  cd ${WORKDIR}/$DEBDIR/
  rm -rf tec360
  source ${BASHDIR}
  wait
  #
elif [ $TECPLOT_OP = "0" ]; then
  echo "==>不安装$TECPLOT_NM..."
else
  echo "==>输入错误！"
fi
wait
#
#-----------------------------------------------------------------------texlive
#http://blog.csdn.net/bendanban/article/details/23284415
#
if [ $TEXLIVE_OP = "1" ]; then
  echo "==>安装$TEXLIVE_NM..."
  echo "   ==>安装expect以实现自动输入..."
  installIt 1 expect
  #echo $PASSWD | sudo -S -k apt-get install -y expect 1>/dev/null
  wait
  #echo $PASSWD| sudo -S apt-get -y install $TEXLIVE_NM
  #wait
  cd ${WORKDIR}/$ISODIR/
  cat texlive.tar.gz.a* | tar -zxv
  rm texlive.tar.gz.a*
  echo $PASSWD | sudo -S -k mkdir /media/texlive
  echo $PASSWD | sudo -S -k mount ${WORKDIR}/$ISODIR/texlive2013-20130530.iso  /media/texlive
  cd /media/texlive
  #expect
/usr/bin/expect <<-EOF
  set timeout -1
  spawn sudo ./install-tl
  expect {
                "password for $LOGNAME" {send "lt\r"; exp_continue}
                "Enter command:" {send "I\r";}
         }
  expect eof
EOF
  #interact
  wait
  #
  echo $PASSWD | sudo -S -k sed -i '$a\export PATH=/usr/local/texlive/2013/bin/x86_64-linux:$PATH' /etc/profile
  echo $PASSWD | sudo -S -k sed -i '$a\export MANPATH=/usr/local/texlive/2013/texmf-dist/doc/man:$MANPATH' ${BASHDIR}
  echo $PASSWD | sudo -S -k sed -i '$a\export INFOPATH=/usr/local/texlive/2013/texmf-dist/doc/info:$INFOPATH' ${BASHDIR}
  source /etc/profile
  wait
  source ${BASHDIR}
  wait
  #
  cd /etc/fonts/conf.d  
  echo $PASSWD | sudo -S -k ln -s /usr/local/texlive/2013/texmf-dist/tex/latex/ctex/fontset/ctex-xecjk-winfonts.def 09-texlive.conf
  #
  cd /usr/share/fonts  
  echo $PASSWD | sudo -S -k mkdir WinFonts
  echo $PASSWD | sudo -S -k cp ${WORKDIR}/${WINFONTSDIR}/*.ttf ./WinFonts
  #
  cd ./WinFonts
  echo $PASSWD | sudo -S -k chmod 644 *.ttf
  #创建字体的fonts.scale文件，它用来控制字体旋转缩放
  echo $PASSWD | sudo -S -k mkfontscale
  wait
  #创建字体的fonts.dir文件，它用来控制字体粗斜体产生
  echo $PASSWD | sudo -S -k mkfontdir
  wait
  #建立字体缓存信息，也就是让系统认识认识这些字体
  echo $PASSWD | sudo -S -k fc-cache -fsv
  wait
  #
  cd  /usr/local/texlive/2013/texmf-dist/tex/latex/ctex/fontset/
  echo $PASSWD | sudo -S -k sed -i "s/[SIMFANF.TTF]/FangSong/g" ctex-xecjk-winfonts.def
  echo $PASSWD | sudo -S -k sed -i "s/[SIMKAI.TTF]/KaiTi/g" ctex-xecjk-winfonts.def
elif [ $TEXLIVE_OP = "0" ]; then
  echo "==>不安装$TEXLIVE_NM..."
else
  echo "==>输入错误！"
fi
wait
#
#
#---------------------------------------------------------------------------mpi
#
#
which gfortran >/dev/null
GFORTRAN_INSTALLED=`echo $?`
which g++ >/dev/null
GPP_INSTALLED=`echo $?`
#
if [ $GFORTRAN_INSTALLED = "0" -a $GPP_INSTALLED = "0" ]; then
  PRE_INSTALLED="1"
else
  PRE_INSTALLED="0"
fi
#
if [ $MPI_OP = "1" -a $PRE_INSTALLED = "1" ]; then
  echo "==>安装$MPI_NM..."
  cd ${WORKDIR}/$DEBDIR/
  tar xzf mpich-3.1.3.tar.gz
  cd mpich-3.1.3
  #./configure --prefix=/usr/local/mpich-install 2>&1 | tee c.txt
  ./configure --prefix=/usr/local/mpich-install
  #echo $PASSWD | sudo -S -k make 2>&1 | tee m.txt
  echo $PASSWD | sudo -S -k make
  #	This step should succeed if there were no problems with the preceding step. Check file m.txt. 
  #	If there were problems, do a "make clean" and then run make again with V=1.
  #	make V=1 2>&1 | tee m.txt
  #echo $PASSWD | sudo -S -k make install 2>&1 | tee mi.txt
  echo $PASSWD | sudo -S -k make install
  echo $PASSWD | sudo -S -k sed -i '$a\export PATH=/usr/local/mpich-install/bin:$PATH' ${BASHDIR}
  wait
  cd ${WORKDIR}/$DEBDIR/
  rm -rf mpich-3.1.3
  source ${BASHDIR}
  wait
elif [ $MPI_OP = "0" ]; then
  echo "==>不安装$MPI_NM..."
elif [ $PRE_INSTALLED = "0" ]; then
  echo "==>安装$MPI_NM..."
  if [ $GFORTRAN_INSTALLED = "1" ];then
    echo "   ==>需要的$GFORTRAN_NM未安装！"
  fi
  if [ $GPP_INSTALLED = "1" ];then
    echo "   ==>需要的$GPP_NM未按装！"
  fi
  echo "==>$MPI_NM安装失败！"
else
  echo "==>输入错误！"
fi
wait
#
#
#checking whether the C++ compiler g++ can build an executable... no
#configure: error: Aborting because C++ compiler does not work.  If you do not need a C++ compiler, configure with --disable-cxx
#
#-----------------------------------------------------------------lapack & blas
#
#
if [ $LAPACK_OP = "1" ]; then
  echo "==>安装$LAPACK_NM..."
  cd ${WORKDIR}/$LIBDIR/
  echo $PASSWD | sudo -S -k cp *.a /usr/lib/
  wait
elif [ $LAPACK_OP = "0" ]; then
  echo "==>不安装$LAPACK_NM..."
else
  echo "==>输入错误！"
fi
wait
#
#-------------------------------------------------------------------------petsc
#
#
#---------------------------------------------------------------------------gdb
#
#
#
#
#
##先看看是用的哪个 shell
#ls -al /bin/sh
#
##如果是 Dash 可用以下方法切回 Bash(选择 NO)
#方法一
#sudo dpkg-reconfigure dash
#
#方法二
#sudo ln -fs /bin/bash /bin/sh
#
#
#/etc/fonts/conf.avail----这个里面存放着可供使用的各种语言的字体配置文件；
#/etc/fonts/conf.d----这个里面的配置文件是系统启动时所要加载的。
#明白了这一点，我们只需要在conf.avail中找到简体中文的配置文件，然后复制或者链接到conf.d中即可。打开终端（注意不要切换路径，默认即可），输入如下命令：
#sudo ln -s /etc/fonts/conf.avail/69-language-selector-zh-cn.conf /etc/fonts/conf.d/
#
#http://wiki.ubuntu.org.cn/%E5%AD%97%E4%BD%93
#



#3. 将libflashplayer.so拷到firefox的插件目录/usr/lib/mozilla/plugin/下
#    sudo cp libflashplayer.so /usr/lib/mozilla/plugins   
#
#4. 将usr/目录下所有文件拷到/usr下
#    sudo cp -r usr/* /usr  
#
#5. 重吂firefox就OK了!




