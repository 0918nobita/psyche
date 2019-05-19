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

    let plus size x y =
      let rec plus_inner = function
        | (false, a, b, c) ->
            (match (a, b, c) with
              | ([], [], bits) -> bits
              | (bit :: a, [], c) -> bit :: c
              | ([], bit :: b, c) -> bit :: c
              | (Zero :: a, Zero :: b, c) -> plus_inner (false, a, b, Zero :: c)
              | (Zero :: a, One :: b, c) -> plus_inner (false, a, b, One :: c)
              | (One :: a, Zero :: b, c) -> plus_inner (false, a, b, One :: c)
              | (One :: a, One :: b, c) -> plus_inner (true, a, b, Zero :: c))
        | (true, a, b, c) ->  (* set carry flag *)
            (match (a, b, c) with
              | ([], [], c) -> One :: c
              | (Zero :: a, [], c) -> One :: c
              | (One :: a, [], c) -> One :: Zero :: c
              | ([], Zero :: b, c) -> One :: c
              | ([], One :: b, c) -> One :: Zero :: c
              | (Zero :: a, Zero :: b, c) -> plus_inner (false, a, b, One :: c)
              | (Zero :: a, One :: b, c) -> plus_inner (true, a, b, Zero :: c)
              | (One :: a, Zero :: b, c) -> plus_inner (true, a, b, Zero :: c)
              | (One :: a, One :: b, c) -> plus_inner (true, a, b, One :: c))
      in
        let z = plus_inner (false, List.rev x, List.rev y, []) in
        let lack = size - List.length z in
          if lack >= 0
            then (make_list lack Zero) @ z
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
