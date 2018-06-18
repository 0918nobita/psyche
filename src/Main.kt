package net.zero918nobita.miniLang

fun main(args: Array<String>) {
  for (i in 1..20) println(fizzBuzz(i))
}

fun fizzBuzz(value: Int): String {
  return value.toString() + when {
    (value % 15 == 0) -> " : FizzBuzz"
    (value % 3 == 0) -> " : Fizz"
    (value % 5 == 0) -> " : Buzz"
    else -> ""
  }
}
