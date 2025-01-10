# ===================================================================================
# script for task:  Extract acoustic features of fricatives /f s ʃ v z ʒ/ 
# Input (from):       .wav / .TextGrid 
# Output (to):        .tsv
# 
# Note that this script assumes the fulfilment of the following conditions in .TextGrid files:
# 1 - a tier of annotated words
# 2 - a tier of annotated phonemes
# these tiers should be:
#   1) aligned with sound file
#   2) aligned with each other
#   
#   => a word interval should:
#       1) start at the left boundary of its first phoneme, 
#       2) end at the right boundary of its last phoneme
#       3) not contain any pause phoneme '<p:>'
#
# 
# author:   Ji AN (https://github.com/an-kei/PraatPhonetics.git)
# email:    onkei.anji@gmail.com
# date:     2025-01-10
# 
# 
# Data for each column:
# 1 - filename (XXX.wav) 
# 2 - fricative itself (SAMPA): /f v s ʃ z ʒ/ => f v s S z Z
# 3 - middle time point (s)
# 4 - duration (ms)
# 5 - average intensity (dB)
# 6 - center of gravity of the spectrum, (Hz)
# 7 - number of phonemes between current and next fricative (excluding '<p:>'), 
#     ... 0 for the last one (integer)
# 8 - duration (s) between current and next fricative, 
#     ... '--undefined--' for the last one (string)
# 9 - the word in which the fricative occurs (string)
# 10 - word length in number of phonemes (integer)
# 11 - position of the fricative in the word (first=1, second=2, etc.) => (integer)
# 
# 
# User Input (with default values):
# 1- folder:        directory of sound files (.wav)
# 2- folder:        directory of textgrid files (.TextGrid)
# 3- suffix:        str, e.g. "_aligne"
# 4- tier index:    words (e.g. 1)
# 5- tier index:    phonemes (e.g. 2)
# 6- folder:        output directory (e.g. results)
# 7- name:          output filename (e.g. fricatives)

# NB: have used ChatGPT for some understanding, but mostly it misleads human about praat scripting :)
# ===================================================================================


# ==== FORM ==== # 
# this window pops up, asks user to enter folder paths, tier indices 
# possible suffix string added in .TextGrid filenames, output folder and filename
# we then reuse them as variables in the script

form Extract acoustic features of fricatives
    # path to the folders for .wav files / .TextGrid files
    comment Paths to folders for sound files (.wav) and annotation files (.TextGrid)
    folder      Sound_folder                    dossier_fichiers_wav_TextGrid
    folder      Annotation_folder               dossier_fichiers_wav_TextGrid
    # suffix added at the end of .TextGrid filenames
    comment Uniform suffix added to .wav filenames as their .TextGrid filenames
    comment (Leave it empty if .wav and .TextGrid files have shared filenames)
    sentence    Suffix_for_annotation_files     _aligne
    
    comment Tier indices of annotations for words and phonemes in .TextGrid files
    natural     Word_tier_index         1
    natural     Phoneme_tier_index      2
    
    comment Path to output folder (will be created if nonexistent)
    folder      Output_folder           results
    comment Output filename (without extension)
    word        Output_filename         fricatives
endform

# clear info window if any info is already there
clearinfo


# ==== SCRIPT ==== #
# Re-assign variables provided by user (add slash, shorten a bit)
soundPath$  = sound_folder$ + "/"
gridPath$   = annotation_folder$ + "/"
suffix$     = suffix_for_annotation_files$
outputFile$ = output_folder$ + "/" + output_filename$ + ".tsv"

# create output folder if not done yet
createDirectory: output_folder$
# delete existent output file if any
if fileReadable(outputFile$)
    deleteFile: outputFile$
endif

# before looping all sound files, should write header line to output file
writeFileLine: outputFile$,
    ... "SoundName_(.wav)", tab$,   "Fricative_(SAMPA)",    tab$, 
    ... "MiddleTime_(s)",   tab$,   "Duration_(ms)",        tab$, 
    ... "MeanIntensity_(dB)",           tab$, 
    ... "CentreOfGravity_(Hz)",         tab$,
    ... "PhonemesToNextFricative",      tab$,
    ... "DurationToNextFricative_(s)",  tab$, 
    ... "InWord",                       tab$,   
    ... "WordLength",                   tab$, 
    ... "FricativePositionInWord"

