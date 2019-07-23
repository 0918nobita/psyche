let make_list len elem = Array.to_list @@ Array.make len elem

let concatMap f list = List.(concat @@ map f list)
