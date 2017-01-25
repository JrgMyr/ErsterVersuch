#!perl -w
# chktree.pl
# My 2004-04-22, 2006-01-15, 2010-10-18, 2017-01-25

# use bigint;
# Einsatz von "bigint" fuehrte zu Fehlern!

$PROGRAM   = 'chktree.pl';
$VERSION   = 'v0.50';
$DESCRPT   = '';

$STARTPFAD = '';
@STARTAUSW = ();
@IGNORAUSW = ();
$IGNORNEXT = 0;
$REGEXNEXT = 0;
$RECURS    = 1;
$AUSWTIEFE = 1;
$DISPDIAG  = 0;
$ONEDAY    = 24 * 3600;
$trenn     = ' - ';

if (@ARGV == 0) {
    print $PROGRAM, ": Kein Startpfad angegeben.\n";
    exit;
}

sub usage {
    print 'Usage: ', $PROGRAM, " [Parameter] Startpfad [Startauswahl] [-s SkipDir]\n\n",
          "Parameter:\n",
          "\t-1\tNur ein Verzeichnis tief anzeigen (Vorgabe)\n",
          "\t-2\tZwei Verzeichnisse tief anzeigen\n",
          "\t-3\tDrei Verzeichnisse tief anzeigen\n",
          "\t-4\tVier Verzeichnisse tief anzeigen\n",
          "\t-5\tFuenf Verzeichnisse tief anzeigen\n",
          "\t-e\tWeitere Angaben sind regulaere Ausdruecke\n",
          "\t-h\tHilfeseite anzeigen\n",
          "\t-i\tMuster zum Ignorieren\n",
          "\t-n\tNicht rekursiv\n",
          "\t-p\tDiagnose-Parameter anzeigen\n",
          "\t-r\trekursiv (Vorgabe)\n",
          "\t-v\tVersion anzeigen\n",
          "\t-w\tWeitere Angaben sind BS-Wildcards (Vorgabe)\n";
    exit;
}

sub version {
    print $PROGRAM, $trenn, $VERSION, "\n",
          $DESCRPT, "\n";
    exit;
}

sub formint {
    my $t = shift;

    if ($t > 1000) {
        $t =~ s/(.+)(...)$/$1.$2/;
    }

    return $t;
}

sub formsize {
    my $t = shift;

    if ($t == 0) {
        return '0';
    }
    elsif ($t < 1024) {
        return '< 1';
    }
    else {
        $t += 500;
        $t >>= 10;
        $t =~ s/(.+)(...)$/$1.$2/;
        return $t;
    }

}

sub ScanDir {

    opendir VERZ, '.';
    my @liste = sort { lc $a cmp lc $b } readdir VERZ;
    closedir VERZ;
    $dircount++;
    shift @liste if $liste[0] eq '.';
    shift @liste if $liste[0] eq '..';

    if ($tiefe == 0 && scalar(@STARTAUSW) > 0) {
        my @neueliste = ();

        foreach $eintrag (@liste) {
            $ok = 0;
            foreach $muster (@STARTAUSW) {
                $ok = 1 if $eintrag =~ m/$muster/;
            }
            push @neueliste, $eintrag if $ok;
        }

        @liste = @neueliste;
    }

    print '(', $tiefe, ':', scalar @liste, ') '
        if $DISPDIAG;

    foreach $eintrag (@liste) {
        if (-f $eintrag) {

            $filecount++;
            $dt = $^T - $ONEDAY * (-M $eintrag);
#           $mindt = $dt if $dt < $mindt;
            $maxdt = $dt if $dt > $maxdt;
            $fsize = (500 + -s $eintrag) >> 10;        # Speichern in gerundeten Kilobytes, sonst Ueberlauf bei 4 GB
            $sizesum += $fsize;
            $maxsize = $fsize if $fsize > $maxsize;
        }
    }

    if ($RECURS) {
        foreach $eintrag (@liste) {
            if (-d $eintrag) {
                next if ($eintrag eq '.') || ($eintrag eq '..');
                # eigentlich jetzt redundant, aber schad't nicht...

                $raus = 0;
                foreach $muster (@IGNORAUSW) {
                    $raus = 1 if $eintrag =~ m/$muster/;
                }

                if ($raus) {
                    $ignorecount++;
                    next;
                }

                push @dirstack, $eintrag;

                if (chdir $eintrag) {
                    $tiefe++;
                    $maxtiefe = $tiefe if $tiefe > $maxtiefe;
                    $ttlmaxtiefe = $tiefe if $tiefe > $ttlmaxtiefe;

                    if ($tiefe <= $AUSWTIEFE) {
                        push @maxdatestack, $maxdt;
                        $maxdt = 0;

                        push @sizestack, $sizesum;
                        $sizesum = 0;

                        push @maxsizestack, $maxsize;
                        $maxsize = 0;

                        push @maxdepthstack, $maxtiefe;
                        $maxtiefe = 0;  #  Eigentlich sollte hier nichts zurueckgesetzt werden!
                                        #  Klappt aber nur so richtig!

                        push @dircountstack, $dircount;
                        $dircount = 0;

                        push @filecountstack, $filecount;
                        $filecount = 0;
                    }

                    &ScanDir;

                    if ($tiefe <= $AUSWTIEFE) {
                        (undef, undef, undef, $day, $mon, $year,
                         undef, undef, undef) = localtime($maxdt);

                        print "\n" if $DISPDIAG;

                        printf "%02d.%02d.%d%7s%7s%9s%8s MB%9s MB  %s\n",
                               $day, $mon+1, $year+1900,
                               &formint($dircount-1),
                               &formint($maxtiefe),
                               &formint($filecount),
                               &formsize($maxsize),
                               &formsize($sizesum),
                               join('/', @dirstack);

                        $tmp = pop @maxdatestack;
                        $maxdt = $tmp if $tmp > $maxdt;

                        $sizesum += pop @sizestack;

                        $tmp = pop @maxsizestack;
                        $maxsize = $tmp if $tmp > $maxsize;

                        $tmp = pop @maxdepthstack;  
                        $maxtiefe = $tmp if $tmp > $maxtiefe;

                        $dircount += pop @dircountstack;

                        $filecount += pop @filecountstack;
                    }

                    print "\n" if $tiefe == 1 && $AUSWTIEFE > 1;

                    $tiefe--;
                    chdir '..';
                }
                else {
                    print "Verzeichnis $eintrag nicht zugaenglich!.\n";
                    $errorcount++;
                }

                pop @dirstack;
            }
        }
    }
    return 1;
}

