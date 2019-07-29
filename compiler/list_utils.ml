let make_list len elem = Array.to_list @@ Array.make len elem

let rec find elem = function
  | [] -> (-1)
  | h :: _ when elem = h -> 0
  | h :: t ->
      let tail = find elem t in
      if tail != (-1) then 1 + tail else (-1)
