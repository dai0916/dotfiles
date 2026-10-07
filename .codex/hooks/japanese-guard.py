#!/usr/bin/env python3
"""Codex の Stop hook。最終回答が英語主体なら、終了させずに日本語で書き直させる。

claude-code-japanese-guard（https://github.com/minorun365/claude-code-japanese-guard、
Apache License 2.0、930f056）の Codex 版。判定の基準と環境変数は元のものと同じ。

Codex は Stop hook に最終回答の本文を last_assistant_message として渡すので、
会話記録（形式が安定していない）は読まない。
コードブロック・インラインコード・URL・メールアドレス・Markdown リンクは数えない。
差し戻しは1ターンにつき1回だけ（stop_hook_active が立っていたら通す）。

単体で試す: echo '{"last_assistant_message": "..."}' | python3 japanese-guard.py
"""

import json
import os
import re
import sys

# 英字がこれ未満の段落は判定しない（「OK」「Done」程度の短い返事は見逃す）
MIN_LATIN = int(os.environ.get("JAPANESE_GUARD_MIN_LATIN", "25"))
# 英字の数が日本語の文字数のこの倍を超えたら、英語主体とみなす
RATIO = float(os.environ.get("JAPANESE_GUARD_RATIO", "3"))

JA = re.compile(r"[ぁ-んァ-ヶ一-龥]")
LATIN = re.compile(r"[A-Za-z]")
IGNORE = [
    re.compile(r"```.*?```", re.S),
    re.compile(r"`[^`\n]*`"),
    re.compile(r"https?://\S+"),
    re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"),
    re.compile(r"\[[^\]]*\]\([^)]*\)"),
]

REASON = (
    "この回答に、英語で書いた箇所があります。\n"
    "{quoted}\n"
    "ユーザーは日本語での応答を求めています。上に挙げた英語の箇所だけを、日本語に書き直して出してください。"
    "日本語で書けていた部分は、すでにユーザーに届いているので再掲しないこと。"
    "言い訳や原因の説明は書かず、以降の応答もすべて日本語で書くこと。"
)


def strip_ignored(text):
    for pattern in IGNORE:
        text = pattern.sub("", text)
    return text


def is_english(text):
    latin = len(LATIN.findall(text))
    ja = len(JA.findall(text))
    return latin >= MIN_LATIN and latin > ja * RATIO


def english_passages(message):
    """コードブロックなどを除いたうえで、英語主体の段落の先頭行を返す"""
    paragraphs = re.split(r"\n\s*\n", strip_ignored(message))
    return [p.strip().splitlines()[0][:80] for p in paragraphs if p.strip() and is_english(p)]


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    if data.get("stop_hook_active"):
        return
    message = data.get("last_assistant_message")
    if not message:
        return
    hits = english_passages(message)
    if hits:
        quoted = "\n".join("- " + h for h in hits[:5])
        print(json.dumps({"decision": "block", "reason": REASON.format(quoted=quoted)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
