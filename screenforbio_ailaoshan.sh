#!/bin/bash

set -e
set -u
set -o pipefail

# Send STDOUT and STDERR to log file
exec > >(tee -a get_taxonomy.`date +%Y-%m-%d`.log)
exec 2> >(tee -a get_taxonomy.`date +%Y-%m-%d`.log >&2)

# run '. ~/.linuxify' # activates GNU versions of grep, sed, awk

# Run

# Steps and associated scripts:
# 1. Process twin-tagged metabarcoding data
#   - *read_preprocessing.sh*


# Steps and associated scripts:

# 1. Process twin-tagged metabarcoding data
# did not run because we have an alternative bioinformatic pipeline

# 2. Obtain initial taxonomic classification for target taxon
#   - *get_taxonomy.sh*
# The working folder is the folder with the scripts in it.
# usage: bash get_taxonomy.sh <taxonName> <taxonRank> <screenforbio>
# where:
# <taxonName> is the scientific name of the target taxon e.g. Tetrapoda
# <taxonRank> is the classification rank of the target taxon e.g. superclass
# <screenforbio> is the path to the screenforbio-mbc directory
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
bash ~/src/screenforbio-mbc-ailaoshan/get_taxonomy.sh Tetrapoda superclass ~/src/screenforbio-mbc-ailaoshan/
# Success.
# Fetching taxonomy of Tetrapoda took 8.14 hours on 20190526, using fast internet
# output is Tetrapoda_ITIS_taxonomy.txt, a copy of which is in screenforbio-mbc-ailaoshan/archived_files/
cp archived_files/Tetrapoda_ITIS_taxonomy_20190512.txt ./Tetrapoda_ITIS_taxonomy.txt

# format of the new file is different from the 20190512 version, so this needs to be tested
# cp archived_files/Tetrapoda_ITIS_taxonomy_20190526.txt ./Tetrapoda_ITIS_taxonomy.txt

# 3. Generate non-redundant curated reference sequence database for target amplicon(s) and fix taxonomic classification
#   - *get_sequences.sh*
# usage: bash get_sequences.sh <extras> <gap-fill> <module> <taxon> <screenforbio>
# where:
# <extras> is 'yes' or 'no', indicating whether to add local FASTA format sequences. if 'yes', files must be in present directory labelled "extra_12S.fa", "extra_16S.fa", "extra_Cytb.fa", "extra_COI.fa", with headers in format Genus_species_uniqueID.
     # We add sequences from the Salleh et al. (2017 GigaScience paper). To generate 'extra_12S.fa' and 'extra_16S.fa' run archived_files/parse_Salleh_fasta_header.sh
# <gap-fill> is 'no' or a tab-delimited text file of species names to be targeted for gap-filling from NCBI, in format Genus_species.
# <module> is 'one', 'two', 'three' or 'four' indicating whether the script is starting from scratch ('one'), restarting after checking the output of the mafft alignment ('two'), restarting after manual correction of failed taxonomy lookups ('three'), or restarting after manual checks of SATIVA output ('four'). see end of module messages for any requirements for the next module."
# <taxon> is the taxon for which the taxonomy was downloaded with get_taxonomy.sh, e.g. Mammalia or Tetrapoda (all outputs should be in present directory).
# <screenforbio> is the path to the screenforbio-mbc directory


# Module 1 - Extract subset of raw Midori database for query taxon and loci. Remove sequences with non-binomial species names, reduce subspecies to species labels. Add local sequences (optional). Check for relevant new sequences for list of query species on NCBI (GenBank and RefSeq) (optional). Select amplicon region and remove primers. Remove sequences with ambiguous bases. Align. End of module: optional check of alignments
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
# copy MIDORI files that i want to process to the working directory: screenforbio-mbc-ailaoshan/
cp archived_files/MIDORI_UNIQUE_20180221_lrRNA_RDP.fasta.gz ./MIDORI_UNIQUE_1.2_lrRNA_RDP.fasta.gz; gunzip MIDORI_UNIQUE_1.2_lrRNA_RDP.fasta.gz
cp archived_files/MIDORI_UNIQUE_20180221_srRNA_RDP.fasta.gz ./MIDORI_UNIQUE_1.2_srRNA_RDP.fasta.gz; gunzip MIDORI_UNIQUE_1.2_srRNA_RDP.fasta.gz

