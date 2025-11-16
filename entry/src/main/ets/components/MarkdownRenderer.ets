// MarkdownTypes.ets - 类型定义
interface MarkdownElement {
  type: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'paragraph' | 'list' | 'quote' | 'code' | 'divider'
  content: string
  level?: number
  items?: string[]
}

interface InlineSpan {
  text: string
  isBold: boolean
  isItalic: boolean
  isCode: boolean
  isLink: boolean
  linkUrl?: string
}

// MarkdownParser.ets - Markdown解析器
class MarkdownParser {
  static parse(markdown: string): MarkdownElement[] {
    const elements: MarkdownElement[] = []
    const lines = markdown.split('\n')
    let currentList: string[] = []
    let inCodeBlock = false
    let codeContent = ''

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim()

      // 处理代码块
      if (line.startsWith('```')) {
        if (inCodeBlock) {
          // 结束代码块
          elements.push({ type: 'code', content: codeContent })
          codeContent = ''
          inCodeBlock = false
        } else {
          // 开始代码块
          inCodeBlock = true
        }
        continue
      }

      if (inCodeBlock) {
        codeContent += line + '\n'
        continue
      }

      // 处理空行
      if (line === '') {
        if (currentList.length > 0) {
          elements.push({ type: 'list', content: '', items: [...currentList] })
          currentList = []
        }
        continue
      }

      // 处理分割线
      if (/^[-*_]{3,}$/.test(line)) {
        elements.push({ type: 'divider', content: '' })
        continue
      }

      // 处理标题
      const headerMatch = line.match(/^(#{1,6})\s+(.+)$/)
      if (headerMatch) {
        if (currentList.length > 0) {
          elements.push({ type: 'list', content: '', items: [...currentList] })
          currentList = []
        }
        const level = headerMatch[1].length
        const content = headerMatch[2]
        const headerType: MarkdownElement['type'] = `h${level}` as MarkdownElement['type']
        elements.push({
          type: headerType,
          content,
          level
        })
        continue
      }

      // 处理列表
      const listMatch = line.match(/^[-*+]\s+(.+)$/)
      if (listMatch) {
        currentList.push(listMatch[1])
        continue
      }

      // 处理引用
      const quoteMatch = line.match(/^>\s+(.+)$/)
      if (quoteMatch) {
        if (currentList.length > 0) {
          elements.push({ type: 'list', content: '', items: [...currentList] })
          currentList = []
        }
        elements.push({ type: 'quote', content: quoteMatch[1] })
        continue
      }

      // 处理普通段落
      if (currentList.length > 0) {
        elements.push({ type: 'list', content: '', items: [...currentList] })
        currentList = []
      }
      elements.push({ type: 'paragraph', content: line })
    }

    // 处理最后的列表
    if (currentList.length > 0) {
      elements.push({ type: 'list', content: '', items: [...currentList] })
    }

    // 处理最后的代码块
    if (inCodeBlock) {
      elements.push({ type: 'code', content: codeContent })
    }

    return elements
  }

  static parseInline(text: string): InlineSpan[] {
    const spans: InlineSpan[] = []
    let currentText = ''
    let isBold = false
    let isItalic = false
    let isCode = false
    let isLink = false
    let linkText = ''
    let linkUrl = ''

    for (let i = 0; i < text.length; i++) {
      const char = text[i]
      const nextChar = text[i + 1]

      // 处理代码 `code`
      if (char === '`') {
        if (currentText) {
          spans.push({ text: currentText, isBold, isItalic, isCode, isLink, linkUrl })
          currentText = ''
        }
        isCode = !isCode
        continue
      }

      // 处理粗体 **bold**
      if (char === '*' && nextChar === '*' && !isCode) {
        if (currentText) {
          spans.push({ text: currentText, isBold, isItalic, isCode, isLink, linkUrl })
          currentText = ''
        }
        isBold = !isBold
        i++ // 跳过下一个*
        continue
      }

      // 处理斜体 *italic*
      if (char === '*' && !isCode) {
        if (currentText) {
          spans.push({ text: currentText, isBold, isItalic, isCode, isLink, linkUrl })
          currentText = ''
        }
        isItalic = !isItalic
        continue
      }

      // 处理链接 [text](url)
      if (char === '[' && !isCode) {
        if (currentText) {
          spans.push({ text: currentText, isBold, isItalic, isCode, isLink, linkUrl })
          currentText = ''
        }
        isLink = true
        // 查找链接结束
        const linkEnd = text.indexOf(']', i)
        if (linkEnd !== -1) {
          linkText = text.substring(i + 1, linkEnd)
          const urlStart = text.indexOf('(', linkEnd)
          const urlEnd = text.indexOf(')', urlStart)
          if (urlStart !== -1 && urlEnd !== -1) {
            linkUrl = text.substring(urlStart + 1, urlEnd)
            spans.push({ text: linkText, isBold, isItalic, isCode, isLink: true, linkUrl })
            i = urlEnd // 跳到URL结束
            isLink = false
            linkText = ''
            linkUrl = ''
            continue
          }
        }
      }

      currentText += char
    }

    // 添加最后一段文本
    if (currentText) {
      spans.push({ text: currentText, isBold, isItalic, isCode, isLink, linkUrl })
    }

    return spans
  }
}

// MarkdownRenderer.ets - 主组件
@Component
export default struct MarkdownRenderer {
  private markdownText: string = ''
  private textColor: ResourceColor = Color.Black
  private fontSize: number = 16
  private paddingValue: Padding | number = 16

