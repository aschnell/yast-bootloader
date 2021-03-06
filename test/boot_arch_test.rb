require_relative "test_helper"

Yast.import "BootArch"

describe Yast::BootArch do
  subject { Yast::BootArch }

  def stub_arch(arch)
    Yast.import "Arch"

    allow(Yast::Arch).to receive(:architecture).and_return(arch)
  end

  describe ".ResumeAvailable" do
    it "returns true if it is on x86_64 architecture" do
      stub_arch("x86_64")

      expect(subject.ResumeAvailable).to eq true
    end

    it "returns true if it is on i386 architecture" do
      stub_arch("i386")

      expect(subject.ResumeAvailable).to eq true
    end

    it "returns true if it is on s390 architecture" do
      stub_arch("s390_64")

      expect(subject.ResumeAvailable).to eq true
    end

    it "it returns false otherwise" do
      stub_arch("ppc64")

      expect(subject.ResumeAvailable).to eq false
    end
  end

  describe ".DefaultKernelParams" do
    context "on x86_64 or i386" do
      before do
        stub_arch("x86_64")
      end

      it "adds parameters from boot command line" do
        allow(Yast::Kernel).to receive(:GetCmdLine).and_return("console=ttyS0")

        expect(subject.DefaultKernelParams("/dev/sda2")).to include("console=ttyS0")
      end

      it "adds additional parameters from Product file" do
        allow(Yast::ProductFeatures).to receive(:GetStringFeature).and_return("console=ttyS0")

        expect(subject.DefaultKernelParams("/dev/sda2")).to include("console=ttyS0")
      end

      it "removes splash param from command line or product file and add it silent" do
        allow(Yast::Kernel).to receive(:GetCmdLine).and_return("splash=verbose splash=quit splash=hell")

        expect(subject.DefaultKernelParams("/dev/sda2")).to include("splash=silent")
        expect(subject.DefaultKernelParams("/dev/sda2")).to_not include("splash=verbose")
        expect(subject.DefaultKernelParams("/dev/sda2")).to_not include("splash=quit")
        expect(subject.DefaultKernelParams("/dev/sda2")).to_not include("splash=hell")
      end

      it "adds passed parameter as resume device" do
        expect(subject.DefaultKernelParams("/dev/sda2")).to include("resume=/dev/sda2")
      end

      it "do not adds resume device if parameter is empty" do
        expect(subject.DefaultKernelParams("")).to_not include("resume")
      end

      it "adds splash=silent quit showopts parameters" do
        expect(subject.DefaultKernelParams("/dev/sda2")).to include(" splash=silent quiet showopts")
      end
    end

    context "on s390" do
      before do
        stub_arch("s390_64")
      end

      it "adds additional parameters from Product file" do
        allow(Yast::ProductFeatures).to receive(:GetStringFeature).and_return("console=ttyS0")

        expect(subject.DefaultKernelParams("/dev/sda2")).to include("console=ttyS0")
      end

      it "adds serial console if ENV{TERM} is linux" do
        ENV["TERM"] = "linux"

        expect(subject.DefaultKernelParams("/dev/sda2")).to include("TERM=linux console=ttyS0 console=ttyS1")
      end

      it "adds TERM=dumb and hvc_iucv=8 for other TERM" do
        ENV["TERM"] = "xterm"

        expect(subject.DefaultKernelParams("/dev/sda2")).to include("hvc_iucv=8 TERM=dumb")
      end

      it "adds passed parameter as resume device" do
        expect(subject.DefaultKernelParams("/dev/dasd2")).to include("resume=/dev/dasd2")
      end

      # JR: temporary disabled as it cause build service only failure
      it "does not add parameters from boot command line"
    end

    context "on POWER archs" do
      before do
        stub_arch("ppc64")
      end

      it "returns parameters from current command line" do
        allow(Yast::Kernel).to receive(:GetCmdLine).and_return("console=ttyS0 splash=verbose")
        # just to test that it do not add product features
        allow(Yast::ProductFeatures).to receive(:GetStringFeature).and_return("console=ttyS1")

        expect(subject.DefaultKernelParams("/dev/sda2")).to eq "console=ttyS0 resume=/dev/sda2 console=ttyS1 splash=silent quiet showopts"
      end

      it "adds splash=silent quit showopts parameters" do
        expect(subject.DefaultKernelParams("/dev/sda2")).to include(" splash=silent quiet showopts")
      end
    end
  end
end