# The 20180221 versions of MIDORI have more complex headers, which interfere with the `get_sequences.sh` code.
# V 1.1:  `>AF382008	root;Eukaryota;Chordata;Mammalia;Primates;Hominidae;Homo;Homo sapiens`
# V 20180221:  `>AF382008.3.649.1602	root;Eukaryota;Chordata;Mammalia;Primates;Hominidae;Homo;Homo sapiens`
sed -i 's/\.[0-9].*\t/\t/g' MIDORI_UNIQUE_1.2_lrRNA_RDP.fasta | head -n 40
sed -i 's/\.[0-9].*\t/\t/g' MIDORI_UNIQUE_1.2_srRNA_RDP.fasta | head -n 40

# there are two 12S_primers files:  12S_primers_kocher.fa and 12S_primers_riaz.fa. Duplicate the one that you want to use and change its filename to 12S_primers.fa, and this will be the pair used to pull out 12S amplicons from the Midori reference database
# to use the Kocher primers (12S_primers_kocher.fa), in get_sequences.sh:
     # change the usearch -search_pcr line 178 to
     # usearch -search_pcr ${label}.raw.fa -db ${SCRIPTS}/12S_primers.fa -strand both -maxdiffs 4 -minamp 420 -maxamp 470 -ampout ${label}.amp.fa
     # change the usearch -fastx_truncate line 183 to
     # usearch -fastx_truncate ${label}.amp.fa -stripleft 30 -stripright 28 -fastaout ${label}.amp_only.fa # for Kocher 12S primers
     # change the awk line 188 to
     # cat ${label}.amp.blastn | awk 'BEGIN{FS=OFS}($4>=360){print $1 OFS $7 OFS $8}' > ${label}.amp.blastn.coords # for 12S Kocher primers
# to use the Riaz primers (12S_primers_riaz.fa), in get_sequences.sh:
     # change the usearch -search_pcr line 179 to
     # usearch11 -search_pcr2 ${label}.raw.fa -fwdprimer ACTGGGATTAGATACCCC -revprimer YRGAACAGGCTCCTCTAG -minamp 80 -maxamp 120 -strand both -maxdiffs 4 -fastaout ${label}.amp.fa # for 12S Riaz primers
     # change the usearch -fastx_truncate line 184 to
     # usearch -fastx_truncate ${label}.amp.fa -stripleft 0 -stripright 0 -fastaout ${label}.amp_only.fa # for Riaz 12S primers
     # change the awk line 189 to
     # cat ${label}.amp.blastn | awk 'BEGIN{FS=OFS}($4>=80){print $1 OFS $7 OFS $8}' > ${label}.amp.blastn.coords # for 12S Riaz primers

bash ~/src/screenforbio-mbc-ailaoshan/get_sequences.sh yes no one Tetrapoda ~/src/screenforbio-mbc-ailaoshan/
# the first no is changed from no to yes to add the Salleh et al. 75 mitogenomes from GigaScience, which are in the files extra_12S.fa and extra_16S.fa (same content). The files were created with archived_files/parse_Salleh_fasta_header.sh
# Successful
# Module 1 took 0.58 hours (16Smam and 12SRiaz primers, Midori 1.1)
# Module 1 took 1.3 hours (16Smam and 12SRiaz primers, Midori 1.2)

# Actions after Module 1 complete
# Module 1 complete. Stopping now for manual inspection of alignments *.mafft.fa inside ./intermediate_files.
# Restart script when happy with alignments (save as *.mafft_edit.fa in present directory even if no edits are made).
# It is not feasible to examine the alignment in detail. What you are looking for is a tree with clear groupings of the Tetrapoda classes:  Mammalia, Reptilia, Amphibia, and Aves. And also, no extremely long branches.
# Input files have been moved to ./intermediate_files
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
mv ./intermediate_files/MIDORI_lrRNA.amp_blast.noN.mafft.fa ./MIDORI_lrRNA.amp_blast.noN.mafft_edit.fa
mv ./intermediate_files/MIDORI_srRNA.amp_blast.noN.mafft.fa ./MIDORI_srRNA.amp_blast.noN.mafft_edit.fa

