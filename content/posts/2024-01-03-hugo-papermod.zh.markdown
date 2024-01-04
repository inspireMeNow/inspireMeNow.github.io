---
title: "使用Hugo搭建个人博客"
ZHtags: 
  - web
key: hugo-papermod
date: '2024-01-04'
lastmod: '2024-01-04'
---
# 安装Hugo工具

```bash
export HUGO_VERSION=0.121.1
wget -O ./hugo.tar.gz https://github.com/gohugoio/hugo/releaserms/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz 
tar -xvf ./tar.gz
sudo cp hugo /usr/bin
sudo chmod +x /usr/bin/hugo
```
# 创建网站
```bash
hugo new site quickstart
cd quickstart
git init
```
# 设置博客主题
```bash
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
echo "theme: 'PaperMod'" >> hugo.toml
hugo server
```
# 配置网站
```yaml
baseURL: "https://example.com/"
title: username
paginate: 5
theme: PaperMod
# 修复新帖子不渲染的问题
buildFuture: true

# 设置网站默认显示语言
DefaultContentLanguage: "zh"
DefaultContentLanguageInSubdir: true

# 启用Robots.txt
enableRobotsTXT: true
buildDrafts: false
buildExpired: false

# 启用Google Analytics
googleAnalytics: EXAMPLE
```
# 新建一篇文章
*新建content/posts文件夹，在posts文件夹里新建Markdown文件即可，以下为示例*
```markdown
---
title: c++练习
tags: 
  - c++
key: c++link
date: '2022-04-24'
lastmod: '2022-04-24'
---
```
*date为创建日期，lastmod为最后修改日期*
# 新建归档页面
*编辑content/archive.md文件*
```markdown
---
title: "archives"
layout: "archives"
url: "/en/archives/"
summary: archives
---
```
# 为网站启用搜索
*config.yml*
```yaml
outputs:
  home:
    - HTML
    - RSS
    - JSON # 搜索需要
```
*content/search.md*
```markdown
---
title: "Search" # in any language you want
layout: "search" # is necessary
# url: "/archive"
# description: "Description for Search"
summary: "search"
placeholder: "search"
---
```
# 添加多语言支持
```yaml
languages:
  zh:
    languageName: ":zh:"
    weight: 1
    title: "username的小站"
    taxonomies:
      category: ZHcategories
      # 中文语言标签
      tag: ZHtags 
      series: ZHseries
    menu:
      main:
        - identifier: ZHcategories
          name: "目录"
          url: /zh/posts/
          weight: 5
        - identifier: ZHsearch
          name: "搜索"
          url: /search/
          weight: 10
        - identifier: ZHtags
          name: "标签"
          url: /zh/zhtags/
          weight: 15
        - identifier: ZHarchives
          name: "归档"
          url: /archives/
          weight: 17
        - identifier: ZHabout
          name: "关于"
          url: /zh/about/
          weight: 20
        - identifier: ZHprivate
          name: "云盘"
          url: https://example.com
          weight: 25

    # custom params for each language should be under [langcode].parms - hugo v0.120.0
    params:
      languageAltTitle: "中文"
      label:
        text: "username的小站"
      profileMode:
        enabled: true # needs to be explicitly set
        title: username
        subtitle: "CS本科生，热爱开源和自由软件"
        imageUrl: "/images/profile.jpg"
        imageWidth: 120
        imageHeight: 120
        imageTitle: my image
        buttons:
          - name: "目录"
            url: /zh/posts/
          - name: "标签"
            url: /zh/zhtags/
          - name: "关于"
            url: /zh/about/

  en:
    languageName: "English"
    contentDir: content/
    weight: 2
    taxonomies:
      category: categories
      tag: tags
      series: series
    # 菜单栏
    menu:
      main:
        - identifier: categories
          name: categories
          url: /posts/
          weight: 5
        - identifier: search
          name: search
          url: /search/
          weight: 10
        - identifier: tags
          name: tags
          url: /tags/
          weight: 15
        - identifier: archives
          name: archives
          url: /archives/
          weight: 17
        - identifier: about
          name: about
          url: /about/
          weight: 20
        - identifier: private
          name: drive
          url: https://example.com
          weight: 25

    params:
      languageAltTitle: "English"
      # 简介
      profileMode:
        enabled: true # needs to be explicitly set
        title: username
        subtitle: "CS undergraduate student, passionate about open source and free software"
        imageUrl: "/images/profile.jpg"
        imageWidth: 120
        imageHeight: 120
        imageTitle: my image
        buttons:
          - name: "categories"
            url: /posts/
          - name: "tags"
            url: /tags/
          - name: "about"
            url: /about/
```
*多语言文章命名以.language.markdown为后缀即可，language替换为对应的地区代码，多语言归档页面设置方式与上面相同*
# 修复中文标签题目的显示问题
*将themes/PaperMod/layout/_default/terms.html文件复制到layout/_default/目录，之后修改新复制的文件内容*
```html
{{- if .Title }}
<header class="page-header">
    {{- if eq .Title "Categories" }}
    <h1>{{ .Title }}</h1>
    {{- end }}
    {{- if eq .Title "Tags" }}
    <!-- 英文标签题目 -->
    <h1>{{ "Tags" }}</h1>
    {{- end }}
    <!-- 中文标签题目 -->
    {{- if eq .Title "ZHtags" }}
    <h1>{{ "标签" }}</h1>
    {{- end }}
    {{- if .Description }}
    <div class="post-description">
        {{ .Description }}
    </div>
    {{- end }}
</header>
{{- end }}
<!-- 与原始文件相同 -->
```