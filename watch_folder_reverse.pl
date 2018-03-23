#!/usr/bin/perl
# korolev-ia [at] yandex.ru

$version="1.3 20180209";

use File::Which;   
use Getopt::Long;
use File::Path qw(make_path);
use File::Spec;
use Cwd;
use File::Basename;

#$widthDef=1080;
#$heightDef=1080;
$widthDef=800;
$heightDef=800;
$blend=0.2;
$similarity=0.3;
$colorkey="0x3BBD1E";
$video_extensions="avi|mkv|mov|mp4";
$image_extensions="png|jpg|jpeg|tif|tiff|bmp";

$basedir  = dirname($0);
chdir( $basedir );
$curdir = getcwd();

$defIn=File::Spec->catdir( $curdir, "IN" );
$defOut=File::Spec->catdir( $curdir, "OUT" );
$defBackup=File::Spec->catdir( $curdir, "BACKUP" );
$defImageOverlay=File::Spec->catfile( $curdir , "IMAGES", "overlay.png" );
$defFfmpeg=File::Spec->catfile( $curdir , "FFMPEG", "bin", "ffmpeg.exe" );
$once=0;

GetOptions (
        'in=s' => \$in,
        'out=s' => \$out,
        'backup=s' => \$backup,
        'imageoverlay=s' => \$imageoverlay,
        'ffmpeg=s' => \$ffmpeg,
        'mkdir|m' => \$mkdir,
        'once' => \$once,
        "help|h|?"  => \$help ) ;

$in=( $in ) ? $in : $defIn;		
$out=( $out ) ? $out : $defOut;		
$backup=( $backup ) ? $backup : $defBackup;	
$imageoverlay=( $imageoverlay ) ? $imageoverlay : $defImageOverlay;	
$ffmpeg=( $ffmpeg ) ? $ffmpeg : $defFfmpeg;				
			
			
show_help( ) if( $help )	;


unless( $ffmpeg ) {
	$ffmpeg=which 'ffmpeg';
}

print "Will use ffmpeg binary: '$ffmpeg'\n";

if( ! -f "$ffmpeg" ){
	show_help( 'Please, set the path to ffmpeg in enviroment or use option --ffmpeg ');
}

