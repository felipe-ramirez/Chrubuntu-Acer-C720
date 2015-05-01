#!/bin/bash

###
### Fetch and install the Minecraft icon.
###
wget http://images.wikia.com/yogbox/images/d/dd/Minecraft_Block.svg
mv Minecraft_Block.svg /usr/share/icons/


###
### Create a Minecraft.desktop file in /usr/share/applications
###
cat >/usr/share/applications/Minecraft.desktop <<EOL
[Desktop Entry] 
Name=Minecraft
Comment=
Exec=/opt/Minecraft/Minecraft.sh
Icon=/usr/share/icons/Minecraft_Block.svg
Terminal=false
Type=Application
StartupNotify=true
EOL


###
### Create a Minecraft.sh file in /opt/Minecraft
###
mkdir /opt/Minecraft
cat >/opt/Minecraft/Minecraft.sh <<EOL
#!/bin/bash
cd \$(dirname "\$0")
java -Xmx1024M -Xms512M -cp /opt/Minecraft/Minecraft.jar net.minecraft.bootstrap.Bootstrap
EOL

chmod a+x /opt/Minecraft/Minecraft.sh


###
### Download Minecraft
###

wget https://s3.amazonaws.com/Minecraft.Download/launcher/Minecraft.jar
mv Minecraft.jar /opt/Minecraft/


###
### Install OpenJDK Java 7 Runtime
###

apt-get install -y openjdk-7-jre
