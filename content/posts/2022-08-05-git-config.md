---

title: git配置
tags:
  - git
key: git-config 
date: '2022-08-05'
lastmod: '2023-01-09'
---

# 安装git

## Linux
### Debian
```bash
sudo apt install git
```
### Fedora
```bash
sudo dnf install git
```

## Windows

### 直接安装

[下载链接](https://github.com/git-for-windows/git/releases/download/v2.37.1.windows.1/Git-2.37.1-64-bit.exe)

### winget安装

```powershell
winget install --id Git.Git -e --source winget
```

# git初步配置

```bash
git config --global user.name "username" #用户名

git config --list #已有配置信息

git config --global user.email youremail #邮箱

git config --global core.editor nvim #默认文本编辑器

git config --global merge.tool vimdiff #差异分析工具
```

# git使用

**概念:**  
工作区：就是你在电脑里能看到的目录。  
暂存区：英文叫 stage 或 index。一般存放在 .git 目录下的 index 文件（.git/index）中，所以我们把暂存区有时也叫作索引（index）。  
版本库：工作区有一个隐藏目录 .git，这个不算工作区，而是 Git 的版本库。

## 基本操作

```bash
git init #初始化仓库
```

**注：第一次初始提交后才有master分支**

```bash
git reset HEAD #版本回退，重写暂存区的目录树，被 master 分支指向的目录树所替换

git rm --cached <file>  #直接从暂存区删除文件，工作区则不做出改变

git checkout .  #清除工作区中未添加到暂存区中的改动

git mv    #移动或重命名工作区文件

git checkout HEAD . #用 HEAD 指向的 master 分支中的全部或者部分文件替换暂存区和以及工作区中的文件

git add file #将文件加入版本控制

git commit -m 'first commit' #提交说明

git status #查看仓库状态

git clone <repo> <directory> #拷贝项目到指定目录

git log #查看历史提交记录
 
git log --show-signature #查看仓库每次提交的签名信息

git blame <path> #查看文件修改记录（列表形式）

git pull #下载源代码合并

git push #上传源代码合并

git fetch #从远程获取代码库
```

## git diff命令

*不加参数即默认比较工作区与暂存区*

```bash
git diff
```

*比较暂存区与最新本地版本库*

```bash
git diff --cached  [<path>...] 
```

*比较工作区与最新本地版本库*

*注：如果HEAD指向的是master分支，那么HEAD还可以换成master* 

```bash
git diff HEAD [<path>...]
```

*比较工作区与指定commit-id的差异*

```bash
git diff commit-id  [<path>...]
```

*比较暂存区与指定commit-id的差异*

```bash
git diff --cached [<commit-id>] [<path>...] 
```

*比较两个commit-id之间的差异*

```bash
git diff [<commit-id>] [<commit-id>]
```

### 使用git diff打补丁

#### 做补丁

```bash
git diff > patch #patch命名随意
git diff --cached > patch #是将我们暂存区与版本库的差异做成补丁
git diff --HEAD > patch #是将工作区与版本库的差异做成补丁
git diff Testfile > patch #将单个文件做成一个单独的补丁
```

#### 打补丁

```bash
git apply patch #打补丁
git apply --check patch #无输出表示可以顺利接受补丁
git apply --reject patch #若有冲突则生成.rej文件，可手动打补丁
```

## git branch命令

*列出分支*

```bash
git branch
```

*创建分支*

```bash
git branch (branchname)
```

*切换分支*

```bash
git checkout (branchname)
```

**注：使用分支将工作切分开来，并能够来回切换。**  

![git-checkout](/images/git-checkout.png)  

如图，切换到test分支后创建README.md,提交更改，然后切换回master分支后发现README.md消失，再切换回test分支后README.md文件出现。  

*合并分支*  

```bash
git merge 
```

**注：多次合并到统一分支， 也可在合并之后直接删除被并入的分支。** 
# git标签
**注意：提交信代码不会改变这个版本，可以理解为当前版本的提交快照！**  
  
*发布release版本时使用，使用-a选项会创建一个带注解的标签，没有-a选项也可以执行，但是不会记录打标签的时间以及提交标签的人，所以推荐创建带注解的标签*  
  
*创建带注解的标签*
```bash
git tag -a v1.0
```
*提交标签到远程仓库*
```bash
git push --tags
```
*追加标签*  
*适用于忘了给提交打标签，却发布了release版本的情况*
*下面命令中d0f2d34是已经发布的提交*
```bash
git tag -a v1.0 d0f2d34
git log --oneline --decorate --graph
```

*指定标签信息*
```bash
git tag -a <tagname> -m "message"
```