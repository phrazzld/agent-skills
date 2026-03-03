# device specs + store sizes

Use store "buckets" not every device model. Fastlane covers model mapping.

## iPhone (portrait pixels)
- 6.7-inch: 1290 × 2796
- 6.5-inch: 1242 × 2688
- 6.1-inch (Pro): 1179 × 2556
- 6.1-inch (non-Pro): 1170 × 2532
- 5.8-inch: 1125 × 2436
- 5.5-inch: 1242 × 2208

## iPad (portrait pixels)
- 12.9-inch: 2048 × 2732
- 11-inch: 1668 × 2388
- 10.5-inch: 1668 × 2224
- 9.7-inch: 1536 × 2048

## Android common targets
- Phone: 1080 × 1920 (16:9) or 1440 × 3120 (19.5:9)
- 7-inch tablet: 1200 × 1920
- 10-inch tablet: 1600 × 2560

## App Store required sizes (practical set)
- Provide at least one modern iPhone bucket: 6.7-inch or 6.5-inch
- Provide at least one iPad bucket if iPad supported: 12.9-inch recommended
- Landscape variants required for landscape-only apps

## Play Store required sizes
- PNG or JPEG, 16:9 to 9:16 aspect ratio
- Min dimension: 320px; max dimension: 3840px
- Separate sets: phone, 7-inch tablet, 10-inch tablet (if supported)

When in doubt, generate more buckets and let stores scale down.

