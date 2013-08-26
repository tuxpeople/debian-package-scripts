#!/bin/bash
 
# jdk_packager.sh
#    Downloads JDK 7 and packages as DEB for both i386 and amd64
#    The resulting packages installing to /opt, creating a symlink /opt/java7 and do some magic stuff which hopefully works.
# 
# Requirements
#  - Effing Package Management
#    https://github.com/jordansissel/fpm
#
# Acknowledgments
#  - http://stackoverflow.com/questions/10268583/how-to-automate-download-and-instalation-of-java-jdk-on-linux
#  - http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
#  - Danilo Tommasina
 
## Set a var called DEBUG to anything you want if you need debug output.
# DEBUG="YES"
 
###################################################################
# VAR's (to set)                                                  #
###################################################################
BASEDIR=/tmp
DLDDIR=$BASEDIR/jdkdld
WRKDIR=$BASEDIR/jdkpkg
PACKAGENAME=my-jdk7
MAINTAINER=its.me@mydomain.com
PACKAGEURL="http://www.mydomain.com"
PACKAGEDESCRIPTION="My package of JDK 7"
 
###################################################################
# VAR's (NOT to set)                                              #
###################################################################
X64_DOWNLOAD=$(wget -q $(lynx -dump http://www.oracle.com/technetwork/java/javase/downloads/index.html | grep jdk7-downloads | head -1 | awk '{ print $2 }') -O - | grep linux-x64.tar.gz | cut -d'"' -f12)
X32_DOWNLOAD=$(wget -q $(lynx -dump http://www.oracle.com/technetwork/java/javase/downloads/index.html | grep jdk7-downloads | head -1 | awk '{ print $2 }') -O - | grep linux-i586.tar.gz | cut -d'"' -f12)
X64_NAME=$(basename $X64_DOWNLOAD)
X32_NAME=$(basename $X32_DOWNLOAD)
JVERSION=$(echo $X64_NAME | cut -d'-' -f2)
 
###################################################################
# The basics                                                      #
###################################################################
 
# check for FPM
command -v fpm >/dev/null 2>&1 || { echo >&2 "!!    I require fpm but it's not installed.  Aborting. Please check https://github.com/jordansissel/fpm for more details."; exit 1; }
 
# Debug infos
if [ ! -z "$1" ]; then
    echo "DEBUG: URL for 64bit JDK: $X64_DOWNLOAD"
    echo "DEBUG: URL for 32bit JDK: $X32_DOWNLOAD"
fi
 
# Download
echo " *    Start downloading to $DLDDIR."
 
mkdir -p $DLDDIR
echo "      $X64_NAME"
wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" -q $X64_DOWNLOAD -O $DLDDIR/$X64_NAME
echo "      $X32_NAME"
wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" -q $X32_DOWNLOAD -O $DLDDIR/$X32_NAME
 
echo " *    Finished download."
 
###################################################################
# Creating X64 package                                            #
###################################################################
mkdir -p $WRKDIR/working/opt
mkdir -p $WRKDIR/working/usr/lib/jvm/
cd $WRKDIR/working/opt
tar -xzf $DLDDIR/$X64_NAME
 
JAVA_PKG=$(ls -1)
 
cat <<EOF > $WRKDIR/working/usr/lib/jvm/.java-7-oracle.jinfo
name=java-7-oracle
alias=java-7-oracle
priority=63
section=non-free
 
jre ControlPanel /opt/java7/jre/bin/ControlPanel
jre java /opt/java7/jre/bin/java
jre java_vm /opt/java7/jre/bin/java_vm
jre javaws /opt/java7/jre/bin/javaws
jre jcontrol /opt/java7/jre/bin/jcontrol
jre keytool /opt/java7/jre/bin/keytool
jre pack200 /opt/java7/jre/bin/pack200
jre policytool /opt/java7/jre/bin/policytool
jre rmid /opt/java7/jre/bin/rmid
jre rmiregistry /opt/java7/jre/bin/rmiregistry
jre unpack200 /opt/java7/jre/bin/unpack200
jre orbd /opt/java7/jre/bin/orbd
jre servertool /opt/java7/jre/bin/servertool
jre tnameserv /opt/java7/jre/bin/tnameserv
jre jexec /opt/java7/jre/lib/jexec
jdk appletviewer /opt/java7/bin/appletviewer
jdk apt /opt/java7/bin/apt
jdk extcheck /opt/java7/bin/extcheck
jdk idlj /opt/java7/bin/idlj
jdk jar /opt/java7/bin/jar
jdk jarsigner /opt/java7/bin/jarsigner
jdk java-rmi.cgi /opt/java7/bin/java-rmi.cgi
jdk javac /opt/java7/bin/javac
jdk javadoc /opt/java7/bin/javadoc
jdk javah /opt/java7/bin/javah
jdk javap /opt/java7/bin/javap
jdk jconsole /opt/java7/bin/jconsole
jdk jdb /opt/java7/bin/jdb
jdk jhat /opt/java7/bin/jhat
jdk jinfo /opt/java7/bin/jinfo
jdk jmap /opt/java7/bin/jmap
jdk jps /opt/java7/bin/jps
jdk jrunscript /opt/java7/bin/jrunscript
jdk jsadebugd /opt/java7/bin/jsadebugd
jdk jstack /opt/java7/bin/jstack
jdk jstat /opt/java7/bin/jstat
jdk jstatd /opt/java7/bin/jstatd
jdk native2ascii /opt/java7/bin/native2ascii
jdk rmic /opt/java7/bin/rmic
jdk schemagen /opt/java7/bin/schemagen
jdk serialver /opt/java7/bin/serialver
jdk wsgen /opt/java7/bin/wsgen
jdk wsimport /opt/java7/bin/wsimport
jdk xjc /opt/java7/bin/xjc
plugin xulrunner-1.9-javaplugin.so /opt/java7/jre/lib/amd64/libnpjp2.so
plugin mozilla-javaplugin.so /opt/java7/jre/lib/amd64/libnpjp2.so
EOF
 
cat <<EOF > $WRKDIR/working/opt/$JAVA_PKG/javaconfig.sh
#!/bin/sh
 
if [ -e /usr/lib/jvm/java-7-oracle ]; then
   rm -rf /usr/lib/jvm/java-7-oracle
fi
ln -fs /opt/java7 /usr/lib/jvm/java-7-oracle
 
update-alternatives --quiet --install /usr/lib/xulrunner-addons/plugins/libjavaplugin.so xulrunner-1.9-javaplugin.so /opt/java7/jre/lib/amd64/libnpjp2.so 63
update-alternatives --quiet --install /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so /opt/java7/jre/lib/amd64/libnpjp2.so 63
update-alternatives --quiet --install /usr/bin/appletviewer appletviewer /opt/java7/bin/appletviewer 63 --slave /usr/share/man/man1/appletviewer.1 appletviewer.1 /opt/java7/man/man1/appletviewer.1
update-alternatives --quiet --install /usr/bin/apt apt /opt/java7/bin/apt 63 --slave /usr/share/man/man1/apt.1 apt.1 /opt/java7/man/man1/apt.1
update-alternatives --quiet --install /usr/bin/extcheck extcheck /opt/java7/bin/extcheck 63 --slave /usr/share/man/man1/extcheck.1 extcheck.1 /opt/java7/man/man1/extcheck.1
update-alternatives --quiet --install /usr/bin/idlj idlj /opt/java7/bin/idlj 63 --slave /usr/share/man/man1/idlj.1 idlj.1 /opt/java7/man/man1/idlj.1
update-alternatives --quiet --install /usr/bin/jar jar /opt/java7/bin/jar 63 --slave /usr/share/man/man1/jar.1 jar.1 /opt/java7/man/man1/jar.1
update-alternatives --quiet --install /usr/bin/jarsigner jarsigner /opt/java7/bin/jarsigner 63 --slave /usr/share/man/man1/jarsigner.1 jarsigner.1 /opt/java7/man/man1/jarsigner.1
update-alternatives --quiet --install /usr/bin/javac javac /opt/java7/bin/javac 63 --slave /usr/share/man/man1/javac.1 javac.1 /opt/java7/man/man1/javac.1
update-alternatives --quiet --install /usr/bin/javadoc javadoc /opt/java7/bin/javadoc 63 --slave /usr/share/man/man1/javadoc.1 javadoc.1 /opt/java7/man/man1/javadoc.1
update-alternatives --quiet --install /usr/bin/javah javah /opt/java7/bin/javah 63 --slave /usr/share/man/man1/javah.1 javah.1 /opt/java7/man/man1/javah.1
update-alternatives --quiet --install /usr/bin/javap javap /opt/java7/bin/javap 63 --slave /usr/share/man/man1/javap.1 javap.1 /opt/java7/man/man1/javap.1
update-alternatives --quiet --install /usr/bin/jconsole jconsole /opt/java7/bin/jconsole 63 --slave /usr/share/man/man1/jconsole.1 jconsole.1 /opt/java7/man/man1/jconsole.1
update-alternatives --quiet --install /usr/bin/jdb jdb /opt/java7/bin/jdb 63 --slave /usr/share/man/man1/jdb.1 jdb.1 /opt/java7/man/man1/jdb.1
update-alternatives --quiet --install /usr/bin/jhat jhat /opt/java7/bin/jhat 63 --slave /usr/share/man/man1/jhat.1 jhat.1 /opt/java7/man/man1/jhat.1
update-alternatives --quiet --install /usr/bin/jinfo jinfo /opt/java7/bin/jinfo 63 --slave /usr/share/man/man1/jinfo.1 jinfo.1 /opt/java7/man/man1/jinfo.1
update-alternatives --quiet --install /usr/bin/jmap jmap /opt/java7/bin/jmap 63 --slave /usr/share/man/man1/jmap.1 jmap.1 /opt/java7/man/man1/jmap.1
update-alternatives --quiet --install /usr/bin/jps jps /opt/java7/bin/jps 63 --slave /usr/share/man/man1/jps.1 jps.1 /opt/java7/man/man1/jps.1
update-alternatives --quiet --install /usr/bin/jrunscript jrunscript /opt/java7/bin/jrunscript 63 --slave /usr/share/man/man1/jrunscript.1 jrunscript.1 /opt/java7/man/man1/jrunscript.1
update-alternatives --quiet --install /usr/bin/jsadebugd jsadebugd /opt/java7/bin/jsadebugd 63 --slave /usr/share/man/man1/jsadebugd.1 jsadebugd.1 /opt/java7/man/man1/jsadebugd.1
update-alternatives --quiet --install /usr/bin/jstack jstack /opt/java7/bin/jstack 63 --slave /usr/share/man/man1/jstack.1 jstack.1 /opt/java7/man/man1/jstack.1
update-alternatives --quiet --install /usr/bin/jstat jstat /opt/java7/bin/jstat 63 --slave /usr/share/man/man1/jstat.1 jstat.1 /opt/java7/man/man1/jstat.1
update-alternatives --quiet --install /usr/bin/jstatd jstatd /opt/java7/bin/jstatd 63 --slave /usr/share/man/man1/jstatd.1 jstatd.1 /opt/java7/man/man1/jstatd.1
update-alternatives --quiet --install /usr/bin/native2ascii native2ascii /opt/java7/bin/native2ascii 63 --slave /usr/share/man/man1/native2ascii.1 native2ascii.1 /opt/java7/man/man1/native2ascii.1
update-alternatives --quiet --install /usr/bin/rmic rmic /opt/java7/bin/rmic 63 --slave /usr/share/man/man1/rmic.1 rmic.1 /opt/java7/man/man1/rmic.1
update-alternatives --quiet --install /usr/bin/schemagen schemagen /opt/java7/bin/schemagen 63 --slave /usr/share/man/man1/schemagen.1 schemagen.1 /opt/java7/man/man1/schemagen.1
update-alternatives --quiet --install /usr/bin/serialver serialver /opt/java7/bin/serialver 63 --slave /usr/share/man/man1/serialver.1 serialver.1 /opt/java7/man/man1/serialver.1
update-alternatives --quiet --install /usr/bin/wsgen wsgen /opt/java7/bin/wsgen 63 --slave /usr/share/man/man1/wsgen.1 wsgen.1 /opt/java7/man/man1/wsgen.1
update-alternatives --quiet --install /usr/bin/wsimport wsimport /opt/java7/bin/wsimport 63 --slave /usr/share/man/man1/wsimport.1 wsimport.1 /opt/java7/man/man1/wsimport.1
update-alternatives --quiet --install /usr/bin/xjc xjc /opt/java7/bin/xjc 63 --slave /usr/share/man/man1/xjc.1 xjc.1 /opt/java7/man/man1/xjc.1
update-alternatives --quiet --install /usr/bin/java-rmi.cgi java-rmi.cgi /opt/java7/bin/java-rmi.cgi 63
update-alternatives --quiet --install /usr/bin/ControlPanel ControlPanel /opt/java7/jre/bin/ControlPanel 63
update-alternatives --quiet --install /usr/bin/java java /opt/java7/jre/bin/java 63
update-alternatives --quiet --install /usr/bin/java_vm java_vm /opt/java7/jre/bin/java_vm 63
update-alternatives --quiet --install /usr/bin/javaws javaws /opt/java7/jre/bin/javaws 63
update-alternatives --quiet --install /usr/bin/jcontrol jcontrol /opt/java7/jre/bin/jcontrol 63
update-alternatives --quiet --install /usr/bin/keytool keytool /opt/java7/jre/bin/keytool 63
update-alternatives --quiet --install /usr/bin/pack200 pack200 /opt/java7/jre/bin/pack200 63
update-alternatives --quiet --install /usr/bin/policytool policytool /opt/java7/jre/bin/policytool 63
update-alternatives --quiet --install /usr/bin/rmid rmid /opt/java7/jre/bin/rmid 63
update-alternatives --quiet --install /usr/bin/rmiregistry rmiregistry /opt/java7/jre/bin/rmiregistry 63
update-alternatives --quiet --install /usr/bin/unpack200 unpack200 /opt/java7/jre/bin/unpack200 63
update-alternatives --quiet --install /usr/bin/orbd orbd /opt/java7/jre/bin/orbd 63
update-alternatives --quiet --install /usr/bin/servertool servertool /opt/java7/jre/bin/servertool 63
update-alternatives --quiet --install /usr/bin/tnameserv tnameserv /opt/java7/jre/bin/tnameserv 63
update-alternatives --quiet --install /usr/bin/jexec jexec /opt/java7/jre/lib/jexec 63
EOF
 
cat <<EOF > $WRKDIR/working/opt/$JAVA_PKG/postinstall.sh
#!/bin/bash
if [ -e /opt/java7 ]; then
   rm /opt/java7
fi
ln -fs /opt/$JAVA_PKG /opt/java7
/bin/bash /opt/$JAVA_PKG/javaconfig.sh
EOF
 
chmod +x $WRKDIR/working/opt/$JAVA_PKG/postinstall.sh
 
echo " *    Create amd64 package."
fpm -s dir -t deb -a x86_64 --post-install $WRKDIR/working/opt/$JAVA_PKG/postinstall.sh -m $MAINTAINER --url $PACKAGEURL --description "$PACKAGEDESCRIPTION" -n $PACKAGENAME -v $JVERSION -C $WRKDIR/working ./
 
MYDEBFILE=$(ls -1 *.deb)
mv $MYDEBFILE $BASEDIR/
echo " *    Moved $MYDEBFILE to $BASEDIR."
 
rm -rf *
 
 
###################################################################
# Creating i386 package                                           #
###################################################################
mkdir -p $WRKDIR/working/opt
mkdir -p $WRKDIR/working/usr/lib/jvm/
cd $WRKDIR/working/opt
tar -xzf $DLDDIR/$X32_NAME
 
JAVA_PKG=$(ls -1)
 
cat <<EOF > $WRKDIR/working/usr/lib/jvm/.java-7-oracle.jinfo
name=java-7-oracle
alias=java-7-oracle
priority=63
section=non-free
 
jre ControlPanel /opt/java7/jre/bin/ControlPanel
jre java /opt/java7/jre/bin/java
jre java_vm /opt/java7/jre/bin/java_vm
jre javaws /opt/java7/jre/bin/javaws
jre jcontrol /opt/java7/jre/bin/jcontrol
jre keytool /opt/java7/jre/bin/keytool
jre pack200 /opt/java7/jre/bin/pack200
jre policytool /opt/java7/jre/bin/policytool
jre rmid /opt/java7/jre/bin/rmid
jre rmiregistry /opt/java7/jre/bin/rmiregistry
jre unpack200 /opt/java7/jre/bin/unpack200
jre orbd /opt/java7/jre/bin/orbd
jre servertool /opt/java7/jre/bin/servertool
jre tnameserv /opt/java7/jre/bin/tnameserv
jre jexec /opt/java7/jre/lib/jexec
jdk appletviewer /opt/java7/bin/appletviewer
jdk apt /opt/java7/bin/apt
jdk extcheck /opt/java7/bin/extcheck
jdk idlj /opt/java7/bin/idlj
jdk jar /opt/java7/bin/jar
jdk jarsigner /opt/java7/bin/jarsigner
jdk java-rmi.cgi /opt/java7/bin/java-rmi.cgi
jdk javac /opt/java7/bin/javac
jdk javadoc /opt/java7/bin/javadoc
jdk javah /opt/java7/bin/javah
jdk javap /opt/java7/bin/javap
jdk jconsole /opt/java7/bin/jconsole
jdk jdb /opt/java7/bin/jdb
jdk jhat /opt/java7/bin/jhat
jdk jinfo /opt/java7/bin/jinfo
jdk jmap /opt/java7/bin/jmap
jdk jps /opt/java7/bin/jps
jdk jrunscript /opt/java7/bin/jrunscript
jdk jsadebugd /opt/java7/bin/jsadebugd
jdk jstack /opt/java7/bin/jstack
jdk jstat /opt/java7/bin/jstat
jdk jstatd /opt/java7/bin/jstatd
jdk native2ascii /opt/java7/bin/native2ascii
jdk rmic /opt/java7/bin/rmic
jdk schemagen /opt/java7/bin/schemagen
jdk serialver /opt/java7/bin/serialver
jdk wsgen /opt/java7/bin/wsgen
jdk wsimport /opt/java7/bin/wsimport
jdk xjc /opt/java7/bin/xjc
plugin xulrunner-1.9-javaplugin.so /opt/java7/jre/lib/i386/libnpjp2.so
plugin mozilla-javaplugin.so /opt/java7/jre/lib/i386/libnpjp2.so
EOF
 
cat <<EOF > $WRKDIR/working/opt/$JAVA_PKG/javaconfig.sh
#!/bin/sh
 
if [ -e /usr/lib/jvm/java-7-oracle ]; then
   rm -rf /usr/lib/jvm/java-7-oracle
fi
ln -fs /opt/java7 /usr/lib/jvm/java-7-oracle
 
update-alternatives --quiet --install /usr/lib/xulrunner-addons/plugins/libjavaplugin.so xulrunner-1.9-javaplugin.so /opt/java7/jre/lib/i386/libnpjp2.so 63
update-alternatives --quiet --install /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so /opt/java7/jre/lib/i386/libnpjp2.so 63
update-alternatives --quiet --install /usr/bin/appletviewer appletviewer /opt/java7/bin/appletviewer 63 --slave /usr/share/man/man1/appletviewer.1 appletviewer.1 /opt/java7/man/man1/appletviewer.1
update-alternatives --quiet --install /usr/bin/apt apt /opt/java7/bin/apt 63 --slave /usr/share/man/man1/apt.1 apt.1 /opt/java7/man/man1/apt.1
update-alternatives --quiet --install /usr/bin/extcheck extcheck /opt/java7/bin/extcheck 63 --slave /usr/share/man/man1/extcheck.1 extcheck.1 /opt/java7/man/man1/extcheck.1
update-alternatives --quiet --install /usr/bin/idlj idlj /opt/java7/bin/idlj 63 --slave /usr/share/man/man1/idlj.1 idlj.1 /opt/java7/man/man1/idlj.1
update-alternatives --quiet --install /usr/bin/jar jar /opt/java7/bin/jar 63 --slave /usr/share/man/man1/jar.1 jar.1 /opt/java7/man/man1/jar.1
update-alternatives --quiet --install /usr/bin/jarsigner jarsigner /opt/java7/bin/jarsigner 63 --slave /usr/share/man/man1/jarsigner.1 jarsigner.1 /opt/java7/man/man1/jarsigner.1
update-alternatives --quiet --install /usr/bin/javac javac /opt/java7/bin/javac 63 --slave /usr/share/man/man1/javac.1 javac.1 /opt/java7/man/man1/javac.1
update-alternatives --quiet --install /usr/bin/javadoc javadoc /opt/java7/bin/javadoc 63 --slave /usr/share/man/man1/javadoc.1 javadoc.1 /opt/java7/man/man1/javadoc.1
update-alternatives --quiet --install /usr/bin/javah javah /opt/java7/bin/javah 63 --slave /usr/share/man/man1/javah.1 javah.1 /opt/java7/man/man1/javah.1
update-alternatives --quiet --install /usr/bin/javap javap /opt/java7/bin/javap 63 --slave /usr/share/man/man1/javap.1 javap.1 /opt/java7/man/man1/javap.1
update-alternatives --quiet --install /usr/bin/jconsole jconsole /opt/java7/bin/jconsole 63 --slave /usr/share/man/man1/jconsole.1 jconsole.1 /opt/java7/man/man1/jconsole.1
update-alternatives --quiet --install /usr/bin/jdb jdb /opt/java7/bin/jdb 63 --slave /usr/share/man/man1/jdb.1 jdb.1 /opt/java7/man/man1/jdb.1
update-alternatives --quiet --install /usr/bin/jhat jhat /opt/java7/bin/jhat 63 --slave /usr/share/man/man1/jhat.1 jhat.1 /opt/java7/man/man1/jhat.1
update-alternatives --quiet --install /usr/bin/jinfo jinfo /opt/java7/bin/jinfo 63 --slave /usr/share/man/man1/jinfo.1 jinfo.1 /opt/java7/man/man1/jinfo.1
update-alternatives --quiet --install /usr/bin/jmap jmap /opt/java7/bin/jmap 63 --slave /usr/share/man/man1/jmap.1 jmap.1 /opt/java7/man/man1/jmap.1
update-alternatives --quiet --install /usr/bin/jps jps /opt/java7/bin/jps 63 --slave /usr/share/man/man1/jps.1 jps.1 /opt/java7/man/man1/jps.1
update-alternatives --quiet --install /usr/bin/jrunscript jrunscript /opt/java7/bin/jrunscript 63 --slave /usr/share/man/man1/jrunscript.1 jrunscript.1 /opt/java7/man/man1/jrunscript.1
update-alternatives --quiet --install /usr/bin/jsadebugd jsadebugd /opt/java7/bin/jsadebugd 63 --slave /usr/share/man/man1/jsadebugd.1 jsadebugd.1 /opt/java7/man/man1/jsadebugd.1
update-alternatives --quiet --install /usr/bin/jstack jstack /opt/java7/bin/jstack 63 --slave /usr/share/man/man1/jstack.1 jstack.1 /opt/java7/man/man1/jstack.1
update-alternatives --quiet --install /usr/bin/jstat jstat /opt/java7/bin/jstat 63 --slave /usr/share/man/man1/jstat.1 jstat.1 /opt/java7/man/man1/jstat.1
update-alternatives --quiet --install /usr/bin/jstatd jstatd /opt/java7/bin/jstatd 63 --slave /usr/share/man/man1/jstatd.1 jstatd.1 /opt/java7/man/man1/jstatd.1
update-alternatives --quiet --install /usr/bin/native2ascii native2ascii /opt/java7/bin/native2ascii 63 --slave /usr/share/man/man1/native2ascii.1 native2ascii.1 /opt/java7/man/man1/native2ascii.1
update-alternatives --quiet --install /usr/bin/rmic rmic /opt/java7/bin/rmic 63 --slave /usr/share/man/man1/rmic.1 rmic.1 /opt/java7/man/man1/rmic.1
update-alternatives --quiet --install /usr/bin/schemagen schemagen /opt/java7/bin/schemagen 63 --slave /usr/share/man/man1/schemagen.1 schemagen.1 /opt/java7/man/man1/schemagen.1
update-alternatives --quiet --install /usr/bin/serialver serialver /opt/java7/bin/serialver 63 --slave /usr/share/man/man1/serialver.1 serialver.1 /opt/java7/man/man1/serialver.1
update-alternatives --quiet --install /usr/bin/wsgen wsgen /opt/java7/bin/wsgen 63 --slave /usr/share/man/man1/wsgen.1 wsgen.1 /opt/java7/man/man1/wsgen.1
update-alternatives --quiet --install /usr/bin/wsimport wsimport /opt/java7/bin/wsimport 63 --slave /usr/share/man/man1/wsimport.1 wsimport.1 /opt/java7/man/man1/wsimport.1
update-alternatives --quiet --install /usr/bin/xjc xjc /opt/java7/bin/xjc 63 --slave /usr/share/man/man1/xjc.1 xjc.1 /opt/java7/man/man1/xjc.1
update-alternatives --quiet --install /usr/bin/java-rmi.cgi java-rmi.cgi /opt/java7/bin/java-rmi.cgi 63
update-alternatives --quiet --install /usr/bin/ControlPanel ControlPanel /opt/java7/jre/bin/ControlPanel 63
update-alternatives --quiet --install /usr/bin/java java /opt/java7/jre/bin/java 63
update-alternatives --quiet --install /usr/bin/java_vm java_vm /opt/java7/jre/bin/java_vm 63
update-alternatives --quiet --install /usr/bin/javaws javaws /opt/java7/jre/bin/javaws 63
update-alternatives --quiet --install /usr/bin/jcontrol jcontrol /opt/java7/jre/bin/jcontrol 63
update-alternatives --quiet --install /usr/bin/keytool keytool /opt/java7/jre/bin/keytool 63
update-alternatives --quiet --install /usr/bin/pack200 pack200 /opt/java7/jre/bin/pack200 63
update-alternatives --quiet --install /usr/bin/policytool policytool /opt/java7/jre/bin/policytool 63
update-alternatives --quiet --install /usr/bin/rmid rmid /opt/java7/jre/bin/rmid 63
update-alternatives --quiet --install /usr/bin/rmiregistry rmiregistry /opt/java7/jre/bin/rmiregistry 63
update-alternatives --quiet --install /usr/bin/unpack200 unpack200 /opt/java7/jre/bin/unpack200 63
update-alternatives --quiet --install /usr/bin/orbd orbd /opt/java7/jre/bin/orbd 63
update-alternatives --quiet --install /usr/bin/servertool servertool /opt/java7/jre/bin/servertool 63
update-alternatives --quiet --install /usr/bin/tnameserv tnameserv /opt/java7/jre/bin/tnameserv 63
update-alternatives --quiet --install /usr/bin/jexec jexec /opt/java7/jre/lib/jexec 63
EOF
 
cat <<EOF > $WRKDIR/working/opt/$JAVA_PKG/postinstall.sh
#!/bin/bash
if [ -e /opt/java7 ]; then
   rm /opt/java7
fi
ln -fs /opt/$JAVA_PKG /opt/java7
/bin/bash /opt/$JAVA_PKG/javaconfig.sh
EOF
 
chmod +x $WRKDIR/working/opt/$JAVA_PKG/postinstall.sh
 
echo " *    Create i386 package."
fpm -s dir -t deb -a i386 --post-install $WRKDIR/working/opt/$JAVA_PKG/postinstall.sh -m $MAINTAINER --url $PACKAGEURL --description "$PACKAGEDESCRIPTION" -n $PACKAGENAME -v $JVERSION -C $WRKDIR/working ./
 
MYDEBFILE=$(ls -1 *.deb)
mv $MYDEBFILE $BASEDIR/
echo " *    Moved $MYDEBFILE to $BASEDIR."
 
 
###################################################################
# Cleanup                                                         #
###################################################################
rm -rf $DLDDIR
rm -rf $WRKDIR