if( ! $imageoverlay ){
	show_help( 'Please, set the imageoverlay file with option --imageoverlay ');
}
if( ! -f "$imageoverlay" ){
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

$tmpdir="$backup/tmp" ;
if( ! -d $tmpdir ) {
	make_path( $tmpdir ) or die( "Cannot make backup directory '$tmpdir': $!" );
}



my ($volume,$directories,$file) = File::Spec->splitpath( $ffmpeg );
$ffprobe= File::Spec->catpath( $volume,$directories, 'ffprobe.exe' );

if( ! -f $ffprobe ){
	print STDERR  "Cannot found the '$ffprobe' file. Cannot continue processing.\n";
}

# infinity loop
while( 1 ) {
	opendir(DIR, $in) or die( "can't opendir $in: $!" );
		@ls = reverse sort grep { /\.($video_extensions)$/i && -f "$in/$_" } readdir(DIR);
	closedir DIR;

	$loop='';
	if( $imageoverlay =~/\.($image_extensions)$/i ) {
		$loop=' -loop 1 ';
	}

	if( 0==@ls ) {
		print "Do not found any video files in folder '$in'.\n" ;
		if( $once ) {
			print "Press ENTER to exit:";
			<STDIN>;	
			exit(0);
		}
		print "Sleep 10 sec.\n" ;
		sleep( 10 );		
	}

	foreach $fileName ( @ls ) {

		$videoIn=File::Spec->catfile( $backup, $fileName);	
		$videoOut=File::Spec->catfile( $tmpdir, $fileName);
		$origVideoIn=File::Spec->catfile( $in, $fileName );
		$origVideoOut=File::Spec->catfile( $out, $fileName );
		print getDate()." Start processing file '$origVideoIn'.\n" ;
		
		unless( rename( $origVideoIn, $videoIn ) ) {
			print STDERR "Cannot move file '$origVideoIn' to '$videoIn': $!. Cannot processing file $fileName\n" ;
			next;
		}


		$cmd="$ffprobe -v error -show_streams -of default=noprint_wrappers=1 \"$videoIn\"";
		my $streams_info=qx/ $cmd /;
		$streams_info=~/\s+duration=(\d*\.\d+)/;
		my $duration=$1;
		$streams_info=~/\s+width=(\d+)/;
		my $width=$1;
		$streams_info=~/\s+height=(\d+)/;
		my $height=$1;

		unless( $duration ) {
			print STDERR "Cannot get duration of file '$videoIn': $!. Cannot processing file $fileName\n" ;
			next;
		}
		if( !$width ) {
			print STDERR "Cannot get width of file '$videoIn': $!. Cannot processing file $fileName\n" ;
			next;
		}
		if( !$height ) {
			print STDERR "Cannot get height of file '$videoIn': $!. Cannot processing file $fileName\n" ;
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

		$image_scale="null";
		if( $height!=$heightDef ) {
			if( $height< $width) {
				$scale="scale=w=-2:h=$heightDef";
			} else {
				$scale="scale=h=-2:w=$widthDef";
			}
		}			
		

		#$cmd="$ffmpeg -y -loglevel error -i \"$videoIn\" -i \"$imageoverlay\" $loop -ss 0 -t $duration -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef} [0v]; [0v][1:v]overlay[out]\" -map \"[out]\" -map \"0:a?\" -crf 23 -f mp4 -c:a aac -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
		#$cmd="$ffmpeg -y -loglevel error -i \"$videoIn\" -i \"$imageoverlay\"  $loop -ss 0 -t $duration  -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef} [0v1]; [0v1] reverse [0v2]; [0v1][0v2] concat=n=2:v=1:a=0 [0v]; [0v][1:v]overlay[out]\" -map \"[out]\"  -crf 23 -f mp4 -an  -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
		#[0:v] null , crop=w=1080:h=1080 [vv1]; [vv1] split [sv1][sv2]; [sv1] reverse [vv2]; [sv2][vv2] concat=n=2:v=1:a=0 [vv3]; [vv3][1:v]overlay[out] 

		#$cmd="$ffmpeg -y -loglevel error -i \"$videoIn\" -i \"$imageoverlay\"  -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef} [vv1]; [vv1] split [sv1][sv2]; [sv1] reverse [vv2]; [sv2][vv2] concat=n=2:v=1:a=0 [vv3]; [vv3][1:v]overlay[out]\" -map \"[out]\"  -crf 23 -f mp4 -an  -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
		#$cmd="$ffmpeg -y -loglevel error -i \"$videoIn\" -i \"$imageoverlay\"  -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef}, split [sv1][sv2]; [sv1] reverse [vv2]; [sv2][vv2] concat=n=2:v=1:a=0 [vv3]; [vv3][1:v]overlay[out]\" -map \"[out]\"  -crf 23 -f mp4 -an  -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
		#$cmd="$ffmpeg -y -loglevel error -i \"$videoIn\" -i \"$imageoverlay\"  -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef}[vv0]; [vv0][1:v]overlay, split [sv1][sv2]; [sv1] reverse [vv2]; [sv2][vv2] concat=n=2:v=1:a=0 [out]\" -map \"[out]\"  -crf 28 -preset slow  -f mp4 -an  -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
		$cmd="$ffmpeg -y -loglevel error -i \"$videoIn\" -i \"$imageoverlay\"  -filter_complex  \"[0:v] $scale , crop=w=${widthDef}:h=${heightDef}[vv0]; [1:v] scale=w=$widthDef:h=$heightDef [vv1]; [vv0][vv1]overlay, split [sv1][sv2]; [sv1] reverse [vv2]; [sv2][vv2] concat=n=2:v=1:a=0 [out]\" -map \"[out]\"  -crf 25 -f mp4 -an  -c:v libx264  -pix_fmt yuv420p \"$videoOut\"  \n";
		my $ret=system( $cmd );
		if( 0==system( $cmd ) ) {
			unless( rename( $videoOut, $origVideoOut ) ) {
				print STDERR "Cannot move file '$videoOut' to '$origVideoOut': $!\n" ;
				next;
			}	
			
			print getDate()." # Processing of file $fileName finished with success. Out file: '$origVideoOut'\n" ;
			next;
		} 
		print STDERR getDate()." # Processing of file $fileName finished with errors: $!\n" ;
		print $cmd;
	}
	if( $once ) {
		print "Press ENTER to exit:";
		<STDIN>;	
		exit(0);
	}	
}

#print "Press ENTER to exit:";
#<STDIN>;
#exit(0);

sub getDate {
	my $time=shift() || time();
	my $format=shift || "%s-%.2i-%.2i %.2i:%.2i:%.2i";
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
	$year+=1900;$mon++;
    return sprintf( $format,$year,$mon,$mday,$hour,$min,$sec);
}	


sub show_help {
		my $msg=shift;
        print STDERR ("##	$msg\n\n") if( $msg);
        print STDERR ("Version $version
This script take the video files in IN folder, move to folder BACKUP, processing with ffmpeg and save transcoded video to folder OUT
Effect: reverse video file and concatenate forward and reverse videos to one
Usage: $0 [--in=IN] [--out=OUT] [--backup=BACKUP] [--imageoverlay=imageoverlay] [--ffmpeg=FFMPEG] [--once] [--help]
Where:
	--in=IN - watch new videos in this folder
	--out=OUT - save transcoded videos into this folder
	--backup=BACKUP - save original videos to this folder
	--imageoverlay=IMAGE_OVERLAY - transparent image overlay  
	--ffmpeg=FFMPEG - path to ffmpeg
	--mkdir - make OUT and BACKUP directories if do not exist
	--once - run script one time ( by default script run in the infinity loop )
	--help - this help
Sample:	${0} --in=\"c:/temp/video\" --out=\"c:/temp/video/out\" --backup=\"c:/temp/video/backup\" --imageoverlay=\"c:/TEMP/video/bg/bg.png\" --mkdir  --ffmpeg=\"c:/tools/ffmpeg/bin/ffmpeg.exe\" --mkdir
");
	print "Press ENTER to exit:";
	<STDIN>;
	exit (1);
}

