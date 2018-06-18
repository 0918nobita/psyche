package net.zero918nobita.miniLang

import java.math.BigDecimal

class Lexer(n: Int, s: String) {
  private var line = n
  private val reader = LexerReader(s)
  private var tokenType = TokenType.INITIAL

  init {
    advance()
  }

  fun advance(): Boolean {
    val c = reader.read()
    c ?: return false
    when(c) {
      '&' -> {
        tokenType = TokenType.CONTINUATION
      }
      else -> {
        when {
          c.isDigit() -> {
            reader.unread()
            lexDigit()
          }
          c.isJavaIdentifierStart() -> {
            reader.unread()
            lexSymbol()
          }
          else -> throw Exception()
        }
      }
    }
    return true
  }

  fun lexDigit() {
    var num = BigDecimal("0")
    var point = false
    var decimal_place = 0

    while (true) {
      val c = reader.read()
    }
  }

  fun lexSymbol() {
  }
}
