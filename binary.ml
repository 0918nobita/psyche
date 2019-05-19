module Binary :
  sig
    type bit = Zero | One
    type bin = bit list
    val bin_of_unsigned : int -> int -> bit list
    val string_of_bin : bin -> string
  end
=
  struct
    type bit = Zero | One
    type bin = bit list

    let make_list len elem = Array.to_list @@ Array.make len elem

    let bin_of_unsigned size = function
      | 0 -> (make_list size Zero)
      | n ->
          let rec conv = function
              | (0, bin) -> (0, bin)
              | (decimal, bin) ->
                  conv (decimal / 2, (if decimal mod 2 = 0 then Zero else One) :: bin)
            in
              let (_, bin) = conv (n, []) in
              let lack = size - List.length bin in
                if lack >= 0
                  then (make_list lack Zero) @ bin
                  else failwith "(bin_of_int) Overflow"

    let string_of_bin bits =
      String.concat ""
        @@ List.map (function Zero -> "0" | One -> "1") bits
  end
