# ClaudeKit `ck` — Hướng dẫn cài đặt

## Đã sửa những gì

Kit gốc của bạn không chạy được `/ck:*` vì hai lỗi cấu trúc:

| Vấn đề | Trạng thái gốc | Đã sửa thành |
|---|---|---|
| Không có manifest plugin | thiếu `.claude-plugin/plugin.json` | đã tạo, `name: ck` |
| Tên skill chứa dấu `:` | `name: ck:brainstorm` (không hợp lệ cho skill thường) | `name: brainstorm` — namespace `ck:` giờ do plugin sinh ra |
| Tên thư mục lệch tên skill | dir `ck-plan/` vs `name: ck:plan` | đổi dir thành `plan/`, khớp nhau |
| Skill lồng 2 cấp không được quét | `skills/document-skills/docx/` | đưa lên `skills/docx/` |
| Hook trỏ sai biến môi trường | `$CLAUDE_PROJECT_DIR/.claude/hooks/` | `${CLAUDE_PLUGIN_ROOT}/hooks/` |
| Hook nằm trong `settings.json` | không dùng được ở dạng plugin | tách ra `hooks/hooks.json` |
| Rác đóng gói | 478 MB / 34.912 file (`.venv`, `node_modules`) | 24 MB |

Kết quả: **88 skills, 13 agents, 11 hooks**.

---

## Cách 1 — Cài dạng plugin (khuyến nghị, có `/ck:*`)

Giải nén `ck-plugin.zip` ra một chỗ cố định (đừng để trong Downloads vì Claude Code đọc trực tiếp từ đường dẫn này):

```bash
mkdir -p ~/.claude-kits
unzip ck-plugin.zip -d ~/.claude-kits
```

Mở Claude Code rồi chạy:

```
/plugin marketplace add ~/.claude-kits/ck-marketplace
/plugin install ck@ck-local
```

Khởi động lại Claude Code. Kiểm tra bằng cách gõ `/ck:` — danh sách skill sẽ hiện ra.

> Plugin cài theo cách này có hiệu lực **global**, mọi project đều dùng được.

---

## Cách 2 — Cài global kiểu thư mục (không có `/ck:*`)

Chỉ dùng nếu bạn muốn skill chạy tự động theo ngữ cảnh thay vì gõ lệnh.

```bash
cp -r ~/.claude-kits/ck-marketplace/ck/skills   ~/.claude/
cp -r ~/.claude-kits/ck-marketplace/ck/agents   ~/.claude/
cp -r ~/.claude-kits/ck-marketplace/ck/hooks    ~/.claude/
cp    ~/.claude-kits/ck-marketplace/ck/statusline.cjs ~/.claude/
cp    settings.global.json ~/.claude/settings.json
```

`settings.global.json` là bản đã đổi toàn bộ `$CLAUDE_PROJECT_DIR` → `$HOME`. Nếu dùng file `settings.json` gốc ở scope global thì tất cả hook sẽ gãy.

⚠️ Cách này **không** tạo ra `/ck:brainstorm`. Skill sẽ được Claude tự gọi khi bạn mô tả nhu cầu bằng lời.

---

## Cấu hình thêm

- `.ck.json` — chỉnh `codingLevel`, `statusline`, `plan.namingFormat`, `locale.responseLanguage`. Copy vào `~/.claude/.ck.json` nếu muốn áp dụng global.
- `.env.example` — đổi tên thành `.env` và điền API key nếu dùng các skill cần key ngoài.
- `.mcp.json.example` — mẫu cấu hình MCP server, không bắt buộc.

## Lưu ý bảo mật

11 hook trong kit chạy script Node ở mỗi lần submit prompt và mỗi lần gọi tool (`session-init`, `privacy-block`, `scout-block`, `simplify-gate`...). Đây là code tuỳ ý chạy trên máy bạn — nên đọc qua `hooks/*.cjs` trước khi bật nếu kit không do bạn tự viết.

## Danh sách lệnh

Xem `skill-list.txt` — đầy đủ 88 shortcut.
