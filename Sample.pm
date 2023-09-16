package Sample;

use strict;
use warnings;
our $VERSION = '0.01';

use FindBin;
use lib "$FindBin::Bin";
use TestData;
use Tie::IxHash;
use Carp 'croak';

use Data::Dumper;

my $test_data = $TestData::hash;
warn Dumper $test_data;

my $key_order_fixed = __PACKAGE__->clone_to_key_order_fixed_object(data => $test_data);
print "###### Fixed Order ===\n";
warn Dumper $key_order_fixed;

sub clone_to_key_order_fixed_object{
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $get_type = sub{
        my $obj = shift;
        my $t = ref($obj);
        return '' unless $t;
        return $t if &_is_hash($t);
        return $t if &_is_array($t);
        return $t if $t eq 'JSON::PP::Boolean';
        croak 'can not be processed.';
    };

    my $clone = sub{
        my $this = shift; 
        my $data = shift;

        my $type = $get_type->($data);
        return $data unless $type;

        my $ret;
        if(&_is_hash($type)){
            my @keys = sort keys %{$data};
            unless(@keys){
                $ret = {};
            }
            else{
                tie my %fix_hash, 'Tie::IxHash';
                for my $k (@keys){
                    my $type = $get_type->($data->{$k});
                    if(&_is_hash($type)){
                        $fix_hash{$k}  = $this->($this,$data->{$k});
                        next;
                    }
                    elsif(&_is_array($type)){
                        $fix_hash{$k} = $this->($this,$data->{$k});
                        next;
                    }
                    $fix_hash{$k} = $data->{$k};
                }
                $ret = \%fix_hash;
            }
        }       
        elsif(&_is_array($type)){
            my @array = ();
            for my $d (@{$data}){
                my $type = $get_type->($d);
                if(&_is_hash($type)){
                    push @array, $this->($this,$d);
                    next;
                }
                elsif(&_is_array($type)){
                    push @array, $this->($this,$d);
                    next;
                } 
                push @array, $d;
            }
            $ret = \@array;
        }
        return $ret;
    };

    my $fixed;
    eval{
        $fixed = $clone->($clone, $args{data});
    };
    if($@){
        croak $@;
    }
    return $fixed;
} 

sub _is_hash  { $_[0] eq 'HASH'  ? 1 : 0; }

sub _is_array { $_[0] eq 'ARRAY' ? 1 : 0; }

1;
__END__
