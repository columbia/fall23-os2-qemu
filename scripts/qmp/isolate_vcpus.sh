#!/bin/bash

# Assign all interrupts and processes on the sytem to low-numbered CPUs and
# assign the VCPU thread to high-numbered CPUs.

# Relies on starting QEMU with a qmp socket in /var/run/qmp, like this:
#   qemu-system-aarch64 -qmp unix:/var/run/qmp,server,nowait
#
# Pass the -1 argument to assign all system activities to core 0
#
# Pass the -u argument to undo all isolation/pin operations

# Get number of cores
NCORES=`getconf _NPROCESSORS_ONLN`

# Get number of virtual cores
VCORES=`./qmp-cpus -s /var/run/qmp | wc -l`


# For 2-way SMP systems we need to special-case the SYS_MASK to just use CPU 0
# (it is the best we can do in terms of isolation and supporting guest IPI tests)
if [[ "$1" == "-u" ]]; then
    SYS_MASK=`printf '%x' $(( (1 << $NCORES) - 1 ))`
elif [[ $NCORES -le 2 || "$1" == "-1" ]]; then
    SYS_MASK="1"
else
    SYS_MASK=`printf '%x' $(( ( 1 << ($NCORES - $VCORES)) - 1 ))`
fi

echo "All processes and interrupts will be assigned to: 0x$SYS_MASK"

# Assign all interrupts to SYS_MASK
for IRQDIR in `find /proc/irq/ -maxdepth 1 -mindepth 1 -type d`
do
	echo $SYS_MASK > $IRQDIR/smp_affinity >/dev/null 2>&1
done

# Set the CPU affinity off all processes in the system to SYS_MASK
for PID in `ps -eLf | awk '{ print $4 }'`
do
	taskset -a -p 0x$SYS_MASK $PID >/dev/null 2>&1
done

if [[ "$1" != "-u" ]]; then
	# Pin the VCPU threads to the high cores
	./pin_vcpus.sh
fi
