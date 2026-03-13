# OCRDetection iOS Project - Full Context

## Project Overview

**Project Name:** OCRDetection_Arpit_Practical
**Platform:** iOS
**Language:** Swift 5+
**Architecture:** Clean Architecture with Domain/Data/Service layers
**UI Pattern:** UIKit + Storyboard (Required by specification)
**Frameworks:** Vision (OCR), Core Data (Persistence), PDFKit (Export)

---

## Requirements Summary (iOS Task No. 9)

### Core Objective
Import an image → run OCR to detect polynomial expressions → parse & process each → save locally → show results in adaptive Storyboard list/grid → tap for details → export/share as PDF.

### Must-Do Requirements

1. **Storyboard-based UI only** - No SwiftUI
2. **Import image** from photo library → show small preview
3. **Vision OCR** (background thread) for text + bounding boxes
4. **Filter OCR output** to polynomial-like strings (support +, −, ×, ÷, ^)
5. **Parse each polynomial** → simplify, derivative, value@1, value@2
6. **Handle multiplication & division** expressions
7. **Save locally** (Core Data, background save + main merge)
8. **Collection/grid view** with card-style cells (Storyboard prototype)
9. **Detail screen**: original, simplified, derivative, values + share/export PDF
10. **Adaptive layout**: Compact = 1 column; Regular = 2–3 columns
11. **Accessibility**: Size Classes, Dynamic Type, Dark Mode, scalable SF Symbols
12. **Threading**: Run OCR, parsing, saves off main thread; show activity indicator

### UI Specifications

| Element | Requirement |
|---------|-------------|
| Navigation Title | "Polynomial OCR" |
| Nav Bar Icon | Import icon (SF Symbol: `square.and.arrow.down` or `photo.on.rectangle`) |
| Top Section | Image preview + status label ("N polynomials detected") |
| Main View | Collection view with card cells (IB prototype) |
| Cell Content | Primary (equation), Secondary (simplified), Tertiary (value@1 and 2) |
| Cell Labels | Multi-line primary (numberOfLines=0), semantic text styles |
| Size Classes | Compact: 1 column; Regular: 2-3 columns |
| Spacing/Fonts | IB size-class variations |

---

## Current Implementation Status

### ✅ Phase 1: Core Services (COMPLETED)

| Component | File | Status |
|-----------|------|--------|
| OCR Models | `Models/Domain/OCRResult.swift` | ✅ Complete |
| Math Models | `Models/Domain/PolynomialMathResult.swift` | ✅ Complete |
| OCR Service | `Services/OCR/OCRService.swift` + `OCRServiceImpl.swift` | ✅ Complete |
| Filter Service | `Services/PolynomialFilterService.swift` | ✅ Complete |
| Parser Service | `Services/PolynomialParserService.swift` + `PolynomialParserServiceImpl.swift` | ✅ Complete |
| PDF Export | `Services/PDFExport/PDFExportService.swift` + `PDFExportServiceImpl.swift` | ✅ Complete |
| DI Container | `Services/DependencyContainer.swift` | ✅ Complete |

### ⏳ Phase 2: Storyboard UI (IN PROGRESS)

### ⏳ Phase 3: ViewControllers (PENDING)

### ⏳ Phase 4: Integration (PENDING)

---

## Architecture Design

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                    Presentation Layer                │
│  (ViewControllers, Storyboard, ViewModels)          │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                      Domain Layer                    │
│  (Polynomial, OCRResult, PolynomialMathResult)      │
│  (Repository Protocols, Service Protocols)          │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                       Data Layer                     │
│  (PolynomialRepositoryImpl, PolynomialEntity)       │
│  (Core Data Stack, ImageFileManager)                │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                     Service Layer                    │
│  (OCRServiceImpl, PolynomialParserServiceImpl)      │
│  (PDFExportServiceImpl, DependencyContainer)        │
└─────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Protocol-Oriented**: All services and repositories use protocols for testability
2. **Dependency Injection**: Centralized `DependencyContainer` for managing dependencies
3. **Async/Await**: Modern Swift concurrency for all async operations
4. **Background Processing**: OCR runs on background queue, UI updates on main queue
5. **Error Handling**: Custom `OCRServiceError`, `PolynomialParserError`, `PDFExportError`
6. **Image Optimization**: Resize to max 1024px, JPEG 0.7 quality, atomic file operations

