# Spóznawanje rěče - serwer

## Container twarić

```code
docker build -f docker/Dockerfile -t offline_transcription_back .
```

## Přidatne dataje wobstarać

Wotpowědne rjadowaki wutworić

```code
mkdir -p proprietary whisper fairseq
```

### proprietary

Spóznawanski system wot Fraunhofer bohužel njeje zjawne přistupne.

### whisper

#### model wobstarać a přihotować

```code
mkdir -p tmp && cd tmp

git clone git@github.com:ggerganov/whisper.cpp.git

git checkout v1.5.4

git clone https://huggingface.co/spaces/Korla/hsb_stt_demo

git clone https://github.com/openai/whisper

mkdir -p output/hsb/whisper_small

python3 ./models/convert-h5-to-ggml.py  ../hsb_stt_demo/hsb_whisper/ ../whisper/ output/hsb/whisper_small
```

#### model do rjadowaka kopěrować

```code
mkdir -p whisper/hsb/whisper_small/

cp tmp/output/hsb/whisper_small/* whisper/hsb/whisper_small/
```

## fairseq

```code
cd fairseq

wget https://dl.fbaipublicfiles.com/mms/asr/mms1b_all.pt
```

## Container wuwjesć

TBD

