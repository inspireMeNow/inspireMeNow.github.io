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

DefaultContentLanguage: "zh"
DefaultContentLanguageInSubdir: true

enableRobotsTXT: true
buildDrafts: false
buildExpired: false

# 启用Google Analytics
googleAnalytics: EXAMPLE

minify:
  disableXML: true
  minifyOutput: true

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

params:
  env: production # to enable google analytics, opengraph, twitter-cards and schema.
  title: "username"
  description: "username"
  keywords: [Blog, Portfolio, PaperMod]
  author: Me
  # author: ["Me", "You"] # multiple authors
  images: ["/images/profile.jpg"]
  DateFormat: "January 2, 2006"
  defaultTheme: auto # dark, light
  disableThemeToggle: false

  ShowReadingTime: true
  ShowShareButtons: true
  ShowPostNavLinks: true
  ShowBreadCrumbs: true
  ShowCodeCopyButtons: false
  ShowWordCount: true
  ShowRssButtonInSectionTermList: true
  UseHugoToc: true
  disableSpecial1stPost: false
  disableScrollToTop: false
  comments: true
  hidemeta: false
  hideSummary: false
  showtoc: false
  tocopen: false

  assets:
    # disableHLJS: true # to disable highlight.js
    # disableFingerprinting: true
    favicon: "/images/profile.jpg"
    favicon16x16: "/images/profile.jpg"
    favicon32x32: "/images/profile.jpg"
    # apple_touch_icon: "<link / abs url>"
    # safari_pinned_tab: "<link / abs url>"
  label:
    text: "username"
    # icon: /apple-touch-icon.png
    # iconHeight: 35

  # home-info mode
  # homeInfoParams:
  #   Title: "Hi there \U0001F44B"
  #   Content: "I am an undergraduate student majoring in Computer Science. I have a strong passion for open source and free software, and I thoroughly enjoy acquiring new knowledge and exploring emerging technologies."

  # 社交网站
  socialIcons:
    - name: twitter
      url: "https://twitter.com/username"
    - name: telegram
      url: "https://t.me/username"
    - name: github
      url: "https://github.com/username"
    - name: email
      url: "mailto:username@example.com"
    - name: rss
      url: "/index.xml"

  # analytics:
  #   google:
  #     SiteVerificationTag: "XYZabc"
  #   bing:
  #     SiteVerificationTag: "XYZabc"
  #   yandex:
  #     SiteVerificationTag: "XYZabc"

  cover:
    hidden: true # hide everywhere but not in structured data
    hiddenInList: true # hide on list pages and home
    hiddenInSingle: true # hide on single page

  editPost:
    URL: "https://github.com/username/username.github.io/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link

  # for search
  # https://fusejs.io/api/options.html
  fuseOpts:
    isCaseSensitive: false
    shouldSort: true
    location: 0
    distance: 1000
    threshold: 0.4
    minMatchCharLength: 0
    keys: ["title", "permalink", "summary", "content"]

# Read: https://github.com/adityatelange/hugo-PaperMod/wiki/FAQs#using-hugos-syntax-highlighter-chroma
pygmentsUseClasses: true
markup:
  highlight:
    noClasses: false
    # anchorLineNos: true
    # codeFences: true
    # guessSyntax: true
    # lineNos: true
    # style: monokai
```
# 新建一篇文章
*新建content/posts文件夹，在posts文件夹里新建Markdown文件即可，多语言文章以.language.markdown为后缀即可，language替换为对应的地区代码，以下为示例*
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
*lastmod为最后修改日期*
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
*多语言归档页面设置方式与上面相同*
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