# The virtualenv path
#export TF_ENV=/home/heliang05/liuyi/venv

export TF_KALDI_ROOT=/workspace/ssd2/PVoice/tf-kaldi-speaker
export KALDI_ROOT=/workspace/ssd2/PVoice/kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C
