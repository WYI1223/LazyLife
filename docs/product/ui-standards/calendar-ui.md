![image.png](./images/CalendarUI.png)

### 1. Image Prompt (用于生成/留档)

这个 Prompt 强调了“一体化容器”、“内部垂直分割线”以及具体的配色方案。

**英文 Prompt:**

> A clean, minimalist UI design render of a desktop weekly calendar interface, featuring a **single, large, unified white rounded rectangular container** floating on a soft off-white background.
> 
> 
> **Layout & Structure:**
> 
> - **One Unified Card:** The entire interface is one continuous white card with soft diffuse shadows.
> - **Split View:** Inside the card, a layout is divided into a narrower left sidebar and a wider right main area.
> - **The Divider:** Separating the two areas is a **thin, subtle grey vertical line** that does not touch the top or bottom edges (it has vertical indentation).
> 
> **Content:**
> 
> - **Left Sidebar:** Features a mini month view calendar at the top and a list of categories below (Work, Personal, Study) with circular colored dots.
> - **Right Main View:** A spacious weekly time grid.
> - **Events:** Floating **pastel-colored event blocks** (soft sage green, baby blue, light purple) with rounded corners, sitting on top of the grid.
> - **Current Time:** A crisp red horizontal line crossing the grid.
> 
> **Style:** Premium matte finish, high-fidelity, "Apple-like" clean aesthetic.
> 

---

### 2. 给 Flutter 开发人员的最终实现指南

请将以下文档发送给您的开发人员。这部分明确了如何用 Flutter 代码还原这种“一体化布局”。

### Flutter 组件开发需求：Unified Calendar Card

**核心设计目标：**
我们要摒弃传统的“侧边栏 + 内容区”的分离式布局，改为实现一个**巨大的、悬浮的、单一容器** (`Single Container`)，内部包含侧边栏和日历视图。

### A. 布局结构 (Layout Architecture)

请使用以下 Widget 树结构：

Plaintext

`Container (Root)
  └── BoxDecoration (White color, BorderRadius 24, BoxShadow)
  └── Row
      ├── Column (Left Sidebar: Width ~260px)
      ├── VerticalDivider (The subtle separator)
      └── Expanded (Right Main Content)
          └── ClipRRect (To clip content to the right-side rounded corners)
              └── SingleChildScrollView (The Scrollable Calendar Grid)`

### B. 关键代码实现细节

**1. 容器与阴影 (The Container):**
这是整个界面的灵魂。不要给 Sidebar 单独加背景，背景色和圆角只加在这个最外层的 Container 上。

Dart

`Container(
  margin: EdgeInsets.all(24), // 悬浮感：外边距
  decoration: BoxDecoration(
    color: Colors.white, // 统一背景
    borderRadius: BorderRadius.circular(24), // 统一大圆角
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06), // 极淡的阴影
        blurRadius: 30,
        offset: Offset(0, 10),
      ),
    ],
  ),
  child: Row( ... ) // 内部布局
)`

**2. 那个精致的分割线 (The Divider):**
这是设计图中最高级的部分。请使用 `VerticalDivider` 并配合 `indent`。

Dart

`VerticalDivider(
  width: 1,            // 占位宽度
  thickness: 1,        // 绘制线条粗细
  color: Colors.grey.withOpacity(0.2), // 非常淡的灰色
  indent: 30,          // ★ 关键：顶部缩进，不顶头
  endIndent: 30,       // ★ 关键：底部缩进，不触底
)`

**3. 粉彩色调色板 (Pastel Colors):**
为了还原图中的高级感，请使用以下特定的粉彩颜色值来渲染日程块 (Event Blocks)：

Dart

`class AppColors {
  static const Color pastelGreen = Color(0xFFD6E6CE); // Sage Green
  static const Color pastelBlue = Color(0xFFCBE4F9);  // Baby Blue
  static const Color pastelPurple = Color(0xFFE6D6F5); // Light Lavender
  static const Color redIndicator = Color(0xFFFF5A5F); // Current Time Line
  static const Color textDark = Color(0xFF2C2C2C);     // Primary Text
  static const Color textGrey = Color(0xFF8E8E93);     // Secondary Text
}`

### C. 右侧日历的特殊处理

由于外层容器有 `BorderRadius: 24`，右侧的滚动视图（周视图）如果不做处理，滚动时内容会“溢出”圆角，破坏美感。

- **必须使用 `ClipRRect`** 包裹右侧的 `Expanded` 区域。
- 只需裁剪右侧两个角：Dart
    
    `ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: WeekView(...),
    )`