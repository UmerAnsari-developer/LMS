# LMS Java Swing Desktop Admin Panel — Complete Design & Implementation Prompt

## Role

You are a senior Java Swing desktop application designer and engineer. Design and implement a polished, production-ready **Library Management System Admin Panel** for the existing LMS Java Swing application. The result must visually and behaviorally match the approved HTML/CSS/JS admin prototype, while being implemented natively with Java Swing and Java2D.

The application is an internal desktop command center for library administrators. It should feel like a refined enterprise operations console: dense but readable, fast, structured, and visually distinctive.

Do not create a generic CRUD form. Recreate the visual hierarchy, navigation model, dashboard composition, colors, spacing, data density, and interaction patterns described below.

---

## Product Context

Application name: **LMS**

Subtitle: **Library Management**

Primary user: **Super administrator**

Example administrator: **Alex Morgan**

Workspace: **Admin workspace · Central Library · 01**

Product purpose: Manage library users, books, circulation, reports, settings, and administrator profile operations from a desktop interface.

The current project uses Java Swing under the package:

```java
package librarymanagement;
```

The existing application includes classes such as `HomeTemplate`, `Homepage`, `AdminPanel`, `LibrarianPanel`, `StudentPanel`, and `Login_Out`. Preserve existing database and authentication behavior. The redesign should primarily improve the Admin Panel shell and its visual presentation.

---

## Primary Design Direction

Create a **dark navy library command center** with subtle futuristic depth, cyan data visualization, purple secondary accents, amber operational warnings, and red overdue alerts.

The interface should combine:

- Enterprise admin-console clarity
- Desktop application density
- Subtle 3D/Java2D atmospheric background
- Strong navigation hierarchy
- Compact but legible data tables
- Clear operational status feedback
- Refined spacing and alignment

Avoid:

- Bright white generic dashboard layouts
- Excessive gradients
- Large decorative illustrations that reduce information density
- Web-browser-only patterns that do not translate well to Swing
- Excessive rounded cards or cartoon-like icons
- Unstructured forms

---

## Window and Layout Requirements

### Main Window

Use a non-resizable or controlled-resize `JFrame` depending on the existing application behavior.

Recommended initial size:

```java
1200 x 760 pixels
```

Recommended minimum size:

```java
1024 x 680 pixels
```

Use:

```java
setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
setLocationRelativeTo(null);
```

The main application shell must have three structural layers:

1. **3D atmospheric background layer**
2. **Application chrome and navigation layer**
3. **Dashboard content layer**

Use a root `JPanel` with a custom `paintComponent(Graphics)` implementation or a `JLayeredPane` when the background needs to sit behind interactive content.

Recommended structure:

```text
JFrame
└── JLayeredPane or custom root JPanel
    ├── ThreeDBackgroundPanel
    └── MainShellPanel
        ├── SidebarPanel
        └── ContentPanel
            ├── TopBar
            └── DashboardView
```

---

## Global Visual Tokens

### Colors

Declare all colors centrally in a theme class such as `LmsTheme` or `ThemeTokens`.

```java
public final class LmsTheme {
    public static final Color BG = new Color(7, 17, 31);
    public static final Color SIDEBAR = new Color(9, 21, 34);
    public static final Color SURFACE = new Color(13, 26, 43);
    public static final Color SURFACE_2 = new Color(18, 34, 56);
    public static final Color SURFACE_3 = new Color(23, 41, 67);

    public static final Color TEXT = new Color(237, 245, 251);
    public static final Color MUTED = new Color(130, 148, 170);
    public static final Color FAINT = new Color(80, 100, 123);

    public static final Color CYAN = new Color(86, 222, 234);
    public static final Color PURPLE = new Color(157, 134, 255);
    public static final Color AMBER = new Color(244, 184, 96);
    public static final Color RED = new Color(240, 120, 120);
    public static final Color GREEN = new Color(98, 213, 162);

    public static final Color BORDER = new Color(173, 205, 234, 28);
    public static final Color BORDER_STRONG = new Color(86, 222, 234, 90);
}
```

### Typography

