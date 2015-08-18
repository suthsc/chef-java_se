require 'spec_helper'

describe 'java_se::default' do
  context 'windows' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        file_cache_path: 'C:/chef/cache', platform: 'windows', version: '2008R2').converge(described_recipe)
    end

    it 'installs open_uri_redirections gem' do
      expect(chef_run).to install_chef_gem('open_uri_redirections')
    end

    it 'fetches java' do
      expect(chef_run).to run_ruby_block(
        'fetch http://download.oracle.com/otn-pub/java/jdk/8u51-b16/jdk-8u51-windows-x64.exe')
    end

    it 'validates java' do
      expect(chef_run).to run_ruby_block('validate C:/chef/cache/jdk-8u51-windows-x64.exe')
    end

    it 'installs java' do
      expect(chef_run).to run_ruby_block(
        'install jdk-8u51-windows-x64.exe to \Java\jdk1.8.0_51')
    end

    it 'sets JAVA_HOME' do
      expect(chef_run).to create_env('JAVA_HOME')
    end

    it 'sets PATH' do
      expect(chef_run).to modify_env('PATH')
    end
  end

  context 'linux' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        file_cache_path: '/var/chef/cache', platform: 'centos', version: '7.0').converge(described_recipe)
    end
  end

  context 'mac_os_x' do
    let(:exitstatus) { 0 }
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/var/chef/cache', platform: 'mac_os_x', version: '10.10') do
        out = double('out', exitstatus: 1, stdout: '', stderr: '')
        allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out).with(
          "pkgutil --pkgs='com.oracle.jdk8u51'").and_return(out)
      end.converge(described_recipe)
    end

    it 'installs open_uri_redirections gem' do
      expect(chef_run).to install_chef_gem('open_uri_redirections')
    end

    it 'fetches java' do
      expect(chef_run).to run_ruby_block(
        'fetch http://download.oracle.com/otn-pub/java/jdk/8u51-b16/jdk-8u51-macosx-x64.dmg')
    end

    it 'validates java' do
      expect(chef_run).to run_ruby_block('validate /var/chef/cache/jdk-8u51-macosx-x64.dmg')
    end

    it 'attaches volume' do
      expect(chef_run).to run_execute("hdiutil attach '/var/chef/cache/jdk-8u51-macosx-x64.dmg' -quiet")
    end

    it 'install pkg' do
      expect(chef_run).to run_execute("sudo installer -pkg '/Volumes/JDK 8 Update 51/JDK 8 Update 51.pkg' -target /")
    end

    it 'detaches volume' do
      expect(chef_run).to run_execute("hdiutil detach '/Volumes/JDK 8 Update 51' " \
        "|| hdiutil detach '/Volumes/JDK 8 Update 51' -force")
    end

    it 'adds BundledApp capability' do
      expect(chef_run).to run_execute('/usr/bin/sudo /usr/libexec/PlistBuddy -c ' \
        "\"Add :JavaVM:JVMCapabilities: string BundledApp\" " \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Info.plist')
    end

    it 'adds JNI capability' do
      expect(chef_run).to run_execute('/usr/bin/sudo /usr/libexec/PlistBuddy -c ' \
        "\"Add :JavaVM:JVMCapabilities: string JNI\" " \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Info.plist')
    end

    it 'adds WebStart capability' do
      expect(chef_run).to run_execute('/usr/bin/sudo /usr/libexec/PlistBuddy -c ' \
        "\"Add :JavaVM:JVMCapabilities: string WebStart\" " \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Info.plist')
    end

    it 'adds Applets capability' do
      expect(chef_run).to run_execute('/usr/bin/sudo /usr/libexec/PlistBuddy -c ' \
        "\"Add :JavaVM:JVMCapabilities: string Applets\" " \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Info.plist')
    end

    it 'removes previous jdk' do
      expect(chef_run).to run_execute('/usr/bin/sudo /bin/rm -rf ' \
        '/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK')
    end

    it 'adds current jdk' do
      expect(chef_run).to run_execute('/usr/bin/sudo /bin/ln -nsf ' \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents ' \
        '/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK')
    end

    it 'creates java home' do
      expect(chef_run).to run_execute('/usr/bin/sudo /bin/ln -nsf ' \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home /Library/Java/Home')
    end

    it 'creates lib dir' do
      expect(chef_run).to run_execute('/usr/bin/sudo /bin/mkdir -p ' \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/bundle/Libraries')
    end

    it 'creates java home' do
      expect(chef_run).to run_execute('/usr/bin/sudo /bin/ln -nsf ' \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/jre/lib/server/libjvm.dylib ' \
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/bundle/Libraries/libserver.dylib')
    end
  end
end
