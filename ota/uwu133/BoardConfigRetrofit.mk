# OnePlus 6 uwuAOSP 17.0.133: VERIFIED-layout-only A/B Retrofit Dynamic profile.
# Included by device/oneplus/enchilada/BoardConfig.mk only for uwu_enchilada.
# This is a source-only candidate: NOT validated target-files or signed OTA.
# Values MUST come from the actual phone's blockdev and lpdump output.

ifneq ($(TARGET_PRODUCT),uwu_enchilada)
$(error OP6 Retrofit profile included for unexpected product $(TARGET_PRODUCT))
endif

# Fail closed. An old physical ext4 device tree must never emit a misleading OTA.
ifneq ($(OP6_UWU133_LAYOUT_VERIFIED),true)
$(error uwu_enchilada: retrofit layout not verified; supply device lpdump/bootctl preflight first)
endif

_required_op6_ota_sizes := \
    OP6_UWU133_SYSTEM_DEVICE_SIZE \
    OP6_UWU133_VENDOR_DEVICE_SIZE \
    OP6_UWU133_ODM_DEVICE_SIZE \
    OP6_UWU133_SUPER_PARTITION_SIZE \
    OP6_UWU133_DYNAMIC_GROUP_SIZE
$(foreach n,$(_required_op6_ota_sizes),$(if $($(n)),,$(error uwu_enchilada: missing verified $(n))))

# Exact current ROM fstab was extracted read-only from 64MiB boot.img (SHA256
# 6b305cace01270c797c7ad44a1457154ec91667227ce1e4b35be49156d940a0e).
# system/vendor/odm are EROFS logical block devices; /metadata is logdump.
TARGET_RECOVERY_FSTAB := device/oneplus/sdm845-common/ota/uwu133/fstab.qcom
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs

# Existing legacy physical partition image maxima must not survive the retrofit
# profile: lp metadata and the named group own the logical partition capacities.
BOARD_SYSTEMIMAGE_PARTITION_SIZE :=
BOARD_VENDORIMAGE_PARTITION_SIZE :=
BOARD_ODMIMAGE_PARTITION_SIZE :=

BOARD_SUPER_PARTITION_METADATA_DEVICE := system
BOARD_SUPER_PARTITION_BLOCK_DEVICES := system vendor odm
BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE := $(OP6_UWU133_SYSTEM_DEVICE_SIZE)
BOARD_SUPER_PARTITION_VENDOR_DEVICE_SIZE := $(OP6_UWU133_VENDOR_DEVICE_SIZE)
BOARD_SUPER_PARTITION_ODM_DEVICE_SIZE := $(OP6_UWU133_ODM_DEVICE_SIZE)
BOARD_SUPER_PARTITION_SIZE := $(OP6_UWU133_SUPER_PARTITION_SIZE)
BOARD_SUPER_PARTITION_GROUPS := oneplus_dynamic_partitions
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor odm
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := $(OP6_UWU133_DYNAMIC_GROUP_SIZE)

# Device already uses A/B. Reconcile partition list with target_files before OTA.
AB_OTA_PARTITIONS += odm