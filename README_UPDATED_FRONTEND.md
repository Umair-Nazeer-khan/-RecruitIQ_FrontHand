# RecruitIQ — Whole Frontend UI Update

This is the complete updated `lib/` folder for the RecruitIQ FYP frontend.

## Updated UI direction

The frontend now follows one consistent **AI recruitment dashboard** design:

**Authentication → Dashboard → Resume Upload → AI Parsing → Job Requirements → Matching → Match Results → Candidate Detail → Shortlist**

### Responsive behavior
- Mobile: bottom Material 3 NavigationBar.
- Tablet/Desktop: extended NavigationRail with persistent FYP modules.
- Content widths expand on large screens instead of leaving a narrow phone-sized layout.
- Lists/cards use responsive wrapping and grids where appropriate.
- Web no longer forces portrait orientation.

### FYP committee presentation points visible in UI
- AI Screening Pipeline:
  **PyMuPDF → spaCy NLP → TF-IDF + Cosine Similarity → Ranking**
- Match score and component scores.
- Missing skills and candidate recommendation.
- Candidate shortlist workflow.
- Resume upload and parsed candidate profile.
- Job requirements and weighted matching.
- Professional empty/loading/error states.

## Files updated
- `lib/views/screens/dashboard_screen.dart` — redesigned dashboard and responsive navigation.
- `lib/views/screens/upload_screen.dart` — wider responsive upload experience.
- `lib/views/screens/job_requirements_screen.dart` — responsive content width.
- `lib/views/screens/match_results_screen.dart` — responsive content width.
- `lib/views/screens/shortlist_screen.dart` — responsive content width.
- `lib/views/screens/candidate_detail_screen.dart` — responsive content width.
- `lib/views/screens/login_screen.dart` — retained existing authentication logic and visual system.
- `lib/views/screens/register_screen.dart` — retained existing authentication logic and visual system.
- `lib/views/widgets/shared_widgets.dart` — upgraded common components and added reusable AI/status/responsive widgets.
- `lib/main.dart` — web-safe orientation handling.

Backend/API/ViewModel logic was intentionally preserved.

## After replacing your `lib` folder

Run:

```bash
flutter clean
flutter pub get
dart format lib
flutter run
```

If your installed Flutter SDK is older and reports `WidgetState` as unknown,
replace `WidgetState.selected` with `MaterialState.selected` in the mobile
NavigationBar label style.
