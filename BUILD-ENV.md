# rEFInd 编译环境准备

本文档说明在本仓库中编译 rEFInd 所需的环境，重点覆盖在 **x86-64 Linux 主机上交叉编译 ARM64（aa64）** 的场景。更完整的官方说明见 [BUILDING.txt](BUILDING.txt)。

## 1. 通用依赖

在 Debian / Ubuntu 上：

```bash
sudo apt-get install build-essential git
```

| 目标架构 | 额外依赖 |
|----------|----------|
| x64（本机） | `gnu-efi` |
| aa64（交叉） | `gcc-aarch64-linux-gnu` `binutils-aarch64-linux-gnu`，以及带 aarch64 头文件的 GNU-EFI（见下文） |

## 2. x64 本机编译

在 x86-64 系统上编译本机版本：

```bash
sudo apt-get install gnu-efi
cd /path/to/refind-0.14.2
make clean
make gnuefi
```

产物：

- `refind/refind_x64.efi`
- `gptsync/gptsync_x64.efi`

## 3. aa64 交叉编译（重点）

### 3.1 为什么不能只用系统 `gnu-efi`？

Debian/Ubuntu 的 `gnu-efi` 包通常**只包含 x86/x64 头文件和库**，没有 `aarch64/efibind.h` 等 ARM64 专用文件。

若直接执行：

```bash
make gnuefi ARCH=aarch64 GNUEFI_ARM64_TARGET_SUPPORT=y
```

会出现类似错误：

```text
fatal error: aarch64/efibind.h: 没有那个文件或目录
```

**解决办法：** 从 GNU-EFI 源码单独编译 ARM64 支持，安装到项目目录 `.gnuefi-aa64/`（不写入系统路径）。

### 3.2 一键准备 GNU-EFI（推荐）

```bash
cd /path/to/refind-0.14.2
./scripts/prepare-gnuefi-aa64.sh
```

脚本会：