# Module 2 - Compare sequence species labels in the MIDORI fasta files with the ITIS taxonomy. Non-matching labels are queried against Catalogue of Life to check for known synonyms. Remaining mismatches kept if genus already exists in taxonomy, otherwise flagged for removal. End of module: optional check of flagged species labels.
# Requires a taxon_ITIS_taxonomy.txt file (e.g. Tetrapoda_ITIS_taxonomy.txt file)
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
bash ~/src/screenforbio-mbc-ailaoshan/get_sequences.sh yes no two Tetrapoda ~/src/screenforbio-mbc-ailaoshan/

# Some species cause the taxize::classification() function inside get_sequences.sh to fail, throwing up the following error:
     # Retrieving data for taxon 'Zygogeomys trichopus'
     #
     # Error in doc_parse_raw(x, encoding = encoding, base_url = base_url, as_html = as_html,  :
     #   CData section not finished
     #  [63]
     # Calls: classification ... read_xml.character -> read_xml.raw -> doc_parse_raw
     # Execution halted
# The developer of taxize has flagged this bug in the Catalogue of Life, to be dealt with in the next release of taxize (for 0.9.8). UPDATE:  the problem appears to be in read_xml2, which is a separate module, which cannot read some non-standard ASCII characters in the names of some taxonomists. UPDATE: The 0.9.8 version of taxize has fixed the problem. The fix below is no longer needed.
     # To ID the species causing this error, open `classification_misbehavers_finder.Rmd`. This script loads "MIDORI_taxon.ITIS_mismatch_sp.txt", uses a tryCatch() loop to run taxize::classification() on each name in this file, and records the species that causes taxize::classification() to throw crashing errors.
     # We call these crashing species 'misbehavers,' and we remove them manually starting at line 532, which is before get_taxonomy_mismatches.R is run
          # remove misbehavers by deleting these species, like this:
          # sed -i '/Hemidactylus adensis/d' MIDORI_${TAXON}.ITIS_mismatch_sp.txt
     # Then add back the removed species starting at line 565, like this (WITH UNDERSCORE!!):
          # sed -i '$a\Hemidactylus_adensis\' MIDORI_${TAXON}.missing_sp.txt

# Success
# Module 2 took 0.96 hours (MIDORI 1.1)
# Module 2 took 3.63 hours (MIDORI 1.2)
# There are two output files:
     # Tetrapoda.missing_sp_to_delete.txt
     # Tetrapoda.combined_taxonomy.txt

# Actions after Module 2 complete
# Module 2 complete. Stopping now for manual inspection of failed species lookups (in Tetrapoda.missing_sp_to_delete.txt).
# If a failed lookup can be resolved, remove from Tetrapoda.missing_sp_to_delete.txt and add taxonomy to a tab-delimited file named Tetrapoda.missing_sp_taxonomy.txt with columns for kingdom,phylum,class,order,family,genus,species,status,query - 'status' should be something short and descriptive (_ instead of spaces; eg. mispelling or manual_synonym) and 'query' should be the entry in Tetrapoda.missing_sp_to_delete.txt. Tetrapoda.missing_sp_taxonomy.txt must not have a header line when the script is restarted.
# If all failed lookups are resolved, delete Tetrapoda.missing_sp_to_delete.txt. If some/all failed lookups cannot be resolved, keep the relevant species names in Tetrapoda.missing_sp_to_delete.txt. When restarting the script it will check for the presence of this file and act accordingly (sequences for these species will be discarded).
# If no failed lookups can be resolved, do not create Tetrapoda.missing_sp_taxonomy.txt, leave Tetrapoda.missing_sp_to_delete.txt as it is.
# Restart script when happy.

# I looked through Tetrapoda.missing_sp_to_delete.txt, and all the species are not ones found in Ailaoshan, so rather than look up and add their full taxonomic pathways, i left them in the file and proceeded to module_three.


