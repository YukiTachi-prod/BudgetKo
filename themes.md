# App Theme & Design Guidelines

This document outlines the design system, colors, typography, and styling used in the application. It serves as a reference for creating a consistent look and feel across new applications.

## 🎨 Color Palette

The app supports both Light and Dark themes, using a violet/purple-centric design system.

### Light Theme
| Element | Hex Color | Description |
| :--- | :--- | :--- |
| **Background** | `#EEF2FF` | Soft lavender |
| **Surface** | `#FFFFFF` | White (Cards, Dialogs, etc.) |
| **Nav Background**| `#6D28D9` | Deep purple sidebar |
| **Nav Foreground**| `#FFFFFF` | White |
| **Border** | `#E5E7EB` | Light gray |
| **Text** | `#1E1B4B` | Dark navy |
| **Subtext** | `#6B7280` | Gray |
| **Accent (Primary)**| `#7C3AED` | Violet |

### Dark Theme
| Element | Hex Color | Description |
| :--- | :--- | :--- |
| **Background** | `#0D0B1A` | Very dark violet |
| **Surface** | `#16132B` | Dark purple-tinted (Cards, Dialogs) |
| **Nav Background**| `#1A1733` | Dark purple sidebar |
| **Nav Foreground**| `#FFFFFF` | White |
| **Border** | `#2E2A4A` | Dark border |
| **Text** | `#E2E8F0` | Light gray/white |
| **Subtext** | `#94A3B8` | Slate gray |
| **Accent (Primary)**| `#8B5CF6` | Lighter violet |

---

## 🔤 Typography

The app uses a consistent typographic scale across all components.

| Style | Font Size | Font Weight | Letter Spacing |
| :--- | :--- | :--- | :--- |
| **Title Large** | 18px | 700 (Bold) | -0.3 |
| **Title Medium**| 15px | 600 (Semi-bold) | -0.2 |
| **Title Small** | 13px | 500 (Medium) | 0.0 |
| **Body Large** | 14px | Normal | 0.0 |
| **Body Medium** | 13px | Normal | 0.0 |
| **Body Small** | 12px | Normal | 0.0 |
| **Label Large** | 13px | 500 (Medium) | 0.0 |
| **Label Medium**| 12px | Normal | 0.0 |
| **Label Small** | 11px | Normal | 0.0 |

---

## 🚦 Status Colors

Used for visual indicators of progress or states.

- **Ongoing**: `#7C3AED` (Violet)
- **Finished**: `#10B981` (Emerald)
- **Dropped**: `#EF4444` (Red)
- **Not Started**: `#6B7280` (Gray)

---

## 🌈 Category Palette

A stable, hash-based palette for assigning distinct colors to different categories or tags.

- `#8B5CF6` (Violet)
- `#6366F1` (Indigo)
- `#3B82F6` (Blue)
- `#06B6D4` (Cyan)
- `#10B981` (Emerald)
- `#F59E0B` (Amber)
- `#EF4444` (Red)
- `#EC4899` (Pink)

---

## 💠 UI Components & Styling Notes

- **App Bar**: Flat (0 elevation), uncentered titles, matches the surface color.
- **Bottom Navigation**: Surface colored, fixed type, selected items use Accent color, unselected use Subtext color.
- **Navigation Rail**: Uses the distinct Nav Background color, selected items have an indicator with a 15% opacity of the Nav Foreground color.
- **Inputs**: Filled styling with rounded corners (10px border radius). Focused borders use the Accent color.
- **Cards & Dialogs**: Surface colored. Cards have 14px rounded corners and 0 elevation. Dialogs have 16px rounded corners and 8 elevation.
- **Buttons (Filled)**: Accent background with White text, 8px border radius.
- **Chips**: 8px border radius, background matches surface, selected state uses a 12% opacity Accent color.
