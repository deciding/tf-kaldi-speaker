import os
import argparse

from kaldiio import ReadHelper
import numpy as np
from tqdm import tqdm

#python local/prepare_for_libritts.py -i exp/xvector_nnet_1a/xvectors_libritts_train/transformed_spk_xvector.ark -o ''

#python local/prepare_for_libritts.py -i exp/xvector_nnet_1a/xvectors_libritts_test/transformed_xvector.ark -o libritts_test_spkids
parser=argparse.ArgumentParser()
parser.add_argument('-i', '--input', help='input ark of transformed ivectors')
parser.add_argument('-o', '--output', help='the output dir for saving the spkids')
args=parser.parse_args()

input_ark=args.input
out_dir=args.output

# for libritts speaker-chapter architecture avg.npy
#libritts_spk_mean=True
#libritts_training_root='/home/zining/workspace/datasets/tts_training/training_libritts_wavernn_24k/'
#libritts_spkid_map={}
#if libritts_spk_mean:
#    with ReadHelper("ark:%s" % input_ark) as reader:
#        for key, spkid in tqdm(reader):
#            libritts_spkid_map[key]=spkid
#
#speaker_chapters=os.listdir(libritts_training_root)
#for speaker_chapter in tqdm(speaker_chapters):
#    speaker, chapter=speaker_chapter.split('-')
#    cur_dir="%s/%s" % (libritts_training_root, speaker_chapter)
#    cur_dir_spkids="%s/spkids" % cur_dir
#    os.makedirs(cur_dir_spkids, exist_ok=True)
#    np.save("%s/avg.npy" % cur_dir_spkids, libritts_spkid_map["%04d" % int(speaker)])
#exit()

if not os.path.exists(out_dir):
    os.makedirs(out_dir)
#indexed by speaker_chapter
with ReadHelper("ark:%s" % input_ark) as reader:
    for key, spkid in tqdm(reader):
        ## default spk_utt
        #spk, utt=key.split('_')
        #saving_dir="%s/%s" % (out_dir, spk)
        #if not os.path.exists(saving_dir):
        #    os.makedirs(saving_dir)
        ##np.save("%s/%s.npy" % (saving_dir, key), spkid)
        #np.save("%s/%s.npy" % (saving_dir, utt), spkid)

        # single speaker
        spk, utt='1', key
        saving_dir="%s/%s" % (out_dir, spk)
        if not os.path.exists(saving_dir):
            os.makedirs(saving_dir)
        np.save("%s/%s.npy" % (saving_dir, key), spkid)

        ## aishell2
        #utt=key
        #spk=utt[1:6]
        #saving_dir="%s/%s" % (out_dir, spk)
        #if not os.path.exists(saving_dir):
        #    os.makedirs(saving_dir)
        #np.save("%s/%s.npy" % (saving_dir, key), spkid)

        ##libritts
        #spk, chp, clip, utt=key.split('_')
        #spk=spk.lstrip("0")
        #chp=chp.lstrip("0")
        #saving_dir="%s/%s-%s" % (out_dir, spk, chp)
        ##saving_dir="%s/%s" % (out_dir, spk)
        #if not os.path.exists(saving_dir):
        #    os.makedirs(saving_dir)
        #np.save("%s/%s_%s_%s_%s.npy" % (saving_dir, spk, chp, clip, utt), spkid)

        #cn
        #spk, utt=key.split('_')
        ##spk=spk.lstrip("0")
        #utt=utt.lstrip("0")
        #if utt=='':
        #    utt='0'
        #saving_dir="%s/%s" % (out_dir, spk)
        #if not os.path.exists(saving_dir):
        #    os.makedirs(saving_dir)
        #np.save("%s/%s.npy" % (saving_dir, utt), spkid)

        #voicebunny
        #spk, chp, utt=key.split('_')
        #saving_dir="%s/%s" % (out_dir, spk)
        #if not os.path.exists(saving_dir):
        #    os.makedirs(saving_dir)
        #np.save("%s/%s.npy" % (saving_dir, key), spkid)

        #vctk
        #spk, utt='1', key
        #saving_dir="%s/%s" % (out_dir, spk)
        #if not os.path.exists(saving_dir):
        #    os.makedirs(saving_dir)
        #np.save("%s/%s.npy" % (saving_dir, key), spkid)