# Module 3 - Discard flagged sequences. Update taxonomy key file for sequences found to be incorrectly labelled in Module 2. Run SATIVA. End of module: optional check of putatively mislabelled sequences
# requires file Tetrapoda.combined_taxonomy.txt from Module 2, or there is a copy in archived_files/
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
bash ~/src/screenforbio-mbc-ailaoshan/get_sequences.sh no no three Tetrapoda ~/src/screenforbio-mbc-ailaoshan/
# Success
# Module 3 took ~ 5.7 hours for srRNA and lrRNA, using 4 threads (MIDORI 1.1)
# Module 3 took ~ 13.15 hours for srRNA and lrRNA, using 6 threads (MIDORI 1.2)

# Actions after Module 3 complete
# Module 3 complete. Stopping now for manual inspection of mislabelled sequences in ./MIDORI_locus_sativa/MIDORI_locus.mis
# To skip manual editing, do nothing and restart script.
# To make changes, create file ./MIDORI_locus_sativa/MIDORI_locus.mis_to_delete and copy all confirmed mislabelled sequence accessions as a single column, tab-delimited list. These will be deleted at the start of module 4.
# For sequences where species-level or genus-level mislabelling can be resolved, make corrections directly in Tetrapoda.final_taxonomy_sativa.txt (i.e. replace the taxonomic classification for that sequence with the correct one), this will be used to rename sequences.
# Make higher level changes to the taxonomy at your own risk - untested.
# Restart script when happy.

cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
# archive an original version before changing it with the sativa suggestions
cp Tetrapoda.final_taxonomy_sativa.txt Tetrapoda.final_taxonomy_sativa_orig.txt
# then use this R code (delete_seqs_suggested_by_sativa.Rmd) to remove sequences that sativa identifies as incorrect
     # I remove all sequences that sativa identifies as having an incorrect taxonomy at family level and above, as such large errors are most likely to be database errors.
     # I ignore sativa's proposed substitute taxonomies below family level (mostly genus and species), because some unknown, possibly large, proportion of these are due to the *tree* being incorrect, since these are short seqs

# START AGAIN HERE to go over the species and genus-level sativa-flagged sequences to see if i can make useful corrections:  e.g. add Bufo to the ones with missing genus name

# Module 4 - Discard flagged sequences. Finalize consensus taxonomy and relabel sequences with correct species label and accession number. Select 1 representative sequence per haplotype per species.
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
bash ~/src/screenforbio-mbc-ailaoshan/get_sequences.sh no no four Tetrapoda ~/src/screenforbio-mbc-ailaoshan/

# sometimes Module 4 will fail because it reports an "F" in the sequence. This is because seqbuddy --clean_seq inserts "FTP error" messages in the within-species fasta files.  Check the uniq.fa and taxon.fa files in the working directory and see what the FTP error message is, which will be appended to the last sequence. Then go to get_sequences.sh module_four and modify or add to the sed -i lines where i remove these error messages (search on 'FTP error')
# examples from line 788.  There are 4 pairs of such lines.
     # sed -i '/FTP Error: got more than 8192 bytes/d' ${label}.final_clean_relabel.unalign.fa
     # sed -i '/FTP Error: \[Errno 8] nodename nor servname provided, or not known/d'  ${label}.final_clean_relabel.unalign.fa  ## \[ to escape the square bracket

# Success
# Module 4 took 5.67 hours (MIDORI 1.1)
# Module 4 took 4.08 hours (MIDORI 1.2)

# Module 4 complete. You have reached the end of get_sequences.sh
#
# Final database sequences are in Tetrapoda.final_database.locus.fa
# Final taxonomy file is in Tetrapoda.final_protax_taxonomy.txt
#
# Next step: train PROTAX models with either:
#   - train_protax.sh for unweighted models
#   - train_weighted_protax.sh for models weighted using a list of expected species


