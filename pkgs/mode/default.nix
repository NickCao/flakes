{ writeShellScriptBin, xxd, upower, gnugrep, systemd }:
writeShellScriptBin "mode" ''
  ECREG=`sudo ${xxd}/bin/xxd -s 0x1d -l 1 -ps /sys/kernel/debug/ec/ec0/io`
  echo -n "Fan Control: "
  case $ECREG in
    00)
      echo "Balanced Mode";;
    01)
      echo "Beast Mode";;
    02)
      echo "Quiet Mode";;
  esac

  echo -n "Freq Governor: "
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
  echo -n "GPU Status: "
  cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status

  ${systemd}/lib/systemd/systemd-boot-check-no-failures
''
