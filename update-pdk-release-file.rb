# frozen_string_literal: true

require "open-uri"
require "oga"

NIGHTLIES_HOST = "https://nightlies.puppetlabs.com"
PDK_BIONIC_BASE = "#{NIGHTLIES_HOST}/apt/pool/bionic/puppet6-nightly/p/pdk"
PDK_RELEASE_PKG_REGEX = /^pdk_(?<version>\d+\.\d+\.\d+\.\d+)-1bionic_amd64/
PDK_NIGHTLY_PKG_REGEX = /^pdk_(?<version>\d+\.\d+\.\d+\.\d+\..*)-1bionic_amd64/

def pdk_nightlies_html
  URI.parse("#{PDK_BIONIC_BASE}/index_by_lastModified_reverse.html").read
rescue OpenURI::HTTPError
  nil
end

def pdk_release_versions
  doc = Oga.parse_html(pdk_nightlies_html)

  version_map = doc.css('a[href$="deb"]').collect do |el|
    if matches = el['href'].match(PDK_RELEASE_PKG_REGEX)
      {
        :version => matches[:version],
        :href => "#{PDK_BIONIC_BASE}/#{el['href']}",
        :type => "release",
      }
    elsif matches = el['href'].match(PDK_NIGHTLY_PKG_REGEX)
      {
        :version => matches[:version],
        :href => "#{PDK_BIONIC_BASE}/#{el['href']}",
        :type => "nightly",
      }
    end
  end

  version_map.compact
end

pdk_latest = pdk_release_versions.first || exit(1)

File.open('pdk-release.env', 'w+') do |release_file|
  release_file.puts "export PDK_DEB_URL=\"#{pdk_latest[:href]}\""
  release_file.puts "export PDK_VERSION=\"#{pdk_latest[:version]}\""
  release_file.puts "export PDK_RELEASE_TYPE=\"#{pdk_latest[:type]}\""
end

exit(0)
