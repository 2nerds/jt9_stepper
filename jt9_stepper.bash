#!/bin/bash

MYNAME=$(basename $0)
SPACES=$(echo "$MYNAME" | sed -e 's/[^ ]/ /g')

SUBPROGRAM=jt9

type $SUBPROGRAM >/dev/null || { echo "$SUBPROGRAM executable not found in PATH"; exit 1; }

BEGIN=1420
STEP=40
END=1580
DRIFT=0
CYCLES=0
JITTER=0
MAXJOBS=4

usage() {
cat <<EOF
NAME
     $MYNAME -- run jt9 on given input file(s) multiple times across
     $SPACES    a range of frequency settings, collate outputs,
     $SPACES    convert to wspr_spots format

SYNOPSIS
     $MYNAME [ -q ]
     $SPACES [ -b base ]
     $SPACES [ -s step ]
     $SPACES [ -e end ]
     $SPACES [ -p maxjobs ]
     $SPACES [ -d drift ]
     $SPACES [ -c cycles ]
     $SPACES [ -j jitter ] -- [ $SUBPROGRAM options ... ] input_wav_file ...

DESCRIPTION
     For the given input wav file(s), run jt9 multiple times, once for
     each frequency from 'base' to 'end' incrementing by 'step'.

     The starting frequency is $BEGIN unless overridden with the -b option.
     The frequency increment is $STEP unless overridden with the -s option.
     The ending frequency is $END unless overridden with the -e option.

     Once the wav file has been processed for each frequency, the
     outputs are filtered such that only the strongest signal for each
     callsign is written to decoded.txt.

     Finally, the decoded.txt file is converted to wspr_spots.txt
     format, passing through the drift, cycles, and jitter values
     given on the command line (all defaulting to zero if not
     specified).

     The following options are available:

         -q        Be less chatty

         -b base   Use 'base' as the starting frequency (default $BEGIN)

         -s step   Use 'step' as the frequency increment (default $STEP)

         -e end    Use 'end' as the ending frequency (default $END)

         -p maxjobs  Run no more than 'maxjobs' $PROGRAM subtasks in parallel (default $MAXJOBS)

         -d drift  Pass 'drift' value through to wspr_spots.txt output (default $DRIFT)

         -c cycles Pass 'cycles' value through to wspr_spots.txt output (default $CYCLES)

         -j jitter Pass 'jitter' value through to wspr_spots.txt output (default $JITTER)

EOF
}

unset QUIET
while getopts qb:s:e:p:d:c:j:h arg; do
  case $arg in
  q) QUIET=1         ;;
  b) BEGIN=$OPTARG   ;;
  s) STEP=$OPTARG    ;;
  e) END=$OPTARG     ;;
  p) MAXJOBS=$OPTARG ;;
  d) DRIFT=$OPTARG   ;;
  c) CYCLES=$OPTARG  ;;
  j) JITTER=$OPTARG  ;;
  *) usage; exit 1   ;;
  esac
done
shift $(($OPTIND - 1))

# Collect remaining arguments, if any,
# adjusting filenames to point to parent directory.
PROGARGS=""
GOTFN=""
while test -n "$1" ; do
  # Adjust readable filenames to point to the parent directory
  # (because we'll be running $SUBPROGRAM in a subdirectory).
  # This "if it's readable it's an input file" technique
  # assumes that no files exist with names matching
  # any $SUBPROGRAM option /VALUES/.
  # (e.g. if you're passing "-p 120" to $SUBPROGRAM, you better
  # hope no file named "120" exists in the current directory)
  if test -r "./$1" ; then
    if test -z "$GOTFN" ; then FIRSTFILENAME="$1"; fi
    PROGARGS="$PROGARGS ../$1"
    GOTFN=1
  else
    PROGARGS="$PROGARGS $1"
  fi
  shift
done

test -n "$GOTFN" || { echo "Missing input filename argument(s)"; usage; exit 1; }
test $BEGIN -lt $END || { echo "'begin' must be less than 'end'"; exit 1; }
test $MAXJOBS -gt 0  || { echo "'maxjobs' must be greater than zero"; exit 1; }

DIRS=""
let j=1
for f in $(seq $BEGIN $STEP $END) ; do
  DIR=$(mktemp -d $(pwd)/${MYNAME}.XXXXXX) || { echo "Unable to make temporary directory" 1>&2; exit 1; }