---

## Critical Implementation Details

### OCR Service (Vision Framework)

- **Recognizer**: `VNRecognizeTextRequest`
- **Recognition Level**: `.accurate`
- **Languages**: English, plus handle common math symbols
- **Threading**: Background queue, results marshaled to main thread
- **Output**: Array of `OCRResult` with text, bounding box, confidence

### Polynomial Parser Service

**Expression Normalization:**
- `×` → `*`
- `÷` → `/`
- `^` → `**` (for DDMathParser)
- Remove spaces

**Supported Operations:**
- Addition: `+`
- Subtraction: `-`
- Multiplication: `×` or `*`
- Division: `÷` or `/`
- Exponentiation: `^`

**Calculations:**
1. **Simplified**: Original expression normalized
2. **Derivative**: d/dx using DDMathParser
3. **Value@1**: Evaluate at x=1
4. **Value@2**: Evaluate at x=2

### PDF Export Service

- **Size**: A4 (612x792 points)
- **Margins**: 48pt on all sides
- **Fonts**: System font hierarchy
- **Colors**: Adapts to light/dark mode
- **Format**: One polynomial per page with full details

### Core Data Integration

- **Entity**: `PolynomialEntity`
- **Background Save**: Uses `performBackgroundTask`
- **Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy`
- **Image Storage**: File system path in Core Data, actual file in `Documents/polynomial-images/`

---

## Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| No text detected | Return empty array, show "No polynomials detected" |
| Invalid polynomial | Skip, log warning |
| OCR returns garbage | Filter service rejects non-polynomial strings |
| Image save fails | Continue without image, show warning |
| Core Data save fails | Bubble up error, show alert |
| PDF export fails | Show error alert with details |
| Memory pressure | Vision framework handles; images optimized at source |
| User denies photo library access | Show alert with instructions to enable in Settings |
| Long-running OCR | Activity indicator with cancel option |
| Device orientation change | Storyboard handles via constraints and size classes |
| Background app state | Continue OCR, pause UI updates until return |

---

## Threading Model

```
Main Thread                          Background Thread
─────────────────────────────────────────────────────────
User Action ────────► Trigger OCR
                             │
                             ▼
                      OCRService.process()
                             │
                             ▼
                      Vision Framework
                             │
                             ▼
                      Filter Service
                             │
                             ▼
                      Parser Service
                             │
                             ▼
                      Repository Save
                             │
                             ▼
Results ──────────────────────◄── Async/Await
     │
     ▼
