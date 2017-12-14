#!/usr/bin/perl
# korolev-ia [at] yandex.ru

use File::Which;   
use Getopt::Long;
use File::Path qw(make_path);
use File::Spec;


$widthDef=1080;
$heightDef=1080;
$blend=0.2;
$similarity=0.3;
$colorkey="0x3BBD1E";
$video_extensions="avi|mkv|mov|mp4";
$image_extensions="png|jpg|jpeg|tif|tiff|bmp";


GetOptions (
        'in=s' => \$in,
        'out=s' => \$out,
        'backup=s' => \$backup,
        'imageoverlay=s' => \$imageoverlay,
        'ffmpeg=s' => \$ffmpeg,
        'mkdir|m' => \$mkdir,
        "help|h|?"  => \$help ) or show_help();

show_help( 'Please set the --in folder' ) unless( $in )	;
show_help( 'Please set the --out folder' ) unless( $out  )	;
show_help( 'Please set the --backup folder' ) unless( $backup  )	;

unless( $ffmpeg ) {
	$ffmpeg=which 'ffmpeg';
}
if( ! -f $ffmpeg ){
	show_help( 'Please, set the path to ffmpeg in enviroment or use option --ffmpeg ');
}

if( ! $imageoverlay ){
	show_help( 'Please, set the imageoverlay file with option --imageoverlay ');
}
if( ! -f $imageoverlay ){
	show_help( "imageoverlay file '$imageoverlay' do not exist ");
}


if( ! -d $in ) {
	show_help( "Directory for input files '$in' do not exist");
}

if( ! -d $out ) {
	make_path( $out ) or die( "Cannot make output directory '$out': $!" );
}

if( ! -d $backup ) {
	make_path( $backup ) or die( "Cannot make backup directory '$backup': $!" );
}

my ($volume,$directories,$file) = File::Spec->splitpath( $ffmpeg );
$ffprobe= File::Spec->catpath( $volume,$directories, 'ffprobe.exe' );

if( ! -f $ffprobe ){
	print STDERR  "Cannot found the '$ffprobe' file. Cannot continue processing.";
}


opendir(DIR, $in) or die( "can't opendir $in: $!" );
    @ls = reverse sort grep { /\.($video_extensions)$/i && -f "$in/$_" } readdir(DIR);
closedir DIR;

$loop='';
if( $imageoverlay =~/\.($image_extensions)$/i ) {
	$loop=' -loop 1 ';
}

if( 0==@ls ) {
	print "Do not found any video files in folder '$in'." ;
	exit(0);
}

foreach $fileName ( @ls ) {


	$videoIn="$backup/$fileName";	
	$videoOut="$out/$fileName";
	unless( rename( "$in/$fileName", $videoIn ) ) {
		print STDERR "Cannot move file '$in/$fileName' to '$videoIn': $!. Cannot processing file $fileName" ;
		next;
	}
	$cmd="$ffprobe -v error -show_streams -of default=noprint_wrappers=1 $videoIn";
	my $streams_info=qx/ $cmd /;
	$streams_info=~/\s+duration=(\d*\.\d+)/;
	my $duration=$1;
	$streams_info=~/\s+width=(\d+)/;
	my $width=$1;
	$streams_info=~/\s+height=(\d+)/;
	my $height=$1;

	unless( $duration ) {
		print STDERR "Cannot get duration of file '$videoIn': $!. Cannot processing file $fileName" ;
		next;
	}
	if( !$width ) {
		print STDERR "Cannot get width of file '$videoIn': $!. Cannot processing file $fileName" ;
		next;
	}
	if( !$height ) {
		print STDERR "Cannot get height of file '$videoIn': $!. Cannot processing file $fileName" ;
		next;
	}
	$scale="null";
	if( $height!=$heightDef ) {
		if( $height< $width) {
			$scale="scale=w=-2:h=$heightDef";
		} else {
			$scale="scale=h=-2:w=$widthDef";
		}
	}	
	
	$cmd="$ffmpeg -y -loglevel warning -i \"$videoIn\" -i \"$imageoverlay\" $loop -ss 0 -t $duration -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef} [0v]; [0v][1:v]overlay[out]\" -map \"[out]\" -map \"0:a?\" -crf 23 -f mp4 -c:a aac -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
	#print $cmd;
	my $ret=system( $cmd );
	if( 0==system( $cmd ) ) {
		print "# Processing of file $fileName finished with success. Out file: '$videoOut'\n" ;
		next;
	} 
	print STDERR "# Processing of file $fileName finished with errors: $!\n" ;
	print $cmd;
}



sub show_help {
		my $msg=shift;
        print STDERR ("$msg
This script take the video files in IN folder, move to folder BACKUP, processing with ffmpeg and save transcoded video to folder OUT
Usage: $0 --in=IN --out=OUT --backup=BACKUP --imageoverlay=imageoverlay [--ffmpeg=FFMPEG] [--help]
Where:
	--in=IN - watch new videos in this folder
	--out=OUT - save transcoded videos into this folder
	--backup=BACKUP - save original videos to this folder
	--imageoverlay=IMAGE_OVERLAY - transparent image overlay  
	--ffmpeg=FFMPEG - path to ffmpeg
	--mkdir - make OUT and BACKUP directories if do not exist
	--help - this help
Sample:	${0} --in=\"c:/temp/video\" --out=\"c:/temp/video/out\" --backup=\"c:/temp/video/backup\" --imageoverlay=\"c:/TEMP/video/bg/bg.png\" --mkdir  --ffmpeg=\"c:/tools/ffmpeg/bin/ffmpeg.exe\" --mkdir
");
	exit (1);
}
