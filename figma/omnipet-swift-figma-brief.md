# OmniPet iOS (Swift) — Figma Blueprint

## Product POV
**OmniPet = Search + Logistics engine with a premium pet data vault.**

- **Hook:** Discovery (vet, daycare, grooming, boarding)
- **Retention:** Vault (pet passport + one-tap sharing)
- **Core promise:** Remove first-time friction by automating pet-record handoff

## Figma File Structure
Create one Figma file named:
`OmniPet iOS — Universal Pet Passport (v1)`

Use these pages:
1. `00 Foundations`
2. `01 Components`
3. `02 Flows`
4. `03 Screens — Discovery`
5. `04 Screens — Vault`
6. `05 Screens — Scanner`
7. `06 Screens — Business Profile`
8. `07 Prototype + Motion Notes`
9. `08 Dev Handoff (SwiftUI)`

---

## 00 Foundations

### Grid + Device
- Frame preset: **iPhone 16 Pro** (or closest iOS modern size)
- Base width for design: **393 pt**
- Layout grid: 4 columns, 16 margin, 12 gutter
- Spacing scale: 4, 8, 12, 16, 20, 24, 32
- Corner radius scale: 8, 12, 16, 20, 28

### Color Tokens
- `Emerald/600` #00A86B (partner pin, primary CTA)
- `Emerald/700` #008C59
- `Slate/950` #0B1020 (deep background)
- `Slate/900` #111827
- `Slate/700` #334155
- `Slate/500` #64748B
- `Slate/200` #E2E8F0
- `Slate/100` #F1F5F9
- `White` #FFFFFF
- `Gray Pin` #94A3B8 (scraped listing)
- `Success` #22C55E
- `Warning` #F59E0B
- `Danger` #EF4444

### Typography
- iOS-native style (SF Pro)
- Display: 28/34 semibold
- H1: 24/30 semibold
- H2: 20/26 semibold
- Title: 17/22 semibold
- Body: 16/22 regular
- Caption: 13/18 regular
- Micro: 11/14 medium

### Effects
- Card shadow: y=8, blur=24, 12% black
- Floating dock blur: background blur + 80% white fill
- Holographic pass overlay: gradient mesh + subtle noise

---

## 01 Components

Build as Auto Layout components with variants.

### Navigation
1. **Floating Dock / 3 tabs**
   - Tabs: Search, Vault, Activity
   - States: default, active, pressed

2. **Top Search Bar**
   - Placeholder: “Search anywhere…”
   - States: idle, focused, voice input

### Discovery
3. **Action Card**
   - Variants: Vet, Daycare, Groomer, Boarding
   - States: default, pressed

4. **Map Pin**
   - Variants: Scraped (gray), Partner (emerald), selected

5. **Suggestion Card — Expiring Soon**
   - Includes vaccine icon, expiry date, CTA

### Vault
6. **Pet Pass Card**
   - Includes pet photo, name, breed, vaccine status badge
   - Status variants: green / yellow / red

7. **Document Folder Tile**
   - Variants: Medical, Certificates, Identity, Diet

8. **Primary CTA Button**
   - Label default: “Send Records”
   - States: enabled, disabled, loading, success

### Scanner
9. **Scanner Overlay**
   - Includes document frame, leveler, OCR laser line
   - States: ready, scanning, error_low_light, error_blur

10. **Auto-Tag Toast**
   - Example copy: “Rabies Cert from Central Vet. Saving to Medical…”

### Business Profile
11. **Business Header Card**
   - Name, rating, distance, scraped/partner badge

12. **Omni-Action Button**
   - Label: “Check-In with Vault”

13. **Requirement Checklist Item**
   - Variants: present, missing, needs update

### Activity
14. **Share Log Row**
   - Business name, timestamp, docs sent, status

---

## 02 Flows

### A. Service Handshake (Primary)
1. Discovery map result tapped
2. Business profile opens
3. Tap “Check-In with Vault”
4. Requirements modal appears
5. Confirm send
6. Success + add to Activity log

### B. Vault Send Flow
1. Tap “Send Records”
2. Select docs
3. Output type: temp link vs PDF summary
4. Add recipient email
5. Send + confirmation toast

### C. Scanner Intake
1. Camera opens with leveler
2. OCR laser animation during capture
3. Auto-tag preview
4. User confirms folder

---

## 03 Screen Spec — Discovery Hub

### Layout order
1. Greeting + profile chip
2. Search bar
3. Action cards row (4)
4. Map module (60% of viewport)
5. “Expiring Soon?” smart suggestions
6. Floating dock

### Interaction notes
- Pin tap opens bottom sheet preview
- Gray pin CTA: “Visit Site”
- Emerald pin CTA: “Book in App”
- Trigger subtle “pop” haptic on found result

---

## 04 Screen Spec — Vault

### Layout order
1. Pet selector (horizontal)
2. Holographic Pet Pass
3. Vaccine status strip (green/yellow/red)
4. Document grid (2x2)
5. “Send Records” sticky CTA

### Share sheet behavior
- Multi-select documents
- Preview generated package
- Send as secure link or professional PDF
- Show success feedback (“Zip” haptic + audio)

---

## 05 Screen Spec — Smart Scanner

### Layout order
1. Camera feed
2. Frame + perspective leveler
3. OCR laser animation
4. Capture button (disabled until quality checks pass)
5. Real-time quality tooltip

### Refusal logic copy
- Low light: “Needs more light for data extraction.”
- Blur: “Hold steady to capture readable text.”

---

## 06 Screen Spec — Business Profile

### Layout order
1. Hero: business image/logo + rating + distance
2. Metadata: address, phone, web, review summary
3. Requirements panel (“Usually requires…”)
4. Primary CTA: “Check-In with Vault”
5. Secondary CTA: Call / Directions

### Non-partner behavior
- Show AI-generated business profile from scraped data
- CTA still available for record handoff via email/form

---

## 07 Prototype + Motion Notes
- Transition: Search result -> profile uses spring (220ms)
- Bottom sheet reveal: ease-out (180ms)
- OCR laser: linear repeat (1200ms loop)
- Success state: checkmark morph + subtle scale (160ms)

---

## 08 Dev Handoff (SwiftUI)

### Suggested SwiftUI structure
- `SearchHubView`
- `VaultView`
- `ScannerView`
- `BusinessProfileView`
- `ActivityView`
- Shared components in `DesignSystem/`

### Token export checklist
- Colors exported as named assets
- Typography mapped to text styles
- Spacing + radius documented in design tokens
- Component variants named for direct SwiftUI enum mapping

### Accessibility requirements
- Minimum tap target 44x44
- Contrast ratio >= 4.5:1 for core text
- Dynamic Type support on all text components
- VoiceOver labels for map pins and status badges

---

## Deliverables (for this first Swift-focused pass)
1. High-fidelity frames for 4 core screens
2. Clickable prototype for Service Handshake flow
3. Component library for Floating Dock, Pet Pass, Action Cards, Omni-Action button
4. Dev handoff annotations tied to SwiftUI naming

## Decision checkpoint
Yes — this “Universal Passport” direction strongly hits **high utility** because it combines immediate search value with long-term data lock-in through repeat, low-friction check-ins.
