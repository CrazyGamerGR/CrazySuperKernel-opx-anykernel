# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers
# modified by CrazyGamerGR for CrazySuperKernel

## AnyKernel setup
# EDIFY properties
do.devicecheck=1
do.initd=1
do.modules=1
do.cleanup=1
device.name1=OnePlus
device.name2=ONE
device.name3=onyx
device.name4=E1003

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;
initd=/system/etc/init.d;
bindir=/system/bin;
is_slot_device=0;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel permissions
# set permissions for included ramdisk files
chmod 755 /tmp/anykernel/ramdisk/sbin/busybox
chmod -R 755 $ramdisk


## AnyKernel install
dump_boot;

# begin ramdisk changes

# Init.d
cp -fp $patch/init.d/* $initd
chmod -R 755 $initd

# remove mpdecsion binary
mv $bindir/mpdecision $bindir/mpdecision-rm

# Android version
if [ -f "/system/build.prop" ]; then
  SDK="$(grep "ro.build.version.sdk" "/system/build.prop" | cut -d '=' -f 2)";
  ui_print "Android SDK API: $SDK.";
  if [ "$SDK" -le "21" ]; then
    ui_print " "; ui_print "Android 5.0 and older is not supported. Aborting..."; exit 1;
  fi;
else
  ui_print " "; ui_print "No build.prop could be found. Aborting..."; exit 1;
fi;

# Properties
ui_print "Modifying properties...";
backup_file default.prop;
replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
replace_string default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";

# Init files
ui_print "Modifying init files...";
# CyanogenMod
if [ -f init.onyx.rc ]; then
  if [ "$SDK" -ge "24" ]; then
    ui_print "CyanogenMod 14.1 based ROM detected.";
  elif [ "$SDK" -eq "23" ]; then
    ui_print "CyanogenMod 13.0 based ROM detected.";
  elif [ "$SDK" -eq "22" ]; then
    ui_print "CyanogenMod 12.1 based ROM detected.";
  fi;
  backup_file init.onyx.rc;
  ui_print "Injecting post-boot script support...";
  append_file init.onyx.rc "csk-post_boot" init.onyx.patch;
fi;

# Fast Random
ui_print "Injecting frandom/erandom support...";
if [ -f file_contexts.bin ]; then
  # Nougat file_contexts binary can't be patched so simply.
  ui_print "File contexts is a binary file, skipping...";
elif [ -f file_contexts ]; then
  # Marshmallow file_contexts can be patched.
  ui_print "Patching file contexts...";
  backup_file file_contexts;
  insert_line file_contexts "frandom" after "/dev/urandom            u:object_r:urandom_device:s0" "/dev/frandom            u:object_r:frandom_device:s0\n/dev/erandom            u:object_r:erandom_device:s0"
fi;
if [ -f ueventd.rc ]; then
  ui_print "Patching ueventd devices...";
  backup_file ueventd.rc;
  insert_line ueventd.rc "frandom" after "/dev/urandom              0666   root       root" "/dev/frandom              0666   root       root\n/dev/erandom              0666   root       root"
fi;

# init.onyx.rc
backup_file init.onyx.rc;
append_file init.onyx.rc "csk-post_boot" init.onyx.patch;

# end ramdisk changes

write_boot;

## end install