Use available system fonts with graceful fallback:

- Headings and large metrics: `Space Grotesk`, fallback `Arial`
- Body text: `Manrope`, fallback `Segoe UI`
- Labels and metadata: `Monospaced`, fallback `Consolas`

Recommended typography:

| Element | Font | Size | Weight |
|---|---|---:|---|
| Product name | Space Grotesk | 18 px | Bold |
| Page title | Space Grotesk | 32–38 px | Semibold |
| Panel title | Space Grotesk | 16 px | Semibold |
| Metric value | Space Grotesk | 26 px | Semibold |
| Body text | Manrope | 12–14 px | Regular |
| Navigation | Manrope | 12 px | Semibold |
| Metadata / labels | Monospaced | 9–10 px | Regular/Medium |
| Table content | Manrope | 11–12 px | Regular |

If the preferred fonts are not installed, use:

```java
new Font("SansSerif", Font.PLAIN, 12)
new Font("SansSerif", Font.BOLD, 14)
new Font("Monospaced", Font.PLAIN, 10)
```

### Spacing

Use an 8 px base spacing system:

```text
8, 16, 24, 32, 40 px
```

Recommended dimensions:

- Sidebar width: `250 px`
- Top bar height: `76 px`
- Main content horizontal padding: `40 px`
- Panel radius: `14 px`
- Control radius: `8 px`
- Small badge radius: `5–6 px`
- Standard panel padding: `20–22 px`

### Borders and Shadows

Use subtle borders instead of heavy outlines:

```java
new LineBorder(new Color(173, 205, 234, 28), 1, true)
```

Implement soft shadows with either:

- A reusable `ShadowPanel` that paints translucent offset rectangles; or
- A custom `paintComponent` implementation using several blurred-looking translucent layers.

Do not use platform-default Swing borders for major panels.

---

## Sidebar Navigation

### Sidebar Appearance

The sidebar is fixed on the left and occupies approximately 250 px.

Background:

```text
Top: #0C1C2E
Bottom: #07111E
```

Add a subtle right border and a faint cyan edge glow near active navigation items.

The sidebar must contain:

1. Brand block
2. Workspace switcher
3. Navigation tree
4. Profile entry
5. Help card

### Brand Block

Top-left brand block:

```text
[bar graph logo] LMS
                  Library Management
```

Use a compact geometric logo made from three vertical bars. The logo should be cyan with a subtle glow.

Text:

- `LMS` in bold uppercase
- `Library Management` in small muted text

### Workspace Switcher

Create a compact panel below the brand:

```text
[AU]  Admin workspace                 ●
      Central Library · 01
```

Use:

- 28–30 px avatar square
- Rounded surface background
- Green live-status dot
- Muted secondary line

### Navigation Sections

Navigation labels:

```text
COMMAND CENTER
MANAGEMENT
CONFIGURATION
```

Use uppercase monospaced labels in muted blue-gray.

The complete navigation tree must be:

```text
ADMIN
│
├── Dashboard
│
├── Users
│   ├── Students
│   └── Librarians
│
├── Books
│   ├── Books
│   ├── Categories
│   ├── Authors
│   └── Publishers
│
├── Transactions
│   ├── All Transactions
│   ├── Issued Books
│   ├── Returned Books
│   ├── Overdue Books
│   └── Renewals
│
├── Reports
│   ├── Book Reports
│   ├── User Reports
│   ├── Circulation Reports
│   ├── Overdue Reports
│   └── Fine Reports
│
├── Settings
│   ├── Library Information
│   ├── Borrowing Rules
│   ├── Fine Rules
│   └── System Preferences
│
└── Profile
    ├── View Profile
    ├── Edit Profile
    ├── Change Password
    └── Logout
```

### Navigation Item States

Default:

- Transparent background
- Muted text
- Muted blue-gray icon
- 9–10 px vertical padding

Hover:

- Background `SURFACE_3`
- Text becomes `TEXT`
- Icon becomes `CYAN`

Active:

- Background gradient or translucent cyan surface
- 2 px cyan accent line on the left
- White text
- Cyan icon

Expandable groups:

