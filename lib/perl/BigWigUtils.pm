package BigWigUtils;

use strict;
use Exporter;
use File::Copy;
use File::Basename;
use DBI;
use JSON qw( );
our @ISA = 'Exporter';
our @EXPORT = qw(installBwFile validateBwFile validateBwSequences validationError getRefGenome);

my $VALIDATION_ERROR_CODE = 99;

sub installBwFile {
  my ($origBwFile, $dataFilesDir, $dbh, $orgNameForFiles) = @_;

  validateBwSequences($origBwFile, $orgNameForFiles, $dbh);
  
  # .bw extension needed for jbrowse
  my $bwFile = basename($origBwFile);
  $bwFile =~ s/\.bigwig$/.bw/;
  $bwFile = ($bwFile =~ /\.bw$/) ? $bwFile : "$bwFile.bw";
  print STDERR "Copying file '$origBwFile' to '$dataFilesDir/$bwFile'\n";
  copy($origBwFile, "$dataFilesDir/$bwFile") or die "Copy of '$origBwFile' to '$dataFilesDir/$bwFile' failed: $!";
  chmod(0664, "$dataFilesDir/$bwFile") or die "Could not chmod $dataFilesDir/$bwFile\n";
}

sub validateBwFile {
  my ($filePath) = @_;
  my $fileName = basename($filePath);
  validationError("Invalid bigwig file: $fileName") if system("isbigwig $filePath");
  my $sz =  -s $filePath;
  return validationError("Bigwig file too big (> 500M): $fileName ($sz)") if ($sz > (500 * 1024 * 1024));
}

sub validateBwSequences {
  my ($filePath, $orgNameForFiles, $dbh) = @_;

  my $sql = "
select s.source_id
from apidbtuning.genomicseqattributes s, apidbtuning.organismattributes o
where o.name_for_filenames = ?
and o.internal_abbrev = s.org_abbrev
";

  my %knownIds;
  my $stmt = $dbh->prepare($sql);
  $stmt->execute($orgNameForFiles);
  while (my ($sourceid) = $stmt->fetchrow_array()) {
    $knownIds{$sourceid} = 1;
  }
  $stmt->finish();

  die "Database contains no sequence IDs for $orgNameForFiles\n" unless keys %knownIds;

  my $count = 0;
  my @unfoundIds;
  open(CMD, "bigwigSequenceIds $filePath |") or die "couldn't open bigwigSequenceIds: $!";
  while(<CMD>) {
    chomp;
    push(@unfoundIds, $_) unless $knownIds{$_};
    $count += 1;
  }

  my $fileName = basename($filePath);

  validationError("bigWig file $fileName contains no sequence IDs") unless $count;

  my @examples = @unfoundIds > 10 ? @unfoundIds[0..4] : @unfoundIds;
  my $uCount = @unfoundIds;
  return validationError("bigWig file $fileName contains $uCount of $count IDs that do not match our version of $orgNameForFiles. For example: " . join(",", @examples) .". Seems like the wrong genome.") if $uCount > ($count * .2);
}


# return the orgNameForFiles of the genome declared as a dependency
sub getRefGenome {
  my ($metaJsonFile) = @_;

  my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", $metaJsonFile)
      or die("Can't open \"$metaJsonFile\": $!\n");
    local $/;
    <$json_fh>
  };

  my $json = JSON->new;
  my $metadata = $json->decode($json_text);

  my $dependencies = $metadata->{dependencies};

  validationError("More than one reference genome") if (@$dependencies != 1);

  my $genomeIdentifier = $dependencies->[0]->{resourceIdentifier};

  # extract org name from eg PlasmoDB-51_Pfalciparum3D7_Genome
  $genomeIdentifier =~ /^[A-Za-z]+-\d+_(.+)_Genome/ || validationError("Invalid genome resource format: $genomeIdentifier");
  my $orgNameForFiles = $1;
  return $orgNameForFiles;
}

sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERROR_CODE);
}

1;
