![image.png](./images/NoteUIwithCapsule.png)

### **Updated Final Image Prompt**

I will update the prompt to include this new floating input element, ensuring the "matte white" aesthetic is applied to it as well (so it looks like a floating layer above the editor).

> A high-fidelity UI design render of a **minimalist desktop note-taking app with AI integration**, strictly adhering to a premium matte white aesthetic.
> 
> 
> **Global Structure:**
> 
> - **Container:** A single, expansive white rounded rectangular card floating on a soft off-white background.
> - **Split:** Divided vertically into a **Left Sidebar** and a **Right Editor** by a subtle, indented vertical grey divider.
> 
> **1. Left Sidebar (The Directory):**
> 
> - **Header:** A clean, bold text header "**My Workspace**".
> - **Content:** A simple, indented hierarchical tree with items like "▶ Projects", "▶ Notes", "▶ Personal", using small chevron arrows and subtle pastel icons.
> - **Footer:** A minimalist "**+ New Page**" button at the very bottom.
> 
> **2. Right Editor Pane (The Content & AI):**
> 
> - **Top Tab Bar:** A horizontal strip at the top. The active tab "**😊 Omni-Bar**" is highlighted; inactive tabs are slightly greyed out.
> - **Document Content:** The rich content (Title, Breadcrumbs, Paragraphs, Data Table, Code Block) remains exactly as before—clean, high-readability, dark grey text.
> - **The Key Addition - Floating AI Input:** Floating at the **bottom center** of this editor pane (hovering over the content) is a **capsule-shaped white input bar**.
>     - **Visuals:** It has a distinct but soft drop shadow to separate it from the editor background.
>     - **Content:** Placeholder text "**Ask me anything...**" on the left, and **Microphone** and **Send** icons on the right.
>     - **Style:** It looks like a premium, floating command center within the note.
> 
> **Style:** High-readability, distraction-free, soft diffuse shadows, and a clean, airy "Apple-like" finish.
> 

---

### **Updated Flutter Implementation Guide (For the Input Bar)**

You need to tell your developer how to layer this floating input bar on top of the text editor.

### **Add to "Right Editor" Section:**

**Use a `Stack` Layout:**
The Editor Pane is no longer just a `Column` or `ListView`. It must be a `Stack` to allow the input bar to float on top.

Dart

`// Inside the Right Expanded Area
Expanded(
  child: Stack(
    children: [
      // Layer 1: The Scrollable Content
      Positioned.fill(
        child: Column(
          children: [
            TabBarWidget(),
            Expanded(child: SingleChildScrollView(child: EditorContentWidget())), // Add padding-bottom to avoid overlap
          ],
        ),
      ),

      // Layer 2: The Floating AI Input Bar
      Positioned(
        bottom: 32, // Distance from bottom
        left: 48,   // Margins to center it
        right: 48,  // Margins to center it
        child: Center( // Center horizontally if you want max-width
          child: Container(
            width: 600, // Max width constraint
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Capsule shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Slightly stronger shadow for floating effect
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 24),
                Expanded(child: Text("Ask me anything...", style: TextStyle(color: Colors.grey))),
                Icon(Icons.mic, color: Colors.grey),
                SizedBox(width: 16),
                Icon(Icons.send, color: Colors.grey),
                SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)`

**Crucial Detail:** Tell the developer to add `padding: EdgeInsets.only(bottom: 100)` to the `EditorContentWidget` (the scrolling text area). This ensures that the last paragraph of text doesn't get hidden behind the floating input bar when the user scrolls to the very bottom.