# Actions after Module 4 complete:  If sativa is used to change genus and/or species names, some of the reference sequences in Tetrapoda.final_database.16S.fa and Tetrapoda.final_database.12S.fa will have a few sequences without species names (e.g. >_DQ158435) or starting with _TAXCLUSTER (e.g. >__TAXCLUSTER161__Spea_bombifrons_AY523786)
# These should be removed because they interfere with PROTAX train (PROTAX needs sequences in the reference dataset to have the format >Ablepharus_kitaibelii_AY308325)
# cd ~/src/screenforbio-mbc-ailaoshan/
# . ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
# seqkit grep Tetrapoda.final_database.12S.fa -r -p ^_ -v -o Tetrapoda.final_database.12S_new.fa
# seqkit grep Tetrapoda.final_database.16S.fa -r -p ^_ -v -o Tetrapoda.final_database.16S_new.fa
# check the new fasta files
# mv Tetrapoda.final_database.12S_new.fa Tetrapoda.final_database.12S.fa # overwrites the pre-existing file
# mv Tetrapoda.final_database.16S_new.fa Tetrapoda.final_database.16S.fa # overwrites the pre-existing file

# 4. Train PROTAX models for target amplicon(s)
#   - *train_protax.sh* (unweighted) or *train_weighted_protax.sh* (weighted)
#   - *check_protax_training.sh* (makes bias-accuracy plots)
#   - *choose between weighted or unweighted.  I use weighted because we have a species list for Ailaoshan

# unweighted
# cd ~/src/screenforbio-mbc-ailaoshan/
# . ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed
# bash ~/src/screenforbio-mbc-ailaoshan/train_protax.sh Tetrapoda.final_protax_taxonomy.txt ~/src/screenforbio-mbc-ailaoshan
     # usage: bash train_protax.sh taxonomy screenforbio
     # where:
     # taxonomy is the final protax-formatted taxonomy file from get_sequences.sh (e.g. Tetrapoda.final_protax_taxonomy.txt)
     # uses fasta files output from module_four of get_sequences.sh:  taxon.final_database.locus.fa (e.g. Tetrapoda.final_database.12S.fa)
     # screenforbio is the path to the screenforbio-mbc directory (must contain subdirectory protaxscripts)


# weighted by Ailaoshan species list:  splist (birds, herps, mammals)
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed

cp ~/Dropbox/Working_docs/Ji_Ailaoshan_leeches/2018/data/species_lists/splist_20190516.csv ./splist.csv

bash ~/src/screenforbio-mbc-ailaoshan/train_weighted_protax.sh splist.csv Tetrapoda.final_protax_taxonomy.txt ~/src/screenforbio-mbc-ailaoshan/
     # usage: bash train_weighted_protax.sh splist taxonomy screenforbio
     # where:
     # splist is a list of expected species to use in weighting in the format Genus,species (e.g. Homo,sapiens)
     # taxonomy is the final protax-formatted taxonomy file from get_sequences.sh (e.g. Tetrapoda.final_protax_taxonomy.txt)
     # screenforbio is the path to the screenforbio-mbc directory (must contain subdirectory protaxscripts)
     # note: will take the taxon from the protax taxonomy file name
     # note: assumes curated database FASTA files are in current directory and labelled with format taxon.final_database.locus.fa (e.g. Tetrapoda.final_database.12S.fa)

# End of train_protax.sh
# Success
# This took a total of 4.3 hours (MIDORI 1.2)
     # weighted_protax_training.R is hardcoded to run through all four loci (12S, 16S, Cytb, COI), so if one or more loci is missing (i.e. no Tetrapoda.final_database.Cytb.fa), the script is halted and generates an error message, but the previous loci do complete successfully.
     # example error message when Cytb is not included. Just ignore this and go to the next step
          # Working on Cytb in folder ./w_model_Cytb/
          # Working on level1
          # Error in file(file, "rt") : cannot open the connection
          # Calls: read.xdata -> read.table -> file
          # In addition: Warning message:
          # In file(file, "rt") :
          #   cannot open file './w_model_Cytb/train.w1.xdat': No such file or directory
          # Execution halted

