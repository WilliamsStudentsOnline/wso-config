#!/bin/bash
cd /opt/minecraft
# TODO: bump this. but 4GB should be conservative enough.
# Don't ever bump this beyond about 8GB, massive diminishing returns
exec java -Xms512M -Xmx2048M -XX:+UseZGC -XX:+ZGenerational -jar paper.jar --nogui
