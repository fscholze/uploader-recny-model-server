#!/bin/bash

FOLDERNAME=$1
SOURCEFILE=$2
MODEL=$3
OUTFORMAT=srt
PROGRESS=$4
TRANSLATE=$5 
DIARIZATION=$6 
VAD=$7

echo "========================== Transcript whisper ======================"
echo "Dataja=$SOURCEFILE"
echo "Postup=$PROGRESS"
echo "Rjadowak=$FOLDERNAME"
echo "Model=$MODEL"
echo "Format=$OUTFORMAT (ignored)"
echo "Translate=$TRANSLATE"
echo "DiarizeSpeakers=$DIARIZATION"
echo "VAD=$VAD"

OUTFILENAMENOEXT="${SOURCEFILE%.*}"
CWD=$(pwd)
echo "Output filename w/o ext: $OUTFILENAMENOEXT"
echo "CWD: $CWD"

echo "SOTRA_URL=$SOTRA_URL"
echo "HF_TOKEN=$HF_TOKEN"

# video --> audio
echo "0|Wobdźěłam $SOURCEFILE" >> $PROGRESS
ffmpeg -i $SOURCEFILE $SOURCEFILE.wav
DURATION=$(soxi -D $SOURCEFILE.wav)
echo ${DURATION%.*} > $PROGRESS.tmp # strip the decimal part
cat $PROGRESS >> $PROGRESS.tmp
mv $PROGRESS.tmp $PROGRESS

# this model does not diarize

# VAD on
if [ "$VAD" = "true" ]; then
	
	sox $SOURCEFILE.wav -r 48000 -c 1 -b 16 $SOURCEFILE.wav.resample.wav
	echo "20|Resampling hotowe" >> $PROGRESS
	LD_LIBRARY_PATH=/opt/whisper_out/:/opt/onnxruntime-linux-x64-1.12.1/lib/:/opt/whisper.cpp/build/ggml/src/:/opt/whisper.cpp/build/src/:/opt/whisper.cpp/build/ggml/src/ggml-cuda/ \
	    /opt/whisper_out/whisper_main $MODEL $SOURCEFILE.wav.resample.wav ./uploads/${FOLDERNAME} > ./uploads/${FOLDERNAME}/log.txt 2>&1
	
	mv uploads/${FOLDERNAME}/subtitles.srt ${OUTFILENAMENOEXT}.srt
	mv uploads/${FOLDERNAME}/transcript.txt ${OUTFILENAMENOEXT}.txt
	
	if [ "$TRANSLATE" = "true" ]; then
		# run the .srt translation
		$(dirname $0)/translate_srt.sh ${CWD}/${OUTFILENAMENOEXT}.srt ${CWD}/${OUTFILENAMENOEXT}.de.srt hsb de $SOTRA_URL
		
		echo "100|Podtitle hotowe|1|1|0|1" >> $PROGRESS
	else
		# nothing more to do
		echo "100|Podtitle hotowe|1|1|0|0" >> $PROGRESS
	fi
	
# VAD off, only create transcript
else
	
	sox $SOURCEFILE.wav -r 16000 -c 1 -b 16 $SOURCEFILE.wav.resample.wav
	echo "20|Resampling hotowe" >> $PROGRESS
	
	LD_LIBRARY_PATH=/opt/whisper.cpp/build/bin:/opt/whisper.cpp/build/ggml/src/:/opt/whisper.cpp/build/src/:/opt/whisper.cpp/build/ggml/src/ggml-cuda/ \
	    /opt/whisper.cpp/build/bin/whisper-cli -m $MODEL --output-txt -f $SOURCEFILE.wav.resample.wav
	mv $SOURCEFILE.wav.resample.wav.txt ${OUTFILENAMENOEXT}.txt
	echo "100|Transkript hotowe|1|0|0|0" >> $PROGRESS
	
	# transcript will not be translated
fi
