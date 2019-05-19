module Binary :
  sig
    val bin_of_unsigned : int -> int -> bin
    type bit = Zero | One
    type bin = bit list
    val string_of_bin : bin -> string
  end
=
  struct
    type bit = Zero | One
    type bin = bit list

    let make_list len elem = Array.to_list @@ Array.make len elem

    let bin_of_unsigned size = function
      | 0 -> Bin (make_list size 0)
      | n ->
          let rec conv = function
            | (0, bin) -> (0, bin)
            | (decimal, bin) ->
                conv (decimal / 2, (decimal mod 2) :: bin)
          in
            let (_, bin) = conv (n, []) in
            let lack = size - List.length bin in
              if lack >= 0
                then Bin ((make_list lack 0) @ bin)
                else failwith "(bin_of_int) Overflow"

    let string_of_bin (Bin bin) =
      String.concat "" @@ List.map string_of_int bin
  end