- Use `⌄` or a custom chevron icon on the right
- Rotate or swap to `⌃` when expanded
- Child rows are indented 38–42 px
- Child counts appear right-aligned in faint monospaced text

Transaction alert:

- Show a red badge containing `12` beside Transactions
- Overdue Books child item should use red text for its count

### Sidebar Help Card

At the bottom:

```text
(?) Need a hand?
    Open admin guide                         ↗
```

Use a top divider, muted text, and a simple circular help icon.

---

## Top Bar

The top bar spans the content area and is approximately 76 px high.

Left side:

```text
ADMIN / DASHBOARD
```

Use monospaced uppercase breadcrumb text:

- `ADMIN` muted
- `/` faint
- Current page cyan

Right side:

1. Global search field
2. Theme toggle
3. Notification button with red count badge
4. Administrator profile chip

### Search Field

Dimensions approximately `218 x 34 px`.

Appearance:

```text
⌕  Search anything...                    ⌘ K
```

Use a dark translucent background, subtle border, and compact keyboard-hint badge.

Behavior:

- Clicking focuses the text field
- `Ctrl + K` or `Cmd + K` focuses the search field
- Search filters visible table records
- Empty search restores all records

### Theme Toggle

Toggle between dark and light themes.

Dark theme icon: sun-like glyph

Light theme icon: moon-like glyph

The prototype is dark-first, but the light theme should preserve:

- Clear text contrast
- Cyan as the primary accent
- Soft gray-blue surfaces
- Green, amber, and red status meanings

### Notifications

Button with a small red circular badge containing `3`.

On click, show a Swing toast or compact popup:

```text
3 notifications:
2 overdue alerts
1 backup complete
```

### Profile Chip

Display:

```text
[AM] Alex Morgan
     Super admin             ⌄
```

Use a circular gradient avatar and muted role text.

---

## Dashboard Header

Main content starts with a page header.

Eyebrow line:

```text
WEDNESDAY, 17 SEPTEMBER 2026   ● LIVE SYSTEM
```

Title:

```text
Good morning, Alex.
```

The final period should be cyan.

Subtitle:

```text
Here’s what’s happening across your library today.
```

Right-side actions:

- `Export report` ghost button with download icon
- `Quick action` cyan primary button with plus icon

### Quick Action Behavior

Clicking Quick action opens a modal or dialog titled:

```text
Start an operation
```

Description:

```text
Choose a quick operation from the shortcuts below or use the navigation tree.
```

Buttons:

- Cancel
- Continue →

---

## Metric Cards

Display four cards in a single row on large windows and two columns on smaller windows.

### Card 1: Total Books

```text
TOTAL BOOKS                         [▤]
12,640
↗ 8.4%  vs last month       mini bars
```

Accent: cyan.

### Card 2: Active Members

```text
ACTIVE MEMBERS                      [♙]
1,284
↗ 12.7% vs last month       mini bars
```

Accent: purple.

### Card 3: Books Issued

```text
BOOKS ISSUED                        [⇄]
324
↗ 5.2%  vs last month       mini bars
```

Accent: amber.

### Card 4: Overdue Books

```text
OVERDUE BOOKS                       [!]
12
↘ 2.1%  vs last month       mini bars
```

Accent: red. The trend can remain green if overdue volume improved.

### Card Styling

Each card must include:

- Thin 2 px accent line at top
- Dark gradient surface
- Subtle shadow
- Small uppercase/monospaced label
- Large metric value
- Compact trend indicator
- Tiny seven-bar sparkline
- Small icon tile in the top-right corner

Use a reusable Swing component:

```java
class MetricCard extends JPanel {
    void setLabel(String label);
    void setValue(String value);
    void setTrend(String trend, boolean positive);
    void setAccent(Color accent);
}
```

---

## Circulation Activity Panel

Place this panel in the primary content column below the metric cards.

Header:

```text
ACTIVITY OVERVIEW
Circulation activity                              [Last 7 days ▼]
```

Legend:

```text
cyan line     Issued 1,849
purple line   Returned 1,208
```

Chart:

