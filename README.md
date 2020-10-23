# Outline

jt9_stepper.bash is a simple script inspired by
[Clint's blog](http://ka7oei.blogspot.com/2020/10/using-jt9-executable-to-receive-fst4w.html)

It's a work in progress; caveat emptor. :-)

It runs the jt9 program (presumed to be in `$PATH`) multiple times
across a specified range of frequencies (default 1420 to 1580 with a
step size of 40).

It collates the resulting outputs and writes the strongest signal for each
callsign to decoded.txt.

Once the decoded.txt file has been written, the script reformats the
output into a wspr_spots.txt file.  The date written into this file
file is taken from the YYMMDD portion of the first input filename,
which is presumed to begin with "`CCYYMMDDTHHMMSSZ...`".

The script has been exercised only on ubuntu 20.04 (docker container)
and on mac/HighSierra.

The resulting wspr_spots.txt file currently has a few problems
relating to unknown values:

First, as mentioned in Clint's blog post (linked above), the script
doesn't know the carrier frequency.  The script currently writes
(audiofreq/1E6) because it knows not what better to do here.

Second, the script does not possess values for the drift, cycles, and
jitter output fields.  The script writes zeroes for those output
fields unless you give other values with the `-d`, `-c`, and `-j`
command-line options respectively.

One possible immediate improvement might be to add another
command-line option to specify the carrier frequency.  If this avenue
is pursued, we'd need to figure out how the given carrier frequency
value should be combined, if at all, with the jt9's output audio
frequency in order to generate the output carrier frequency in the
wspr spots file.

Run the script with the `-h` command-line option to see usage info.


## Sample runs

Here are some sample runs that show how the double-dash command-line
option (`--`) is used to separate script options from jt9 options.

### Example 1: no script options

This example uses jt9 command-line options but no script command-line
options.  The **mandatory** double-dash says "end of script options";
everything after that is passed to jt9.

```
$ ./jt9_stepper.bash -- -W -p 120 20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1420 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1460 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1500 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1540 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1580 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
0000   9  0.2 1573 `  KA7OEI DN40 17                                  
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   1
decoded.txt:
0000   0    9   0.2   1573.   0   KA7OEI DN40 17                        FST4
wspr_spots.txt:
201016 0000   0   9  0.2   0.001573 KA7OEI DN40 17          0     0    0
```

### Example 2: values to pass through to wspr_spots.txt

This example specifies values for the drift, cycles, and jitter
output fields.  The given values are passed unchanged to the
wspr_spots.txt file.  Note how the script options come before the
double-dash; the jt9 options come after.

```
$ ./jt9_stepper.bash -d 12 -c 12345 -j 1234 -- -W -p 120 20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1420 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1460 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1500 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1540 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1580 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
0000   9  0.2 1573 `  KA7OEI DN40 17                                  
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   1
decoded.txt:
0000   0    9   0.2   1573.   0   KA7OEI DN40 17                        FST4
wspr_spots.txt:
201016 0000   0   9  0.2   0.001573 KA7OEI DN40 17         12 12345 1234
```

### Example 3: shorter step

This example specifies a nondefault step value (10 vs the default 40,
the latter having been taken from the example in Clint's blog).
Because a narrower step is used, three of the jt9 subprograms find
callsign matches with varying signal strengths.  Only the
strongest SNR (11) is written to the decoded.txt and wspr_spots.txt
output files.

```
$ ./jt9_stepper.bash -s 10 -d 12 -c 12345 -j 1234 -- -W -p 120 20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1420 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1430 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1440 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1450 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1460 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1470 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1480 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1490 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1500 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1510 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1520 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1530 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1540 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1550 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1560 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1570 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
nice jt9 -f 1580 -W -p 120 ../20201016T060800Z_474200_usb.in.wav
0000  11  0.2 1573 `  KA7OEI DN40 17                                  
0000   9  0.2 1573 `  KA7OEI DN40 17                                  
0000  10  0.2 1573 `  KA7OEI DN40 17                                  
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   0
<DecodeFinished>   0   1
<DecodeFinished>   0   1
<DecodeFinished>   0   1
decoded.txt:
0000   0   11   0.2   1573.   0   KA7OEI DN40 17                        FST4
wspr_spots.txt:
201016 0000   0  11  0.2   0.001573 KA7OEI DN40 17         12 12345 1234
```

### Quiet:

When you tire of the chatty output, use -q to tone it down.  When the
script is done, you'll have to examine the output file yourself.

```
$ ./jt9_stepper.bash -q -s 10 -d 12 -c 12345 -j 1234 -- -W -p 120 20201016T060800Z_474200_usb.in.wav

$ cat wspr_spots.txt
201016 0000   0  11  0.2   0.001573 KA7OEI DN40 17         12 12345 1234
```