Update UI (must be on main)
```

---

## Testing Checklist (from Requirements)

1. ✅ Import → preview + OCR runs
2. ✅ Polynomial detected, parsed, saved
3. ⏳ Cards appear; wrap text correctly
4. ⏳ Regular width → multi-column
5. ⏳ Tap → detail shows all data + share/export PDF works
6. ⏳ Fonts and symbols scale properly
7. ⏳ No UI freeze during OCR or saves

---

## What Still Needs to be Built

### Phase 2: Storyboard UI
- [ ] Modify Main.storyboard with Navigation Controller
- [ ] Add PolynomialListViewController (Collection View)
- [ ] Create PolynomialCell prototype in Storyboard
- [ ] Add constraints and size-class variations
- [ ] Add PolynomialDetailViewController scene
- [ ] Add ImagePreviewView component
- [ ] Configure adaptive layout (Compact/Regular)

### Phase 3: ViewControllers
- [ ] PolynomialListViewController.swift
  - [ ] Collection view data source/delegate
  - [ ] Image picker integration
  - [ ] OCR coordination
  - [ ] Activity indicator management
- [ ] PolynomialDetailViewController.swift
  - [ ] Detail display
  - [ ] PDF export action
  - [ ] Share sheet integration
- [ ] ImagePreviewView.swift
  - [ ] Reusable preview component
  - [ ] Status label

### Phase 4: Integration
- [ ] AppDelegate integration
- [ ] Error handling UI
- [ ] Permission handling (Photo Library)
- [ ] End-to-end testing

---

## File Structure (Current State)

```
OCRDetection_Arpit_Practical/
├── AppDelegate.swift
├── SceneDelegate.swift (DELETED - using app-based lifecycle)
├── ViewController.swift (EMPTY - needs replacement)
├── Info.plist (photo library permission added)
├── Models/
│   ├── Domain/
│   │   ├── Polynomial.swift ✅
│   │   ├── OCRResult.swift ✅
│   │   └── PolynomialMathResult.swift ✅
│   └── Data/
│       ├── CoreData/
│       │   ├── PolynomialEntity+CoreDataClass.swift
│       │   └── PolynomialEntity+CoreDataProperties.swift
│       └── Repositories/
│           ├── PolynomialRepository.swift
│           └── PolynomialRepositoryImpl.swift
├── Services/
│   ├── ImageFileManager.swift ✅
│   ├── OCR/
│   │   ├── OCRService.swift ✅
│   │   └── OCRServiceImpl.swift ✅
│   ├── PolynomialFilterService.swift ✅
│   ├── PolynomialParser/
│   │   ├── PolynomialParserService.swift ✅
│   │   └── PolynomialParserServiceImpl.swift ✅
│   ├── PDFExport/
│   │   ├── PDFExportService.swift ✅
│   │   └── PDFExportServiceImpl.swift ✅
│   └── DependencyContainer.swift ✅
└── ViewControllers/ (EMPTY - needs to be populated)
```

---

## Dependencies

| Framework/Package | Purpose | Status |
|-------------------|---------|--------|
| Vision | OCR functionality | ✅ System Framework |
| Core Data | Local persistence | ✅ System Framework |
| PDFKit | PDF generation | ✅ System Framework |
| PhotosUI | Image picker | ✅ System Framework |
| DDMathParser | Math expression evaluation | ⏳ Need to add via SPM |

### Required SPM Package
```swift
// Package.swift (or add via Xcode)
https://github.com/davedelong/DDMathParser
```

---

## Storyboard Structure Design

### Main.storyboard Scenes

```
Navigation Controller (Initial)
└── Polynomial List View Controller
    ├── Navigation Item
    │   ├── Title: "Polynomial OCR"
    │   └── Bar Button Item: Import (Photo Library)
    ├── Container View (Top)
    │   ├── Image Preview View
    │   └── Status Label
    └── Collection View
        └── Polynomial Cell (Prototype)
            ├── Primary Label (Original)
            ├── Secondary Label (Simplified)
            └── Tertiary Label (Values)

Polynomial Detail View Controller
├── Navigation Item
│   ├── Title: "Polynomial Details"
│   └── Bar Button Item: Share/Export
└── Scroll View
    └── Content View
        ├── Original Label
        ├── Simplified Label
        ├── Derivative Label
        ├── Value @ 1 Label
        ├── Value @ 2 Label
        └── Image View (Optional)
```

### Size Class Configurations

| Element | Any/Any | Compact/Any | Regular/Any |
|---------|---------|-------------|-------------|
| Collection View Items | - | 1 column | 2-3 columns |
| Cell Spacing | 8pt | 8pt | 16pt |
| Cell Insets | 16pt | 16pt | 24pt |
| Title Font | Headline | Title2 | Title1 |

---

## Next Steps

1. **Phase 2**: Implement Storyboard UI changes
2. **Phase 3**: Build ViewControllers with proper delegation and data binding
3. **Phase 4**: Wire everything together in AppDelegate
4. **Testing**: Run through the Quick Testing Checklist
5. **Polish**: Animations, accessibility, error messages

---

## Contact & Notes

- **Developer**: Arpit Parekh
- **Date Created**: 2025-03-13
- **Last Updated**: 2025-03-13
- **Task Reference**: iOS Task No. 9 - Polynomial OCR Detection

---

*This document is maintained as part of the project development process and reflects the current state of implementation.*