print $PROGRAM, $trenn, $VERSION, "\n\n";

foreach (@ARGV) {
    if (substr($_, 0, 1) eq '-') {
        m/1/ && ($AUSWTIEFE = 1);
        m/2/ && ($AUSWTIEFE = 2);
        m/3/ && ($AUSWTIEFE = 3);
        m/4/ && ($AUSWTIEFE = 4);
        m/5/ && ($AUSWTIEFE = 5);
        m/e/ && ($REGEXNEXT = 1);
        m/h|\?/ && &usage();
        m/i/ && ($IGNORNEXT = 1);
        m/n/ && ($RECURS    = 0);
        m/p/ && ($DISPDIAG  = 1);
        m/r/ && ($RECURS    = 1);
        m/v/ && &version();
        m/w/ && ($REGEXNEXT = 0);
    }
    else {
        if ($STARTPFAD eq '' && $IGNORNEXT == 0) {
            $STARTPFAD = $_; }
        else {
            if ($REGEXNEXT == 0) {
                s/\?/./g;
                s/\*/.*/g;
                $_ = '^'.$_.'$';
            }

            if ($IGNORNEXT) {
                push @IGNORAUSW, $_;
            }
            else {
                push @STARTAUSW, $_;
            }
        }
    }
}

print $STARTPFAD ne '' ? 'Untersuche ' . $STARTPFAD : '',
      $STARTPFAD ne '' && $AUSWTIEFE != 1 ? ', ' : '',
      $AUSWTIEFE != 1 ? 'Ausweistiefe ist ' . $AUSWTIEFE : '',
      $STARTPFAD ne '' || $AUSWTIEFE != 1 ? "\n" : '';

print 'Startauswahl ist ', join(', ', @STARTAUSW), "\n" if scalar @STARTAUSW;
print 'Zu ignorieren sind ', join(', ', @IGNORAUSW), "\n" if scalar @IGNORAUSW;
print "\n" if $STARTPFAD ne '' || $AUSWTIEFE != 1 || scalar(@STARTAUSW) + scalar(@IGNORAUSW) != 0;


if ($STARTPFAD eq '') {
    $STARTPFAD = '.';
}
else {
    die "$STARTPFAD ist kein Verzeichnis!\n" unless -d $STARTPFAD;
    chdir($STARTPFAD) || die "Kann nicht nach $STARTPFAD wechseln!\n";
}

$tiefe = $maxtiefe = $maxdt = $sizesum = $maxsize = $ttlmaxtiefe = 0;
@dirstack = ();
@maxdatestack = ();
@sizestack = ();
@maxsizestack = ();
@depthstack = ();
@dircountstack = ();
@filecountstack = ();
$dircount = $filecount = $errorcount = $ignorecount = 0;

print "Ltzt.Datei  Anz.U  Max.T  Anz.Dat  Grsst.Dat  Ges.Vol.    Verzeichnis\n",
      "----------  -----  -----  -------  ---------  ----------  -----------\n";

&ScanDir;

print "----------  -----  -----  -------  ---------  ----------  -----------\n";

(undef, undef, undef, $day, $mon, $year,
 undef, undef, undef) = localtime($maxdt);

printf "%02d.%02d.%d%7s%7s%9s%8s MB%9s MB  %s\n",
       $day, $mon+1, $year+1900,
       &formint($dircount),
       &formint($ttlmaxtiefe),
       &formint($filecount),
       &formsize($maxsize),
       &formsize($sizesum),
       '(Gesamt)';

print "Es sind $errorcount Fehler aufgetreten!\n" if $errorcount;
print "Es wurden $ignorecount Eintraege ignoriert!\n" if $ignorecount;
print "Fertig.\n";
