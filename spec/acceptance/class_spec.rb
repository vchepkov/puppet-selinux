require 'spec_helper_acceptance'

describe 'selinux class' do
  let(:pp) do
    <<-EOS
      class { 'selinux': mode => 'enforcing' }

      selinux::boolean { 'puppet_selinux_test_policy_bool': }

      selinux::permissive { 'puppet_selinux_test_policy_t': }

      selinux::port { 'puppet_selinux_test_policy_port_t/tcp':
        seltype => 'puppet_selinux_test_policy_port_t',
        port => 55555,
        protocol => 'tcp',
      }

      # with puppet4 I would use a HERE DOC to make this pretty,
      # but with puppet3 it's not possible.
      selinux::module { 'puppet_selinux_test_policy':
        content => "policy_module(puppet_selinux_test_policy, 1.0.0)\ngen_tunable(puppet_selinux_test_policy_bool, false)\ntype puppet_selinux_test_policy_t;\ntype puppet_selinux_test_policy_exec_t;\ninit_daemon_domain(puppet_selinux_test_policy_t, puppet_selinux_test_policy_exec_t)\ntype puppet_selinux_test_policy_port_t;\ncorenet_port(puppet_selinux_test_policy_port_t)\n",
        prefix => '',
        syncversion => undef,
      }

      Class['selinux'] ->

      file { '/tmp/test_selinux_fcontext':
        content => 'TEST',
        seltype => 'puppet_selinux_test_policy_exec_t',
      }

      selinux::fcontext {'/tmp/fcontexts_source(/.*)?':
        seltype => 'puppet_selinux_test_policy_exec_t',
      }

      selinux::fcontext::equivalence {'/tmp/fcontexts_equivalent':
        target => '/tmp/fcontexts_source',
      }

      file {['/tmp/fcontexts_source', '/tmp/fcontexts_equivalent']:
        ensure => 'directory',
        require => [Selinux::Fcontext['/tmp/fcontexts_source(/.*)?'], Selinux::Fcontext::Equivalence['/tmp/fcontexts_equivalent']],
      }

      file {['/tmp/fcontexts_source/define_test', '/tmp/fcontexts_equivalent/define_test']:
        ensure  => file,
        notify  => Exec["/sbin/restorecon -FR /tmp/fcontexts_*"]
      }
      exec {'/sbin/restorecon -FR /tmp/fcontexts_*':
      # this is needed because puppet creates files with the wrong context as
      # it runs unconfined and only becomes idempotent after the second run.
        refreshonly => true,
      }

      # test purging
      resources {['selinux_fcontext', 'selinux_fcontext_equivalence']: purge => true }

    EOS
  end

  # We should really add something for it to purge, but we can't because
  # semanage doesn't even exist at the start. maybe a separate spec run after this?

  it_behaves_like 'a idempotent resource'

  describe package('selinux-policy-targeted') do
    it { is_expected.to be_installed }
  end

  describe file('/etc/selinux/config') do
    its(:content) { is_expected.to match(%r{^SELINUX=enforcing$}) }
  end

  describe command('getenforce') do
    its(:stdout) { is_expected.to match(%r{^Enforcing$}) }
  end

  context 'the test module source should exist and the module should be loaded' do
    describe file('/usr/share/selinux/puppet_selinux_test_policy.te') do
      it { is_expected.to be_file }
    end

    describe command('semodule -l | grep puppet_selinux_test_policy') do
      its(:stdout) { is_expected.to match(%r{puppet_selinux_test_policy}) }
    end
  end

  context 'the test file should have the specified file context' do
    describe file('/tmp/test_selinux_fcontext') do
      its(:selinux_label) { is_expected.to match(%r{^.*:puppet_selinux_test_policy_exec_t:s0$}) }
    end
  end

  context 'the define test directory should have the specified file context' do
    describe file('/tmp/fcontexts_source/define_test') do
      its(:selinux_label) { is_expected.to match(%r{^.*:puppet_selinux_test_policy_exec_t:s0$}) }
    end
  end

  context 'the define equivalence test directory should have the same file context' do
    describe file('/tmp/fcontexts_equivalent/define_test') do
      its(:selinux_label) { is_expected.to match(%r{^.*:puppet_selinux_test_policy_exec_t:s0$}) }
    end
  end

  context 'test boolean is available and activated' do
    describe command('getsebool puppet_selinux_test_policy_bool') do
      its(:stdout) { is_expected.to match(%r{puppet_selinux_test_policy_bool --> on}) }
    end
  end

  context 'test domain is permissive' do
    describe command('semanage permissive -l') do
      its(:stdout) { is_expected.to match(%r{^puppet_selinux_test_policy_t$}) }
    end
  end

  context 'port 55555 should have type puppet_selinux_test_policy_port_t' do
    describe command('semanage port -l | grep puppet_selinux_test_policy_port_t') do
      its(:stdout) { is_expected.to match(%r{puppet_selinux_test_policy_port_t.*55555$}) }
    end
  end
end