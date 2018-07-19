# OrganizePhotos

[![Build Status](https://travis-ci.org/GlenHertz/OrganizePhotos.jl.svg?branch=master)](https://travis-ci.org/GlenHertz/OrganizePhotos.jl)

[![Coverage Status](https://coveralls.io/repos/GlenHertz/OrganizePhotos.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/GlenHertz/OrganizePhotos.jl?branch=master)

[![codecov.io](http://codecov.io/github/GlenHertz/OrganizePhotos.jl/coverage.svg?branch=master)](http://codecov.io/github/GlenHertz/OrganizePhotos.jl?branch=master)

OrganizePhotos is designed to organize a photo archive into a fixed directory structure (since manually managing photos is a waste of time).

# Usage:

    backup_photos(src_dirs, dst_root, keep_years_old, dry_run)

Move and rename photos in `src_dirs` source directories to an organized `dst_root` destination directory.

The destination directory is organized as follows:

    <root>/YYYY/<season>/YYYYMMDD_HHMMSS.SSS_<camera_model>.<extension>

where `season` is `Spring`, `Summer`, `Fall` or `Winter` (depending of photo's date).

## Arguments
- `src_dirs::Vector{String}`: dirctories containing photos to organize.
- `dst_root:String`: the destination directory of organized photos.
- `rm_src::Bool`: delete source photo if true.  Useful if coming from SD card.
- `dry_run::Bool`: if true then don't change anything, just print what would happen.

## Example
```julia
julia> backup_photos(["/media/hertz/NIKON/DCIM"], "/home/hertz/Pictures/Pictures", 9999, true)
```
