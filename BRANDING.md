# Branding

`later` is the product name and the installed CLI name. Always write it in lowercase. The canonical tagline is **Durable time and workflows for Ruby.**

## Identity

The visual identity combines a geometric `L` with a clock face: durable application state plus time-aware coordination. The mark is original project artwork created for this repository and is released for use with the project under the repository's MIT-licensed materials.

Approved source assets:

- `assets/brand/later-mark.svg` — square mark for avatars, favicons, and compact layouts;
- `assets/brand/later-wordmark.svg` — mark plus lowercase wordmark for README and release surfaces;
- `assets/media/later-cli-screenshot.svg` — terminal-style product screenshot;
- `assets/media/later-cli-demo.svg` — lightweight animated SVG product demo;
- `website/public/brand/` and `website/public/media/` — deployment copies for the Astro site.

The Ruby gem includes the root `assets/` files so the README's visual identity remains available when the package is installed or rendered by a registry.

## Usage rules

- Keep `later` lowercase in prose, headings, package names, URLs, and CLI examples.
- Use **Durable time and workflows for Ruby.** as the primary tagline.
- Use the mark on its own when the surrounding context already identifies the project; use the wordmark for first-contact surfaces.
- Keep clear space around the mark equal to at least one quarter of its rendered width.
- Preserve the SVG proportions. Do not stretch, rotate, recolor, add shadows, or place the mark inside another badge.
- Use descriptive alt text such as `later — Durable time and workflows for Ruby` for the wordmark and `later mark` for the compact mark.
- Prefer the original SVG assets over rasterized copies. The animated demo is intentionally SVG rather than a hosted GIF or video so it remains portable and resolution independent.

## Palette

| Token | Value | Use |
| --- | --- | --- |
| Ink | `#101828` | Primary mark background and dark surfaces |
| Paper | `#F8FAFC` | Light mark strokes and readable text on dark surfaces |
| Cyan | `#67E8F9` | Time/active accent and focus states |
| Violet | `#A78BFA` | Secondary accent and transitions |
| Slate | `#64748B` | Supporting text and metadata |
| Green | `#34D399` | Successful health/status indicators |

Use sufficient contrast for text and controls. Do not use the cyan-to-violet gradient as the sole indicator of state.

## Boundaries

Do not imply hosted service availability, adoption, sponsorship, trademark ownership, or support for PostgreSQL, Rails/Active Job, dashboards, network transports, full calendar/DST parsing, or OpenTelemetry exporters unless the implementation, tests, documentation, and support policy have been updated. Do not add third-party logos or media without a clear license and attribution record.
