#!/bin/bash

FOLDERNAME=$1
SOURCEFILE=$2
MODEL=$3
OUTFORMAT=srt
PROGRESS=$4
TRANSLATE=$5 
DIARIZATION=$6 
VAD=$7


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

touch $PROGRESS

# list all currently used models here

# RECIKTS_MODEL_BOZA_MSA=misa_2024_08_02.cfg
RECIKTS_MODEL_BOZA_MSA=merged_47_nnet_v4_trns_118_wordpc_misa.cfg
WHISPER_MODEL_HSB_BIG=/usr/app/src/whisper/Korla/whisper_large_v3_turbo_hsb-v1/ggml-model.bin
WHISPER_MODEL_DSB_BIG=/usr/app/src/whisper/Korla/whisper_large_v3_turbo_dsb/ggml-model.bin
WHISPER_MODEL_GERMAN=large-v2

case $MODEL in

#	HFHSB)
#		$(dirname $0)/transcript_whisper.sh $FOLDERNAME $SOURCEFILE $WHISPER_MODEL_HSB $PROGRESS $TRANSLATE $DIARIZATION $VAD
#		;;
	
	HFHSBBIG)
		$(dirname $0)/transcript_whisper.sh $FOLDERNAME $SOURCEFILE $WHISPER_MODEL_HSB_BIG $PROGRESS $TRANSLATE $DIARIZATION $VAD
		;;
	
	HFDSB)
		$(dirname $0)/transcript_whisper.sh $FOLDERNAME $SOURCEFILE $WHISPER_MODEL_DSB_BIG $PROGRESS $TRANSLATE $DIARIZATION $VAD
		;;
	
	BOZA_MSA)
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
			LD_LIBRARY_PATH=/usr/app/src/proprietary:/opt/onnxruntime-linux-x64-1.12.1/lib/ /opt/recikts_out/recikts_main /usr/app/src/proprietary/$RECIKTS_MODEL_BOZA_MSA $SOURCEFILE.wav.resample.wav ./uploads/${FOLDERNAME} > ./uploads/${FOLDERNAME}/log.txt 2>&1
			echo "80|Spóznawanje hotowe" >> $PROGRESS
			
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
			
			
		# VAD off
		else
			
			sox $SOURCEFILE.wav -r 16000 -c 1 -b 16 $SOURCEFILE.wav.resample.wav
			echo "20|Resampling hotowe" >> $PROGRESS
			LD_LIBRARY_PATH=/usr/app/src/proprietary /usr/app/src/proprietary/testrec /usr/app/src/proprietary/$RECIKTS_MODEL_BOZA_MSA $SOURCEFILE.wav.resample.wav | tee $SOURCEFILE.wav.resample.wav.rec.log
			echo "80|Spóznawanje hotowe" >> $PROGRESS
			
			# need a venv with numpy for the processing scripts
			pushd /opt/venv/forcealign
			source bin/activate
			popd

			python3 $(dirname $0)/log2srt.py $SOURCEFILE.wav.resample.wav.rec.log
			mv uploads/${FOLDERNAME}/*.srt ${OUTFILENAMENOEXT}.srt

			python3 $(dirname $0)/log2txt.py $SOURCEFILE.wav.resample.wav.rec.log
			mv uploads/${FOLDERNAME}/*.rawtxt ${OUTFILENAMENOEXT}.txt
			
			if [ "$TRANSLATE" = "true" ]; then
				# run the .srt translation
				$(dirname $0)/translate_srt.sh ${CWD}/${OUTFILENAMENOEXT}.srt ${CWD}/${OUTFILENAMENOEXT}.de.srt hsb de $SOTRA_URL
				
				echo "100|Podtitle hotowe|1|1|0|1" >> $PROGRESS
			else
				# nothing more to do
				echo "100|Podtitle hotowe|1|1|0|0" >> $PROGRESS
			fi
			
			
		fi
		;;
		
	GERMAN)
		echo "0|Wobdźěłam $SOURCEFILE" >> $PROGRESS
		ffmpeg -i $SOURCEFILE $SOURCEFILE.wav
		DURATION=$(soxi -D $SOURCEFILE.wav)
		echo ${DURATION%.*} > $PROGRESS.tmp # strip the decimal part
		cat $PROGRESS >> $PROGRESS.tmp
		mv $PROGRESS.tmp $PROGRESS
		sox $SOURCEFILE.wav -r 48000 -c 1 -b 16 $SOURCEFILE.wav.resample.wav
		echo "20|Resampling hotowe" >> $PROGRESS
		
		pushd /opt/venv/ctranslate2
		source bin/activate
		
		# somehow this path needs to be specified manually
		export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/venv/ctranslate2/lib/python3.12/site-packages/nvidia/cublas/lib/
		echo $LD_LIBRARY_PATH

		if [ "$DIARIZATION" -gt 0 ]; then
			# with speaker diarization
			whisper-ctranslate2 --model $WHISPER_MODEL_GERMAN --output_dir /usr/app/src/uploads/${FOLDERNAME}/ --device cuda --hf_token $HF_TOKEN --language de /usr/app/src/$SOURCEFILE.wav.resample.wav > /usr/app/src/uploads/${FOLDERNAME}/log.log 2>&1
		else
			# no speaker diarization
			whisper-ctranslate2 --model $WHISPER_MODEL_GERMAN --output_dir /usr/app/src/uploads/${FOLDERNAME}/ --device cuda --language de /usr/app/src/$SOURCEFILE.wav.resample.wav > /usr/app/src/uploads/${FOLDERNAME}/log.log 2>&1
		fi
		popd

		ls -l /usr/app/src/uploads/${FOLDERNAME}/
		
		# TBD which filename?
		# mv ${SOURCEFILE%.*}*.txt $(echo "${SOURCEFILE%.*}".txt)
		mv $SOURCEFILE.wav.resample.txt ${OUTFILENAMENOEXT}.txt
		mv $SOURCEFILE.wav.resample.srt ${OUTFILENAMENOEXT}.de.srt
		echo "100|Transkript hotowe|1|0|0|1" >> $PROGRESS
		;;
		
	DEVEL)
		echo "0|Wobdźěłam $SOURCEFILE" >> $PROGRESS
		sleep 1
		DURATION="175"
		echo $DURATION > $PROGRESS.tmp
		cat $PROGRESS >> $PROGRESS.tmp
		mv $PROGRESS.tmp $PROGRESS
		cp $SOURCEFILE $SOURCEFILE.wav
		cp $SOURCEFILE.wav $SOURCEFILE.wav.resample.wav
		cp $SOURCEFILE $SOURCEFILE.wav.resample.wav.rec.log
		sleep 1
		echo "20|Resampling hotowe ($DURATION)" >> $PROGRESS
		cp $SOURCEFILE.wav.resample.wav $SOURCEFILE.wav.resample.wav.rec.log
		cp $SOURCEFILE.wav.resample.wav $SOURCEFILE.wav.resample.wav.rec.log
		sleep 5
		echo "80|Spóznawanje hotowe" >> $PROGRESS
		sleep 1
		cp $SOURCEFILE.wav.resample.wav.rec.log ${OUTFILENAMENOEXT}.txt
		echo "100|Podtitle hotowe|1|0|0|0" >> $PROGRESS
		;;

#	FB)
		#### currently unused ###############
#		if [ "$OUTFORMAT" = "text" ]; then
#			echo "0|Wobdźěłam $SOURCEFILE" >> $PROGRESS
#			ffmpeg -i $SOURCEFILE $SOURCEFILE.wav
#			DURATION=$(soxi -D $SOURCEFILE.wav)
#			echo ${DURATION%.*} > $PROGRESS.tmp # strip the decimal part
#			cat $PROGRESS >> $PROGRESS.tmp
#			mv $PROGRESS.tmp $PROGRESS
#			sox $SOURCEFILE.wav -r 16000 -c 1 -b 16 $SOURCEFILE.wav.resample.wav
#			echo "20|Resampling hotowe" >> $PROGRESS
#			echo "test test test" > $SOURCEFILE.trl.resample.trl
#			export USER=$FOLDERNAME
#			pushd /fairseq
#			source bin/activate
#			python /fairseq/examples/mms/asr/infer/mms_infer.py --model /fairseqdata/mms1b_all.pt  --lang hsb --audio /uploader-recny-model-server/$SOURCEFILE.wav.resample.wav --format letter > /uploader-recny-model-server/$SOURCEFILE.log
#			popd
#			echo "80|Spóznawanje hotowe" >> $PROGRESS
#			mv $SOURCEFILE.log ${SOURCEFILE}.${OUTFORMAT}
#			ln -s $(basename $SOURCEFILE.text) $(echo "${SOURCEFILE%.*}".text)
#			echo "100|Podtitle hotowe" >> $PROGRESS
#		else
#			echo "100|Tuta warianta hišće njeje přistupna!" >> $PROGRESS
#		fi
#		;;
	
	*)
		echo "100|Tuta warianta hišće njeje přistupna!" >> $PROGRESS
		;;
	
esac
