# EduFlow Flutter

A full-stack educational platform for Principals, Teachers, and Parents, built with Flutter and Firebase. Features onboarding, school creation, task management, mark uploads, and AI-powered question paper generation via chat interface.

## Features
- Firebase Auth (email/password)
- Firestore for users, schools, tasks, classes, students, marks
- Modular role-based dashboards (Principal, Teacher, Parent)
- School code onboarding
- Task assignment and management
- Marks upload and viewing
- AI-powered question paper generation (via MongoDB REST API)
- Modern chat-based AI assistant UI

## Structure
```
/lib
  /auth
  /dashboard
  /principal
  /teacher
  /parent
  /models
  /services
  /widgets
```

## Getting Started
1. Install Flutter SDK (>=3.0.0)
2. Run `flutter pub get`
3. Set up Firebase project (see `/lib/services/firebase_service.dart`)
4. Configure MongoDB REST API endpoint in `/lib/services/question_api_service.dart`

## State Management
- Uses Riverpod for scalable state management

## Security & Branch Protection
- Only you have write access to this repository. No collaborators are added.
- All code changes are tracked via Git for easy rollback and history.
- For safety, always push your changes to the `main` branch. If you want to try risky changes, create a new branch with:
  ```bash
  git checkout -b feature/your-feature
  ```
  Then merge back to `main` when ready.
- If you ever want to enable branch protection (require PRs, prevent force-push), go to GitHub > Settings > Branches > Add rule for `main`.

## Contact & Support
- This project is maintained by `gexx123` (and Cascade AI assistant).
- For questions, open an issue on GitHub or document your queries in this README for future reference.

## Notes
- All logic is in Dart (no TypeScript/React)
- Voice/AI features are modular and can be enabled later

---

For detailed implementation, see the `/lib` directory and feature folders.
