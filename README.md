# ft_linux

LFS - Linux from Scratch

## Requirements

- qemu, virt-install, virsh
- USB drive (at least 64GB)
- (Optional): noVNC

## Steps

- (Optional): Configure `MOUNT_DIR` and potentially other environment variables in Makefile  
- (First run only): `make install`  
- `make start`  
- Connect to the VM with:  
  * `make console` (Console connection),  
  * `make ssh` (SSH connection) or  
  * `make vnc` to connect via VNC through the browser for graphical interface  

Run `make help` to see all available commands.  

Now the system is ready for the LFS journey. GLHF;  


## Customized LFS validation

- `uname -r`  
- `journalctl -b | grep "Linux version"`