#  echo "$f using $DIR" 1>&2
  DIRS="$DIRS $DIR"
  trap "rm -rf $DIRS" EXIT

  # Run $SUBPROGRAM with input file from parent directory,
  # frequency option from the loop control variable, and
  # $SUBPROGRAM args from the script command line, if any
  test -z "$QUIET" && echo nice $SUBPROGRAM -f $f $PROGARGS
  bash -c "cd $DIR && nice $SUBPROGRAM -f $f $PROGARGS ${QUIET:+>/dev/null}" &

  # not too much at once
  if test $((j % $MAXJOBS)) -eq 0 ; then
    wait
  fi
  let j=j+1
done
wait


# decoded.txt format:
#
# snipped from decoder.f90:
#          write(13,1002) nutc,nint(sync),nsnr,dt,freq,0,decoded0
#   1002   format(i6.6,i4,i5,f6.1,f8.0,i4,3x,a37,' FST4')
#
# time                     audio                         reported tx power       (always)
# UTC--- sync SNR-- DT---- freq---- ---0xxxcallsign grid (dBm)------------------ FST4
# ------------------------------------------------------------------------------------
# 0000      0     9    0.2    1573.    0   KA7OEI   DN40 17                      FST4
# ------ ---- ----- ------ -------- ----xxx------------------------------------- -----
# i6.6   i4   i5    f6.1   f8.0     i4  3x a37                                 ' FST4'
# nutc   sync nsnr  dt     freq     0      decoded0                            ' FST4'
# $1     $2   $3    $4     $5       $6     $7       $8   $9                      $10
#

test -r decoded.txt && rm -f decoded.txt
for d in $DIRS ; do
  cat "$d/decoded.txt"
done \
| awk '
{
  callsign=$7
  this_snr=$3
  if (lines[callsign] == "" || snr[callsign] < this_snr) {
    lines[callsign] = $0;
    snr[callsign] = this_snr;
  }
}
END {
  for (callsign in lines) {
    print lines[callsign];
  }
}' \
| sort -k 7 \
> decoded.txt
test -z "$QUIET" && echo "decoded.txt:"
test -z "$QUIET" && cat decoded.txt

# TODO: post-process decoded.txt into wspr_spots.txt format?
# e.g.
# ------------------------------------------------------------------------------
# _47420 _usb   7   1    0.3    0.001447 K0KE DM79 33            0        1     0
# _47420 _usb   1 -26    0.2    0.001502 AC7GZ DM43 23           0     7068    32
# ------ ---- --- ---   ----  ---------- ---------------------- --    -----  ----
# %6s    %4s  %3d %3.0f %4.1f %10.6f     %-22s                  %2d   %5u    %4d
# date   time sync snr  dt    freq       message                drift cycles jitter
# $1     $2   $3   $4   $5    $6         $7                     $8    $9     $10

# Take the date from the FIRST input filename
# Assuming filename format begins with e.g.:
# 20201016T060800Z
# CCYYMMDDTHHMMSSZ
# ... we snip off the century digits and take YYMMDD "201016"
FILEDATE=$(echo "$FIRSTFILENAME" | sed -e 's/^..\(......\).*$/\1/')

test -r wspr_spots.txt && rm -f wspr_spots.txt
cat decoded.txt \
| awk -v date=$FILEDATE -v drift=$DRIFT -v cycles=$CYCLES -v jitter=$JITTER '
{
  time=$1;
  sync=$2;
  snr=$3;
  dt=$4;
  audiofreq=$5;
  alwayszero=$6;
  callsign=$7;
  grid=$8;
  txpower=$9;
  alwaysFST4=$10;

  # Thi format string matches that in the wsprd source code:
  printf("%6s %4s %3d %3.0f %4.1f %10.6f %-22s %2d %5u %4d\n",
         date,
         time,
         sync,
         snr,
         dt,
         audiofreq / 1000000,           # <---  THIS IS WRONG
         callsign " " grid " " txpower,
         drift,
         cycles,
         jitter);
}
' \
> wspr_spots.txt
test -z "$QUIET" && echo "wspr_spots.txt:"
test -z "$QUIET" && cat wspr_spots.txt

exit 0
