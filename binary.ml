module Binary :
  sig
    type bit = Zero | One
    type bin = bit list
    val plus : int -> bit list -> bit list -> bit list
    val twos_complement : int -> bit list -> bit list
    val bin_of_unsigned : int -> int -> bit list
    val string_of_bin : bin -> string
  end
=
  struct
    type bit = Zero | One
    type bin = bit list

    let make_list len elem = Array.to_list @@ Array.make len elem

    let plus size a b =
      let rec plus_inner = function
        | (false, [], [], bits) -> bits
        | (false, bit :: a, [], c) -> bit :: c
        | (false, [], bit :: b, c) -> bit :: c
        | (false, Zero :: a, Zero :: b, c) -> plus_inner (false, a, b, Zero :: c)
        | (false, Zero :: a, One :: b, c) -> plus_inner (false, a, b, One :: c)
        | (false, One :: a, Zero :: b, c) -> plus_inner (false, a, b, One :: c)
        | (false, One :: a, One :: b, c) -> plus_inner (true, a, b, Zero :: c)
        | (true, [], [], c) -> One :: c
        | (true, Zero :: a, [], c) -> One :: c
        | (true, One :: a, [], c) -> One :: Zero :: c
        | (true, [], Zero :: b, c) -> One :: c
        | (true, [], One :: b, c) -> One :: Zero :: c
        | (true, Zero :: a, Zero :: b, c) -> plus_inner (false, a, b, One :: c)
        | (true, Zero :: a, One :: b, c) -> plus_inner (true, a, b, Zero :: c)
        | (true, One :: a, Zero :: b, c) -> plus_inner (true, a, b, Zero :: c)
        | (true, One :: a, One :: b, c) -> plus_inner (true, a, b, One :: c)
      in
        let c = plus_inner (false, List.rev a, List.rev b, []) in
        let lack = size - List.length c in
          if lack >= 0
            then (make_list lack Zero) @ c
            else failwith "(plus) Overflow"

    let twos_complement size bin =
      plus size [One] @@ List.map (function Zero -> One | One -> Zero) bin

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
