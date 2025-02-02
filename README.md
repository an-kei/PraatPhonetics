Praat
===

This Praat script allows to extract phonetic features of all occurrences of fricative consonants ``[f v s ʃ z ʒ]`` from sound recordings. It requires audio files (typically ``.wav``) associated with their corresponding ``.TextGrid`` files, where word and phoneme tiers are well labeled and aligned, without any pause/silence inside each non-empty word interval.

## What do we get?
The output will be a ``.tsv`` file made up of 11 columns listing the following information or features:
1. The sound filename in which the fricative occurs
2. The fricative represented by its SAMPA symbol
3. The middle time point (in s)
4. The duration (in ms)
5. The mean intensity (in dB)
6. The centre of gravity (CoG, in Hz)
7. Number of phonemes between this and next fricatives
8. Duration between this and next fricatives (in s)
9. The word in which the fricative occurs
10. Length of the word (in $N$ of phonemes)
11. Position of the fricative in the word ($i^{th}$ phoneme)  

*PS: This is my final assignment for the course **LYSL042 - Informatique et phonétique (2024-2025) © [Nicolas Audibert](https://github.com/nicolasaudibert)***
