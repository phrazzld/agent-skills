# Mobile Excellence Standards

Mobile is NOT responsive desktop—it's a different product requiring separate design thinking.

## The Anti-"Sucks" Checklist

Mobile experiences that "suck" typically have:
- [ ] Tiny touch targets (< 44px)
- [ ] No gesture support beyond tap
- [ ] No haptic feedback
- [ ] Desktop layout squeezed to mobile
- [ ] Hamburger menus hiding critical actions
- [ ] Horizontal scrolling on tables
- [ ] Small text unreadable outdoors
- [ ] No pull-to-refresh
- [ ] Instant state changes (no physics)
- [ ] Click events instead of touch events

## Touch Libraries

### Gesture Libraries
- **@use-gesture/react**: Unified gestures (drag, pinch, scroll, wheel, hover)
- **react-spring + @use-gesture**: Physics-based animated gestures
- **framer-motion**: Gesture recognition + animation + layout animations
- **swiper**: Professional touch sliders with momentum

### Haptic Feedback
- **Web Vibration API**: `navigator.vibrate([50])` for basic haptics
- **@capacitor/haptics**: `Haptics.impact({ style: 'medium' })` for native feel
- **React Native Haptics**: Full haptic vocabulary on mobile

### Scroll Enhancements
- **overscroll-behavior**: CSS for pull-to-refresh control
- **scroll-snap-type**: Native snap points for carousels
- **Lenis/Locomotive Scroll**: Smooth scroll with inertia
- **@tanstack/virtual**: Virtualized lists for performance

## Quality Targets

### Touch Targets
- Minimum: 44x44px (Apple HIG)
- Comfortable: 48x48px (Material Design)
- Generous: 56x56px (for key actions)

### Gesture Vocabulary
| Gesture | Common Use |
|---------|------------|
| Swipe left/right | Navigate, reveal actions |
| Pull down | Refresh content |
| Pinch | Zoom where meaningful |
| Long press | Context menu, reorder |
| Double tap | Zoom or favorite |
| Edge swipe | Back navigation |

### Haptic Patterns
| Pattern | Use Case |
|---------|----------|
| Light | Selection feedback, toggles |
| Medium | Action confirmation, button press |
| Heavy | Important completion, success |
| Error | Distinct from success, warns user |
| Selection | List item selection |

## Mobile-First Layout Patterns

### Bottom Navigation > Hamburger
```tsx
// Thumb-zone optimized navigation
<nav className="fixed bottom-0 inset-x-0 flex justify-around py-2 bg-white border-t">
  <NavItem icon={Home} label="Home" />
  <NavItem icon={Search} label="Search" />
  <NavItem icon={Plus} label="Create" primary />
  <NavItem icon={Bell} label="Activity" />
  <NavItem icon={User} label="Profile" />
</nav>
```

### Safe Area Handling
```css
/* Respect device notches and home indicators */
.mobile-container {
  padding-bottom: env(safe-area-inset-bottom);
  padding-top: env(safe-area-inset-top);
}
```

### Touch-Friendly Forms
```tsx
// Large inputs, clear labels, big submit button
<input
  type="email"
  className="w-full p-4 text-lg rounded-xl border-2 focus:border-blue-500"
  inputMode="email"
  autoComplete="email"
/>
```

## Physics-Based Interactions

### Spring Animation (react-spring)
```tsx
import { useSpring, animated } from '@react-spring/web'
import { useDrag } from '@use-gesture/react'

const [{ x }, api] = useSpring(() => ({ x: 0 }))

const bind = useDrag(({ down, movement: [mx] }) => {
  api.start({ x: down ? mx : 0, immediate: down })
})

<animated.div {...bind()} style={{ x }} />
```

### Pull-to-Refresh Physics
```tsx
// Natural bounce, not instant snap
const bind = useDrag(({ movement: [, my], last }) => {
  if (my > 60 && last) {
    onRefresh()
  }
  api.start({
    y: last ? 0 : Math.min(my * 0.4, 100), // Resistance
    config: last ? config.wobbly : config.stiff
  })
})
```

## Testing Mobile Excellence

### Manual Checks
1. Use actual device, not just devtools
2. Test in bright sunlight (contrast, text size)
3. Test with one thumb only (reachability)
4. Test on slow network (loading states)
5. Test offline behavior

### Automated Checks
```bash
# Lighthouse mobile audit
npx lighthouse https://yoursite.com --preset=perf --form-factor=mobile

# Check touch target sizes
npx axe-core --rules touch-target-size
```

## Reference Apps (Study These)

- **Linear**: Gesture-rich, physics-perfect
- **Stripe Dashboard**: Touch-optimized data
- **Arc Browser**: Swipe navigation excellence
- **Things 3**: Haptic feedback mastery
- **Apple Music**: Scroll physics benchmark