# get all files in sound / textgrid folders into a Strings object
soundList = Create Strings as file list: "soundList", soundPath$ + "*.wav"
# see how many sound files will be processed
numSounds = Get number of strings
writeInfoLine: "Found ", numSounds, " sound files", newline$

# main loop: through all sound files in the folder
for iSound from 1 to numSounds
    selectObject: soundList
    soundName$ = Get string: iSound         ; get current sound filename
    soundFile$ = soundPath$ + soundName$    ; get full path of current sound file
    
    # get full path of current textgrid file 
    # no matter suffix$ is empty ("") or not, this concatenation works
    gridFile$ = gridPath$ + soundName$ - ".wav" + suffix$ + ".TextGrid"
    
    sound = Read from file: soundFile$
    grid = Read from file: gridFile$

    # print out current file pair being processed
    appendInfoLine: 
    ... "Processing files:", newline$, 
    ... soundFile$, newline$, 
    ... gridFile$, newline$

    # for each tier, (optionally) inspect raw number of intervals
    selectObject: grid
    num_intervals_phon = Get number of intervals: phoneme_tier_index
    num_intervals_word = Get number of intervals: word_tier_index
    appendInfoLine: 
    ... "Total intervals in phoneme tier:", tab$, num_intervals_phon, newline$,
    ... "Total intervals in word tier:",    tab$, num_intervals_word, newline$

    f_count = 0 ; counter for fricatives
    for iPhon from 1 to num_intervals_phon 
        selectObject: grid
        phon_label$ = Get label of interval: phoneme_tier_index, iPhon
        # main condition to match fricatives
        if         phon_label$ == "f" or phon_label$ == "v" 
            ... or phon_label$ == "s" or phon_label$ == "S" 
            ... or phon_label$ == "z" or phon_label$ == "Z"
            
            f_count += 1    ; as fricative index of current file

            # optional: assigne label to f_label$ for better readability later
            f_label$ = phon_label$
            # get start / end / middle / duration of current fricative
            f_start = Get start time of interval: phoneme_tier_index, iPhon
            f_end = Get end time of interval: phoneme_tier_index, iPhon
            f_middle = (f_start + f_end) / 2
            # duration should be converted from s to ms
            f_duration = (f_end - f_start) * 1000 

            
            # Below: to obtain mean intensity + centre of gravity (CoG),
            # use respectively a temporary fricative sound slice object
            # and a temporary spectrum object from this slice
            selectObject: sound
            f_sound = Extract part: f_start, f_end, "rectangular", 1.0, "no"
            f_mean_intensity = Get intensity (dB)
            # NB: at first I thought I need to create an intensity object based on the current 
            # fricative sound slice, later I learn that this requires some strict conditions
            # on the duration and pitch floor etc. So I changed to use the sound slice's
            # default "Get intensity (dB)" instead, which seems more straightforward.

            # create spectrum object from current fricative sound slice
            selectObject: f_sound
            f_spectrum = To Spectrum: "yes"  
            # get centre of gravity from this spectrum
            f_cog = Get centre of gravity: 2.0

            # remove these temporary objects after use
            removeObject: f_spectrum, f_sound
            
            
            ## Below: count the number of phonemes between current and next fricative
            # and compute the duration between current fricative and next fricative
            selectObject: grid
            # counter: value we need! count phonemes between current and next fricative
            phon_count = 0 
            # if we find the next fricative, we set this to 1, 
            # otherwise 0, meaning the current fricative is the last one
            found_next_f = 0
            # since iPhon is the index of current fricative, 
            # so we start from the index of its next phoneme, i.e. iPhon+1
            next_iPhon = iPhon + 1
            
            # start loop: from the next phoneme through the next fricative
            while next_iPhon <= num_intervals_phon
                # for each phoneme iPhon, get the label of next phoneme
                next_phon_label$ = Get label of interval: phoneme_tier_index, next_iPhon
                # if next phoneme is a fricative, we can stop looping
                if next_phon_label$ == "f" or next_phon_label$ == "v" 
                    ... or next_phon_label$ == "s" or next_phon_label$ == "S"
                    ... or next_phon_label$ == "z" or next_phon_label$ == "Z"
                    found_next_f = 1                ; means we found next fricative
                    next_f_start = Get start time of interval: phoneme_tier_index, next_iPhon
                    # convert duration's varible type to string 
                    # because it can also be '--undefined--' later
                    duration_between$ = string$(next_f_start - f_end) 
                    next_iPhon = num_intervals_phon + 1 ; just for breaking the loop
                
                elif next_phon_label$ == "<p:>"     ; if next is a silence pause
                    next_iPhon += 1                 ; skip it & move forward
                else   ; if next is any of the other phonemes (neither fricative nor pause)
                    phon_count = phon_count + 1     ; count it as a phoneme in between
                    next_iPhon += 1                 ; move to next
                endif
            endwhile

            # if after while loop, found_next_f is still O, it means current fricative is the final one
            if found_next_f == 0
                # in while loop we increment phon_count by 1 no matter we find next fricative or not,
                # so, since current fricative is the last fricative, we need to reset phon_count back to zero
                phon_count = 0  
                duration_between$ = "--undefined--"
            endif


            ## Below: get the word in which the fricative occurs
            # and the word length in number of phonemes
            selectObject: grid
            # use fricative's middle time to locate the word in word tier
            # given fricative's middle time, get the word's index (time -> interval index)
            iWord = Get interval at time: word_tier_index, f_middle 
            # given interval index, get the word's label (interval index -> label)
            f_word$ = Get label of interval: word_tier_index, iWord 
            # since the whole textgrid is pre-aligned, 
            # hopefully there is no pause in any 'word' interval
            # this way we can directly get the number of phonemes in this word by slicing off this word interval
            # so for convenience I extract the textgrid slice of the target word
            w_start = Get start time of interval: word_tier_index, iWord
            w_end   = Get end time of interval: word_tier_index, iWord
            word_grid = Extract part: w_start, w_end, "yes"
            word_len = Get number of intervals: phoneme_tier_index

            stop = word_len
            for jPhon from 1 to stop
                w_phon_label$ = Get label of interval: phoneme_tier_index, jPhon
                w_phon_start = Get start time of interval: phoneme_tier_index, jPhon
                w_phon_end = Get end time of interval: phoneme_tier_index, jPhon
                # NB: we have to make sure all these 3 conditions are met
                # if we don't check the time boundaries 
                # there may be another identical fricative in the same word!!
                if f_label$ == w_phon_label$ 
                    ... and f_start == w_phon_start 
                    ... and f_end == w_phon_end
                    f_position = jPhon
                    # bingo! current index jPhon is exactly the fricative's position we want
                    stop = jPhon ; tell the loop to stop here ;)
                endif
            endfor
            # clean up temporaty word grid object
            removeObject: word_grid
            

            # check for each fricative if all values are correctly computed / extracted
            appendInfoLine: 
            ... "Found fricative No. ",             tab$, f_count,              newline$,
            ... "Label: ",                          tab$, f_label$,             newline$, 
            ... "Start: ",                          tab$, f_start,              newline$, 
            ... "End: ",                      tab$, tab$, f_end,                newline$, 
            ... "Middle: ",                         tab$, f_middle,             newline$, 
            ... "Duration (ms): ",            tab$, tab$, f_duration,           newline$,
            ... "Intensity (dB): ",           tab$, tab$, f_mean_intensity,     newline$,
            ... "Centre of Gravity (Hz): ",         tab$, f_cog,                newline$,
            ... "Phonemes to next fricative: ",     tab$, phon_count,           newline$,
            ... "Duration to next fricative (s): ", tab$, duration_between$,    newline$,
            ... "Fricative is in word: ",           tab$, f_word$,              newline$,
            ... "Total phonemes in word: ",         tab$, word_len,             newline$,
            ... "Fricative position in word: ",     tab$, f_position,           newline$

            # after checking, we can finally write these values to output file
            appendFileLine: outputFile$,
            ... soundName$ - ".wav", tab$, f_label$, tab$, 
            ... f_middle, tab$, f_duration, tab$, 
            ... f_mean_intensity, tab$, 
            ... f_cog, tab$, 
            ... phon_count, tab$, 
            ... duration_between$, tab$, 
            ... f_word$, tab$, word_len, tab$, f_position

        # end of if condition for current fricative 
        endif
    # end for loop for current sound file
    endfor
    # clean up current pair sound / grid objects, move to next pair
    removeObject: sound, grid
# end of main loop for all pair files
endfor

# final clean-up
removeObject: soundList
appendInfoLine: "All done! Results saved in ", newline$, outputFile$, newline$
