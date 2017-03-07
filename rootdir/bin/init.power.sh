#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

################################################################################

# disable thermal hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0
write /sys/devices/soc/soc:qcom,bcl/mode "disable"
write /sys/devices/soc/soc:qcom,bcl/hotplug_mask 0
write /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask 0
write /sys/devices/soc/soc:qcom,bcl/mode "enable"

# bring back main cores CPU 0,2
write /sys/devices/system/cpu/cpu0/online 1
write /sys/devices/system/cpu/cpu2/online 1

# Enable Adaptive LMK
write /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk 1
write /sys/module/lowmemorykiller/parameters/vmpressure_file_min 81250

# if EAS is present, switch to sched governor (no effect if not EAS)
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor "schedutil"
write /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor "schedutil"

# re-enable thermal hotplug
write /sys/module/msm_thermal/core_control/enabled 1
write /sys/devices/soc/soc:qcom,bcl/mode "disable"
write /sys/devices/soc/soc:qcom,bcl/hotplug_mask 12
write /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask 8
write /sys/devices/soc/soc:qcom,bcl/mode "enable"

# Enable bus-dcvs
for cpubw in /sys/class/devfreq/*qcom,cpubw* ; do
    write $cpubw/governor "bw_hwmon"
    write $cpubw/polling_interval 50
    write $cpubw/min_freq 1525
    write $cpubw/bw_hwmon/mbps_zones "1525 5195 11863 13763"
    write $cpubw/bw_hwmon/sample_ms 4
    write $cpubw/bw_hwmon/io_percent 34
    write $cpubw/bw_hwmon/hist_memory 20
    write $cpubw/bw_hwmon/hyst_length 10
    write $cpubw/bw_hwmon/low_power_ceil_mbps 0
    write $cpubw/bw_hwmon/low_power_io_percent 34
    write $cpubw/bw_hwmon/low_power_delay 20
    write $cpubw/bw_hwmon/guard_band_mbps 0
    write $cpubw/bw_hwmon/up_scale 250
    write $cpubw/bw_hwmon/idle_mbps 1600
done

for memlat in /sys/class/devfreq/*qcom,memlat-cpu* ; do
    write $memlat/governor "mem_latency"
    write $memlat/polling_interval 10
done

# Enable all LPMs by default
# This will enable C4, D4, D3, E4 and M3 LPMs
write /sys/module/lpm_levels/parameters/sleep_disabled N

# Set idle GPU to 133 Mhz
write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 6
