#!/bin/bash
 
src=""
out=""
tm=""
urls=""
db=""
vr="400k"
scl="720"

opt="s" 

while [ "$opt" != "q" ]; do
		
	if [ "$opt" = "s" ]; then	
		src=$1 #(powershell.exe -command 'Get-Clipboard')
		echo "$src"
		
		out=$(youtube-dl -s --get-title $src)
		
		tm=$(youtube-dl -s --get-duration $src)
		tm="0:00 $tm"
		
		urls=$(youtube-dl -g -f bestvideo+bestaudio $src)		
		readarray -t url <<< "$urls" 
		
		# normalize volume
		mv=$(ffmpeg -ss ${t[0]} -to ${t[1]} -i ${url[1]} -vn -af volumedetect -f null NUL 2>&1)		# ffmpeg get volume
		mv=$(echo $mv | grep -o -E 'mean_volume: [-.0-9]+' | cut -d ' ' -f 2)						# find  'mean_volume' value(dB)
		db=$(bc -l <<< "-($mv) * 0.5")																# tweak volume 
				
		opt="t"
	fi
	
	#clear
		
	#echo "[s] Input: $src"
	echo "[d] Output: $out"
	echo "[v] VRate: $vr" 
	echo "[t] Time range: $tm"
	echo "[x] Scale: $scl"
	echo "[p] Preview"
	echo "[q] Quit"
	echo "Enter to encode"	
		
	if [ "$opt" = "" ]; then
		read -e -n 1 -p $"Enter:" opt
		if [ "$opt" = "" ]; then 
			opt="e"; 
		fi
	fi
	
	if [ "$opt" = "t" ]; then
		read -e -i "$tm" -p "Time range:" tm;
	fi
	
	if [ "$opt" = "x" ]; then
		read -e -i "$scl" -p "Scale:" scl;
	fi
	
	if [ "$opt" = "v" ]; then
		read -e -i "$vr" -p "Target vrate:" vr;
	fi

	if [ "$opt" = "d" ]; then
		read -e -i "$out" -p "Output:" out;		
	fi
	
	# ENCODE PREVIEW
	if [ "$opt" = "p" ]; then
		readarray -d ' ' t <<< "$tm"
		db=5
		ffmpeg -y -ss ${t[0]} -to ${t[1]} -i ${url[0]} -ss ${t[0]} -to ${t[1]} -i ${url[1]} -c:v libx264 -preset ultrafast -vf "scale=-2:$scl" -af "volume=$dbdB" "preview.mp4";
		cmd.exe /C start preview.mp4
		read -e -p "OK";
	fi
	
	# ENCODE FINAL
	if [ "$opt" = "e" ]; then
	
		readarray -d ' ' t <<< "$tm"		
	
		ffmpeg -y -ss ${t[0]} -to ${t[1]} -i ${url[0]} -ss ${t[0]} -to ${t[1]} -i ${url[1]} -c:v libvpx-vp9 -b:v $vr -vf "scale=-2:$scl" -af "volume=$dbdB" -f null -pass 1 /dev/null;
		ffmpeg -y -ss ${t[0]} -to ${t[1]} -i ${url[0]} -ss ${t[0]} -to ${t[1]} -i ${url[1]} -c:v libvpx-vp9 -b:v $vr -vf "scale=-2:$scl" -af "volume=$dbdB" -pass 2 "'"$out.webm'"";
	fi
	
	if [ "$opt" = "q" ]; then
		exit
	fi
	
	opt=""
	
done
echo "Done."