- Java2D line chart
- Two smooth lines
- Very subtle translucent area fills
- Dashed horizontal grid lines
- Y-axis: `400`, `300`, `200`, `100`, `0`
- X-axis: `11 Sep` through `17 Sep`
- Cyan line for issued books
- Purple line for returned books
- Tooltip on mouse hover is recommended

The chart should be implemented without external chart libraries unless the project already includes one. Prefer a reusable custom component:

```java
class CirculationChart extends JPanel {
    private List<Integer> issuedValues;
    private List<Integer> returnedValues;

    @Override
    protected void paintComponent(Graphics g) {
        // draw grid, axes, labels, lines, fills, points, tooltip
    }
}
```

Dropdown options:

- Last 7 days
- Last 30 days
- Last 90 days

Changing the range should update the chart data or show a prototype status message.

---

## Quick Actions Panel

Place this panel to the right of the circulation chart.

Header:

```text
SHORTCUTS
Quick actions                                      •••
```

Rows:

1. **Add a new book** — Register a new title in the catalog
2. **Register a user** — Create a student or librarian account
3. **Issue a book** — Start a new circulation transaction
4. **Generate report** — Build a custom library report

Each row includes:

- Colored icon tile
- Strong title
- Muted supporting text
- Right arrow
- Top divider except on the first item

Use a reusable component:

```java
class QuickActionRow extends JPanel {
    void setTitle(String title);
    void setDescription(String description);
    void setAccent(Color accent);
    void setAction(Runnable action);
}
```

Clicking any row should open a modal/dialog or route to the appropriate screen.

---

## Overdue Books Table

Place this panel below the chart and quick actions.

Header:

```text
REQUIRES ATTENTION
Overdue books                              View all →
```

Toolbar:

```text
12 records                                  ☷ Filter
```

Columns:

```text
BOOK TITLE | MEMBER | DUE DATE | FINE | STATUS | ACTIONS
```

Rows:

### Row 1

- Book: `Atomic Habits`
- Author and code: `James Clear · BK-10294`
- Member: `Riya Shah`
- Member code: `STU-00841`
- Due date: `14 Sep 2026`
- Detail: `3 days overdue`
- Fine: `$4.50`
- Status: `Overdue`

### Row 2

- Book: `The Design of Everyday Things`
- Author and code: `Don Norman · BK-08412`
- Member: `Marcus Lee`
- Member code: `STU-00729`
- Due date: `15 Sep 2026`
- Detail: `2 days overdue`
- Fine: `$3.00`
- Status: `Overdue`

### Row 3

- Book: `Clean Code`
- Author and code: `Robert C. Martin · BK-11028`
- Member: `Sofia Patel`
- Member code: `STU-00618`
- Due date: `16 Sep 2026`
- Detail: `1 day overdue`
- Fine: `$1.50`
- Status: `Reminder sent`

### Table Styling

- Header text in small uppercase monospaced font
- Rows separated by subtle borders
- Book cell includes a compact colored book-cover tile
- Overdue detail text in red
- Fine value in white
- Status uses compact pill badges
- Actions column uses a three-dot button

Status colors:

```text
Overdue: red text on translucent red background
Reminder sent: amber text on translucent amber background
Returned: green text on translucent green background
```

Clicking a row action should open a contextual action dialog:

```text
Overdue record actions
Send a reminder, record a return, or waive the fine for this member.
```

Recommended Swing implementation:

- `JTable`
- Custom `TableCellRenderer`
- Custom `TableCellEditor` for action button
- `JScrollPane` with a dark-themed viewport
- Disable default grid lines and draw custom row separators

---

## Library Health Panel

Place this panel to the right of the overdue table.

Header:

```text
SYSTEM PULSE
Library health                                  92%
```

Center:

- Circular 92% progress ring
- Center label: `Excellent`
- Supporting line: `All systems operational`

Implement the progress ring with Java2D `Arc2D` and a custom `paintComponent` method.

Health rows:

```text
● Catalog database                    99.9%
● Circulation service                 99.8%
● Backup status                       Today, 02:00
```

Use:

- Green dot for operational systems
- Amber dot for informational/attention status
- White or muted values aligned to the right

Bottom button:

```text
View system status                              →
```

---

## Footer

At the bottom of the content view:

```text
LMS Admin Console v2.4.0                 ● Last synced 2 min ago
```

Use small monospaced text and a green live-status dot.

---

## Interaction Requirements

Implement these interactions in Swing:

### Navigation

- Clicking Dashboard activates the dashboard view
- Clicking Users expands/collapses Students and Librarians
- Clicking Books expands/collapses Books, Categories, Authors, Publishers
- Clicking Transactions expands/collapses all transaction categories
- Clicking Reports expands/collapses report categories
- Clicking Settings expands/collapses configuration categories
- Clicking Profile opens a profile menu or profile view
- Active item receives cyan accent styling

### Theme Toggle

- Toggle between dark and light theme
- Update all registered components through a theme refresh method
- Repaint the complete window after switching
- Persist the preference using `java.util.prefs.Preferences`

Example:

```java
Preferences prefs = Preferences.userNodeForPackage(LmsTheme.class);
prefs.putBoolean("darkMode", true);
```

### Global Search

- Focus with `Ctrl + K` / `Cmd + K`
- Filter overdue table rows by title, author, member, or code
- Show a small status toast when search is active

### Export Report

Clicking Export report should show a confirmation toast or dialog:

```text
Export started
Your circulation report is being prepared.
```

A later implementation may export CSV or PDF.

### Notifications

Clicking the notification icon should show a small popup with:

- 2 overdue alerts
- 1 backup completed

### Quick Actions

All quick actions should either:

- Open the existing LMS dialog/class; or
- Open a clearly labeled placeholder dialog in the prototype.

### Chart Range

Changing the chart range updates the chart and shows a small status message:

```text
Activity range updated
Chart updated to last 30 days.
```

### Modal Dialogs

Use custom `JDialog` instead of `JOptionPane` for important prototype dialogs. Match the dark panel style:

- Navy gradient or solid surface
- Cyan border highlight
- Rounded corners where feasible
- Title in Space Grotesk-like font
- Muted supporting copy
- Ghost Cancel button
- Cyan Continue button

---

## 3D Background Integration

Use the existing or improved `ThreeDBackgroundPanel` behind the Admin Panel.

The background must remain subtle and never compete with controls.

Required visual elements:

- Deep navy atmospheric gradient
- Perspective grid floor in the lower half
- Small depth-based cyan, blue, and purple particles
- Thin connecting lines between nearby nodes
- Floating wireframe polygons
- Soft mouse-parallax response
- Horizontal scan-line texture at low opacity
- Optional cursor glow

Animation requirements:

- Use a Swing `Timer` around 30–33 ms
- Stop the timer in `removeNotify()`
- Avoid creating new objects inside every frame where possible
- Keep opacity low behind panels
- Respect reduced-motion preference if the application later supports it

Example:

```java
private final Timer animationTimer = new Timer(32, event -> {
    updateParticles();
    updateShapes();
    repaint();
});
```

The background should be resilient when the window is resized.

---

## Reusable Component Architecture

Create reusable Swing components rather than one very large `HomeTemplate` method.

Recommended classes:

```text
librarymanagement/
├── LmsTheme.java
├── ThreeDBackgroundPanel.java
├── AdminShell.java
├── AdminSidebar.java
├── AdminTopBar.java
├── DashboardView.java
├── MetricCard.java
├── CirculationChart.java
├── QuickActionRow.java
├── OverdueBooksPanel.java
├── LibraryHealthPanel.java
├── LmsTable.java
├── LmsButton.java
├── LmsDialog.java
├── ToastManager.java
└── ProfileMenu.java
```

If a full refactor is too large, implement the minimum viable structure first:

```text
ThreeDBackgroundPanel
HomeTemplate
AdminPanel
MetricCard
CirculationChart
OverdueBooksPanel
LibraryHealthPanel
```

All components should expose clear setters and avoid duplicating color literals.

---

## Swing Rendering Guidance

### Anti-aliasing

For all custom painting:

```java
Graphics2D g2 = (Graphics2D) g.create();
g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
g2.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
```

Always dispose the copied graphics object:

```java
g2.dispose();
```

### Rounded Panels

Use custom panels with:

```java
setOpaque(false);
```

Then paint a rounded rectangle using:

```java
g2.fillRoundRect(0, 0, getWidth(), getHeight(), 14, 14);
```

### Layout Managers

Prefer:

- `BorderLayout` for shell structure
- `GridBagLayout` or nested `GridLayout` for dashboard regions
- `BoxLayout` for vertical sidebar navigation
- `GridBagLayout` for metric cards
- `CardLayout` for switching dashboard/modules

Avoid relying on absolute positioning for the entire application. Absolute positioning is acceptable only for the existing image-based legacy components or small custom overlays.

### Event Dispatch Thread

All UI creation and updates must occur on the EDT:

```java
SwingUtilities.invokeLater(() -> {
    new AdminShell().setVisible(true);
});
```

Database operations must not block the EDT. Use `SwingWorker` for:

- Loading dashboard metrics
- Loading table data
- Exporting reports
- Updating user/book records

---

## Responsive Desktop Behavior

The application is desktop-first, but should gracefully support resizing.

At approximately 1100 px width:

- Metric cards become two columns
- Dashboard chart and quick actions stack vertically
- Overdue table and health panel stack vertically

At approximately 760 px width:

- Sidebar becomes a slide-out drawer
- Top bar shows a menu button
- Profile text collapses to avatar only
- Search input becomes icon-first
- Content padding reduces

Do not allow important table columns to become unreadably narrow. Use horizontal scrolling for tables.

---

## Accessibility and Usability

Implement:

- Keyboard focus indicators
- Tooltips for icon-only buttons
- Clear button labels
- Meaningful accessible text where possible
- Strong contrast between text and surfaces
- Non-color-only status cues
- Escape key closes dialogs and popup menus
- Enter activates focused primary actions
- Tab order follows visual order

Icon-only buttons must include:

```java
setToolTipText("Toggle theme");
```

---

## Prototype Data

Use the following initial dashboard values:

```text
Total books: 12,640
Active members: 1,284
Books issued: 324
Overdue books: 12

Issued this period: 1,849
Returned this period: 1,208

Library health: 92%
Catalog database: 99.9%
Circulation service: 99.8%
Backup status: Today, 02:00
```

Use the overdue records described in the table section.

The prototype may use in-memory data, but structure the code so the existing database repositories can replace it later.

---

## Quality Checklist

Before considering the Java Swing implementation complete, verify:

- [ ] Main window opens without layout exceptions
- [ ] Background animation starts and stops correctly
- [ ] Sidebar navigation expands and collapses
- [ ] Active navigation state is visually clear
- [ ] Dashboard metrics align in a clean grid
- [ ] Chart renders without flicker
- [ ] Table supports scrolling and custom cell styling
- [ ] Overdue status colors are correct
- [ ] Health ring displays the correct percentage
- [ ] Theme toggle updates all major components
- [ ] Search filters overdue records
- [ ] Quick action buttons open dialogs or existing workflows
- [ ] Export report shows feedback
- [ ] Notification button shows feedback
- [ ] Escape closes dialogs
- [ ] Window resizing does not overlap major panels
- [ ] No database calls run directly on the EDT
- [ ] No external web dependencies are required
- [ ] Existing login and database behavior remains intact
- [ ] Java compilation succeeds with the project’s configured JDK

---

## Final Implementation Instruction

Implement the LMS Java Swing Admin Panel so that a user opening the desktop application sees a polished command center matching this design. Preserve the existing LMS application behavior and package structure, but refactor the presentation into reusable components wherever practical.

The final result should feel like the HTML prototype translated into a native desktop application—not like a browser page embedded in Java.

Prioritize:

1. Visual fidelity to the prototype
2. Clear operational workflows
3. Smooth Java2D rendering
4. Reusable Swing components
5. Responsive desktop layout
6. Database-ready architecture
7. Maintainable code
8. Reliable interaction states
