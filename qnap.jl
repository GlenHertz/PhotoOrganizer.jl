using PhotoOrganizer

dry_run = false
rm_src = false
dst_root="/mnt/zpool/tank/media/Pictures"

src_dirs = [ "/mnt/zpool/tank/syncthing/Pixel4a" ]
organize_photos(src_dirs, dst_root; rm_src, dry_run, photo_suffix="_Glen")

# Move photos off of IncomingPhotos drive to the photo library
rm_src = true
organize_photos(["/mnt/zpool/tank/IncomingPhotos"], dst_root; rm_src, dry_run)

