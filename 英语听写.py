# ==========================================
# 基础配置、样式常量与核心密码区
# ==========================================
from typing import Dict, List, Any, Optional, Callable
import sys, os, subprocess, json, base64, re, time, random, asyncio
from datetime import datetime

# [核心安全] 初始密码明文。一旦开启加密，系统会自动将其擦除
ADMIN_PASSWORD: str = "090421"
ENCRYPT_PASSWORD: bool = False

BIND_HOST: str = "0.0.0.0"  
BIND_PORT: int = 8080
STORAGE_SECRET: str = "dictation_secret_key_123"

THEME_BG: str = "linear-gradient(135deg, #0f172a 0%, #2e1022 100%)"
GLASS_BG: str = "rgba(255, 255, 255, 0.05)"
GLASS_BORDER: str = "rgba(255, 255, 255, 0.1)"
GLASS_RADIUS: str = "2dvh"
COLOR_SUCCESS: str = "#4ade80"
COLOR_ERROR: str = "#f87171"
ANIMATION_DUR: str = "0.5s"

# ==========================================
# 动态持久化数据仓 (纯明文 JSON, 随应用运行自动更新)
# ==========================================
# [自洽更新引擎] 修改脚本内部常量
def rewrite_py_vars(updates: dict):
    try:
        with open(__file__, 'r', encoding='utf-8') as f: content = f.read()
        for k, v in updates.items():
            if isinstance(v, str):
                content = re.sub(rf'^({k}\s*:\s*str\s*=\s*)".*?"', f'\\1"{v}"', content, flags=re.MULTILINE)
            elif isinstance(v, bool):
                content = re.sub(rf'^({k}\s*:\s*bool\s*=\s*)\w+', f'\\1{v}', content, flags=re.MULTILINE)
        temp_file = __file__ + '.tmp'
        with open(temp_file, 'w', encoding='utf-8') as f: f.write(content)
        os.replace(temp_file, __file__)
    except Exception as e: print(f"文件覆写失败: {e}")