# Select an mcmc iteration for each of the four levels for each marker (e.g. ./w_model_16S/w_mcmc1a-d, ./w_model_16S/w_mcmc2a-d, etc.) based on the training plots (labelled ./w_model_16S/weighted_training_plot_16S_level1a_MCMC.pdf, etc). Chains should be well-mixed and acceptance ratio as close to 0.44 as possible. Relabel the selected model as ./w_model_16S/mcmc1 ./w_model_16S/mcmc2 etc.

# For an example of how to choose the model, go to archived_files/protax_training_mcmc_output_16S_example/. There are 4 PDF files (training_plot_16S_level4{a,b,c,d}_MCMC.pdf). To choose amongst these, Panu Somervuo wrote:
     # "In all four cases a-d, the highest logposterior is very similar (around -7912) and also the coefficients corresponding to it (red dot) among a-d are very close to each other (i.e. mislabeling probability around 0.25 , beta1 around 0, beta2 around -40, beta3 around 4 and beta4 around -80, so I would say that all of them would give very similar classification results. Of course, when looking the traceplot of a, it seems that the MCMC has not converged properly, since in the beginning of the plot it is in a different regime, however, the parameter values corresponding to the largest posterior are similar as in b,c,d. I think if taking any one from b,c,or d, they would give very similar (or even identical) classification results."
     # The traceplots of 'mcmc a' are seen to wander by looking at the traceplots themselves and also at the histograms, which are skewed.
     # Acceptance ratio is on the second page of the PDFs

cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed

# unweighted
     # 12S
# MOD1CHOSEN12S="mcmc1c"
# MOD2CHOSEN12S="mcmc2a"
# MOD3CHOSEN12S="mcmc3d"
# MOD4CHOSEN12S="mcmc4b"
     # 16S
# MOD1CHOSEN16S="mcmc1d"
# MOD2CHOSEN16S="mcmc2b"
# MOD3CHOSEN16S="mcmc3c"
# MOD4CHOSEN16S="mcmc4d"
# mv ./model_12S/${MOD1CHOSEN12S} ./model_12S/mcmc1
# mv ./model_12S/${MOD2CHOSEN12S} ./model_12S/mcmc2
# mv ./model_12S/${MOD3CHOSEN12S} ./model_12S/mcmc3
# mv ./model_12S/${MOD4CHOSEN12S} ./model_12S/mcmc4
# mv ./model_16S/${MOD1CHOSEN16S} ./model_16S/mcmc1
# mv ./model_16S/${MOD2CHOSEN16S} ./model_16S/mcmc2
# mv ./model_16S/${MOD3CHOSEN16S} ./model_16S/mcmc3
# mv ./model_16S/${MOD4CHOSEN16S} ./model_16S/mcmc4

# weighted
     # 12S
MOD1CHOSEN12S="w_mcmc1d"
MOD2CHOSEN12S="w_mcmc2d"
MOD3CHOSEN12S="w_mcmc3b"
MOD4CHOSEN12S="w_mcmc4d"
     # 16S
MOD1CHOSEN16S="w_mcmc1c"
MOD2CHOSEN16S="w_mcmc2c"
MOD3CHOSEN16S="w_mcmc3b"
MOD4CHOSEN16S="w_mcmc4c"
mv ./w_model_12S/${MOD1CHOSEN12S} ./w_model_12S/w_mcmc1
mv ./w_model_12S/${MOD2CHOSEN12S} ./w_model_12S/w_mcmc2
mv ./w_model_12S/${MOD3CHOSEN12S} ./w_model_12S/w_mcmc3
mv ./w_model_12S/${MOD4CHOSEN12S} ./w_model_12S/w_mcmc4
mv ./w_model_16S/${MOD1CHOSEN16S} ./w_model_16S/w_mcmc1
mv ./w_model_16S/${MOD2CHOSEN16S} ./w_model_16S/w_mcmc2
mv ./w_model_16S/${MOD3CHOSEN16S} ./w_model_16S/w_mcmc3
mv ./w_model_16S/${MOD4CHOSEN16S} ./w_model_16S/w_mcmc4

