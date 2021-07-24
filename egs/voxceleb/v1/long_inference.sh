#!/bin/bash
# Copyright   2017   Johns Hopkins University (Author: Daniel Garcia-Romero)
#             2017   Johns Hopkins University (Author: Daniel Povey)
#        2017-2018   David Snyder
#             2018   Ewald Enzinger
# Apache 2.0.
#
# See ../README.txt for more info on data required.
# Results (mostly equal error-rates) are inline in comments below.

. ./cmd.sh
. ./path.sh
set -e

job_name=tmp
infile=$1

featmode='mfcc'
root=/workspace/voxceleb/kaldi/voxceleb/
#root=$PWD
data=$root/data
exp=$root/exp
mfccdir=$root/mfcc
plpdir=$root/plp
fbankdir=$root/fbank
vaddir=$root/mfcc


nnet_dir=$root/exp/xvector_nnet_tdnn_amsoftmax_m0.20_linear_bn_1e-2
libritts_root=/workspace/datasets/raw_libri/ls_clean/

#TODO
stage=1
#out_mode='spk' # 'utt' 'spk' 'single_spk'
out_mode='utt' # 'utt' 'spk' 'single_spk'

if [ $stage -le 1 ]; then
  #TODO: both name and shell code
  # REQUIREMENT:
  # 0. obey chinese folder architecture: Wave folder
  # 1. speaker id is number
  # 2. foldername is spkid, wav name is spkid_uttid, this is for prepareforlibritts
  # 3. ids should be padded with same length

  rm -rf $data/$job_name
  local/data_prep_one.sh "$infile" $data/$job_name
  # exit
fi

#TODO
libritts_datasets=($job_name)

#TODO
#nj=40 # should be less than num of speakers
nj=1

if [ $stage -le 2 ]; then
  if [ $featmode == 'plp' ]; then
    # Make PLPs
    for name in ${libritts_datasets[@]}; do
      steps/make_plp.sh --write-utt2num-frames true --plp-config conf/plp.conf --nj $nj --cmd "$train_cmd" \
        $data/${name} $exp/make_plp_${name} ${plpdir}_${name}
      utils/fix_data_dir.sh $data/${name}
    done
  elif [ $featmode == 'fbank' ]; then
    # Make FBank
    for name in ${libritts_datasets[@]}; do
      steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank.conf --nj $nj --cmd "$train_cmd" \
        $data/${name} $exp/make_fbank_${name} ${fbankdir}_${name}
      utils/fix_data_dir.sh $data/${name}
    done
  else
    # Make MFCCs
    for name in ${libritts_datasets[@]}; do
      steps/make_mfcc.sh --write-utt2num-frames true --mfcc-config conf/mfcc.conf --nj $nj --cmd "$train_cmd" \
        $data/${name} $exp/make_mfcc_${name} ${mfccdir}_${name}
      utils/fix_data_dir.sh $data/${name}
    done
  fi
  for name in ${libritts_datasets[@]}; do
    sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" \
      $data/${name} $exp/make_vad_${name} ${vaddir}_${name}
    utils/fix_data_dir.sh $data/${name}
  done
  #exit
fi

# Tensorflow version
checkpoint='last'
if [ $stage -le 3 ]; then
  # Extract the embeddings
  for name in ${libritts_datasets[@]}; do
      nnet/run_extract_embeddings.sh --cmd "$train_cmd" --nj $nj --use-gpu false --checkpoint $checkpoint --stage 0 \
        --chunk-size 700 --normalize false --node "tdnn6_dense" \
        $nnet_dir $data/${name} \
        $nnet_dir/xvectors_${name}
  done
  #exit
fi

if [ $stage -le 4 ]; then
  # Compute the mean vector for centering the evaluation xvectors.
  # mean for all xvector
  $train_cmd $nnet_dir/xvectors_${libritts_datasets[0]}/log/compute_mean.log \
     ivector-mean scp:$nnet_dir/xvectors_${libritts_datasets[0]}/xvector.scp \
     $nnet_dir/xvectors_${libritts_datasets[0]}/mean.vec || exit 1;
fi

if [ $stage -le 5 ]; then
  #train_dir=${libritts_datasets[0]}
  train_dir=libritts_train
  #transformed_name="transformed_xvector.ark"
  #train_dir=train
  for name in ${libritts_datasets[@]}; do
    #$train_cmd exp/produce_transformed_xvector/log/ivector_plda_applying.log \
    echo ivector-plda-applying --normalize-length=true \
      "ivector-copy-plda --smoothing=0.0 $nnet_dir/xvectors_${train_dir}/plda - |" \
      "ark:ivector-subtract-global-mean $nnet_dir/xvectors_${train_dir}/mean.vec scp:$nnet_dir/xvectors_${name}/xvector.scp ark:- | transform-vec $nnet_dir/xvectors_${train_dir}/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
      "ark:$nnet_dir/xvectors_${name}/transformed_xvector.ark" || exit 1;

    if [ $out_mode == 'utt' ]; then
      transformed_name="transformed_xvector.ark"
      ivector-plda-applying --normalize-length=true \
        "ivector-copy-plda --smoothing=0.0 $nnet_dir/xvectors_${train_dir}/plda - |" \
        "ark:ivector-subtract-global-mean $nnet_dir/xvectors_${train_dir}/mean.vec scp:$nnet_dir/xvectors_${name}/xvector.scp ark:- | transform-vec $nnet_dir/xvectors_${train_dir}/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "ark:$nnet_dir/xvectors_${name}/${transformed_name}" || exit 1;

    elif [ $out_mode == 'spk' ]; then
      # spk mean
      transformed_name="transformed_spk_xvector.ark"
      ivector-plda-applying --normalize-length=true \
        "ivector-copy-plda --smoothing=0.0 $nnet_dir/xvectors_${train_dir}/plda - |" \
        "ark:ivector-subtract-global-mean $nnet_dir/xvectors_${train_dir}/mean.vec scp:$nnet_dir/xvectors_${name}/spk_xvector.scp ark:- | transform-vec $nnet_dir/xvectors_${train_dir}/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "ark:$nnet_dir/xvectors_${name}/${transformed_name}" || exit 1;

    elif [ $out_mode == 'single_spk' ]; then
      # single spk mean, need write customized text mean.ark
      transformed_name="transformed_single_spk_xvector.ark"
      ivector-plda-applying --normalize-length=true \
        "ivector-copy-plda --smoothing=0.0 $nnet_dir/xvectors_${train_dir}/plda - |" \
        "ark:ivector-subtract-global-mean $nnet_dir/xvectors_${train_dir}/mean.vec ark,t:$nnet_dir/xvectors_${name}/mean.ark ark:- | transform-vec $nnet_dir/xvectors_${train_dir}/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
        "ark:$nnet_dir/xvectors_${name}/${transformed_name}"
    fi

    echo run python
    #TODO
    echo python local/prepare_for_libritts.py -i $nnet_dir/xvectors_${name}/${transformed_name} -o ${name}_spkids
    python local/prepare_for_libritts.py -i $nnet_dir/xvectors_${name}/${transformed_name} -o ${name}_spkids
  done
  exit
fi
