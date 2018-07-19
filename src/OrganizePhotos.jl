module OrganizePhotos

export backup_photos

importall Base.Dates

struct Photo
   src::String
   dt::Nullable{DateTime}
   dst::Nullable{String}
   backuped::Bool
   err::Nullable{Any}
end

function Base.show(io::IO, ph::Photo)
   println(io, "Photo:")
   for (i, field) in enumerate(fieldnames(ph))
      f = getfield(ph, field)
      print(io, " - $field: $f")
      if i != length(fieldnames(ph))
         println(io)
      end
   end
end

function get_photo_dst_dir(dt::DateTime, dst_root::String)
   y, m, d = yearmonthday(dt)
   spring = Date(y, 3, 20)
   summer = Date(y, 6, 21)
   fall   = Date(y, 9, 22)
   winter = Date(y,12, 21)
   if dt < spring
      return joinpath(dst_root, string(y), "Winter")
   elseif dt < summer
      return joinpath(dst_root, string(y), "Spring")
   elseif dt < fall
      return joinpath(dst_root, string(y), "Summer")
   elseif dt < winter
      return joinpath(dst_root, string(y), "Fall")
   elseif dt >= winter
      # Consider part of next year's winter
      return joinpath(dst_root, string(y+1), "Winter")
   end
   error("Could not find season for $dt")
end

function organize_photos(mount::String, dst_root::String; dry_run::Bool=true, rm_src::Bool=false)
   #album = Vector{Photo}()
   return Channel(csize=30, ctype=Photo) do album
     dt0 = now()
     ms_in_year = Dates.Millisecond(daysinyear(Dates.year(dt0)) * 24 * 60 * 60 * 1000)
     if !isdir(mount)
         warn("Mount doesn't exist, skipping:\n - $mount")
         close(album)
     end
     if dry_run
        info("Reading from dir (DRY RUN): $mount")
     else
        info("Reading from dir: $mount")
     end
     for line in eachline(Cmd(`exiftool -T -directory -filename -CreateDate -SubSecTime -modifydate -filemodifydate -model -r $mount`, ignorestatus=true))
        dir, fname, date, subsec, modifydate, filemodifydate, camera = split(line, ['\t'])
        if dir == "-"
           warn("Bad SourceFile from exiftool: $line")
           continue
        end
        src = joinpath(dir, fname)
        dtnull = Nullable{DateTime}()
        dstnull = Nullable{String}()
        backuped = false
        errmsg = Nullable{Any}()
        print(src)
        if date == "-"
           date = modifydate
        end
        if date == "-"
           date = filemodifydate
        end
        fields = split(date, [':', ' ', '-', '+', 'Z'])
           yr, m, d, H, M, S = (0, 0, 0, 0, 0, 0)
        try
           yr, m, d, H, M, S = map(str -> parse(Int, str), fields[1:6])
        catch err
           errmsg = "Could not parse date: $fields, $err"
           warn(errmsg)
           push!(album, Photo(src, dtnull, dstnull, backuped, Nullable{Any}(errmsg)))
           continue
        end
        if !(1990 < yr < 2100)
           errmsg = "year out of range ($yr), skipping: $line"
           warn(errmsg)
           push!(album, Photo(src, dtnull, dstnull, backuped, Nullable{Any}(errmsg)))
           continue
        end
        if !(0 <= H <= 23)
           errmsg = "hour out of range ($H), skipping: $line"
           warn(errmsg)
           push!(album, Photo(src, dtnull, dstnull, backuped, Nullable{Any}(errmsg)))
           continue
        end
        if !(0 <= M <= 59)
           errmsg = "minute out of range ($M), skipping: $line"
           warn(errmsg)
           push!(album, Photo(src, dtnull, dstnull, backuped, Nullable{Any}(errmsg)))
           continue
        end
        if !(0 <= S <= 59)
           errmsg = "second out of range ($S), skipping: $line"
           warn(errmsg)
           push!(album, Photo(src, dtnull, dstnull, backuped, Nullable{Any}(errmsg)))
           continue
        end
        MS = 0
        if all(isnumber, subsec)
           try
              MS = round(Int, parse(Float64, "0.$(subsec)")*1000)
           catch err
              warn("Could not parse ms: $subsec, $err")
              continue
           end
        end
        dt = DateTime(yr, m, d, H, M, S, MS)
        # Normalize name of new photo:
        ext = splitext(src)[2]
        new_dir = get_photo_dst_dir(dt, dst_root)
        if camera == "-"
           camera = ""
        else
           camera = string("_", replace(camera, " ", "_"))
        end
        froot = string(lpad(yr, 4, "0"), lpad(m, 2, "0"), lpad(d, 2, "0"), "_", 
                       lpad(H,  2, "0"), lpad(M, 2, "0"), lpad(S, 2, "0"), ".",
                       lpad(MS, 3, "0"), camera)
        is_actual_dup = false
        is_rename_needed = false
	local dst
        for uniq_suffix in ["", map(v->string("_v$v"), 2:200)...]
           dst = joinpath(new_dir, string(froot, uniq_suffix, ext))
           if isfile(dst)
              if stat(src).size == stat(dst).size
                 is_actual_dup = true
                 break
              else 
                 is_rename_needed = true
                 if length(uniq_suffix) == 0
                     print_with_color(:yellow, " renaming")
                 else
                     print_with_color(:yellow, " $uniq_suffix")
                 end
              end
           else
              break
           end
        end
        if is_rename_needed
           print_with_color(:yellow, " $uniq_suffix")
        end
        if isfile(new_dir) && !isdir(new_dir)
            error("Expected directory but found a file:\n - $new_dir")
        end
        if !isdir(new_dir)
            print_with_color(:orange, " mkdir -p $new_dir")
            if !dry_run
                run(`mkdir -p $new_dir`)
            end
        end
        backuped=false
        if !isfile(dst) && !is_actual_dup
            print_with_color(:green, " cp $dst")
            if !dry_run
                try
                   #cp(src, dst, follow_symlinks=true)
                   run(`cp -dR --preserve=all $src $dst`)
                   backuped=true
                catch err
                   warn("Cound not copy file: $src\n$err")
                   continue
                end
            end
        else
           print_with_color(:green, " Skipping dup")
           backuped=true
        end
        age_in_years = (dt0 - dt) / ms_in_year
        if rm_src
            print(" rm src")
            if !dry_run
                try
                   rm(src)
                catch err
                   print_with_color(:red, " rm src failed: $err", bold=true)
                end 
            end
        end
        println()
        push!(album, Photo(src, Nullable{DateTime}(dt), Nullable{String}(dst), backuped, errmsg))
      end
   end
   #return album
