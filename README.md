#						Watch videos in the folder, and processing with specified effects


##  What is it?
##  -----------
This script/application watching the specified folder, and when found new videos start ffmpeg processing video effects ( overlay, logo, reverse,etc ).


	

##  Documentation
##  -------------


##  Features
##  ------------
Now available 2 scripts with effects :

	+	watch_folder_reverse.pl - cut original viddeo to square, video play in direct and after end, in the reverse direction
	+	watch_folder_overlay.pl - cut original viddeo to square, overlay with transparent image


##  Installation
##  ------------
Please, install ffmpeg ( `https://ffmpeg.zeranoe.com/builds/` ) and perl ( `https://www.activestate.com/activeperl` or `http://strawberryperl.com/` ).


##	Usage:
##
```
Usage: perl watch_folder_reverse.pl [--in=IN] [--out=OUT] [--backup=BACKUP] [--imageoverlay=imageoverlay] [--ffmpeg=FFMPEG] [--once] [--help]
Where:
        --in=IN - watch new videos in this folder
        --out=OUT - save transcoded videos into this folder
        --backup=BACKUP - save original videos to this folder
        --imageoverlay=IMAGE_OVERLAY - transparent image overlay
        --ffmpeg=FFMPEG - path to ffmpeg
        --mkdir - make OUT and BACKUP directories if do not exist
        --once - run script one time ( by default script run in the infinity loop )
        --help - this help
Sample: perl watch_folder_reverse.pl --in="c:/temp/video" --out="c:/temp/video/out" --backup="c:/temp/video/backup" --imageoverlay="c:/TEMP/video/bg/bg.png" --mkdir  --ffmpeg="c:/tools/ffmpeg/bin/ffmpeg.exe" --mkdir
```
#######################
```
Usage: perl watch_folder_overlay.pl [--in=IN] [--out=OUT] [--backup=BACKUP] [--imageoverlay=imageoverlay] [--ffmpeg=FFMPEG] [
--once] [--help]
Where:
        --in=IN - watch new videos in this folder
        --out=OUT - save transcoded videos into this folder
        --backup=BACKUP - save original videos to this folder
        --imageoverlay=IMAGE_OVERLAY - transparent image overlay
        --ffmpeg=FFMPEG - path to ffmpeg
        --mkdir - make OUT and BACKUP directories if do not exist
        --once - run script one time ( by default script run in the infinity loop )
        --help - this help
Sample: perl watch_folder_overlay.pl --in="c:/temp/video" --out="c:/temp/video/out" --backup="c:/temp/video/backup" --imageoverlay="c:/TEMP/video/bg/bg.png" --mkdir  --ffmpeg="c:/tools/ffmpeg/bin/ffmpeg.exe" --mkdir
```




##  Bugs
##  ------------



  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

