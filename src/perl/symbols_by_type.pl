#!/usr/bin/perl
use strict;

use Getopt::Long;
use File::Basename;

### // foo.c 
### int i; /* common */ 
### int j=0; /* bss */ 
### int k=100; /* data */ 
### char *p=0; /* bss */ 
### char *s=""; /* data */ 
### static double PI = 3.1415926; /* data */ 
### extern long x; /* no symbol */ 
### void foo() { /* text */ 
###     return; 
### } 
### 
### // bar.c 
### void bar1() { /* text */ 
###     return; 
### } 
### 
### static void bar2(void) { /* text */ 
###     return; 
### } 
### 
### extern void foo(void); /* no symbol */ 
### extern void undefined(void); /* no symbol */ 
### void bar3() { /* text */ 
###     foo(); 
###     undefined(); 
### } 
### 
### > ar rcs test.a foo.o bar.o 
### > nm -C test.a # IT'S NOT EASY TO FIND OUT THAT 'foo' IS A DEFINED SYMBOL IN test.a, HOWEVER IT IS UNDEFINED IN bar.o.
###   
### 
###  
### > perl symbols_by_type.pl --help 
### -t, --symbol_type=type        Type of symbols [defined | undefined].                      
###  -f, --file=obj_file_path          Path of valid .o|.so|.a|... file.                           
###  -v, --version                         Get version of this toolkit.                                
###  -h, --help                             Show HOW-TO. 
### 
### > perl symbols_by_type.pl -t defined -f ./test.a 
### 0000000000000000        T       bar1 
### 0000000000000006        t       bar2 
### 000000000000000c        T       bar3 
### 0000000000000008        D       s 
### 0000000000000000        B       j 
### 0000000000000008        B       p 
### 0000000000000000        D       k 
### 0000000000000000        T       foo 
### 0000000000000010        d       PI 
### 0000000000000004        C       i 
### 
### > perl symbols_by_type.pl -t undefined -f ./test.a 
### U       undefined



#####################################################################
my $my_type = undef;
my $my_path = undef;
my ($defined, $undefined) = ("defined", "undefined");
GetOptions(
        "type|t:s"      => \$my_type,
        "file|f:s"      => \$my_path,
        "version|v!"    => sub {&print_version and exit(0)},
        'help!'         => sub {&print_version and &print_usage},
        ) or print_usage();
print("********* Please specify valid type! *********\n") and print_usage() if ! $my_type or ($my_type ne $defined and $my_type ne $undefined);
print("********* Please specify valid obj file path! *********\n") and exit(1) if ! $my_path;
die("********* Obj file specified by file option is not a UN-EMPTY & READABLE file! *********\n") 
    if ! -e $my_path or ! -r $my_path or ! -f $my_path or -z $my_path;

&main;

######################################################################
sub main
{
    my %symbols_dic = ();
    open(my $fp, "/usr/bin/nm -C " . $my_path . " | ") or die "$!";
    while (<$fp>) {
        chomp;
        # print "ERROR PARSING: $_\n" and next unless /([\w\s]+)\s+?([\w])\s+?(.+)/; 
        next unless /([\w\s]+)\s+?([\w])\s+?(.+)/;
        my ($symbol_value, $symbol_type, $symbol_name) = (my_trim($1), my_trim($2), my_trim($3));
        # print "$symbol_value, $symbol_type, $symbol_name\n";
        if (! exists $symbols_dic{$symbol_name}) {
            $symbols_dic{$symbol_name} = [];
            push @{$symbols_dic{$symbol_name}}, ($symbol_type, $symbol_value);
        } else {
            my $exist_symbol_type = @{$symbols_dic{$symbol_name}}[0];  
            if (uc $exist_symbol_type eq "U" and uc $symbol_type ne "U") {
                pop @{$symbols_dic{$symbol_name}};
                pop @{$symbols_dic{$symbol_name}};
                push @{$symbols_dic{$symbol_name}}, $symbol_type;
                push @{$symbols_dic{$symbol_name}}, $symbol_value;
            }
        }
    }

    foreach my $symbol_name (keys %symbols_dic) {
        my ($symbol_type, $symbol_value) = @{$symbols_dic{$symbol_name}};
        if (uc $my_type eq uc $defined) {
            next if uc $symbol_type eq "U"; 
            print "$symbol_value\t$symbol_type\t$symbol_name\n";
        } elsif (uc $my_type eq uc $undefined) {
            next unless uc $symbol_type eq "U";
            print "$symbol_value\t$symbol_type\t$symbol_name\n";
        }
    }

    close($fp);
    exit(0);
}

sub my_trim
{
    (my $str = $_[0]) =~ s/^\s+|\s+$//g;
    return $str;
}

sub print_version
{
    my $version = "v1.0";
    print "#######################################\n";
    print "##### Initial Version Authors    ######\n";
    print "##### <harryczhang\@tencent.com>  ######\n";
    print "##### Since Feb 2014             ######\n";
    print "#######################################\n";
    print basename($0) . ": Version $version\n"; 
    print "#######################################\n\n";
}

sub print_usage 
{
    my $info = [
        ["-t, --symbol_type=type"         =>   "Type of symbols [defined | undefined]."],
        ["-f, --file=obj_file_path"       =>   "Path of valid .o|.so|.a|... file."],
        ["-v, --version"                  =>   "Get version of this toolkit."],
        ["-h, --help"                     =>   "Show HOW-TO."],
        ];

    foreach(@$info) {
        printf("%-40s%-60s\n",$_->[0],$_->[1]);
    }

    exit(0);
}
