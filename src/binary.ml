module Binary :
  sig
    type bit = Zero | One
    type bin = bit list
    val plus : int -> bit list -> bit list -> bit list
    val twos_complement : int -> bit list -> bit list
    val bin_of_int : int -> int -> bit list
    val string_of_bin : bin -> string
    val slice : 'a list -> int -> int -> 'a list
    val split_per : int -> 'a list -> ('a list) list
    val int_of_bin : bit list -> int
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
              | (bit :: a, [], c) -> plus_inner (false, a, [], bit :: c)
              | ([], bit :: b, c) -> plus_inner (false, [], b, bit :: c)
              | (Zero :: a, Zero :: b, c) -> plus_inner (false, a, b, Zero :: c)
              | (Zero :: a, One :: b, c) -> plus_inner (false, a, b, One :: c)
              | (One :: a, Zero :: b, c) -> plus_inner (false, a, b, One :: c)
              | (One :: a, One :: b, c) -> plus_inner (true, a, b, Zero :: c))
        | (true, a, b, c) ->  (* set carry flag *)
            (match (a, b, c) with
              | ([], [], c) -> One :: c
              | (Zero :: a, [], c) -> plus_inner (false, a, [], One :: c)
              | (One :: a, [], c) -> plus_inner (true, a, [], Zero :: c)
              | ([], Zero :: b, c) -> plus_inner (false, [], b, One :: c)
              | ([], One :: b, c) -> plus_inner (true, [], b, Zero :: c)
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

    let rec bin_of_int size = function
      | 0 -> (make_list size Zero)
      | n when n > 0 ->
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
      | n -> twos_complement size @@ bin_of_int size @@ (-1) * n

    let string_of_bin bits =
      String.concat ""
        @@ List.map (function Zero -> "0" | One -> "1") bits

    let slice arr b e =
      let rec slice_inner = function
        | ([], _, _, _, part) -> part
        | (_, current, _, e, part) when current > e -> part
        | (head :: tail, current, b, e, part) when current >= b ->
            slice_inner (tail, current + 1, b, e, head :: part)
        | (_ :: tail, current, b, e, part) ->
            slice_inner (tail, current + 1, b, e, part)
      in
        List.rev @@ slice_inner (arr, 0, b, e, [])

    let split_per size arr =
      let len = List.length arr in
      let rec split_per_inner = function
        | (current, part) when current >= len -> part
        | (current, part) -> split_per_inner (current + size, slice arr current (current + size - 1) :: part)
      in
        List.rev @@ split_per_inner (0, [])

    let int_of_bin bin =
      List.fold_left
        (fun acc n -> acc + n)
        0
        @@ List.mapi
          (fun i bit -> (int_of_float @@ 2. ** float_of_int i) * (match bit with Zero -> 0 | One -> 1))
          @@ List.rev bin
  end
