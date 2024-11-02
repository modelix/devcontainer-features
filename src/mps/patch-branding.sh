#!/bin/sh

# patch branding.jar to not show EULA and data sharing agreement at startup

unzip -d /branding /mps/lib/branding.jar
(
  cd /branding
  sed -i.bak -E "s/JetBrains s.r.o./Modelix/" idea/IdeaApplicationInfo.xml
  rm idea/IdeaApplicationInfo.xml.bak
  rm /mps/lib/branding.jar
  zip -r /mps/lib/branding.jar ./*
)