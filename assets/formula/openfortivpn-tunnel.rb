class OpenfortivpnTunnel < Formula
  desc "Open Fortinet client for PPP+SSL VPN tunnel services"
  homepage "https://github.com/yanminhui/openfortivpn"
  url "https://github.com/yanminhui/openfortivpn/archive/v1.17.1.20210919.tar.gz"
  sha256 "757baefa0fa173203245d8cd741ca3681bd7e8b92cffde2687bb7efa283a68d7"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://github.com/yanminhui/openfortivpn/releases/download/v1.17.1.20210919"
    sha256 big_sur:  "079bfb54149dc01a5370ee77a1e630f8ea73310ed409d7ffa47f673f9b625295"
    sha256 catalina: "fd932b1ca632ac643425a350c2a595e57a2e567bf8c0293bbc2fd3719ec997c2"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkg-config" => :build
  depends_on "oath-toolkit"
  depends_on "openssl@1.1"

  conflicts_with "openfortivpn", because: "it is an alias for `openfortivpn`"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}"
    system "make", "install"
  end

  plist_options manual: "openfortivpn"

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
              <string>#{bin}/openfortivpn</string>
          </array>
          <key>StandardOutPath</key>
          <string>/var/log/openfortivpn/out.log</string>
          <key>StandardErrorPath</key>
          <string>/var/log/openfortivpn/err.log</string>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    EOS
  end

  test do
    system bin/"openfortivpn", "--version"
  end
end
