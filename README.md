# sikker-selvbetjening-config

This repository defines configuration overlays per target/site and builds per-target container images based on `ghcr.io/bibsdb/sikker-selvbetjening`.

## Process and Flow

```mermaid
flowchart TD
  A[Author configuration] --> A1[group_vars/*.yml]
  A --> A2[inventory/build_targets.yml]
  A --> A3[assets/*]

  subgraph CI Build Pipeline [.github/workflows/build.yml]
    B1[Checkout repository]
    B2[Discover targets from build_targets.yml]
    B3[Validate groups and image_name uniqueness]
    B4[Matrix build per target]
  end

  A1 --> B2
  A2 --> B2
  B1 --> B2 --> B3 --> B4

  subgraph Render and Build [scripts/build-group-image.sh]
    C1[Resolve target groups CSV and image name]
    C2[Run ansible render playbook]
    C3[Build overlay image FROM base image]
    C4[Tag latest/date/sha]
    C5[Push to GHCR]
  end

  B4 --> C1 --> C2 --> C3 --> C4 --> C5

  subgraph Overlay Render [playbooks/render-host-overlays.yml]
    D1[Load selected group_vars in order]
    D2[Recursive merge into overlay_sections]
    D3[Normalize *_file paths]
    D4[Copy referenced assets into build root]
    D5[Render section YAML files]
  end

  C2 --> D1 --> D2 --> D3 --> D4 --> D5

  subgraph Output Layout [build/<image>/usr/share/sikker-selvbetjening/config]
    E1[printer.yml]
    E2[wifi.yml]
    E3[desktop.yml]
    subgraph Assets [assets/]
      E4[referenced files from source assets]
    end
  end

  D5 --> E1
  D5 --> E2
  D5 --> E3
  D4 --> E4
  E1 --> C3
  E2 --> C3
  E3 --> C3
  E4 --> C3

  subgraph Optional Validation [Local/CI helper]
    V1[schemas/group-vars.schema.json]
    V2[scripts/validate-group-vars.py]
    V3[Cross-field checks default_printer membership]
  end

  A1 -. validate against .-> V1
  A1 -. validate with .-> V2 --> V3

```

## Key Paths

- Group overlays: `group_vars/`
- Build target matrix input: `inventory/build_targets.yml`
- Overlay renderer: `playbooks/render-host-overlays.yml`
- Build and push script: `scripts/build-group-image.sh`
- Optional cross-field validator: `scripts/validate-group-vars.py`
- Schema definitions: `schemas/`
