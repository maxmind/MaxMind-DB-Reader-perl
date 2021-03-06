requires "Carp" => "0";
requires "Data::IEEE754" => "0";
requires "Data::Printer" => "0";
requires "Data::Validate::IP" => "0.25";
requires "DateTime" => "0";
requires "Encode" => "0";
requires "Getopt::Long" => "0";
requires "List::AllUtils" => "0";
requires "Math::BigInt" => "0";
requires "MaxMind::DB::Common" => "0.040001";
requires "MaxMind::DB::Metadata" => "0";
requires "MaxMind::DB::Role::Debugs" => "0";
requires "MaxMind::DB::Types" => "0";
requires "Module::Implementation" => "0";
requires "Moo" => "1.003000";
requires "Moo::Role" => "0";
requires "MooX::StrictConstructor" => "0";
requires "Role::Tiny" => "1.003002";
requires "Socket" => "1.87";
requires "autodie" => "0";
requires "bytes" => "0";
requires "constant" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010000";
requires "strict" => "0";
requires "warnings" => "0";
suggests "MaxMind::DB::Reader::XS" => "1.000003";

on 'test' => sub {
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Path::Class" => "0.27";
  requires "Scalar::Util" => "1.42";
  requires "Test::Bits" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::MaxMind::DB::Common::Data" => "0";
  requires "Test::MaxMind::DB::Common::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Number::Delta" => "0";
  requires "Test::Requires" => "0";
  requires "lib" => "0";
  requires "utf8" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Code::TidyAll::Plugin::Test::Vars" => "0.02";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Math::Int128" => "0";
  requires "Net::Works" => "0";
  requires "Parallel::ForkManager" => "1.19";
  requires "Perl::Critic" => "1.126";
  requires "Perl::Tidy" => "20190601";
  requires "Pod::Coverage::Moose" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta::JSON" => "0.16";
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.96";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
  requires "Test::Vars" => "0.009";
  requires "Test::Version" => "2.05";
  requires "parent" => "0";
};
