# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tem_ruby}
  s.version = "0.11.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Victor Costan"]
  s.date = %q{2009-11-01}
  s.description = %q{TEM (Trusted Execution Module) driver, written in and for ruby.}
  s.email = %q{victor@costan.us}
  s.executables = ["tem_bench", "tem_ca", "tem_irb", "tem_proxy", "tem_stat", "tem_upload_fw"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README", "bin/tem_bench", "bin/tem_ca", "bin/tem_irb", "bin/tem_proxy", "bin/tem_stat", "bin/tem_upload_fw", "lib/tem/_cert.rb", "lib/tem/apdus/buffers.rb", "lib/tem/apdus/keys.rb", "lib/tem/apdus/lifecycle.rb", "lib/tem/apdus/tag.rb", "lib/tem/auto_conf.rb", "lib/tem/benchmarks/benchmarks.rb", "lib/tem/benchmarks/blank_bound_secpack.rb", "lib/tem/benchmarks/blank_sec.rb", "lib/tem/benchmarks/devchip_decrypt.rb", "lib/tem/benchmarks/post_buffer.rb", "lib/tem/benchmarks/simple_apdu.rb", "lib/tem/benchmarks/vm_perf.rb", "lib/tem/benchmarks/vm_perf_bound.rb", "lib/tem/builders/abi.rb", "lib/tem/builders/assembler.rb", "lib/tem/builders/crypto.rb", "lib/tem/builders/isa.rb", "lib/tem/ca.rb", "lib/tem/definitions/abi.rb", "lib/tem/definitions/assembler.rb", "lib/tem/definitions/isa.rb", "lib/tem/ecert.rb", "lib/tem/firmware/tc.cap", "lib/tem/firmware/uploader.rb", "lib/tem/hive.rb", "lib/tem/keys/asymmetric.rb", "lib/tem/keys/key.rb", "lib/tem/keys/symmetric.rb", "lib/tem/sec_exec_error.rb", "lib/tem/seclosures.rb", "lib/tem/secpack.rb", "lib/tem/tem.rb", "lib/tem/toolkit.rb", "lib/tem_ruby.rb"]
  s.files = ["CHANGELOG", "LICENSE", "Manifest", "README", "Rakefile", "bin/tem_bench", "bin/tem_ca", "bin/tem_irb", "bin/tem_proxy", "bin/tem_stat", "bin/tem_upload_fw", "dev_ca/ca_cert.cer", "dev_ca/ca_cert.pem", "dev_ca/ca_key.pem", "dev_ca/config.yml", "lib/tem/_cert.rb", "lib/tem/apdus/buffers.rb", "lib/tem/apdus/keys.rb", "lib/tem/apdus/lifecycle.rb", "lib/tem/apdus/tag.rb", "lib/tem/auto_conf.rb", "lib/tem/benchmarks/benchmarks.rb", "lib/tem/benchmarks/blank_bound_secpack.rb", "lib/tem/benchmarks/blank_sec.rb", "lib/tem/benchmarks/devchip_decrypt.rb", "lib/tem/benchmarks/post_buffer.rb", "lib/tem/benchmarks/simple_apdu.rb", "lib/tem/benchmarks/vm_perf.rb", "lib/tem/benchmarks/vm_perf_bound.rb", "lib/tem/builders/abi.rb", "lib/tem/builders/assembler.rb", "lib/tem/builders/crypto.rb", "lib/tem/builders/isa.rb", "lib/tem/ca.rb", "lib/tem/definitions/abi.rb", "lib/tem/definitions/assembler.rb", "lib/tem/definitions/isa.rb", "lib/tem/ecert.rb", "lib/tem/firmware/tc.cap", "lib/tem/firmware/uploader.rb", "lib/tem/hive.rb", "lib/tem/keys/asymmetric.rb", "lib/tem/keys/key.rb", "lib/tem/keys/symmetric.rb", "lib/tem/sec_exec_error.rb", "lib/tem/seclosures.rb", "lib/tem/secpack.rb", "lib/tem/tem.rb", "lib/tem/toolkit.rb", "lib/tem_ruby.rb", "tem_ruby.gemspec", "test/_test_cert.rb", "test/builders/test_abi_builder.rb", "test/firmware/test_uploader.rb", "test/tem_test_case.rb", "test/tem_unit/test_tem_alu.rb", "test/tem_unit/test_tem_bound_secpack.rb", "test/tem_unit/test_tem_branching.rb", "test/tem_unit/test_tem_crypto_asymmetric.rb", "test/tem_unit/test_tem_crypto_hash.rb", "test/tem_unit/test_tem_crypto_pstore.rb", "test/tem_unit/test_tem_crypto_random.rb", "test/tem_unit/test_tem_emit.rb", "test/tem_unit/test_tem_memory.rb", "test/tem_unit/test_tem_memory_compare.rb", "test/tem_unit/test_tem_output.rb", "test/tem_unit/test_tem_yaml_secpack.rb", "test/test_auto_conf.rb", "test/test_driver.rb", "test/test_exceptions.rb"]
  s.homepage = %q{http://tem.rubyforge.org}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Tem_ruby", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{tem}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{TEM (Trusted Execution Module) driver, written in and for ruby.}
  s.test_files = ["test/builders/test_abi_builder.rb", "test/firmware/test_uploader.rb", "test/tem_unit/test_tem_alu.rb", "test/tem_unit/test_tem_bound_secpack.rb", "test/tem_unit/test_tem_branching.rb", "test/tem_unit/test_tem_crypto_asymmetric.rb", "test/tem_unit/test_tem_crypto_hash.rb", "test/tem_unit/test_tem_crypto_pstore.rb", "test/tem_unit/test_tem_crypto_random.rb", "test/tem_unit/test_tem_emit.rb", "test/tem_unit/test_tem_memory.rb", "test/tem_unit/test_tem_memory_compare.rb", "test/tem_unit/test_tem_output.rb", "test/tem_unit/test_tem_yaml_secpack.rb", "test/test_auto_conf.rb", "test/test_driver.rb", "test/test_exceptions.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<smartcard>, [">= 0.4.6"])
    else
      s.add_dependency(%q<smartcard>, [">= 0.4.6"])
    end
  else
    s.add_dependency(%q<smartcard>, [">= 0.4.6"])
  end
end
