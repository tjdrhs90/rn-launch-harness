# Contributing

## Commit & PR rules

- [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix(scope):`, `docs:`, `chore:`).
- **Never add AI-authorship trailers** — no `Co-Authored-By`, no "Generated with…" line.
- No credentials or personal info in the diff.
- Keep PRs small and focused; open an issue first for larger changes.

## Releasing

하니스가 만들어 내는 결과물이 달라지는 변경은 릴리스로 나간다. **버전 올리기를
변경과 같은 커밋에 넣는다** — 따로 떼면 잊는다.

버전이 **두 군데**에 있다. 둘 다 올려야 한다.

| 파일 | 역할 | 빠뜨리면 |
| --- | --- | --- |
| `.claude-plugin/plugin.json` | 플러그인 자체의 버전 | 설치 후 표시되는 버전이 옛것 |
| `.claude-plugin/marketplace.json` | **마켓플레이스가 읽는 버전** | 이미 설치한 사람에게 업데이트가 보이지 않는다 |

절차:

1. `.claude-plugin/plugin.json` 의 `version` 을 올린다. 생성 결과나 스킬 동작이
   바뀌면 minor, 문구·안내만 고쳤으면 patch.
2. `.claude-plugin/marketplace.json` 안 `plugins[].version` 도 **같은 값**으로 맞춘다.
3. 푸시한 뒤 태그와 릴리스를 만든다.

```bash
git tag vx.y.z && git push origin main vx.y.z
gh release create vx.y.z --title "vx.y.z — <요약>" \
  --notes "<증상 · 원인 · 어떻게 확인했는지>"
```

릴리스 노트에는 무엇을 고쳤는지만 적지 말고 **어떤 증상이었고 왜 그랬는지**를
남긴다. 이 저장소에는 아직 `CHANGELOG.md` 가 없어서 GitHub 릴리스가 유일한
기록이다.

### 왜 이걸 적어 두나

2026-09-01 에 v1.11.0 을 내면서 `plugin.json` 만 올리고 `marketplace.json` 을
빠뜨렸다. 태그와 릴리스도 만들지 않았다. 버전 필드는 올라갔지만 실제로는
아무에게도 업데이트가 가지 않는 상태였다.

같은 일이 이웃 저장소(`flutter-flame-harness`)에서도 있었다 — 0.16.0 부터
0.19.0 까지 태그가 끊겼고, 그래서 거기에 이 절차를 적었다. 여기에도 적는다.
