# Powershell script to automate downloading and encoding of a part of youtube video using youtube-dl and ffmpeg
# Usage:
# -Copy youtube video URL into clipboard
# -Run script
# -Specify time range and other options if needed
# -Press Enter
#
# To run the script use:
# PowerShell.exe -ExecutionPolicy Bypass -Command "& './cmd.ps1'"


# This provides default value inside user input
function Read-HostDefault([object]$Prompt, [object]$Default)
{
	[void][System.Windows.Forms.SendKeys]
	[System.Windows.Forms.SendKeys]::SendWait(([regex]'([\{\}\[\]\(\)\+\^\%\~])').Replace($Default, '{$1}'))

	$res = Read-Host -Prompt $Prompt

	trap 
	{
		[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
		continue
	}
	
	return $res
}

#param ($src, $out, $tm, $vrate)
 
$src = ""
$out = ""
$tm = ""
$urls = ""
$db = ""
$vr = "400k"
$scl = "720"
#$ccd = "libvpx-vp9"
$ccd = "libx264"
$opt="s" 

while ( "$opt" -ne "q" )
{ 
	# INIT INPUT YOUTUBE URL
	if ( "$opt" -eq "s" ){
		$src = Get-Clipboard 
		echo $src
		
		$out = youtube-dl -s --encoding utf-16 --get-title $src 
		#$out = "$out.webm" 
		
		$tm = $(youtube-dl -s --get-duration $src)
		$tm = "0:00 $tm"
		#$t = $tm -split ' '
		
		$urls = $(youtube-dl -g -f bestvideo+bestaudio $src)
		$url = $urls -split ' '
		
		# normalize volume
		$mv = $(ffmpeg -ss 0:00 -to 0:10 -i $url[1] -vn -af volumedetect -f null NULL 2>&1)				# ffmpeg get volume
		$mv = echo $mv | select-string "mean_volume"													# find  'mean_volume' value(dB)
		$mv = ($mv -split ': ')[1]
		$mv = ($mv -split ' ')[0]
		echo $mv
		$db = [float]::Parse($mv)
		$db = -$db * 0.5																				# tweak volume somehow
		$opt = "t"
	}
	
	# PRINT MENU KEYS AND VARIABlES
	clear		
	echo "[s] Input: $src"
	echo "[d] Output: $out"
	echo "[c] Codec: $ccd"
	echo "[v] VRate: $vr" 
	echo "[t] Time range: $tm"
	echo "[x] Scale: $scl"
	echo "[p] Preview"
	echo "[q] Quit"	
	
	# LET USER TO CHOOSE A MENU
	if ( "$opt" -eq "" ){		
		echo "Enter:"
		$opt = $Host.UI.RawUI.ReadKey().Character
		  
		if ( $opt -eq 13 ){ $opt = "e"; }
	}
	
	# READ USER INPUT
	if ( "$opt" -eq "t" ) {	$tm = Read-HostDefault "Time range"	$tm }	
	if ( "$opt" -eq "x" ) {	$scl = Read-HostDefault "Scale" $scl }	
	if ( "$opt" -eq "v" ) {	$vr = Read-HostDefault "Vrate" $vr }
	if ( "$opt" -eq "d" ) { $out = Read-HostDefault "Output" $out }
	if ( "$opt" -eq "c" ) { $ccd = if ($ccd -eq "libvpx-vp9") { "libx264" } else {"libvpx-vp9"}}
	
	# ENCODE PREVIEW
	if ( "$opt" -eq "p" ){		
		$t = $tm -split ' '
				
		ffmpeg -y -ss $t[0] -to $t[1] -i $url[0] -ss $t[0] -to $t[1] -i $url[1] -c:v libx264 -preset ultrafast -vf "scale=-2:$scl" -af "volume= $db dB" "$out.mp4";
		start "$out.mp4"
		#pause
	}
	
	# ENCODE FINAL
	if ( "$opt" -eq "e" ){	
		$t = $tm -split ' '		
		
		if ( "$ccd" -eq "libvpx-vp9"){
	
			ffmpeg -y -ss $t[0] -to $t[1] -i $url[0] -ss $t[0] -to $t[1] -i $url[1] -c:v libvpx-vp9 -b:v $vr -vf "scale=-2:$scl" -an -f webm -pass 1 NULL;
			ffmpeg -y -ss $t[0] -to $t[1] -i $url[0] -ss $t[0] -to $t[1] -i $url[1] -c:v libvpx-vp9 -b:v $vr -vf "scale=-2:$scl" -af "volume= $db dB" -pass 2 "$out.webm";
			start "$out.webm"
		}
		else
		{
			ffmpeg -y -ss $t[0] -to $t[1] -i $url[0] -ss $t[0] -to $t[1] -i $url[1] -c:v libx264 -preset veryslow -vf "scale=-2:$scl" -an -f mp4 -pass 1 NULL;
			ffmpeg -y -ss $t[0] -to $t[1] -i $url[0] -ss $t[0] -to $t[1] -i $url[1] -c:v libx264 -preset veryslow -vf "scale=-2:$scl" -c:a aac -b:a 128k -af "volume= $db dB" "$out.mp4";
			start "$out.mp4"
		}
		#pause
	}
	
	if ( "$opt" -eq "q" ){ exit }	
	$opt = ""
	
}

echo "Done."