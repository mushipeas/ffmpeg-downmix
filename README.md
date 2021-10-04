# FFPMEG-DOWNMIX

An ffmpeg-docker wrapper for a script to appropriately downmix surround-sound audio in a media file to stereo, and append it to the media file.  

The script requires a `workdir` folder to be mounted containing the input file. The output file is placed in the same directory.
If the output file (arg#2) is not specified, the input file will be deleted at the end of the script and the output file will replace it.

## Docker

### Scripts

Build the container:

    docker build --tag ffmpeg-downmix .

Run the script:

    docker run -v /ABSOLUTE/PATH/TO/WORKDIR:/workdir --rm ffmpeg-downmix INPUT_FILE [OUTPUT_FILE]

Where `/ABSOLUTE/PATH/TO/WORKDIR`, `INPUT_FILE` and `[OUTPUT_FILE]` need to be modified per your usage.
`OUTPUT_FILE` is optional. If specified, the input will remain untouched.
If no `OUTPUT_FILE` is specified, the input_file will be overwritten with the output file at the end of the script.
This second use is for automation cases where it is useful to replace the existing file.

### Example 1:

Input and output files specified.

The following example mounts the existing workdir folder in the repo, and downmixes the primary audio source in `input.mkv` to 
a stereo source. It will **append** it to a new version of the file, `output.mkv`, as the new **default** source at **a:0**.
The original sources and subtitles will all be preserved:

    docker run -v C:\ffmpeg-downmix\workdir:/workdir --rm ffmpeg-downmix input.mkv output.mkv

The output `output.mkv` will be in the same `workdir` folder as the input file.

### Example 2: 

Only input file specified.

The following example mounts the existing workdir folder in the repo, and downmixes the primary audio source in `input.mkv` to 
a stereo source. It will **append** it to a new version of the file, `input_new.mkv`, as the new **default** source at **a:0**.
The script will then overwrite `input.mkv` with `input_new.mkv`.
The original sources and subtitles will all be preserved:

    docker run -v C:\ffmpeg-downmix\workdir:/workdir --rm ffmpeg-downmix input.mkv

All temporary files will be deleted.

## Mixing Ratios

The current mixing ratios in the script are as follows:

### 5.1 Surround

    FL = "0.5*FC + 0.707 * FL+0.707*BL + 0.5*LFE"
    FR = "0.5*FC + 0.707*FR + 0.707*BR + 0.5*LFE"

### 5.1(side) Surround

    FL = "0.5*FC + 0.707*FL + 0.707*SL + 0.5*LFE"
    FR = "0.5*FC + 0.707*FR + 0.707*SR + 0.5*LFE"

### 6.1 Surround

    FL = "0.321953*FC + 0.455310*FL + 0.394310*SL + 0.227655*SR + 278819*BC + 0.321953*LFE"
    FR = "0.321953*FC + 0.455310*FR + 0.394310*SR + 0.227655*SL + 278819*BC + 0.321953*LFE"

### 7.1 Surround

    FL = "0.274804*FC + 0.388631*FL + 0.336565*SL + 0.194316*SR + 0.336565*BL + 0.194316*BR + 0.274804*LFE"
    FR = "0.274804*FC + 0.388631*FR + 0.336565*SR + 0.194316*SL + 0.336565*BR + 0.194316*BL + 0.274804*LFE"

These can be adjusted in `downmix.sh` before building the container.

## Sources

The script uses some of the mixing ratios suggested in the discussion:
https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg