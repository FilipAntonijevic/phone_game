# Sum Ten

A Flutter phone game: clear an 8×15 grid of numbered circles by selecting rectangles that sum to 10.

## Rules

1. Tap **Play** on the home screen.
2. The board is **8 columns × 15 rows**. Each cell is a circle with a number from **1–9**.
3. Tap one cell to select it, then tap another. Those two points are the **diagonal corners** of a rectangle. **Empty cells can also be corners.**
4. If the sum of all remaining numbers inside that rectangle equals **10**, those circles are removed and the count is added to your **score**.
5. A **timer** runs from the start of the round.
6. The round ends when:
   - every circle is cleared → **You won**
   - no rectangle summing to 10 remains → **No more moves**

## Run (web)

```bash
flutter pub get
flutter run -d chrome --web-port=8080
```

## Run (mobile)

```bash
flutter run
```
