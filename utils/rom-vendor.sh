#!/bin/sh

# Drivers (https://developers.google.com/android/nexus/drivers)
cd out/
wget -c https://dl.google.com/dl/android/aosp/broadcom-hammerhead-mra58n-1b71cb95.tgz
wget -c https://dl.google.com/dl/android/aosp/lge-hammerhead-mra58n-922a9ee4.tgz
wget -c https://dl.google.com/dl/android/aosp/qcom-hammerhead-mra58n-630ddcfd.tgz

# Images (https://developers.google.com/android/nexus/images)
wget -c https://dl.google.com/dl/android/aosp/hammerhead-mra58n-factory-aeca4139.tgz
cd -

# Unpacking
for t in out/*.tgz; do
	tar -C out -xavf "${t}"
done

# Extracting
for s in out/extract*.sh; do
	sed -i 's/^more/cat/' "${s}"
	sed -i 's/^read\ dummy//' "${s}"
	sed -i 's/^read\ typed/typed="I\ ACCEPT"/' "${s}"
	"${s}"
done

# Add google vendor
git clone git://githib.com/eugenesan/android-vendor-google.git vendor/google

# Unpack system image
unzip -o out/hammerhead-mra58k/image-hammerhead-mra58n.zip system.img -d out

# Convert and mount system image
vendor/google/boot.img.sh unmount
vendor/google/boot.img.sh convert
vendor/google/boot.img.sh mount

# Enable vendor
echo '-include vendor/eugenesan/$(LOCAL_STEM)' >> vendor/lge/hammerhead/BoardConfigVendor.mk
echo '$(call inherit-product-if-exists, vendor/eugenesan/$(LOCAL_STEM))' >> vendor/lge/hammerhead/device-vendor.mk

echo "Remeber to clean out directory before re-trying build!"
