#!/usr/bin/env ruby
# A curated, categorized list of well-known public OSINT resources - a
# quick-reference page, not something the dashboard executes.
module OsintResources
  CATEGORIES = [
    {
      title: 'Domain / DNS',
      items: [
        { name: 'crt.sh', url: 'https://crt.sh', note: 'certificate transparency search' },
        { name: 'ViewDNS.info', url: 'https://viewdns.info', note: 'DNS/WHOIS/reverse-IP toolkit' },
        { name: 'SecurityTrails', url: 'https://securitytrails.com', note: 'historical DNS/WHOIS' },
        { name: 'DNSDumpster', url: 'https://dnsdumpster.com', note: 'DNS recon and mapping' }
      ]
    },
    {
      title: 'IP / Network',
      items: [
        { name: 'Shodan', url: 'https://www.shodan.io', note: 'internet-connected device search' },
        { name: 'Censys', url: 'https://search.censys.io', note: 'internet-wide host/cert search' },
        { name: 'BGP.HE.net', url: 'https://bgp.he.net', note: 'ASN / netblock lookup' },
        { name: 'IPinfo', url: 'https://ipinfo.io', note: 'IP geolocation and ownership' }
      ]
    },
    {
      title: 'Email',
      items: [
        { name: 'Have I Been Pwned', url: 'https://haveibeenpwned.com', note: 'breach exposure lookup' },
        { name: 'Hunter.io', url: 'https://hunter.io', note: 'email pattern discovery' },
        { name: 'EmailRep', url: 'https://emailrep.io', note: 'email reputation lookup' }
      ]
    },
    {
      title: 'Username / Social',
      items: [
        { name: 'WhatsMyName', url: 'https://whatsmyname.app', note: 'username enumeration across sites' },
        { name: 'Sherlock (GitHub)', url: 'https://github.com/sherlock-project/sherlock', note: 'username enumeration CLI' }
      ]
    },
    {
      title: 'Images / Metadata',
      items: [
        { name: 'TinEye', url: 'https://tineye.com', note: 'reverse image search' },
        { name: 'Google Images', url: 'https://images.google.com', note: 'reverse image search' },
        { name: 'ExifTool', url: 'https://exiftool.org', note: 'image/file metadata extraction' }
      ]
    },
    {
      title: 'Company / Public records',
      items: [
        { name: 'OpenCorporates', url: 'https://opencorporates.com', note: 'company registry search' },
        { name: 'LinkedIn', url: 'https://www.linkedin.com', note: 'employee / org structure' }
      ]
    },
    {
      title: 'Code / Leaks',
      items: [
        { name: 'GitHub code search', url: 'https://github.com/search', note: 'exposed secrets, internal refs' },
        { name: 'GitLeaks (GitHub)', url: 'https://github.com/gitleaks/gitleaks', note: 'secret scanning CLI' }
      ]
    }
  ].freeze
end
