require 'spec_helper'

describe 'reprepro::update' do

  let :default_params do
    {
      :basedir     => '/var/packages',
      :name        => 'lenny-backports',
      :suite       => 'lenny',
      :repository  => 'dev',
      :url         => 'http://backports.debian.org/debian-backports',
      :filter_name => 'lenny-backports'
    }
  end

  context "With default params" do
    let(:title) { 'lenny-backports' }
    let :params do default_params end

    it { should contain_class('reprepro::params') }
    it { should contain_class('concat::setup') }

    it do
      should contain_concat__fragment('update-lenny-backports').with({
        :target => '/var/packages/dev/conf/updates'
      })
    end
  end
end