1. 克隆 [gnu-efi](https://github.com/vathpela/gnu-efi) 源码到临时目录
2. 使用 `aarch64-linux-gnu-gcc` 交叉编译
3. 将头文件、库、链接脚本安装到 `.gnuefi-aa64/`

### 3.3 手动准备 GNU-EFI

若脚本不可用，可手动执行：

```bash
# 安装交叉工具链
sudo apt-get install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu

# 克隆并编译 GNU-EFI（只编译 lib + gnuefi，不要 make all，apps 会在 CI 上失败）
git clone --depth 1 https://github.com/vathpela/gnu-efi.git /tmp/gnu-efi
cd /tmp/gnu-efi
make clean
make lib gnuefi ARCH=aarch64 CROSS_COMPILE=aarch64-linux-gnu-

# 安装到项目目录
GNUEFI_DIR=/path/to/refind-0.14.2/.gnuefi-aa64
mkdir -p "$GNUEFI_DIR/include" "$GNUEFI_DIR/lib"
cp -r inc "$GNUEFI_DIR/include/efi"
cp aarch64/gnuefi/crt0-efi-aarch64.o aarch64/gnuefi/libgnuefi.a gnuefi/elf_aarch64_efi.lds "$GNUEFI_DIR/lib/"
cp aarch64/lib/libefi.a "$GNUEFI_DIR/lib/"
```

### 3.4 编译 aa64 版本

```bash
cd /path/to/refind-0.14.2
./scripts/build-aa64.sh
```

或手动执行：

```bash
make gnuefi ARCH=aarch64 GNUEFI_ARM64_TARGET_SUPPORT=y \
  EFIINC=$PWD/.gnuefi-aa64/include/efi \
  GNUEFILIB=$PWD/.gnuefi-aa64/lib \
  EFILIB=$PWD/.gnuefi-aa64/lib \
  EFICRT0=$PWD/.gnuefi-aa64/lib
```

**说明：**

- `GNUEFI_ARM64_TARGET_SUPPORT=y` 在使用 GNU-EFI 3.0.17 及更高版本时**必须**设置
- 修改源码后建议先 `make clean` 再编译（见 [BUILDING.txt](BUILDING.txt) 开头说明）

### 3.5 产物

| 文件 | 说明 |
|------|------|
| `refind/refind_aa64.efi` | rEFInd 主程序 |
| `gptsync/gptsync_aa64.efi` | GPT 同步工具 |

验证架构：

```bash
file refind/refind_aa64.efi
# 应显示: PE32+ executable (EFI application) Aarch64
```

### 3.6 可选：文件系统驱动

```bash
make fs_gnuefi ARCH=aarch64 GNUEFI_ARM64_TARGET_SUPPORT=y \
  EFIINC=$PWD/.gnuefi-aa64/include/efi \
  GNUEFILIB=$PWD/.gnuefi-aa64/lib \
  EFILIB=$PWD/.gnuefi-aa64/lib \
  EFICRT0=$PWD/.gnuefi-aa64/lib
```

驱动输出在 `drivers_aa64/` 目录。

## 4. 部署到 ESP

```bash
# 示例：复制到 ESP 的 rEFInd 目录
cp refind/refind_aa64.efi /boot/efi/EFI/refind/

# 或作为 ARM64 默认启动项
cp refind/refind_aa64.efi /boot/efi/EFI/BOOT/bootaa64.efi
```

也可使用项目自带的 `refind-install` 脚本（需在 ARM64 机器上运行，或手动复制文件）。

## 5. 常见问题

### `aarch64/efibind.h: 没有那个文件或目录`

系统 `gnu-efi` 不含 ARM64 头文件。按 [3.2](#32-一键准备-gnu-efi推荐) 准备 `.gnuefi-aa64/`，编译时通过 `EFIINC` 等变量指向该目录。

### `aarch64-linux-gnu-gcc: 未找到命令`

```bash
sudo apt-get install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

### GNU-EFI 汇编错误（`no such instruction: stp`）

编译 GNU-EFI 时未使用交叉编译器。确保：

```bash
make lib gnuefi ARCH=aarch64 CROSS_COMPILE=aarch64-linux-gnu-
```

### `ld: cannot represent machine aarch64`（CI 常见）

GNU-EFI 顶层 `make all` 会编译 `apps` 示例，在 x86 主机上用宿主机 `ld` 链接 aarch64 会失败。只编译 rEFInd 需要的部分：

```bash
make lib gnuefi ARCH=aarch64 CROSS_COMPILE=aarch64-linux-gnu-
```

`scripts/prepare-gnuefi-aa64.sh` 已按此方式处理。

### `.gnuefi-aa64/` 被删除

重新运行 `./scripts/prepare-gnuefi-aa64.sh`。

## 6. GitHub Actions

推送或 PR 到 `master` / `main` 分支时，`.github/workflows/build.yml` 会自动运行 **build-aa64**（`prepare-gnuefi-aa64.sh` + `build-aa64.sh`）。

构建产物可在 Actions 页面的 **Artifacts** 中下载（`refind-aa64`）。

### 发布 Release

推送任意 tag 时，会自动创建 GitHub Release 并上传 zip 包：

```bash
git tag v0.14.2
git push origin v0.14.2
```

Release 附件为 **`xiaomi_raphael_refind_efi.zip`**，内含：

| 文件 | 架构 |
|------|------|
| `refind_aa64.efi` | ARM64 |
| `gptsync_aa64.efi` | ARM64 |

也可在 GitHub Actions 页面手动触发 **workflow_dispatch**，勾选 **Create GitHub Release** 发布（tag 为 `manual-<run号>`）。

## 7. 目录说明

| 路径 | 说明 |
|------|------|
| `.gnuefi-aa64/` | 本地 GNU-EFI（含 aarch64 头文件/库），由准备脚本生成，已加入 `.gitignore` |
| `.github/workflows/build.yml` | CI 自动编译工作流 |
| `scripts/prepare-gnuefi-aa64.sh` | 准备交叉编译用 GNU-EFI |
| `scripts/build-aa64.sh` | 编译 `refind_aa64.efi` |
| `BUILDING.txt` | 官方完整编译文档（英文） |
