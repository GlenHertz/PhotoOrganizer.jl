using PhotoBackup

dry_run = !(length(ARGS) == 1 && ARGS[1] == "-f")
dry_run = true
keep_years_old=99999999999
dst_root="/home/hertz/Pictures/Pictures"

src_dirs = String[]
#push!(src_dirs, "/run/user/1000/gvfs/mtp:host=%5Busb%3A002%2C009%5D/Samsung SD card/CameraZOOM")
#push!(src_dirs, "/run/user/1000/gvfs/mtp:host=%5Busb%3A002%2C009%5D/Samsung SD card/DCIM/Camera")
#push!(src_dirs, "/home/hertz/Documents/Glen/backups/Google/Takeout/Google Photos")
#push!(src_dirs, "/home/hertz/Documents/Erin/backups/Google/Takeout/Google Photos")
#src_dirs = readlines(`/home/hertz/bin/ls_phone_backup_dirs.jl`)

src_dirs = ["/home/hertz/Documents.local/Pictures"]
if length(src_dirs) > 0
    backup_photos(src_dirs, dst_root, keep_years_old, dry_run)
else
    warn("No directories found to backup")
end