end 

struct MountStat
   mount
   photos::Vector{Photo}
end

function report_missing(mount_stats::Vector{MountStat})
   open("missing.log", "w") do f
     print_with_color(:red, "The following files were not backed up (see missing.log):\n", bold=true)
     for mount_stat in mount_stats
        src_dir = mount_stat.mount
        if !isdir(src_dir)
           warn("Source directory doesn't exist, skipping: $src_dir")
           continue
        end
        for file in eachline(`find $(src_dir) -type f`)
           if any(regex->ismatch(regex, file), [r"Picasa\.ini$", r"album.txt", r"\.json$", r"\.DS_Store$", r"Thumbs\.db$", r"CardThumb\.db$", r"\.nomedia$"])
              continue  # non-important file
           end
           matching_photo_idx = findfirst(photo-> photo.src == file, mount_stat.photos)
           if matching_photo_idx != 0 
              photo = mount_stat.photos[matching_photo_idx]
              if !photo.backuped 
                 print(file)
                 print(f, file)
                 print_with_color(:green, " !backuped")
                 print(f, " !backuped")
                 if !isnull(photo.err)
                    msg = get(photo.err)
                    print_with_color(:red, " $msg")
                    print(f, " $msg")
                 end
                 println()
                 println(f)
              end
           else
              print(file)
              print(f, file)
              print_with_color(:red, " missing")
              print(f, " missing")
              println()
              println(f)
           end
        end
     end
   end
end

function backup_photos(mounts::Vector{String}, dst_root::String; dry_run=true, rm_src=false)
   mount_stats = Vector{MountStat}()
   for mount in mounts
      mount_stat = MountStat(mount, Photo[])
      for photo in organize_photos(mount, dst_root, dry_run=dry_run, rm_src=rm_src)
         push!(mount_stat.photos, photo)
      end
      push!(mount_stats, mount_stat)
   end
   info("backed up photos from the following mounts:")
   for stat in mount_stats
      info(" $(length(stat.photos)): $(stat.mount)")
   end
   total = sum(length(stat.photos) for stat in mount_stats)
   info(" $total photos in total")
   return mount_stats
end

"""
    backup_photos(src_dirs, dst_root, rm_src, dry_run)

Move and rename photos in `src_dirs` source directories to an organized `dst_root` destination directory.

The destination directory is organized as follows:

    <root>/YYYY/<season>/YYYYMMDD_HHMMSS.SSS_<camera_model>.<extension>

where `season` is `Spring`, `Summer`, `Fall` or `Winter` (depending of photo's date).

# Arguments
- `src_dirs::Vector{String}`: dirctories containing photos to organize
- `dst_root:String`: the destination directory of organized photos 
- `rm_src::Bool`: delete source photos if true 
- `dry_run::Bool`: if true then don't change anything, just print what would happen

# Examples
```julia-repl
julia> backup_photos(["/home/hertz/Documents.local/Pictures"], "/home/hertz/Pictures/Pictures", 9999, true)
```
"""
function backup_photos(src_dirs::Vector{String}, dst_root::String, rm_src::Bool, dry_run::Bool)
    if dry_run
       warn("DRY RUN: only printing what would happen")
    end
    mount_stats = Vector{MountStat}()
    for dir in src_dirs
       mount_stat = MountStat(dir, Photo[])
       for photo in organize_photos(dir, dst_root, dry_run=dry_run, rm_src=rm_src)
          push!(mount_stat.photos, photo)
       end
       push!(mount_stats, mount_stat)
    end
    info("backed up photos from the following mounts:")
    for stat in mount_stats
       info(" $(length(stat.photos)): $(stat.mount)")
    end
    total = sum(length(stat.photos) for stat in mount_stats)
    info(" $total photos in total")
    report_missing(mount_stats)
    if dry_run
       warn("DRY RUN: only printing what would happen")
    end
end

end # module
