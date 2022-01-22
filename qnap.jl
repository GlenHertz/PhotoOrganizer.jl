using PhotoOrganizer

dry_run = false
rm_src = false
dst_root="/mnt/zpool/tank/media/Pictures"

src_dirs = [ "/mnt/zpool/tank/syncthing/Pixel4a" ]
organize_photos(src_dirs, dst_root; rm_src, dry_run, photo_suffix="_Glen")

