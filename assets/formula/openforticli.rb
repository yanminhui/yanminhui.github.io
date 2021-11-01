class Openforticli < Formula
  desc "Command-Line Interface for PPP+SSL VPN tunnel services"
  homepage "https://github.com/yanminhui/openforticli"
  url "https://github.com/yanminhui/openforticli/archive/v1.17.1.20211101.tar.gz"
  sha256 "934434206085e5ab8455da3a887ab0474b538019db4710aadbc9700fe44cb70a"
  license "GPL-3.0-or-later"
  
  bottle do
    root_url "https://github.com/yanminhui/openforticli/releases/download/v1.17.1.20211101"
    sha256 big_sur: "25b65c396c852164608853f5d909a545c0338e3ce90aa5dd6109d71a4dcec1f6"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkg-config" => :build
  depends_on "oath-toolkit"
  depends_on "openssl@1.1"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}"
    system "make", "install"
  end

  plist_options manual: "openforticli"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>WorkingDirectory</key>
          <string>/tmp</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{bin}/openforticli</string>
          </array>
          <key>StandardOutPath</key>
          <string>/var/log/openforticli/out.log</string>
          <key>StandardErrorPath</key>
          <string>/var/log/openforticli/err.log</string>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    EOS
  end

  test do
    system bin/"openforticli", "--version"
  end
end
