=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::ImageConfig::MultiTop;

use strict;


sub init {
  my $self = shift;
  
  $self->set_parameters({
    sortable_tracks  => 1,     # allow the user to reorder tracks
    opt_empty_tracks => 0,     # include empty tracks
    opt_lines        => 1,     # draw registry lines
  });
## EG - ENSEMBL-3644
  my $site = $SiteDefs::ENSEMBL_SITETYPE =~ s/Ensembl //r; #/
  my $sp_img_48 = $self->species_defs->ENSEMBL_SERVERROOT . '/eg-web-' . lc($site) . '/htdocs/i/species/48'; 
##  
  if(-e $sp_img_48) {
    $self->set_parameters({ spritelib => {
      %{$self->get_parameter('spritelib')||{}},
      species => $sp_img_48,
    }});
  }

  $self->create_menus(qw(
    sequence
    marker
    transcript
    synteny
    decorations
    information
  ));

  my $gencode_version = $self->hub->species_defs->GENCODE ? $self->hub->species_defs->GENCODE->{'version'} : '';
  $self->add_track('transcript', 'gencode', "Basic Gene Annotations from GENCODE $gencode_version", '_gencode', {
    labelcaption => "Genes (Basic set from GENCODE $gencode_version)",
    display     => 'off',
    description => 'The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).',
    sortable    => 1,
    colours     => $self->species_defs->colour('gene'),
    label_key  => '[biotype]',
    logic_names => ['proj_ensembl',  'proj_ncrna', 'proj_havana_ig_gene', 'havana_ig_gene', 'ensembl_havana_ig_gene', 'proj_ensembl_havana_lincrna', 'proj_havana', 'ensembl', 'mt_genbank_import', 'ensembl_havana_lincrna', 'proj_ensembl_havana_ig_gene', 'ncrna', 'assembly_patch_ensembl', 'ensembl_havana_gene', 'ensembl_lincrna', 'proj_ensembl_havana_gene', 'havana'],
    renderers   =>  [
      'off',                     'Off',
      'gene_nolabel',            'No exon structure without labels',
      'gene_label',              'No exon structure with labels',
      'transcript_nolabel',      'Expanded without labels',
      'transcript_label',        'Expanded with labels',
      'collapsed_nolabel',       'Collapsed without labels',
      'collapsed_label',         'Collapsed with labels',
      'transcript_label_coding', 'Coding transcripts only (in coding genes)',
    ],
  }) if($gencode_version);
    
  $self->add_track('sequence',    'contig', 'Contigs',     'contig', { display => 'normal', strand => 'f' });
  $self->add_track('information', 'info',   'Information', 'text',            { display => 'normal' });
  
  $self->load_tracks;

  $self->add_tracks('decorations',
    [ 'scalebar',  '', 'scalebar',  { display => 'normal', strand => 'b', menu => 'no' }],
    [ 'ruler',     '', 'ruler',     { display => 'normal', strand => 'f', menu => 'no' }],
    [ 'draggable', '', 'draggable', { display => 'normal', strand => 'b', menu => 'no' }]
  );
  
  $self->modify_configs(
    [ 'transcript' ],
    { strand => 'r' }
  );
}

sub join_genes {
  my ($self, $chr, @slices) = @_;
  my ($ps, $pt, $ns, $nt) = map { $_->{'species'}, $_->{'target'} } @slices;
  my $sp         = $self->{'species'};
  my $sd         = $self->species_defs;
## EG
  my $hub = $self->hub;
  
  for (map { @{$hub->intra_species_alignments($_, $ps, $pt)}, @{$hub->intra_species_alignments($_, $ns, $nt)} } @{$sd->compara_like_databases}) {
    $self->set_parameter('homologue', $_->{'homologue'}) if $_->{'species'}{"$sp--$chr"};
  }
##
  
  foreach ($self->get_node('transcript')->nodes) {
    $_->set('previous_species', $ps) if $ps;
    $_->set('next_species',     $ns) if $ns;
    $_->set('previous_target',  $pt) if $pt;
    $_->set('next_target',      $nt) if $nt;
    $_->set('join', 1);
  }
}

1;