def install_dependencies():
    import sys, os, subprocess, time, shutil, re
    
    if os.environ.get('_DICTATION_ENV_CHECKED') == '1':
        try: import nicegui
        except ImportError:
            print("\n[!] 致命错误：系统曾报告安装成功，但模块仍不可用。程序已强制终止。")
            sys.exit(1)
        return

    try:
        import nicegui
        if int(nicegui.__version__.split('.')[0]) < 1: raise ImportError("需更新")
        return
    except ImportError: pass

    print("\n" + "★"*50)
    print("🚀 启动 [终极防抖悬浮版] 依赖管理器")
    print("★"*50)
    
    is_termux = 'com.termux' in os.environ.get('PREFIX', '')

    if is_termux:
        os.environ["ANDROID_API_LEVEL"] = "24"
        os.environ["CARGO_BUILD_TARGET"] = "aarch64-linux-android"
        os.environ["MATURIN_TARGET"] = "aarch64-linux-android"
        os.environ["CARGO_BUILD_JOBS"] = "4"
        prefix = os.environ.get('PREFIX', '/data/data/com.termux/files/usr')
        os.environ["CFLAGS"] = f"-I{prefix}/include/libxml2 -I{prefix}/include"
        os.environ["LDFLAGS"] = f"-L{prefix}/lib"

    steps = []
    if is_termux:
        steps.extend([
            ("更新 Termux 软件源", "pkg update -y"),
            ("安装底层编译工具链", "pkg install -y rust binutils clang libxml2 libxslt pkg-config libffi")
        ])
        
    py_exe = sys.executable
    steps.extend([
        ("安装构建基础包", f"{py_exe} -m pip install setuptools --default-timeout=15"),
        ("安装 Rust 编译后端", f"{py_exe} -m pip install maturin --default-timeout=15"),
        ("安装 Wheel 打包工具", f"{py_exe} -m pip install wheel --default-timeout=15"),
        ("编译 JSON 加速底层库", f"{py_exe} -m pip install orjson --no-build-isolation --default-timeout=15"),
        ("编译 Pydantic 核心库", f"{py_exe} -m pip install pydantic-core --no-build-isolation --default-timeout=15"),
        ("安装 Web UI 核心库", f"{py_exe} -m pip install nicegui --default-timeout=15")
    ])

    start_time = time.time()
    total_steps = len(steps)

    sys.stdout.write('\033[?25l')
    sys.stdout.flush()

    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    first_draw = True

    try:
        for i, (name, cmd) in enumerate(steps):
            p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)

            def update_ui(log_line=""):
                nonlocal first_draw
                cols = shutil.get_terminal_size().columns or 80
                elapsed = time.time() - start_time
                eta_str = "计算中" if i == 0 else f"{int((elapsed / max(1, i)) * (total_steps - i))}s"
                pct = int((i / total_steps) * 100)
                filled = int(20 * i // total_steps)
                bar = '█' * filled + '░' * (20 - filled)
                l1 = f"🔄 进度: [{bar}] {pct}% ({i}/{total_steps}) | ⏱️ {int(elapsed)}s ⏳ {eta_str}"
                l2 = f"📦 正在执行: {name}"

                line_print = log_line[:cols-1] if log_line else ""
                l1, l2 = l1[:cols-1], l2[:cols-1]

                if not first_draw: sys.stdout.write('\r\033[2A\033[J')
                sys.stdout.write(f"\033[38;5;245m{line_print}\033[0m\n" if line_print else "\n")
                sys.stdout.write(f"\033[1;36m{l1}\033[0m\n\033[1;33m{l2}\033[0m")
                sys.stdout.flush()
                first_draw = False

            update_ui("准备启动...")
            while True:
                line = p.stdout.readline()
                if not line and p.poll() is not None: break
                if line.strip(): update_ui(ansi_escape.sub('', line.strip()))

            if p.returncode != 0:
                sys.stdout.write('\r\033[2A\033[J')
                print(f"\n❌ 致命错误：[{name}] 执行失败！")
                sys.exit(1)

        sys.stdout.write('\r\033[2A\033[J')
        print(f"\n✅ 进度: [████████████████████] 100% ({total_steps}/{total_steps}) | ⏱️ {int(time.time() - start_time)}s")
        print("🎉 所有依赖安装完毕，重载环境启动界面！")
    finally:
        sys.stdout.write('\033[?25h')
        sys.stdout.flush()

    os.environ['_DICTATION_ENV_CHECKED'] = '1'
    try: os.execv(sys.executable, [sys.executable] + sys.argv)
    except Exception as e: print(f"\n[!] 重启环境失败: {e}，请手动重新运行本脚本。"); sys.exit(1)

install_dependencies()
from nicegui import ui, app

# ==========================================
# 数据模型与原子化多账户引擎
# ==========================================
class DataManager:
    def __init__(self) -> None:
        self.vocab: Dict[str, Any] = {}
        self.accounts: Dict[str, Any] = {}
        self.global_settings: Dict[str, Any] = {}
        self.pos_cache: set = set()
        self._needs_migration = False 
        self.load_data()
        self.auto_fix_db()
        if self._needs_migration:
            self.save_data()

    def load_data(self) -> None:
        try:
            with open(__file__, 'r', encoding='utf-8') as f: 
                content = f.read()
            
            data = {}
            # [核心修复]: 强制只匹配行首的 DATA_STORE_JSON，防止被 save_data 中的代码字符串干扰导致解析全盘崩溃
            json_match = re.search(r"^DATA_STORE_JSON\s*=\s*'''(.*?)'''", content, flags=re.MULTILINE|re.DOTALL)
            if json_match and json_match.group(1).strip() and json_match.group(1).strip() != "{}":
                data = json.loads(json_match.group(1).strip())
            else:
                b64_match = re.search(r'DATA_STORE_B64.*?=\s*"(.*?)"', content)
                if b64_match and b64_match.group(1).strip():
                    data = json.loads(base64.b64decode(b64_match.group(1)).decode('utf-8'))
                    self._needs_migration = True

            self.vocab = data.get("vocab", {})
            self.accounts = data.get("accounts", {})
            self.global_settings = data.get("global_settings", {})

            if not self.accounts:
                old_settings = data.get("settings", {
                    "allow_backward": True, "allow_hint": False, "timer_lock": True,
                    "per_q_time": 20.0, "hide_test_config": False, "hint_delay": 5, "hint_limit": 0, "folders": []
                })
                if 'password' in old_settings:
                    self.global_settings['password'] = old_settings.pop('password')
                self.accounts["default"] = {
                    "name": "默认账户", "history": data.get("history", []), 
                    "stats": data.get("stats", {}), "settings": old_settings
                }
            self.rebuild_pos_cache()
        except Exception as e:
            print(f"数据加载异常: {e}")
            self.vocab, self.accounts, self.global_settings = {}, {}, {}
            self.accounts["default"] = {"name": "默认账户", "history": [], "stats": {}, "settings": {}}

    def get_acc(self, acc_id: str) -> Dict[str, Any]:
        if acc_id not in self.accounts:
            acc_id = list(self.accounts.keys())[0] if self.accounts else "default"
        return self.accounts.get(acc_id, {})

    def auto_fix_db(self) -> None:
        db_changed = False
        import re
        for b in self.vocab.values():
            for u in b.values():
                for meta in u.values():
                    old_keys = list(meta.keys())
                    for k in old_keys:
                        if k not in ["单词", "_uid", "source_book", "_ask_pos", "_test_mode"]:
                            # 核心修改：检测到连字符时，自动拆分并转换为多个独立词性键值对
                            if '&' in k or '/' in k:
                                parts = [p.strip() for p in re.split(r'[&/]', k) if p.strip()]
                                val = meta.pop(k) # 移除旧的整体组合键
                                for p in parts:
                                    pl = p.lower()
                                    if pl == 'vt.': pl = 'v.(vt.)'
                                    elif pl == 'vi.': pl = 'v.(vi.)'
                                    meta[pl] = val # 将原本的释义分别赋予拆分后的单个词性
                                db_changed = True
                            else:
                                kl = k.lower()
                                if kl == 'vt.': kl = 'v.(vt.)'
                                elif kl == 'vi.': kl = 'v.(vi.)'
                                if k != kl:
                                    meta[kl] = meta.pop(k); db_changed = True
        
        # 同步修复词性缓存池，把缓存里的复合词性也拆干净
        cached_list = list(self.pos_cache)
        for p in cached_list:
            if '&' in p or '/' in p:
                self.pos_cache.remove(p)
                parts = [pt.strip().lower() for pt in re.split(r'[&/]', p) if pt.strip()]
                for pt in parts:
                    if pt == 'vt.': pt = 'v.(vt.)'
                    elif pt == 'vi.': pt = 'v.(vi.)'
                    self.pos_cache.add(pt)
                db_changed = True
            else:
                pl = p.lower()
                if pl == 'vt.': pl = 'v.(vt.)'
                elif pl == 'vi.': pl = 'v.(vi.)'
                if p != pl:
                    self.pos_cache.remove(p); self.pos_cache.add(pl); db_changed = True

        if db_changed: self.save_data()

    def rebuild_pos_cache(self) -> None:
        self.pos_cache.clear()
        for b in self.vocab.values():
            for u in b.values():
                for w in u.values():
                    for k in w.keys():
                        if k not in ["单词", "_uid", "source_book", "_ask_pos", "_test_mode"]:
                            self.pos_cache.add(k.lower())

    def save_data(self) -> None:
        try:
            self.rebuild_pos_cache()
            data = {"vocab": self.vocab, "accounts": self.accounts, "global_settings": self.global_settings}
            
            # ── 自定义序列化：词条单行紧凑，外层结构保留缩进 ──
            # [紧凑序列化] 判断一个值是否可以放在单行（无嵌套dict，list内元素也是简单值）
            def _is_flat(v):
                if isinstance(v, (str, bool, int, float)) or v is None: return True
                if isinstance(v, list): return all(isinstance(i, (str, bool, int, float)) or i is None for i in v)
                return False

            def _encode(obj, depth=0):
                ind  = '  ' * depth
                ind1 = '  ' * (depth + 1)
                if isinstance(obj, dict):
                    if not obj: return '{}'
                    # 单词统计对象 → header + history每条单行
                    if 'total' in obj and 'correct' in obj and 'wrong' in obj and 'history' in obj:
                        hist = obj['history']
                        non_hist_items = [(k, v) for k, v in obj.items() if k != 'history']
                        header = '{' + ', '.join(f'{json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}' for k, v in non_hist_items)
                        if not hist:
                            return header + ', "history": []}'
                        hist_lines = [f'{ind1}{json.dumps(h, ensure_ascii=False, separators=(", ", ": "))}' for h in hist]
                        return header + ', "history": [\n' + ',\n'.join(hist_lines) + '\n' + ind + ']}'
                    # 会话历史条目 (含timestamp+details) → header单行 + details每条单行
                    if 'timestamp' in obj and 'details' in obj:
                        details = obj['details']
                        non_det_items = [(k, v) for k, v in obj.items() if k != 'details']
                        header = '{' + ', '.join(f'{json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}' for k, v in non_det_items)
                        if not details:
                            return header + ', "details": []}'
                        det_lines = [f'{ind1}{json.dumps(d, ensure_ascii=False, separators=(", ", ": "))}' for d in details]
                        return header + ', "details": [\n' + ',\n'.join(det_lines) + '\n' + ind + ']}'
                    # 所有值均为简单类型（含简单list）→ 单行输出
                    if all(_is_flat(v) for v in obj.values()):
                        return json.dumps(obj, ensure_ascii=False, separators=(', ', ': '))
                    # 深度≥4 且含"单词"键 → 词条单行输出
                    if depth >= 4 and '单词' in obj:
                        return json.dumps(obj, ensure_ascii=False, separators=(', ', ': '))
                    parts = [f'{ind1}{json.dumps(k, ensure_ascii=False)}: {_encode(v, depth+1)}' for k, v in obj.items()]
                    return '{\n' + ',\n'.join(parts) + '\n' + ind + '}'
                if isinstance(obj, list):
                    if not obj: return '[]'
                    parts = [f'{ind1}{_encode(v, depth+1)}' for v in obj]
                    return '[\n' + ',\n'.join(parts) + '\n' + ind + ']'
                return json.dumps(obj, ensure_ascii=False)
            
            json_str = _encode(data).replace("'''", "''\\'")
            
            with open(__file__, 'r', encoding='utf-8') as f: content = f.read()
            
            content = re.sub(r'^DATA_STORE_B64.*?=\s*".*?"\n*', '', content, flags=re.MULTILINE)
            
            pattern = r"^(DATA_STORE_JSON\s*=\s*''').*?(''')"
            if re.search(pattern, content, flags=re.MULTILINE|re.DOTALL):
                new_content = re.sub(pattern, f"\\g<1>\n{json_str}\n\\g<2>", content, count=1, flags=re.MULTILINE|re.DOTALL)
            else:
                new_content = content.rstrip() + f"\n\n# ==========================================\n# 动态持久化数据仓 (纯明文 JSON)\n# ==========================================\nDATA_STORE_JSON = '''\n{json_str}\n'''\n"
            
            temp_file = __file__ + '.tmp'
            with open(temp_file, 'w', encoding='utf-8') as f: f.write(new_content)
            os.replace(temp_file, __file__)
            self._needs_migration = False
        except Exception as e:
            print(f"数据持久化失败: {e}")

    def update_word_stats(self, acc_id: str, word_text: str, is_correct: bool, time_spent: float = 0) -> None:
        acc = self.get_acc(acc_id)
        stats = acc.setdefault("stats", {})
        if word_text not in stats:
            stats[word_text] = {"total": 0, "correct": 0, "wrong": 0, "cumulative_seconds": 0, "history": []}
        s = stats[word_text]
        s["total"] += 1
        s["correct" if is_correct else "wrong"] += 1
        s["cumulative_seconds"] = s.get("cumulative_seconds", 0) + int(time_spent)
        s["history"].append({"time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "result": "对" if is_correct else "错"})
        # 修复：只更新内存，不在每道题统计时触发磁盘IO。由调用的业务逻辑负责最终 save_data

    def clean_empty_nodes(self, book: str, unit: str) -> None:
        if not self.vocab.get(book, {}).get(unit): self.vocab[book].pop(unit, None)
        if not self.vocab.get(book): self.vocab.pop(book, None)
        self.save_data()

db = DataManager()

def get_admin_pwd():
    raw_pwd = db.global_settings.get('password', '') if ENCRYPT_PASSWORD else ADMIN_PASSWORD
    return str(raw_pwd).strip()

os.makedirs('static_assets', exist_ok=True)
app.add_static_files('/static', 'static_assets')

ui.add_head_html(f'''
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
<script>
    window.onbeforeunload = function() {{ if (document.getElementById('testing_flag')) return "正在听写中，刷新将丢失进度！"; }};
    function speakWord(text) {{
        if ('speechSynthesis' in window) {{
            let utterance = new SpeechSynthesisUtterance(text);
            utterance.lang = 'en-US';
            utterance.rate = 0.9; 
            window.speechSynthesis.speak(utterance);
        }}
    }}
    setInterval(function() {{ fetch('/keepalive_heartbeat').catch(function() {{}}); }}, 2000);
</script>
<style>
    :root {{ --safe-top: env(safe-area-inset-top, 2dvh); --safe-bottom: env(safe-area-inset-bottom, 2dvh); }}
    body {{ margin:0; background: {THEME_BG}; color: white; overflow-x: hidden; overscroll-behavior-y: none; }}
    .glass-card {{ background: {GLASS_BG}; backdrop-filter: blur(1.5dvh); border: 0.1dvh solid {GLASS_BORDER}; border-radius: {GLASS_RADIUS}; transition: background-color {ANIMATION_DUR}; }}
    ::-webkit-scrollbar {{ display: none; }}
    .mobile-input {{ background: transparent !important; border: none !important; border-bottom: 0.3dvh solid rgba(255,255,255,0.5) !important; color: white !important; font-size: 3.5dvh !important; text-align: center !important; outline: none !important; border-radius: 0; transition: all {ANIMATION_DUR}; padding: 1dvh 0 !important; }}
    .mobile-input:focus {{ border-bottom-color: {COLOR_SUCCESS} !important; }}
    .view-shift {{ margin-bottom: 25dvh !important; transition: margin {ANIMATION_DUR} cubic-bezier(0.4, 0, 0.2, 1); }}
    
    @keyframes shake {{
        0% {{ transform: translateX(0); }}
        25% {{ transform: translateX(-8px); }}
        50% {{ transform: translateX(8px); }}
        75% {{ transform: translateX(-8px); }}
        100% {{ transform: translateX(0); }}
    }}
    .shake-anim {{ animation: shake 0.5s cubic-bezier(.36,.07,.19,.97) both; }}
    .success-bg {{ background-color: rgba(74, 222, 128, 0.15) !important; border: 2px solid #4ade80 !important; box-shadow: 0 0 25px rgba(74,222,128,0.4) !important; transition: all 0.2s; border-radius: {GLASS_RADIUS} !important; }}
    .manual-bg {{ background-color: rgba(234, 179, 8, 0.15) !important; border: 2px solid #eab308 !important; box-shadow: 0 0 25px rgba(234,179,8,0.4) !important; transition: all 0.2s; border-radius: {GLASS_RADIUS} !important; }}
</style>
''', shared=True)

class AppState:
    def __init__(self) -> None:
        self.current_account_id: str = list(db.accounts.keys())[0] if db.accounts else "default"
        self.current_view: str = 'home'
        self.selected_words: List[Dict] = [] 
        self.test_mode: str = ''
        self.test_queue: List[Dict] = []
        self.current_q_index: int = 0
        self.score_log: List[Dict] = []
        self.auth_dialog_open: bool = False
        self.is_submitting: bool = False
        self.result_saved: bool = False  # 修复：防止重复存入历史记录
        
        self.user_answers: Dict[int, Any] = {}
        self.per_q_time: float = 20.0
        self.total_time: float = 0.0
        self.q_time_left: float = 20.0
        self.tot_left: float = 0.0
        
        self.allow_backward: bool = True
        self.allow_hint: bool = False
        self.guest_password: str = ""
        self.admin_expanded_paths: set = set()
        self.browser_expanded_paths: set = set()

_client_states = {}
_client_containers = {}
_account_online: Dict[str, set] = {} 

class StateProxy:
    def _get_state(self):
        try:
            cid = ui.context.client.id
            if cid not in _client_states:
                _client_states[cid] = AppState()
                acc_id = _client_states[cid].current_account_id
                _account_online.setdefault(acc_id, set()).add(cid)
            return _client_states[cid]
        except RuntimeError:
            if 'system' not in _client_states: _client_states['system'] = AppState()
            return _client_states['system']

    def __getattr__(self, name): return getattr(self._get_state(), name)
    def __setattr__(self, name, value): setattr(self._get_state(), name, value)

state = StateProxy()

@app.on_disconnect
def handle_disconnect(client):
    cid = client.id
    for acc_id, clients in _account_online.items():
        if cid in clients: clients.remove(cid)

def render_view() -> None:
    try:
        cid = ui.context.client.id
        container = _client_containers.get(cid)
    except RuntimeError: return
    if container is None: return
    container.clear()
    with container: globals()[f'render_{state.current_view}']()

def change_view(view_name: str) -> None:
    state.current_view = view_name
    render_view()

def require_password(callback: Callable, allow_guest: bool = False) -> None:
    if state.auth_dialog_open: return
    state.auth_dialog_open = True
    with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[80vw]'):
        title = '安全验证 (支持访客)' if allow_guest and state.guest_password else '管理员安全验证'
        ui.label(title).classes('text-[3dvh] font-bold mb-[2dvh]')
        inp = ui.input(password=True).classes('mobile-input w-full mb-[3dvh]').props('autofocus')
        
        def verify():
            current_input = str(inp.value).strip() if inp.value else ""
            sys_pwd = get_admin_pwd()
            guest_pwd = str(state.guest_password).strip() if state.guest_password else ""
            
            is_admin = (current_input == sys_pwd)
            is_guest = allow_guest and guest_pwd and (current_input == guest_pwd)
            
            if is_admin or is_guest: 
                d.close()
                state.auth_dialog_open = False
                callback()
            else: 
                ui.notify('验证失败：密码错误或权限不足', type='negative')
                inp.value = ''
                
        def cancel(): d.close(); state.auth_dialog_open = False
        inp.on('keydown.enter', verify)
        with ui.row().classes('w-full gap-[2vw] justify-between'):
            ui.button('取消', on_click=cancel).classes('flex-1 bg-gray-500 rounded-[1.5dvh]')
            ui.button('验证', on_click=verify).classes('flex-1 bg-blue-500 rounded-[1.5dvh]')
        d.on('hide', lambda: setattr(state, 'auth_dialog_open', False))
    d.open()

def multi_action_dialog(title: str, msg: str, actions: List[tuple]) -> None:
    with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[85vw]'):
        ui.label(title).classes('text-[2.5dvh] font-bold text-yellow-400')
        ui.label(msg).classes('text-[2dvh] mt-[1dvh] mb-[3dvh]')
        with ui.row().classes('w-full justify-end gap-[2vw] flex-wrap'):
            for label, color, callback in actions:
                def wrap_cb(cb=callback): d.close(); (cb() if cb else None)
                ui.button(label, on_click=wrap_cb).classes(f'bg-{color}-500 mb-[1dvh]')
    d.open()

def prompt_dialog(title: str, label: str, default: str, callback: Callable) -> None:
    with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[85vw]'):
        ui.label(title).classes('text-[2.5dvh] font-bold')
        inp = ui.input(label, value=default).classes('w-full mb-[2dvh]')
        with ui.row().classes('w-full justify-end gap-[2vw]'):
            ui.button('取消', on_click=d.close).classes('bg-gray-500')
            def submit():
                if inp.value.strip(): d.close(); callback(inp.value.strip())
            ui.button('确认', on_click=submit).classes('bg-blue-500')
    d.open()

def show_account_switch():
    with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[90vw] max-h-[85dvh] overflow-y-auto flex flex-col'):
        ui.label('切换或管理账户').classes('text-[2.5dvh] font-bold mb-[2dvh]')
        
        for acc_id, acc in list(db.accounts.items()):
            is_current = (acc_id == state.current_account_id)
            online_clients = _account_online.get(acc_id, set())
            is_online = len(online_clients) > 0
            
            with ui.row().classes('w-full items-center justify-between mb-[1dvh] p-[2vw] rounded bg-white/5 border border-white/10'):
                with ui.row().classes('items-center gap-[1.5vw] flex-1 truncate'):
                    ui.icon('circle', size='1.5dvh', color='green' if is_online else 'gray').tooltip('在线' if is_online else '离线')
                    ui.label(acc['name']).classes('text-[2dvh] truncate' + (' text-blue-400 font-bold' if is_current else ''))
                    if is_current: ui.label('当前').classes('text-gray-400 text-[1.2dvh] whitespace-nowrap')
                
                with ui.row().classes('items-center gap-[1vw] no-wrap ml-[1vw]'):
                    def do_rename(aid=acc_id, old_name=acc['name']):
                        def _save_rename(new_name):
                            if new_name and new_name != old_name:
                                db.accounts[aid]['name'] = new_name
                                db.save_data()
                                ui.notify(f'已重命名为: {new_name}', type='positive'); d.close(); render_view() 
                        require_password(lambda: prompt_dialog('重命名账户', '新账户名', old_name, _save_rename))
                    
                    ui.button(icon='edit', on_click=do_rename).props('flat round size=sm').classes('text-blue-300 bg-white/5')
                    
                    def do_delete(aid=acc_id, name=acc['name'], current=is_current):
                        if len(db.accounts) <= 1: return ui.notify('这是系统中最后一个账户，无法删除！请先创建新账户。', type='warning')
                        def _confirm_delete():
                            db.accounts.pop(aid, None)
                            if aid in _account_online: _account_online.pop(aid, None)
                            if current:
                                new_aid = list(db.accounts.keys())[0]; state.current_account_id = new_aid
                                cid = ui.context.client.id; _account_online.setdefault(new_aid, set()).add(cid)
                            db.save_data(); ui.notify(f'账户 [{name}] 已彻底删除', type='positive'); d.close(); render_view()
                            
                        require_password(lambda: multi_action_dialog('危险操作', f'确定要彻底删除账户 [{name}] 吗？此操作不可逆！', [('取消', 'gray', None), ('确认删除', 'red', _confirm_delete)]))
                        
                    ui.button(icon='delete', on_click=do_delete).props('flat round size=sm').classes('text-red-400 bg-white/5')

                    if not is_current:
                        def do_switch(aid=acc_id):
                            def _confirmed():
                                cid = ui.context.client.id
                                old_aid = state.current_account_id
                                if old_aid in _account_online and cid in _account_online.get(old_aid, set()): _account_online[old_aid].discard(cid)
                                state.current_account_id = aid
                                _account_online.setdefault(aid, set()).add(cid)
                                # [设备记忆] 将 device_id → account_id 写入 DB，跨重启持久化
                                try:
                                    dev_id = app.storage.browser.get('device_id', '')
                                    if dev_id:
                                        db.global_settings.setdefault('device_accounts', {})[dev_id] = aid
                                        db.save_data()
                                except Exception: pass
                                ui.notify(f'已切换至账户: {db.accounts[aid]["name"]}', type='positive'); d.close(); render_view()
                            require_password(_confirmed)
                        ui.button('切换', on_click=do_switch).classes('bg-blue-500 py-[0.5dvh] px-[2vw] rounded ml-[1vw]')
                    
        def create_acc(name):
            if not name: return
            new_id = str(int(time.time() * 1000))
            base_settings = db.get_acc("default").get("settings", {}) if "default" in db.accounts else {}
            db.accounts[new_id] = {"name": name, "history": [], "stats": {}, "settings": base_settings.copy()}
            db.save_data(); ui.notify(f'账户 {name} 已创建', type='positive'); d.close(); render_view()
            
        ui.button('+ 新建账户 (需验密)', on_click=lambda: require_password(lambda: prompt_dialog('新建账户', '输入姓名/昵称', '', create_acc))).classes('w-full mt-[2dvh] bg-green-600 py-[1dvh] font-bold rounded-[1dvh]')
    d.open()

def render_home() -> None:
    current_acc = db.get_acc(state.current_account_id)
    
    with ui.column().classes('w-full h-full items-center justify-center p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)] relative'):
        with ui.row().classes('absolute top-[var(--safe-top)] right-[5vw] items-center gap-[1vw] bg-black/30 px-[3vw] py-[1dvh] rounded-[2dvh] cursor-pointer hover:bg-black/50 transition-colors').on('click', show_account_switch):
            ui.label(current_acc['name']).classes('text-[1.8dvh] font-bold text-blue-300')
            ui.icon('manage_accounts', size='2.5dvh').classes('text-white')

        ui.icon('school', size='10dvh').classes('text-white mb-[2dvh] mt-[4dvh]')
        ui.label('移动端听写系统').classes('text-[4dvh] font-bold mb-[3dvh]')
        
        my_history = current_acc.get('history', [])
        my_stats = current_acc.get('stats', {})
        total_tests = len(my_history)
        total_practiced = sum(s['total'] for s in my_stats.values())
        total_correct = sum(s['correct'] for s in my_stats.values())
        acc = int((total_correct / total_practiced) * 100) if total_practiced > 0 else 0
        
        with ui.row().classes('w-full max-w-[80vw] justify-between glass-card p-[3vw] mb-[4dvh]'):
            for v, l in [(total_tests, '听写次数'), (total_practiced, '练词数'), (f"{acc}%", '正确率')]:
                with ui.column().classes('items-center flex-1'):
                    ui.label(str(v)).classes('text-[2.5dvh] font-bold text-blue-300')
                    ui.label(l).classes('text-[1.8dvh] text-gray-400')

        with ui.column().classes('w-full gap-[2dvh] max-w-[80vw]'):
            saved_state = app.storage.user.get('dictation_state')
            has_save = saved_state and saved_state.get('current_q_index', 0) < len(saved_state.get('test_queue', []))

            def on_start_click():
                if not db.vocab: return ui.notify('暂无词库请先导入', type='warning')
                if has_save:
                    with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[85vw]'):
                        ui.label('发现保存的进度').classes('text-[2.5dvh] font-bold text-yellow-400')
                        ui.label(f"已答/总题: {len(saved_state.get('user_answers', {}))}/{len(saved_state.get('test_queue',[]))}").classes('text-[2dvh] my-[2dvh]')
                        
                        def resume():
                            state.test_mode = saved_state['test_mode']
                            state.test_queue = saved_state['test_queue']
                            state.current_q_index = saved_state['current_q_index']
                            state.score_log = saved_state.get('score_log', [])
                            acc_settings = db.get_acc(state.current_account_id).get('settings', {})
                            state.per_q_time = saved_state.get('per_q_time', acc_settings.get('per_q_time', 20.0))
                            state.total_time = saved_state.get('total_time', 0.0)
                            state.tot_left = saved_state.get('tot_left', 0.0)
                            state.allow_backward = saved_state.get('allow_backward', acc_settings.get('allow_backward', True))
                            state.allow_hint = saved_state.get('allow_hint', acc_settings.get('allow_hint', False))
                            state.used_hints = set(saved_state.get('used_hints', []))
                            state.user_answers = {int(k): v for k, v in saved_state.get('user_answers', {}).items()}
                            d.close(); change_view('testing')
                            
                        def start_new():
                            app.storage.user['dictation_state'] = None; d.close(); change_view('select_content')
                            
                        with ui.row().classes('w-full justify-between gap-[2vw]'):
                            ui.button('开始新听写', on_click=start_new).classes('bg-gray-500 py-[1dvh] flex-1 font-bold')
                            ui.button('继续进度', on_click=resume).classes('bg-green-500 py-[1dvh] flex-1 font-bold')
                    d.open()
                else: change_view('select_content')

            btn_start = ui.button('开始听写', on_click=on_start_click).classes('w-full py-[2dvh] text-[2.5dvh] rounded-[2dvh] bg-green-500 font-bold')
            if not db.vocab: btn_start.classes('bg-gray-600')
            
            def start_mistakes():
                mistakes = []
                for b in db.vocab.values():
                    for u in b.values():
                        for wid, meta in u.items():
                            word = meta.get('单词')
                            if my_stats.get(word, {}).get('wrong', 0) > 0:
                                m_copy = meta.copy(); m_copy['_uid'] = wid; mistakes.append(m_copy)
                if not mistakes: return ui.notify('太棒了，当前账户没有错题记录！', type='positive')
                
                with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[90vw] max-h-[80dvh] flex flex-col'):
                    ui.label(f'选择错题 (共 {len(mistakes)} 题)').classes('text-[2.5dvh] font-bold mb-[1dvh]')
                    chk_boxes = []
                    with ui.row().classes('w-full justify-between items-center mb-[1dvh] pb-[1dvh] border-b border-white/20'):
                        ui.label('默认全选').classes('text-gray-300')
                        sel_all = ui.switch('', value=True)
                        def toggle_all(e):
                            for c, _ in chk_boxes: c.value = e.value
                        sel_all.on_value_change(toggle_all)
                        
                    scroll = ui.scroll_area().classes('w-full flex-1 mb-[2dvh]')
                    with scroll:
                        for m in mistakes:
                            with ui.row().classes('w-full items-center justify-between py-[0.5dvh]'):
                                c = ui.checkbox(m['单词'], value=True)
                                ui.label(f"错 {my_stats.get(m['单词'], {}).get('wrong', 0)} 次").classes('text-red-400 text-[1.5dvh]')
                                chk_boxes.append((c, m))
                                
                    def confirm():
                        selected = [m for c, m in chk_boxes if c.value]
                        if not selected: return ui.notify('请至少选择一题', type='warning')
                        state.selected_words = selected; d.close(); change_view('select_mode')
                        
                    with ui.row().classes('w-full justify-end gap-[2vw]'):
                        ui.button('取消', on_click=d.close).classes('bg-gray-500 py-[0.5dvh]')
                        ui.button('确认', on_click=confirm).classes('bg-blue-500 py-[0.5dvh]')
                d.open()
            
            ui.button('错题本重练', on_click=start_mistakes).classes('w-full py-[2dvh] text-[2.5dvh] rounded-[2dvh] bg-blue-600 font-bold')
            ui.button('专属数据详情', on_click=lambda: change_view('data_browser')).classes('w-full py-[2dvh] text-[2.5dvh] rounded-[2dvh] bg-purple-600 font-bold')
            ui.button('系统管理后台', on_click=lambda: require_password(lambda: change_view('admin'))).classes('w-full py-[2dvh] text-[2.5dvh] rounded-[2dvh] glass-card')

def render_data_browser() -> None:
    current_acc = db.get_acc(state.current_account_id)
    my_stats = current_acc.get('stats', {})
    my_history = current_acc.get('history', [])

    with ui.column().classes('w-full h-full p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)] relative'):
        with ui.row().classes('w-full items-center mb-[2dvh]'):
            ui.button(icon='arrow_back', on_click=lambda: change_view('home')).classes('glass-card').props('flat round')
            ui.label(f"[{current_acc['name']}] 数据追踪").classes('text-[3dvh] font-bold ml-[3vw]')

        if not db.vocab:
            ui.label('词库为空，无法呈现数据').classes('text-gray-400 text-center w-full block mt-[2dvh]')
            return

        tree = {}
        for book_path, units in db.vocab.items():
            parts = book_path.split('/')
            curr = tree
            path_so_far = []
            for p in parts:
                path_so_far.append(p)
                if p not in curr: curr[p] = {'_units': {}, '_book_path': "/".join(path_so_far), 'children': {}}
                curr = curr[p]['children']
        for book_path, units in db.vocab.items():
            parts = book_path.split('/')
            curr = tree
            for p in parts[:-1]: curr = curr[p]['children']
            curr[parts[-1]]['_units'] = units

        def get_all_words_in_node(node_dict) -> set:
            words = set()
            for name, data in node_dict.items():
                for unit, u_words in data['_units'].items():
                    for wid, meta in u_words.items(): words.add(meta.get('单词', ''))
                words.update(get_all_words_in_node(data['children']))
            return words

        def show_folder_stats(title, word_set):
            if not word_set: return ui.notify('该目录下没有有效单词', type='warning')
            
            f_total, f_correct, f_wrong = 0, 0, 0
            for w in word_set:
                st = my_stats.get(w, {})
                f_total += st.get('total', 0); f_correct += st.get('correct', 0); f_wrong += st.get('wrong', 0)
                
            involved_history = []
            for sess in reversed(my_history):
                match_details = [d for d in sess.get('details', []) if d.get('word') in word_set]
                if match_details:
                    sess_c = sum(1 for d in match_details if d.get('correct'))
                    sess_w = len(match_details) - sess_c
                    involved_history.append({
                        'time': sess.get('timestamp'), 'involved_count': len(match_details),
                        'correct': sess_c, 'wrong': sess_w, 'words': [d.get('word') for d in match_details]
                    })

            with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[90vw] max-h-[85dvh] flex flex-col'):
                ui.label(title).classes('text-[2.5dvh] font-bold text-yellow-400 mb-[1dvh]')
                with ui.row().classes('w-full justify-between glass-card p-[2vw] mb-[2dvh]'):
                    ui.label(f'涉及词量: {len(word_set)}').classes('text-[1.8dvh] text-gray-300')
                    ui.label(f'总听写频次: {f_total}').classes('text-[1.8dvh] text-blue-300 font-bold')
                    ui.label(f'对 {f_correct} / 错 {f_wrong}').classes('text-[1.8dvh] text-green-400')
                
                ui.label('包含此目录单词的历史会话').classes('text-[2dvh] font-bold mb-[1dvh]')
                h_scroll = ui.scroll_area().classes('w-full flex-1')
                with h_scroll:
                    if not involved_history: ui.label('未找到听写记录').classes('text-gray-500 text-[1.5dvh]')
                    for h in involved_history:
                        with ui.expansion(f"{h['time']} (抽查 {h['involved_count']} 词)").classes('bg-white/5 w-full mb-[0.5dvh] rounded'):
                            ui.label(f"对 {h['correct']} | 错 {h['wrong']}").classes('pl-[2vw] text-purple-300 text-[1.5dvh]')
                            ui.label(", ".join(h['words'])).classes('pl-[2vw] text-gray-400 text-[1.5dvh] break-all pb-[1dvh]')
            d.open()

        def show_word_stats(word):
            st = my_stats.get(word, {})
            h_list = st.get('history', [])
            
            with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[85vw] max-h-[70dvh] flex flex-col'):
                ui.label(word).classes('text-[3dvh] font-bold text-purple-400 mb-[1dvh]')
                with ui.row().classes('w-full justify-between glass-card p-[2vw] mb-[1dvh]'):
                    ui.label(f"总次: {st.get('total', 0)}").classes('text-[1.8dvh] text-blue-300')
                    ui.label(f"对: {st.get('correct', 0)}").classes('text-[1.8dvh] text-green-400')
                    ui.label(f"错: {st.get('wrong', 0)}").classes('text-[1.8dvh] text-red-400')
                
                cum_secs = st.get('cumulative_seconds', 0)
                ui.label(f'累计用时: {cum_secs} 秒').classes('text-[1.5dvh] text-yellow-300 mb-[1dvh]')
                ui.label('精确历史流水 (最近 50 条)').classes('text-[2dvh] font-bold mb-[1dvh]')
                h_scroll = ui.scroll_area().classes('w-full flex-1')
                with h_scroll:
                    if not h_list: ui.label('该单词尚无听写记录').classes('text-gray-500 text-[1.5dvh]')
                    for h in reversed(h_list[-50:]):
                        color = "text-green-400" if h['result'] == '对' else "text-red-400"
                        icon = "check_circle" if h['result'] == '对' else "cancel"
                        with ui.row().classes('w-full justify-between items-center py-[0.5dvh] border-b border-white/5'):
                            ui.label(h.get('time', '未知时间')).classes('text-[1.5dvh] text-gray-300 font-mono')
                            with ui.row().classes('items-center gap-[0.5vw]'):
                                ui.label(h['result']).classes(f"text-[1.8dvh] {color} font-bold")
                                ui.icon(icon, size='1.8dvh').classes(color)
            d.open()

        scroll = ui.scroll_area().classes('w-full flex-1 pb-[5dvh]')
        with scroll:
            def render_node(node_dict):
                for name, data in node_dict.items():
                    book_path = data['_book_path']
                    is_expanded = book_path in state.browser_expanded_paths
                    
                    with ui.element('div').classes('w-full relative mb-[0.5dvh]'):
                        with ui.expansion(name, icon='folder', value=is_expanded).classes('bg-white/5 w-full rounded') as exp:
                            def toggle_folder(e, p=book_path):
                                if e.value: state.browser_expanded_paths.add(p)
                                else: state.browser_expanded_paths.discard(p)
                            exp.on_value_change(toggle_folder)

                            if data['children']:
                                with ui.column().classes('w-full pl-[4vw] mt-[0.5dvh]'): render_node(data['children'])

                            for unit, words in data['_units'].items():
                                unit_path = f"{book_path}:::{unit}"
                                is_u_expanded = unit_path in state.browser_expanded_paths
                                
                                with ui.element('div').classes('w-full relative mb-[0.5dvh]'):
                                    with ui.expansion(unit, icon='description', value=is_u_expanded).classes('bg-black/20 w-full border-l-2 border-purple-500/50') as u_exp:
                                        def toggle_unit(e, p=unit_path):
                                            if e.value: state.browser_expanded_paths.add(p)
                                            else: state.browser_expanded_paths.discard(p)
                                        u_exp.on_value_change(toggle_unit)

                                        for wid, meta in words.items():
                                            word_txt = meta.get('单词', '')
                                            st = my_stats.get(word_txt, {})
                                            total_c = st.get('total', 0)
                                            wrong_c = st.get('wrong', 0)
                                            
                                            with ui.row().classes('w-full justify-between items-center py-[0.5dvh] border-b border-white/5 pl-[4vw] pr-[2vw] no-wrap hover:bg-white/5'):
                                                with ui.column().classes('flex-1 gap-0'):
                                                    ui.label(word_txt).classes('text-[1.6dvh] font-bold')
                                                    if total_c > 0:
                                                        lbl_color = "text-red-400" if wrong_c > 0 else "text-green-400"
                                                        ui.label(f"测{total_c}次 · 错{wrong_c}次").classes(f'text-[1dvh] {lbl_color}')
                                                    else: ui.label('未测试').classes('text-[1dvh] text-gray-500')
                                                ui.button(icon='info', on_click=lambda w=word_txt: show_word_stats(w)).props('flat round dense size=sm color=blue').tooltip('精准流水')
                                    
                                    u_word_set = {m.get('单词', '') for m in words.values()}
                                    ui.button(icon='info', on_click=lambda u_name=unit, w_set=u_word_set: show_folder_stats(f"单词集: {u_name}", w_set)).props('flat round dense size=sm color=yellow').classes('absolute top-[1dvh] right-[10vw] z-10')

                        ui.button(icon='info', on_click=lambda b=book_path, nd={name: data}: show_folder_stats(f"目录聚合: {b}", get_all_words_in_node(nd))).props('flat round dense size=sm color=yellow').classes('absolute top-[1dvh] right-[10vw] z-10')

            render_node(tree)
def render_admin() -> None:
    with ui.column().classes('w-full h-full p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)]'):
        with ui.row().classes('w-full justify-between items-center mb-[2dvh]'):
            ui.button(icon='arrow_back', on_click=lambda: change_view('home')).classes('glass-card').props('flat round')
            ui.label('系统后台').classes('text-[3dvh] font-bold')
            ui.icon('settings', size='3dvh')

        tabs = ui.tabs().classes('w-full')
        with tabs:
            ui.tab('words', '全局书单与词库')
            ui.tab('import_export', '导入与导出') 
            ui.tab('settings', '专属系统设置')
            ui.tab('logs', '个人听写明细')
            
        panels = ui.tab_panels(tabs, value='words').classes('w-full flex-1 glass-card mt-[2dvh] bg-transparent p-0')
        with panels:
            with ui.tab_panel('words').classes('p-[2vw] flex flex-col h-full'): admin_tab_words()
            with ui.tab_panel('import_export').classes('p-[4vw]'): admin_tab_import_export()
            with ui.tab_panel('settings').classes('p-[4vw] flex flex-col h-full'): admin_tab_settings()
            with ui.tab_panel('logs').classes('p-[2vw]'): admin_tab_logs()

def admin_tab_words() -> None:
    def edit_word_dialog(book, unit, word_id=None):
        wid = word_id or str(int(time.time() * 1000))
        meta = db.vocab[book][unit].get(wid, {"单词": ""}).copy()
        with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[90vw] max-h-[80dvh] overflow-y-auto'):
            ui.label('新增单词' if not word_id else '编辑单词').classes('text-[2.5dvh] font-bold')
            inp_word = ui.input('英文拼写', value=meta.get('单词','')).classes('w-full mb-[2dvh]')
            pos_list_container = ui.column().classes('w-full gap-[1dvh]')
            pos_rows = []
            
            def add_pos_row(p_key='', p_val=''):
                with pos_list_container, ui.row().classes('w-full items-center no-wrap'):
                    rk = ui.input('词性/短语(n.)', value=p_key).classes('w-[30%]')
                    rv = ui.input('释义', value=p_val).classes('flex-1')
                    btn_del = ui.button(icon='delete', color='red').props('flat round size=sm')
                    row_data = {'k': rk, 'v': rv, 'ui': rk.parent_slot.parent}
                    pos_rows.append(row_data)
                    btn_del.on('click', lambda r=row_data: (r['ui'].delete(), pos_rows.remove(r)))
            
            for k, v in meta.items():
                if k not in ["单词", "_uid", "source_book"]: add_pos_row(k, str(v))
            ui.button('+ 添加考点词性', on_click=lambda: add_pos_row()).classes('w-full glass-card mt-[1dvh]')
            
            def save_word():
                if not inp_word.value.strip(): return ui.notify('拼写不能为空', type='warning')
                new_meta = {"单词": re.sub(r'\s+', ' ', inp_word.value.strip())}
                for r in pos_rows:
                    k, v = r['k'].value.strip().lower(), r['v'].value.strip()
                    if k == 'vt.': k = 'v.(vt.)'
                    elif k == 'vi.': k = 'v.(vi.)'
                    if k and v: new_meta[k] = v
                db.vocab[book][unit][wid] = new_meta
                db.save_data(); d.close(); render_view()

            with ui.row().classes('w-full justify-end mt-[3dvh] gap-[2vw]'):
                ui.button('取消', on_click=d.close).classes('bg-gray-500')
                ui.button('保存', on_click=save_word).classes('bg-green-500')
        d.open()

    def handle_rename_book(old_path, new_path):
        if not new_path or old_path == new_path: return
        keys = list(db.vocab.keys())
        for k in keys:
            if k == old_path or k.startswith(old_path + '/'):
                new_k = new_path + k[len(old_path):]
                db.vocab[new_k] = db.vocab.pop(k)
        db.save_data(); render_view()

    def handle_delete_book(path_to_delete):
        keys = list(db.vocab.keys())
        for k in keys:
            if k == path_to_delete or k.startswith(path_to_delete + '/'):
                db.vocab.pop(k, None)
        db.save_data(); render_view()

    def move_book(book_path, direction):
        parts = book_path.split('/')
        parent = "/".join(parts[:-1]) if len(parts) > 1 else ""
        
        siblings = []
        for k in db.vocab.keys():
            if parent == "" or k.startswith(parent + '/'):
                rel_path = k[len(parent)+1:] if parent else k
                sibling_name = rel_path.split('/')[0]
                sibling_full = f"{parent}/{sibling_name}" if parent else sibling_name
                if sibling_full not in siblings:
                    siblings.append(sibling_full)
                    
        if book_path not in siblings: return
        idx = siblings.index(book_path)
        
        if direction == 'up' and idx > 0: swap_with = siblings[idx-1]
        elif direction == 'down' and idx < len(siblings) - 1: swap_with = siblings[idx+1]
        else: return
        
        ordered_keys = list(db.vocab.keys())
        block1_prefix = book_path + '/'
        block2_prefix = swap_with + '/'
        
        block1 = [k for k in ordered_keys if k == book_path or k.startswith(block1_prefix)]
        block2 = [k for k in ordered_keys if k == swap_with or k.startswith(block2_prefix)]
        
        b1_start = ordered_keys.index(block1[0])
        b2_start = ordered_keys.index(block2[0])
        
        first_start = min(b1_start, b2_start)
        last_end = max(b1_start + len(block1), b2_start + len(block2))
        
        if b1_start < b2_start:
            middle = ordered_keys[b1_start + len(block1):b2_start]
            new_slice = block2 + middle + block1
        else:
            middle = ordered_keys[b2_start + len(block2):b1_start]
            new_slice = block1 + middle + block2
            
        new_keys = ordered_keys[:first_start] + new_slice + ordered_keys[last_end:]
        db.vocab = {k: db.vocab[k] for k in new_keys}
        db.save_data(); render_view()

    def move_unit(book, unit, direction):
        d = db.vocab[book]; keys = list(d.keys()); idx = keys.index(unit)
        if direction == 'up' and idx > 0: keys[idx], keys[idx-1] = keys[idx-1], keys[idx]
        elif direction == 'down' and idx < len(keys) - 1: keys[idx], keys[idx+1] = keys[idx+1], keys[idx]
        else: return
        db.vocab[book] = {k: d[k] for k in keys}; db.save_data(); render_view()

    def move_word(book, unit, wid, direction):
        d = db.vocab[book][unit]; keys = list(d.keys()); idx = keys.index(wid)
        if direction == 'up' and idx > 0: keys[idx], keys[idx-1] = keys[idx-1], keys[idx]
        elif direction == 'down' and idx < len(keys) - 1: keys[idx], keys[idx+1] = keys[idx+1], keys[idx]
        else: return
        db.vocab[book][unit] = {k: d[k] for k in keys}; db.save_data(); render_view()

    tree = {}
    for book_path, units in db.vocab.items():
        parts = book_path.split('/')
        curr = tree
        path_so_far = []
        for p in parts:
            path_so_far.append(p)
            if p not in curr: curr[p] = {'_units': {}, '_book_path': "/".join(path_so_far), 'children': {}}
            curr = curr[p]['children']
            
    for book_path, units in db.vocab.items():
        parts = book_path.split('/')
        curr = tree
        for p in parts[:-1]: curr = curr[p]['children']
        curr[parts[-1]]['_units'] = units

    scroll = ui.scroll_area().classes('w-full flex-1')
    with scroll:
        is_edit = getattr(state, 'is_edit_mode', False)
        
        with ui.row().classes('w-full justify-between items-center mb-[1.5dvh]'):
            ui.button('+ 新建根文件夹', on_click=lambda: prompt_dialog('新建根文件夹', '输入名称 (如: 小学)', '', lambda v: (db.vocab.setdefault(v, {}), db.save_data(), render_view()))).classes('flex-1 bg-blue-600 font-bold py-[1dvh] rounded-[1dvh]')
            ui.switch('编辑排序', value=is_edit, on_change=lambda e: (setattr(state, 'is_edit_mode', e.value), render_view())).classes('ml-[2vw] text-yellow-400 font-bold')

        if not db.vocab: ui.label('词库为空，请先新建根文件夹').classes('text-gray-400 text-center w-full block mt-[2dvh]')

        def render_node(node_dict):
            for name, data in node_dict.items():
                book_path = data['_book_path']
                is_expanded = book_path in state.admin_expanded_paths
                
                with ui.expansion(name, icon='folder', value=is_expanded).classes('bg-white/5 w-full mb-[0.1dvh] rounded') as exp:
                    def toggle_folder(e, p=book_path):
                        if e.value: state.admin_expanded_paths.add(p)
                        else: state.admin_expanded_paths.discard(p)
                    exp.on_value_change(toggle_folder)

                    with ui.row().classes('w-full justify-between items-center px-[2vw] py-[0.5dvh] border-b border-white/10 no-wrap'):
                        ui.label(book_path).classes('text-[1.2dvh] text-gray-500 truncate flex-1 mr-[1vw]')
                        with ui.row().classes('gap-[0.5vw] no-wrap items-center'):
                            if not is_edit:
                                ui.button(icon='create_new_folder', on_click=lambda b=book_path: prompt_dialog('新建子文件夹', f'在 [{b}] 下新建:', '', lambda v: (db.vocab.setdefault(f"{b}/{v}", {}), db.save_data(), render_view()))).props('flat round dense size=sm color=green').tooltip('子文件夹')
                                ui.button(icon='note_add', on_click=lambda b=book_path: prompt_dialog('新建单词集', '输入名称 (相当于Txt文件):', '', lambda v: (db.vocab[b].setdefault(v, {}), db.save_data(), render_view()))).props('flat round dense size=sm color=purple').tooltip('单词集')
                                ui.button(icon='edit', on_click=lambda b=book_path: prompt_dialog('重命名/移动', '新路径:', b, lambda v: handle_rename_book(b, v))).props('flat round dense size=sm color=blue')
                            else:
                                ui.button(icon='arrow_upward', on_click=lambda b=book_path: move_book(b, 'up')).props('flat round dense size=sm color=white')
                                ui.button(icon='arrow_downward', on_click=lambda b=book_path: move_book(b, 'down')).props('flat round dense size=sm color=white')
                                ui.button(icon='close', on_click=lambda b=book_path: multi_action_dialog('危险操作', f'删除 [{b}] 及其全部内容?', [('取消','gray',None),('确认','red',lambda: handle_delete_book(b))])).props('flat round dense size=sm color=red')

                    if data['children']:
                        with ui.column().classes('w-full pl-[4vw] mt-0'):
                            render_node(data['children'])

                    for unit, words in data['_units'].items():
                        unit_path = f"{book_path}:::{unit}"
                        is_u_expanded = unit_path in state.admin_expanded_paths
                        
                        with ui.expansion(unit, icon='description', value=is_u_expanded).classes('bg-black/20 w-full mb-[0.1dvh] border-l-2 border-purple-500/50') as u_exp:
                            def toggle_unit(e, p=unit_path):
                                if e.value: state.admin_expanded_paths.add(p)
                                else: state.admin_expanded_paths.discard(p)
                            u_exp.on_value_change(toggle_unit)

                            with ui.row().classes('w-full justify-between items-center px-[2vw] py-[0.5dvh] border-b border-white/10 no-wrap'):
                                ui.label(f"{len(words)} 词").classes('text-[1.2dvh] text-gray-400 flex-1 truncate')
                                with ui.row().classes('gap-[0.5vw] no-wrap items-center'):
                                    if not is_edit:
                                        ui.button(icon='add', on_click=lambda b=book_path, u=unit: edit_word_dialog(b,u)).props('flat round dense size=sm color=green')
                                        ui.button(icon='edit', on_click=lambda b=book_path, u=unit: prompt_dialog('重命名', '新名称:', u, lambda v: (db.vocab[b].update({v: db.vocab[b].pop(u)}) if v!=u else None, db.save_data(), render_view()))).props('flat round dense size=sm color=blue')
                                    else:
                                        ui.button(icon='arrow_upward', on_click=lambda b=book_path, u=unit: move_unit(b, u, 'up')).props('flat round dense size=sm color=white')
                                        ui.button(icon='arrow_downward', on_click=lambda b=book_path, u=unit: move_unit(b, u, 'down')).props('flat round dense size=sm color=white')
                                        ui.button(icon='close', on_click=lambda b=book_path, u=unit: multi_action_dialog('确认', '删除此单词集?', [('取消','gray',None),('删除','red',lambda: (db.vocab[b].pop(u), db.clean_empty_nodes(b, u), render_view()))])).props('flat round dense size=sm color=red')

                            for wid, meta in words.items():
                                with ui.row().classes('w-full justify-between items-center py-[0.5dvh] border-b border-white/5 pl-[4vw] pr-[2vw] no-wrap hover:bg-white/5'):
                                    ui.label(meta.get('单词','')).classes('text-[1.6dvh] truncate flex-1')
                                    with ui.row().classes('no-wrap gap-[0.5vw]'):
                                        if not is_edit:
                                            ui.button(icon='edit', on_click=lambda b=book_path, u=unit, w=wid: edit_word_dialog(b,u,w)).props('flat round dense size=sm color=blue')
                                        else:
                                            ui.button(icon='arrow_upward', on_click=lambda b=book_path, u=unit, w=wid: move_word(b, u, w, 'up')).props('flat round dense size=sm color=white')
                                            ui.button(icon='arrow_downward', on_click=lambda b=book_path, u=unit, w=wid: move_word(b, u, w, 'down')).props('flat round dense size=sm color=white')
                                            ui.button(icon='close', on_click=lambda b=book_path, u=unit, w=wid: multi_action_dialog('确认', '删除单词?', [('取消','gray',None), ('删除','red',lambda b=b,u=u,w=w: (db.vocab[b][u].pop(w), db.clean_empty_nodes(b, u), render_view()))])).props('flat round dense size=sm color=red')

        render_node(tree)

def admin_tab_import_export() -> None:
    json_input = ui.textarea('粘贴 JSON 代码进行导入').classes('w-full bg-black/20 text-white p-[2vw]').props('rows="6"')
    ui.label('指定导入目标 (书册或单词集)').classes('text-[1.8dvh] text-yellow-300 mt-[1dvh]')
    
    target_folder_state = {'path': '/ (根目录)'}
    btn_folder = ui.button('导入位置: / (根目录)').classes('w-full bg-blue-600/50 text-left justify-start px-[4vw]')
    folder_inp = ui.input('新书册名称 (如: 小学/一年级)').classes('w-full mt-[1dvh]')
    folder_inp.set_visibility(False)
    
    def open_folder_tree():
        with ui.dialog() as d, ui.card().classes('glass-card w-[85vw] h-[70dvh] p-[4vw] flex flex-col'):
            ui.label('选择目标 (点击可选中)').classes('text-[2dvh] font-bold mb-[2dvh]')
            
            tree_dict = {'/': {'id': '/ (根目录)', 'label': '📁 / (根目录)', 'children': {}}}
            for path, units in db.vocab.items():
                parts = path.split('/')
                curr = tree_dict['/']['children']
                curr_path = []
                for p in parts:
                    curr_path.append(p)
                    full_p = "/".join(curr_path)
                    if full_p not in curr:
                        curr[full_p] = {'id': full_p, 'label': f'📁 {p}', 'children': {}}
                    curr = curr[full_p]['children']
                # [核心修复] 将单词集作为可选叶子节点加入
                for u in units.keys():
                    u_id = f"{path}:::{u}"
                    curr[u_id] = {'id': u_id, 'label': f'📄 {u} (单词集)'}
            
            def dict_to_list(d):
                return [{'id': v['id'], 'label': v['label'], 'children': dict_to_list(v.get('children', {}))} for v in d.values()]
            
            nodes = dict_to_list(tree_dict)
            nodes.append({'id': '➕ 创建新文件夹...', 'label': '➕ 创建新文件夹...'})
            
            def on_select(e):
                if not e.value: return
                target_folder_state['path'] = e.value
                # [核心修复] UI反馈更新
                if ':::' in e.value:
                    btn_folder.set_text(f'追加到单词集: {e.value.replace(":::", " -> ")}')
                else:
                    btn_folder.set_text(f'导入位置: {e.value}')
                folder_inp.set_visibility(e.value == '➕ 创建新文件夹...')
                
                # 延迟关闭以呈现选中高亮的动画效果
                ui.timer(0.3, d.close, once=True)
                
            scroll = ui.scroll_area().classes('w-full flex-1 mb-[2dvh]')
            with scroll:
                # [修复点] 移除了 props 中的 default-expand-all，并在链式调用末尾增加了 .expand()
                ui.tree(nodes, on_select=on_select).props('text-color="white" selected-color="primary"').classes('w-full').expand()
                
            ui.button('取消', on_click=d.close).classes('w-full bg-gray-500 py-[1dvh]')
        d.open()

        
    btn_folder.on_click(open_folder_tree)

    # [增强] 词性标签智能规范化：将各种格式统一为标准格式
    def normalize_pos_key(k: str) -> str:
        k = k.strip().lower()
        _pos_map = {
            'n': 'n.', 'v': 'v.', 'adj': 'adj.', 'adv': 'adv.',
            'pron': 'pron.', 'num': 'num.', 'art': 'art.',
            'prep': 'prep.', 'conj': 'conj.', 'interj': 'interj.',
            'vt': 'v.(vt.)', 'vi': 'v.(vi.)',
            'vt.': 'v.(vt.)', 'vi.': 'v.(vi.)',
            '名词': 'n.', '动词': 'v.', '形容词': 'adj.', '副词': 'adv.',
            '代词': 'pron.', '数词': 'num.', '冠词': 'art.',
            '介词': 'prep.', '连词': 'conj.', '感叹词': 'interj.',
            '及物动词': 'v.(vt.)', '不及物动词': 'v.(vi.)',
        }
        return _pos_map.get(k, k)

    def process_import():
        try:
            raw_data = json.loads(json_input.value)
            
            selected_val = target_folder_state['path']
            target_book = ""
            target_unit = ""
            
            # [核心修复] 智能解析选中的是文件还是文件夹
            if selected_val == '➕ 创建新文件夹...':
                target_book = folder_inp.value.strip()
            elif ':::' in selected_val:
                target_book, target_unit = selected_val.split(':::')
            elif selected_val != '/ (根目录)':
                target_book = selected_val

            def get_all_depths(d, current_level=1):
                if not isinstance(d, dict): return set()
                if "单词" in d: return {current_level}
                depths = set()
                for v in d.values():
                    if isinstance(v, dict): depths.update(get_all_depths(v, current_level + 1))
                return depths
            depths = get_all_depths(raw_data)
            if not depths: raise ValueError("未在任何层级找到包含 '单词' 键的有效属性节点。")
            if len(depths) > 1: raise ValueError("数据结构彻底混乱！")
            leaf_level = depths.pop()

            def validate_data(data):
                v_data, err_nodes = {}, []
                valid_pos_set = db.pos_cache.copy()
                valid_pos_set.update({"n.", "v.", "adj.", "adv.", "pron.", "num.", "art.", "prep.", "conj.", "interj.", "v.(vt.)", "v.(vi.)", "vt.", "vi.", "释义"})
                
                for b, units in data.items():
                    for u, words in units.items():
                        for wid, meta in words.items():
                            reasons = []
                            word = str(meta.get("单词", "")).strip()
                            if not word: reasons.append("缺失单词拼写")
                            
                            pos_keys = [k for k in meta.keys() if k not in ["单词", "_uid", "source_book"]]
                            if not pos_keys:
                                reasons.append("完全缺失词性及释义")
                            else:
                                for k in pos_keys:
                                    if not str(meta.get(k, "")).strip(): 
                                        reasons.append(f"缺失[{k}]的释义内容")
                                    else:
                                        # 核心修改：导入验证阶段就开始将组合词性打散验证
                                        parts = [p.strip() for p in re.split(r'[&/]', k) if p.strip()]
                                        for p in parts:
                                            k_lower = normalize_pos_key(p)
                                            if k_lower not in valid_pos_set:
                                                reasons.append(f"出现未录入词性 [{p}]")
                            
                            if reasons: err_nodes.append({'b': b, 'u': u, 'wid': wid, 'meta': meta.copy(), 'reasons': reasons})
                            else:
                                if b not in v_data: v_data[b] = {}
                                if u not in v_data[b]: v_data[b][u] = {}
                                v_data[b][u][wid] = meta
                return v_data, err_nodes

            def execute_import_phase2(standardized_data):
                if not standardized_data: return ui.notify('没有有效数据可导入！', type='warning')
                    
                overlap_words = 0
                for b, units in standardized_data.items():
                    for u, words in units.items():
                        for wid, meta in words.items():
                            meta["单词"] = re.sub(r'\s+', ' ', meta["单词"].strip())
                            new_meta = {"单词": meta["单词"]}
                            for k, v in meta.items():
                                if k not in ["单词", "_uid", "source_book"]:
                                    # 核心修改：写入底层字典前，将复合词性拆解为多个独立键写入
                                    parts = [p.strip() for p in re.split(r'[&/]', k) if p.strip()]
                                    for p in parts:
                                        kl = normalize_pos_key(p)
                                        new_meta[kl] = v 
                                else: 
                                    if k != "单词": # 防止上面重新添加过的"单词"键被重复覆盖
                                        new_meta[k] = v
                            words[wid] = new_meta
                            if b in db.vocab and u in db.vocab[b] and wid in db.vocab[b][u]: overlap_words += 1
                            
                overlap_books = [b for b in standardized_data.keys() if b in db.vocab]
                
                def merge_data():
                    for b, u_dict in standardized_data.items():
                        if b not in db.vocab: db.vocab[b] = {}
                        for u, w_dict in u_dict.items():
                            if u not in db.vocab[b]: db.vocab[b][u] = {}
                            db.vocab[b][u].update(w_dict)
                    db.save_data(); ui.notify('合并成功', type='positive'); render_view()
                    
                def overwrite_data():
                    db.vocab.update(standardized_data); db.save_data(); ui.notify('覆盖成功', type='positive'); render_view()
                    
                if overlap_books: 
                    msg = f"发现同名书册或路径冲突 [{','.join(overlap_books)}]\n"
                    if overlap_words > 0: msg += f"⚠️ 包含 {overlap_words} 个重复的单词ID，将被覆盖！"
                    multi_action_dialog('冲突预警', msg, [('取消', 'gray', None), ('保留原有合并增量', 'blue', merge_data), ('清空并整体覆盖', 'red', overwrite_data)])
                else:
                    db.vocab.update(standardized_data); db.save_data(); ui.notify('导入成功', type='positive'); render_view()

            def show_validation_dialog(v_data, err_nodes):
                with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[95vw] max-h-[90dvh]'):
                    ui.label(f'拦截到 {len(err_nodes)} 个待确认数据').classes('text-[2.5dvh] font-bold text-red-400')
                    ui.label('发现缺失信息或新词性。请选择对应的规范词性（如一词多义请分别选择），或勾选抛弃。').classes('text-[1.8dvh] text-gray-300 mb-[1dvh]')
                    
                    scroll = ui.scroll_area().classes('w-full flex-1 mb-[2dvh]')
                    node_uis = []
                    base_pos_opts = list(db.pos_cache.union({"n.", "v.", "adj.", "adv.", "pron.", "num.", "art.", "prep.", "conj.", "interj.", "v.(vt.)", "v.(vi.)", "vt.", "vi.", "释义"}))
                    base_pos_opts.sort()
                    pos_options = base_pos_opts + ["➕ 新增自定义词性..."]
                    
                    with scroll:
                        for node in err_nodes:
                            with ui.card().classes('w-full mb-[2dvh] p-[2vw] border-2 border-red-500/50 bg-red-900/20'):
                                with ui.row().classes('w-full justify-between items-center mb-[1dvh]'):
                                    chk = ui.checkbox(f"[{node['b']} - {node['u']}]", value=True)
                                    ui.label(" | ".join(node['reasons'])).classes('text-red-400 text-[1.5dvh]')
                                
                                inp_word = ui.input('英文拼写', value=node['meta'].get('单词', '')).classes('w-full mb-[1dvh]')
                                pos_container = ui.column().classes('w-full gap-[1dvh]')
                                pos_inputs = []
                                existing_pos = {k: v for k, v in node['meta'].items() if k not in ["单词", "_uid", "source_book"]}
                                if not existing_pos: existing_pos = {"": ""}
                                
                                def add_pos_ui(container, p_list, init_k, init_v):
                                    with container:
                                        row_ui = ui.column().classes('w-full glass-card p-[2vw]')
                                        with row_ui:
                                            if init_k: ui.label(f'AI识别标签: [{init_k}]').classes('text-[1.5dvh] text-orange-300 mb-[0.5dvh]')
                                            rv = ui.input('释义内容', value=str(init_v)).classes('w-full mb-[1dvh]')
                                            with ui.row().classes('w-full items-center no-wrap gap-[2vw]'):
                                                default_sel = init_k.lower() if init_k.lower() in base_pos_opts else None
                                                rk_sel = ui.select(pos_options, label='选择规范词性', value=default_sel).classes('flex-1')
                                                rk_inp = ui.input('输入新词性 (如: n.)').classes('flex-1')
                                                rk_inp.set_visibility(rk_sel.value == "➕ 新增自定义词性...")
                                                def on_sel_change(e, inp=rk_inp): inp.set_visibility(e.value == "➕ 新增自定义词性...")
                                                rk_sel.on_value_change(on_sel_change)
                                                btn_del = ui.button(icon='delete', color='red').props('flat round size=sm')
                                                row_data = {'sel': rk_sel, 'inp': rk_inp, 'v': rv, 'ui': row_ui}
                                                p_list.append(row_data)
                                                btn_del.on('click', lambda r=row_data: (r['ui'].delete(), p_list.remove(r)))

                                for pk, pv in existing_pos.items(): add_pos_ui(pos_container, pos_inputs, pk, pv)
                                ui.button('+ 添加另一组意思与词性', on_click=lambda c=pos_container, p=pos_inputs: add_pos_ui(c, p, "", "")).props('flat size=sm color=blue')
                                node_uis.append({'node': node, 'chk': chk, 'inp_word': inp_word, 'pos_inputs': pos_inputs})
                    
                    def submit_fixes():
                        for nu in node_uis:
                            if nu['chk'].value:
                                w_val = nu['inp_word'].value.strip()
                                if not w_val: return ui.notify("勾选项的单词不能为空！", type='negative')
                                new_meta = {"单词": w_val}
                                has_pos = False
                                for r in nu['pos_inputs']:
                                    k = r['inp'].value.strip() if r['sel'].value == "➕ 新增自定义词性..." else (r['sel'].value.strip() if r['sel'].value else "")
                                    k = normalize_pos_key(k)
                                    v = r['v'].value.strip()
                                    if k and v: new_meta[k] = v; has_pos = True; db.pos_cache.add(k)
                                
                                if not has_pos: return ui.notify(f"单词 [{w_val}] 缺少有效的词性或释义！", type='negative')
                                b, u, wid = nu['node']['b'], nu['node']['u'], nu['node']['wid']
                                if b not in v_data: v_data[b] = {}
                                if u not in v_data[b]: v_data[b][u] = {}
                                v_data[b][u][wid] = new_meta
                        
                        db.save_data(); d.close(); execute_import_phase2(v_data)

                    with ui.row().classes('w-full justify-end gap-[2vw] mt-[2dvh]'):
                        ui.button('取消导入', on_click=d.close).classes('bg-gray-500')
                        ui.button('确认匹配并导入', on_click=submit_fixes).classes('bg-blue-500')
                d.open()

            def execute_import_phase1(standardized_data):
                valid_data, invalid_nodes = validate_data(standardized_data)
                if invalid_nodes: show_validation_dialog(valid_data, invalid_nodes)
                else: execute_import_phase2(valid_data)

            # [核心修复] 根据选中项的深度智能跳过弹窗
            if leaf_level == 2 and target_unit:
                execute_import_phase1({target_book: {target_unit: raw_data}})
            elif leaf_level == 3 and target_book and not target_unit:
                execute_import_phase1({target_book: raw_data})
            elif leaf_level == 4:
                prefix = f"{target_book}/" if target_book else ""
                if prefix: raw_data = {f"{prefix}{b}": d for b, d in raw_data.items()}
                execute_import_phase1(raw_data)
            elif leaf_level <= 3:
                # 只选了根目录但数据是二级的，需要补全信息
                with ui.dialog() as assign_dialog, ui.card().classes('glass-card p-[4vw] w-[90vw]'):
                    ui.label('为导入数据分配书册与单元').classes('text-[2.5dvh] font-bold mb-[2dvh]')
                    book_opts = list(db.vocab.keys()); book_opts.insert(0, "➕ 创建新书册...")
                    book_sel = ui.select(book_opts, label='选择目标书册', value=target_book if target_book else (book_opts[0] if len(book_opts)==1 else book_opts[1])).classes('w-full mb-[1dvh]')
                    book_inp = ui.input('输入新书册名称').classes('w-full mb-[2dvh]')
                    book_inp.set_visibility(book_sel.value == "➕ 创建新书册...")
                    
                    unit_sel = unit_inp = None
                    if leaf_level == 2:
                        unit_sel = ui.select([], label='选择目标单元').classes('w-full mb-[1dvh]')
                        unit_inp = ui.input('输入新单元名称').classes('w-full mb-[2dvh]')
                        def update_units(e=None):
                            if book_sel.value == "➕ 创建新书册...":
                                book_inp.set_visibility(True)
                                unit_sel.options = ["➕ 创建新单元..."]; unit_sel.value = "➕ 创建新单元..."
                            else:
                                book_inp.set_visibility(False)
                                u_opts = list(db.vocab.get(book_sel.value, {}).keys()); u_opts.insert(0, "➕ 创建新单元...")
                                unit_sel.options = u_opts; unit_sel.value = u_opts[0] if len(u_opts)==1 else u_opts[1]
                            unit_sel.update(); unit_inp.set_visibility(unit_sel.value == "➕ 创建新单元...")
                        book_sel.on_value_change(update_units); unit_sel.on_value_change(lambda e: unit_inp.set_visibility(unit_sel.value == "➕ 创建新单元..."))
                        update_units() 
                    else:
                        book_sel.on_value_change(lambda e: book_inp.set_visibility(book_sel.value == "➕ 创建新书册..."))
                        
                    def confirm_assign():
                        final_book = book_inp.value.strip() if book_sel.value == "➕ 创建新书册..." else book_sel.value
                        if not final_book: return ui.notify('书册名称不能为空！', type='warning')
                        if target_book and book_sel.value == "➕ 创建新书册...": final_book = f"{target_book}/{final_book}"
                        final_data = raw_data
                        if leaf_level == 2:
                            final_unit = unit_inp.value.strip() if unit_sel.value == "➕ 创建新单元..." else unit_sel.value
                            if not final_unit: return ui.notify('单元名称不能为空！', type='warning')
                            final_data = {final_unit: final_data} 
                        assign_dialog.close(); execute_import_phase1({final_book: final_data})

                    with ui.row().classes('w-full justify-end gap-[2vw] mt-[2dvh]'):
                        ui.button('取消', on_click=assign_dialog.close).classes('bg-gray-500')
                        ui.button('确认分配并导入', on_click=confirm_assign).classes('bg-blue-500')
                assign_dialog.open()
            else: raise ValueError(f"JSON 嵌套异常 (深达 {leaf_level} 层)。")
        except json.JSONDecodeError: ui.notify('JSON 格式不合法 (可能缺失逗号或括号)。', type='negative')
        except Exception as e: ui.notify(f'错误: {e}', type='negative')
            
    ui.button('智能校验并导入', on_click=process_import).classes('w-full mt-[1dvh] bg-blue-500 py-[1dvh] font-bold')
    
    ui.label('获取 AI 格式化提示词').classes('text-[2dvh] font-bold mt-[3dvh] mb-[1dvh] text-blue-300')
    
    # [核心修复] 原文一字不落的 AI 提示词
    ai_prompt_single = """请帮我把以下内容（文本或图片）转换为严格的 JSON 格式，方便我导入听写系统。
【结构要求：单单元扁平模式】
1. 必须是单层扁平化结构：外层键名为"唯一的单词ID"（如word_01），值为该单词的属性字典。
2. 属性字典中，必须包含一个键名为 "单词"，值为英文拼写。如果是短语包含空格即可。
3. 其他属性键名为词性（如 "n.", "v."，若无词性可直接用 "释义"），值为中文解释。
4. 纯 JSON 代码，不要外层书名/单元包裹。
【输出严格规范】
请务必将结果直接包裹在可复制的 ```json 和 ``` 代码块中！
请直接输出 JSON 代码块，绝不要输出任何解释、问候语、确认语或普通对话内容！"""

    ai_prompt_multi = """请帮我把以下内容（可能是多张图片或长文本）转换为严格的 JSON 格式，方便我导入听写系统。
【结构要求：多书册/多单元完整层级模式】
1. 系统需要完整的层级结构：{ "书册名称": { "单元名称": { "单词ID": {属性字典} } } }。
2. 请根据我提供的内容，自动识别或归纳出合理的“书册名称”（如：八年级上册）和“单元名称”（如：Unit 1）。如果图片中跨越了多个单元，请将它们正确分类到对应的单元对象下。
3. 单词ID需要保证在单元内唯一（如 word_01）。
4. 属性字典中，必须包含一个键名为 "单词"，值为英文拼写。如果是短语包含空格即可。
5. 其他属性键名为词性（如 "n.", "v."，若无词性可直接用 "释义"），值为中文解释。
【输出严格规范】
请务必将结果直接包裹在可复制的 ```json 和 ``` 代码块中！
请直接输出 JSON 代码块，绝不要输出任何解释、问候语、确认语或普通对话内容！"""

    # [核心修复] 防封锁的系统剪贴板备用方案
    def safe_copy(text: str, title: str):
        try:
            ui.clipboard.write(text)
            ui.notify('尝试自动写入剪贴板... 如失败请使用弹窗手动复制。', type='info')
        except Exception: pass
        with ui.dialog() as copy_dialog, ui.card().classes('glass-card p-[4vw] w-[95vw]'):
            ui.label(title).classes('text-[2dvh] font-bold text-green-400 mb-[1dvh]')
            ui.label('由于浏览器安全策略限制，请长按下方代码框 -> 全选 -> 复制').classes('text-[1.5dvh] text-gray-300 mb-[1dvh]')
            ui.textarea(value=text).classes('w-full bg-black/50 text-white').props('readonly rows="15"')
            ui.button('关闭窗口', on_click=copy_dialog.close).classes('w-full mt-[2dvh] bg-gray-600')
        copy_dialog.open()

    with ui.row().classes('w-full gap-[2vw]'):
        ui.button('复制单单元模板', icon='content_copy', on_click=lambda: safe_copy(ai_prompt_single, '复制: 单单元模板')).classes('flex-1 bg-green-600 py-[1dvh] text-[1.5dvh]')
        ui.button('复制完整层级模板', icon='content_copy', on_click=lambda: safe_copy(ai_prompt_multi, '复制: 完整层级模板')).classes('flex-1 bg-teal-600 py-[1dvh] text-[1.5dvh]')

    ui.label('词库导出与备份').classes('text-[2.2dvh] font-bold mt-[4dvh] mb-[1dvh] text-yellow-400')
    def export_json():
        ui.download(json.dumps(db.vocab, ensure_ascii=False, indent=2).encode('utf-8'), f'dictation_backup_{datetime.now().strftime("%Y%m%d")}.json')
        ui.notify('备份文件已触发下载！', type='positive')
    def copy_full_json():
        full_json = json.dumps(db.vocab, ensure_ascii=False, indent=2)
        safe_copy(full_json, '复制完整词库数据')
    with ui.row().classes('w-full gap-[2vw]'):
        ui.button('下载完整备份', icon='download', on_click=export_json).classes('flex-1 bg-purple-500 py-[1dvh] text-[1.5dvh]')
        ui.button('复制词库代码', icon='content_copy', on_click=copy_full_json).classes('flex-1 bg-purple-600 py-[1dvh] text-[1.5dvh]')


def admin_tab_settings() -> None:
    current_acc = db.get_acc(state.current_account_id)
    acc_settings = current_acc.setdefault('settings', {})

    scroll = ui.scroll_area().classes('w-full flex-1')
    with scroll:
        ui.label(f'[{current_acc["name"]}] 专属听写配置').classes('text-[2.2dvh] font-bold text-blue-400 mb-[1dvh]')
        with ui.card().classes('glass-card w-full mb-[3dvh]'):
            def save_setting(): db.save_data(); ui.notify('账户专属配置已保存', type='positive')
            ui.switch('隐藏听写前配置界面 (直接使用默认)', value=acc_settings.get('hide_test_config', False), on_change=lambda e: (acc_settings.update({'hide_test_config': e.value}), save_setting())).classes('mb-[1dvh]')
            ui.switch('允许倒退与修改', value=acc_settings.get('allow_backward', True), on_change=lambda e: (acc_settings.update({'allow_backward': e.value}), save_setting())).classes('mb-[1dvh]')
            ui.switch('开启首字母提示', value=acc_settings.get('allow_hint', False), on_change=lambda e: (acc_settings.update({'allow_hint': e.value}), save_setting())).classes('mb-[1dvh]')
            ui.switch('限时关联计算锁 (时间到强制跳题)', value=acc_settings.get('timer_lock', True), on_change=lambda e: (acc_settings.update({'timer_lock': e.value}), save_setting())).classes('mb-[1dvh]')
            
            ui.number('默认单题限时 (秒)', value=acc_settings.get('per_q_time', 20.0), format='%.1f', on_change=lambda e: (acc_settings.update({'per_q_time': float(e.value) if e.value is not None else 20.0}), save_setting())).classes('w-full mt-[1dvh]')
            ui.number('提示亮起延迟 (秒)', value=acc_settings.get('hint_delay', 5), format='%d', on_change=lambda e: (acc_settings.update({'hint_delay': int(e.value) if e.value is not None else 5}), save_setting())).classes('w-full mt-[1dvh]')
            ui.number('每局最大提示次数 (0为无限)', value=acc_settings.get('hint_limit', 0), format='%d', on_change=lambda e: (acc_settings.update({'hint_limit': int(e.value) if e.value is not None else 0}), save_setting())).classes('w-full mt-[1dvh]')

        ui.label(f'[{current_acc["name"]}] 数据清理区').classes('text-[2.2dvh] font-bold mt-[2dvh] mb-[1dvh] text-red-600')
        def do_clear_stats():
            current_acc['history'] = []; current_acc['stats'] = {}; db.save_data()
            ui.notify('个人统计数据和记录已清空！', type='positive'); render_view()
            
        def do_clear_mistakes():
            for s in current_acc.get('stats', {}).values(): s['wrong'] = 0
            db.save_data()
            ui.notify('个人错题本已被清空！', type='positive'); render_view()
            
        ui.button('清空所有统计与历史记录 (需验密)', icon='delete_sweep', on_click=lambda: require_password(do_clear_stats)).classes('w-full bg-red-800 py-[1dvh] mb-[1dvh]')
        ui.button('仅清空错题本记录 (需验密)', icon='playlist_remove', on_click=lambda: require_password(do_clear_mistakes)).classes('w-full bg-red-600 py-[1dvh] mb-[3dvh]')

        ui.label('全局安全控制与密码管理').classes('text-[2.2dvh] font-bold text-yellow-400 mb-[1dvh]')
        with ui.card().classes('glass-card w-full mb-[3dvh]'):
            ui.label('高强度密码加密隔离').classes('font-bold text-[1.8dvh]')
            ui.label('开启后系统脚本内的明文密码将被直接擦除，转为深层加密态储存，断绝盗码风险。').classes('text-[1.5dvh] text-gray-400 mb-[2dvh]')
            
            enc_status = '🔒 已加密隐藏 (安全)' if ENCRYPT_PASSWORD else '⚠️ 明文暴露在脚本顶端'
            lbl_status = ui.label(f"当前状态：{enc_status}").classes('font-bold text-yellow-400 mb-[1dvh]')
            
            def toggle_encryption():
                def action():
                    global ADMIN_PASSWORD, ENCRYPT_PASSWORD
                    curr = get_admin_pwd()
                    if ENCRYPT_PASSWORD: 
                        rewrite_py_vars({'ENCRYPT_PASSWORD': False, 'ADMIN_PASSWORD': curr})
                        db.global_settings.pop('password', None); db.save_data()
                        ADMIN_PASSWORD = curr; ENCRYPT_PASSWORD = False
                        ui.notify('密码已恢复明文！', type='positive')
                    else: 
                        db.global_settings['password'] = curr; db.save_data()
                        rewrite_py_vars({'ENCRYPT_PASSWORD': True, 'ADMIN_PASSWORD': ''})
                        ADMIN_PASSWORD = ''; ENCRYPT_PASSWORD = True
                        ui.notify('密码已转为内部加密！明文已抹除。', type='positive')
                    lbl_status.set_text(f"当前状态：{'🔒 已加密隐藏 (安全)' if ENCRYPT_PASSWORD else '⚠️ 明文暴露在脚本顶端'}")
                require_password(action)
            ui.button('点击切换加密/明文状态', on_click=toggle_encryption).classes('w-full bg-blue-600')

        with ui.card().classes('glass-card w-full mb-[3dvh]'):
            ui.label('设置临时访客密码').classes('font-bold text-[1.8dvh]')
            ui.label('本次运行有效，可授权他人进行听写“上帝跳转”，但绝无后台权限。').classes('text-[1.5dvh] text-gray-400 mb-[1dvh]')
            g_pwd = ui.input('输入一次性访客密码').classes('w-full')
            def set_guest():
                if not g_pwd.value: return ui.notify('密码不可为空', type='warning')
                state.guest_password = g_pwd.value
                ui.notify(f'临时访客密码已生效: {state.guest_password}', type='positive')
            ui.button('激活访客身份', on_click=set_guest).classes('mt-[1dvh] bg-yellow-600 w-full')

        with ui.card().classes('glass-card w-full mb-[4dvh]'):
            ui.label('修改系统管理员主密码').classes('font-bold text-[1.8dvh] mb-[1dvh]')
            old_pwd = ui.input('请输入当前旧密码', password=True).classes('w-full mb-[1dvh]')
            new_pwd = ui.input('请输入新密码', password=True).classes('w-full')
            def change_pwd():
                global ADMIN_PASSWORD, ENCRYPT_PASSWORD
                if (str(old_pwd.value).strip() if old_pwd.value else "") == get_admin_pwd():
                    if len(new_pwd.value) > 0:
                        db.global_settings.pop('password', None)
                        db.save_data()
                        rewrite_py_vars({'ADMIN_PASSWORD': new_pwd.value, 'ENCRYPT_PASSWORD': False})
                        ADMIN_PASSWORD = new_pwd.value; ENCRYPT_PASSWORD = False
                        ui.notify('超级密码修改成功！加密模式已自动重置为明文。', type='positive')
                        lbl_status.set_text('当前状态：⚠️ 明文暴露在脚本顶端')
                        old_pwd.value = ''; new_pwd.value = ''
                    else: ui.notify('新密码不能为空', type='warning')
                else: ui.notify('旧密码验证失败', type='negative')
            ui.button('确认修改密码', on_click=change_pwd).classes('w-full mt-[2dvh] bg-red-500 py-[1dvh]')

        ui.label('全局危险操作核心区').classes('text-[2.2dvh] font-bold mt-[2dvh] mb-[1dvh] text-red-600')
        def do_clear_all():
            db.vocab = {}; db.accounts = {}; db.load_data(); db.save_data() 
            ui.notify('所有数据、配置及所有账户已被抹除！', type='positive'); render_view()
        ui.button('抹除所有账户及词库数据 (需验密)', icon='delete_forever', on_click=lambda: require_password(do_clear_all)).classes('w-full bg-red-700 py-[1.5dvh]')


def admin_tab_logs() -> None:
    current_acc = db.get_acc(state.current_account_id)
    my_history = current_acc.get('history', [])
    def clear_all(): current_acc['history'] = []; db.save_data(); render_view()
    
    ui.label(f'[{current_acc["name"]}] 专属听写明细').classes('text-[2dvh] font-bold mb-[1dvh] text-blue-300')
    ui.button('清空所有记录', on_click=lambda: multi_action_dialog('警告', '清空所有?', [('取消','gray',None),('清空','red',clear_all)])).classes('w-full bg-red-500 mb-[1dvh]')
    scroll = ui.scroll_area().classes('w-full flex-1')
    with scroll:
        for idx, log in reversed(list(enumerate(my_history))):
            score_val = log.get('score_val', log.get('correct', 0))
            score_disp = f"{score_val:.1f}/{log['total']}" if isinstance(score_val, float) else f"{score_val}/{log['total']}"
            hints = log.get('used_hints', 0)
            with ui.expansion(f"{log['timestamp']} ({log['score']}分 - {log['mode']} - {log.get('status', '已完成')})").classes('bg-white/5 w-full mb-[1dvh]'):
                ui.label(f"总得分点: {score_disp} | 提示使用: {hints}次").classes('pl-[2vw] text-gray-300')
                for d in log.get('details', []):
                    c_val = d.get('score_val', 1.0 if d.get('correct') else 0.0)
                    # 判断是否为"漏选但未错选"的部分得分（仅词性题）
                    is_partial = (d.get('mode') == 'pos') and (0 < c_val < 1.0)
                    if c_val >= 1.0:
                        color = 'text-green-400'
                    elif is_partial:
                        color = 'text-yellow-400'
                    else:
                        color = 'text-red-400'
                    # 部分得分时附加 m/n 标注
                    partial_tag = ''
                    if is_partial:
                        n = len(d.get('expected', []))
                        m = round(c_val * n) if n > 0 else 0
                        partial_tag = f' ({m}/{n})'
                    ui.label(f"[{d.get('mode', '未知')}] {d['word']} -> {d['ans']} (标答:{d.get('expected',[])}){partial_tag}").classes(f'pl-[4vw] text-[1.8dvh] {color}')

def render_select_content() -> None:
    node_to_meta, tick_keys = {}, []
    tree_dict = {}
    for book_path, units in db.vocab.items():
        parts = book_path.split('/')
        curr = tree_dict
        path_so_far = []
        for p in parts:
            path_so_far.append(p)
            node_id = ":::".join(path_so_far)
            if p not in curr: curr[p] = {'id': node_id, 'label': p, 'children': {}}
            curr = curr[p]['children']
            
        for unit, words in units.items():
            u_id = f"{book_path}:::{unit}"
            curr[unit] = {'id': u_id, 'label': unit, 'children': {}}
            for wid, meta in words.items():
                w_id = f"{u_id}:::{wid}"
                curr[unit]['children'][wid] = {'id': w_id, 'label': meta.get('单词', '')}
                m_copy = meta.copy(); m_copy['_uid'] = w_id
                node_to_meta[w_id] = m_copy
                if any(sw.get('_uid') == w_id for sw in state.selected_words): tick_keys.append(w_id)

    def dict_to_list(d, is_word_level=False):
        res = []
        for k, v in d.items():
            node = {'id': v['id']}
            has_children = bool(v.get('children'))
            if not is_word_level and has_children and ':::' not in v['id']: icon = '📁 ' 
            elif not is_word_level and has_children: icon = '📄 ' 
            else: icon = ''   
            node['label'] = f"{icon}{v.get('label', k)}"
            if has_children:
                is_next_word = ':::' in v['id'] and len(v['id'].split(':::')) == 2
                node['children'] = dict_to_list(v['children'], is_next_word)
            res.append(node)
        return res

    base_nodes = dict_to_list(tree_dict)

    with ui.column().classes('w-full h-full p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)] relative'):
        with ui.row().classes('w-full items-center mb-[1dvh]'):
            ui.button(icon='arrow_back', on_click=lambda: change_view('home')).classes('glass-card').props('flat round')
            ui.label('听写范围').classes('text-[3dvh] font-bold ml-[3vw]')
            
        with ui.row().classes('w-full items-center gap-[2vw] mb-[2dvh]'):
            search_inp = ui.input('搜索文件夹/单词集/单词...').classes('flex-1 bg-white/10 rounded px-[2vw]')
            t_state = {'all_selected': False}
            def toggle_all():
                t_state['all_selected'] = not t_state['all_selected']
                t._props['ticked'] = list(node_to_meta.keys()) if t_state['all_selected'] else []
                t.update()
            ui.button('全选/反选', on_click=toggle_all).classes('bg-blue-600 py-[1dvh]')

        scroll = ui.scroll_area().classes('w-full flex-1 glass-card p-[2vw] mb-[8dvh]')
        with scroll:
            t = ui.tree(base_nodes, tick_strategy='leaf').props('text-color="white"')
            t._props['ticked'] = tick_keys 

            def filter_tree(e):
                val = e.value.lower()
                if not val: t._props['nodes'] = base_nodes; t.update(); return
                def search_nodes(nodes):
                    filtered = []
                    import copy
                    for node in copy.deepcopy(nodes):
                        if val in node['label'].lower(): filtered.append(node)
                        elif 'children' in node:
                            child_res = search_nodes(node['children'])
                            if child_res: node['children'] = child_res; filtered.append(node)
                    return filtered
                t._props['nodes'] = search_nodes(base_nodes); t.update()
            search_inp.on('input', filter_tree)

        def go_next():
            state.selected_words = [node_to_meta[tid] for tid in t._props.get('ticked', []) if tid in node_to_meta]
            if not state.selected_words: return ui.notify('请勾选内容', type='warning')
            change_view('select_mode')

        ui.button('继续', on_click=go_next).classes('absolute bottom-[var(--safe-bottom)] left-[5vw] right-[5vw] py-[2dvh] bg-blue-500 font-bold rounded-[2dvh]')


def render_select_mode() -> None:
    current_acc = db.get_acc(state.current_account_id)
    acc_settings = current_acc.get('settings', {})

    with ui.column().classes('w-full h-full items-center p-[5vw] pt-[var(--safe-top)]'):
        ui.button(icon='arrow_back', on_click=lambda: change_view('select_content')).classes('glass-card absolute top-[var(--safe-top)] left-[5vw]').props('flat round')
        ui.label('混合生成模式').classes('text-[3.5dvh] font-bold mt-[6dvh] mb-[1dvh]')
        
        original_queue = state.selected_words.copy()
        n = len(original_queue)
        ui.label(f'当前单词池容量: {n} 个').classes('text-[1.8dvh] text-gray-400 mb-[2dvh]')
        
        modes_cfg = [
            {'key': 'spelling', 'name': '拼写模式 (中译英)', 'enabled': True, 'qty': n},
            {'key': 'pos', 'name': '词性辨析 (选词性)', 'enabled': False, 'qty': n},
            {'key': 'translation', 'name': '翻译模式 (英译中)', 'enabled': False, 'qty': n}
        ]
        
        hide_config = acc_settings.get('hide_test_config', False)
        
        scroll = ui.scroll_area().classes('w-full flex-1 mb-[2dvh]')
        with scroll:
            ui.label('题型与数量配置 (允许重复测试单词)').classes('text-[2dvh] font-bold text-blue-300 mb-[1dvh]')
            for m in modes_cfg:
                m['enabled_state'] = m['enabled']
                m['qty_state'] = m['qty']
                with ui.card().classes('glass-card w-full mb-[1.5dvh] p-[3vw]'):
                    with ui.row().classes('w-full items-center justify-between'):
                        m['chk'] = ui.checkbox(m['name'], value=m['enabled']).classes('font-bold text-[2dvh]')
                        m['inp'] = ui.number('出题数', value=m['qty'], min=1, max=n, format='%d').classes('w-[30vw]')
                        m['inp'].set_visibility(m['enabled'])
                        
                        def on_chk_change(e, m=m):
                            m['inp'].set_visibility(e.value)
                            m['enabled_state'] = e.value
                            if not hide_config: update_times('qty')
                        m['chk'].on_value_change(on_chk_change)
                        
                        def on_inp_change(e, m=m):
                            m['qty_state'] = int(e.value) if e.value else n
                            if not hide_config: update_times('qty')
                        m['inp'].on_value_change(on_inp_change)
            
            if not hide_config:
                ui.label('全局难度配置').classes('text-[2dvh] font-bold mt-[2dvh] mb-[1dvh] text-yellow-400')
                with ui.card().classes('glass-card w-full p-[3vw]'):
                    switch_backward = ui.switch('允许倒退与修改', value=acc_settings.get('allow_backward', True)).classes('w-full mb-[1dvh]')
                    switch_hint = ui.switch('开启首字母智能提示', value=acc_settings.get('allow_hint', False)).classes('w-full mb-[1dvh]')
                    
                    with ui.row().classes('w-full items-center justify-between mb-[1dvh]'):
                        ui.label('时间关联计算锁').classes('text-[1.8dvh] text-gray-300')
                        switch_lock = ui.switch('', value=acc_settings.get('timer_lock', True))
                    
                    inp_per = ui.number('单题限时 (秒)', value=acc_settings.get('per_q_time', 20.0), format='%.1f').classes('w-full mb-[1dvh]')
                    init_tq = sum(m['qty_state'] for m in modes_cfg if m['enabled_state'])
                    init_tq = max(1, init_tq)
                    init_total = round(acc_settings.get('per_q_time', 20.0) * init_tq * 0.9, 1)
                    inp_total = ui.number('交卷总限时 (秒)', value=init_total, format='%.1f').classes('w-full')
                    
                    is_updating = {'val': False}
                    def update_times(source):
                        if is_updating['val']: return
                        is_updating['val'] = True
                        try:
                            tq = sum(m['qty_state'] for m in modes_cfg if m['enabled_state'])
                            if tq <= 0: tq = 1
                            if switch_lock.value:
                                if source == 'per' or source == 'qty':
                                    pv = float(inp_per.value) if inp_per.value else 0.0
                                    inp_total.value = round(pv * tq * 0.9, 1)
                                elif source == 'total':
                                    tv = float(inp_total.value) if inp_total.value else 0.0
                                    inp_per.value = round(tv / (tq * 0.9), 1)
                        except Exception: pass
                        finally: is_updating['val'] = False

                    switch_lock.on_value_change(lambda e: update_times('per') if e.value else None)
                    inp_per.on_value_change(lambda e: update_times('per'))
                    inp_total.on_value_change(lambda e: update_times('total'))

        def start_mixed_test():
            state.test_queue = []
            total_selected_q = 0
            
            for m in modes_cfg:
                if m['enabled_state']:
                    q = int(m['qty_state'])
                    q = min(max(1, q), n)
                    total_selected_q += q
                    sampled = random.sample(original_queue, q)
                    for item in sampled:
                        new_item = item.copy()
                        new_item['_test_mode'] = m['key']
                        pos_keys = [k for k in new_item.keys() if k not in ["单词", "_uid", "source_book", "_ask_pos", "_test_mode"]]
                        new_item['_ask_pos'] = random.choice(pos_keys) if pos_keys else ""
                        state.test_queue.append(new_item)
                        
            if not state.test_queue: return ui.notify('请至少勾选一种题型！', type='warning')
            random.shuffle(state.test_queue)
            
            state.test_mode = "混合模式"
            state.current_q_index = 0
            state.user_answers = {}
            state.score_log = []
            state.used_hints = set()
            
            if hide_config:
                state.allow_backward = acc_settings.get('allow_backward', True)
                state.allow_hint = acc_settings.get('allow_hint', False)
                state.per_q_time = float(acc_settings.get('per_q_time', 20.0))
                state.total_time = float(round(state.per_q_time * total_selected_q * 0.9, 1))
            else:
                state.allow_backward = switch_backward.value
                state.allow_hint = switch_hint.value
                state.per_q_time = float(inp_per.value) if inp_per.value else 20.0
                state.total_time = float(inp_total.value) if inp_total.value else float(round(state.per_q_time * total_selected_q * 0.9, 1))
            
            state.tot_left = state.total_time
            change_view('testing')

        ui.button('融合生成试卷并开始', on_click=start_mixed_test).classes('w-full py-[2dvh] bg-green-500 font-bold text-[2.5dvh] rounded-[2dvh]')
def render_testing() -> None:
    current_acc = db.get_acc(state.current_account_id)
    my_stats = current_acc.get('stats', {})
    acc_settings = current_acc.get('settings', {})
    
    ui.element('div').props('id="testing_flag"').classes('hidden')

    class TestEnv:
        class NavState:
            def __init__(self): self.prev_clicks = 0
        def __init__(self):
            self.active = True
            self.last_speed_warn = 0
            self.hint_enabled = False
            self.hint_btn = None
            self.hint_lbl = None
            self.timer_obj = None
            self.nav_state = self.NavState() 
            self.force_record_current = None
            self.word_start_time = 0.0   # [累计用时] 当前题开始显示的时间戳
            self.word_time_accum = {}    # [累计用时] {题目索引: 累计秒数}
            self._last_q_idx = -1       # [累计用时] 上次记录的题目索引
        
    env = TestEnv()

    def cleanup_env():
        env.active = False
        if hasattr(env, 'timer_obj') and env.timer_obj and getattr(env.timer_obj, 'active', False): env.timer_obj.cancel()

    with ui.column().classes('w-full h-full p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)] relative') as container:
        with ui.row().classes('w-full justify-between items-center mb-[1dvh] glass-card px-[4vw] py-[1.5dvh]'):
            def exit_test():
                env.active = False
                with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[85vw]'):
                    ui.label('中止听写').classes('text-[2.5dvh] font-bold text-red-400')
                    ui.label('是否保存当前进度以便下次继续？').classes('text-[1.8dvh] my-[2dvh]')
                    
                    def do_save():
                        cleanup_env()
                        if env.force_record_current: env.force_record_current()
                        app.storage.user['dictation_state'] = {
                            'test_mode': state.test_mode, 'test_queue': state.test_queue, 'current_q_index': state.current_q_index,
                            'user_answers': state.user_answers, 'per_q_time': getattr(state, 'per_q_time', 20.0),
                            'total_time': getattr(state, 'total_time', 0.0), 'tot_left': getattr(state, 'tot_left', 0.0),
                            'allow_backward': state.allow_backward, 'allow_hint': state.allow_hint, 'used_hints': list(state.used_hints),
                            'score_log': getattr(state, 'score_log', []) # [修复] 将 score_log 纳入进度保存
                        }
                        temp_log = [state.user_answers[i] for i, m in enumerate(state.test_queue) if i in state.user_answers]
                        score_val = sum(l.get('score_val', 1.0 if l.get('correct') else 0.0) for l in temp_log)
                        current_acc.setdefault('history', []).append({
                            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "mode": state.test_mode,
                            "score": 0, "total": len(state.test_queue), "correct": score_val, "score_val": score_val,
                            "used_hints": len(state.used_hints), "status": "已保存待继续", "details": temp_log
                        })
                        db.save_data(); d.close(); change_view('home')
                        
                    def do_discard():
                        cleanup_env()
                        app.storage.user['dictation_state'] = None
                        temp_log = list(state.user_answers.values())
                        score_val = sum(l.get('score_val', 1.0 if l.get('correct') else 0.0) for l in temp_log)
                        current_acc.setdefault('history', []).append({
                            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "mode": state.test_mode,
                            "score": 0, "total": len(state.test_queue), "correct": score_val, "score_val": score_val,
                            "used_hints": len(state.used_hints), "status": "中途被放弃", "details": temp_log
                        })
                        db.save_data(); d.close(); change_view('home')
                        
                    with ui.row().classes('w-full justify-between gap-[2vw]'):
                        ui.button('直接放弃', on_click=do_discard).classes('bg-red-500 py-0 px-[3vw]')
                        ui.button('保存进度', on_click=do_save).classes('bg-green-500 py-0 px-[3vw]')
                        ui.button('取消', on_click=lambda: (setattr(env, 'active', True), d.close())).classes('bg-gray-500 py-0 px-[3vw]')
                d.open()
                
            ui.button(icon='logout', on_click=exit_test).props('flat round size=sm').classes('text-red-400')
            lbl_progress = ui.label('').classes('font-bold text-[2dvh]')
            
            def show_word_history():
                if state.current_q_index >= len(state.test_queue): return
                word = state.test_queue[state.current_q_index]['单词']
                w_st = my_stats.get(word, {})
                h_list = w_st.get('history', [])
                cum_secs = w_st.get('cumulative_seconds', 0)
                with ui.dialog() as d, ui.card().classes('glass-card p-[4vw] w-[80vw] max-h-[60dvh] overflow-y-auto'):
                    ui.label(f'{word} 记录').classes('font-bold text-[2.5dvh] mb-[1dvh]')
                    ui.label(f'累计用时: {cum_secs} 秒').classes('text-[1.5dvh] text-yellow-300 mb-[1dvh]')
                    if not h_list: ui.label('暂无记录').classes('text-gray-400')
                    for h in reversed(h_list[-10:]):
                        color = "text-green-400" if h['result']=='对' else "text-red-400"
                        ui.label(f"{h['time']} - {h['result']}").classes(color)
                d.open()
            with ui.row().classes('items-center gap-[1vw] cursor-pointer').on('click', show_word_history):
                lbl_stats = ui.label('').classes('text-[1.5dvh] text-blue-300')
                ui.icon('info', size='2dvh').classes('text-blue-300')

        with ui.row().classes('w-full justify-between mb-[1dvh] px-[2vw]'):
            lbl_tot_timer = ui.label(f'交卷倒计时: {int(getattr(state, "tot_left", 0))}s').classes('text-yellow-400 font-mono text-[1.8dvh]')
            lbl_q_timer = ui.label(f'本题剩余: {int(getattr(state, "q_time_left", 0))}s').classes('text-green-400 font-mono text-[1.8dvh]')

        with ui.card().classes('glass-card w-full flex-1 flex-col items-center justify-center p-[4vw] transition-all duration-300 relative min-h-[45dvh]') as card:
            def play_current_word():
                if state.current_q_index < len(state.test_queue): ui.run_javascript(f'speakWord("{state.test_queue[state.current_q_index]["单词"]}")')
            ui.button(icon='volume_up', on_click=play_current_word).props('flat round').classes('absolute top-[2dvh] right-[2dvh] text-blue-300 z-10')
            
            if getattr(state, 'allow_hint', False):
                with ui.row().classes('absolute top-[2dvh] left-[2dvh] items-center gap-[1vw] z-10'):
                    env.hint_btn = ui.button(icon='lightbulb').props('flat round').classes('text-gray-500 transition-colors duration-300 p-0')
                    env.hint_lbl = ui.label('').classes('text-[1.5dvh] text-white/70 font-mono')
                    env.hint_btn.disable()
                
                def update_hint_ui():
                    limit = acc_settings.get('hint_limit', 0)
                    used = len(state.used_hints)
                    env.hint_lbl.set_text(f"({limit - used}/{limit})" if limit > 0 else "")
                        
                def pop_hint():
                    limit = acc_settings.get('hint_limit', 0)
                    used = len(state.used_hints)
                    idx = state.current_q_index
                    
                    if limit > 0 and idx not in state.used_hints and used >= limit: return ui.notify('已达到本局提示次数上限！', type='warning', position='top')
                    if idx not in state.used_hints: state.used_hints.add(idx); update_hint_ui()

                    meta = state.test_queue[state.current_q_index]
                    w = meta["单词"]
                    current_mode = meta.get('_test_mode', state.test_mode)
                    sel_pos = meta.get('_ask_pos', '')
                    
                    if current_mode == 'spelling':
                        meaning_str = meta.get(sel_pos, '')
                        collisions = [sw["单词"] for sw in state.selected_words if sw.get(sel_pos, '') == meaning_str and sw["单词"].lower() != w.lower()]
                        show_len = 1
                        if collisions:
                            w_lower = w.lower(); max_lcp = 0
                            for cw in collisions:
                                cw_lower = cw.lower(); l = 0
                                while l < len(w_lower) and l < len(cw_lower) and w_lower[l] == cw_lower[l]: l += 1
                                if l > max_lcp: max_lcp = l
                            show_len = max_lcp + 1
                        
                        if show_len > 1:
                            hint_chars, visible = [], 0
                            for char in w:
                                if char in ' .': hint_chars.append(char)
                                elif visible < show_len: hint_chars.append(char); visible += 1
                                else: hint_chars.append('*')
                            hint_text = "".join(hint_chars)
                        else: hint_text = " ".join([seg[0] + "*" * (len(seg)-1) if len(seg)>0 else "" for seg in w.split()])
                    else:
                        target_str = meta.get(sel_pos, '')
                        hint_text = " ".join([seg[0] + "*" * (len(seg)-1) if len(seg)>0 else "" for seg in target_str.split()])
                    ui.notify(f'提示: {hint_text}', position='top', type='info', timeout=3000)
                env.hint_btn.on_click(pop_hint)
            
            content_container = ui.column().classes('w-full flex-1 items-center justify-center')

        def load_question():
            if state.current_q_index >= len(state.test_queue): return
            # [累计用时] 离开上一题时，记录本段停留耗时
            _now_t = time.time()
            if env.word_start_time > 0 and env._last_q_idx >= 0:
                env.word_time_accum[env._last_q_idx] = env.word_time_accum.get(env._last_q_idx, 0) + (_now_t - env.word_start_time)
            env._last_q_idx = state.current_q_index
            env.word_start_time = _now_t
            state.q_time_left = getattr(state, 'per_q_time', 20.0)
            lbl_q_timer.classes(remove='text-yellow-400 text-red-500', add='text-green-400')
            
            if getattr(state, 'allow_hint', False) and getattr(env, 'hint_btn', None):
                env.hint_enabled = False; env.hint_btn.disable(); env.hint_btn.classes(remove='text-yellow-400', add='text-gray-500'); update_hint_ui()
                
            app.storage.user['dictation_state'] = {
                'test_mode': state.test_mode, 'test_queue': state.test_queue, 'current_q_index': state.current_q_index, 
                'user_answers': state.user_answers, 'per_q_time': getattr(state, 'per_q_time', 20), 'total_time': getattr(state, 'total_time', 0),
                'tot_left': getattr(state, 'tot_left', 0), 'allow_backward': getattr(state, 'allow_backward', True), 'allow_hint': getattr(state, 'allow_hint', False),
                'used_hints': list(getattr(state, 'used_hints', set())),
                'score_log': getattr(state, 'score_log', []) # [修复] 将 score_log 纳入进度保存
            }
                
            meta = state.test_queue[state.current_q_index]
            word = meta["单词"]
            sel_pos = meta.get('_ask_pos', '')
            meaning_str = meta.get(sel_pos, '')
            current_mode = meta.get('_test_mode', state.test_mode) 
            
            prev_ans = state.user_answers.get(state.current_q_index, {}).get("ans", "")
            if prev_ans in ["跳过/未作答", "超时未作答"]: prev_ans = ""
            
            lbl_progress.set_text(f'{state.current_q_index+1}/{len(state.test_queue)}')
            st = my_stats.get(word, {"total":0,"correct":0})
            lbl_stats.set_text(f"历史: {st['correct']}/{st['total']}对")
            
            card.classes(remove='success-bg manual-bg shake-anim flash-success flash-error')
            state.is_submitting = False
            
            def record_and_next(is_c: bool, mode: str, q: str, ans: str, manual: bool, expected: list, score_val: float = None):
                if score_val is None: score_val = 1.0 if is_c else 0.0
                state.user_answers[state.current_q_index] = {
                    "word": word, "mode": mode, "q": q, "ans": ans,
                    "correct": is_c, "score_val": score_val, "needs_manual": manual, "expected": expected
                }
                state.is_submitting = False; action_next()

            content_container.clear()
            with content_container:
                if current_mode == 'spelling':
                    pos_display = sel_pos.lower() if sel_pos and sel_pos != "释义" else ""
                    if pos_display: ui.label(pos_display).classes('text-[2.2dvh] text-gray-400 mb-[0.5dvh]')
                    ui.label(meaning_str).classes('text-[3dvh] font-bold mb-[1dvh] text-center w-full')
                    
                    vk_state = {'text': prev_ans, 'caps': False, 'sym': False}
                    disp = ui.html().classes('w-full text-center text-[3.5dvh] mb-[1dvh] min-h-[5dvh] break-all tracking-wider font-mono text-green-300 border-b-2 border-white/50 pb-[0.5dvh]')
                    
                    def update_disp():
                        val = vk_state['text']
                        html_parts = []
                        for char in val:
                            if char == " ": html_parts.append("<span style='display:inline-block; width:1.5ch; height:1.5ch; background-color:rgba(248,113,113,0.8); vertical-align:middle; margin:0 2px; border-radius:0.4dvh;'></span>")
                            else: html_parts.append(char.replace('<', '&lt;').replace('>', '&gt;'))
                        disp.set_content("".join(html_parts) + "<span class='animate-pulse border-r-2 border-green-400 ml-[2px]'>&nbsp;</span>")

                    kb_container = ui.column().classes('w-full gap-[0.8dvh] mt-[1dvh]')
                    def render_kb():
                        kb_container.clear()
                        with kb_container:
                            if not vk_state['sym']:
                                rows = ["q w e r t y u i o p", "a s d f g h j k l", "z x c v b n m"]
                                if vk_state['caps']: rows = [r.upper() for r in rows]
                            else: rows = ["1 2 3 4 5 6 7 8 9 0", "- / : ; ( ) $ & @ \"", ". , ? ! '"]
                            
                            for i, row in enumerate(rows):
                                with ui.row().classes('w-full justify-center gap-[1vw] no-wrap'):
                                    if i == 2:
                                        if not vk_state['sym']:
                                            shift_bg = 'bg-gray-300 text-black' if vk_state['caps'] else 'glass-card text-white'
                                            ui.button('⬆', on_click=lambda: (vk_state.update({'caps': not vk_state['caps']}), render_kb())).classes(f'{shift_bg} flex-1 min-w-[10vw] p-0 text-[2.2dvh] rounded-[1dvh]')
                                        else:
                                            ui.button('[]=', on_click=lambda: ui.notify('特殊符号已激活', position='top')).classes('glass-card text-white flex-1 min-w-[10vw] p-0 text-[1.8dvh] rounded-[1dvh]')

                                    for key in row.split():
                                        ui.button(key, on_click=lambda k=key: (vk_state.update({'text': vk_state['text'] + k}), update_disp())).classes('glass-card text-white flex-1 min-w-0 p-0 text-[2.5dvh] py-[1.2dvh] rounded-[1dvh]')
                                    
                                    if i == 2: ui.button('⌫', on_click=lambda: (vk_state.update({'text': vk_state['text'][:-1]}), update_disp())).classes('glass-card text-white flex-1 min-w-[10vw] p-0 text-[2.2dvh] rounded-[1dvh]')
                            
                            with ui.row().classes('w-full justify-center gap-[1vw] no-wrap'):
                                mode_btn = 'ABC' if vk_state['sym'] else '?123'
                                ui.button(mode_btn, on_click=lambda: (vk_state.update({'sym': not vk_state['sym']}), render_kb())).classes('glass-card text-white w-[18vw] p-0 text-[2dvh] py-[1.2dvh] rounded-[1dvh]')
                                ui.button('空 格', on_click=lambda: (vk_state.update({'text': vk_state['text'] + ' '}), update_disp())).classes('glass-card text-white flex-1 p-0 text-[2dvh] py-[1.2dvh] rounded-[1dvh] tracking-widest')
                                ui.button('确定', on_click=check_sp).classes('bg-blue-500 text-white w-[20vw] p-0 text-[2dvh] py-[1.2dvh] rounded-[1dvh] font-bold')

                    def check_spelling_smart(user_ans: str, target_word: str) -> bool:
                        """
                        括号内容（如序数词）智能验证：
                        - 括号可整体省略不填
                        - 填了数字则数字必须正确
                        - 填了序数后缀则后缀必须正确（23rd/1st/2nd/4th…）
                        - 主体拼写仍用 token 精确匹配
                        """
                        raw = user_ans.strip().lower()
                        tgt = target_word.strip().lower()
                        paren_re = re.compile(r'^(.*?)(?:\s*[（(]([^）)]*)[）)])?\s*$')
                        
                        tm = paren_re.match(tgt)
                        target_main  = tm.group(1).strip() if tm else tgt
                        target_paren = tm.group(2).strip() if (tm and tm.group(2)) else None
                        
                        am = paren_re.match(raw)
                        ans_main  = am.group(1).strip() if am else raw
                        ans_paren = am.group(2).strip() if (am and am.group(2)) else None
                        
                        tok = lambda s: re.findall(r"[a-z0-9'-]+", s)
                        
                        # 主体必须完全一致
                        if tok(ans_main) != tok(target_main):
                            return False
                        
                        # 括号可以省略
                        if ans_paren is None:
                            return True
                        
                        # 目标没有括号，用户却填了 → 拒绝
                        if target_paren is None:
                            return False
                        
                        # ── 数字类括号：智能验证 ──
                        t_num = re.search(r'\d+', target_paren)
                        a_num = re.search(r'\d+', ans_paren)
                        if t_num and a_num:
                            tn, an = int(t_num.group()), int(a_num.group())
                            if tn != an:          # 数字本身必须相同
                                return False
                            if re.fullmatch(r'\d+', ans_paren):   # 只填数字，无后缀 → 接受
                                return True
                            # 填了序数后缀 → 必须正确
                            def _ordinal(n):
                                if 11 <= n % 100 <= 13: return 'th'
                                return {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')
                            m = re.fullmatch(r'(\d+)(st|nd|rd|th)', ans_paren)
                            if m:
                                return m.group(2) == _ordinal(an)
                            return tok(ans_paren) == tok(target_paren)   # 兜底
                        
                        # 非数字括号：token 比较
                        return tok(ans_paren) == tok(target_paren)

                    def force_record_sp():
                        raw_ans = vk_state['text'].lower() if vk_state['text'] else ""
                        if not raw_ans.strip(): return False
                        is_c = check_spelling_smart(raw_ans, word)
                        state.user_answers[state.current_q_index] = {
                            "word": word, "mode": "spelling", "q": meaning_str, "ans": raw_ans.strip(),
                            "correct": is_c, "score_val": 1.0 if is_c else 0.0, "needs_manual": False, "expected": [word]
                        }
                        return True
                    env.force_record_current = force_record_sp

                    async def check_sp():
                        if state.is_submitting: return
                        state.is_submitting = True
                        raw_ans = vk_state['text'].lower() if vk_state['text'] else ""
                        is_c = check_spelling_smart(raw_ans, word)
                        
                        if getattr(state, 'allow_backward', True): card.classes('shake-anim')
                        else: card.classes('success-bg shake-anim') if is_c else card.classes('manual-bg shake-anim')
                        
                        await asyncio.sleep(0.5); record_and_next(is_c, "spelling", meaning_str, raw_ans.strip(), False, [word])

                    update_disp(); render_kb()

                elif current_mode == 'pos':
                    ui.label(word).classes('text-[4.5dvh] font-bold mb-[1dvh]')
                    correct_pos = [k.lower() for k in meta.keys() if k.lower() not in ["单词", "_uid", "source_book", "_ask_pos", "_test_mode"]]
                    is_multi = len(correct_pos) > 1
                    ui.label('多选题 (漏选得部分分，错选不得分)' if is_multi else '单选题').classes('text-[1.8dvh] text-yellow-400 mb-[2dvh]')
                    
                    opts = [o.lower() for o in set(list(db.pos_cache) + correct_pos)]
                    random.shuffle(opts)
                    if len(opts) > 6:
                        extra_needed = max(0, 6 - len(correct_pos))
                        distractors = random.sample([o for o in opts if o not in correct_pos], extra_needed)
                        opts = correct_pos + distractors; random.shuffle(opts)
                    
                    selected_opts = set([s.lower() for s in prev_ans.split(",")]) if prev_ans else set()
                    selected_opts.discard("未选择"); selected_opts.discard("")
                    btn_dict = {}
                    
                    def toggle_opt(p_val, btn_obj):
                        if p_val in selected_opts: selected_opts.remove(p_val); btn_obj.props('color=grey-7')
                        else:
                            if not is_multi:
                                selected_opts.clear()
                                for b in btn_dict.values(): b.props('color=grey-7')
                            selected_opts.add(p_val); btn_obj.props('color=primary')

                    pos_scroll = ui.scroll_area().classes('w-full flex-1 max-h-[30dvh]')
                    with pos_scroll, ui.row().classes('w-full justify-center gap-[2vw]'):
                        for p in opts:
                            p_lower = p.lower()
                            btn = ui.button('').classes('w-[38vw] py-[1.5dvh]').props('no-caps')
                            with btn: ui.label(p_lower).style('text-transform: lowercase !important; font-size: 2dvh; letter-spacing: 0.05em;')
                            btn.props('color=primary') if p_lower in selected_opts else btn.props('color=grey-7')
                            btn.on('click', lambda e, p_val=p_lower, b=btn: toggle_opt(p_val, b)); btn_dict[p_lower] = btn

                    def force_record_pos_fn():
                        if not selected_opts: return False
                        ans_str = ",".join(selected_opts)
                        wrong_count = len(selected_opts - set(correct_pos))
                        correct_count = len(selected_opts.intersection(correct_pos))
                        score_val = 0.0 if (wrong_count > 0 or correct_count == 0) else (correct_count / len(correct_pos))
                        is_c = (score_val == 1.0)
                        state.user_answers[state.current_q_index] = {
                            "word": word, "mode": "pos", "q": word, "ans": ans_str,
                            "correct": is_c, "score_val": score_val, "needs_manual": False, "expected": correct_pos
                        }
                        return True
                    env.force_record_current = force_record_pos_fn
                            
                    async def submit_pos():
                        if state.is_submitting: return
                        state.is_submitting = True
                        wrong_count = len(selected_opts - set(correct_pos))
                        correct_count = len(selected_opts.intersection(correct_pos))
                        score_val = 0.0 if (wrong_count > 0 or correct_count == 0) else (correct_count / len(correct_pos))
                        is_c = (score_val == 1.0)
                            
                        if getattr(state, 'allow_backward', True): card.classes('shake-anim')
                        else: card.classes('success-bg shake-anim') if is_c else card.classes('manual-bg shake-anim')
                            
                        await asyncio.sleep(0.5)
                        ans_str = ",".join(selected_opts) if selected_opts else "未选择"
                        record_and_next(is_c, "pos", word, ans_str, False, correct_pos, score_val)
                        
                    ui.button('确定', on_click=submit_pos).classes('w-[60vw] mt-[2dvh] bg-blue-500 rounded-[1.5dvh] py-[1.5dvh] text-[2.2dvh] font-bold')

                elif current_mode == 'translation':
                    clean_sel_pos = str(sel_pos).strip().lower() if sel_pos else ""
                    pos_display = f" ({clean_sel_pos})" if clean_sel_pos and clean_sel_pos != "释义" else ""
                    q_str = f"{word}{pos_display}"
                    valid = [m.strip() for m in re.split(r'[,，;；/|]', meaning_str) if m.strip()]
                    ui.label(q_str).classes('text-[3.5dvh] font-bold mb-[5dvh] text-center w-full')
                    
                    inp = ui.input(value=prev_ans).classes('mobile-input w-full transition-all duration-300').props('inputmode="text" autocomplete="off" spellcheck="false" data-lpignore="true"')
                    inp.on('focus', lambda: card.classes('view-shift')); inp.on('blur', lambda: card.classes(remove='view-shift'))

                    def force_record_tr_fn():
                        ans = inp.value.strip() if inp.value else ""
                        if not ans: return False
                        is_c = ans in valid
                        state.user_answers[state.current_q_index] = {
                            "word": word, "mode": "translation", "q": q_str, "ans": ans,
                            "correct": is_c, "score_val": 1.0 if is_c else 0.0, "needs_manual": not is_c, "expected": valid
                        }
                        return True
                    env.force_record_current = force_record_tr_fn
                    
                    async def check_tr():
                        if state.is_submitting: return
                        state.is_submitting = True
                        ans = inp.value.strip() if inp.value else ""
                        is_c = ans in valid
                        
                        if getattr(state, 'allow_backward', True): card.classes('shake-anim')
                        else: card.classes('success-bg shake-anim') if is_c else card.classes('manual-bg shake-anim')
                        
                        await asyncio.sleep(0.5); record_and_next(is_c, "translation", q_str, ans, not is_c, valid)
                        
                    ui.button('确定', on_click=check_tr).classes('w-[60vw] mt-[4dvh] bg-blue-500 rounded-[1.5dvh] py-[1.5dvh] text-[2.2dvh] font-bold shadow-[0_1dvh_2dvh_rgba(0,0,0,0.3)]')
                    inp.on('keydown.enter', check_tr)

        def action_prev():
            if getattr(state, 'allow_backward', True):
                if state.current_q_index > 0: state.current_q_index -= 1; load_question()
            else:
                env.nav_state.prev_clicks += 1
                if env.nav_state.prev_clicks >= 2:
                    env.nav_state.prev_clicks = 0
                    def do_jump():
                        with ui.dialog() as jd, ui.card().classes('glass-card p-[4vw] w-[80vw]'):
                            ui.label('上帝跳转 (解除锁定)').classes('text-[2.5dvh] font-bold mb-[2dvh] text-purple-400')
                            j_inp = ui.number('题号', value=state.current_q_index+1, min=1, max=len(state.test_queue)).classes('w-full mb-[2dvh]')
                            def confirm_jump():
                                idx = int(j_inp.value) - 1
                                if 0 <= idx < len(state.test_queue): state.current_q_index = idx; jd.close(); load_question()
                            ui.button('确认空降', on_click=confirm_jump).classes('w-full bg-purple-500 py-[1dvh]')
                        jd.open()
                    require_password(do_jump, allow_guest=True)
                else: ui.notify('倒退已被锁死！双击此按钮可验证密码进行空降。', type='warning')

        def action_next():
            if state.current_q_index < len(state.test_queue) - 1: state.current_q_index += 1; load_question()
            else: action_submit()

        def action_submit():
            # [累计用时] 记录最后一题的耗时（在 cleanup 前执行）
            _now_t = time.time()
            if env.word_start_time > 0 and env._last_q_idx >= 0:
                env.word_time_accum[env._last_q_idx] = env.word_time_accum.get(env._last_q_idx, 0) + (_now_t - env.word_start_time)
                env.word_start_time = 0
            cleanup_env()
            state.result_saved = False  # [新增修复] 确保任何路径进入的新测试，重置保存标志位
            state.score_log = []
            
            for i, meta in enumerate(state.test_queue):
                word = meta["单词"]
                if i in state.user_answers:
                    ans_data = state.user_answers[i]
                    state.score_log.append(ans_data)
                    # 如果是待人工判定的翻译题，不要在此时统计进数据库（防止后续 mark_all 时双重计数）
                    if not ans_data.get('needs_manual', False):
                        db.update_word_stats(state.current_account_id, word, ans_data['correct'], env.word_time_accum.get(i, 0))
                else:
                    sel_pos = meta.get('_ask_pos')
                    meaning_str = meta.get(sel_pos, "")
                    valid = [m.strip() for m in re.split(r'[,，;；/|]', meaning_str) if m.strip()]
                    current_mode = meta.get('_test_mode', state.test_mode)
                    
                    clean_sel_pos = str(sel_pos).strip().lower() if sel_pos else ""
                    pos_display = f" ({clean_sel_pos})" if clean_sel_pos and clean_sel_pos != "释义" else ""
                    
                    q_str = f"{word}{pos_display}" if current_mode == 'translation' else (meaning_str if current_mode == 'spelling' else word)
                    expected = [word] if current_mode == 'spelling' else ([clean_sel_pos] if current_mode == 'pos' else valid)
                    
                    state.score_log.append({
                        "word": word, "mode": current_mode, "q": q_str, "ans": "跳过/未作答",
                        "correct": False, "score_val": 0.0, "needs_manual": False, "expected": expected
                    })
                    db.update_word_stats(state.current_account_id, word, False, env.word_time_accum.get(i, 0))
            
            # 统一在这此处交卷时执行一次写盘，大幅减少高频 I/O 卡顿
            db.save_data()
                        
            app.storage.user['dictation_state'] = None 
            change_view('interim_report') 

        with ui.row().classes('w-full justify-between mt-[2dvh] px-[2vw]'):
            btn_prev = ui.button('上一题', icon='arrow_back' if getattr(state, 'allow_backward', True) else 'lock', on_click=action_prev)
            btn_prev.classes('bg-blue-500' if getattr(state, 'allow_backward', True) else 'bg-gray-700 text-gray-400').classes('rounded-[1.5dvh]')
            ui.button('跳过', icon='skip_next', on_click=action_next).classes('bg-gray-500 rounded-[1.5dvh]')
            ui.button('交卷', icon='done_all', on_click=action_submit).classes('bg-red-500 rounded-[1.5dvh]')

        def check_tick():
            try:
                if not env.active or state.is_submitting: return
                state.tot_left -= 1; state.q_time_left -= 1
                pct = state.q_time_left / getattr(state, 'per_q_time', 20.0)
                color_class = 'text-red-500' if state.q_time_left < 0 else ('text-yellow-400' if pct <= 0.3 else 'text-green-400')
                
                lbl_tot_timer.set_text(f'交卷倒计时: {int(state.tot_left)}s')
                lbl_q_timer.set_text(f'本题剩余: {int(state.q_time_left)}s')
                lbl_q_timer.classes(remove='text-green-400 text-yellow-400 text-red-500', add=color_class)
                
                hint_delay = acc_settings.get('hint_delay', 5)
                if getattr(state, 'allow_hint', False) and state.q_time_left <= state.per_q_time - hint_delay and not env.hint_enabled and getattr(env, 'hint_btn', None):
                    env.hint_enabled = True; env.hint_btn.enable(); env.hint_btn.classes(remove='text-gray-500', add='text-yellow-400')
                
                if state.tot_left <= 0:
                    env.active = False
                    ui.notify('总时间耗尽！系统已强制交卷。', type='negative', timeout=3000)
                    if env.force_record_current: env.force_record_current()
                    action_submit()
                elif -1 < state.q_time_left <= 0:
                    ui.notify('该题作答建议时限已过，请尽快确认或跳过！', type='warning', position='top')
                    
                answered_count = len(state.user_answers)
                if answered_count > 0:
                    elapsed = state.total_time - state.tot_left
                    est_total = (elapsed / answered_count) * len(state.test_queue)
                    if est_total > 1.2 * state.total_time:
                        current_t = time.time()
                        if current_t - env.last_speed_warn > 15:
                            ui.notify('配速过慢！预计总用时将超限，请加快速度！', type='warning', position='bottom')
                            env.last_speed_warn = current_t
            except RuntimeError: pass 
                        
        env.timer_obj = ui.timer(1.0, check_tick)
        load_question()


def render_interim_report() -> None:
    total = len(state.score_log)
    auto_correct = sum(1 for l in state.score_log if l['correct'])
    needs_manual = sum(1 for l in state.score_log if l['needs_manual'])
    used_hints = len(getattr(state, 'used_hints', set()))
    
    with ui.column().classes('w-full h-full items-center justify-center p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)]'):
        ui.label('听写汇报').classes('text-[4dvh] font-bold mb-[3dvh] text-blue-400')
        with ui.card().classes('glass-card w-[80vw] p-[6vw] mb-[4dvh] flex flex-col gap-[2dvh]'):
            ui.label(f'总题目数: {total}').classes('text-[2.5dvh] font-bold text-white')
            ui.label(f'自动判对: {auto_correct}').classes('text-[2.5dvh] text-green-400')
            ui.label(f'提示使用: {used_hints} 次').classes('text-[2.5dvh] text-gray-400')
            if needs_manual > 0: ui.label(f'待人工判定: {needs_manual}').classes('text-[2.8dvh] font-bold text-yellow-400 mt-[2dvh]')
            else: ui.label('所有题目已自动批改完毕！').classes('text-[2.2dvh] text-blue-300 mt-[2dvh]')

        if needs_manual > 0:
            ui.button('进行人工判定 (需验密)', icon='admin_panel_settings', on_click=lambda: require_password(lambda: change_view('manual_grade'))).classes('w-[80vw] py-[2dvh] bg-yellow-600 text-[2.2dvh] font-bold rounded-[2dvh]')
        else:
            ui.button('查看最终成绩', icon='analytics', on_click=lambda: change_view('results')).classes('w-[80vw] py-[2dvh] bg-blue-500 text-[2.2dvh] font-bold rounded-[2dvh]')

def render_manual_grade() -> None:
    with ui.column().classes('w-full h-full p-[5vw] pt-[var(--safe-top)] pb-[var(--safe-bottom)]'):
        ui.label('人工判定').classes('text-[3dvh] font-bold text-yellow-400 mb-[1dvh]')
        def mark_all(is_c: bool):
            for l in state.score_log:
                if l['needs_manual']:
                    l['correct'], l['score_val'], l['needs_manual'] = is_c, (1.0 if is_c else 0.0), False
                    # [修复] 在统一交卷阶段这部分没有算入 total，现在进行算入补全
                    db.update_word_stats(state.current_account_id, l['word'], is_c)
            change_view('results')
            
        with ui.row().classes('w-full justify-end gap-[2vw] mb-[2dvh]'):
            ui.button('剩余全错', on_click=lambda: mark_all(False)).classes('bg-red-500 py-[0.5dvh]')
            ui.button('剩余全对', on_click=lambda: mark_all(True)).classes('bg-green-500 py-[0.5dvh]')

        scroll = ui.scroll_area().classes('w-full flex-1')
        with scroll:
            for item in state.score_log:
                if not item.get('needs_manual', False): continue
                with ui.card().classes('glass-card w-full mb-[2dvh]'):
                    ui.label(f"[{item.get('mode', '未知')}] {item['q']}").classes('font-bold text-blue-300')
                    ui.label(f"你的输入: {item['ans']}").classes('text-red-300')
                    ui.label(f"标准释义: {', '.join(item['expected'])}").classes('text-gray-400')
                    
                    with ui.row().classes('w-full justify-center mt-[2dvh]'):
                        btn_w = ui.button(icon='close').props('color=negative round size=lg').classes('mx-[2vw]')
                        btn_r = ui.button(icon='check').props('color=positive round size=lg').classes('mx-[2vw]')
                        
                        def mark(it, is_c, bw, br):
                            it['correct'], it['score_val'], it['needs_manual'] = is_c, (1.0 if is_c else 0.0), False
                            # [修复] 手动计入一次统计数据
                            db.update_word_stats(state.current_account_id, it['word'], is_c)
                            bw.disable(); br.disable()
                            bw.props('color=grey-7'); br.props('color=grey-7')
                            br.props('color=positive') if is_c else bw.props('color=negative')
                            if not any(l['needs_manual'] for l in state.score_log): 
                                ui.timer(0.5, lambda: change_view('results'), once=True)
                                
                        btn_w.on_click(lambda it=item, w=btn_w, r=btn_r: mark(it, False, w, r))
                        btn_r.on_click(lambda it=item, w=btn_w, r=btn_r: mark(it, True, w, r))

def render_results() -> None:
    total = len(state.score_log)
    total_score_val = sum(l.get('score_val', 1.0 if l.get('correct') else 0.0) for l in state.score_log)
    score = int((total_score_val / total) * 100) if total > 0 else 0
    used_hints = len(getattr(state, 'used_hints', set()))
    
    current_acc = db.get_acc(state.current_account_id)
    
    # [修复] 增加标志位，防止用户通过前进/后退/异常重载等方式重复把当前数据写入历史导致历史数据永久脏乱
    if not getattr(state, 'result_saved', False):
        state.result_saved = True
        current_acc.setdefault('history', []).append({
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "mode": state.test_mode, "score": score, "total": total, 
            "correct": total_score_val, "score_val": total_score_val,
            "used_hints": used_hints, "status": "已完成", "details": state.score_log
        })
        db.save_data()
    
    with ui.column().classes('w-full h-full items-center justify-center p-[5vw]'):
        ui.label('测试完成').classes('text-[4dvh] font-bold mb-[3dvh]')
        color = "text-green-400" if score >= 80 else "text-red-400"
        ui.label(f"{score}分").classes(f'text-[8dvh] font-bold {color} mb-[1dvh]')
        ui.label(f"使用提示: {used_hints}次").classes('text-[2dvh] text-gray-400 mb-[4dvh]')
        
        def try_again():
            state.test_queue = state.selected_words.copy()
            random.shuffle(state.test_queue)
            state.current_q_index = 0
            state.user_answers = {}
            state.score_log = []
            state.used_hints = set()
            state.result_saved = False # [重置]
            state.tot_left = state.total_time 
            change_view('select_mode') 
            
        ui.button('重新配置题型', on_click=try_again).classes('w-[80vw] py-[2dvh] bg-green-500 text-[2.5dvh] rounded-[2dvh] mb-[2dvh] font-bold')
        ui.button('返回主页', on_click=lambda: change_view('home')).classes('w-[80vw] py-[2dvh] bg-blue-500 text-[2.5dvh] rounded-[2dvh]')

@ui.page('/')
def index_page() -> None:
    state.auth_dialog_open = False
    state.is_submitting = False
    ui.timer(20.0, lambda: None)
    
    # [设备记忆] 通过浏览器持久化的 device_id 自动还原上次账户
    try:
        # 若浏览器尚无 device_id，则生成一个 UUID 并写入
        import uuid as _uuid_mod
        dev_id = app.storage.browser.get('device_id', '')
        if not dev_id:
            dev_id = str(_uuid_mod.uuid4())
            app.storage.browser['device_id'] = dev_id
        # 从 DB 中查找该设备上次登录的账户
        device_map = db.global_settings.setdefault('device_accounts', {})
        last_acc_id = device_map.get(dev_id, '')
        if last_acc_id and last_acc_id in db.accounts and last_acc_id != state.current_account_id:
            cid_pre = ui.context.client.id
            old_aid = state.current_account_id
            _account_online.get(old_aid, set()).discard(cid_pre)
            state.current_account_id = last_acc_id
            _account_online.setdefault(last_acc_id, set()).add(cid_pre)
    except Exception:
        pass
    
    cid = ui.context.client.id
    _client_containers[cid] = ui.element('div').classes('w-full h-[100dvh] absolute top-0 left-0')
    render_view()

from fastapi import Response
@app.get('/keepalive_heartbeat')
def keep_alive_endpoint():
    return Response(content=b'0'*1024, media_type='application/octet-stream')

import socket
import signal

async def on_startup():
    if 'com.termux' in os.environ.get('PREFIX', ''):
        try: subprocess.run(['termux-wake-lock'], check=False, capture_output=True); print("\n[+] 自定义后台保活已启动。")
        except Exception: pass
        
    async def auto_shutdown():
        await asyncio.sleep(3600)  
        print("\n[*] ⏱️ 运行已达1小时，为防止后台端口持续占用，系统正在自动保存并关闭...")
        db.save_data()
        os.kill(os.getpid(), signal.SIGINT) 
        
    asyncio.create_task(auto_shutdown())

def on_shutdown():
    print("\n[*] 正在执行安全退出清理程序...")
    try: db.save_data(); print("[+] 持久化数据已安全保存。")
    except Exception as e: print(f"[!] 保存异常: {e}")
    if 'com.termux' in os.environ.get('PREFIX', ''):
        try: subprocess.run(['termux-wake-unlock'], check=False, capture_output=True); print("[-] 唤醒锁已释放。")
        except Exception: pass

app.on_startup(on_startup)
app.on_shutdown(on_shutdown)

def start_server():
    global BIND_PORT
    import socket
    import sys
    import os
    import subprocess
    import time

    if 'DICTATION_NEW_PORT' in os.environ:
        BIND_PORT = int(os.environ['DICTATION_NEW_PORT'])

    print("\n" + "="*50)
    print(f"[*] 🔍 正在执行系统预检: 检查端口 {BIND_PORT} 占用状态...")
    
    def check_port(port):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                s.bind((BIND_HOST, port))
                return False 
            except OSError:
                return True  

    port_in_use = check_port(BIND_PORT)
    
    if not port_in_use:
        print(f"[+] 诊断报告: 端口 {BIND_PORT} 绑定测试通过，网络层处于空闲状态。")
    else:
        print(f"[-] 诊断报告: 端口 {BIND_PORT} 测试失败，发现被占用。")
        print(f"[*] 🛡️ 尝试越权: 正在呼叫 Root 权限准备跨进程清理...")
        try:
            chk = subprocess.run(['su', '-c', 'id'], capture_output=True, text=True, timeout=3)
            if 'uid=0' in chk.stdout:
                print(f"[+] 🗡️ 权限获取成功！正在强制绞杀霸占 {BIND_PORT} 端口的僵尸进程...")
                
                termux_bin = "/data/data/com.termux/files/usr/bin"
                kill_cmd = f"pids=$({termux_bin}/lsof -t -i:{BIND_PORT} 2>/dev/null); if [ -n \"$pids\" ]; then kill -9 $pids; fi"
                
                subprocess.run(['su', '-c', kill_cmd], capture_output=True, text=True)
                
                time.sleep(1)
                
                if not check_port(BIND_PORT):
                    port_in_use = False
                    print(f"[+] 🧹 战果确认: 清理完成！端口 {BIND_PORT} 已被成功夺回。")
                else:
                    print(f"[-] ⚠️ 击杀完毕，但系统底层仍死锁该端口 (可能处于不可中断的睡眠状态或进程伪装)。")
            else:
                print("[-] ❌ 未获得 Root 授权或已拒绝，无法执行强制清理操作。")
        except Exception as e:
            print(f"[-] ❌ 呼叫 Root 权限时发生意外: {e}")

    print("="*50 + "\n")

    if port_in_use:
        print(f"[!] 🚨 警告：端口 {BIND_PORT} 依然不可用。")
        try:
            user_input = input(f"    👉 请输入新端口号 (直接回车将自动顺延至 {BIND_PORT + 1}): ").strip()
            new_port = int(user_input) if user_input.isdigit() else BIND_PORT + 1
            os.environ['DICTATION_NEW_PORT'] = str(new_port)
            print(f"[*] 🔄 正在注入新端口 {new_port} 并全面重启进程...")
            os.execv(sys.executable, [sys.executable] + sys.argv)
        except (EOFError, KeyboardInterrupt):
            print("\n[+] 用户已取消启动。")
            return

    try:
        print(f"[*] 🚀 准备就绪，正在通过核心引擎启动服务 (指定端口: {BIND_PORT})...")
        ui.run(host=BIND_HOST, port=BIND_PORT, title="听写系统", dark=True, reload=False, storage_secret=STORAGE_SECRET)
    except SystemExit as e:
        print(f"\n[!] 💥 核心服务意外崩溃并强制退出了！(系统退出码: {e})")
        print(f"[*] 诊断分析: 底层 Uvicorn 启动阶段遭遇了隐形冲突或死锁。")
        try:
            user_input = input(f"    👉 是否切换端口并重试？请输入新端口号 (直接回车顺延至 {BIND_PORT + 1}): ").strip()
            new_port = int(user_input) if user_input.isdigit() else BIND_PORT + 1
            os.environ['DICTATION_NEW_PORT'] = str(new_port)
            print(f"[*] 🔄 正在注入新端口 {new_port} 并全面重启进程...")
            os.execv(sys.executable, [sys.executable] + sys.argv)
        except (EOFError, KeyboardInterrupt):
            print("\n[+] 已放弃重启，退出程序。")
            return
    except KeyboardInterrupt: pass
    except Exception as e:
        if 'CancelledError' not in str(type(e)): raise

if __name__ in {"__main__", "__mp_main__"}:
    start_server()

# ==========================================
# 动态持久化数据仓 (纯明文 JSON)
# ==========================================
DATA_STORE_JSON = '''
{
  "vocab": {
    "小学": {},
    "小学/五年级": {},
    "小学/五年级/下册": {
      "Unit 1": {
        "word_01": {"单词": "eat breakfast", "v.": "吃早饭"},
        "word_02": {"单词": "have ... class", "v.": "上……课"},
        "word_03": {"单词": "play sports", "v.": "进行体育运动"},
        "word_04": {"单词": "exercise", "n.": "活动；运动", "v.": "活动；运动"},
        "word_05": {"单词": "do morning exercises", "v.": "做早操"},
        "word_06": {"单词": "eat dinner", "v.": "吃晚饭"},
        "word_07": {"单词": "clean my room", "v.": "打扫我的房间"},
        "word_08": {"单词": "go for a walk", "v.": "散步"},
        "word_09": {"单词": "go shopping", "v.": "去买东西；购物"},
        "word_10": {"单词": "take", "v.": "学习；上（课）"},
        "word_11": {"单词": "dancing", "n.": "跳舞；舞蹈", "v.": "跳舞；舞蹈"},
        "word_12": {"单词": "take a dancing class", "v.": "上舞蹈课"},
        "word_13": {"单词": "when", "adv.": "什么时候；何时", "conj.": "什么时候；何时"},
        "word_14": {"单词": "after", "prep.": "在（时间）后", "adv.": "在（时间）后"},
        "word_15": {"单词": "start", "v.": "开始", "n.": "开始"},
        "word_16": {"单词": "usually", "adv.": "通常地；惯常地"},
        "word_17": {"单词": "Spain", "n.": "西班牙"},
        "word_18": {"单词": "late", "adj.": "晚；迟", "adv.": "晚；迟"},
        "word_19": {"单词": "a.m.", "n.": "午前；上午"},
        "word_20": {"单词": "p.m.", "n.": "午后；下午"},
        "word_21": {"单词": "why", "adv.": "为什么", "conj.": "为什么"},
        "word_22": {"单词": "shop", "v.": "去买东西；购物", "n.": "去买东西；购物"},
        "word_23": {"单词": "work", "v.": "工作", "n.": "工作"},
        "word_24": {"单词": "last", "adj.": "上一个的；刚过去的", "adv.": "上一个的；刚过去的", "v.": "上一个的；刚过去的"},
        "word_25": {"单词": "sound", "v.": "听起来好像", "n.": "听起来好像"},
        "word_26": {"单词": "also", "adv.": "还；也"},
        "word_27": {"单词": "busy", "adj.": "忙的"},
        "word_28": {"单词": "need", "v.": "需要", "n.": "需要"},
        "word_29": {"单词": "play", "n.": "戏剧；剧本"},
        "word_30": {"单词": "letter", "n.": "信"},
        "word_31": {"单词": "live", "v.": "居住"},
        "word_32": {"单词": "island", "n.": "岛"},
        "word_33": {"单词": "always", "adv.": "总是；一直"},
        "word_34": {"单词": "cave", "n.": "山洞；洞穴"},
        "word_35": {"单词": "go swimming", "v.": "去游泳"},
        "word_36": {"单词": "win", "v.": "获胜"}
      },
      "Unit 2": {
        "word_01": {"单词": "spring", "n.": "春天"},
        "word_02": {"单词": "summer", "n.": "夏天"},
        "word_03": {"单词": "autumn", "n.": "秋天"},
        "word_04": {"单词": "winter", "n.": "冬天"},
        "word_05": {"单词": "season", "n.": "季节"},
        "word_06": {"单词": "picnic", "n.": "野餐", "v.": "野餐"},
        "word_07": {"单词": "go on a picnic", "v.": "去野餐"},
        "word_08": {"单词": "pick", "v.": "摘；采集"},
        "word_09": {"单词": "pick apples", "v.": "摘苹果"},
        "word_10": {"单词": "snowman", "n.": "雪人"},
        "word_11": {"单词": "make a snowman", "v.": "堆雪人"},
        "word_12": {"单词": "go swimming", "v.": "去游泳"},
        "word_13": {"单词": "which", "adj.": "哪一个", "pron.": "哪一个"},
        "word_14": {"单词": "best", "adv.": "最，最高程度地", "adj.": "最，最高程度地"},
        "word_15": {"单词": "snow", "n.": "雪", "v.": "雪"},
        "word_16": {"单词": "good job", "interj.": "做得好"},
        "word_17": {"单词": "because", "conj.": "因为"},
        "word_18": {"单词": "vacation", "n.": "假期"},
        "word_19": {"单词": "all", "adj.": "全；完全", "adv.": "全；完全", "pron.": "全；完全"},
        "word_20": {"单词": "pink", "n.": "粉色；粉色的", "adj.": "粉色；粉色的"},
        "word_21": {"单词": "lovely", "adj.": "可爱的；美丽的"},
        "word_22": {"单词": "leaf", "n.": "叶子"},
        "word_23": {"单词": "fall", "v.": "落下；【美】秋天", "n.": "落下；【美】秋天"},
        "word_24": {"单词": "paint", "v.": "用颜料绘画", "n.": "用颜料绘画"}
      }
    },
    "初中": {},
    "高中": {},
    "高中/必修": {},
    "高中/必修/必修2": {
      "Unit 1 Cultural Heritage": {
        "w1_001": {"单词": "heritage", "n.": "遗产（指国家或社会长期形成的语言、传统、建筑等）"},
        "w1_002": {"单词": "creatively", "adv.": "创造性地；有创造力地"},
        "w1_003": {"单词": "creative", "adj.": "创造性的；有创造力的；有才华的"},
        "w1_004": {"单词": "temple", "n.": "庙；寺；神殿"},
        "w1_005": {"单词": "relic", "n.": "遗物；遗迹；纪念物"},
        "w1_006": {"单词": "mount", "n.": "山峰；山", "v.(vt.)": "登上；骑上", "v.(vi.)": "增加"},
        "w1_007": {"单词": "former", "adj.": "以前的；（两者中）前者的"},
        "w1_008": {"单词": "clue", "n.": "线索；提示"},
        "w1_009": {"单词": "preserve", "v.(vt.)": "保存；保护；维持", "n.": "保护区"},
        "w1_010": {"单词": "promote", "v.(vt.)": "促进；提升；推销；晋升"},
        "w1_011": {"单词": "cypress", "n.": "柏树"},
        "w1_012": {"单词": "app", "n.": "应用程序；应用软件"},
        "w1_013": {"单词": "application", "n.": "申请（表）；用途；运用；应用（程序）"},
        "w1_014": {"单词": "take part in", "释义": "参与；参加"},
        "w1_015": {"单词": "give way to", "释义": "让步；屈服"},
        "w1_016": {"单词": "balance", "n.": "平衡；均匀", "v.(vt.)": "使平衡"},
        "w1_017": {"单词": "keep balance", "释义": "保持平衡"},
        "w1_018": {"单词": "lead to", "释义": "导致；造成（后果）"},
        "w1_019": {"单词": "dam", "n.": "水坝；拦河坝"},
        "w1_020": {"单词": "proposal", "n.": "提议；建议"},
        "w1_021": {"单词": "make a proposal", "释义": "提出建议"},
        "w1_022": {"单词": "protest", "n.": "抗议", "v.(vi.)": "（公开）抗议；反对", "v.(vt.)": "（公开）抗议；反对"},
        "w1_023": {"单词": "likely", "adj.": "可能的", "adv.": "可能地"},
        "w1_024": {"单词": "turn to", "释义": "向...求助"},
        "w1_025": {"单词": "committee", "n.": "委员会"},
        "w1_026": {"单词": "establish", "v.(vt.)": "建立；创立；设立；确立"},
        "w1_027": {"单词": "limit", "n.": "限度；限制", "v.(vt.)": "限制；限定"},
        "w1_028": {"单词": "prevent", "v.(vt.)": "阻止；阻碍；阻挠"},
        "w1_029": {"单词": "prevent ... from ...", "释义": "阻止；不让...做"},
        "w1_030": {"单词": "loss", "n.": "丧失；损失；亏损"},
        "w1_031": {"单词": "contribution", "n.": "捐款；贡献；捐赠"},
        "w1_032": {"单词": "contribute", "v.(vi.)": "捐献；捐助", "v.(vt.)": "捐献；捐助"},
        "w1_033": {"单词": "department", "n.": "部；局；处；系"},
        "w1_034": {"单词": "fund", "n.": "基金；专款"},
        "w1_035": {"单词": "within", "prep.": "在（某段时间、距离或范围）之内", "adv.": "在内部"},
        "w1_036": {"单词": "investigate", "v.(vi.)": "调查；研究", "v.(vt.)": "调查；研究"},
        "w1_037": {"单词": "issue", "n.": "重要议题；争论的问题", "v.(vt.)": "宣布；公布"},
        "w1_038": {"单词": "conduct", "n.": "行为；举止；管理方法", "v.(vt.)": "组织；安排；带领"},
        "w1_039": {"单词": "document", "n.": "文件；公文；（计算机）文档", "v.(vt.)": "记录；记载（详情）"},
        "w1_040": {"单词": "donate", "v.(vt.)": "（尤指向慈善机构）捐赠；赠送"},
        "w1_041": {"单词": "donate ... to ...", "释义": "向...捐赠..."},
        "w1_042": {"单词": "disappear", "v.(vi.)": "消失；灭绝；消亡"},
        "w1_043": {"单词": "attempt", "n.": "企图；试图；尝试", "v.(vt.)": "企图；试图；尝试"},
        "w1_044": {"单词": "make sure", "释义": "确保；设法保证"},
        "w1_045": {"单词": "worthwhile", "adj.": "值得做的；值得花时间的"},
        "w1_046": {"单词": "download", "v.(vt.)": "下载", "n.": "已下载的数据资料"},
        "w1_047": {"单词": "republic", "n.": "共和国"},
        "w1_048": {"单词": "professional", "adj.": "专业的；职业的", "n.": "专业人员；职业选手"},
        "w1_049": {"单词": "archaeologist", "n.": "考古学家"},
        "w1_050": {"单词": "entrance", "n.": "入口；进入"},
        "w1_051": {"单词": "pyramid", "n.": "金字塔；锥体"},
        "w1_052": {"单词": "process", "n.": "过程；进程；步骤", "v.(vt.)": "处理；加工"},
        "w1_053": {"单词": "overseas", "adj.": "海外的", "adv.": "在海外"},
        "w1_054": {"单词": "exit", "n.": "出口；通道；退场"},
        "w1_055": {"单词": "sheet", "n.": "一张（纸）；床单；被单"},
        "w1_056": {"单词": "parade", "n.": "游行；检阅", "v.(vi.)": "游行；检阅"},
        "w1_057": {"单词": "mirror", "n.": "镜子"},
        "w1_058": {"单词": "roof", "n.": "顶部；屋顶"},
        "w1_059": {"单词": "dragon", "n.": "龙"},
        "w1_060": {"单词": "forgive", "v.(vt.)": "原谅；宽恕", "v.(vi.)": "原谅；宽恕"},
        "w1_061": {"单词": "digital", "adj.": "数码的；数字显示的"},
        "w1_062": {"单词": "image", "n.": "形象；印象"},
        "w1_063": {"单词": "cave", "n.": "洞穴；透水洞"},
        "w1_064": {"单词": "throughout", "prep.": "各处；遍及；自始至终"},
        "w1_065": {"单词": "quality", "n.": "质量；品质；素质", "adj.": "优质的；高质量的"},
        "w1_066": {"单词": "all over the world", "释义": "世界各地"},
        "w1_067": {"单词": "tradition", "n.": "传统；传统的信仰或风俗"},
        "w1_068": {"单词": "further", "adv.": "较远；进一步地", "adj.": "进一步的"},
        "w1_069": {"单词": "historic", "adj.": "历史上著名（或重要）的；有史时期的"},
        "w1_070": {"单词": "opinion", "n.": "意见；想法；看法"},
        "w1_071": {"单词": "quote", "v.(vt.)": "引用"}
      },
      "Unit 2 Wildlife Protection": {
        "w2_001": {"单词": "wildlife", "n.": "野生动植物；野生生物"},
        "w2_002": {"单词": "protection", "n.": "保护；防卫"},
        "w2_003": {"单词": "wild", "adj.": "野生的；野蛮的；荒凉的"},
        "w2_004": {"单词": "habitat", "n.": "（动植物的）生活环境；栖息地"},
        "w2_005": {"单词": "threaten", "v.(vt.)": "威胁；危及"},
        "w2_006": {"单词": "decrease", "v.(vi.)": "减少；降低", "v.(vt.)": "减少；降低", "n.": "减少；下降"},
        "w2_007": {"单词": "endanger", "v.(vt.)": "使遭受危险；危害"},
        "w2_008": {"单词": "die out", "释义": "灭绝；消失"},
        "w2_009": {"单词": "loss", "n.": "丧失；损失；亏损"},
        "w2_010": {"单词": "reserve", "n.": "（动植物）保护区；储备", "v.(vt.)": "预订；保留"},
        "w2_011": {"单词": "hunt", "v.(vi.)": "打猎；猎杀；搜寻", "v.(vt.)": "打猎；猎杀；搜寻", "n.": "打猎；猎杀；搜寻"},
        "w2_012": {"单词": "zone", "n.": "地带；地区"},
        "w2_013": {"单词": "in peace", "释义": "和平地；安详地"},
        "w2_014": {"单词": "in danger", "释义": "处在危险中"},
        "w2_015": {"单词": "species", "n.": "物种"},
        "w2_016": {"单词": "shark", "n.": "鲨鱼"},
        "w2_017": {"单词": "fin", "n.": "鱼鳍"},
        "w2_018": {"单词": "on earth", "释义": "究竟；到底；在地球上"},
        "w2_019": {"单词": "target", "n.": "目标；对象；靶子", "v.(vt.)": "把...作为攻击目标"},
        "w2_020": {"单词": "catch", "v.(vt.)": "抓住；了解"},
        "w2_021": {"单词": "spring", "v.(vi.)": "跳；跃；蹦", "n.": "春天；泉水"},
        "w2_022": {"单词": "attack", "n.": "攻击；抨击", "v.(vt.)": "攻击；抨击"},
        "w2_023": {"单词": "force", "n.": "力量；军队", "v.(vt.)": "强迫；迫使"},
        "w2_024": {"单词": "moreover", "adv.": "此外；而且"},
        "w2_025": {"单词": "extinction", "n.": "灭绝；绝种"},
        "w2_026": {"单词": "authority", "n.": "官方；权威；批准"},
        "w2_027": {"单词": "dinosaur", "n.": "恐龙"},
        "w2_028": {"单词": "struggle", "v.(vi.)": "奋斗；搏斗", "n.": "难事；斗争"},
        "w2_029": {"单词": "strike", "v.(vi.)": "打；击；罢工", "v.(vt.)": "打；击"},
        "w2_030": {"单词": "rough", "adj.": "粗糙的；粗略的"},
        "w2_031": {"单词": "skin", "n.": "皮肤"},
        "w2_032": {"单词": "creature", "n.": "生物；动物"},
        "w2_033": {"单词": "emotion", "n.": "感情；情绪；激情"},
        "w2_034": {"单词": "replace", "v.(vt.)": "接替；取代；更换"},
        "w2_035": {"单词": "replacement", "n.": "替换物；代替者"},
        "w2_036": {"单词": "poster", "n.": "海报；画报"},
        "w2_037": {"单词": "illegal", "adj.": "不合法的；非法的"},
        "w2_038": {"单词": "hunter", "n.": "猎人"},
        "w2_039": {"单词": "immediately", "adv.": "立即；马上"},
        "w2_040": {"单词": "threat", "n.": "威胁；恐吓"},
        "w2_041": {"单词": "rate", "n.": "速度；比率"},
        "w2_042": {"单词": "state", "v.(vt.)": "陈述；说明", "n.": "状态；国家"},
        "w2_043": {"单词": "plain", "n.": "平原", "adj.": "清楚的；简单的"},
        "w2_044": {"单词": "make out", "释义": "看清；听清；分清"},
        "w2_045": {"单词": "observe", "v.(vt.)": "观察（到）；注视；遵守"},
        "w2_046": {"单词": "beauty", "n.": "美；美丽；美人"},
        "w2_047": {"单词": "roughly", "adv.": "粗略地；大约"},
        "w2_048": {"单词": "day and night", "释义": "日日夜夜；夜以继日"},
        "w2_049": {"单词": "attention", "n.": "注意；关注；注意力"},
        "w2_050": {"单词": "pay attention to", "释义": "注意"},
        "w2_051": {"单词": "drop", "v.(vi.)": "下降；落下", "v.(vt.)": "下降；落下", "n.": "滴；下降"},
        "w2_052": {"单词": "boundary", "n.": "边界；界限；分界线"},
        "w2_053": {"单词": "reward", "n.": "回报；奖励；报酬", "v.(vt.)": "奖励；奖赏"},
        "w2_054": {"单词": "visual", "adj.": "视觉的；视力的"}
      },
      "Unit 3 The Internet": {
        "w3_001": {"单词": "blog", "n.": "博客；网络日志"},
        "w3_002": {"单词": "blogger", "n.": "博客作者；博主"},
        "w3_003": {"单词": "engine", "n.": "发动机；引擎"},
        "w3_004": {"单词": "search engine", "n.": "搜索引擎"},
        "w3_005": {"单词": "chat", "v.(vi.)": "聊天；闲谈", "n.": "聊天；闲谈"},
        "w3_006": {"单词": "stream", "v.(vt.)": "流播（不用下载而直接播放）", "n.": "小河；溪流"},
        "w3_007": {"单词": "identity", "n.": "身份；个性"},
        "w3_008": {"单词": "convenient", "adj.": "方便的；近便的"},
        "w3_009": {"单词": "cash", "n.": "现金；钱"},
        "w3_010": {"单词": "update", "v.(vt.)": "更新；向...提供最新信息", "n.": "更新；最新消息"},
        "w3_011": {"单词": "database", "n.": "数据库；资料库"},
        "w3_012": {"单词": "software", "n.": "软件"},
        "w3_013": {"单词": "network", "n.": "网络；网状系统"},
        "w3_014": {"单词": "stuck", "adj.": "卡住的；陷入的"},
        "w3_015": {"单词": "keep ... in mind", "释义": "牢记"},
        "w3_016": {"单词": "surf", "v.(vi.)": "冲浪；浏览", "v.(vt.)": "冲浪；浏览"},
        "w3_017": {"单词": "benefit", "n.": "益处；优势", "v.(vt.)": "使受益", "v.(vi.)": "得益于"},
        "w3_018": {"单词": "distance", "n.": "距离；间距"},
        "w3_019": {"单词": "inspiring", "adj.": "鼓舞人心的；启发灵感的"},
        "w3_020": {"单词": "access", "n.": "通道；（使用、查阅的）机会", "v.(vt.)": "进入；使用"},
        "w3_021": {"单词": "charity", "n.": "慈善；慈善机构（或组织）"},
        "w3_022": {"单词": "go through", "释义": "经历；度过；通读"},
        "w3_023": {"单词": "tough", "adj.": "艰难的；严厉的"},
        "w3_024": {"单词": "province", "n.": "省"},
        "w3_025": {"单词": "conference", "n.": "会议；研讨会"},
        "w3_026": {"单词": "resident", "n.": "居民；（美国的）高级专科住院医生"},
        "w3_027": {"单词": "plus", "prep.": "加；加上", "n.": "优势；加号"},
        "w3_028": {"单词": "function", "n.": "功能；作用"},
        "w3_029": {"单词": "battery", "n.": "电池"},
        "w3_030": {"单词": "confirm", "v.(vt.)": "确认；证实"},
        "w3_031": {"单词": "press", "v.(vt.)": "按；压；敦促", "n.": "报刊；新闻界"},
        "w3_032": {"单词": "button", "n.": "按钮；纽扣"},
        "w3_033": {"单词": "file", "n.": "文件；文件夹"},
        "w3_034": {"单词": "in shape", "释义": "状况良好"},
        "w3_035": {"单词": "keep company", "释义": "陪伴；做伴"},
        "w3_036": {"单词": "track", "v.(vt.)": "跟踪；追踪", "n.": "足迹；踪迹"},
        "w3_037": {"单词": "discount", "n.": "折扣"},
        "w3_038": {"单词": "account", "n.": "账户；描述"},
        "w3_039": {"单词": "click", "v.(vi.)": "点击", "v.(vt.)": "点击", "n.": "咔哒声"},
        "w3_040": {"单词": "privacy", "n.": "隐私；私密"},
        "w3_041": {"单词": "theft", "n.": "偷窃；盗窃罪"},
        "w3_042": {"单词": "false", "adj.": "假的；错误的"},
        "w3_043": {"单词": "familiar", "adj.": "熟悉的；熟知的"}
      },
      "Unit 4 History and Traditions": {
        "w4_001": {"单词": "historic", "adj.": "历史上著名（或重要）的"},
        "w4_002": {"单词": "historical", "adj.": "（有关）历史的"},
        "w4_003": {"单词": "tradition", "n.": "传统；风俗"},
        "w4_004": {"单词": "theme", "n.": "主题；题目"},
        "w4_005": {"单词": "parade", "n.": "游行；检阅", "v.(vi.)": "游行；列队行进"},
        "w4_006": {"单词": "generation", "n.": "一代（人）"},
        "w4_007": {"单词": "customs", "n.": "海关；关税"},
        "w4_008": {"单词": "admit", "v.(vt.)": "承认；准许进入", "v.(vi.)": "承认；准许进入"},
        "w4_009": {"单词": "occur", "v.(vi.)": "发生；出现"},
        "w4_010": {"单词": "religious", "adj.": "宗教的；虔诚的"},
        "w4_011": {"单词": "bell", "n.": "钟；铃；钟声"},
        "w4_012": {"单词": "union", "n.": "联合；联盟；工会"},
        "w4_013": {"单词": "kingdom", "n.": "王国；领域"},
        "w4_014": {"单词": "consist", "v.(vi.)": "由...组成；在于"},
        "w4_015": {"单词": "consist of", "释义": "由...组成；由...构成"},
        "w4_016": {"单词": "state", "n.": "国家；政府；州；状态", "v.(vt.)": "陈述；说明"},
        "w4_017": {"单词": "powerful", "adj.": "强有力的；有权势的"},
        "w4_018": {"单词": "area", "n.": "地区；区域；面积"},
        "w4_019": {"单词": "divide", "v.(vt.)": "分；划分；分配；除以"},
        "w4_020": {"单词": "puzzle", "n.": "谜；智力游戏", "v.(vt.)": "使迷惑；使困惑"},
        "w4_021": {"单词": "belong", "v.(vi.)": "应在（某处）；适应"},
        "w4_022": {"单词": "belong to", "释义": "属于"},
        "w4_023": {"单词": "defence", "n.": "防御；保卫"},
        "w4_024": {"单词": "legal", "adj.": "法律的；合法的"},
        "w4_025": {"单词": "surround", "v.(vt.)": "包围；围绕"},
        "w4_026": {"单词": "evidence", "n.": "证据；证明"},
        "w4_027": {"单词": "achievement", "n.": "成就；成绩；达到"},
        "w4_028": {"单词": "location", "n.": "地方；地点；位置"},
        "w4_029": {"单词": "conquer", "v.(vt.)": "占领；征服；控制"},
        "w4_030": {"单词": "battle", "n.": "战役；搏斗"},
        "w4_031": {"单词": "port", "n.": "港口（城市）"},
        "w4_032": {"单词": "fascinate", "v.(vt.)": "深深吸引；迷住"},
        "w4_033": {"单词": "fascinated", "adj.": "被迷住的；被吸引的"},
        "w4_034": {"单词": "fascinating", "adj.": "极有吸引力的；迷人的"},
        "w4_035": {"单词": "keep one's eyes open", "释义": "留心；留意"},
        "w4_036": {"单词": "structure", "n.": "结构；体系；建筑物"},
        "w4_037": {"单词": "alive", "adj.": "活着的；有生气的"},
        "w4_038": {"单词": "survive", "v.(vi.)": "生存；存活", "v.(vt.)": "幸存；艰难度过"},
        "w4_039": {"单词": "master", "n.": "主人；大师", "v.(vt.)": "精通；掌握"},
        "w4_040": {"单词": "unique", "adj.": "唯一的；独特的"},
        "w4_041": {"单词": "architecture", "n.": "建筑学；建筑设计"},
        "w4_042": {"单词": "material", "n.": "材料；布料；素材"},
        "w4_043": {"单词": "earn", "v.(vt.)": "挣得；赚得；赢得"}
      },
      "Unit 5 Music": {
        "w5_001": {"单词": "music", "n.": "音乐；乐曲"},
        "w5_002": {"单词": "album", "n.": "相册；集邮册；音乐专辑"},
        "w5_003": {"单词": "classic", "adj.": "经典的；典型的", "n.": "经典著作；名著"},
        "w5_004": {"单词": "blues", "n.": "布鲁斯音乐；蓝调"},
        "w5_005": {"单词": "jazz", "n.": "爵士乐"},
        "w5_006": {"单词": "hip-hop", "n.": "嘻哈音乐；嘻哈文化"},
        "w5_007": {"单词": "rap", "n.": "说唱乐", "v.(vt.)": "敲击；急拍"},
        "w5_008": {"单词": "soul", "n.": "灵魂；心灵；灵魂乐"},
        "w5_009": {"单词": "performer", "n.": "表演者；演出者"},
        "w5_010": {"单词": "virtual", "adj.": "虚拟的；几乎的"},
        "w5_011": {"单词": "tap", "v.(vt.)": "轻叩；轻敲", "v.(vi.)": "轻叩；轻敲", "n.": "水龙头；轻叩"},
        "w5_012": {"单词": "act", "n.": "（戏的）一幕；行为", "v.(vi.)": "行动；表演"},
        "w5_013": {"单词": "talent", "n.": "天才；天资；天赋"},
        "w5_014": {"单词": "string", "n.": "细绳；线；弦"},
        "w5_015": {"单词": "audience", "n.": "观众；听众"},
        "w5_016": {"单词": "instrument", "n.": "器械；仪器；乐器"},
        "w5_017": {"单词": "stage", "n.": "舞台；阶段；时期"},
        "w5_018": {"单词": "delivery", "n.": "递送；交付；分娩"},
        "w5_019": {"单词": "common", "adj.": "普通的；常见的；共有的"},
        "w5_020": {"单词": "ordinary", "adj.": "普通的；平凡的；一般的"},
        "w5_021": {"单词": "classical", "adj.": "古典的；传统的"},
        "w5_022": {"单词": "energy", "n.": "能源；能量；精力"},
        "w5_023": {"单词": "musical", "adj.": "音乐的；有音乐天赋的", "n.": "音乐剧"},
        "w5_024": {"单词": "rhythm", "n.": "节奏；韵律"},
        "w5_025": {"单词": "beat", "n.": "节拍；拍子", "v.(vt.)": "打败；敲打", "v.(vi.)": "跳动"},
        "w5_026": {"单词": "piano", "n.": "钢琴"},
        "w5_027": {"单词": "pain", "n.": "痛苦；疼痛"},
        "w5_028": {"单词": "moreover", "adv.": "此外；而且"},
        "w5_029": {"单词": "pretend", "v.(vt.)": "假装；装扮"},
        "w5_030": {"单词": "stage fright", "释义": "怯场"},
        "w5_031": {"单词": "attach", "v.(vt.)": "系；绑；贴；附加"},
        "w5_032": {"单词": "sort", "n.": "种类；类别"},
        "w5_033": {"单词": "sort out", "释义": "整理；把...分类"},
        "w5_034": {"单词": "relief", "n.": "宽慰；轻松；解脱"},
        "w5_035": {"单词": "in relief", "释义": "如释重负"},
        "w5_036": {"单词": "burst", "v.(vi.)": "爆裂；破裂；突然猛冲", "n.": "突然增加；迸发"},
        "w5_037": {"单词": "burst into", "释义": "突然开始；爆发"},
        "w5_038": {"单词": "perform", "v.(vt.)": "做；履行；执行", "v.(vi.)": "演出；表演"},
        "w5_039": {"单词": "band", "n.": "乐队；带子"},
        "w5_040": {"单词": "studio", "n.": "演播室；工作室；录音室"},
        "w5_041": {"单词": "million", "num.": "一百万"},
        "w5_042": {"单词": "broadcast", "n.": "广播节目；电视节目", "v.(vt.)": "播送；广播", "v.(vi.)": "播送；广播"},
        "w5_043": {"单词": "relieve", "v.(vt.)": "解除；减轻；缓和"}
      }
    }
  },
  "accounts": {
    "1774875972147": {
      "name": "王钧浩",
      "history": [
        {"timestamp": "2026-03-30 21:26:40", "mode": "混合模式", "score": 80, "total": 15, "correct": 12.0, "score_val": 12.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "all", "mode": "pos", "q": "all", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adj.&adv.&pron."]},
          {"word": "summer", "mode": "translation", "q": "summer (n.)", "ans": "夏天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["夏天"]},
          {"word": "all", "mode": "spelling", "q": "全；完全", "ans": "all", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["all"]},
          {"word": "make a snowman", "mode": "translation", "q": "make a snowman (v.)", "ans": "堆雪人", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["堆雪人"]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "which", "mode": "translation", "q": "which (adj.&pron.)", "ans": "哪一个", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["哪一个"]},
          {"word": "go swimming", "mode": "pos", "q": "go swimming", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "paint", "mode": "pos", "q": "paint", "ans": "v.&n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.&n."]},
          {"word": "season", "mode": "spelling", "q": "季节", "ans": "season", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["season"]},
          {"word": "paint", "mode": "spelling", "q": "用颜料绘画", "ans": "paint", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["paint"]},
          {"word": "autumn", "mode": "spelling", "q": "秋天", "ans": "autumn", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["autumn"]},
          {"word": "because", "mode": "pos", "q": "because", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["conj."]},
          {"word": "spring", "mode": "translation", "q": "spring (n.)", "ans": "春天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["春天"]},
          {"word": "summer", "mode": "spelling", "q": "夏天", "ans": "summer", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["summer"]},
          {"word": "season", "mode": "pos", "q": "season", "ans": "adj.&adv.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n."]}
        ]},
        {"timestamp": "2026-03-31 21:35:29", "mode": "混合模式", "score": 86, "total": 15, "correct": 13.0, "score_val": 13.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "make a snowman", "mode": "pos", "q": "make a snowman", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "go on a picnic", "mode": "pos", "q": "go on a picnic", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "picnic", "mode": "translation", "q": "picnic (n.)", "ans": "野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["野餐"]},
          {"word": "which", "mode": "translation", "q": "which (adj.)", "ans": "哪一个", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["哪一个"]},
          {"word": "picnic", "mode": "pos", "q": "picnic", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["n.", "v."]},
          {"word": "snow", "mode": "pos", "q": "snow", "ans": "prep.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n.", "v."]},
          {"word": "fall", "mode": "pos", "q": "fall", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "fall", "mode": "spelling", "q": "落下；【美】秋天", "ans": "fall", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["fall"]},
          {"word": "winter", "mode": "spelling", "q": "冬天", "ans": "winter", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["winter"]},
          {"word": "fall", "mode": "translation", "q": "fall (n.)", "ans": "落下", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["落下", "【美】秋天"]},
          {"word": "vacation", "mode": "spelling", "q": "假期", "ans": "vacation", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["vacation"]},
          {"word": "leaf", "mode": "translation", "q": "leaf (n.)", "ans": "叶子", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["叶子"]},
          {"word": "paint", "mode": "translation", "q": "paint (n.)", "ans": "用颜料绘画", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["用颜料绘画"]},
          {"word": "good job", "mode": "spelling", "q": "做得好", "ans": "good job", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["good job"]},
          {"word": "go swimming", "mode": "spelling", "q": "去游泳", "ans": "go swimming", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go swimming"]}
        ]},
        {"timestamp": "2026-04-01 21:25:41", "mode": "混合模式", "score": 86, "total": 15, "correct": 13.0, "score_val": 13.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "go swimming", "mode": "translation", "q": "go swimming (v.)", "ans": "去游泳", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去游泳"]},
          {"word": "go on a picnic", "mode": "spelling", "q": "去野餐", "ans": "go on a picnic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go on a picnic"]},
          {"word": "pick", "mode": "pos", "q": "pick", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "autumn", "mode": "spelling", "q": "秋天", "ans": "autumn", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["autumn"]},
          {"word": "leaf", "mode": "spelling", "q": "叶子", "ans": "leaf", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["leaf"]},
          {"word": "vacation", "mode": "spelling", "q": "假期", "ans": "vacation", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["vacation"]},
          {"word": "good job", "mode": "translation", "q": "good job (interj.)", "ans": "做的好", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["做得好"]},
          {"word": "summer", "mode": "pos", "q": "summer", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "snowman", "mode": "pos", "q": "snowman", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "which", "mode": "translation", "q": "which (pron.)", "ans": "哪一个", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["哪一个"]},
          {"word": "vacation", "mode": "pos", "q": "vacation", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "snow", "mode": "spelling", "q": "雪", "ans": "nsnow", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["snow"]},
          {"word": "season", "mode": "pos", "q": "season", "ans": "adv.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n."]},
          {"word": "paint", "mode": "translation", "q": "paint (v.)", "ans": "用颜料绘画", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["用颜料绘画"]},
          {"word": "snowman", "mode": "translation", "q": "snowman (n.)", "ans": "雪人", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["雪人"]}
        ]},
        {"timestamp": "2026-04-02 21:36:21", "mode": "混合模式", "score": 86, "total": 15, "correct": 13.0, "score_val": 13.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "vacation", "mode": "pos", "q": "vacation", "ans": "adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n."]},
          {"word": "make a snowman", "mode": "translation", "q": "make a snowman (v.)", "ans": "堆雪人", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["堆雪人"]},
          {"word": "season", "mode": "pos", "q": "season", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "autumn", "mode": "spelling", "q": "秋天", "ans": "autumn", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["autumn"]},
          {"word": "snowman", "mode": "spelling", "q": "雪人", "ans": "snowman", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["snowman"]},
          {"word": "paint", "mode": "spelling", "q": "用颜料绘画", "ans": "paint", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["paint"]},
          {"word": "because", "mode": "translation", "q": "because (conj.)", "ans": "因为", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["因为"]},
          {"word": "good job", "mode": "translation", "q": "good job (interj.)", "ans": "做的好", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["做得好"]},
          {"word": "pink", "mode": "pos", "q": "pink", "ans": "adj.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n.", "adj."]},
          {"word": "pick", "mode": "spelling", "q": "摘；采集", "ans": "pick", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["pick"]},
          {"word": "snow", "mode": "pos", "q": "snow", "ans": "adv.,n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n.", "v."]},
          {"word": "best", "mode": "translation", "q": "best (adj.)", "ans": "最", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["最", "最高程度地"]},
          {"word": "pick", "mode": "pos", "q": "pick", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "lovely", "mode": "spelling", "q": "可爱的；美丽的", "ans": "lovely", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["lovely"]}
        ]},
        {"timestamp": "2026-04-02 21:49:02", "mode": "混合模式", "score": 90, "total": 18, "correct": 16.333333333333332, "score_val": 16.333333333333332, "used_hints": 0, "status": "已完成", "details": [
          {"word": "because", "mode": "translation", "q": "because (conj.)", "ans": "因为", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["因为"]},
          {"word": "go swimming", "mode": "spelling", "q": "去游泳", "ans": "goswimming", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["go swimming"]},
          {"word": "summer", "mode": "spelling", "q": "夏天", "ans": "summer", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["summer"]},
          {"word": "summer", "mode": "pos", "q": "summer", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "leaf", "mode": "translation", "q": "leaf (n.)", "ans": "叶子", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["叶子"]},
          {"word": "lovely", "mode": "pos", "q": "lovely", "ans": "adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj."]},
          {"word": "picnic", "mode": "translation", "q": "picnic (v.)", "ans": "野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["野餐"]},
          {"word": "all", "mode": "pos", "q": "all", "ans": "adj.", "correct": false, "score_val": 0.3333333333333333, "needs_manual": false, "expected": ["adj.", "adv.", "pron."]},
          {"word": "vacation", "mode": "pos", "q": "vacation", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "all", "mode": "spelling", "q": "全；完全", "ans": "all", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["all"]},
          {"word": "paint", "mode": "pos", "q": "paint", "ans": "v.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "vacation", "mode": "spelling", "q": "假期", "ans": "vacation", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["vacation"]},
          {"word": "go swimming", "mode": "pos", "q": "go swimming", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "picnic", "mode": "spelling", "q": "野餐", "ans": "picnic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["picnic"]},
          {"word": "lovely", "mode": "translation", "q": "lovely (adj.)", "ans": "可爱的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["可爱的", "美丽的"]},
          {"word": "pick apples", "mode": "spelling", "q": "摘苹果", "ans": "pick apples", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["pick apples"]},
          {"word": "vacation", "mode": "translation", "q": "vacation (n.)", "ans": "假期", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["假期"]},
          {"word": "pink", "mode": "translation", "q": "pink (adj.)", "ans": "粉色", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["粉色", "粉色的"]}
        ]},
        {"timestamp": "2026-04-09 21:14:48", "mode": "混合模式", "score": 0, "total": 30, "correct": 2.0, "score_val": 2.0, "used_hints": 0, "status": "中途被放弃", "details": [
          {"word": "summer", "mode": "translation", "q": "summer (n.)", "ans": "夏天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["夏天"]},
          {"word": "take a dancing class", "mode": "spelling", "q": "上舞蹈课", "ans": "take a dancing class", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["take a dancing class"]}
        ]},
        {"timestamp": "2026-04-09 21:25:02", "mode": "混合模式", "score": 83, "total": 30, "correct": 25.0, "score_val": 25.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "spring", "mode": "pos", "q": "spring", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "autumn", "mode": "pos", "q": "autumn", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "play sports", "mode": "spelling", "q": "进行体育运动", "ans": "plae shorts", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["play sports"]},
          {"word": "go swimming", "mode": "translation", "q": "go swimming (v.)", "ans": "去游泳", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去游泳"]},
          {"word": "sound", "mode": "translation", "q": "sound (n.)", "ans": "听起来好像", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["听起来好像"]},
          {"word": "island", "mode": "spelling", "q": "岛", "ans": "island", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["island"]},
          {"word": "go on a picnic", "mode": "spelling", "q": "去野餐", "ans": "go on a picnic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go on a picnic"]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "play", "mode": "spelling", "q": "戏剧；剧本", "ans": "play", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["play"]},
          {"word": "p.m.", "mode": "spelling", "q": "午后；下午", "ans": "p.m", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["p.m."]},
          {"word": "sound", "mode": "pos", "q": "sound", "ans": "v.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "need", "mode": "pos", "q": "need", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "dancing", "mode": "spelling", "q": "跳舞；舞蹈", "ans": "dancing", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["dancing"]},
          {"word": "eat breakfast", "mode": "translation", "q": "eat breakfast (v.)", "ans": "吃早饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃早饭"]},
          {"word": "last", "mode": "spelling", "q": "上一个的；刚过去的", "ans": "last", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["last"]},
          {"word": "letter", "mode": "pos", "q": "letter", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "always", "mode": "pos", "q": "always", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv."]},
          {"word": "lovely", "mode": "translation", "q": "lovely (adj.)", "ans": "可爱的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["可爱的", "美丽的"]},
          {"word": "take a dancing class", "mode": "pos", "q": "take a dancing class", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "clean my room", "mode": "translation", "q": "clean my room (v.)", "ans": "打扫我的房间", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["打扫我的房间"]},
          {"word": "Spain", "mode": "pos", "q": "Spain", "ans": "v.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n."]},
          {"word": "start", "mode": "spelling", "q": "开始", "ans": "start", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["start"]},
          {"word": "all", "mode": "translation", "q": "all (adj.)", "ans": "全", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["全", "完全"]},
          {"word": "snowman", "mode": "spelling", "q": "雪人", "ans": "snowman", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["snowman"]},
          {"word": "picnic", "mode": "translation", "q": "picnic (v.)", "ans": "野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["野餐"]},
          {"word": "busy", "mode": "spelling", "q": "忙的", "ans": "busy", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["busy"]},
          {"word": "do morning exercises", "mode": "pos", "q": "do morning exercises", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "pick", "mode": "translation", "q": "pick (v.)", "ans": "摘", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["摘", "采集"]},
          {"word": "have ... class", "mode": "pos", "q": "have ... class", "ans": "adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v."]},
          {"word": "eat dinner", "mode": "translation", "q": "eat dinner (v.)", "ans": "吃晚饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃晚饭"]}
        ]},
        {"timestamp": "2026-04-13 21:09:08", "mode": "混合模式", "score": 0, "total": 30, "correct": 3.5, "score_val": 3.5, "used_hints": 0, "status": "中途被放弃", "details": [
          {"word": "exercise", "mode": "translation", "q": "exercise (n.)", "ans": "活动", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["活动", "运动"]},
          {"word": "snow", "mode": "pos", "q": "snow", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["n.", "v."]},
          {"word": "cave", "mode": "spelling", "q": "山洞；洞穴", "ans": "cave", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["cave"]},
          {"word": "snowman", "mode": "spelling", "q": "雪人", "ans": "snowman", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["snowman"]},
          {"word": "go for a walk", "mode": "spelling", "q": "散步", "ans": "go for a wolk", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["go for a walk"]},
          {"word": "when", "mode": "pos", "q": "when", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv.", "conj."]}
        ]},
        {"timestamp": "2026-04-13 21:18:51", "mode": "混合模式", "score": 83, "total": 30, "correct": 25.0, "score_val": 25.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "cave", "mode": "spelling", "q": "山洞；洞穴", "ans": "cave", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["cave"]},
          {"word": "go on a picnic", "mode": "spelling", "q": "去野餐", "ans": "go on a picnic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go on a picnic"]},
          {"word": "last", "mode": "pos", "q": "last", "ans": "n.,adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adj.", "adv.", "v."]},
          {"word": "fall", "mode": "pos", "q": "fall", "ans": "v.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "pick", "mode": "translation", "q": "pick (v.)", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["摘", "采集"]},
          {"word": "leaf", "mode": "spelling", "q": "叶子", "ans": "leaf", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["leaf"]},
          {"word": "work", "mode": "spelling", "q": "工作", "ans": "work", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["work"]},
          {"word": "why", "mode": "translation", "q": "why (conj.)", "ans": "为什么", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["为什么"]},
          {"word": "late", "mode": "translation", "q": "late (adv.)", "ans": "晚", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["晚", "迟"]},
          {"word": "cave", "mode": "translation", "q": "cave (n.)", "ans": "山洞", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["山洞", "洞穴"]},
          {"word": "which", "mode": "translation", "q": "which (adj.)", "ans": "哪一个", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["哪一个"]},
          {"word": "last", "mode": "translation", "q": "last (v.)", "ans": "上一个的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["上一个的", "刚过去的"]},
          {"word": "snowman", "mode": "translation", "q": "snowman (n.)", "ans": "雪人", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["雪人"]},
          {"word": "play", "mode": "pos", "q": "play", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "take a dancing class", "mode": "pos", "q": "take a dancing class", "ans": "adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v."]},
          {"word": "when", "mode": "spelling", "q": "什么时候；何时", "ans": "when", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["when"]},
          {"word": "do morning exercises", "mode": "pos", "q": "do morning exercises", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "start", "mode": "translation", "q": "start (n.)", "ans": "开始", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["开始"]},
          {"word": "go swimming", "mode": "pos", "q": "go swimming", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "pick", "mode": "pos", "q": "pick", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "snow", "mode": "pos", "q": "snow", "ans": "n.,adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n.", "v."]},
          {"word": "usually", "mode": "spelling", "q": "通常地；惯常地", "ans": "usually", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["usually"]},
          {"word": "when", "mode": "pos", "q": "when", "ans": "n.,adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv.", "conj."]},
          {"word": "go for a walk", "mode": "spelling", "q": "散步", "ans": "go for a walk", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go for a walk"]},
          {"word": "eat breakfast", "mode": "translation", "q": "eat breakfast (v.)", "ans": "吃早饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃早饭"]},
          {"word": "because", "mode": "spelling", "q": "因为", "ans": "because", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["because"]},
          {"word": "pick apples", "mode": "pos", "q": "pick apples", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "a.m.", "mode": "spelling", "q": "午前；上午", "ans": "a.m", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["a.m."]},
          {"word": "best", "mode": "spelling", "q": "最，最高程度地", "ans": "best", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["best"]},
          {"word": "also", "mode": "translation", "q": "also (adv.)", "ans": "还", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["还", "也"]}
        ]},
        {"timestamp": "2026-04-13 21:30:05", "mode": "混合模式", "score": 83, "total": 30, "correct": 25.0, "score_val": 25.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "shop", "mode": "spelling", "q": "去买东西；购物", "ans": "go shopping", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["shop"]},
          {"word": "best", "mode": "spelling", "q": "最，最高程度地", "ans": "best", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["best"]},
          {"word": "winter", "mode": "translation", "q": "winter (n.)", "ans": "冬天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["冬天"]},
          {"word": "fall", "mode": "translation", "q": "fall (n.)", "ans": "落下", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["落下", "【美】秋天"]},
          {"word": "make a snowman", "mode": "translation", "q": "make a snowman (v.)", "ans": "堆雪人", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["堆雪人"]},
          {"word": "p.m.", "mode": "translation", "q": "p.m. (n.)", "ans": "午后", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["午后", "下午"]},
          {"word": "clean my room", "mode": "pos", "q": "clean my room", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "fall", "mode": "pos", "q": "fall", "ans": "v.,adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "summer", "mode": "translation", "q": "summer (n.)", "ans": "夏天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["夏天"]},
          {"word": "snow", "mode": "translation", "q": "snow (v.)", "ans": "雪", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["雪"]},
          {"word": "vacation", "mode": "spelling", "q": "假期", "ans": "vacation", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["vacation"]},
          {"word": "go swimming", "mode": "spelling", "q": "去游泳", "ans": "go swimming", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go swimming"]},
          {"word": "pink", "mode": "pos", "q": "pink", "ans": "n.,adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n.", "adj."]},
          {"word": "because", "mode": "spelling", "q": "因为", "ans": "because", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["because"]},
          {"word": "autumn", "mode": "pos", "q": "autumn", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "eat dinner", "mode": "translation", "q": "eat dinner (v.)", "ans": "吃晚饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃晚饭"]},
          {"word": "go for a walk", "mode": "pos", "q": "go for a walk", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "pick", "mode": "pos", "q": "pick", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "always", "mode": "pos", "q": "always", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv."]},
          {"word": "good job", "mode": "spelling", "q": "做得好", "ans": "good job", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["good job"]},
          {"word": "all", "mode": "spelling", "q": "全；完全", "ans": "all", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["all"]},
          {"word": "last", "mode": "spelling", "q": "上一个的；刚过去的", "ans": "last", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["last"]},
          {"word": "always", "mode": "translation", "q": "always (adv.)", "ans": "总是", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["总是", "一直"]},
          {"word": "Spain", "mode": "pos", "q": "Spain", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "all", "mode": "translation", "q": "all (adv.)", "ans": "全", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["全", "完全"]},
          {"word": "lovely", "mode": "translation", "q": "lovely (adj.)", "ans": "可爱的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["可爱的", "美丽的"]},
          {"word": "win", "mode": "pos", "q": "win", "ans": "adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v."]},
          {"word": "letter", "mode": "pos", "q": "letter", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "pick apples", "mode": "spelling", "q": "摘苹果", "ans": "pick apples", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["pick apples"]},
          {"word": "picnic", "mode": "spelling", "q": "野餐", "ans": "go on a picnic", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["picnic"]}
        ]},
        {"timestamp": "2026-04-13 21:50:03", "mode": "混合模式", "score": 86, "total": 30, "correct": 26.0, "score_val": 26.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "cave", "mode": "spelling", "q": "山洞；洞穴", "ans": "cave", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["cave"]},
          {"word": "why", "mode": "spelling", "q": "为什么", "ans": "why", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["why"]},
          {"word": "start", "mode": "spelling", "q": "开始", "ans": "start", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["start"]},
          {"word": "take", "mode": "pos", "q": "take", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v."]},
          {"word": "have ... class", "mode": "spelling", "q": "上……课", "ans": "have......class", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["have ... class"]},
          {"word": "pick", "mode": "pos", "q": "pick", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "sound", "mode": "pos", "q": "sound", "ans": "v.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "autumn", "mode": "pos", "q": "autumn", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "paint", "mode": "translation", "q": "paint (n.)", "ans": "用颜料绘画", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["用颜料绘画"]},
          {"word": "last", "mode": "spelling", "q": "上一个的；刚过去的", "ans": "last", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["last"]},
          {"word": "snow", "mode": "spelling", "q": "雪", "ans": "snow", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["snow"]},
          {"word": "which", "mode": "translation", "q": "which (adj.)", "ans": "哪一个", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["哪一个"]},
          {"word": "which", "mode": "spelling", "q": "哪一个", "ans": "which", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["which"]},
          {"word": "after", "mode": "translation", "q": "after (prep.)", "ans": "", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["在（时间）后"]},
          {"word": "usually", "mode": "translation", "q": "usually (adv.)", "ans": "通常", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["通常地", "惯常地"]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "go shopping", "mode": "pos", "q": "go shopping", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "eat dinner", "mode": "pos", "q": "eat dinner", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "always", "mode": "translation", "q": "always (adv.)", "ans": "总是", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["总是", "一直"]},
          {"word": "need", "mode": "pos", "q": "need", "ans": "adv.,n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "play", "mode": "translation", "q": "play (n.)", "ans": "戏剧", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["戏剧", "剧本"]},
          {"word": "play sports", "mode": "pos", "q": "play sports", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "letter", "mode": "pos", "q": "letter", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "do morning exercises", "mode": "spelling", "q": "做早操", "ans": "do morning exercises", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["do morning exercises"]},
          {"word": "start", "mode": "translation", "q": "start (v.)", "ans": "开始", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["开始"]},
          {"word": "eat breakfast", "mode": "spelling", "q": "吃早饭", "ans": "eat breakfast", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["eat breakfast"]},
          {"word": "season", "mode": "translation", "q": "season (n.)", "ans": "季节", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["季节"]},
          {"word": "work", "mode": "pos", "q": "work", "ans": "v.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "take a dancing class", "mode": "translation", "q": "take a dancing class (v.)", "ans": "上舞蹈课", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["上舞蹈课"]},
          {"word": "fall", "mode": "spelling", "q": "落下；【美】秋天", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["fall"]}
        ]},
        {"timestamp": "2026-04-14 21:13:55", "mode": "混合模式", "score": 86, "total": 30, "correct": 26.0, "score_val": 26.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "work", "mode": "spelling", "q": "工作", "ans": "work", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["work"]},
          {"word": "fall", "mode": "pos", "q": "fall", "ans": "v.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "pick", "mode": "pos", "q": "pick", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "pick apples", "mode": "translation", "q": "pick apples (v.)", "ans": "摘苹果", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["摘苹果"]},
          {"word": "eat breakfast", "mode": "pos", "q": "eat breakfast", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "take", "mode": "translation", "q": "take (v.)", "ans": "学习", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["学习", "上（课）"]},
          {"word": "p.m.", "mode": "translation", "q": "p.m. (n.)", "ans": "午后", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["午后", "下午"]},
          {"word": "last", "mode": "translation", "q": "last (adj.)", "ans": "上一个的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["上一个的", "刚过去的"]},
          {"word": "go swimming", "mode": "pos", "q": "go swimming", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "pink", "mode": "pos", "q": "pink", "ans": "n.,adv.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n.", "adj."]},
          {"word": "eat breakfast", "mode": "spelling", "q": "吃早饭", "ans": "eat breakfast", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["eat breakfast"]},
          {"word": "which", "mode": "spelling", "q": "哪一个", "ans": "which", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["which"]},
          {"word": "which", "mode": "translation", "q": "which (pron.)", "ans": "哪一个", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["哪一个"]},
          {"word": "play", "mode": "translation", "q": "play (n.)", "ans": "戏剧", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["戏剧", "剧本"]},
          {"word": "vacation", "mode": "pos", "q": "vacation", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "live", "mode": "spelling", "q": "居住", "ans": "live", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["live"]},
          {"word": "snowman", "mode": "spelling", "q": "雪人", "ans": "snow", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["snowman"]},
          {"word": "all", "mode": "spelling", "q": "全；完全", "ans": "all", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["all"]},
          {"word": "letter", "mode": "spelling", "q": "信", "ans": "letter", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["letter"]},
          {"word": "start", "mode": "translation", "q": "start (n.)", "ans": "开始", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["开始"]},
          {"word": "spring", "mode": "spelling", "q": "春天", "ans": "spring", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["spring"]},
          {"word": "lovely", "mode": "pos", "q": "lovely", "ans": "adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj."]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "summer", "mode": "pos", "q": "summer", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "dancing", "mode": "translation", "q": "dancing (n.)", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["跳舞", "舞蹈"]},
          {"word": "always", "mode": "spelling", "q": "总是；一直", "ans": "always", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["always"]},
          {"word": "dancing", "mode": "spelling", "q": "跳舞；舞蹈", "ans": "dancing", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["dancing"]},
          {"word": "go for a walk", "mode": "translation", "q": "go for a walk (v.)", "ans": "散步", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["散步"]},
          {"word": "go on a picnic", "mode": "pos", "q": "go on a picnic", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "do morning exercises", "mode": "pos", "q": "do morning exercises", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v."]}
        ]},
        {"timestamp": "2026-04-14 21:18:42", "mode": "混合模式", "score": 0, "total": 30, "correct": 3.5, "score_val": 3.5, "used_hints": 0, "status": "中途被放弃", "details": [
          {"word": "eat breakfast", "mode": "translation", "q": "eat breakfast (v.)", "ans": "吃早饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃早饭"]},
          {"word": "autumn", "mode": "pos", "q": "autumn", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "live", "mode": "pos", "q": "live", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v."]},
          {"word": "all", "mode": "translation", "q": "all (adj.)", "ans": "全", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["全", "完全"]},
          {"word": "snow", "mode": "pos", "q": "snow", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["n.", "v."]}
        ]},
        {"timestamp": "2026-04-14 21:24:01", "mode": "混合模式", "score": 0, "total": 30, "correct": 10.666666666666666, "score_val": 10.666666666666666, "used_hints": 0, "status": "中途被放弃", "details": [
          {"word": "when", "mode": "pos", "q": "when", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv.", "conj."]},
          {"word": "late", "mode": "pos", "q": "late", "ans": "adj.,adv.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj.", "adv."]},
          {"word": "late", "mode": "spelling", "q": "晚；迟", "ans": "late", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["late"]},
          {"word": "also", "mode": "translation", "q": "also (adv.)", "ans": "还", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["还", "也"]},
          {"word": "season", "mode": "pos", "q": "season", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "go swimming", "mode": "translation", "q": "go swimming (v.)", "ans": "去游泳", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去游泳"]},
          {"word": "p.m.", "mode": "spelling", "q": "午后；下午", "ans": "p.m", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["p.m."]},
          {"word": "take", "mode": "pos", "q": "take", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "exercise", "mode": "translation", "q": "exercise (n.)", "ans": "活动", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["活动", "运动"]},
          {"word": "season", "mode": "spelling", "q": "季节", "ans": "season", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["season"]},
          {"word": "go on a picnic", "mode": "spelling", "q": "去野餐", "ans": "go on a picnic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go on a picnic"]},
          {"word": "lovely", "mode": "spelling", "q": "可爱的；美丽的", "ans": "looely", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["lovely"]},
          {"word": "last", "mode": "pos", "q": "last", "ans": "adj.,adv.", "correct": false, "score_val": 0.6666666666666666, "needs_manual": false, "expected": ["adj.", "adv.", "v."]}
        ]},
        {"timestamp": "2026-04-14 21:32:54", "mode": "混合模式", "score": 87, "total": 30, "correct": 26.333333333333332, "score_val": 26.333333333333332, "used_hints": 0, "status": "已完成", "details": [
          {"word": "a.m.", "mode": "pos", "q": "a.m.", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "win", "mode": "spelling", "q": "获胜", "ans": "win", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["win"]},
          {"word": "take a dancing class", "mode": "spelling", "q": "上舞蹈课", "ans": "take a dancing class", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["take a dancing class"]},
          {"word": "snow", "mode": "translation", "q": "snow (v.)", "ans": "雪", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["雪"]},
          {"word": "dancing", "mode": "translation", "q": "dancing (n.)", "ans": "舞蹈", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["跳舞", "舞蹈"]},
          {"word": "autumn", "mode": "translation", "q": "autumn (n.)", "ans": "秋天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["秋天"]},
          {"word": "all", "mode": "pos", "q": "all", "ans": "adj.,adv.", "correct": false, "score_val": 0.6666666666666666, "needs_manual": false, "expected": ["adj.", "adv.", "pron."]},
          {"word": "pick apples", "mode": "pos", "q": "pick apples", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "spring", "mode": "translation", "q": "spring (n.)", "ans": "春天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["春天"]},
          {"word": "win", "mode": "translation", "q": "win (v.)", "ans": "获胜", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["获胜"]},
          {"word": "eat dinner", "mode": "translation", "q": "eat dinner (v.)", "ans": "吃晚饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃晚饭"]},
          {"word": "picnic", "mode": "spelling", "q": "野餐", "ans": "go on a picnic", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["picnic"]},
          {"word": "island", "mode": "pos", "q": "island", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "snowman", "mode": "pos", "q": "snowman", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "cave", "mode": "pos", "q": "cave", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "season", "mode": "spelling", "q": "季节", "ans": "season", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["season"]},
          {"word": "best", "mode": "spelling", "q": "最，最高程度地", "ans": "best", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["best"]},
          {"word": "last", "mode": "pos", "q": "last", "ans": "adj.,adv.", "correct": false, "score_val": 0.6666666666666666, "needs_manual": false, "expected": ["adj.", "adv.", "v."]},
          {"word": "go swimming", "mode": "pos", "q": "go swimming", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "pink", "mode": "translation", "q": "pink (adj.)", "ans": "粉色", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["粉色", "粉色的"]},
          {"word": "best", "mode": "translation", "q": "best (adj.)", "ans": "最", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["最", "最高程度地"]},
          {"word": "go for a walk", "mode": "spelling", "q": "散步", "ans": "walk", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["go for a walk"]},
          {"word": "go swimming", "mode": "spelling", "q": "去游泳", "ans": "go swimming", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go swimming"]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "have ... class", "mode": "pos", "q": "have ... class", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "sound", "mode": "pos", "q": "sound", "ans": "v.,n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "dancing", "mode": "spelling", "q": "跳舞；舞蹈", "ans": "dancing", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["dancing"]},
          {"word": "island", "mode": "spelling", "q": "岛", "ans": "island", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["island"]},
          {"word": "pick apples", "mode": "spelling", "q": "摘苹果", "ans": "go on a picnic", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["pick apples"]},
          {"word": "busy", "mode": "translation", "q": "busy (adj.)", "ans": "忙的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["忙的"]}
        ]},
        {"timestamp": "2026-04-15 21:30:54", "mode": "混合模式", "score": 75, "total": 30, "correct": 22.5, "score_val": 22.5, "used_hints": 0, "status": "已完成", "details": [
          {"word": "work", "mode": "spelling", "q": "工作", "ans": "work", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["work"]},
          {"word": "autumn", "mode": "translation", "q": "autumn (n.)", "ans": "秋天", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["秋天"]},
          {"word": "go on a picnic", "mode": "translation", "q": "go on a picnic (v.)", "ans": "去野餐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去野餐"]},
          {"word": "cave", "mode": "pos", "q": "cave", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "go swimming", "mode": "translation", "q": "go swimming (v.)", "ans": "去游泳", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去游泳"]},
          {"word": "start", "mode": "translation", "q": "start (n.)", "ans": "开始", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["开始"]},
          {"word": "which", "mode": "spelling", "q": "哪一个", "ans": "whach", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["which"]},
          {"word": "snowman", "mode": "spelling", "q": "雪人", "ans": "now", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["snowman"]},
          {"word": "lovely", "mode": "spelling", "q": "可爱的；美丽的", "ans": "healle", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["lovely"]},
          {"word": "which", "mode": "pos", "q": "which", "ans": "adv.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adj.", "pron."]},
          {"word": "when", "mode": "pos", "q": "when", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv.", "conj."]},
          {"word": "take a dancing class", "mode": "pos", "q": "take a dancing class", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "shop", "mode": "pos", "q": "shop", "ans": "v.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["v.", "n."]},
          {"word": "picnic", "mode": "spelling", "q": "野餐", "ans": "picnic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["picnic"]},
          {"word": "spring", "mode": "spelling", "q": "春天", "ans": "spring", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["spring"]},
          {"word": "pink", "mode": "pos", "q": "pink", "ans": "n.,adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n.", "adj."]},
          {"word": "dancing", "mode": "translation", "q": "dancing (n.)", "ans": "舞蹈", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["跳舞", "舞蹈"]},
          {"word": "season", "mode": "translation", "q": "season (n.)", "ans": "季节", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["季节"]},
          {"word": "do morning exercises", "mode": "pos", "q": "do morning exercises", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "autumn", "mode": "pos", "q": "autumn", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "when", "mode": "translation", "q": "when (adv.)", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["什么时候", "何时"]},
          {"word": "season", "mode": "pos", "q": "season", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "exercise", "mode": "spelling", "q": "活动；运动", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["exercise"]},
          {"word": "lovely", "mode": "translation", "q": "lovely (adj.)", "ans": "可爱的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["可爱的", "美丽的"]},
          {"word": "after", "mode": "spelling", "q": "在（时间）后", "ans": "after", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["after"]},
          {"word": "all", "mode": "translation", "q": "all (adv.)", "ans": "全", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["全", "完全"]},
          {"word": "dancing", "mode": "spelling", "q": "跳舞；舞蹈", "ans": "dancing", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["dancing"]},
          {"word": "why", "mode": "translation", "q": "why (conj.)", "ans": "为什么", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["为什么"]},
          {"word": "spring", "mode": "pos", "q": "spring", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "go swimming", "mode": "spelling", "q": "去游泳", "ans": "go swimming", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go swimming"]}
        ]},
        {"timestamp": "2026-04-15 21:42:01", "mode": "混合模式", "score": 85, "total": 30, "correct": 25.5, "score_val": 25.5, "used_hints": 0, "status": "已完成", "details": [
          {"word": "after", "mode": "spelling", "q": "在（时间）后", "ans": "after", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["after"]},
          {"word": "eat breakfast", "mode": "translation", "q": "eat breakfast (v.)", "ans": "吃早饭", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["吃早饭"]},
          {"word": "because", "mode": "pos", "q": "because", "ans": "pron.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["conj."]},
          {"word": "do morning exercises", "mode": "translation", "q": "do morning exercises (v.)", "ans": "做早操", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["做早操"]},
          {"word": "spring", "mode": "pos", "q": "spring", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "play sports", "mode": "pos", "q": "play sports", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "do morning exercises", "mode": "spelling", "q": "做早操", "ans": "do morning exercises", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["do morning exercises"]},
          {"word": "winter", "mode": "spelling", "q": "冬天", "ans": "winter", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["winter"]},
          {"word": "picnic", "mode": "spelling", "q": "野餐", "ans": "go on a picnic", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["picnic"]},
          {"word": "why", "mode": "spelling", "q": "为什么", "ans": "why", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["why"]},
          {"word": "go swimming", "mode": "translation", "q": "go swimming (v.)", "ans": "去游泳", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["去游泳"]},
          {"word": "win", "mode": "translation", "q": "win (v.)", "ans": "获胜", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["获胜"]},
          {"word": "also", "mode": "spelling", "q": "还；也", "ans": "also", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["also"]},
          {"word": "live", "mode": "spelling", "q": "居住", "ans": "live", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["live"]},
          {"word": "p.m.", "mode": "pos", "q": "p.m.", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "vacation", "mode": "spelling", "q": "假期", "ans": "vacation", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["vacation"]},
          {"word": "do morning exercises", "mode": "pos", "q": "do morning exercises", "ans": "v.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["v."]},
          {"word": "snow", "mode": "pos", "q": "snow", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["n.", "v."]},
          {"word": "letter", "mode": "pos", "q": "letter", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "season", "mode": "translation", "q": "season (n.)", "ans": "季节", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["季节"]},
          {"word": "which", "mode": "pos", "q": "which", "ans": "n.,adj.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adj.", "pron."]},
          {"word": "work", "mode": "translation", "q": "work (n.)", "ans": "工作", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["工作"]},
          {"word": "go for a walk", "mode": "spelling", "q": "散步", "ans": "go for a walk", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["go for a walk"]},
          {"word": "leaf", "mode": "pos", "q": "leaf", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "snowman", "mode": "translation", "q": "snowman (n.)", "ans": "雪人", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["雪人"]},
          {"word": "go for a walk", "mode": "translation", "q": "go for a walk (v.)", "ans": "散步", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["散步"]},
          {"word": "usually", "mode": "pos", "q": "usually", "ans": "n.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["adv."]},
          {"word": "pick", "mode": "spelling", "q": "摘；采集", "ans": "pick", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["pick"]},
          {"word": "dancing", "mode": "translation", "q": "dancing (n.)", "ans": "舞蹈", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["跳舞", "舞蹈"]},
          {"word": "letter", "mode": "translation", "q": "letter (n.)", "ans": "信", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["信"]}
        ]}
      ],
      "stats": {
        "picnic": {"total": 10, "correct": 6, "wrong": 4, "cumulative_seconds": 220, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "错"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "错"},
          {"time": "2026-04-14 21:32:52", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "错"}
        ]},
        "paint": {"total": 8, "correct": 7, "wrong": 1, "cumulative_seconds": 124, "history": [
          {"time": "2026-03-30 21:15:49", "result": "错"},
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"}
        ]},
        "bunny": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 23, "history": [
          {"time": "2026-03-30 21:15:49", "result": "错"}
        ]},
        "good job": {"total": 5, "correct": 5, "wrong": 0, "cumulative_seconds": 70, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:41", "result": "对"},
          {"time": "2026-04-02 21:36:20", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"}
        ]},
        "all": {"total": 12, "correct": 9, "wrong": 3, "cumulative_seconds": 131, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-30 21:26:24", "result": "错"},
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "错"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "holiday": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 46, "history": [
          {"time": "2026-03-30 21:15:49", "result": "错"}
        ]},
        "best": {"total": 8, "correct": 6, "wrong": 2, "cumulative_seconds": 112, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-30 21:15:49", "result": "错"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "错"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "American": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 28, "history": [
          {"time": "2026-03-30 21:15:49", "result": "错"}
        ]},
        "vacation": {"total": 12, "correct": 11, "wrong": 1, "cumulative_seconds": 211, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "错"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "winter": {"total": 4, "correct": 4, "wrong": 0, "cumulative_seconds": 67, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "go swimming": {"total": 16, "correct": 15, "wrong": 1, "cumulative_seconds": 245, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "错"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "snow": {"total": 11, "correct": 5, "wrong": 6, "cumulative_seconds": 132, "history": [
          {"time": "2026-03-30 21:15:49", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "错"},
          {"time": "2026-04-01 21:25:06", "result": "错"},
          {"time": "2026-04-02 21:35:48", "result": "错"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "错"},
          {"time": "2026-04-13 21:18:49", "result": "错"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "错"}
        ]},
        "pick": {"total": 11, "correct": 9, "wrong": 2, "cumulative_seconds": 172, "history": [
          {"time": "2026-03-30 21:15:49", "result": "错"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "错"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "National Day": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 0, "history": [
          {"time": "2026-03-30 21:15:49", "result": "错"}
        ]},
        "summer": {"total": 7, "correct": 7, "wrong": 0, "cumulative_seconds": 82, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"}
        ]},
        "make a snowman": {"total": 5, "correct": 5, "wrong": 0, "cumulative_seconds": 71, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"}
        ]},
        "go on a picnic": {"total": 12, "correct": 12, "wrong": 0, "cumulative_seconds": 212, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "which": {"total": 12, "correct": 9, "wrong": 3, "cumulative_seconds": 212, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "错"},
          {"time": "2026-04-15 21:41:59", "result": "错"}
        ]},
        "season": {"total": 10, "correct": 8, "wrong": 2, "cumulative_seconds": 119, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-03-30 21:26:24", "result": "错"},
          {"time": "2026-04-01 21:25:06", "result": "错"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "autumn": {"total": 11, "correct": 11, "wrong": 0, "cumulative_seconds": 111, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "because": {"total": 7, "correct": 5, "wrong": 2, "cumulative_seconds": 111, "history": [
          {"time": "2026-03-30 21:26:24", "result": "错"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "错"}
        ]},
        "spring": {"total": 7, "correct": 7, "wrong": 0, "cumulative_seconds": 50, "history": [
          {"time": "2026-03-30 21:26:24", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "fall": {"total": 8, "correct": 5, "wrong": 3, "cumulative_seconds": 109, "history": [
          {"time": "2026-03-31 21:35:15", "result": "错"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "错"},
          {"time": "2026-04-13 21:49:14", "result": "错"},
          {"time": "2026-04-14 21:13:54", "result": "对"}
        ]},
        "leaf": {"total": 5, "correct": 5, "wrong": 0, "cumulative_seconds": 66, "history": [
          {"time": "2026-03-31 21:35:15", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "snowman": {"total": 10, "correct": 8, "wrong": 2, "cumulative_seconds": 115, "history": [
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-01 21:25:06", "result": "对"},
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "错"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "错"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "pink": {"total": 7, "correct": 6, "wrong": 1, "cumulative_seconds": 54, "history": [
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "错"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "lovely": {"total": 9, "correct": 8, "wrong": 1, "cumulative_seconds": 123, "history": [
          {"time": "2026-04-02 21:35:48", "result": "对"},
          {"time": "2026-04-02 21:41:44", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "pick apples": {"total": 6, "correct": 5, "wrong": 1, "cumulative_seconds": 96, "history": [
          {"time": "2026-04-02 21:48:57", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "错"}
        ]},
        "play sports": {"total": 3, "correct": 2, "wrong": 1, "cumulative_seconds": 57, "history": [
          {"time": "2026-04-09 21:25:00", "result": "错"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "sound": {"total": 4, "correct": 3, "wrong": 1, "cumulative_seconds": 69, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-09 21:25:00", "result": "错"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "island": {"total": 3, "correct": 3, "wrong": 0, "cumulative_seconds": 48, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "play": {"total": 4, "correct": 4, "wrong": 0, "cumulative_seconds": 98, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"}
        ]},
        "p.m.": {"total": 4, "correct": 4, "wrong": 0, "cumulative_seconds": 56, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "need": {"total": 2, "correct": 0, "wrong": 2, "cumulative_seconds": 45, "history": [
          {"time": "2026-04-09 21:25:00", "result": "错"},
          {"time": "2026-04-13 21:49:14", "result": "错"}
        ]},
        "dancing": {"total": 8, "correct": 7, "wrong": 1, "cumulative_seconds": 204, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "错"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "eat breakfast": {"total": 6, "correct": 6, "wrong": 0, "cumulative_seconds": 80, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "last": {"total": 7, "correct": 5, "wrong": 2, "cumulative_seconds": 145, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "错"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "错"}
        ]},
        "letter": {"total": 6, "correct": 6, "wrong": 0, "cumulative_seconds": 93, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "always": {"total": 5, "correct": 3, "wrong": 2, "cumulative_seconds": 149, "history": [
          {"time": "2026-04-09 21:25:00", "result": "错"},
          {"time": "2026-04-13 21:30:04", "result": "错"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"}
        ]},
        "take a dancing class": {"total": 5, "correct": 4, "wrong": 1, "cumulative_seconds": 130, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "错"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "clean my room": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 10, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"}
        ]},
        "Spain": {"total": 2, "correct": 1, "wrong": 1, "cumulative_seconds": 39, "history": [
          {"time": "2026-04-09 21:25:00", "result": "错"},
          {"time": "2026-04-13 21:30:04", "result": "对"}
        ]},
        "start": {"total": 6, "correct": 6, "wrong": 0, "cumulative_seconds": 84, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "busy": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 52, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "do morning exercises": {"total": 8, "correct": 7, "wrong": 1, "cumulative_seconds": 122, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "have ... class": {"total": 3, "correct": 2, "wrong": 1, "cumulative_seconds": 18, "history": [
          {"time": "2026-04-09 21:25:00", "result": "错"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "eat dinner": {"total": 4, "correct": 4, "wrong": 0, "cumulative_seconds": 32, "history": [
          {"time": "2026-04-09 21:25:00", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "cave": {"total": 5, "correct": 5, "wrong": 0, "cumulative_seconds": 54, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"}
        ]},
        "work": {"total": 5, "correct": 5, "wrong": 0, "cumulative_seconds": 51, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "why": {"total": 4, "correct": 4, "wrong": 0, "cumulative_seconds": 38, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:49:14", "result": "对"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "late": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 29, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"}
        ]},
        "when": {"total": 4, "correct": 1, "wrong": 3, "cumulative_seconds": 73, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:18:49", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "错"}
        ]},
        "usually": {"total": 3, "correct": 2, "wrong": 1, "cumulative_seconds": 100, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:50:02", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "错"}
        ]},
        "go for a walk": {"total": 6, "correct": 5, "wrong": 1, "cumulative_seconds": 98, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-13 21:30:04", "result": "对"},
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "错"},
          {"time": "2026-04-15 21:41:59", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "a.m.": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 29, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"}
        ]},
        "also": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 27, "history": [
          {"time": "2026-04-13 21:18:49", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "shop": {"total": 2, "correct": 0, "wrong": 2, "cumulative_seconds": 51, "history": [
          {"time": "2026-04-13 21:30:04", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "错"}
        ]},
        "win": {"total": 4, "correct": 3, "wrong": 1, "cumulative_seconds": 36, "history": [
          {"time": "2026-04-13 21:30:04", "result": "错"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-14 21:32:52", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "take": {"total": 2, "correct": 1, "wrong": 1, "cumulative_seconds": 45, "history": [
          {"time": "2026-04-13 21:49:14", "result": "错"},
          {"time": "2026-04-14 21:13:54", "result": "对"}
        ]},
        "go shopping": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-13 21:49:14", "result": "对"}
        ]},
        "after": {"total": 3, "correct": 2, "wrong": 1, "cumulative_seconds": 49, "history": [
          {"time": "2026-04-13 21:49:58", "result": "错"},
          {"time": "2026-04-15 21:30:48", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "live": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 38, "history": [
          {"time": "2026-04-14 21:13:54", "result": "对"},
          {"time": "2026-04-15 21:41:59", "result": "对"}
        ]},
        "exercise": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 66, "history": [
          {"time": "2026-04-15 21:30:48", "result": "错"}
        ]}
      },
      "settings": {"hide_test_config": true, "allow_backward": false, "allow_hint": false, "per_q_time": 25.0, "timer_lock": true}
    },
    "1774876838293": {
      "name": "王浩艨",
      "history": [
        {"timestamp": "2026-04-15 21:08:35", "mode": "混合模式", "score": 90, "total": 10, "correct": 9.0, "score_val": 9.0, "used_hints": 0, "status": "已完成", "details": [
          {"word": "puzzle", "mode": "translation", "q": "puzzle (v.(vt.))", "ans": "困惑", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["使迷惑", "使困惑"]},
          {"word": "button", "mode": "translation", "q": "button (n.)", "ans": "按钮", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["按钮", "纽扣"]},
          {"word": "powerful", "mode": "translation", "q": "powerful (adj.)", "ans": "有力量的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["强有力的", "有权势的"]},
          {"word": "moreover", "mode": "translation", "q": "moreover (adv.)", "ans": "另外", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["此外", "而且"]},
          {"word": "music", "mode": "translation", "q": "music (n.)", "ans": "音乐", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["音乐", "乐曲"]},
          {"word": "survive", "mode": "translation", "q": "survive (v.(vt.))", "ans": "生存", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["幸存", "艰难度过"]},
          {"word": "click", "mode": "translation", "q": "click (v.(vt.))", "ans": "点击，按", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["点击"]},
          {"word": "privacy", "mode": "translation", "q": "privacy (n.)", "ans": "私人", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["隐私", "私密"]},
          {"word": "benefit", "mode": "translation", "q": "benefit (n.)", "ans": "益处", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["益处", "优势"]},
          {"word": "historic", "mode": "translation", "q": "historic (adj.)", "ans": "历史上的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["历史上著名（或重要）的"]}
        ]},
        {"timestamp": "2026-04-15 21:26:42", "mode": "混合模式", "score": 75, "total": 30, "correct": 22.5, "score_val": 22.5, "used_hints": 13, "status": "已完成", "details": [
          {"word": "network", "mode": "pos", "q": "network", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "historic", "mode": "pos", "q": "historic", "ans": "adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj."]},
          {"word": "studio", "mode": "pos", "q": "studio", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "classic", "mode": "pos", "q": "classic", "ans": "n.", "correct": false, "score_val": 0.5, "needs_manual": false, "expected": ["adj.", "n."]},
          {"word": "evidence", "mode": "pos", "q": "evidence", "ans": "v.(vt.)", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["n."]},
          {"word": "software", "mode": "translation", "q": "software (n.)", "ans": "软件", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["软件"]},
          {"word": "keep one's eyes open", "mode": "translation", "q": "keep one's eyes open", "ans": "保持注意", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["留心", "留意"]},
          {"word": "bell", "mode": "pos", "q": "bell", "ans": "n.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["n."]},
          {"word": "consist of", "mode": "spelling", "q": "由...组成；由...构成", "ans": "conduct from", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["consist of"]},
          {"word": "unique", "mode": "translation", "q": "unique (adj.)", "ans": "唯一的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["唯一的", "独特的"]},
          {"word": "keep company", "mode": "translation", "q": "keep company", "ans": "陪伴", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["陪伴", "做伴"]},
          {"word": "alive", "mode": "pos", "q": "alive", "ans": "adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj."]},
          {"word": "blogger", "mode": "translation", "q": "blogger (n.)", "ans": "博克者", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["博客作者", "博主"]},
          {"word": "religious", "mode": "pos", "q": "religious", "ans": "adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj."]},
          {"word": "keep ... in mind", "mode": "spelling", "q": "牢记", "ans": "keep in mind", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["keep ... in mind"]},
          {"word": "puzzle", "mode": "translation", "q": "puzzle (v.(vt.))", "ans": "使困惑", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["使迷惑", "使困惑"]},
          {"word": "instrument", "mode": "spelling", "q": "器械；仪器；乐器", "ans": "instrument", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["instrument"]},
          {"word": "fascinate", "mode": "pos", "q": "fascinate", "ans": "v.", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["v.(vt.)"]},
          {"word": "tradition", "mode": "spelling", "q": "传统；风俗", "ans": "tradition", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["tradition"]},
          {"word": "stream", "mode": "spelling", "q": "小河；溪流", "ans": "river", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["stream"]},
          {"word": "historical", "mode": "translation", "q": "historical (adj.)", "ans": "历史的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["（有关）历史的"]},
          {"word": "engine", "mode": "spelling", "q": "发动机；引擎", "ans": "engine", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["engine"]},
          {"word": "belong to", "mode": "translation", "q": "belong to", "ans": "属于", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["属于"]},
          {"word": "fascinated", "mode": "spelling", "q": "被迷住的；被吸引的", "ans": "fasnating", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["fascinated"]},
          {"word": "battery", "mode": "spelling", "q": "电池", "ans": "battary", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["battery"]},
          {"word": "sort", "mode": "translation", "q": "sort (n.)", "ans": "种植", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["种类", "类别"]},
          {"word": "puzzle", "mode": "spelling", "q": "谜；智力游戏", "ans": "puzzle", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["puzzle"]},
          {"word": "account", "mode": "spelling", "q": "账户；描述", "ans": "account", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["account"]},
          {"word": "performer", "mode": "translation", "q": "performer (n.)", "ans": "表演者", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["表演者", "演出者"]},
          {"word": "virtual", "mode": "pos", "q": "virtual", "ans": "adj.", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["adj."]}
        ]},
        {"timestamp": "2026-04-16 21:26:22", "mode": "混合模式", "score": 75, "total": 20, "correct": 15.0, "score_val": 15.0, "used_hints": 10, "status": "已完成", "details": [
          {"word": "database", "mode": "spelling", "q": "数据库；资料库", "ans": "database", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["database"]},
          {"word": "convenient", "mode": "spelling", "q": "方便的；近便的", "ans": "convinient", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["convenient"]},
          {"word": "search engine", "mode": "spelling", "q": "搜索引擎", "ans": "search engine", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["search engine"]},
          {"word": "moreover", "mode": "translation", "q": "moreover (adv.)", "ans": "另外", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["此外", "而且"]},
          {"word": "benefit", "mode": "spelling", "q": "得益于", "ans": "benifit", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["benefit"]},
          {"word": "stuck", "mode": "translation", "q": "stuck (adj.)", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["卡住的", "陷入的"]},
          {"word": "bell", "mode": "translation", "q": "bell (n.)", "ans": "铃铛", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["钟", "铃", "钟声"]},
          {"word": "historic", "mode": "spelling", "q": "历史上著名（或重要）的", "ans": "historic", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["historic"]},
          {"word": "stream", "mode": "spelling", "q": "小河；溪流", "ans": "stream", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["stream"]},
          {"word": "software", "mode": "translation", "q": "software (n.)", "ans": "软件", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["软件"]},
          {"word": "admit", "mode": "spelling", "q": "承认；准许进入", "ans": "admit", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["admit"]},
          {"word": "location", "mode": "spelling", "q": "地方；地点；位置", "ans": "location", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["location"]},
          {"word": "musical", "mode": "spelling", "q": "音乐的；有音乐天赋的", "ans": "musical", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["musical"]},
          {"word": "act", "mode": "spelling", "q": "（戏的）一幕；行为", "ans": "act", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["act"]},
          {"word": "generation", "mode": "spelling", "q": "一代（人）", "ans": "generation", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["generation"]},
          {"word": "battle", "mode": "spelling", "q": "战役；搏斗", "ans": "battle", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["battle"]},
          {"word": "in relief", "mode": "spelling", "q": "如释重负", "ans": "in relife", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["in relief"]},
          {"word": "track", "mode": "spelling", "q": "足迹；踪迹", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["track"]},
          {"word": "state", "mode": "spelling", "q": "国家；政府；州；状态", "ans": "state", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["state"]},
          {"word": "pretend", "mode": "translation", "q": "pretend (v.(vt.))", "ans": "假装", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["假装", "装扮"]}
        ]},
        {"timestamp": "2026-04-17 22:05:59", "mode": "混合模式", "score": 60, "total": 30, "correct": 18.0, "score_val": 18.0, "used_hints": 12, "status": "已完成", "details": [
          {"word": "blogger", "mode": "translation", "q": "blogger (n.)", "ans": "博主", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["博客作者", "博主"]},
          {"word": "stuck", "mode": "spelling", "q": "卡住的；陷入的", "ans": "strick", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["stuck"]},
          {"word": "hip-hop", "mode": "spelling", "q": "嘻哈音乐；嘻哈文化", "ans": "hip-hop", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["hip-hop"]},
          {"word": "database", "mode": "spelling", "q": "数据库；资料库", "ans": "database", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["database"]},
          {"word": "port", "mode": "translation", "q": "port (n.)", "ans": "港口", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["港口（城市）"]},
          {"word": "pretend", "mode": "translation", "q": "pretend (v.(vt.))", "ans": "保护", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["假装", "装扮"]},
          {"word": "inspiring", "mode": "translation", "q": "inspiring (adj.)", "ans": "敬佩的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["鼓舞人心的", "启发灵感的"]},
          {"word": "press", "mode": "spelling", "q": "按；压；敦促", "ans": "press", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["press"]},
          {"word": "sort out", "mode": "spelling", "q": "整理；把...分类", "ans": "", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["sort out"]},
          {"word": "network", "mode": "translation", "q": "network (n.)", "ans": "网络", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["网络", "网状系统"]},
          {"word": "customs", "mode": "spelling", "q": "海关；关税", "ans": "port", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["customs"]},
          {"word": "account", "mode": "translation", "q": "account (n.)", "ans": "账户", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["账户", "描述"]},
          {"word": "access", "mode": "translation", "q": "access (n.)", "ans": "通道", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["通道", "（使用、查阅的）机会"]},
          {"word": "fascinate", "mode": "spelling", "q": "深深吸引；迷住", "ans": "fall in love with", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["fascinate"]},
          {"word": "in relief", "mode": "spelling", "q": "如释重负", "ans": "in relife", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["in relief"]},
          {"word": "conference", "mode": "spelling", "q": "会议；研讨会", "ans": "contribution", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["conference"]},
          {"word": "broadcast", "mode": "spelling", "q": "广播节目；电视节目", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["broadcast"]},
          {"word": "port", "mode": "spelling", "q": "港口（城市）", "ans": "port", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["port"]},
          {"word": "discount", "mode": "spelling", "q": "折扣", "ans": "discount", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["discount"]},
          {"word": "alive", "mode": "spelling", "q": "活着的；有生气的", "ans": "alive", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["alive"]},
          {"word": "burst into", "mode": "spelling", "q": "突然开始；爆发", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["burst into"]},
          {"word": "false", "mode": "spelling", "q": "假的；错误的", "ans": "false", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["false"]},
          {"word": "software", "mode": "translation", "q": "software (n.)", "ans": "软件", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["软件"]},
          {"word": "string", "mode": "translation", "q": "string (n.)", "ans": "字符串", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["细绳", "线", "弦"]},
          {"word": "soul", "mode": "spelling", "q": "灵魂；心灵；灵魂乐", "ans": "soul", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["soul"]},
          {"word": "tough", "mode": "spelling", "q": "艰难的；严厉的", "ans": "tough", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["tough"]},
          {"word": "parade", "mode": "spelling", "q": "游行；列队行进", "ans": "跳过/未作答", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["parade"]},
          {"word": "survive", "mode": "spelling", "q": "生存；存活", "ans": "survual", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["survive"]},
          {"word": "false", "mode": "translation", "q": "false (adj.)", "ans": "错误的", "correct": true, "score_val": 1.0, "needs_manual": false, "expected": ["假的", "错误的"]},
          {"word": "theft", "mode": "spelling", "q": "偷窃；盗窃罪", "ans": "chift", "correct": false, "score_val": 0.0, "needs_manual": false, "expected": ["theft"]}
        ]}
      ],
      "stats": {
        "button": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 6, "history": [
          {"time": "2026-04-15 21:08:11", "result": "对"}
        ]},
        "music": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-15 21:08:11", "result": "对"}
        ]},
        "benefit": {"total": 2, "correct": 1, "wrong": 1, "cumulative_seconds": 26, "history": [
          {"time": "2026-04-15 21:08:11", "result": "对"},
          {"time": "2026-04-16 21:26:16", "result": "错"}
        ]},
        "puzzle": {"total": 3, "correct": 3, "wrong": 0, "cumulative_seconds": 22, "history": [
          {"time": "2026-04-15 21:08:17", "result": "对"},
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "powerful": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:08:19", "result": "对"}
        ]},
        "moreover": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:08:22", "result": "对"},
          {"time": "2026-04-16 21:26:21", "result": "对"}
        ]},
        "survive": {"total": 2, "correct": 1, "wrong": 1, "cumulative_seconds": 60, "history": [
          {"time": "2026-04-15 21:08:23", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "click": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:08:24", "result": "对"}
        ]},
        "privacy": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:08:31", "result": "错"}
        ]},
        "historic": {"total": 3, "correct": 3, "wrong": 0, "cumulative_seconds": 24, "history": [
          {"time": "2026-04-15 21:08:34", "result": "对"},
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "network": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 18, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "studio": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 8, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "classic": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 28, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"}
        ]},
        "evidence": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 14, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"}
        ]},
        "software": {"total": 3, "correct": 3, "wrong": 0, "cumulative_seconds": 28, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-16 21:26:16", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "bell": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-16 21:26:22", "result": "对"}
        ]},
        "consist of": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 17, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"}
        ]},
        "unique": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "keep company": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 13, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "alive": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "religious": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 9, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "keep ... in mind": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 26, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "instrument": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 6, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "fascinate": {"total": 2, "correct": 0, "wrong": 2, "cumulative_seconds": 39, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"},
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "tradition": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 29, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "stream": {"total": 2, "correct": 1, "wrong": 1, "cumulative_seconds": 14, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"},
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "engine": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 16, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "belong to": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 3, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "fascinated": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"}
        ]},
        "battery": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 17, "history": [
          {"time": "2026-04-15 21:26:30", "result": "错"}
        ]},
        "account": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 8, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "performer": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "virtual": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 12, "history": [
          {"time": "2026-04-15 21:26:30", "result": "对"}
        ]},
        "keep one's eyes open": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:26:36", "result": "对"}
        ]},
        "blogger": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 12, "history": [
          {"time": "2026-04-15 21:26:38", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "historical": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:26:39", "result": "对"}
        ]},
        "sort": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-15 21:26:41", "result": "错"}
        ]},
        "database": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 32, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "convenient": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 13, "history": [
          {"time": "2026-04-16 21:26:16", "result": "错"}
        ]},
        "search engine": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 15, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "stuck": {"total": 2, "correct": 0, "wrong": 2, "cumulative_seconds": 40, "history": [
          {"time": "2026-04-16 21:26:16", "result": "错"},
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "admit": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 9, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "location": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "musical": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "act": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 8, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "generation": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "battle": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "in relief": {"total": 2, "correct": 0, "wrong": 2, "cumulative_seconds": 41, "history": [
          {"time": "2026-04-16 21:26:16", "result": "错"},
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "track": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 30, "history": [
          {"time": "2026-04-16 21:26:16", "result": "错"}
        ]},
        "state": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 11, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"}
        ]},
        "pretend": {"total": 2, "correct": 1, "wrong": 1, "cumulative_seconds": 13, "history": [
          {"time": "2026-04-16 21:26:16", "result": "对"},
          {"time": "2026-04-17 22:05:55", "result": "错"}
        ]},
        "hip-hop": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 23, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "press": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 3, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "sort out": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 19, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "customs": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "access": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 6, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "conference": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 30, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "broadcast": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 37, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "port": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 6, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"},
          {"time": "2026-04-17 22:05:52", "result": "对"}
        ]},
        "discount": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 18, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "burst into": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 13, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "false": {"total": 2, "correct": 2, "wrong": 0, "cumulative_seconds": 29, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"},
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "soul": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "tough": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 30, "history": [
          {"time": "2026-04-17 22:05:48", "result": "对"}
        ]},
        "parade": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 7, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "theft": {"total": 1, "correct": 0, "wrong": 1, "cumulative_seconds": 4, "history": [
          {"time": "2026-04-17 22:05:48", "result": "错"}
        ]},
        "inspiring": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-17 22:05:56", "result": "对"}
        ]},
        "string": {"total": 1, "correct": 1, "wrong": 0, "cumulative_seconds": 0, "history": [
          {"time": "2026-04-17 22:05:58", "result": "对"}
        ]}
      },
      "settings": {}
    }
  },
  "global_settings": {
    "device_accounts": {"b1ee5e47-9abc-4ee2-9850-1d59e2037f24": "1774875972147", "7e4186d2-23fc-4ef2-a7e3-573b5b2afa03": "1774876838293"}
  }
}
'''
