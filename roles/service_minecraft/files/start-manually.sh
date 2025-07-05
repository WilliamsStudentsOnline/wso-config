#!/bin/bash
cd /opt/minecraft
# Don't ever bump this beyond about 8GB, massive diminishing returns
sudo -u mc java -Xms512M -Xmx6144M -XX:+UseZGC -XX:+ZGenerational -jar paper.jar --nogui
