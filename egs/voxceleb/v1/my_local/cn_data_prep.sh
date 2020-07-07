#!/bin/bash

# Copyright 2014  Vassil Panayotov
#           2014  Johns Hopkins University (author: Daniel Povey)
# Apache 2.0

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <src-dir> <dst-dir>"
  echo "e.g.: $0 /export/a15/vpanayotov/data/LibriSpeech/dev-clean data/dev-clean"
  exit 1
fi

src=$1
dst=$2

mkdir -p $dst || exit 1;

[ ! -d $src ] && echo "$0: no such directory $src" && exit 1;


wav_scp=$dst/wav.scp; [[ -f "$wav_scp" ]] && rm $wav_scp
#trans=$dst/text; [[ -f "$trans" ]] && rm $trans
utt2spk=$dst/utt2spk; [[ -f "$utt2spk" ]] && rm $utt2spk
#spk2gender=$dst/spk2gender; [[ -f $spk2gender ]] && rm $spk2gender

for reader_dir in $(find -L $src -mindepth 1 -maxdepth 1 -type d | sort); do
  reader=$(basename $reader_dir)
  #reader=${reader:1} # vctk
  #reader='1'

  ##aishell2
  #reader=$(echo $reader | sed -e 's/C/0/g')
  #reader=$(echo $reader | sed -e 's/D/1/g')

  if ! [ $reader -eq $reader ]; then  # not integer.
    echo "$0: unexpected subdirectory name $reader"
    continue
    #exit 1;
  fi
  # TODO CHANGE! auto
  # basename filename remove_ext
  # flac -c(stdout) -d(decode) -s(silent) input
  find -L $reader_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
    awk -v "dir=$reader_dir" '{printf "%s sox %s/Wave/%s.wav -r 16000 -b 16 -t wav - |\n", $0, dir, $0}' >>$wav_scp|| exit 1
    # awk -v "dir=$reader_dir" '{printf "%s sox %s/Wave/%s.wav -r 16000 -b 16 -t wav - |\n", substr($0,3), dir, $0}' >>$wav_scp|| exit 1
    # awk -v "dir=$reader_dir" -v "reader=$reader" '{printf "%03d_%03d sox %s/Wave/%s.wav -r 16000 -t wav - |\n", reader, $0, dir, $0}' >>$wav_scp|| exit 1 #vb

  find -L $reader_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
    awk -v "reader=$reader" '{printf "%s %s\n", $0, reader}' >>$utt2spk || exit 1
    #awk -v "reader=$reader" '{printf "%s %s\n", substr($0,3), reader}' >>$utt2spk || exit 1
    # awk -v "reader=$reader" '{printf "%03d_%03d %03d\n", reader, $0, reader}' >>$utt2spk || exit 1 #vb

  #if [[ ${reader:0:1} != "S" && ${reader:0:1} != "T" ]]; then  # not speaker.
  #  echo "$0: unexpected subdirectory name $reader"
  #  continue
  #fi
  #find -L $reader_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
  #  awk -v "reader=$reader" -v "dir=$reader_dir" '{printf "%s_%s sox %s/%s.wav -r 16000 -b 16 -t wav - |\n", reader, $0, dir, $0}' >>$wav_scp|| exit 1
  #find -L $reader_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
  #  awk -v "reader=$reader" '{printf "%s_%s %s\n", reader, $0, reader}' >>$utt2spk || exit 1

done

spk2utt=$dst/spk2utt
utils/utt2spk_to_spk2utt.pl <$utt2spk >$spk2utt || exit 1

#ntrans=$(wc -l <$trans)
#nutt2spk=$(wc -l <$utt2spk)
#! [ "$ntrans" -eq "$nutt2spk" ] && \
#  echo "Inconsistent #transcripts($ntrans) and #utt2spk($nutt2spk)" && exit 1;

utils/fix_data_dir.sh $dst
utils/validate_data_dir.sh --no-feats --no-text $dst || exit 1;

echo "$0: successfully prepared data in $dst"

exit 0
