#!/bin/sh
# 성현님(@ssggg0) shorts-editor 레포에 index.html을 올리고 GitHub Pages를 켠다.
# 레포가 이미 있어야 한다(앱 토큰에는 레포 생성 권한이 없음: 403 createRepository).
set -u
REPO="ssggg0/shorts-editor"
URL="https://ssggg0.github.io/shorts-editor/"
cd "$(dirname "$0")" || exit 1

echo "== 1. 레포 확인 =="
gh api "repos/$REPO" --jq '.full_name + " | private=" + (.private|tostring) + " | default_branch=" + (.default_branch|tostring)' || exit 1

echo "== 2. 원격 연결 =="
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$REPO.git"
BR=$(gh api "repos/$REPO" --jq .default_branch 2>/dev/null)
[ -z "$BR" ] && BR=main
if [ "$BR" != "main" ]; then git branch -M "$BR"; fi

echo "== 3. 푸시 =="
git push -u origin "$BR" --force 2>&1 | tail -5 || exit 1

echo "== 4. GitHub Pages 활성화 =="
gh api -X POST "repos/$REPO/pages" -f "source[branch]=$BR" -f "source[path]=/" 2>&1 | head -5
if ! gh api "repos/$REPO/pages" >/dev/null 2>&1; then
  echo "!! Pages API 사용 불가 → 웹 설정 필요: https://github.com/$REPO/settings/pages (Source: Deploy from a branch / $BR / root)"
fi

echo "== 5. 배포 대기 =="
i=0
while [ $i -lt 60 ]; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "$URL")
  echo "  [$i] $CODE $URL"
  [ "$CODE" = "200" ] && break
  i=$((i+1)); sleep 10
done
[ "$CODE" = "200" ] && echo "DEPLOYED_OK $URL" || echo "DEPLOY_PENDING $URL (Pages 첫 배포는 수 분 걸릴 수 있음)"
