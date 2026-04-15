# About This Documentation

## Overview

This documentation site provides a comprehensive reference for the JSON Schema definitions used in the sikker-selvbetjening fleet configuration system.

## Schema Design Philosophy

The schemas follow these principles:

- **Hierarchical**: Root schema references section-specific subschemas
- **Self-documenting**: Every property includes descriptions for clarity
- **Strict validation**: `additionalProperties: false` enforces explicit schema adherence
- **Extensible**: New sections can be added without modifying the root schema

## Technology Stack

- **Schema Standard**: [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/schema)
- **Documentation Generator**: [MkDocs](https://www.mkdocs.org/) with [Material Theme](https://squidfunk.github.io/mkdocs-material/)
- **Deployment**: GitHub Pages (auto-deployed on schema changes via GitHub Actions)
- **Validation**: JSON Schema validation + custom Python validator for cross-field constraints

## Repository Structure

```
sikker-selvbetjening-config/
├── schemas/                     # All JSON Schema files
│   ├── group-vars.schema.json
│   └── sections/
│       ├── printer.schema.json
│       └── wifi.schema.json
├── group_vars/                  # Target-specific overlay configs
│   ├── borgerservice.yml
│   ├── broager.yml
│   └── nordborg.yml
├── scripts/
│   └── validate-group-vars.py   # Cross-field validator
├── mkdocs.yml                   # Documentation configuration
└── docs/                        # This documentation
```

## Key Concepts

### Overlay Configuration

Each library branch (target) has a corresponding YAML file in `group_vars/` that defines its specific configuration. These files are validated against the schemas before being used to build container images.

### Schema Validation Process

1. Load group_vars YAML file
2. Validate against JSON Schema
3. Run custom validator for cross-field constraints
4. Render configuration into the container overlay

### Custom Validation

Some constraints cannot be expressed in JSON Schema alone. For example, the `default_printer` field must reference a printer that actually exists in the `no_ppd` or `with_ppd` collections. This type of constraint is enforced by `scripts/validate-group-vars.py`.

## Feedback

For questions or suggestions about the schema design, please open an issue in the [repository](https://github.com/bibsdb/sikker-selvbetjening-config/issues).