# Next step: Check model training with check_protax_training.sh
# usage: bash check_protax_training.sh modeldir taxon locus screenforbio
# where:
# modeldir is the path to a directory containing the protax model to be checked
# taxon is the taxon for which the model was generated (used for labelling only)
# locus is the locus for which the model was generated (used for labelling only)
# screenforbio is the path to the screenforbio-mbc directory (must contain subdirectory protaxscripts)

# unweighted
# bash check_protax_training.sh model_12S Tetrapoda 12S ~/src/screenforbio-mbc-ailaoshan/
# bash check_protax_training.sh model_16S Tetrapoda 16S ~/src/screenforbio-mbc-ailaoshan/

# weighted
bash check_protax_training.sh w_model_12S Tetrapoda 12S ~/src/screenforbio-mbc-ailaoshan/
bash check_protax_training.sh w_model_16S Tetrapoda 16S ~/src/screenforbio-mbc-ailaoshan/

# Each model check took ~0.02 hours
# Plots can be found in model_12S/checktrain/unweighted_Tetrapoda_12S_biasaccuracy.pdf
# Plots can be found in model_16S/checktrain/unweighted_Tetrapoda_16S_biasaccuracy.pdf


# 5. Classify query sequences (reads or OTUs) with PROTAX
#   - Process raw data with read_preprocessing.sh (experimental design must follow that described in the manuscript) and classify the output with protax_classify.sh or weighted_protax_classify.sh as appropriate
#   - Classify OTUs with protax_classify_otus.sh or weighted_protax_classify_otus.sh as appropriate

# these are my pathnames to my Ailaoshan OTU representative sequences
OTUS12S_SWARM="/Users/Negorashi2011/Dropbox/Working_docs/Ji_Ailaoshan_leeches/2018/data/OTU_representative_sequences/all_12S_20180317_otu_table_swarm_lulu.fa"
OTUS12S_USEARCH="/Users/Negorashi2011/Dropbox/Working_docs/Ji_Ailaoshan_leeches/2018/data/OTU_representative_sequences/all_12S_20180317_otu_table_usearchderep_lulu.fa"
OTUS16S_SWARM="/Users/Negorashi2011/Dropbox/Working_docs/Ji_Ailaoshan_leeches/2018/data/OTU_representative_sequences/all_16S_20180321_otu_table_swarm_lulu.fa"
echo ${OTUS12S_SWARM}
echo ${OTUS12S_USEARCH}
echo ${OTUS16S_SWARM}

# unweighted
     # move protax output files to a single folder
# mkdir protaxmodels/
# mv model_12S protaxmodels/
# mv model_16S protaxmodels/
# bash protax_classify_otus.sh ${OTUS12S_SWARM} 12S protaxmodels ~/src/screenforbio-mbc-ailaoshan protaxout_swarm
# bash protax_classify_otus.sh ${OTUS12S_USEARCH} 12S protaxmodels ~/src/screenforbio-mbc-ailaoshan protaxout_usearch
# bash protax_classify_otus.sh ${OTUS16S_SWARM} 16S protaxmodels ~/src/screenforbio-mbc-ailaoshan protaxout_swarm
     # usage: bash protax_classify_otus.sh otus locus protaxdir screenforbio outdir
     # where:
     # otus is the (path to) the OTU fasta to be processed (suffix should be ".fa")
     # locus is the target locus, must be one of: 12S, 16S, CYTB, COI. if you have more than one locus to analyse, run script once for each.
     # protaxdir is the path to a directory containing protax models and clean databases for all 4 loci
     # screenforbio is the path to the screenforbio-mbc directory (must contain subdirectory protaxscripts)
     # outdir is the name to give an output directory (inside current) (no slash at end)

# weighted
     # move weighted protax output files to a single folder
