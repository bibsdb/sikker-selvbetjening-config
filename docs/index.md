# Configuration Schema Documentation

Welcome to the schema documentation for **sikker-selvbetjening-config**. This site documents the JSON Schema definitions used to validate overlay configuration files across the fleet.

## Quick Start

The configuration overlay system uses a hierarchical schema approach:

- **Root Schema** ([`group-vars.schema.json`](schemas/root.md)): Defines the top-level structure with sections
- **Section Schemas**: Each section (printer, WiFi, etc.) has its own dedicated schema file

## Configuration Sections

### Printer Configuration
Comprehensive printer setup including support for:
- Multiple printer profiles (with and without PPD files)
- Princh-integrated printers
- Custom print settings and protocols

[Learn more about Printer Configuration →](schemas/printer.md)

### Wi-Fi Configuration
Wireless network settings including:
- SSID and pre-shared key (PSK)
- Hidden network support

[Learn more about Wi-Fi Configuration →](schemas/wifi.md)

## File Locations

All schema files are located in the `schemas/` directory:

```
schemas/
├── group-vars.schema.json       # Root schema
└── sections/
    ├── printer.schema.json      # Printer configuration schema
    └── wifi.schema.json         # Wi-Fi configuration schema
```

## Group Vars Files

Target-specific overlay configurations are defined in `group_vars/`:

```
group_vars/
├── borgerservice.yml            # Borgerservice branch configuration
├── broager.yml                  # Broager branch configuration
└── nordborg.yml                 # Nordborg branch configuration
```

## Validation

Configuration files are validated against these schemas during the build process:

1. **JSON Schema validation**: Automatic type checking and constraint enforcement
2. **Cross-field validation**: Custom constraints (e.g., default printer must exist) are enforced by `scripts/validate-group-vars.py`

## More Information

For details about the overall infrastructure, see the [README](https://github.com/bibsdb/sikker-selvbetjening-config) in the repository.
