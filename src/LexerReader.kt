package net.zero918nobita.miniLang

class LexerReader(s: String) {
  private val str = s
  private var progress = -1

  fun read(): Char? {
    progress ++
    return if (progress < str.length) str[progress] else null
  }

  fun unread() = progress--
}
