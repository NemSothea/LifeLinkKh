# Release notes template · គំរូកំណត់ចំណាំកំណែថ្មី

Copy the block below into a file, fill it in, and pass it to `gh release create … --notes-file`
(`docs/tech-lead/deploy-runbook.md`, Path A step 8). Khmer first, since that is what most users
read. Keep each list short, and describe what the user notices, not the code. The same "what's
new" lines go into the portal's **App version** tab, so installed apps show them.

The Khmer headings are `[km-review]`.

```markdown
## LifeLink KH <version> · កំណែ <version>

### អ្វីដែលថ្មី
- …

### ការកែកំហុស
- …

### បញ្ហាដែលដឹងហើយ
- … (or: មិនមានទេ)

---

### What's new
- …

### Fixes
- …

### Known issues
- … (or: None)

---

**Install / ដំឡើង:** https://lifelinkkh.vercel.app/km/download · Android 7.0 (API 24) or newer ·
ត្រូវការ Android 7.0 ឡើងទៅ

**Update / ធ្វើបច្ចុប្បន្នភាព:** install over the old version. You stay signed in. ·
ដំឡើងពីលើកំណែចាស់ អ្នកនៅតែចូលគណនីដដែល។

**Check the file / ពិនិត្យឯកសារ:** `lifelink-kh.apk.sha256` below. On a computer:
`shasum -a 256 -c lifelink-kh.apk.sha256` in the folder you downloaded both files to.

**Signing certificate SHA-256:** `<printed by build-release-apk.sh>`. It is the same for every
release. If it ever changes, do not install and tell us.
```

## Before you publish

- [ ] `mobile/pubspec.yaml` version bumped. `+N` went up.
- [ ] Built with `bash scripts/build-release-apk.sh`, which refuses a debug-signed APK.
- [ ] Installed on a real phone, over the previous release if one exists. Google and Facebook
      sign-in work.
- [ ] Both assets attached: `lifelink-kh.apk` and `lifelink-kh.apk.sha256`.
- [ ] After publishing: the portal's **App version** tab updated (Path A step 9).
- [ ] Changelog entry (`CHANGELOG.md`, when it exists).
