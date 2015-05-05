# Spaceman Spiff

Takes an SPF-specific DNS record and recursively resolves all `include:` markers down to a flat list of IPs.

Can optionally update Route 53 with the new records.

## Installation

Dependencies are installed using [Bundler].

```bash
bundle install
```

## Examples
### Pipe a raw SPF record into `spaceman`

```bash
echo "v=spf1 a mx ptr mx:aspmx.l.google.com include:_spf.google.com include:sendgrid.net include:mail.zendesk.com ~all" | spaceman
```

### Read a file containing the SPF record
```bash
spaceman spf.txt
```

  [Bundler]: http://bundler.io
