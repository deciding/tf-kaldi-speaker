// ivectorbin/ivector-plda-applying.cc

// Copyright 2020  Zining Zhang

// See ../../COPYING for clarification regarding multiple authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.


#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "ivector/plda.h"


int main(int argc, char *argv[]) {
  using namespace kaldi;
  typedef kaldi::int32 int32;
  typedef std::string string;
  try {
    const char *usage =
        "Transform the input ivector using PLDA model\n"
        "There are two kinds of input ivectors: \n"
        "1. the input is the iVectors averaged over speakers;\n"
        "a separate archive containing the number of utterances per speaker may be\n"
        "optionally supplied using the --num-utts option \n"
        "(if not supplied, it defaults to 1 per speaker).\n"
        "2. the input is just normal single ivector for an utterance. \n"
        "\n"
        "Usage: ivector-plda-applying <plda> <in-ivector-rspecifier> <out-ivector-rspecifier>\n"
        "\n"
        "e.g.: ivector-plda-applying --num-utts=ark:exp/train/num_utts.ark plda "
        "ark:exp/train/spk_ivectors.ark ark:exp/train/transformed_ivectors.ark\n"
        "See also: ivector-compute-dot-products, ivector-compute-plda\n";

    ParseOptions po(usage);

    std::string num_utts_rspecifier;

    PldaConfig plda_config;
    plda_config.Register(&po);
    po.Register("num-utts", &num_utts_rspecifier, "Table to read the number of "
                "utterances per speaker, e.g. ark:num_utts.ark\n");
    po.Read(argc, argv);

    if (po.NumArgs() != 3) {
      po.PrintUsage();
      exit(1);
    }

    std::string plda_rxfilename = po.GetArg(1),
        ivector_rspecifier = po.GetArg(2),
        transformed_ivector_wspecifier = po.GetArg(3);

    //  diagnostics:
    int64 num_ivectors = 0, num_errs = 0;

    Plda plda;
    ReadKaldiObject(plda_rxfilename, &plda);

    int32 dim = plda.Dim();

    SequentialBaseFloatVectorReader ivector_reader(ivector_rspecifier);
    BaseFloatVectorWriter ivector_writer(transformed_ivector_wspecifier);
    RandomAccessInt32Reader num_utts_reader(num_utts_rspecifier);

    typedef unordered_map<string, Vector<BaseFloat>*, StringHasher> HashType;

    // These hashes will contain the iVectors in the PLDA subspace
    // (that makes the within-class variance unit and diagonalizes the
    // between-class covariance).  They will also possibly be length-normalized,
    // depending on the config.
    HashType transformed_ivectors;

    KALDI_LOG << "Reading input iVectors";
    for (; !ivector_reader.Done(); ivector_reader.Next()) {
      std::string spk = ivector_reader.Key();
      if (transformed_ivectors.count(spk) != 0) {
        KALDI_ERR << "Duplicate input iVector found for speaker/utterance " << spk;
      }
      const Vector<BaseFloat> &ivector = ivector_reader.Value();
      int32 num_examples;
      if (!num_utts_rspecifier.empty()) {
        if (!num_utts_reader.HasKey(spk)) {
          KALDI_WARN << "Number of utterances not given for speaker " << spk;
          num_errs++;
          continue;
        }
        num_examples = num_utts_reader.Value(spk);
      } else {
        num_examples = 1;
      }
      Vector<BaseFloat> *transformed_ivector = new Vector<BaseFloat>(dim);

      plda.TransformIvector(plda_config, ivector,
                                         num_examples,
                                         transformed_ivector);
      transformed_ivectors[spk] = transformed_ivector;
      ivector_writer.Write(spk, *transformed_ivector);
      num_ivectors++;
    }
    KALDI_LOG << "Read and wrote" << num_ivectors << " iVectors, "
              << "errors on " << num_errs;
    if (num_ivectors == 0)
      KALDI_ERR << "No training iVectors present.";

    return (num_ivectors != 0 ? 0 : 1);

  } catch(const std::exception &e) {
    std::cerr << e.what();
    return -1;
  }
}