mkdir w_protaxmodels/
mv w_model_12S w_protaxmodels/
mv w_model_16S w_protaxmodels/
bash weighted_protax_classify_otus.sh ${OTUS12S_SWARM} 12S w_protaxmodels ~/src/screenforbio-mbc-ailaoshan w_protaxout_swarm
bash weighted_protax_classify_otus.sh ${OTUS12S_USEARCH} 12S w_protaxmodels ~/src/screenforbio-mbc-ailaoshan w_protaxout_usearch
bash weighted_protax_classify_otus.sh ${OTUS16S_SWARM} 16S w_protaxmodels ~/src/screenforbio-mbc-ailaoshan w_protaxout_swarm
     # usage: bash weighted_protax_classify_otus.sh otus locus protaxdir screenforbio outdir
     # where:
     # otus is the (path to) the OTU fasta to be processed (suffix should be ".fa")
     # locus is the target locus, must be one of: 12S, 16S, CYTB, COI. if you have more than one locus to analyse, run script once for each.
     # protaxdir is the path to a directory containing weighted protax models and clean databases for all 4 loci
     # screenforbio is the path to the screenforbio-mbc directory (must contain subdirectory protaxscripts)
     # outdir is the name to give the output directory (inside current)

# Success
# Example output from 16S:
# This took a total of 0.58 minutes.
#
# Results are in ./w_protaxout_swarm_16S/
# Classification for each OTU at each taxonomic level (species, genus, family, order) in files all_16S_20180321_otu_table_swarm_lulu.<level>_probs
# e.g. all_16S_20180321_otu_table_swarm_lulu.w_species_probs
# queryID taxID   log(probability)  level   taxon
# OTU1    816     -1.25544          4       Anura,Dicroglossidae,Nanorana,taihangnica
# log(prob) is ln(prob), so to get probability, convert by exp(log(probability))

# Additionally, the best matching hit (for assigned species/genus where available) found with LAST is appended to all_16S_20180321_otu_table_swarm_lulu.species_probs in all_16S_20180321_otu_table_swarm_lulu.species_probs_sim
# queryID taxID   log(probability) level   taxon                                        bestHit_similarity      bestHit
# OTU1    816     -1.25544         4       Anura,Dicroglossidae,Nanorana,taihangnica    0.979 Nanorana_taihangnica_KJ569109

# 5.1 Use combine_protax_output_tables.Rmd to combine the protax output files. The script is written to process w_protaxout_swarm_12S, w_protaxout_swarm_16S, w_protaxout_usearch_12S


# 6. To assign taxonomies to new a new set of OTUs
# these are my pathnames to my Ailaoshan OTU representative sequences
cd ~/src/screenforbio-mbc-ailaoshan/
. ~/.linuxify; which sed # should show /usr/local/opt/gnu-sed/libexec/gnubin/sed

# set pathnames to OTU sequences
OTUS12S_SWARM="/Users/Negorashi2011/Dropbox/Working_docs/Cai_443_Ponds/OTUs/table_500ponds2_12sv5_97.fas.blast.fas"
OTUS16S_SWARM="/Users/Negorashi2011/Dropbox/Working_docs/Ji_Ailaoshan_leeches/2018/16S_otu_table_swarm_lulu_20190624.fas"
echo ${OTUS12S_SWARM}; head ${OTUS12S_SWARM}
echo ${OTUS16S_SWARM}
bash weighted_protax_classify_otus.sh ${OTUS12S_SWARM} 12S w_protaxmodels ~/src/screenforbio-mbc-ailaoshan w_protaxout_swarm_20190704
bash weighted_protax_classify_otus.sh ${OTUS16S_SWARM} 16S w_protaxmodels ~/src/screenforbio-mbc-ailaoshan w_protaxout_swarm_20190624
     # usage: bash weighted_protax_classify_otus.sh otus locus protaxdir screenforbio outdir
     # where:
     # otus is the (path to) the OTU fasta to be processed (suffix should be ".fa")
     # locus is the target locus, must be one of: 12S, 16S, CYTB, COI. if you have more than one locus to analyse, run script once for each.
     # protaxdir is the path to a directory containing weighted protax models and clean databases for all 4 loci
     # screenforbio is the path to the screenforbio-mbc directory (must contain subdirectory protaxscripts)
     # outdir is the name to give the output directory (inside current)

     # 5.1 Use combine_protax_output_tables.Rmd to combine the protax output files. The script is written to process w_protaxout_swarm_12S, w_protaxout_swarm_16S, w_protaxout_usearch_12S
