# JPDC 金禧海景城 CRM 安装指南

## 📦 安装包内容

```
JPDC_CRM_安装包/
├── JPDC_CRM_v2.0.apk          ← 安卓App安装包 (85 MB)
├── 启动后端.bat                ← 一键启动后端 (Windows)
└── backend/
    ├── main.py                ← FastAPI 后端主程序
    ├── jpdc.db                ← SQLite 数据库 (1227单元)
    ├── db_setup.py            ← 数据库初始化脚本
    ├── import_excel.py        ← Excel导入脚本
    └── requirements.txt       ← Python依赖
```

## ⚙️ 步骤一：启动后端（电脑）

**前置条件：Python 3.9+ 已安装**

1. 双击 **`启动后端.bat`**
2. 首次运行会自动安装依赖（fastapi / uvicorn / pyjwt）
3. 看到 "后端运行中！" 即启动成功
4. 记下屏幕上的 IP 地址（如 `http://192.168.1.100:8001`）

> 如需开机自启：将 `启动后端.bat` 快捷方式放入 `shell:startup` 文件夹

## 📱 步骤二：安装App（手机）

1. 将 `JPDC_CRM_v2.0.apk` 传到安卓手机
   - 方式A：USB 线拷贝
   - 方式B：电脑开 HTTP 服务 `python -m http.server 8888`，手机浏览器访问 `http://电脑IP:8888` 下载
2. 手机打开 APK 安装（允许"未知来源"安装）
3. 打开 App，进入 **Settings**
4. 服务器地址填入电脑 IP，端口 `8001`，例如 `http://192.168.1.100:8001`
5. 点 "Save & Test" → 显示 "✅ Connected" 即成功

## 🔑 默认账密

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 管理员 | admin | admin123 |

## 📊 功能模块

| 模块 | 说明 | 数据量 |
|------|------|--------|
| Dashboard | 库存概览 + 销售趋势图 | — |
| Units | 单元浏览 (Tower A/E 切换) | 1,227 |
| Overdue | 逾期预警 (高/中/低风险) | 21 |
| Sold Clients | 已售客户 | 99 |
| Payments | 付款明细 | 76 |
| Returned | 退房明细 | 39 |
| Problem Units | 问题/预留单元 | 10 |
| Users | 用户权限管理 | Admin/Agent/Viewer |

## 🔄 月度更新

1. 将最新 Excel 放到桌面
2. 运行 `backend/import_excel.py`（会自动查找桌面上的 CRM Excel 文件）
3. 重启后端

## 🚫 防火墙

若手机连不上，检查电脑防火墙是否放行 8001 端口：
```
控制面板 → Windows Defender 防火墙 → 高级设置 → 入站规则
→ 新建规则 → 端口 → TCP 8001 → 允许连接
```

---

JPDC CRM v2.0 | 2026-07-14
