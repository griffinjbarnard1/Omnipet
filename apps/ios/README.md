# iOS App Scaffold (SwiftUI)

This folder contains a **module-first scaffold** for a mobile-first OmniPet client.

## Proposed Module Layout

- `OmniPet/App`: app entrypoint + root tab shell
- `OmniPet/Core`: domain models + routing primitives
- `OmniPet/DesignSystem`: color tokens + reusable UI building blocks
- `OmniPet/Features/Discovery`
- `OmniPet/Features/Vault`
- `OmniPet/Features/Scanner`
- `OmniPet/Features/BusinessProfile`
- `OmniPet/Features/Activity`

## Notes

- This is intentionally project-generator-friendly scaffolding; integrate via XcodeGen/Tuist or a native `.xcodeproj` next.
- Feature folders include placeholder SwiftUI views to accelerate wiring.
- Business logic should remain in `Core` and service layers; features focus on presentation and interaction.