  build() {
    Column() {
      this.buildMarkdownElements()
    }
    .width('100%')
    .padding(this.paddingValue)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildMarkdownElements() {
    const elements = MarkdownParser.parse(this.markdownText)

    ForEach(elements, (element: MarkdownElement) => {
      this.renderElement(element)
    })
  }

  @Builder
  renderElement(element: MarkdownElement) {
    if (element.type === 'h1') {
      this.renderHeader(element.content, 24, FontWeight.Bold, { bottom: 16, top: 8 })
    } else if (element.type === 'h2') {
      this.renderHeader(element.content, 20, FontWeight.Bold, { bottom: 12, top: 6 })
    } else if (element.type === 'h3') {
      this.renderHeader(element.content, 18, FontWeight.Bold, { bottom: 10, top: 4 })
    } else if (element.type === 'h4') {
      this.renderHeader(element.content, 16, FontWeight.Medium, { bottom: 8, top: 4 })
    } else if (element.type === 'h5') {
      this.renderHeader(element.content, 15, FontWeight.Medium, { bottom: 6, top: 4 })
    } else if (element.type === 'h6') {
      this.renderHeader(element.content, 14, FontWeight.Medium, { bottom: 6, top: 4 })
    } else if (element.type === 'list') {
      this.renderList(element.items || [])
    } else if (element.type === 'quote') {
      this.renderQuote(element.content)
    } else if (element.type === 'code') {
      this.renderCode(element.content)
    } else if (element.type === 'divider') {
      this.renderDivider()
    } else {
      this.renderParagraph(element.content)
    }
  }

  @Builder
  renderHeader(content: string, size: number, weight: FontWeight, margin: Margin) {
    Text(content)
      .fontSize(size)
      .fontWeight(weight)
      .fontColor(this.textColor)
      .margin(margin)
      .width('100%')
  }

  @Builder
  renderParagraph(content: string) {
    const spans = MarkdownParser.parseInline(content)

    Column() {
      ForEach(spans, (span: InlineSpan) => {
        if (span.isLink) {
          Text(span.text)
            .fontColor('#007DFF')
            .decoration({ type: TextDecorationType.Underline })
            .fontSize(this.fontSize)
            .fontWeight(span.isBold ? FontWeight.Bold : FontWeight.Normal)
            .fontStyle(span.isItalic ? FontStyle.Italic : FontStyle.Normal)
            .onClick(() => {
              this.handleLinkClick(span.linkUrl || '')
            })
        } else {
          Text(span.text)
            .fontColor(this.textColor)
            .fontSize(this.fontSize)
            .fontWeight(span.isBold ? FontWeight.Bold : FontWeight.Normal)
            .fontStyle(span.isItalic ? FontStyle.Italic : FontStyle.Normal)
            .backgroundColor(span.isCode ? '#F5F5F5' : Color.Transparent)
            .fontFamily(span.isCode ? 'monospace' : 'sans-serif')
            .padding(span.isCode ? { left: 4, right: 4, top: 2, bottom: 2 } : 0)
            .borderRadius(span.isCode ? 4 : 0)
        }
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 8 })
  }

  @Builder
  renderList(items: string[]) {
    Column() {
      ForEach(items, (item: string) => {
        Row() {
          Text('•')
            .fontSize(this.fontSize)
            .fontColor(this.textColor)
            .margin({ right: 8 })
          this.renderParagraph(item)
        }
        .width('100%')
        .margin({ bottom: 4 })
      })
    }
    .margin({ bottom: 12, left: 8 })
    .width('100%')
  }

  @Builder
  renderQuote(content: string) {
    Column() {
      this.renderParagraph(content)
    }
    .padding(12)
    .backgroundColor('#F8F9FA')
    .border({ width: { left: 4 }, color: '#DEE2E6' })
    .borderRadius(4)
    .margin({ bottom: 12 })
    .width('100%')
  }

  @Builder
  renderCode(content: string) {
    Text(content)
      .fontSize(this.fontSize - 1)
      .fontColor('#24292E')
      .fontFamily('monospace')
      .backgroundColor('#F6F8FA')
      .padding(12)
      .border({ width: 1, color: '#D0D7DE' })
      .borderRadius(6)
      .margin({ bottom: 12 })
      .width('100%')
  }

  @Builder
  renderDivider() {
    Divider()
      .color('#E1E3E6')
      .margin({ top: 16, bottom: 16 })
      .width('100%')
  }

  private handleLinkClick(url: string) {
    console.log('打开链接:', url)
    // 这里可以添加打开链接的逻辑
  }
}