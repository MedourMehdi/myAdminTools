## How to replace a disk on ceph cluster:

### First List OSD.

`ceph osd tree`

`ceph osd df`

`mount`

`...`

### Check disk slot number using his id.

`ls -l /dev/disk/by-id/`

`megacli -PDList -aALL | egrep 'Adapter|Enclosure|Slot|Inquiry|WWN'`

### Example with OSD number 2 assuming that it is linked to /dev/sdc.

`ceph osd out osd.2`

`systemctl stop ceph-osd@2`

`ceph osd crush remove osd.2`

`ceph auth del osd.2`

`ceph osd rm osd.2`

`umount /dev/sdc1`

### Make the disk case blinking to be sure (here slot number 4).

`megacli -PdLocate -start -physdrv[32:4] -a0 -NoLog`

### We can now replace the disk manualy.

`megacli -PDMakeJBOD -PhysDrv[32:4] -a0`

`ceph osd set noout`

`ceph-disk prepare /dev/sdc`

`ceph osd unset noout`

### Check continiously datas replication.

`ceph -w`

`ceph -s`