module Binary :
  sig
    type bit = Zero | One
    type bin = bit list
    val plus : bit list -> bit list -> bit list
    val twos_complement : bit list -> bit list
    val bin_of_unsigned : int -> bit list
    val signed_bin_of_int : int -> bit list
    val string_of_bin : bin -> string
    val int_of_bin : bit list -> int
    val leb128_of_int : int -> int list
  end
=
  struct
    type bit = Zero | One
    type bin = bit list

    let make_list len elem = Array.to_list @@ Array.make len elem

    let plus x y =
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
        plus_inner (false, List.rev x, List.rev y, [])

    let twos_complement bin =
      plus [One] @@ List.map (function Zero -> One | One -> Zero) bin

    let rec bin_of_unsigned = function
      | 0 -> [Zero]
      | n ->
          let rec conv = function
              | (0, bin) -> (0, bin)
              | (decimal, bin) ->
                  conv (decimal / 2,
                    (if decimal mod 2 = 0 then Zero else One) :: bin)
          in
            let (_, bin) = conv (abs n, []) in bin

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
        | (current, part) when current < 0 -> part
        | (current, part) -> split_per_inner (current - size, slice arr (current - size + 1) current :: part)
      in
        split_per_inner (len - 1, [])

    let int_of_bin bin =
      List.fold_left
        (fun acc n -> acc + n)
        0
        @@ List.mapi
          (fun i bit -> (int_of_float @@ 2. ** float_of_int i) * (match bit with Zero -> 0 | One -> 1))
          @@ List.rev bin

    let pow a b = int_of_float @@ (float_of_int a) ** (float_of_int b)

    let adjust_arr_length arr size fill =
      let lack = size - List.length arr in
        if lack = 0
          then arr
          else
            if lack > 0
              then make_list lack fill @ arr
              else failwith "(adjust_arr_length) Invalid format"

    let signed_bin_of_int n =
      let bigger_multiple_of_7 n = if n mod 7 = 0 then n + 7 else 7 * (n / 7 + 1) in
      let
        adjust_length bin =
          adjust_arr_length
            bin
            (bigger_multiple_of_7 @@ List.length bin)
            Zero
      in
      let bin = bin_of_unsigned n in
        if n >= 0
          then adjust_length bin
          else twos_complement @@ adjust_length bin

    let leb128_of_int n =
      List.map int_of_bin
        @@ List.rev
          @@ List.mapi
            (fun i byte -> if i = 0 then Zero :: byte else One :: byte)
            @@ split_per 7 @@ signed_bin_of_int n
  end
