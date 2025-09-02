# Chrit Design System

## 🎨 Core Design Philosophy
Modern dark UI with glassmorphism effects and vibrant gradients

## 🎯 Design Principles
1. **Dark Mode First** - Black background with subtle color accents
2. **Glassmorphism** - Semi-transparent elements with backdrop blur
3. **Gradient Accents** - Purple to blue gradients for CTAs and highlights
4. **Smooth Animations** - Subtle transitions and hover effects
5. **Minimalist Layout** - Focus on content with clean spacing

## 🌈 Color Palette

### Primary Colors
- **Background**: `bg-black` (#000000)
- **Primary Gradient**: `from-purple-600 to-blue-600`
- **Hover Gradient**: `from-purple-700 to-blue-700`
- **Text Primary**: `text-white`
- **Text Secondary**: `text-gray-400`

### Glass Effect Colors
- **Card Background**: `bg-gray-900/50` with `backdrop-blur-sm`
- **Border**: `border-gray-800`
- **Hover Border**: `border-purple-500/50`

### Background Effects
```html
<!-- Gradient Overlay -->
<div class="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-black to-blue-900/20"></div>

<!-- Animated Blobs -->
<div class="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl animate-pulse"></div>
<div class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl animate-pulse" style="animation-delay: 2s;"></div>
```

## 🧩 Component Patterns

### Container Layout
```html
<div class="min-h-screen bg-black text-white flex flex-col relative overflow-hidden">
  <!-- Background effects -->
  <!-- Content with relative z-10 -->
</div>
```

### Navigation Bar
```html
<nav class="relative z-10 flex justify-between items-center p-8">
  <div class="text-2xl font-bold bg-gradient-to-r from-purple-400 to-blue-400 bg-clip-text text-transparent">
    Logo
  </div>
  <!-- Navigation items -->
</nav>
```

### Glass Card
```html
<div class="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-2xl p-6 hover:border-purple-500/50 transition duration-300">
  <!-- Content -->
</div>
```

### Primary Button
```html
<button class="px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-xl hover:from-purple-700 hover:to-blue-700 transition duration-200 font-medium">
  Button Text
</button>
```

### Secondary Button
```html
<button class="px-6 py-3 bg-gray-800 text-white rounded-xl hover:bg-gray-700 transition duration-200">
  Button Text
</button>
```

### Input Field with Glow
```html
<div class="relative group">
  <div class="absolute inset-0 bg-gradient-to-r from-purple-600 to-blue-600 rounded-2xl blur-xl opacity-50 group-hover:opacity-75 transition duration-300"></div>
  <input type="text" class="relative w-full px-8 py-6 text-lg bg-gray-900/90 backdrop-blur-sm border border-gray-800 rounded-2xl text-white placeholder-gray-500 focus:outline-none focus:border-purple-500/50 transition-all duration-300">
</div>
```

### Gradient Text
```html
<h1 class="text-7xl font-bold bg-gradient-to-r from-white via-purple-200 to-blue-200 bg-clip-text text-transparent animate-gradient">
  Heading Text
</h1>
```

## 🎭 Animation Classes

### Custom Animations
```css
@keyframes gradient {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

.animate-gradient {
  background-size: 200% 200%;
  animation: gradient 3s ease infinite;
}
```

### Tailwind Animations
- `animate-pulse` - For background blobs
- `animate-spin` - For loading indicators
- `transition duration-300` - For hover effects
- `transition-all duration-200` - For interactive elements

## 📐 Spacing System
- **Page Padding**: `p-8`
- **Card Padding**: `p-6` or `p-12` for larger cards
- **Section Margin**: `mb-12` or `mb-16`
- **Element Gap**: `gap-4` or `gap-6`

## 🎯 Typography
- **Heading 1**: `text-7xl font-bold`
- **Heading 2**: `text-3xl font-bold`
- **Heading 3**: `text-lg font-semibold`
- **Body**: `text-base` (default)
- **Small**: `text-sm`
- **Caption**: `text-xs`

## 🔲 Border Radius
- **Cards**: `rounded-2xl`
- **Buttons**: `rounded-xl`
- **Inputs**: `rounded-2xl`
- **Small Elements**: `rounded-lg`

## 🌟 Interactive States
- **Hover**: Increase opacity, add glow, or change gradient
- **Focus**: Add purple border with 50% opacity
- **Active**: Darken gradient colors
- **Disabled**: Reduce opacity to 50%

## 📱 Responsive Design
- Mobile First approach
- Use `md:` prefix for tablet and up
- Use `lg:` prefix for desktop
- Grid changes: `grid-cols-1 md:grid-cols-3`

## 🚀 Implementation Example

```erb
<div class="min-h-screen bg-black text-white flex flex-col relative overflow-hidden">
  <!-- Background Effects -->
  <div class="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-black to-blue-900/20"></div>
  <div class="absolute inset-0">
    <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl animate-pulse"></div>
    <div class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl animate-pulse" style="animation-delay: 2s;"></div>
  </div>
  
  <!-- Main Content -->
  <div class="relative z-10">
    <!-- Your content here -->
  </div>
</div>
```

## 🎨 Quick Reference

| Element | Classes |
|---------|---------|
| Background | `bg-black` |
| Card | `bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-2xl` |
| Primary Button | `bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700` |
| Text Primary | `text-white` |
| Text Secondary | `text-gray-400` |
| Gradient Text | `bg-gradient-to-r from-white via-purple-200 to-blue-200 bg-clip-text text-transparent` |
| Input | `bg-gray-900/90 backdrop-blur-sm border border-gray-800 rounded-2xl` |