using PhotoOrganizer

dry_run = false
rm_src = false
dst_root="/home/hertz/mnt/media/Pictures"

#src_dirs = String[]
#push!(src_dirs, "/run/user/1000/gvfs/mtp:host=%5Busb%3A002%2C009%5D/Samsung SD card/CameraZOOM")
#push!(src_dirs, "/run/user/1000/gvfs/mtp:host=%5Busb%3A002%2C009%5D/Samsung SD card/DCIM/Camera")
#push!(src_dirs, "/home/hertz/Documents/Glen/backups/Google/Takeout/Google Photos")
#push!(src_dirs, "/home/hertz/Documents/Erin/backups/Google/Takeout/Google Photos")
#src_dirs = readlines(`/home/hertz/bin/ls_phone_backup_dirs.jl`)

#src_dirs = ["/home/hertz/Documents.local/Pictures"]
#src_root = "/home/hertz/Documents/backups/S7"
#src_root = "/run/user/1000/gvfs/mtp:host=%5Busb%3A003%2C004%5D"
#src_dirs = [
#	    "$src_root/Card/DCIM/Camera",
#            "$src_root/Phone/DCIM/Camera",
#            "$src_root/Phone/DCIM/PhotoScan",
#            "$src_root/Phone/DCIM/Screenshots",
#            "$src_root/Phone/DCIM/Video Editor",
#            "$src_root/Phone/Movies/Instagram",
#            "$src_root/Phone/Pictures",
#            "$src_root/Phone/Snapchat",
#            "$src_root/Phone/Snapseed",
#            "$src_root/Phone/Studio",
#            "$src_root/Phone/Telegram",
#            "$src_root/Phone/WhatsApp/Media"]
#src_dirs = ["/media/hertz/NIKON D5500/DCIM"]
src_root = "/home/hertz/mnt/syncthing/Pixel4a"
src_dirs = [
	    "$src_root/Glen_DCIM"
        "$src_root/Phone/DCIM/Camera",
        "$src_root/Phone/DCIM/PhotoScan",
        "$src_root/Phone/DCIM/Screenshots",
        "$src_root/Phone/DCIM/Video Editor",
        "$src_root/Phone/Movies/Instagram",
        "$src_root/Phone/Pictures",
        "$src_root/Phone/Snapchat",
        "$src_root/Phone/Snapseed",
        "$src_root/Phone/Studio",
        "$src_root/Phone/Telegram",
        "$src_root/Phone/WhatsApp/Media"]

if length(src_dirs) > 0
    organize_photos(src_dirs, dst_root, rm_src, dry_run)
else
    warn("No directories found to backup")
end
