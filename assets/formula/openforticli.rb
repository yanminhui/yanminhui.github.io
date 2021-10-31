class Openforticli < Formula
  desc "Command-Line Interface for PPP+SSL VPN tunnel services"
  homepage "https://github.com/yanminhui/openforticli"
  url "https://github.com/yanminhui/openforticli/archive/v1.17.1.20211031.tar.gz"
  sha256 "92ab71fcb2f9b7e87f29fcfa29bbb9b8aee0be217d298447935562db5b646f65"
  license "GPL-3.0-or-later"
  
  bottle do
    root_url "https://github.com/yanminhui/openforticli/releases/download/v1.17.1.20211031"
    sha256 big_sur: "c399d6d8e0279b7352c704819fc3e6ee98ee560cf6bc30c8b659ae17ef0addfb"
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
